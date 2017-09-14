// TouchButton registers the down event caused by a touch on the screen. The
// position will not handled, only the event seems to be useful for a button

unit TouchButton;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.Buttons,
  Messages, DateUtils, Windows;

const
  WM_POINTERDOWN = $0246;
  WM_POINTERUP   = $0247;                       // Wert muss noch geklärt werden

type
  TTouchButton = class(TBitBtn)
  private
  protected
    procedure WMPointerDown(var Msg: TMessage); message WM_POINTERDOWN;
    procedure WMPointerUp(var Msg: TMessage); message WM_POINTERUP;
  public
    FOnTouchDown: TMouseEvent;
    FOnTouchUp:   TMouseEvent;
  published
    property OnTouchDown: TMouseEvent read FOnTouchDown write FOnTouchDown;
    property OnTouchUp:   TMouseEvent read FOnTouchUp   write FOnTouchUp;
  end;

procedure Register;

implementation

procedure TTouchButton.WMPointerDown(var Msg: TMessage);
var Shift:  TShiftState;
begin
  if assigned(FOnTouchDown) then FOnTouchDown(Self, mbLeft, Shift, 0, 0);
  Msg.Result := DefWindowProc(Handle, Msg.Msg, Msg.WParam, Msg.LParam);
end;

procedure TTouchButton.WMPointerUp(var Msg: TMessage);
var Shift:  TShiftState;
begin
  if assigned(FOnTouchUp) then FOnTouchUp(Self, mbLeft, Shift, 0, 0);
  Msg.Result := DefWindowProc(Handle, Msg.Msg, Msg.WParam, Msg.LParam);
end;

procedure Register;
begin
  RegisterComponents('Touch', [TTouchButton]);
end;

end.
