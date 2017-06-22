unit grbl_com;
// Sende- und Empfangsroutinen for GRBLize und GRBL-Jogger

{$DEFINE UNICODE}
{$DEFINE GRBL115}

interface

//uses SysUtils, FTDIdll, FTDIchip, FTDItypes;
uses SysUtils, StrUtils, DateUtils, Windows, Classes, Forms, Controls, Menus, MMsystem,
  Dialogs, StdCtrls, FTDIdll, FTDIchip, FTDItypes, import_files, Clipper, deviceselect, app_defaults;

type
  TFileBuffer = Array of byte;
   t_alivestates = (s_alive_responded, s_alive_wait_indef, s_alive_wait_timeout);

  procedure ExtractMessage(var my_str: String); // GRBL-Message in [] aufbereiten

  // holt und dekodiert "?"-Status
  function GetStatus: Boolean;

  procedure HandleZeroRequest(axis_mask: Integer);

  // überprüft Antwort auf Push-Message, ist TRUE wenn ja
  function CheckForPushmessage(var my_response: String):Boolean;

  procedure mdelay(const Milliseconds: DWord);
  procedure ShowAliveState(my_state: t_alivestates);

  function SetupFTDI: String;
  function InitFTDI(my_device:Integer; baud_str: String):String;
  function InitFTDIbySerial(my_serial: String; baud_str: String):String;

   // für Kommunikation nicht über FTDI, sondern über COM-port
  function CheckCom(my_ComNumber: Integer): Integer;   // COM# verfügbar?
  function COMOpen(com_name: String): Boolean;
  procedure COMRxClear;
  procedure COMClose;
  function COMSetup(baud_str: String): Boolean;
  function COMReceiveStr(timeout: DWORD): string;

  function grbl_checkResponse: Boolean;

  // fordert Maschinenstatus mit "?" an
  function grbl_statusStr: string;

  // GCode-String oder Char an GRBL senden, auf OK warten wenn my_getok = TRUE
  function grbl_sendStr(sendStr: String; my_getok: boolean): String;
  function grbl_sendWithShortTimeout(my_cmd: String): String;
  procedure grbl_sendRealTimeCmd(my_cmd: char);

  // GCode-String von GRBL holen, ggf. Timeout-Zeit warten:
  // ggf. Application.ProcessMessages während Warten ausführen
  function grbl_receiveStr(timeout: Integer): string;

  // gibt Anzahl der Zeichen im Empfangspuffer zurück:
  function grbl_receiveCount: Integer;

  // leert Empfangspuffer:
  procedure grbl_rx_clear;

  // GCode-String G92 x,y mit abschließendem CR an GRBL senden, auf OK warten:
  procedure grbl_offsXY(x, y: Double);
  // GCode-String G92 z mit abschließendem CR an GRBL senden, auf OK warten
  procedure grbl_offsZ(z: Double);


  // GCode-String G0 x,y mit abschließendem CR an GRBL senden, auf OK warten.
  // Maschinenkoordinaten wenn is_abs = TRUE
  procedure grbl_moveXY(x, y: Double; is_abs: Boolean);

  // GCode-String G0 z mit abschließendem CR an GRBL senden, auf OK warten.
  // Maschinenkoordinaten wenn is_abs = TRUE
  procedure grbl_moveZ(z: Double; is_abs: Boolean);
  procedure grbl_moveslowZ(z: Double; is_abs: Boolean);

  // GCode-String G1 x,y,f mit abschließendem CR an GRBL senden, auf OK warten:
  // F (speed) wird nur gesendet, wenn es sich geändert hat!
  procedure grbl_millXYF(x, y: Double; f: Integer);

  // GCode-String G1 x,y,f mit abschließendem CR an GRBL senden, auf OK warten:
  // F (speed) wird nur gesendet, wenn es sich geändert hat!
  procedure grbl_millXY(x, y: Double);

  // GCode-String G1 z mit abschließendem CR an GRBL senden, auf OK warten:
  // F (speed) wird nur gesendet, wenn es sich geändert hat!
  procedure grbl_millZF(z: Double; f: Integer);

  // GCode-String G1 z mit abschließendem CR an GRBL senden, auf OK warten:
  procedure grbl_millZ(z: Double);

  // GCode-String G1 x,y,z,f mit abschließendem CR an GRBL senden, auf OK warten:
  // F (speed) wird nur gesendet, wenn es sich geändert hat!
  procedure grbl_millXYZF(x, y, z: Double; f: Integer);

  // GCode-String G1 x,y,z mit abschließendem CR an GRBL senden, auf OK warten:
  procedure grbl_millXYZ(x, y, z: Double);

  // kompletten einzelnen Pfad fräsen, zurück bis Anfang wenn Closed
  procedure grbl_millpath(millpath: TPath; millpen: Integer; offset: TIntPoint; is_closedpoly: Boolean);

  // kompletten Pfad bohren, ggf. wiederholen bis z_end erreicht
  procedure grbl_drillpath(millpath: TPath; millpen: Integer; offset: TIntPoint);

  procedure grbl_checkXY(var x,y: Double);
  procedure grbl_checkZ(var z: Double);

  procedure grbl_wait_for_timeout(timeout: Integer);

type TStopWatch = class
   private
     fFrequency : TLargeInteger;
     fIsRunning: boolean;
     fIsHighResolution: boolean;
     fStartCount, fStopCount : TLargeInteger;
     procedure SetTickStamp(var lInt : TLargeInteger);
     function GetElapsedTicks: TLargeInteger;
     function GetElapsedMilliseconds: TLargeInteger;
     function GetCurrentMilliseconds : TLargeInteger;
   public
     constructor Create(const startOnCreate : boolean = false) ;
     procedure Start;
     procedure Stop;
     property IsHighResolution : boolean read fIsHighResolution;
     property ElapsedTicks : TLargeInteger read GetElapsedTicks;
     property ElapsedMilliseconds : TLargeInteger read GetElapsedMilliseconds;
     property CurrentMilliseconds : TLargeInteger read GetCurrentMilliseconds;
     property IsRunning : boolean read fIsRunning;
   end;


var
//FTDI-Device
  ftdi: Tftdichip;
  com_isopen, ftdi_isopen : Boolean;
  com_selected_port, ftdi_selected_device: Integer;  // FTDI-Frosch-Device-Nummer
  com_name, ftdi_serial: String;
  com_device_count, ftdi_device_count: dword;
  ftdi_device_list: pftdiDeviceList;
  ftdi_sernum_arr, ftdi_desc_arr: Array[0..15] of String;
  grbl_oldx, grbl_oldy, grbl_oldz: Double;
  grbl_oldf: Integer;
  grbl_sendlist: TSTringList;
  grbl_checksema: boolean;
  grbl_delay_short, grbl_delay_long: Word;
  ComFile: THandle;
  AliveIndicatorDirection: Boolean;
  AliveCount: Integer;
  LastAliveState: t_alivestates;
  grbl_is_connected: boolean;


implementation

uses grbl_player_main, glscene_view, drawing_window, Graphics;

{$I decodestatus_11.inc}
{$I decodestatus_09.inc}

// #############################################################################

procedure HandleZeroRequest(axis_mask: Integer);
// wenn Zero-Button auf Maschinen-Panel gedrückt
var my_str, my_response: String;

begin
  if axis_mask = 0 then
    exit;
  drawing_tool_down:= false;
  NeedsRedraw:= true;
  if HomingPerformed then with Form1 do begin
    TimerStatus.Enabled:= false;
    Memo1.lines.add('Zero request from machine panel');
    PlaySound('SYSTEMEXCLAMATION', 0, SND_ASYNC);
    if (axis_mask and 1 = 1) then begin
      WorkZero.X:= grbl_mpos.x;
      Jog.X:= WorkZero.X;
      my_str:= 'G92 X0';
      my_response:= uppercase(grbl_SendWithShortTimeout(my_str));
      Form1.Memo1.lines.add(my_str);
      WorkZeroXdone:= true;
    end;

    if (axis_mask and 2 = 2) then begin
      WorkZero.Y:= grbl_mpos.y;
      Jog.Y:= WorkZero.Y;
      my_str:= 'G92 Y0';
      my_response:= uppercase(grbl_SendWithShortTimeout(my_str));
      Form1.Memo1.lines.add(my_str);
      WorkZeroYdone:= true;
    end;

    if (axis_mask and 4 = 4) then begin
      Memo1.lines.add('Set Z pos to Z gauge height from Job Defaults');
      WorkZero.Z:= grbl_mpos.Z - job.z_gauge;
      Jog.Z:= WorkZero.Z;
      MposOnPartGauge:= grbl_mpos.Z;
      WorkZero.Z:= MposOnPartGauge - job.z_gauge;
      Form1.Memo1.lines.add('Cancel Tool Length Offset (TLO)');
      my_str:= 'G49';  // cancel tool offset
      my_response:= uppercase(grbl_SendWithShortTimeout(my_str));
      Form1.Memo1.lines.add(my_str);
      InvalidateTLCs;
      my_str:= 'G92 Z'+FloatToStrDot(job.z_gauge);
      my_response:= uppercase(grbl_SendWithShortTimeout(my_str));
      UpdateATC;
      Form1.Memo1.lines.add(my_str);
      WorkZeroZdone:= true;
    end;

    if (axis_mask and 8 = 8) then begin
      WorkZero.C:= grbl_mpos.C;
      Jog.C:= WorkZero.C;
      my_str:= 'G92 C0';
      my_response:= uppercase(grbl_SendWithShortTimeout(my_str));
      Form1.Memo1.lines.add(my_str);
      Jog.C:= WorkZero.C;
    end;

    InvalidateTLCs;
    repeat
      GetStatus; // muss eingetroffen sein
    until MachineState <> zero;
    TimerStatus.Enabled:= true;
  end else
    Form1.Memo1.lines.add('WARNING: Zero request ignored - no Home Cycle performed');
end;


procedure ExtractMessage(var my_str: String);
// GRBL-Message in [] aufbereiten
begin
  my_str:= StringReplace(my_str,'[','',[rfReplaceAll]);
  my_str:= StringReplace(my_str,']','',[rfReplaceAll]);
  my_str:= StringReplace(my_str,':',',',[rfReplaceAll]);
end;

function CheckForPushmessage(var my_response: String):Boolean;
// überprüft Antwort auf Push-Message oder ALARM, ist TRUE wenn ja
var zero_mask: Integer;
begin
  result:= false;
  if (pos('ALARM', my_response) > 0) then begin
    MachineState:= alarm;
    HomingPerformed:= false;
    result:= true;
  end;
  if (pos('[', my_response) > 0) then begin
    Form1.LabelResponse.Caption:= my_response;
    if AnsiContainsStr(my_response, 'Timeout') then begin
      inc(StatusFaultCounter);  // nicht angekommen
      exit;  // Timeout ist KEINE Push-Message
    end;
    Form1.Memo1.lines.add(my_response);
    zero_mask:= 0;
    if AnsiContainsStr(my_response, 'ZeroX') then
      zero_mask:= zero_mask or 1;
    if AnsiContainsStr(my_response, 'ZeroY') then
      zero_mask:= zero_mask or 2;
    if AnsiContainsStr(my_response, 'ZeroZ') then
      zero_mask:= zero_mask or 4;
    if AnsiContainsStr(my_response, 'ZeroC') then
      zero_mask:= zero_mask or 8;
    if AnsiContainsStr(my_response, 'ZeroAll') then
      zero_mask:= 15;
    if zero_mask > 0 then
      HandleZeroRequest(zero_mask);
    result:= true;
  end;
end;

// #############################################################################

constructor TStopWatch.Create(const startOnCreate : boolean = false) ;
begin
  inherited Create;

  fIsRunning := false;

  fIsHighResolution := QueryPerformanceFrequency(fFrequency);
  if not fIsHighResolution then
    fFrequency := MSecsPerSec;

  if startOnCreate then
    Start;
end;

function TStopWatch.GetElapsedTicks: TLargeInteger;
begin
  result := fStopCount - fStartCount;
end;

procedure TStopWatch.SetTickStamp(var lInt : TLargeInteger) ;
begin
  if fIsHighResolution then
     QueryPerformanceCounter(lInt)
   else
     lInt := MilliSecondOf(Now) ;
end;

function TStopWatch.GetElapsedMilliseconds: TLargeInteger;
// Millisekunden von StopWatch.Start bis StopWatch.Stop
begin
  result := (MSecsPerSec * (fStopCount - fStartCount)) div fFrequency;
end;

function TStopWatch.GetCurrentMilliseconds: TLargeInteger;
// aktuelle Millisekunden seit StopWatch.Start
var current_ticks: TLargeInteger;
begin
  SetTickStamp(current_ticks) ;
  result := (MSecsPerSec * (current_ticks - fStartCount)) div fFrequency;
end;

procedure TStopWatch.Start;
// Stoppuhr "starten" (d.h. fStartCount stetzen)
begin
  SetTickStamp(fStartCount) ;
  fIsRunning := true;
end;

procedure TStopWatch.Stop;
// Stoppuhr "anhalten" (d.h. fStopCount stetzen)
begin
  SetTickStamp(fStopCount) ;
  fIsRunning := false;
end;

// #############################################################################

procedure mdelay(const Milliseconds: DWord);
var
  FirstTickCount: DWord;
begin
  FirstTickCount := GetTickCount;
  while ((GetTickCount - FirstTickCount) < Milliseconds) do begin
    if StartupDone then
      Application.ProcessMessages;   // funktioniert bei CreateForm nicht!
    sleep(0);
  end;
end;

procedure ShowAliveState(my_state: t_alivestates);
begin
  LastAliveState:= my_state;
  with Form1 do
    case my_state of
      s_alive_responded:
        begin
          PanelAlive.Caption:='Resp OK';
          PanelAlive.Color:= (AliveCount shl 12) or clgreen;
        end;
      s_alive_wait_indef:
        begin
          PanelAlive.Caption:='Wait';
          PanelAlive.Color:= clred;
        end;
      s_alive_wait_timeout:
        begin
          PanelAlive.Caption:='Wait';
          PanelAlive.Color:= clred or clgreen;
        end;
    end;
  Form1.PanelAlive.Update;
end;


// #############################################################################

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


function COMOpen(com_name: String): Boolean;
var
  DeviceName: array[0..15] of Char;
  my_Name: AnsiString;
begin
// Wir versuchen, COM1 zu öffnen.
// Sollte dies fehlschlagen, gibt die Funktion false zurück.
  if length(com_name) > 4 then
    my_name:= AnsiString('\\.\'+com_name)  // COM10 und darüber
  else
    my_name:= AnsiString(com_name); // in AnsiSTring kopieren

  StrPCopy(DeviceName, my_name);
  ComFile := CreateFile(DeviceName, GENERIC_READ or GENERIC_WRITE,
    0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

  if ComFile = INVALID_HANDLE_VALUE then
    Result := False
  else
    Result := True;
end;


procedure COMClose;
// nicht vergessen den COM Port wieder zu schliessen!
begin
  CloseHandle(ComFile);
  com_isopen:= false;
end;


function COMReceiveCount: DWORD;
// Anzahl der Bytes im COM-Rx-Buffer
var Comstat: _Comstat;
    Errors: DWORD;
begin
  if ClearCommError(ComFile, Errors, @Comstat) then
    COMReceiveCount:= Comstat.cbInQue
  else
    COMReceiveCount:= 0;
  if GettickCount mod 10 = 0 then
    ShowAliveState(LastAliveState);
end;

procedure COMRxClear;
// evt. im Buffer stehende Daten löschen
begin
//  PurgeComm(ComFile,PURGE_TXCLEAR);
  PurgeComm(ComFile,PURGE_RXCLEAR);
end;

function COMSetup(baud_str: String): Boolean;
const
  RxBufferSize = 256;
  TxBufferSize = 256;
var
  DCB: TDCB;
  Config: AnsiString;
  CommTimeouts: TCommTimeouts;
begin
// wir gehen davon aus das das Einstellen des COM Ports funktioniert.
// sollte dies fehlschlagen wird der Rückgabewert auf "FALSE" gesetzt.
  Result := True;
  if not SetupComm(ComFile, RxBufferSize, TxBufferSize) then
    Result := False;
  if not GetCommState(ComFile, DCB) then
    Result := False;
  // hier die Baudrate, Parität usw. konfigurieren
  Config := 'baud' + baud_str + 'parity=n data=8 stop=1';
  if not BuildCommDCB(@Config[1], DCB) then
    Result := False;
  if not SetCommState(ComFile, DCB) then
    Result := False;
  with CommTimeouts do begin
    ReadIntervalTimeout         := 1;
    ReadTotalTimeoutMultiplier  := 1;
    ReadTotalTimeoutConstant    := 1000;
    WriteTotalTimeoutMultiplier := 1;
    WriteTotalTimeoutConstant   := 1000;
  end;
  if not SetCommTimeouts(ComFile, CommTimeouts) then
    Result := False;
end;

procedure COMSetTimeout(read_timeout: DWord);
var
  CommTimeouts: TCommTimeouts;
begin
  with CommTimeouts do begin
    ReadIntervalTimeout         := 0;
    ReadTotalTimeoutMultiplier  := 0;
    ReadTotalTimeoutConstant    := read_timeout;
    WriteTotalTimeoutMultiplier := 0;
    WriteTotalTimeoutConstant   := 1000;
  end;
  SetCommTimeouts(ComFile, CommTimeouts);
end;

function COMReadChar: Char;
var
  c: AnsiChar;
  BytesRead: DWORD;
begin
  Result := #0;
  if ReadFile(ComFile, c, 1, BytesRead, nil) then
    Result := char(c);
end;

// #############################################################################

function COMReceiveStr(timeout: DWORD): string;
// wartet unendlich, wenn timeout = 0
var
  my_str: AnsiString;
  i: Integer;
  my_char: Char;
  target_time, current_time: TLargeInteger;
  has_timeout: Boolean;
begin
  StopWatch.Start;
  COMSetTimeout(1);
  Result := '';
  my_str:= '';
  my_char:= #0;
  has_timeout:= timeout > 0;
  current_time:= StopWatch.GetCurrentMilliseconds;
  target_time := current_time + cardinal(timeout);
  repeat
    i:= COMReceiveCount;
    if i > 0 then begin
      my_char:= COMReadChar;
      if my_char >= #32 then
        my_str:= my_str + my_char;
    end else begin
      if StartupDone then
        Application.ProcessMessages;   // funktioniert bei CreateForm nicht!
      sleep(0);
    end;
    current_time:= StopWatch.GetCurrentMilliseconds;
  until (my_char= #10) or ((current_time > target_time) and has_timeout) or isWaitExit;
  if has_timeout then begin
    if (current_time > target_time) then begin
      my_str:= '[Timeout]';
    end;
  end;
  Result:= my_str;
end;

function COMsendStr(sendStr: String; my_getok: boolean): String;
// liefert "ok" wenn my_getok TRUE war und GRBL mit "ok" geantwortet hat
// String sollte mit #13 abgeschlossen sein, kann aber auch einzelnes
// GRBL-Steuerzeichen sein (?,!,~,CTRL-X)
var
  BytesWritten: DWORD;
  my_str: AnsiString;
begin
  my_str := AnsiString(sendStr);
  WriteFile(ComFile, my_str[1], Length(my_str), BytesWritten, nil);
  if my_getok then begin
    Result:= COMReceiveStr(0);
  end;
end;

// #############################################################################
// #############################################################################

function FTDIreceiveCount: Integer;
// gibt Anzahl der Zeichen im Empfangspuffer zurück
var i: Integer;
begin
  i:= 0;
  ftdi.getReceiveQueueStatus(i);
  Result:= i;
end;

procedure FTDIrxClear;
begin
  ftdi.purgeQueue(fReceiveQueue);
end;

function FTDIreceiveStr(timeout: Integer): string;
// wartet unendlich, wenn timeout = 0
var
  my_str: AnsiString;
  i: Integer;
  my_char: AnsiChar;
  target_time, current_time: TLargeInteger;
  has_timeout: Boolean;

begin
  StopWatch.Start;
  my_str:= '';
  has_timeout:= timeout > 0;
  current_time:= StopWatch.GetCurrentMilliseconds;
  target_time := current_time + cardinal(timeout);
  repeat
    i:= FTDIreceiveCount;
    if i > 0 then begin
      ftdi.read(@my_char, 1, i);
      if my_char >= #32 then
        my_str:= my_str + my_char;
    end else begin
      if StartupDone then
        Application.ProcessMessages;   // funktioniert bei CreateForm nicht!
      sleep(0);
    end;
    current_time:= StopWatch.GetCurrentMilliseconds;
  until (my_char= #10) or ((current_time > target_time) and has_timeout) or isWaitExit;
  if has_timeout then begin
    if (current_time > target_time) then begin
      my_str:= '[Timeout]';
    end;
  end;
  Result:= my_str;
end;

function FTDIsendStr(sendStr: String; my_getok: boolean): String;
// liefert "ok" wenn my_getok TRUE war und GRBL mit "ok" geantwortet hat
// String sollte mit #13 abgeschlossen sein, kann aber auch einzelnes
// GRBL-Steuerzeichen sein (?,!,~,CTRL-X)
var
  i: longint;
  my_str: AnsiString;
begin
  my_str:= AnsiString(sendStr);
  Result:= '';
  ftdi.write(@my_str[1], length(my_str), i);
  if my_getok then begin
    Result:= grbl_receiveStr(0);
  end;
end;

// #############################################################################
// Abhängig davon, ob FTDI oder COM benutzt wird, entsprechende Routine aufrufen
// #############################################################################

function grbl_receiveCount: Integer;
// gibt Anzahl der Zeichen im Empfangspuffer zurück
begin
  result:= 0;
  if ftdi_isopen then
    result:= FTDIreceiveCount;
  if com_isopen then
    result:= COMreceiveCount;
end;

procedure grbl_rx_clear;
begin
  if ftdi_isopen then
    FTDIrxClear;
  if com_isopen then
    COMRxClear;
end;

function grbl_receiveStr(timeout: Integer): string;
begin
  result:= '';
  repeat
    if ftdi_isopen then
      result:= FTDIreceiveStr(timeout);
    if com_isopen then
      result:= COMReceiveStr(timeout);
  until not CheckForPushmessage(result);
end;

function grbl_receiveStr_noCheck(timeout: Integer): string;
begin
  result:= '';
  if ftdi_isopen then
    result:= FTDIreceiveStr(timeout);
  if com_isopen then
    result:= COMReceiveStr(timeout);
end;

function grbl_sendStr(sendStr: String; my_getok: boolean): String;
// liefert TRUE wenn my_getok TRUE war und GRBL mit "ok" geantwortet hat
// String sollte mit #13 abgeschlossen sein, kann aber auch einzelnes
// GRBL-Steuerzeichen sein (?,!,~,CTRL-X)
begin
  result:= '';
  repeat
    if ftdi_isopen then
      result:= FTDIsendStr(sendStr, my_getok);
    if com_isopen then
      result:= COMsendStr(sendStr, my_getok);
  until not CheckForPushmessage(result);
end;


function grbl_SendWithShortTimeout(my_cmd: String): String;
// bei abgeschaltetem Status senden und empfangen
begin
  if isGRBLactive then begin
    grbl_SendStr(my_cmd + #13, false);
    repeat
      result:= grbl_receiveStr(25);
    until not CheckForPushmessage(result);
  end else
    result:= '';
end;

procedure grbl_SendRealTimeCmd(my_cmd: char);
// my_cmd wird bedingungslos gesendet, sobal eine Schnittstelle offen ist
begin
  if ftdi_isopen then
    FTDIsendStr(my_cmd, false);
  if com_isopen then
    COMsendStr(my_cmd, false);
end;

// #############################################################################
// #############################################################################

procedure grbl_wait_for_timeout(timeout: Integer);
var my_str: String;
begin
  if isGrblActive then
    repeat
      if StartupDone then
        Application.ProcessMessages;   // funktioniert bei CreateForm nicht!
      sleep(0);
      my_str:= grbl_receiveStr(timeout);
      CheckForPushmessage(my_str);
    until (my_str = '[Timeout]') or isEmergency or isWaitExit;
end;

function grbl_statusStr: string;
// fordert Maschinenstatus mit "?" an
begin
  grbl_SendRealTimeCmd('?'); // Status anfordern
  repeat
    result:= grbl_receiveStr(100);
  until not CheckForPushmessage(result);
end;

function grbl_checkResponse: Boolean;
var my_str1, my_str2: String;
  i, my_btn: Integer;
  sl_options: TSTringList;
  realtime_request_ok: Boolean;

begin
  ShowAliveState(s_alive_wait_timeout);
  my_str1:= '';
  result:= false;
  InitMachineOptions;
  if ftdi_isopen or com_isopen then begin
    DisableStatus;
    grbl_rx_clear;
    grbl_SendRealTimeCmd(#24);   // Soft Reset CTRL-X, Stepper sofort stoppen
    sleep(200);
    Form1.Memo1.lines.add('');
    Form1.Memo1.lines.add('Startup Message and Version Info:');
    repeat
      my_str1:= grbl_receiveStr_noCheck(500);
      CheckForPushmessage(my_str1);
    until my_Str1 = '[Timeout]';
    my_str1:= grbl_statusStr;
    realtime_request_ok:= AnsiContainsStr(my_str1, '>');
    if realtime_request_ok then begin
//      grbl_SendRealTimeCmd(#$D0);  // Enable device #0
      grbl_SendStr('$I' + #13, false);
      my_str1:= grbl_receiveStr_noCheck(100);
      my_str2:= grbl_receiveStr_noCheck(100);
      grbl_wait_for_timeout(50);
      if CheckForPushmessage(my_str1) then begin
        // get version info
        if AnsiContainsStr(my_str1, 'VER:1') then
          MachineOptions.NewGrblVersion:= true;
      end;
      sl_options:= TStringList.Create;
      if CheckForPushmessage(my_str2) then begin
        ExtractMessage(my_str2);
        // get Option list from GRBL 1.1
        if AnsiContainsStr(my_str2, 'OPT') then begin
          sl_options.CommaText:= my_str2;
          if sl_options.Count > 0 then begin
            if AnsiContainsStr(sl_options[1], 'V') then
              MachineOptions.VariableSpindle:= true;
            if AnsiContainsStr(sl_options[1], 'H') then
              MachineOptions.SingleAxisHoming:= true;
            if AnsiContainsStr(sl_options[1], 'M') then
              MachineOptions.MistCoolant:= true;
            if AnsiContainsStr(sl_options[1], 'H') then
              MachineOptions.SingleAxisHoming:= true;
            if AnsiContainsStr(sl_options[1], 'Z') then //  HOMING_FORCE_SET_ORIGIN
              MachineOptions.HomingOrigin:= true;
            // parse other GRBL compile options of 644 version
            for i:= 1 to sl_options.Count-1 do begin
               if sl_options[i] =  'SPI_SR' then
                MachineOptions.SPI:= true;
               if sl_options[i] =  'SPI_DISP' then
                MachineOptions.Display:= true;
               if sl_options[i] =  'PANEL' then
                MachineOptions.Panel:= true;
               if sl_options[i] =  'C_AXIS' then
                MachineOptions.Caxis:= true;
            end;
          end;
        end;
      end;
      sl_options.Free;
    end;

    if MachineOptions.HomingOrigin <> get_AppDefaults_bool(45) then begin
    // Positive Maschinenrichtung?
      PlaySound('SYSTEMHAND', 0, SND_ASYNC);
      Form1.Memo1.lines.add('');
      Form1.Memo1.lines.add('WARNING: GRBL option HOMING_FORCE_SET_ORIGIN detected.');
      Form1.Memo1.lines.add('Please set positive machine space in App Defaults,');
      Form1.Memo1.lines.add('otherwise jog functions will not work properly.');
    end;
    MachineOptions.PositiveSpace:= get_AppDefaults_bool(45);
    HomingPerformed:= false;
    MachineState:= none;
    grbl_wait_for_timeout(50);
    GetStatus;
    grbl_wait_for_timeout(50);

    case MachineState of
      alarm:
        begin
          // Nach Neustart immer Alarm wg. Homing Lock
          PlaySound('SYSTEMHAND', 0, SND_ASYNC);
          Form1.Memo1.lines.add('');
          Form1.Memo1.lines.add('WARNING: Alarm state, machine not homed!');
          Form1.Memo1.lines.add('Press HOME CYCLE on machine panel');
          Form1.Memo1.lines.add('or Machine Control page.');
          result:= true; // Homing ermöglichen
        end;
      hold:
        begin
          PlaySound('SYSTEMHAND', 0, SND_ASYNC);
          Form1.Memo1.lines.add('');
          Form1.Memo1.lines.add('ERROR: Machine on HOLD.');
          Form1.Memo1.lines.add('Press CONTINUE or RESET on machine panel.');
          Form1.Memo1.lines.add('Try connecting again.');
        end;
      idle:
        begin
          grbl_SendRealTimeCmd(#13);
          my_str1:= ansiuppercase(grbl_receiveStr_noCheck(20));
          if (pos('OK',my_str1) > 0) then begin
            result:= true;
            HomingPerformed:= true;
            Form1.Memo1.lines.add('');
            Form1.Memo1.lines.add('Machine ready.')
          end else begin
            Form1.Memo1.lines.add('');
            PlaySound('SYSTEMHAND', 0, SND_ASYNC);
            Form1.Memo1.lines.add('ERROR: GRBL resync failed.');
            Form1.Memo1.lines.add('Try connecting again.');
          end;
        end;
    else begin
        PlaySound('SYSTEMHAND', 0, SND_ASYNC);
        Form1.Memo1.lines.add('');
        Form1.Memo1.lines.add('ERROR: Communication fault');
        Form1.Memo1.lines.add('Invalid response or wrong GRBL version.');
        Form1.Memo1.lines.add('Try connecting again.');
        Form1.BtnCloseClick(nil);
      end;
    end;
    if result then
      EnableStatus;
  end;
  ShowAliveState(s_alive_responded);
end;

// #############################################################################
// Highlevel-Funktionen
// #############################################################################


function GetStatus: Boolean;
begin
  if MachineOptions.NewGrblVersion then
    result:= GetStatus11
  else
    result:= GetStatus09;
end;

procedure grbl_checkZ(var z: Double);
// limits z to upper limit
begin
// gilt auch für MachineOptions.PositiveSpace=true!
  if WorkZero.Z + z > -1 then
    z:= - WorkZero.Z -1;
  if WorkZero.Z + z < -job.table_Z then
    z:= -WorkZero.Z - job.table_Z;
end;

procedure grbl_checkXY(var x,y: Double);
// limits xy to machine limits
begin
  if MachineOptions.PositiveSpace then begin
    if WorkZero.X + x < 0 then
      x:= - WorkZero.X;
    if WorkZero.X + x > job.table_X then
      x:= job.table_X - WorkZero.X;
    if WorkZero.Y + y < 0 then
      y:= - WorkZero.Y;
    if WorkZero.Y + Y > job.table_Y then
      y:= job.table_Y - WorkZero.Y;
  end;
end;

procedure grbl_offsXY(x, y: Double);
// GCode-String G92 x,y mit abschließendem CR an GRBL senden, auf OK warten
begin
  grbl_sendlist.add('G92 X'+ FloatToSTrDot(x)+' Y'+ FloatToSTrDot(y));
end;

procedure grbl_offsZ(z: Double);
// GCode-String G92 z mit abschließendem CR an GRBL senden, auf OK warten
// Z mit Tool-Offset versehen
begin
  grbl_sendlist.add('G92 Z'+ FloatToSTrDot(z));
end;

procedure grbl_moveXY(x, y: Double; is_abs: Boolean);
// GCode-String G0 x,y mit abschließendem CR an GRBL senden, auf OK warten
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
  grbl_sendlist.add(my_str);
end;

procedure grbl_moveZ(z: Double; is_abs: Boolean);
// GCode-String G0 z mit abschließendem CR an GRBL senden, auf OK warten
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
  grbl_sendlist.add(my_str);
end;

procedure grbl_moveslowZ(z: Double; is_abs: Boolean);
// GCode-String G1 z mit abschließendem CR an GRBL senden, auf OK warten
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
  grbl_sendlist.add(my_str);
end;

procedure grbl_millXYF(x, y: Double; f: Integer);
// GCode-String G0 x,y mit abschließendem CR an GRBL senden, auf OK warten
// F (speed) wird nur gesendet, wenn es sich geändert hat!
var my_str: String;
begin
  grbl_checkXY(x,y);
  my_str:= 'G1 X'+ FloatToSTrDot(x)+' Y'+ FloatToSTrDot(y);
  if f <> grbl_oldf then
    my_str:= my_str + ' F' + IntToStr(f);
  grbl_sendlist.add(my_str);
  grbl_oldf:= f;
  grbl_oldx:= x;
  grbl_oldy:= y;
end;

procedure grbl_millXY(x, y: Double);
// GCode-String G0 x,y mit abschließendem CR an GRBL senden, auf OK warten
// XY-Werte werden nur gesendet, wenn sie sich geändert haben!
var my_str: String;
begin
  grbl_checkXY(x,y);
  my_str:= 'G1';
  if x <> grbl_oldx then
    my_str:= my_str + ' X'+ FloatToSTrDot(x);
  if y <> grbl_oldy then
    my_str:= my_str + ' Y'+ FloatToSTrDot(y);
  grbl_sendlist.add(my_str);
  grbl_oldx:= x;
  grbl_oldy:= y;
end;

procedure grbl_millZF(z: Double; f: Integer);
// GCode-String G0 x,y mit abschließendem CR an GRBL senden, auf OK warten
// F (speed) wird hier immer neu gesetzt wg. möglichem GRBL-Z-Scaling
var my_str: String;
begin
  grbl_checkZ(z);
  my_str:= 'G1 Z'+ FloatToSTrDot(z) + ' F' + IntToStr(f);
  grbl_sendlist.add(my_str);
  grbl_oldf:= f;
  grbl_oldz:= z;
end;

procedure grbl_millZ(z: Double);
// GCode-String G0 x,y mit abschließendem CR an GRBL senden, auf OK warten
var my_str: String;
begin
  grbl_checkZ(z);
  my_str:= 'G1 Z'+ FloatToSTrDot(z);
  grbl_sendlist.add(my_str);
  grbl_oldz:= z;
end;

procedure grbl_millXYZF(x, y, z: Double; f: Integer);
// GCode-String G0 x,y mit abschließendem CR an GRBL senden, auf OK warten
// F (speed) wird nur gesendet, wenn es sich geändert hat!
var my_str: String;
begin
  grbl_checkZ(z);
  grbl_checkXY(x,y);
  my_str:= 'G1 X' + FloatToSTrDot(x) +' Y'+ FloatToSTrDot(y) +' Z' + FloatToSTrDot(z);
  if f <> grbl_oldf then
    my_str:= my_str + ' F' + IntToStr(f);
  grbl_sendlist.add(my_str);
  grbl_oldf:= f;
  grbl_oldx:= x;
  grbl_oldy:= y;
  grbl_oldz:= z;
end;

procedure grbl_millXYZ(x, y, z: Double);
// GCode-String G0 x,y mit abschließendem CR an GRBL senden, auf OK warten
// XYZ-Werte werden nur gesendet, wenn sie sich geändert haben!
var my_str: String;
begin
  grbl_checkZ(z);
  grbl_checkXY(x,y);
  my_str:= 'G1';
  if x <> grbl_oldx then
    my_str:= my_str + ' X'+ FloatToSTrDot(x);
  if y <> grbl_oldy then
    my_str:= my_str + ' Y'+ FloatToSTrDot(y);
  if z <> grbl_oldz then
    my_str:= my_str + ' Z'+ FloatToSTrDot(z);
  grbl_sendlist.add(my_str);
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
    grbl_moveZ(job.z_penup, false);
    x:= (millpath[i].x + offset.x) / c_hpgl_scale;
    y:= (millpath[i].y + offset.y) / c_hpgl_scale;
    grbl_moveXY(x,y,false);
    z:= 0;
    my_z_feed:= job.pens[millpen].speed; // Feed des gewählten Pens
{
    if my_z_feed > job.z_feed then
      my_z_feed:= job.z_feed;
}
    if i mod 25 = 0 then
      Application.ProcessMessages;
    repeat
      grbl_moveZ(0.5, false); // annähern auf 0,5 mm über Oberfläche
      z:= z - job.pens[millpen].z_inc;
      if z < my_z_end then
        z:= my_z_end;
      grbl_millZF(z, my_z_feed);
    until (z <= my_z_end) or isCancelled;
  end;
  grbl_moveZ(job.z_penup, false);
end;


procedure grbl_millpath(millpath: TPath; millpen: Integer; offset: TIntPoint; is_closedpoly: Boolean);
// kompletten Pfad fräsen, ggf. wiederholen bis z_end erreicht
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
    grbl_moveZ(job.z_penup, false);
    x:= (millpath[0].x + offset.x) / c_hpgl_scale;
    y:= (millpath[0].y + offset.y) / c_hpgl_scale;
    grbl_moveXY(x,y, false);
    grbl_moveZ(0.5, false); // annähern auf 0,5 mm über Oberfläche

    my_z_feed:= job.pens[millpen].speed;
    if my_z_feed > job.z_feed then
      my_z_feed:= job.z_feed;
    grbl_millZF(z, my_z_feed); // langsam eintauchen
    for i:= 1 to my_len - 1 do begin
      x:= (millpath[i].x + offset.x) / c_hpgl_scale;
      y:= (millpath[i].y + offset.y) / c_hpgl_scale;
      grbl_millXYF(x,y, job.pens[millpen].speed);
      if isCancelled then
        break;
    end;
    if is_closedpoly and (not isCancelled) then begin
      x:= (millpath[0].x + offset.x) / c_hpgl_scale;
      y:= (millpath[0].y + offset.y) / c_hpgl_scale;
      grbl_millXYF(x,y, job.pens[millpen].speed);
    end;

  until (my_z_limit <= my_z_end) or isCancelled;
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
    result:= 'Failed to create device info list';
    freeandnil(ftdi);
    exit;
  end;
  { Iterate through the device list that was returned }
  if ftdi_device_count > 0 then begin
    result:= InttoStr (ftdi_device_count) +  ' FTDI device(s) found';
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
    result:= 'No FTDI devices found';
end;

procedure SetFTDIbaudRate(my_str: String);
var
  my_baud: fBaudRate;
begin
  if ftdi_isopen then
    exit;
  ftdi_isopen:= true;
  my_str:= trim(my_str);
  if my_str = '9600' then
    my_baud:= fBaud9600
  else if my_str = '19200' then
    my_baud:= fBaud19200
  else if my_str = '38400' then
    my_baud:= fBaud38400
  else if my_str = '57600' then
    my_baud:= fBaud57600
  else
    my_baud:= fBaud115200;
  ftdi.setBaudRate(my_baud);
  ftdi.setDataCharacteristics(fBits8, fStopBits1, fParityNone);
  ftdi.setFlowControl(fFlowNone, 0, 0);
end;

function InitFTDI(my_device:Integer; baud_str: String):String;
begin
// Check if device is present
  if ftdi_isopen then
    exit;
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
    SetFTDIbaudRate(baud_str);
    result:= 'USB connected';
  end else
    result:= 'Reset error';
end;

function InitFTDIbySerial(my_serial, baud_str: String):String;
begin
  if ftdi_isopen then
    exit;
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
      SetFTDIbaudRate(baud_str);
      result:= 'USB connected';
    end else
      result:= 'Reset error';
  end;
end;

end.
