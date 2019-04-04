// TouchButton registers the down event caused by a touch on the screen. The
// position will not handled, only the event seems to be useful for a button

unit TouchButton;

interface

uses
  System.SysUtils, System.Classes, Dialogs, Vcl.Controls, Vcl.StdCtrls,
  Vcl.Buttons, Messages, DateUtils, Windows;

const
  WM_POINTERDOWN = $0246;
  WM_POINTERUP   = $0247;                       // Wert muss noch geklärt werden

  SM_DIGITIZER         = 94;
  TABLET_CONFIG_NONE   = $00000000; //The input digitizer does not have touch capabilities.
  NID_INTEGRATED_TOUCH = $00000001; //An integrated touch digitizer is used for input.
  NID_EXTERNAL_TOUCH   = $00000002; //An external touch digitizer is used for input.
  NID_INTEGRATED_PEN   = $00000004; //An integrated pen digitizer is used for input.
  NID_EXTERNAL_PEN     = $00000008; //An external pen digitizer is used for input.
  NID_MULTI_INPUT      = $00000040; //An input digitizer with support for multiple inputs is used for input.
  NID_READY            = $00000080; //The input digitizer is ready for input. If this value is unset, it may mean that the tablet service is stopped, the digitizer is not supported, or digitizer drivers have not been installed.

type
  TTouchCapability = (tcTabletPC,tcIntTouch,tcExtTouch,tcIntPen,tcExtPen,tcMultiTouch,tcReady);
  TTouchCapabilities = set of TTouchCapability;

  TTouchButton = class(TBitBtn)
    private
      { Private-Deklarationen }
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
function GetTouchCapabilities : TTouchCapabilities;

implementation

// proves the touch capabilities of the system /////////////////////////////////
function GetTouchCapabilities : TTouchCapabilities;
var ADigitizer : integer;
begin
result := [];
  // First check if the system is a TabletPC
  if GetSystemMetrics(SM_TABLETPC) <> 0 then begin
    include(result,tcTabletPC);
    if CheckWin32Version(6,1) then begin // If Windows 7, then we can do additional tests on input type
      ADigitizer := GetSystemMetrics(SM_DIGITIZER);
     if ((ADigitizer and NID_INTEGRATED_TOUCH) <> 0) then include(result,tcIntTouch);
     if ((ADigitizer and NID_EXTERNAL_TOUCH) <> 0) then include(result,tcExtTouch);
     if ((ADigitizer and NID_INTEGRATED_PEN) <> 0) then include(result,tcIntPen);
     if ((ADigitizer and NID_EXTERNAL_PEN) <> 0) then include(result,tcExtPen);
     if ((ADigitizer and NID_MULTI_INPUT) <> 0) then include(result,tcMultiTouch);
     if ((ADigitizer and NID_READY) <> 0) then include(result,tcReady);
    end else begin
      // If not Windows7 and TabletPC detected, we asume that it's ready
      include(result,tcReady);
    end;
  end;
end;

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

