unit grbl_com;
// Sende- und Empfangsroutinen for GRBLize und GRBL-Jogger

{$DEFINE UNICODE}
{$DEFINE GRBL115}

interface

//uses SysUtils, FTDIdll, FTDIchip, FTDItypes;
uses SysUtils, StrUtils, Windows, Classes, Forms, Controls, Menus,
  Dialogs, StdCtrls, FTDIdll, FTDIchip, FTDItypes, import_files, Clipper;

type
  TFileBuffer = Array of byte;

  procedure mdelay(const Milliseconds: DWord);

  function SetupFTDI: String;
  function InitFTDI(my_device:Integer): String;
  function InitFTDIbySerial(my_serial: String):String;
  function CheckCom(my_ComNumber: Integer): Integer;  // check if a COM port is available

  // fordert Maschinenstatus mit "?" an
  function grbl_statusStr: string;

  // Resync, sende #13 und warte 1000 ms auf OK
  function grbl_resync: boolean;

  // GCode-String oder Char an GRBL senden, auf OK warten wenn my_getok = TRUE
  function grbl_sendStr(sendStr: String; my_getok: boolean): String;

  // GCode-String oder Char an GRBL senden, auf OK warten und Antwort in Memo-Feld eintragen
  procedure grbl_addStr(my_str: String);

  // GCode-String von GRBL holen, ggf. Timeout-Zeit warten:
  // ggf. Application.ProcessMessages w‰hrend Warten ausf¸hren
  function grbl_receiveStr(timeout: Integer): string;

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

  function GetStatus(var pos_changed: Boolean): Boolean;

const
{$IFDEF GRBL115}
  c_delay_short = 4;
  c_delay_long = 16;
{$ELSE}
  c_delay_short = 10;
  c_delay_long = 50;
{$ENDIF}

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

uses grbl_player_main, glscene_view, Graphics;

procedure mdelay(const Milliseconds: DWord);
var
  FirstTickCount: DWord;
begin
  FirstTickCount := GetTickCount;
  while ((GetTickCount - FirstTickCount) < Milliseconds) do
  begin
    Application.ProcessMessages;
    Sleep(0);
  end;
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

function grbl_receiveStr(timeout: Integer): string;
// wartet unendlich, wenn timeout = 0
var
  my_str: AnsiString;
  i: Integer;
  my_char: AnsiChar;
  targettime: cardinal;
  has_timeout: Boolean;
begin
  CancelWait:= false;
  if ftdi_isopen then begin
    my_str:= '';
    has_timeout:= timeout > 0;
    targettime := GetTickCount + timeout;
    repeat
      i:= grbl_receiveCount;
      if i > 0 then begin
        ftdi.read(@my_char, 1, i);
        if my_char >= #32 then
          my_str:= my_str + my_char;
      end;
      Application.processmessages;
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

function grbl_sendStr(sendStr: String; my_getok: boolean): String;
// liefert TRUE wenn my_getok TRUE war und GRBL mit "ok" geantwortet hat
// String sollte mit #13 abgeschlossen sein, kann aber auch einzelnes
// GRBL-Steuerzeichen sein (?,!,~,CTRL-X)
var
  i: longint;
  my_str: AnsiString;
begin
{$IFDEF UNICODE}
  my_str:= AnsiString(sendStr);
{$ELSE}
  my_str:= sendStr;
{$ENDIF}
  CancelWait:= false;
  grbl_sendStr:= '';
  if ftdi_isopen then begin
    ftdi.write(@my_str[1], length(my_str), i);
    if my_getok then begin
      grbl_sendStr:= grbl_receiveStr(0);
    end;
  end;
end;

function grbl_statusStr: string;
// fordert Maschinenstatus mit "?" an
begin
  CancelWait:= false;
  grbl_sendStr('?', false); // Status anfordern
  grbl_statusStr:= grbl_receiveStr(100);
end;


function grbl_resync: boolean;
// Resync, sende #13 und warte 50 ms auf OK
var my_str: AnsiString;
  i, n: Integer;
begin
  CancelWait:= false;
  my_str:= '';
  if ftdi_isopen then begin
    while grbl_receiveCount <> 0 do begin
      mdelay(c_delay_long); // falls noch etwas vorliegt
      grbl_rx_clear;
    end;
    for i:= 0 to 7 do begin  // Anzahl Versuche
      my_str:= #13;
      ftdi.write(@my_str[1], 1, n);
      my_str:= grbl_receiveStr(c_delay_short);
      if (my_str = 'ok') or CancelWait then
        break;
      mdelay(c_delay_long); // nochmal versuchen
      grbl_rx_clear;
    end;
    grbl_resync:= (my_str = 'ok');
  end else
    grbl_resync:= true;
end;

procedure grbl_addStr(my_str: String);
// Zeile an Sendeliste anh‰ngen, wird in Timer2 behandelt
begin
  if (not CancelJob) or (not CancelGrbl) then
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
    if CancelGrbl then
      exit;
    grbl_moveZ(job.z_penup, false);
    x:= (millpath[i].x + offset.x) / c_hpgl_scale;
    y:= (millpath[i].y + offset.y) / c_hpgl_scale;
    grbl_moveXY(x,y,false);
    z:= 0;
    my_z_feed:= job.pens[millpen].speed;
    if my_z_feed > job.z_feed then
      my_z_feed:= job.z_feed;
    if CancelGrbl then
      exit;
    repeat
      grbl_moveZ(0.5, false); // ann‰hern auf 0,5 mm ¸ber Oberfl‰che
      z:= z - job.pens[millpen].z_inc;
      if z < my_z_end then
        z:= my_z_end;
      grbl_millZF(z, my_z_feed);
    until (z <= my_z_end) or CancelGrbl;
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

    if CancelGrbl then
      exit;
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
      if CancelGrbl then
        exit;
      x:= (millpath[i].x + offset.x) / c_hpgl_scale;
      y:= (millpath[i].y + offset.y) / c_hpgl_scale;
      grbl_millXYF(x,y, job.pens[millpen].speed);
    end;
    if is_closedpoly and (not CancelGrbl) then begin
      x:= (millpath[0].x + offset.x) / c_hpgl_scale;
      y:= (millpath[0].y + offset.y) / c_hpgl_scale;
      grbl_millXYF(x,y, job.pens[millpen].speed);
    end;
  until (my_z_limit <= my_z_end) or CancelGrbl;
  grbl_moveZ(job.z_penup, false);
end;


// #############################################################################
// #############################################################################

function SetupFTDI: String;
var
  i: Integer;
begin
  ftdi_isopen:= false;
  ftdi:= tftdichip.create;  { Create class instance }
  { Get the device list }
  if not ftdi.createDeviceInfoList(ftdi_device_count, ftdi_device_list) then begin
    result:= '### Error: Failed to create device info list';
    freeandnil(ftdi);
    exit;
  end;
  { Iterate through the device list that was returned }
  if ftdi_device_count > 0 then begin
    result:= InttoStr (ftdi_device_count) +  ' FTDI devices found';
    for i := 0 to ftdi_device_count - 1 do begin
    {$IFDEF UNICODE}
      ftdi_sernum_arr[i] := UnicodeString(ftdi_device_list^[i].serialNumber);
      ftdi_desc_arr[i] := UnicodeString(ftdi_device_list^[i].description);
    {$ELSE}
      ftdi_sernum_arr[i] := AnsiString(ftdi_device_list^[i].serialNumber);
      ftdi_desc_arr[i] := AnsiString(ftdi_device_list^[i].description);
    {$ENDIF}
    end;
  end else
    result:= '### Error: No FTDI devices found - simulation only';
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
  if ftdi.resetDevice then begin
    ftdi_isopen:= true;
{$IFDEF GRBL115}
// Configure for 115200 baud, 8 bit, 1 stop bit, no parity, no flow control
    ftdi.setBaudRate(fBaud115200);
{$ELSE}
// Configure for 19200 baud, 8 bit, 1 stop bit, no parity, no flow control
    ftdi.setBaudRate(fBaud19200);
{$ENDIF}
    ftdi.setDataCharacteristics(fBits8, fStopBits1, fParityNone);
    ftdi.setFlowControl(fFlowNone, 0, 0);
    result:= 'USB connected';
  end else
    result:= 'Reset error';
end;

function InitFTDIbySerial(my_serial: String):String;
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
    if ftdi.resetDevice then begin
      ftdi_isopen:= true;
{$IFDEF GRBL115}
// Configure for 115200 baud, 8 bit, 1 stop bit, no parity, no flow control
      ftdi.setBaudRate(fBaud115200);
{$ELSE}
// Configure for 19200 baud, 8 bit, 1 stop bit, no parity, no flow control
      ftdi.setBaudRate(fBaud19200);
{$ENDIF}
      ftdi.setDataCharacteristics(fBits8, fStopBits1, fParityNone);
      ftdi.setFlowControl(fFlowNone, 0, 0);
      result:= 'USB connected';
    end else
      result:= 'Reset error';
  end;
end;


function GetStatus(var pos_changed: Boolean): Boolean;
// liefert Busy-Status TRUE wenn GRBL-Status nicht IDLE ist
// setzt pos_changed wenn sich Position ‰nderte
var
  my_str, my_response: String;
  my_start_idx: Integer;
  is_valid: Boolean;

begin
  result:= false;
  pos_changed:= false;
  if not ftdi_isopen then
    exit;

  while grbl_receiveCount > 0 do begin
    my_response:= grbl_receiveStr(2);  // Dummy lesen
    mdelay(c_delay_short);
  end;
  grbl_sendStr('?', false);          // neuen Status anfordern
  mdelay(c_delay_short);
  my_response:= grbl_receiveStr(c_delay_long); // ca. 50 Zeichen maximal
  Form1.EditStatus.Text:= my_response;

{$IFDEF GRBL115}
  // Format bei GRBL-JOG: Idle,MPos,100.00,0.00,0.00,WPos,100.00,0.00,0.00
  // Format bei GRBL 0.9j: <Idle,MPos:0.000,0.000,0.000,WPos:0.000,0.000,0.000>
  if pos('>', my_response) < 1 then   // nicht vollst‰ndig
    exit;
  if my_response[1] = '<' then begin
    my_response:= StringReplace(my_response,'<','',[rfReplaceAll]);
    my_response:= StringReplace(my_response,'>','',[rfReplaceAll]);
    my_response:= StringReplace(my_response,':',',',[rfReplaceAll]);
  end else
    exit;
{$ENDIF}

  is_valid:= false;
  with Form1 do begin
    grbl_receveivelist.clear;
    grbl_receveivelist.CommaText:= my_response;
    if grbl_receveivelist.Count < 2 then
      exit;
    my_Str:= grbl_receveivelist[0];
    if my_Str = 'Idle' then begin
      Panel1.Color:= clLime;
      is_valid:= true;
    end else
      Panel1.Color:= $00004000;
    if (my_Str = 'Queue') or (my_Str =  'Hold') then begin
      is_valid:= true;
      Panel2.Color:= clAqua;
      result:= true;
    end else
      Panel2.Color:= $00400000;

    if (my_Str = 'Run') or AnsiContainsStr(my_Str,'Jog') then begin
      is_valid:= true;
      Panel3.Color:= clFuchsia;
      result:= true;
    end else
      Panel3.Color:= $00400040;

    if my_Str = 'Alarm' then begin
      is_valid:= true;
      Panel4.Color:= clRed;
    end else
      Panel4.Color:= $00000040;

    // keine g¸ltige Statusmeldung?
    if not is_valid then
      exit;
    my_start_idx:= grbl_receveivelist.IndexOf('MPos');
    if my_start_idx >= 0 then begin
      grbl_mpos.x:= StrDotToFloat(grbl_receveivelist[my_start_idx+1]);
      MPosX.Caption:= grbl_receveivelist[my_start_idx+1];
      grbl_mpos.y:= StrDotToFloat(grbl_receveivelist[my_start_idx+2]);
      MPosY.Caption:= grbl_receveivelist[my_start_idx+2];
      grbl_mpos.z:= StrDotToFloat(grbl_receveivelist[my_start_idx+3]);
      MPosZ.Caption:= grbl_receveivelist[my_start_idx+3];
    end;
    my_start_idx:= grbl_receveivelist.IndexOf('WPos');
    if my_start_idx >= 0 then begin
       grbl_wpos.x:= StrDotToFloat(grbl_receveivelist[my_start_idx+1]);
      PosX.Caption:= FormatFloat('000.00', grbl_wpos.x);
      grbl_wpos.y:= StrDotToFloat(grbl_receveivelist[my_start_idx+2]);
      PosY.Caption:= FormatFloat('000.00', grbl_wpos.y);
      grbl_wpos.z:= StrDotToFloat(grbl_receveivelist[my_start_idx+3]);
      PosZ.Caption:= FormatFloat('000.00', grbl_wpos.z);
    end;
    my_start_idx:= grbl_receveivelist.IndexOf('JogX');
    if my_start_idx >= 0 then begin
      grbl_wpos.x:= StrDotToFloat(grbl_receveivelist[my_start_idx+1]);
      PosX.Caption:= FormatFloat('000.00', grbl_wpos.x);
    end;
    my_start_idx:= grbl_receveivelist.IndexOf('JogY');
    if my_start_idx >= 0 then begin
      grbl_wpos.y:= StrDotToFloat(grbl_receveivelist[my_start_idx+1]);
      PosY.Caption:= FormatFloat('000.00', grbl_wpos.y);
    end;
    my_start_idx:= grbl_receveivelist.IndexOf('JogZ');
    if my_start_idx >= 0 then begin
      grbl_wpos.z:= StrDotToFloat(grbl_receveivelist[my_start_idx+1]);
      PosZ.Caption:= FormatFloat('000.00', grbl_wpos.z);
    end;
  end;
  if (old_grbl_wpos.X <> grbl_wpos.X) or (old_grbl_wpos.Y <> grbl_wpos.Y) then begin
    pos_changed:= true;
    old_grbl_wpos:= grbl_wpos;
  end;
end;

end.
