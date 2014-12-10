{
  You cannot change the color of a standard TButton,
  since the windows button control always paints itself with the
  button color defined in the control panel.
  But you can derive derive a new component from TButton and handle
  the and drawing behaviour there.

  Die Farbe eines Standard TButtons kann nicht verändert werden, sie
  ist abhängig von den Systemeinstellungen.
  Durch Ableiten des TButtons kann der Button aber Farbe annehmen.
}


unit ColorButton;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls;

type
  TDrawButtonEvent = procedure(Control: TWinControl;
    Rect: TRect; State: TOwnerDrawState) of object;

  TColorButton = class(TButton)
  private
    FCanvas: TCanvas;
    IsFocused: Boolean;
    FOnDrawButton: TDrawButtonEvent;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure SetButtonStyle(ADefault: Boolean); override;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CNMeasureItem(var Message: TWMMeasureItem); message CN_MEASUREITEM;
    procedure CNDrawItem(var Message: TWMDrawItem); message CN_DRAWITEM;
    procedure WMLButtonDblClk(var Message: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
    procedure DrawButton(Rect: TRect; State: UINT);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Canvas: TCanvas read FCanvas;
  published
    property OnDrawButton: TDrawButtonEvent read FOnDrawButton write FOnDrawButton;
    property Color;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Beispiele', [TColorButton]);
end;

constructor TColorButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCanvas := TCanvas.Create;
end;

destructor TColorButton.Destroy;
begin
  inherited Destroy;
  FCanvas.Free;
end;

procedure TColorButton.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do Style := Style or BS_OWNERDRAW;
end;

procedure TColorButton.SetButtonStyle(ADefault: Boolean);
begin
  if ADefault <> IsFocused then
  begin
    IsFocused := ADefault;
    Refresh;
  end;
end;

procedure TColorButton.CNMeasureItem(var Message: TWMMeasureItem);
begin
  with Message.MeasureItemStruct^ do
  begin
    itemWidth  := Width;
    itemHeight := Height;
  end;
end;

procedure TColorButton.CNDrawItem(var Message: TWMDrawItem);
var
  SaveIndex: Integer;
begin
  with Message.DrawItemStruct^ do
  begin
    SaveIndex := SaveDC(hDC);
    FCanvas.Lock;
    try
      FCanvas.Handle := hDC;
      FCanvas.Font := Font;
      FCanvas.Brush := Brush;
      DrawButton(rcItem, itemState);
    finally
      FCanvas.Handle := 0;
      FCanvas.Unlock;
      RestoreDC(hDC, SaveIndex);
    end;
  end;
  Message.Result := 1;
end;

procedure TColorButton.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TColorButton.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TColorButton.WMLButtonDblClk(var Message: TWMLButtonDblClk);
begin
  Perform(WM_LBUTTONDOWN, Message.Keys, Longint(Message.Pos));
end;

procedure TColorButton.DrawButton(Rect: TRect; State: UINT);
var
  Flags, OldMode: Longint;
  IsDown, IsDefault, IsDisabled: Boolean;
  OldColor: TColor;
  OrgRect: TRect;
begin
  OrgRect := Rect;
  Flags := DFCS_BUTTONPUSH or DFCS_ADJUSTRECT;
  IsDown := State and ODS_SELECTED <> 0;
  IsDefault := State and ODS_FOCUS <> 0;
  IsDisabled := State and ODS_DISABLED <> 0;

  if IsDown then Flags := Flags or DFCS_PUSHED;
  if IsDisabled then Flags := Flags or DFCS_INACTIVE;

  if IsFocused or IsDefault then
  begin
    FCanvas.Pen.Color := clWindowFrame;
    FCanvas.Pen.Width := 1;
    FCanvas.Brush.Style := bsClear;
    FCanvas.Rectangle(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
    InflateRect(Rect, - 1, - 1);
  end;

  if IsDown then
  begin
    FCanvas.Pen.Color := clBtnShadow;
    FCanvas.Pen.Width := 1;
    FCanvas.Brush.Color := clBtnFace;
    FCanvas.Rectangle(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
    InflateRect(Rect, - 1, - 1);
  end
  else
    DrawFrameControl(FCanvas.Handle, Rect, DFC_BUTTON, Flags);

  if IsDown then OffsetRect(Rect, 1, 1);

  OldColor := FCanvas.Brush.Color;
  FCanvas.Brush.Color := Color;
  FCanvas.FillRect(Rect);
  FCanvas.Brush.Color := OldColor;
  OldMode := SetBkMode(FCanvas.Handle, TRANSPARENT);
  FCanvas.Font.Color := clBtnText;
  if IsDisabled then
    DrawState(FCanvas.Handle, FCanvas.Brush.Handle, nil, Integer(Caption), 0,
    ((Rect.Right - Rect.Left) - FCanvas.TextWidth(Caption)) div 2,
    ((Rect.Bottom - Rect.Top) - FCanvas.TextHeight(Caption)) div 2,
      0, 0, DST_TEXT or DSS_DISABLED)
  else
    DrawText(FCanvas.Handle, PChar(Caption), - 1, Rect,
      DT_SINGLELINE or DT_CENTER or DT_VCENTER);
  SetBkMode(FCanvas.Handle, OldMode);

  if Assigned(FOnDrawButton) then
    FOnDrawButton(Self, Rect, TOwnerDrawState(LongRec(State).Lo));

  if IsFocused and IsDefault then
  begin
    Rect := OrgRect;
    InflateRect(Rect, - 4, - 4);
    FCanvas.Pen.Color := clWindowFrame;
    FCanvas.Brush.Color := clBtnFace;
    DrawFocusRect(FCanvas.Handle, Rect);
  end;
end;

end.

