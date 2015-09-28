{ ----------------------------------------------------------------------------
  FTDIclass async demo
  Copyright (c) Michael "Zipplet" Nixon 2009.
  Licensed under the MIT license, see license.txt in the project trunk.

  Unit: unitfrmasyncdemo
  Purpose: Async demo form
  ---------------------------------------------------------------------------- }
unit unitfrmasyncdemo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,
  FTDIchip, FTDItypes;

type
  TfrmAsyncDemo = class(TForm)
    Label1: TLabel;
    editname: TEdit;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure ondata(ftdichip: tobject; datalength: longint);
    procedure onsenddone(ftdichip: tobject);
    procedure onerror(ftdichip: tobject);
  end;

var
  frmAsyncDemo: TfrmAsyncDemo;
  t: tftdichip;

implementation

{$R *.dfm}

{ ----------------------------------------------------------------------------
  START button
  ---------------------------------------------------------------------------- }
procedure TfrmAsyncDemo.Button1Click(Sender: TObject);
var
  s: string;
  i: longint;
begin
  if assigned(t) then begin
    showmessage('already running');
    exit;
  end;
  t := tftdichip.create;

  { Check if device is present }
  if not t.isPresentByDescription(editname.text) then begin
    showmessage('Device not present');
    t.destroy;
    t := nil;
    exit;
  end;

  if not t.openDeviceByDescription(editname.text) then begin
    showmessage('Failed to open device');
    t.destroy;
    t := nil;
    exit;
  end;

  { Configure for 9600 baud, 8 bit, 1 stop bit, no parity, no flow control }
  if not t.resetDevice then showmessage('reset error?');
  t.setBaudRate(fBaud9600);
  t.setDataCharacteristics(fBits8, fStopBits1, fParityNone);
  t.setFlowControl(fFlowNone, 0, 0);

  { --- Setup async comms --- }

  { Tell the class about our callbacks }
  t.setupCommEvents(self.ondata, self.onsenddone, self.onerror);

  { Start the event engine }
  if not t.startCommEvents then begin
    showmessage('Failed to start event engine');
    t.destroy;
    t := nil;
  end;

  { Now to start this off we'll send a string of text }
  s := 'FTDI' + #13#10;
  t.write(@s[1], length(s), i);
end;

{ ----------------------------------------------------------------------------
  This event fires when data is available to be read.
  ---------------------------------------------------------------------------- }
procedure tfrmasyncdemo.ondata(ftdichip: tobject; datalength: longint);
var
  s: string;
  i: longint;
begin
  { Grab the data }
  setlength(s, datalength);
  tftdichip(ftdichip).read(@s[1], datalength, i);

  { Spit it out to the console window }
  write(s);
end;

{ ----------------------------------------------------------------------------
  This event fires when all pending data has been sent.
  ---------------------------------------------------------------------------- }
procedure tfrmasyncdemo.onsenddone(ftdichip: tobject);
var
  s: string;
  i: longint;
begin
  { We'll send something again }
  s := 'Hello, world - ';
  tftdichip(ftdichip).write(@s[1], length(s), i);

  { As you can probably guess this is going to result in it sending continuously }
end;

{ ----------------------------------------------------------------------------
  This event is called when a serious error occurs, usually the device has
  been unplugged.
  ---------------------------------------------------------------------------- }
procedure tfrmasyncdemo.onerror(ftdichip: tobject);
begin
  { Stop event engine }
  t.stopCommEvents;
  { Close device }
  t.closeDevice;
  { Free class }
  t.free;
  t := nil;

  showmessage('Device error');
end;

{ ----------------------------------------------------------------------------
  STOP button
  ---------------------------------------------------------------------------- }
procedure TfrmAsyncDemo.Button2Click(Sender: TObject);
begin
  if not assigned(t) then begin
    showmessage('already stopped');
    exit;
  end;
  t.closeDevice;
  t.free;
  t := nil;
end;

end.
