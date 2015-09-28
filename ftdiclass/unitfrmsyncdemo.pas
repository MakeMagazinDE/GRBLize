{ ----------------------------------------------------------------------------
  FTDIclass sync demo
  Copyright (c) Michael "Zipplet" Nixon 2009.
  Licensed under the MIT license, see license.txt in the project trunk.

  Unit: unitfrmsyncdemo
  Purpose: sync demo form
  ---------------------------------------------------------------------------- }
unit unitfrmsyncdemo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,
  FTDIchip, FTDItypes;

type
  TfrmsyncDemo = class(TForm)
    Label1: TLabel;
    editname: TEdit;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmsyncDemo: TfrmsyncDemo;
  t: tftdichip;
  told_to_stop: boolean;

implementation

{$R *.dfm}

{ ----------------------------------------------------------------------------
  START button
  ---------------------------------------------------------------------------- }
procedure TfrmsyncDemo.Button1Click(Sender: TObject);
var
  s: string;
  i: longint;
  serialstring, descriptionstring: string;
  vid, pid: word;
  device: fDevice;
begin
  { Don't allow start button if it's already running }
  if assigned(t) then begin
    showmessage('already running');
    exit;
  end;

  told_to_stop := false;

  t := tftdichip.create;

  { Check if device is present }
  if not t.isPresentByDescription(editname.text) then begin
    showmessage('Device not present');
    freeandnil(t);
    exit;
  end;

  { Open device }
  if not t.openDeviceByDescription(editname.text) then begin
    showmessage('Failed to open device');
    freeandnil(t);
    exit;
  end;

  { Check that this device is infact an FT232R. First get device info }
  if not t.getDeviceInfo(device, pid, vid, serialstring, descriptionstring) then begin
    showmessage('Failed to get device info');
    freeandnil(t);
    exit;
  end;
  if device <> fDevice232R then begin
    showmessage('Sorry this example only works on FT232R devices');
    freeandnil(t);
    exit;
  end;

  { Tell user about the device we are connecting to }
  showmessage('Device details:' + #13#10 +
              'USB VID: $' + inttohex(vid, 4) + #13#10 +
              'USB PID: $' + inttohex(pid, 4) + #13#10 +
              'Serial number string: ' + serialstring + #13#10 +
              'Description string: ' + descriptionstring + #13#10 +
              '---------------------------------------------' + #13#10 +
              'Click OK to start');

  { Configure for 9600 baud, 8 bit, 1 stop bit, no parity, no flow control }
  if not t.resetDevice then showmessage('reset error?');
  t.setBaudRate(fBaud9600);
  t.setDataCharacteristics(fBits8, fStopBits1, fParityNone);
  t.setFlowControl(fFlowNone, 0, 0);

  { Configure timeouts for tx/rx }
  t.setTimeouts(1000, 1000);

  { Loop }
  repeat
    { Send a single character }
    s := 'A';
    writeln('tx: ' + s);
    t.write(@s[1], 1, i);

    { i contains the number of bytes sent. If it's not 1, then something went wrong }
    if i <> 1 then begin
      showmessage('write error');
      break;
    end;

    { Need these calls or the app will freeze as we are in an infinite loop in the main thread }
    application.processmessages;

    { Try to read a single character back }
    s := ' ';
    t.read(@s[1], 1, i);
    { i contains the number of bytes read. If 0, then something went wrong }
    if i = 0 then begin
      showmessage('read error - please make sure TX and RX are connected together on the FT232R');
      break;
    end;
    writeln('rx: ' + s);

    { Need these calls or the app will freeze as we are in an infinite loop in the main thread }
    application.processmessages;

    { told_to_stop is set by the STOP button }
  until told_to_stop;

  { Close device and free class }
  t.closeDevice;
  freeandnil(t);
end;

{ ----------------------------------------------------------------------------
  STOP button
  ---------------------------------------------------------------------------- }
procedure TfrmsyncDemo.Button2Click(Sender: TObject);
begin
  told_to_stop := true;
end;

{ ----------------------------------------------------------------------------
  Form close
  Must set told_to_stop or the form wont close if the app is busy
  ---------------------------------------------------------------------------- }
procedure TfrmsyncDemo.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := true;
  told_to_stop := true;
end;

end.
