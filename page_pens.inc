// #############################################################################
// ############################ PENS GRID PAGE #################################
// #############################################################################

procedure TForm1.SgPensContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin
  SgPensDblClick(Sender);
end;

procedure TForm1.SgPensDblClick(Sender: TObject);
begin
  SgEditorOff(SgPens);
  FormParamAssist.ShowModal(SgPens.Row-1);                       // start dialog
  JobToPenGridList;                                                 //update GUI
  SgJobDefaults.Cells[1,4]:= string(Materials[Job.material].Name);
end;

procedure TForm1.SgPensDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var my_shape:   Tshape;
    aRect:      TRect;
    aStr:       String;
    my_tooltip: Integer;
begin
  if ARow = 0 then with SgPens,Canvas do begin
    Font.Style := [fsBold];
    TextRect(Rect, Rect.Left + 2, Rect.Top + 2, Cells[ACol, ARow]);
  end else with SgPens,Canvas do begin
      // Draw the Band
    Font.Color:=clblack;
    if (ACol > 2) then begin
      if not job.pens[aRow-1].enable then begin
        Brush.Color := clBtnFace;
        Font.Color:=clgrayText;
      end;
      TextRect(Rect, Rect.Left + 2, Rect.Top + 2, cells[acol, arow]);
    end;
    case ACol of
    0: // Pen
      begin
        Font.Style := [fsBold];
        Font.Color:=clblack;
        TextRect(Rect, Rect.Left + 2, Rect.Top + 2, Cells[ACol, ARow]);
      end;
    1: // Color
      begin
//        InflateRect(Rect, -1, -1);
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
        aStr:= string(ShapeArray[ord(my_shape)]);
        aRect.Top := aRect.Top + 1; // adjust top to center vertical
        DrawText(Canvas.Handle, PChar(aStr), Length(aStr), aRect, DT_CENTER);
      end;
    11:  // ATC, nicht aktiv
      begin
        if job.pens[aRow-1].enable and job.pens[aRow-1].used then begin
          Brush.Color := clInactiveCaption;
          Font.Color:=clblack;
          Font.Style := [];
          TextRect(Rect, Rect.Left + 2, Rect.Top + 2, Cells[ACol, ARow]);
        end else begin
          TextRect(Rect, Rect.Left + 2, Rect.Top + 2,'');
        end;
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
        aStr:= string(ToolTipArray[my_tooltip]);
        aRect.Top := aRect.Top + 1; // adjust top to center vertical
        DrawText(Canvas.Handle, PChar(aStr), Length(aStr), aRect, DT_CENTER);
      end;
    end; //case
  end;
end;

procedure TForm1.SgPensExit(Sender: TObject);
var c: integer;
begin
  c:= SgPens.Col;
  SgEditorOff(SgPens);
  if c in [6,7,8] then OpenFilesInGrid
  else begin
    SgPens.Repaint;
    PenGridListToJob;
    apply_pen_change;
    GLSneedsRedrawTimeout:= 2;
    GLSneedsATCupdateTimeout:= 3;
  end;
end;

procedure TForm1.SgPensKeyPress(Sender: TObject; var Key: Char);
begin
  if Key in [#10, #13, #27] then SgPensExit(Sender);
end;

procedure TForm1.SgPensSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
var R:      TRect;
    org:    TPoint;
begin
  UnHilite;

  with SgPens do begin                       // right col is for hide focus only
    if ACol = ColCount-1 then begin CanSelect:= false; exit end;
    SgEditorOff(SgPens);
    case ACol of
    1:                                                                  // Color
      begin
        ColorDialog1.Color:=     job.pens[ARow-1].color;
        if not ColorDialog1.Execute then Exit;
        Cells[1,ARow]:=          IntToStr(ColorDialog1.Color);
        job.pens[ARow-1].color:= ColorDialog1.Color;
        OpenFilesInGrid;          // in case of SVG the color inflence the
      end;                        // relation between the path and the used pen!
    2:                                                                 // Enable
      begin
        job.pens[ARow-1].enable:= not job.pens[ARow-1].enable;
        if job.pens[ARow-1].enable then
          Cells[2,ARow]:= 'ON'
        else
          Cells[2,ARow]:= 'OFF';
      end;
    3, 4, 5, 6, 7, 8, 10, 13:     // Diameter,Z,F,Xofs,Yofs,Scale,Z/Cycle,Blades
        SgEditorOn(SgPens,ACol,ARow,true,true);
    9:  // Shapes
     if ARow > 0 then begin
        perform( WM_CANCELMODE, 0, 0 );   // verhindert Mausaktion in Stringgrid
        uncheck_ms;
        R := SgPens.CellRect(ACol, ARow);
        org := self.ClientToScreen(R.BottomRight);
        PopupMenuShape.Items[ord(job.pens[ARow-1].shape)].Checked:= true;
        PopupMenuShape.Popup(org.X, org.Y);
      end;
    12:  // Tooltip
      if ARow > 0 then begin
        perform( WM_CANCELMODE, 0, 0 );   // verhindert Mausaktion in Stringgrid
        uncheck_mtt;
        R := SgPens.CellRect(ACol, ARow);
        org := self.ClientToScreen(R.BottomRight);
        PopupMenuTooltip.Items[ord(job.pens[ARow-1].tooltip)].Checked:= true;
        PopupMenuTooltip.Popup(org.X, org.Y);
      end;

    end; //case

    PenGridListToJob;
    apply_pen_change;                    // setzt Timeouts über ListBlocks auf 1
    Repaint;
    if (ACol = 1) or (ACol = 9) then begin
      Form4.FormRefresh(nil);          // sofortiges Update für Enable und Shape
    end;
  end;
end;


