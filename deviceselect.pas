unit deviceselect;

interface

uses Windows, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, ComCtrls;

type
  Tdeviceselectbox = class(TForm)
    Panel1: TPanel;
    OKButton: TButton;
    ListView1: TListView;
    CancelButton: TButton;
    Label1: TLabel;
    procedure OKButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  deviceselectbox: Tdeviceselectbox;
implementation

{$R *.dfm}



procedure Tdeviceselectbox.CancelButtonClick(Sender: TObject);
begin
  deviceselectbox.ModalResult:=mrCancel;
end;

procedure Tdeviceselectbox.OKButtonClick(Sender: TObject);
begin
  deviceselectbox.ModalResult:=mrCancel;
  if deviceselectbox.ListView1.itemindex >= 0 then
    deviceselectbox.ModalResult:=mrOK;
end;


end.

