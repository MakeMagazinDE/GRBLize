unit grbl_com;
// Sende- und Empfangsroutinen for GRBLize und GRBL-Jogger

interface

//uses SysUtils, FTDIdll, FTDIchip, FTDItypes;
uses SysUtils, StrUtils, Windows, Classes, Forms, Controls, Menus,
  Dialogs, StdCtrls, FTDIdll, FTDIchip, FTDItypes, import_files, Clipper;

type
  TFileBuffer = Array of byte;

  procedure mdelay(msecs: Longint);

  function SetupFTDI: String;
  function InitFTDI(my_device:Integer): String;
  function InitFTDIbySerial(my_serial: String):String;
  function CheckCom(my_ComNumber: Integer): Integer;  // check if a COM port is available

  // fordert Maschinenstatus mit "?" an
  function grbl_statusStr: string;

  // Resync, sende #13 und warte 1000 ms auf OK
  function grbl_resync: boolean;

  // GCode-String oder Char an GRBL senden, auf OK warten wenn my_getok = TRUE
  function grbl_sendStr(my_str: String; ProcMsg, my_getok: boolean): String;

  // GCode-String oder Char an GRBL senden, auf OK warten und Antwort in Memo-Feld eintragen
  procedure grbl_addStr(my_str: String);

  // GCode-String von GRBL holen, ggf. Timeout-Zeit warten:
  // ggf. Application.ProcessMessages w‰hrend Warten ausf¸hren
  function grbl_receiveStr(timeout: Integer; ProcMsg: Boolean): string;

  // gibt Anzahl der Zeichen im Empfangspuffer zur¸ck:
  function grbl_receiveCount: Integer;

  // leert Empfangspuffer:
  procedure grbl_rx_clear;

  // GCode-String G92 x,y mit abschlieﬂendem CR an GRBL senden, auf OK warten:
  procedure grbl_offsXY(x, y: Double);
  // GCode-String G92 z mit abschlieﬂendem CR an GRBL senden, auf OK warten
  procedure grbl_offsZ(z: Double);


  // GCode-String G0 x,y mit abschlieﬂendem CR an GRBL senden, auf OK warten.
  // Maschinenkoordinaten wenn is_abs = TRUE
  procedure grbl_moveXY(x, y: Double; is_abs: Boolean);

  // GCode-String G0 z mit abschlieﬂendem CR an GRBL senden, auf OK warten.
  // Maschinenkoordinaten wenn is_abs = TRUE
  procedure grbl_moveZ(z: Double; is_abs: Boolean);
  procedure grbl_moveslowZ(z: Double; is_abs: Boolean);

  // GCode-String G1 x,y,f mit abschlieﬂendem CR an GRBL senden, auf OK warten:
  // F (speed) wird nur gesendet, wenn es sich ge‰ndert hat!
  procedure grbl_millXYF(x, y: Double; f: Integer);

  // GCode-String G1 x,y,f mit abschlieﬂendem CR an GRBL senden, auf OK warten:
  // F (speed) wird nur gesendet, wenn es sich ge‰ndert hat!
  procedure grbl_millXY(x, y: Double);

  // GCode-String G1 z mit abschlieﬂendem CR an GRBL senden, auf OK warten:
  // F (speed) wird nur gesendet, wenn es sich ge‰ndert hat!
  procedure grbl_millZF(z: Double; f: Integer);

  // GCode-String G1 z mit abschlieﬂendem CR an GRBL senden, auf OK warten:
  procedure grbl_millZ(z: Double);

  // GCode-String G1 x,y,z,f mit abschlieﬂendem CR an GRBL senden, auf OK warten:
  // F (speed) wird nur gesendet, wenn es sich ge‰ndert hat!
  procedure grbl_millXYZF(x, y, z: Double; f: Integer);

  // GCode-String G1 x,y,z mit abschlieﬂendem CR an GRBL senden, auf OK warten:
  procedure grbl_millXYZ(x, y, z: Double);

  // kompletten einzelnen Pfad fr‰sen, zur¸ck bis Anfang wenn Closed
  procedure grbl_millpath(millpath: TPath; millpen: Integer; offset: TIntPoint; is_closedpoly: Boolean);

  // kompletten Pfad bohren, ggf. wiederholen bis z_end erreicht
  procedure grbl_drillpath(millpath: TPath; millpen: Integer; offset: TIntPoint);

var
//FTDI-Device
  ftdi: Tftdichip;
  ftdi_isopen : Boolean;
  ftdi_selected_device: Integer;  // FTDI-Frosch-Device-Nummer
  ftdi_serial: String;
  ftdi_device_count: dword;
  ftdi_device_list: pftdiDeviceList;
  ftdi_sernum_arr, ftdi_desc_arr: Array[0..15] of String;
  grbl_oldx, grbl_oldy, grbl_oldz: Double;
  grbl_oldf: Integer;
  grbl_sendlist, grbl_receveivelist: TSTringList;
  grbl_checksema: boolean;

implementation

uses grbl_player_main;


procedure mdelay(msecs: Longint);
var
  targettime: cardinal;
begin
  targettime := GetTickCount + msecs;
  while targettime > GetTickCount do ;
    Application.ProcessMessages;
end;


function ExtComName(ComNr: DWORD): string;
begin
  if ComNr > 9 then
    Result := Format('\\.\COM%d', [ComNr])
  else
    Result := Format('COM%d', [ComNr]);
end;

function CheckCom(my_ComNumber: Integer): Integer;
// check if a COM port is available
var
  FHandle: THandle;
  my_str: String;
begin
  Result := 0;
  my_str:= ExtComName(my_ComNumber);
  FHandle := CreateFile(PChar(my_str),
    GENERIC_WRITE,
    0, {exclusive access}
    nil, {no security attrs}
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0);
  if FHandle <> INVALID_HANDLE_VALUE then
    CloseHandle(FHandle)
  else
    Result := GetLastError;
end;

// #############################################################################
// #############################################################################


function grbl_receiveCount: Integer;
// gibt Anzahl der Zeichen im Empfangspuffer zur¸ck
var i: Integer;
begin
  if ftdi_isopen then begin
    i:= 0;
    ftdi.getReceiveQueueStatus(i);
    grbl_receiveCount:= i;
  end else
    grbl_receiveCount:= 0;
end;

procedure grbl_rx_clear;
begin
  if ftdi_isopen then
    ftdi.purgeQueue(fReceiveQueue);
end;

function grbl_receiveStr(timeout: Integer; ProcMsg: Boolean): string;
// wartet unendlich, wenn timeout = 0
var
  my_str: String;
  i: Integer;
  my_char: char;
  targettime: cardinal;
  has_timeout: Boolean;
begin
  CancelWait:= false;
  if ftdi_isopen then begin
    my_str:= '';
    has_timeout:= timeout > 0;
    targettime := GetTickCount + timeout;
    repeat
      if ProcMsg then
        Application.ProcessMessages;
      i:= grbl_receiveCount;
      if i > 0 then begin
        ftdi.read(@my_char, 1, i);
        if my_char >= #32 then
          my_str:= my_str + my_char;
      end;
    until (my_char= #10) or ((GetTickCount > targettime) and has_timeout) or CancelWait;
    if has_timeout then
      if (GetTickCount > targettime) then
        my_str:= '#Timeout';
    if CancelWait then
      my_str:= '#Cancelled';
  end else
    my_str:= '#Device not open';
  grbl_receiveStr:= my_str;
end;

function grbl_sendStr(my_str: String; ProcMsg, my_getok: boolean): String;
// liefert TRUE wenn my_getok TRUE war und GRBL mit "ok" geantwortet hat
// String sollte mit #13 abgeschlossen sein, kann aber auch einzelnes
// GRBL-Steuerzeichen sein (?,!,~,CTRL-X)
var
  i: longint;
begin
  CancelWait:= false;
  grbl_sendStr:= '';
  if ftdi_isopen then begin
    ftdi.write(@my_str[1], length(my_str), i);
    if my_getok then begin
      grbl_sendStr:= grbl_receiveStr(0, ProcMsg);
    end;
  end;
end;

function grbl_statusStr: string;
// fordert Maschinenstatus mit "?" an
begin
  CancelWait:= false;
  grbl_sendStr('?', false, false); // Status anfordern
  grbl_statusStr:= grbl_receiveStr(100, true);
end;


function grbl_resync: boolean;
// Resync, sende #13 und warte 50 ms auf OK
var my_str: String;
  i, n: Integer;
begin
  CancelWait:= false;
  grbl_resync:= false;
  my_str:= '';
  if ftdi_isopen then begin
    while grbl_receiveCount <> 0 do begin
      mdelay(100); // falls noch etwas vorliegt
      grbl_rx_clear;
    end;
    for i:= 0 to 7 do begin  // Anzahl Versuche
      my_str:= #13;
      ftdi.write(@my_str[1], 1, n);
      my_str:= grbl_receiveStr(50, false);
      if (my_str = 'ok') or CancelWait then
        break;
      mdelay(100); // nochmal versuchen
      grbl_rx_clear;
    end;
    grbl_resync:= (my_str = 'ok');
  end else
    grbl_resync:= true;
end;

procedure grbl_addStr(my_str: String);
// Zeile an Sendeliste anh‰ngen, wird in Timer2 behandelt
begin
  grbl_sendlist.add(my_str);
end;

// #############################################################################
// Highlevel-Funktionen
// #############################################################################

procedure grbl_checkZ(var z: Double);
// limits z to upper limit
begin
end;

procedure grbl_checkXY(var x,y: Double);
// limits xy to machine limits
begin
end;

procedure grbl_offsXY(x, y: Double);
// GCode-String G92 x,y mit abschlieﬂendem CR an GRBL senden, auf OK warten
begin
  grbl_addStr('G92 X'+ FloatToSTrDot(x)+' Y'+ FloatToSTrDot(y));
end;

procedure grbl_offsZ(z: Double);
// GCode-String G92 z mit abschlieﬂendem CR an GRBL senden, auf OK warten
begin
  grbl_addStr('G92 Z'+ FloatToSTrDot(z));
end;

procedure grbl_moveXY(x, y: Double; is_abs: Boolean);
// GCode-String G0 x,y mit abschlieﬂendem CR an GRBL senden, auf OK warten
var my_str: String;
begin
  if is_abs then
    my_str:= 'G0 G53 X'
  else begin
    my_str:= 'G0 X';
    grbl_checkXY(x,y);
    grbl_oldx:= x;
    grbl_oldy:= y;
  end;
  my_str:= my_str + FloatToSTrDot(x) + ' Y' + FloatToSTrDot(y);
  grbl_addStr(my_str);
end;

procedure grbl_moveZ(z: Double; is_abs: Boolean);
// GCode-String G0 z mit abschlieﬂendem CR an GRBL senden, auf OK warten
var my_str: String;
begin
  if is_abs then
    my_str:= 'G0 G53 Z'
  else begin
    my_str:= 'G0 Z';
    grbl_checkZ(z);
    grbl_oldz:= z;
  end;
  my_str:= my_str + FloatToSTrDot(z);
  grbl_addStr(my_str);
end;

procedure grbl_moveslowZ(z: Double; is_abs: Boolean);
// GCode-String G0 z mit abschlieﬂendem CR an GRBL senden, auf OK warten
var my_str: String;
begin
  if is_abs then
    my_str:= 'G1 G53 Z'
  else begin
    my_str:= 'G1 Z';
    grbl_checkZ(z);
    grbl_oldz:= z;
  end;
  my_str:= my_str + FloatToSTrDot(z) + ' F250';
  grbl_oldf:= 250;
  grbl_addStr(my_str);
end;

procedure grbl_millXYF(x, y: Double; f: Integer);
// GCode-String G0 x,y mit abschlieﬂendem CR an GRBL senden, auf OK warten
// F (speed) wird nur gesendet, wenn es sich ge‰ndert hat!
var my_str: String;
begin
  grbl_checkXY(x,y);
  my_str:= 'G1 X'+ FloatToSTrDot(x)+' Y'+ FloatToSTrDot(y);
  if f <> grbl_oldf then
    my_str:= my_str + ' F' + IntToStr(f);
  grbl_addStr(my_str);
  grbl_oldf:= f;
  grbl_oldx:= x;
  grbl_oldy:= y;
end;

procedure grbl_millXY(x, y: Double);
// GCode-String G0 x,y mit abschlieﬂendem CR an GRBL senden, auf OK warten
// XY-Werte werden nur gesendet, wenn sie sich ge‰ndert haben!
var my_str: String;
begin
  grbl_checkXY(x,y);
  my_str:= 'G1';
  if x <> grbl_oldx then
    my_str:= my_str + ' X'+ FloatToSTrDot(x);
  if y <> grbl_oldy then
    my_str:= my_str + ' Y'+ FloatToSTrDot(y);
  grbl_addStr(my_str);
  grbl_oldx:= x;
  grbl_oldy:= y;
end;

procedure grbl_millZF(z: Double; f: Integer);
// GCode-String G0 x,y mit abschlieﬂendem CR an GRBL senden, auf OK warten
// F (speed) wird hier immer neu gesetzt wg. mˆglichem GRBL-Z-Scaling
var my_str: String;
begin
  grbl_checkZ(z);
  if (job.z_feedmult < 0.9) or (job.z_feedmult > 1.1) then begin
    my_str:= 'G1 Z'+ FloatToSTrDot(z) + ' F' + IntToStr(round(f * job.z_feedmult));
    grbl_addStr(my_str);
  end;
  my_str:= 'G1 Z'+ FloatToSTrDot(z) + ' F' + IntToStr(f);
  grbl_addStr(my_str);
  grbl_oldf:= f;
  grbl_oldz:= z;
end;

procedure grbl_millZ(z: Double);
// GCode-String G0 x,y mit abschlieﬂendem CR an GRBL senden, auf OK warten
var my_str: String;
begin
  grbl_checkZ(z);
  my_str:= 'G1 Z'+ FloatToSTrDot(z);
  grbl_addStr(my_str);
  grbl_oldz:= z;
end;

procedure grbl_millXYZF(x, y, z: Double; f: Integer);
// GCode-String G0 x,y mit abschlieﬂendem CR an GRBL senden, auf OK warten
// F (speed) wird nur gesendet, wenn es sich ge‰ndert hat!
var my_str: String;
begin
  grbl_checkXY(x,y);
  grbl_checkZ(z);
  my_str:= 'G1 X' + FloatToSTrDot(x) +' Y'+ FloatToSTrDot(y) +' Z' + FloatToSTrDot(z);
  if f <> grbl_oldf then
    my_str:= my_str + ' F' + IntToStr(f);
  grbl_addStr(my_str);
  grbl_oldf:= f;
  grbl_oldx:= x;
  grbl_oldy:= y;
  grbl_oldz:= z;
end;

procedure grbl_millXYZ(x, y, z: Double);
// GCode-String G0 x,y mit abschlieﬂendem CR an GRBL senden, auf OK warten
// XYZ-Werte werden nur gesendet, wenn sie sich ge‰ndert haben!
var my_str: String;
begin
  grbl_checkXY(x,y);
  grbl_checkZ(z);
  my_str:= 'G1';
  if x <> grbl_oldx then
    my_str:= my_str + ' X'+ FloatToSTrDot(x);
  if y <> grbl_oldy then
    my_str:= my_str + ' Y'+ FloatToSTrDot(y);
  if z <> grbl_oldz then
    my_str:= my_str + ' Z'+ FloatToSTrDot(z);
  grbl_addStr(my_str);
  grbl_oldx:= x;
  grbl_oldy:= y;
  grbl_oldz:= z;
end;


procedure grbl_drillpath(millpath: TPath; millpen: Integer; offset: TIntPoint);
// kompletten Pfad bohren, ggf. wiederholen bis z_end erreicht
var i, my_len, my_z_feed: Integer;
  x, y: Double;
  z, my_z_end: Double;

  begin
  my_len:= length(millpath);
  if my_len < 1 then
    exit;

  // Tool ist noch oben
  x:= (millpath[0].x + offset.x) / c_hpgl_scale;
  y:= (millpath[0].y + offset.y) / c_hpgl_scale;
  grbl_moveXY(x,y, false);

  my_z_end:= -job.pens[millpen].z_end; // Endtiefe
  for i:= 0 to my_len - 1 do begin
    if CancelProc then
      break;
    grbl_moveZ(job.z_penup, false);
    x:= (millpath[i].x + offset.x) / c_hpgl_scale;
    y:= (millpath[i].y + offset.y) / c_hpgl_scale;
    grbl_moveXY(x,y,false);
    z:= 0;
    my_z_feed:= job.pens[millpen].speed;
    if my_z_feed > job.z_feed then
      my_z_feed:= job.z_feed;
    repeat
      grbl_moveZ(0.5, false); // ann‰hern auf 0,5 mm ¸ber Oberfl‰che
      z:= z - job.pens[millpen].z_inc;
      if z < my_z_end then
        z:= my_z_end;
      grbl_millZF(z, my_z_feed);
    until (z <= my_z_end) or CancelProc;
  end;
  grbl_moveZ(job.z_penup, false);
end;


procedure grbl_millpath(millpath: TPath; millpen: Integer; offset: TIntPoint; is_closedpoly: Boolean);
// kompletten Pfad fr‰sen, ggf. wiederholen bis z_end erreicht
var i, my_len, my_z_feed: Integer;
  x, y: Double;
  z, my_z_limit, my_z_end: Double;

  begin
  my_len:= length(millpath);
  if my_len < 1 then
    exit;
  // Tool ist noch oben
  x:= (millpath[0].x + offset.x) / c_hpgl_scale;
  y:= (millpath[0].y + offset.y) / c_hpgl_scale;
  grbl_moveXY(x,y, false);

  my_z_limit:= 0;
  my_z_end:= -job.pens[millpen].z_end; // Endtiefe
  repeat
    my_z_limit:= my_z_limit - job.pens[millpen].z_inc;
    z:= -job.pens[millpen].z_end;
    if z < my_z_limit then
      z:= my_z_limit;

    if CancelProc then
      break;
    grbl_moveZ(job.z_penup, false);
    x:= (millpath[0].x + offset.x) / c_hpgl_scale;
    y:= (millpath[0].y + offset.y) / c_hpgl_scale;
    grbl_moveXY(x,y, false);
    grbl_moveZ(0.5, false); // ann‰hern auf 0,5 mm ¸ber Oberfl‰che

    my_z_feed:= job.pens[millpen].speed;
    if my_z_feed > job.z_feed then
      my_z_feed:= job.z_feed;
    grbl_millZF(z, my_z_feed); // langsam eintauchen
    for i:= 1 to my_len - 1 do begin
      if CancelProc then
        break;
      x:= (millpath[i].x + offset.x) / c_hpgl_scale;
      y:= (millpath[i].y + offset.y) / c_hpgl_scale;
      grbl_millXYF(x,y, job.pens[millpen].speed);
    end;
    if is_closedpoly and (not CancelProc) then begin
      x:= (millpath[0].x + offset.x) / c_hpgl_scale;
      y:= (millpath[0].y + offset.y) / c_hpgl_scale;
      grbl_millXYF(x,y, job.pens[millpen].speed);
    end;
  until (my_z_limit <= my_z_end) or CancelProc;
  grbl_moveZ(job.z_penup, false);
end;


// #############################################################################
// #############################################################################

function SetupFTDI: String;
var
  i: longint;
  vid, pid: word;
  device: fDevice;

begin
  ftdi_isopen:= false;
  ftdi:= tftdichip.create;  { Create class instance }
  { Get the device list }
  if not ftdi.createDeviceInfoList(ftdi_device_count, ftdi_device_list) then begin
    result:= 'Failed to create device info list';
    freeandnil(ftdi);
    exit;
  end;
  result:= 'Found ' + IntToStr(ftdi_device_count) + ' FTDI devices';

  { Iterate through the device list that was returned }
  if ftdi_device_count > 0 then
    for i := 0 to ftdi_device_count - 1 do begin
      ftdi_sernum_arr[i]:= strpas(ftdi_device_list^[i].serialNumber);
      ftdi_desc_arr[i]:= strpas(ftdi_device_list^[i].description);
    end;
end;

function InitFTDI(my_device:Integer):String;
begin
    { Check if device is present }
  if not ftdi.isPresentBySerial(ftdi_sernum_arr[my_device]) then begin
    result:= 'Device not present';
    ftdi.destroy;
    ftdi := nil;
    exit;
  end;

  if not ftdi.openDeviceBySerial(ftdi_sernum_arr[my_device]) then begin
    result:= 'Failed to open device';
    ftdi.destroy;
    ftdi := nil;
    exit;
  end;
  { Configure for 19200 baud, 8 bit, 1 stop bit, no parity, no flow control }
  if ftdi.resetDevice then begin
    ftdi_isopen:= true;
    ftdi.setBaudRate(fBaud19200);
    ftdi.setDataCharacteristics(fBits8, fStopBits1, fParityNone);
    ftdi.setFlowControl(fFlowNone, 0, 0);
    result:= 'USB connected';
  end else
    result:= 'Reset error';
end;

function InitFTDIbySerial(my_serial: String):String;
var
  i: Integer;
begin
  if ftdi_device_count > 0 then begin
    if not ftdi.isPresentBySerial(my_serial) then begin
      result:= 'Device not present';
      ftdi.destroy;
      ftdi := nil;
      exit;
    end;

    if not ftdi.openDeviceBySerial(my_serial) then begin
      result:= 'Failed to open device';
      ftdi.destroy;
      ftdi := nil;
      exit;
    end;
    { Configure for 19200 baud, 8 bit, 1 stop bit, no parity, no flow control }
    if ftdi.resetDevice then begin
      ftdi_isopen:= true;
      ftdi.setBaudRate(fBaud19200);
      ftdi.setDataCharacteristics(fBits8, fStopBits1, fParityNone);
      ftdi.setFlowControl(fFlowNone, 0, 0);
      result:= 'USB connected';
    end else
      result:= 'Reset error';
  end;
end;

end.
