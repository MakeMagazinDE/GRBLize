{ ----------------------------------------------------------------------------
  FTDI D2XX async thread
  Copyright (c) Michael "Zipplet" Nixon 2009.
  Licensed under the MIT license, see license.txt in the project trunk.

  Unit: FTDIthread.pas
  Purpose: FTDI async thread
  ---------------------------------------------------------------------------- }
unit FTDIthread;

{ ----------------------------------------------------------------------------
  ---------------------------------------------------------------------------- }

interface

uses
  sysutils, windows, messages, classes, bsearchtree, blinklist,
  FTDItypes;

const
    { -------- Window messages ----------------------------------------------- }
    WM_APP = $8000;                 { Safe base number for user app messages }
    WM_USER_RX = WM_APP + 1;        { Receive data event }
    WM_USER_TXDONE = WM_APP + 2;    { Send queue empty event }
    WM_USER_ERROR = WM_APP + 3;     { Device error event }

type
  { -------- FTDI class thread ----------------------------------------------- }
  tftdithread = class(TThread)
    { Copies of event handler addresses }
    e_onReceiveData: tftdievent_onReceiveData;
    e_onSendQueueEmpty: tftdievent_onSendQueueEmpty;
    e_onError: tftdievent_onError;

    { Reference to the FTDI chip class that owns this thread }
    ftdiclass: tobject;

    procedure Execute; override;
    constructor Create(CreateSuspended: Boolean);
  end;

var
  { In order to send comm events to the main window we have to create our own
    window and post messages to it from the comms thread. From there we call
    the users event handlers. It is possible (but unlikely) that the user has
    freed the FTDI object while an event is queued in the message queue. This
    would cause a crash when it tried to reference it. Therefore we need a
    linked list to keep track of which FTDI objects exist so we can check if
    an object exists before we reference it. Hence hash_objects. }
  hash_objects: phashtable;

  { Handle to our window for message passing }
  hwndftdi: thandle;

implementation

uses FTDIchip;

{ ----------------------------------------------------------------------------
  Thread process
  ---------------------------------------------------------------------------- }
procedure tftdithread.Execute;
var
  e: fEvent;
  eventobject: thandle;
  i: longint;
begin
  { We want to wait for all events. }
  tftdichip(self.ftdiclass).createEventObject(fEventAny, eventobject);

  { This loop executes until the thread terminates }
  repeat
    { Wait here for an event to occur. This call consumes no CPU. }
    e := tftdichip(self.ftdiclass).waitForEventObject(eventobject, 10);

    case e of
      { Error. Device unplugged or so }
      fEventError: begin
        if assigned(self.e_OnError) then begin
          { Post message to the main thread along with a pointer to the FTDI class that owns this thread }
          postmessage(hwndftdi, WM_USER_ERROR, 0, longint(pointer(self.ftdiclass)));
        end;
      end;
      { Character(s) received }
      fEventRXChar: begin
        if assigned(self.e_OnReceiveData) then begin
          { Post message to the main thread along with a pointer to the FTDI class that owns this thread }
          postmessage(hwndftdi, WM_USER_RX, 0, longint(pointer(self.ftdiclass)));
        end;
      end;
      { Timed out. We could still have a SendQueueEmpty event. }
      fEventTimedOut: begin
        { Try to get send queue status, do not continue if we can't }
        if not tftdichip(self.ftdiclass).getSendQueueStatus(i) then break;
        { If the send queue is empty and data has been sent previously }
        if (i = 0) and tftdichip(self.ftdiclass).dataHasBeenSent then begin
          { MUST unset the dataHasBeenSent flag or this will fire continuously.
            Now it will only fire after we send more data }
          tftdichip(self.ftdiclass).dataHasBeenSent := false;
          if assigned(self.e_OnSendQueueEmpty) then begin
            { Post message to the main thread along with a pointer to the FTDI class that owns this thread }
            postmessage(hwndftdi, WM_USER_TXDONE, 0, longint(pointer(self.ftdiclass)));
          end;
        end;
      end;
    end;
  until self.Terminated;
  { Clean up after ourselves }
  tftdichip(self.ftdiclass).closeEventObject(eventobject);
end;

{ ----------------------------------------------------------------------------
  comm thread constructor
  ---------------------------------------------------------------------------- }
constructor tftdithread.Create(CreateSuspended: Boolean);
begin
  inherited create(CreateSuspended);
  { Thread must not free itself or the app will AV }
  self.FreeOnTerminate := false;
end;

(******************************************************************************)
(*                                                                            *)
(* Below here is window handler stuff                                         *)
(*                                                                            *)
(******************************************************************************)

{ ----------------------------------------------------------------------------
  Window process handler (message handler)
  THIS CODE RUNS IN THE APP MAIN THREAD
  ---------------------------------------------------------------------------- }
function MyWindowProc(ahWnd: HWND; auMsg: Integer; awParam: WPARAM; alParam: LPARAM): Integer; stdcall;
var
  i: longint;
begin
  { Default to handling the message return status }
  result := 0;

  { Only handle messages ourselves that come from our window (sanity check) and
    that the hash table has been allocated }
  if (ahWnd = hwndftdi) and assigned(hash_objects) then begin
    case auMsg of
      { Data receive event }
      WM_USER_RX: begin
        { alParam = class object pointer }
        { Verify the class object exists }
        if not assigned(findtree(hash_objects, inttostr(alParam))) then begin
          { Do nothing }
          exit;
        end;
        { If the receive data event has been assigned... }
        if assigned(tftdichip(pointer(alParam)).e_OnReceiveData) then begin
          { Double check that data is available to read. It is possible that there
            will be none (race condition) - in that case we do nothing }
          if tftdichip(pointer(alParam)).getReceiveQueueStatus(i) then begin
            if i > 0 then begin
              { Finally call the user event }
              tftdichip(pointer(alParam)).e_OnReceiveData(tftdichip(pointer(alParam)), i);
            end;
          end;
        end;
      end;
      WM_USER_ERROR: begin
        { alParam = class object pointer }
        { Verify the class object exists }
        if not assigned(findtree(hash_objects, inttostr(alParam))) then begin
          { Do nothing }
          exit;
        end;
        { If the error event has been assigned... }
        if assigned(tftdichip(pointer(alParam)).e_OnError) then begin
          { Finally call the user event }
          tftdichip(pointer(alParam)).e_OnError(tftdichip(pointer(alParam)));
        end;
      end;
      WM_USER_TXDONE: begin
        { alParam = class object pointer }
        { Verify the class object exists }
        if not assigned(findtree(hash_objects, inttostr(alParam))) then begin
          { Do nothing }
          exit;
        end;
        { If the event has been assigned... }
        if assigned(tftdichip(pointer(alParam)).e_OnSendQueueEmpty) then begin
          { Finally call the user event }
          tftdichip(pointer(alParam)).e_OnSendQueueEmpty(tftdichip(pointer(alParam)));
        end;
      end;
    end;
  end else begin
    Result := DefWindowProc(ahWnd, auMsg, awParam, alParam);
  end;
end;

{ ----------------------------------------------------------------------------
  Window class
  ---------------------------------------------------------------------------- }
var
  MyWindowClass : TWndClass = (style         : 0;
                               lpfnWndProc   : @MyWindowProc;
                               cbClsExtra    : 0;
                               cbWndExtra    : 0;
                               hInstance     : 0;
                               hIcon         : 0;
                               hCursor       : 0;
                               hbrBackground : 0;
                               lpszMenuName  : nil;
                               lpszClassName : 'ftdiClass');

{ ----------------------------------------------------------------------------
  Initialization: Called when the app starts
  ---------------------------------------------------------------------------- }
initialization
  { Register window class and create window }
  if Windows.RegisterClass(MyWindowClass) = 0 then halt;
  hwndftdi := CreateWindowEx(WS_EX_TOOLWINDOW,
                               MyWindowClass.lpszClassName,
                               '',        { Window name   }
                               WS_POPUP,  { Window Style  }
                               0, 0,      { X, Y          }
                               0, 0,      { Width, Height }
                               0,         { hWndParent    }
                               0,         { hMenu         }
                               HInstance, { hInstance     }
                               nil);      { CreateParam   }

  { Allocate the hash table }
  getmem(hash_objects, sizeof(thashtable));

{ ----------------------------------------------------------------------------
  Finalization: Called when the app ends
  ---------------------------------------------------------------------------- }
finalization
  { Destroy window }
  DestroyWindow(hwndftdi);

  { Free hash table }
  freemem(hash_objects);
  hash_objects := nil;
end.
