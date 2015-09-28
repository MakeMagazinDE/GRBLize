{ ----------------------------------------------------------------------------
  FTDI D2XX class wrapper
  Copyright (c) Michael "Zipplet" Nixon 2009.
  Licensed under the MIT license, see license.txt in the project trunk.

  Unit: FTDIchip.pas
  Purpose: FTDI chip class
  ---------------------------------------------------------------------------- }
unit FTDIchip;

{ ----------------------------------------------------------------------------
  ---------------------------------------------------------------------------- }

interface

uses
  sysutils, windows, messages, classes, bsearchtree, blinklist,
  FTDItypes, FTDIthread, FTDIdll;

type
  { -------- FTDI class ------------------------------------------------------ }
  tftdichip = class(tobject)
    { -------- Props --------------------------------------------------------- }

    { Handle to FTDI device }
    fhandle: ft_handle;

    { Are we connected to the device? }
    fconnected: boolean;

    { Event handlers used for async comms }
    e_onReceiveData: tftdievent_onReceiveData;
    e_onSendQueueEmpty: tftdievent_onSendQueueEmpty;
    e_onError: tftdievent_onError;

    { Reference to our thread class }
    thread: tftdithread;

    { Has data been sent? (used for OnSendQueueEmpty event) }
    dataHasBeenSent: boolean;

    { -------- Device functions  --------------------------------------------- }
    function isPresentByDescription(deviceDescription: string): boolean;
    function openDeviceByDescription(deviceDescription: string): boolean;
    function isPresentBySerial(deviceSerial: string): boolean;
    function openDeviceBySerial(deviceSerial: string): boolean;
    procedure closeDevice;
    function resetDevice: boolean;
    function cycleDevice: boolean;
    function setLatencyTimer(millisecs: byte): boolean;

    { -------- Comm control -------------------------------------------------- }
    function setBaudRate(baudrate: fBaudRate): boolean;
    function setBaudRateEx(baudrate: dword): boolean;
    function setDataCharacteristics(wordLength: fWordLength; stopBits: fStopBits; parity: fParity): boolean;
    function setFlowControl(flowcontrol: fFlowControl; xonChar, xoffChar: byte): boolean;
    function setTimeouts(readTimeout, writeTimeout: dword): boolean;

    { -------- Enumeration --------------------------------------------------- }
    function getDeviceInfo(var device: fDevice; var pid, vid: word; var serialnumber, description: string): boolean;
    function createDeviceInfoList(var devicecount: dword; var devicelist: pftdidevicelist): boolean;
    procedure destroyDeviceInfoList(var devicelist: pftdidevicelist);

    { -------- I/O ----------------------------------------------------------- }
    function read(buffer: pointer; bytesToRead: longint; var bytesRead: longint): boolean;
    function write(buffer: pointer; bytesToWrite: longint; var bytesWritten: longint): boolean;

    { -------- Queues -------------------------------------------------------- }
    function getReceiveQueueStatus(var bytesWaiting: longint): boolean;
    function getSendQueueStatus(var bytesWaiting: longint): boolean;
    function purgeQueue(queue: fQueue): boolean;

    { -------- Event object -------------------------------------------------- }
    function createEventObject(event: fEvent; var eventHandle: thandle): boolean;
    function waitForEventObject(var eventhandle: thandle; timeout: cardinal): fEvent;
    procedure closeEventObject(var eventhandle: thandle);

    { -------- Asynchronous comms ^_^ ---------------------------------------- }
    function setupCommEvents(onReceiveData: tftdievent_onReceiveData;
                             onSendQueueEmpty: tftdievent_OnSendQueueEmpty;
                             onError: tftdievent_onError): boolean;
    function stopCommEvents: boolean;
    function startCommEvents: boolean;

    { -------- Comm lines ---------------------------------------------------- }
    function getCTS: boolean;
    function getDSR: boolean;
    function getRI: boolean;
    function getDCD: boolean;

    function setDTR: boolean;
    function clearDTR: boolean;
    function setRTS: boolean;
    function clearRTS: boolean;

    { -------- Class --------------------------------------------------------- }
    constructor create;
    destructor destroy; override;
  end;

implementation

{ ----------------------------------------------------------------------------
  Create a list of FTDI devices currently attached to the system.
  <devicecount> is set to the number of FTDI devices found
  <devicelist> is a pointer to an array of ftdiDeviceNode records.
  If <devicecount> is 0, then <devicelist> is not allocated.
  This function allocates the device list.
  Returns TRUE on success.
  ---------------------------------------------------------------------------- }
function tftdichip.createDeviceInfoList(var devicecount: dword; var devicelist: pftdidevicelist): boolean;
var
  res: ft_result;
begin
  result := false;

  { Create the device list }
  res := FT_CreateDeviceInfoList(@devicecount);
  if res <> FT_OK then exit;

  { Are there any devices? }
  if devicecount > 0 then begin
    { Yes. Allocate space for the list }
    getmem(devicelist, sizeof(ftdiDeviceNode) * devicecount);
    { Grab the list }
    res := FT_GetDeviceInfoList(devicelist, @devicecount);
    { Just to be sure we check for errors }
    if res <> FT_OK then begin
      freemem(devicelist);
      devicelist := nil;
      devicecount := 0;
      exit;
    end;
  end else begin
    { No devices so return empty list }
    devicelist := nil;
  end;

  result := true;
end;

{ ----------------------------------------------------------------------------
  Destroy a previously created device info list
  ---------------------------------------------------------------------------- }
procedure tftdichip.destroyDeviceInfoList(var devicelist: pftdidevicelist);
begin
  freemem(devicelist);
  devicelist := nil;
end;

{ ----------------------------------------------------------------------------
  FTDI chip constructor
  ---------------------------------------------------------------------------- }
constructor tftdichip.create;
begin
  inherited create;

  { Set a sane default state }
  fconnected := false;
  e_onReceiveData := nil;
  e_onSendQueueEmpty := nil;
  e_onError := nil;
  dataHasBeenSent := false;
end;

{ ----------------------------------------------------------------------------
  FTDI chip destructor
  ---------------------------------------------------------------------------- }
destructor tftdichip.destroy;
begin
  { We must stop the comm events (thread) if it is in use }
  self.stopCommEvents;
  inherited destroy;
end;

{ ----------------------------------------------------------------------------
  See if we can find a connected FTDI chip that matches the deviceDescription
  given. If we find it, return TRUE else FALSE.
  ---------------------------------------------------------------------------- }
function tftdichip.isPresentByDescription(deviceDescription: string): boolean;
var
  hnd: ft_handle;
  res: ft_result;
  my_str: AnsiString;
begin
  { Default to failing }
  result := false;
  my_str:= deviceDescription;
  { Try to open the device by description }
  res := FT_OpenEx(pAnsichar(deviceDescription), FT_OPEN_BY_DESCRIPTION, @hnd);

  { If it failed exit, otherwise close device and return TRUE }
  if res <> FT_OK then exit;
  FT_Close(hnd);
  result := true;
end;

{ ----------------------------------------------------------------------------
  Open an FTDI device by description. Returns TRUE on success otherwise FALSE.
  ---------------------------------------------------------------------------- }
function tftdichip.openDeviceByDescription(deviceDescription: string): boolean;
var
  res: ft_result;
  my_str: AnsiString;
begin
  if fconnected then begin
    raise exception.Create('tftdichip.openDeviceByDescription: Already open');
    exit;
  end;

  { Default to failing }
  result := false;
  my_str:= deviceDescription;

  { Try to open the device by description }
  res := FT_OpenEx(pAnsichar(my_str), FT_OPEN_BY_DESCRIPTION, @self.fhandle);

  { If it failed exit, otherwise close device and return TRUE }
  if res <> FT_OK then exit;
  result := true;
  fconnected := true;
end;

{ ----------------------------------------------------------------------------
  Close FTDI device
  ---------------------------------------------------------------------------- }
procedure tftdichip.closeDevice;
begin
  if not fconnected then begin
    raise exception.Create('tftdichip.closeDevice: Not open');
    exit;
  end;
  if assigned(self.thread) then self.stopCommEvents;
  FT_Close(self.fhandle);
  fconnected := false;
end;

{ ----------------------------------------------------------------------------
  Set the baud rate
  ---------------------------------------------------------------------------- }
function tftdichip.setBaudRate(baudrate: fBaudRate): boolean;
var
  res: ft_result;
  tmp: dword;
begin
  { Select baudrate }
  case baudrate of
    fBaud300: tmp := FT_BAUD_300;
    fBaud600: tmp := FT_BAUD_600;
    fBaud1200: tmp := FT_BAUD_1200;
    fBaud2400: tmp := FT_BAUD_2400;
    fBaud4800: tmp := FT_BAUD_4800;
    fBaud9600: tmp := FT_BAUD_9600;
    fBaud14400: tmp := FT_BAUD_14400;
    fBaud19200: tmp := FT_BAUD_19200;
    fBaud38400: tmp := FT_BAUD_38400;
    fBaud57600: tmp := FT_BAUD_57600;
    fBaud115200: tmp := FT_BAUD_115200;
    fBaud230400: tmp := FT_BAUD_230400;
    fBaud460800: tmp := FT_BAUD_460800;
    fBaud921600: tmp := FT_BAUD_921600;
  else
    raise exception.Create('tftdichip.setBaudRate: Invalid baud rate');
  end;

  { Do it! }
  res := FT_SetBaudRate(self.fhandle, tmp);
  result := false;
  if res = FT_OK then result := true;
end;

{ ----------------------------------------------------------------------------
  Set the baud rate to a nonstandard value
  ---------------------------------------------------------------------------- }
function tftdichip.setBaudRateEx(baudrate: dword): boolean;
var
  res: ft_result;
begin
  res := FT_SetBaudRate(self.fhandle, baudrate);
  result := false;
  if res = FT_OK then result := true;
end;

{ ----------------------------------------------------------------------------
  Set the data characteristics
  ---------------------------------------------------------------------------- }
function tftdichip.setDataCharacteristics(wordLength: fWordLength; stopBits: fStopBits; parity: fParity): boolean;
var
  res: ft_result;
  ta, tb, tc: byte;
begin
  { Build settings from enums }
  case wordLength of
    fBits8: ta := FT_DATA_BITS_8;
    fBits7: ta := FT_DATA_BITS_7;
  else
    raise exception.create('tftdichip.setDataCharacteristics: Invalid wordLength');
  end;
  case stopBits of
    fStopBits1: tb := FT_STOP_BITS_1;
    fStopBits2: tb := FT_STOP_BITS_2;
  else
    raise exception.create('tftdichip.setDataCharacteristics: Invalid stopBits');
  end;
  case parity of
    fParityNone: tc := FT_PARITY_NONE;
    fParityOdd: tc := FT_PARITY_ODD;
    fParityEven: tc := FT_PARITY_EVEN;
    fParityMark: tc := FT_PARITY_MARK;
    fParitySpace: tc := FT_PARITY_SPACE;
  else
    raise exception.create('tftdichip.setDataCharacteristics: Invalid parity');
  end;

  res := FT_SetDataCharacteristics(self.fhandle, ta, tb, tc);
  result := false;
  if res = FT_OK then result := true;
end;

{ ----------------------------------------------------------------------------
  Set flow control
  ---------------------------------------------------------------------------- }
function tftdichip.setFlowControl(flowcontrol: fFlowControl; xonChar, xoffChar: byte): boolean;
var
  res: ft_result;
  tmp: word;
begin
  case flowcontrol of
    fFlowNone: tmp := FT_FLOW_NONE;
    fFlowRTSCTS: tmp := FT_FLOW_RTS_CTS;
    fFlowDTRDSR: tmp := FT_FLOW_DTR_DSR;
    fFlowXONXOFF: tmp := FT_FLOW_XON_XOFF;
  else
    raise exception.create('tftdichip.setFlowControl: Invalid flowcontrol');
  end;
  res := FT_SetFlowControl(self.fhandle, tmp, xonChar, xoffChar);
  result := false;
  if res = FT_OK then result := true;
end;

{ ----------------------------------------------------------------------------
  Read up to <bytesRead> bytes from the device. Sets <bytesRead> to the number
  of bytes read. Returns TRUE on success or FALSE on a fatal error such as
  USB disconnected.
  This function blocks until the timeout set.
  ---------------------------------------------------------------------------- }
function tftdichip.read(buffer: pointer; bytesToRead: longint; var bytesRead: longint): boolean;
var
  res: ft_result;
begin
  res := FT_Read(self.fhandle, buffer, bytesToRead, @BytesRead);
  result := false;
  if res = FT_OK then result := true;
end;

{ ----------------------------------------------------------------------------
  Writes up to <bytesWritten> bytes to the device. Sets <bytesWritten> to the number
  of bytes written. Returns TRUE on success or FALSE on a fatal error such as
  USB disconnected.
  ---------------------------------------------------------------------------- }
function tftdichip.write(buffer: pointer; bytesToWrite: longint; var bytesWritten: longint): boolean;
var
  res: ft_result;
begin
  res := FT_Write(self.fhandle, buffer, bytesToWrite, @BytesWritten);
  result := false;
  if res = FT_OK then begin
    { We use dataHasBeenSent to keep track of the fact we actually have sent some
      data. Without this, the OnSendQueueEmpty event would fire indefinately as
      the queue would be empty most of the time }
    self.dataHasBeenSent := true;
    result := true;
  end;
end;

{ ----------------------------------------------------------------------------
  Reset chip. True on success.
  ---------------------------------------------------------------------------- }
function tftdichip.resetDevice: boolean;
var
  res: ft_result;
begin
  res := FT_ResetDevice(fhandle);
  result := false;
  if res = FT_OK then result := true;
end;

{ ----------------------------------------------------------------------------
  Sets <bytesWaiting> to the number of bytes waiting to be read from the
  receive queue. TRUE on success.
  ---------------------------------------------------------------------------- }
function tftdichip.getReceiveQueueStatus(var bytesWaiting: longint): boolean;
var
  res: ft_result;
begin
  res := FT_GetQueueStatus(fhandle, @bytesWaiting);
  result := false;
  if res = FT_OK then result := true;
end;

{ ----------------------------------------------------------------------------
  Sets <bytesWaiting> to the number of bytes waiting to be sent from the
  send queue. TRUE on success.
  ---------------------------------------------------------------------------- }
function tftdichip.getSendQueueStatus(var bytesWaiting: longint): boolean;
var
  res: ft_result;
  i, a: longint;
begin
  res := FT_GetStatus(self.fhandle, @i, @bytesWaiting, @a);
  result := false;
  if res = FT_OK then result := true;
end;

{ ----------------------------------------------------------------------------
  Return status of the CTS (Clear To Send) input
  ---------------------------------------------------------------------------- }
function tftdichip.getCTS: boolean;
var
  i: dword;
begin
  if (FT_GetModemStatus(self.fhandle, @i) <> FT_OK) then begin
    raise exception.create('tftdichip.getCTS: Error');
    exit;
  end;
  if (i and CTS) <> 0 then result := true else result := false;
end;

{ ----------------------------------------------------------------------------
  Return status of the DSR (Data Set Ready) input
  ---------------------------------------------------------------------------- }
function tftdichip.getDSR: boolean;
var
  i: dword;
begin
  if (FT_GetModemStatus(self.fhandle, @i) <> FT_OK) then begin
    raise exception.create('tftdichip.getDSR: Error');
    exit;
  end;
  if (i and DSR) <> 0 then result := true else result := false;
end;

{ ----------------------------------------------------------------------------
  Return status of the RI (Ring Indicator) input
  ---------------------------------------------------------------------------- }
function tftdichip.getRI: boolean;
var
  i: dword;
begin
  if (FT_GetModemStatus(self.fhandle, @i) <> FT_OK) then begin
    raise exception.create('tftdichip.getRI: Error');
    exit;
  end;
  if (i and RI) <> 0 then result := true else result := false;
end;

{ ----------------------------------------------------------------------------
  Return status of the DCD (Data Carrier Detect) input
  ---------------------------------------------------------------------------- }
function tftdichip.getDCD: boolean;
var
  i: dword;
begin
  if (FT_GetModemStatus(self.fhandle, @i) <> FT_OK) then begin
    raise exception.create('tftdichip.getDCD: Error');
    exit;
  end;
  if (i and DCD) <> 0 then result := true else result := false;
end;

{ ----------------------------------------------------------------------------
  Assert the DTR signal
  ---------------------------------------------------------------------------- }
function tftdichip.setDTR: boolean;
var
  res: ft_result;
begin
  res := FT_SetDTR(fhandle);
  if res <> FT_OK then result := false else result := true;
end;

{ ----------------------------------------------------------------------------
  Clear the DTR signal
  ---------------------------------------------------------------------------- }
function tftdichip.clearDTR: boolean;
var
  res: ft_result;
begin
  res := FT_ClrDTR(fhandle);
  if res <> FT_OK then result := false else result := true;
end;

{ ----------------------------------------------------------------------------
  Assert the RTS signal
  ---------------------------------------------------------------------------- }
function tftdichip.setRTS: boolean;
var
  res: ft_result;
begin
  res := FT_SetRTS(fhandle);
  if res <> FT_OK then result := false else result := true;
end;

{ ----------------------------------------------------------------------------
  Clear the RTS signal
  ---------------------------------------------------------------------------- }
function tftdichip.clearRTS: boolean;
var
  res: ft_result;
begin
  res := FT_ClrRTS(fhandle);
  if res <> FT_OK then result := false else result := true;
end;

{ ----------------------------------------------------------------------------
  Purge the send, receive or both queues
  ---------------------------------------------------------------------------- }
function tftdichip.purgeQueue(queue: fQueue): boolean;
var
  res: ft_result;
begin
  { Purge queue depending on enum }
  case queue of
    fSendQueue: res := FT_Purge(fhandle, FT_PURGE_TX);
    fReceiveQueue: res := FT_Purge(fhandle, FT_PURGE_RX);
    fAll: res := FT_Purge(fhandle, FT_PURGE_RX or FT_PURGE_TX);
  else
    raise exception.create('tftdichip.purgeQueue: Invalid queue');
  end;

  if res <> FT_OK then result := false else result := true;
end;

{ ----------------------------------------------------------------------------
  Set timeouts in milliseconds for reading and writing
  ---------------------------------------------------------------------------- }
function tftdichip.setTimeouts(readTimeout, writeTimeout: dword): boolean;
var
  res: ft_result;
begin
  res := FT_SetTimeouts(self.fhandle, readtimeout, writetimeout);
  if res <> FT_OK then result := false else result := true;
end;

{ ----------------------------------------------------------------------------
  Get device info about the currently open device.
  Returns device type, product ID, vendor ID, serial string, description string
  TRUE on success
  ---------------------------------------------------------------------------- }
function tftdichip.getDeviceInfo(var device: fDevice; var pid, vid: word; var serialnumber, description: string): boolean;
var
  res: ft_result;
  s1: array[0..16] of AnsiChar;
  s2: array[0..64] of AnsiChar;
  dtype, did: cardinal;
  my_serstr, my_descstr: AnsiString;

begin
  { Get the device info from FTDI }
  res := FT_GetDeviceInfo(self.fhandle, @dtype, @did, @s1, @s2, nil);

  { Nicely format it for the caller }
  my_serstr := AnsiString(pAnsiChar(@s1[0]));
  my_descstr := AnsiString(pAnsiChar(@s2[0]));

{$IFDEF UNICODE}
  description := UnicodeString(my_serstr);
  serialnumber:= UnicodeString(my_descstr);
{$ELSE}
  description := my_serstr;
  serialnumber:= my_descstr;
{$ENDIF}
  vid := (did shr 16) and $FFFF;
  pid := did and $FFFF;
  case dtype of
    FT_DEVICE_232BM: device := fDevice232BM;
    FT_DEVICE_232AM: device := fDevice232AM;
    FT_DEVICE_100AX: device := fDevice100AX;
    FT_DEVICE_2232C: device := fDevice2232C;
    FT_DEVICE_232R: device := fDevice232R;
  else
    device := fDeviceUnknown
  end;
  if res <> FT_OK then result := false else result := true;
end;


{ ----------------------------------------------------------------------------
  Cycle the device (makes it disconnect then reconnect to USB controller)
  TRUE on success.
  ---------------------------------------------------------------------------- }
function tftdichip.cycleDevice: boolean;
var
  res: ft_result;
begin
  res := FT_CyclePort(self.fhandle);
  if res <> FT_OK then result := false else result := true;
end;

{ ----------------------------------------------------------------------------
  Creates an event object that will trigger on events matching <event>. The
  type of handle returned is a windows event handle - use WaitForSingleObject.
  TRUE on success.

  THIS CALL MUST BE THREAD SAFE as the ftdi comms thread uses it.
  ---------------------------------------------------------------------------- }
function tftdichip.createEventObject(event: fEvent; var eventHandle: thandle): boolean;
var
  res: ft_result;
  eventmask: dword;
begin
  { We are actually going to create a windows event object and return that }
  eventHandle := CreateEvent(nil, false, false, '');

  { Create correct event mask depending on enum }
  case event of
    fEventRXChar: eventmask := FT_EVENT_RXCHAR;
    fEventModemStatus: eventmask := FT_EVENT_MODEM_STATUS;
  else
    eventmask := FT_EVENT_RXCHAR or FT_EVENT_MODEM_STATUS;
  end;

  { Get FTDI to tie the event object to the event we want to watch }
  res := FT_SetEventNotification(self.fhandle, eventmask, eventHandle);
  if res <> FT_OK then result := false else result := true;

  { Must clean up if it failed or we will leak handles }
  if not result then begin
    CloseHandle(eventHandle);
    eventHandle := 0;
  end;
end;

{ ----------------------------------------------------------------------------
  Wait for an event to occur from the event object <eventhandle>. Waits up to
  <timeout> milliseconds. Returns the status:
    fEventRXChar: A character has been received
    fEventModemStatus: Comm signal line states changed
    fEventTimedOut: Timed out
    fEventError: Device error (device unplugged most likely)

  THIS CALL MUST BE THREAD SAFE as the ftdi comms thread uses it.
  ---------------------------------------------------------------------------- }
function tftdichip.waitForEventObject(var eventhandle: thandle; timeout: cardinal): fEvent;
var
  res: ft_result;
  rx, tx, sta: longint;
begin
  { Wait for the object }
  WaitForSingleObject(eventhandle, timeout);

  { Investigate status }
  res := FT_GetStatus(self.fhandle, @rx, @tx, @sta);

  { If we failed to get the status then return fEventError }
  if res <> FT_OK then begin
    result := fEventError;
    exit;
  end;

  { Check for modem status change }
  if (sta and FT_EVENT_MODEM_STATUS) <> 0 then begin
    result := fEventModemStatus;
    exit;
  end;

  { Check for received bytes }
  if (rx > 0) then begin
    result := fEventRXChar;
    exit;
  end;

  { Timed out? }
  result := fEventTimedOut;
end;

{ ----------------------------------------------------------------------------
  Close an event object. Must do this to free system resources when an object
  is no longer needed.

  THIS CALL MUST BE THREAD SAFE as the ftdi comms thread uses it.
  ---------------------------------------------------------------------------- }
procedure tftdichip.closeEventObject(var eventhandle: thandle);
begin
  CloseHandle(eventhandle);
  eventhandle := 0;
end;

{ ----------------------------------------------------------------------------
  Setup COMM events. Assign event handlers.
  Returns TRUE if successful.
  ---------------------------------------------------------------------------- }
function tftdichip.setupCommEvents(onReceiveData: tftdievent_onReceiveData; onSendQueueEmpty: tftdievent_OnSendQueueEmpty; onError: tftdievent_onError): boolean;
begin
  { Setup events }
  self.e_onReceiveData := onReceiveData;
  self.e_onSendQueueEmpty := onSendQueueEmpty;
  self.e_onError := onError;

  result := true;
end;

{ ----------------------------------------------------------------------------
  Stop comm event thread
  ---------------------------------------------------------------------------- }
function tftdichip.stopCommEvents: boolean;
begin
  result := false;
  
  { Exit if the thread isn't running }
  if not assigned(self.thread) then exit;

  { Remove this FTDI object from the tree, so any events that were waiting to
    fire from this object will no longer fire }
  deltree(hash_objects, inttostr(longint(pointer(self))));

  { Signal thread to terminate }
  self.thread.Terminate;

  { Wait for it to terminate (takes 10 milliseconds at most }
  self.thread.WaitFor;

  { Kill thread }
  self.thread.Free;
  self.thread := nil;
  result := true;
end;

{ ----------------------------------------------------------------------------
  Start comm event thread
  ---------------------------------------------------------------------------- }
function tftdichip.startCommEvents: boolean;
begin
  result := false;

  { Drop out if the thread is already running }
  if assigned(self.thread) then exit;

  { Create thread and give it the event handlers and a ref to ourself }
  self.thread := tftdithread.Create(true);
  self.thread.e_onReceiveData := self.e_onReceiveData;
  self.thread.e_onSendQueueEmpty := self.e_onSendQueueEmpty;
  self.thread.e_onError := self.e_onError;
  self.thread.ftdiclass := self;

  { Must add ourselves to the hash tree or no events will be received }
  addtree(hash_objects, inttostr(longint(pointer(self))), pointer(self));

  { Go! }
  self.thread.Resume;

  result := true;
end;

{ ----------------------------------------------------------------------------
  See if we can find a connected FTDI chip that matches the deviceSerial
  given. If we find it, return TRUE else FALSE.
  ---------------------------------------------------------------------------- }
function tftdichip.isPresentBySerial(deviceSerial: string): boolean;
var
  hnd: ft_handle;
  res: ft_result;
  my_str: AnsiString;
begin
  { Default to failing }
  result := false;
  my_str:= deviceSerial;
  { Try to open the device by serial }
  res := FT_OpenEx(pansichar(my_str), FT_OPEN_BY_SERIAL_NUMBER, @hnd);

  { If it failed exit, otherwise close device and return TRUE }
  if res <> FT_OK then exit;
  FT_Close(hnd);
  result := true;
end;

{ ----------------------------------------------------------------------------
  Open an FTDI device by serial. Returns TRUE on success otherwise FALSE.
  ---------------------------------------------------------------------------- }
function tftdichip.openDeviceBySerial(deviceSerial: string): boolean;
var
  res: ft_result;
  my_str: AnsiString;
begin
  if fconnected then begin
    raise exception.Create('tftdichip.openDeviceBySerial: Already open');
    exit;
  end;

  { Default to failing }
  result := false;
  my_str:= deviceSerial;

  { Try to open the device by serial }
  res := FT_OpenEx(pansichar(my_str), FT_OPEN_BY_SERIAL_NUMBER, @self.fhandle);

  { If it failed exit, otherwise close device and return TRUE }
  if res <> FT_OK then exit;
  result := true;
  fconnected := true;
end;

{ ----------------------------------------------------------------------------
  Set the device latency timer. Every <millisecs> milliseconds, the receive
  buffer will be flushed and sent to the OS (and then to the user app) if the
  buffer was not full.
  Valid range 1 - 255. Default 16.
  Lowering this is beneficial to apps needing a fast response and using small
  packets.
  ---------------------------------------------------------------------------- }
function tftdichip.setLatencyTimer(millisecs: byte): boolean;
var
  res: ft_result;
begin
  result := false;
  res := FT_SetLatencyTimer(self.fhandle, millisecs);
  if res <> FT_OK then exit;
  result := true;
end;

{ ----------------------------------------------------------------------------
  ---------------------------------------------------------------------------- }
end.
