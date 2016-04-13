// #############################################################################
// ############################ PENS GRID PAGE #################################
// #############################################################################

procedure TForm1.SgPensDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  my_shape: Tshape;
  aRect: TRect;
  aStr: String;
  my_tooltip: Integer;

begin
  Rect.Left:= Rect.Left-4;    // Workaround für XE8-Darstellung
  if aRow = 0 then with SgPens,Canvas do begin
    Font.Style := [fsBold];
    TextRect(Rect, Rect.Left + 2, Rect.Top + 2, Cells[ACol, ARow]);
  end else with SgPens,Canvas do begin
      // Draw the Band
    if (ACol > 2) then begin
      if not job.pens[aRow-1].enable then begin
        Brush.Color := clBtnFace;
        Font.Color:=clgrayText;
      end;
      TextRect(Rect, Rect.Left + 2, Rect.Top + 2, cells[acol, arow]);
    end;
    if (ACol = Col) and (ARow= Row) then begin
      Brush.Color := clHighlight;
      Font.Color:=clwhite;
      TextRect(Rect, Rect.Left + 2, Rect.Top + 1, cells[acol, arow]);
      Font.Color:=clblack;
    end;
    case aCol of
    0: // Pen
      begin
        Font.Style := [fsBold];
        Font.Color:=clblack;
        TextRect(Rect, Rect.Left + 2, Rect.Top + 2, Cells[ACol, ARow]);
      end;
    1: // Color
      begin
        InflateRect(Rect, -1, -1);
        Brush.Color := clgray;
        FrameRect(Rect);
        Brush.Color := job.pens[aRow-1].color;
        InflateRect(Rect, -1, -1);
        FillRect(Rect);
        Font.Color:=clwhite;
      end;
    2: // Enable
      begin
        Brush.Color := clgray;
        Pen.Color := cl3Dlight;
        inc(Rect.Left);
        inc(Rect.Top);
        FrameRect(Rect);
        Brush.Color := cl3Dlight;
        InflateRect(Rect, -1, -1);
        if job.pens[aRow-1].used then begin
          if job.pens[aRow-1].enable then
            Font.Color:= clred
          else
            Font.Color:=clblack;
        end else
            Font.Color:=clwhite;
        if job.pens[aRow-1].enable then
          Font.Style := [fsBold];
        FillRect(Rect);
        aRect := Rect;
        aStr:= Cells[ACol, ARow];
        aRect.Top := aRect.Top + 1; // adjust top to center vertical
        DrawText(Canvas.Handle, PChar(aStr), Length(aStr), aRect, DT_CENTER);
      end;
    9:  // Shape
      begin
        Brush.Color := clgray;
        Pen.Color := cl3Dlight;
        inc(Rect.Left);
        inc(Rect.Top);
        FrameRect(Rect);
        Brush.Color := cl3Dlight;
        InflateRect(Rect, -1, -1);
        FillRect(Rect);
        aRect := Rect;
        my_shape:= job.pens[aRow-1].shape;
        Font.Color:= ShapeColorArray[ord(my_shape)];
        aStr:= ShapeArray[ord(my_shape)];
        aRect.Top := aRect.Top + 1; // adjust top to center vertical
        DrawText(Canvas.Handle, PChar(aStr), Length(aStr), aRect, DT_CENTER);
      end;
    12:  // Tooltip
      begin
        Brush.Color := clgray;
        Pen.Color := cl3Dlight;
        inc(Rect.Left);
        inc(Rect.Top);
        FrameRect(Rect);
        Brush.Color := cl3Dlight;
        InflateRect(Rect, -1, -1);
        FillRect(Rect);
        aRect := Rect;
        my_tooltip:= job.pens[aRow-1].tooltip;
        aStr:= ToolTipArray[my_tooltip];
        aRect.Top := aRect.Top + 1; // adjust top to center vertical
        DrawText(Canvas.Handle, PChar(aStr), Length(aStr), aRect, DT_CENTER);
      end;
    end; //case
  end;
end;

procedure TForm1.SgPensKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) or (Key = #10) then begin
    SgPens.Repaint;
    PenGridListToJob;
    param_change;
    Form4.FormRefresh(sender);
  end;
end;


procedure TForm1.SgPensMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  my_shape, max_shape: Tshape;
  R: TRect;
  org: TPoint;
begin
  UnHilite;
  with SgPens do begin
    Options:= Options - [goEditing, goAlwaysShowEditor];
    case Col of
    1:  // Color
      begin
        Options:= Options - [goEditing];
        ColorDialog1.Color:= job.pens[Row-1].color;
        if not ColorDialog1.Execute then Exit;
        Cells[1,Row]:= IntToStr(ColorDialog1.Color);
      end;
    2:  // Enable
      begin
        Options:= Options - [goEditing];
        job.pens[Row-1].enable:= not job.pens[Row-1].enable;
        if job.pens[Row-1].enable then
          Cells[2,Row]:= 'ON'
        else
          Cells[2,Row]:= 'OFF';
      end;
    3, 4, 5,6,7,10,11:  // F, Xofs, Yofs, Z+
        Options:= Options + [goEditing];
    8:  // Scale
      begin
        Options:= Options + [goEditing];
        job.pens[Row-1].Scale:= StrToFloatDef(Cells[8,Row],100);
      end;
    9:  // Shapes
      begin
        Options:= Options - [goEditing];
        my_shape:= job.pens[Row-1].shape;
        if my_shape >= drillhole then
          job.pens[Row-1].shape:= contour
        else
          inc(job.pens[Row-1].shape);
        if (ssRight in Shift) then      // reset to default mit rechter Maustaste
          if Row > 10 then
            job.pens[Row-1].shape:= drillhole
          else
            job.pens[Row-1].shape:= contour;
        Cells[9,Row]:= IntToStr(ord(job.pens[Row-1].shape));
      end;
    12:  // Tooltip
      if Row > 0 then begin
        R := SgPens.CellRect(Col, Row);
        org := self.ScreenToClient(self.ClientToScreen(R.TopLeft));
        perform( WM_CANCELMODE, 0, 0 ); // verhindert Mausaktion in Stringgrid
        with ComboBoxTip do begin
          SetBounds(org.X-14, org.Y-2, R.Right-R.Left+14, Form1.Height);
          ItemIndex := STrToIntDef(Cells[12,Row],0);
          if ItemIndex < 0 then
            ItemIndex:= 0;
          Show;
          BringToFront;
          SetFocus;
          DroppedDown:= true;
        end;
      end;
    end; //case
    Form4.FormRefresh(sender);
    PenGridListToJob;
    param_change;
    Form4.FormRefresh(nil);
    Repaint;
  end;
end;


procedure TForm1.SgPensTopLeftChanged(Sender: TObject);
var
  my_rect: TRect;
begin
  my_rect:= SgPens.CellRect(2,SgPens.Row);
  ComboBoxTip.ItemIndex:= 0;
  ComboBoxTip.hide;
end;

procedure TForm1.ComboBoxTipExit(Sender: TObject);
var my_str: String;
begin
  if ComboBoxTip.ItemIndex >= 0 then
    my_str:= IntToStr(ComboBoxTip.ItemIndex); //  := Items[ItemIndex];
  with SgPens do
    if (Row > 0) and (Col= 12) then begin
      Cells[col, row]:= my_str;
      UnHilite;
      if ComboBoxTip.ItemIndex = 6 then begin
        job.pens[Row-1].shape:= drillhole;
        Cells[9,Row]:= IntToStr(ord(job.pens[Row-1].shape));
      end;
      CalcTipDia;
      Repaint;
    end;
  ComboBoxTip.hide;
  NeedsRedraw:= true;
end;

procedure TForm1.ComboBoxTipMouseLeave(Sender: TObject);
begin
  ComboBoxTip.hide;
  CalcTipDia;
  SgPens.Repaint;
end;

procedure TForm1.ComboBoxTipKeyPress(Sender: TObject; var Key: Char);
begin
  ComboBoxTip.hide;
  CalcTipDia;
  SgPens.Repaint;
end;

