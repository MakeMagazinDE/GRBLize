{ ----------------------------------------------------------------------------
  FTDIclass enumeration demo
  Copyright (c) Michael "Zipplet" Nixon 2009.
  Licensed under the MIT license, see license.txt in the project trunk.

  Unit: unitfrmenumdemo
  Purpose: enum demo form
  ---------------------------------------------------------------------------- }
unit unitfrmenumdemo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,
  FTDIchip, FTDItypes;

type
  Tfrmenumdemo = class(TForm)
    ListBox: TListBox;
    Timer1: TTimer;
    Label1: TLabel;
    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListBoxDblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmenumdemo: Tfrmenumdemo;
  sl: tstringlist;

implementation

{$R *.dfm}

{ ----------------------------------------------------------------------------
  Timer to refresh list
  ---------------------------------------------------------------------------- }
procedure Tfrmenumdemo.Timer1Timer(Sender: TObject);
var
  t: tftdichip;
  i: longint;
  s: string;
  devicecount: dword;
  devicelist: pftdiDeviceList;
begin
  listbox.clear;
  sl.Clear;

  { Create class instance }
  t := tftdichip.create;

  { Get the device list }
  if not t.createDeviceInfoList(devicecount, devicelist) then begin
    showmessage('Failed to create device info list');
    freeandnil(t);
    exit;
  end;

  listbox.items.Add('--- ' + inttostr(devicecount) + ' devices found ---');

  { Iterate through the device list that was returned }
  for i := 0 to devicecount - 1 do begin
    sl.Add(strpas(devicelist^[i].serialNumber));
    if strpas(devicelist^[i].serialNumber) = '' then begin
      listbox.Items.Add(inttostr(i) + ' - connecting to bus...');
    end else begin
      listbox.Items.Add(
        inttostr(i) + ' - ' +
        '[' + strpas(devicelist^[i].description) + '] - ' +
        '[' + strpas(devicelist^[i].serialNumber) + ']'
      );
    end;
  end;

  { Done, clean up }
  t.destroyDeviceInfoList(devicelist);
  freeandnil(t);
end;

{ ----------------------------------------------------------------------------
  Fill list on start
  ---------------------------------------------------------------------------- }
procedure Tfrmenumdemo.FormShow(Sender: TObject);
begin
  sl := tstringlist.Create;
  timer1timer(self);
end;

{ ----------------------------------------------------------------------------
  Double click event
  ---------------------------------------------------------------------------- }
procedure Tfrmenumdemo.ListBoxDblClick(Sender: TObject);
var
  s: string;
  serialstring, descriptionstring: string;
  vid, pid: word;
  device: fDevice;
  t: tftdichip;
begin
  { Exit if an invalid device is selected }
  if listbox.ItemIndex < 1 then exit;
  s := sl.Strings[listbox.itemindex - 1];
  if s = '' then begin
    showmessage('That device is not ready yet');
    exit;
  end;

  t := tftdichip.create;

  { Open device }
  if not t.openDeviceBySerial(s) then begin
    showmessage('Failed to open device');
    freeandnil(t);
    exit;
  end;

  { Get device info }
  if not t.getDeviceInfo(device, pid, vid, serialstring, descriptionstring) then begin
    showmessage('Failed to get device info');
    freeandnil(t);
    exit;
  end;

  t.closeDevice;

  { Tell user about the device }
  showmessage('Device details:' + #13#10 +
              'USB VID: $' + inttohex(vid, 4) + #13#10 +
              'USB PID: $' + inttohex(pid, 4) + #13#10 +
              'Serial number string: ' + serialstring + #13#10 +
              'Description string: ' + descriptionstring);

  freeandnil(t);
end;

end.
