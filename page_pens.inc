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
  if aRow = 0 then with SgPens,Canvas do begin
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
{
    if (ACol = Col) and (ARow= Row) then begin
    // statt schraffierter Umrandung, besser sichtbar
      Brush.Color := clMenuHighlight;
      FillRect(Rect);
      Font.Color:=clwhite;
      TextRect(Rect, Rect.Left + 2, Rect.Top + 1, cells[acol, arow]);
      Font.Color:=clblack;
    end;
}
    case aCol of
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

procedure TForm1.SgPensKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) or (Key = #10) then begin
    SgPens.Repaint;
    PenGridListToJob;
    apply_pen_change;
    GLSneedsRedrawTimeout:= 2;
    GLSneedsATCupdateTimeout:= 3;
  end;
end;

procedure TForm1.SgPensMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  my_row, my_col: integer;
  T: integer;
begin
  SgPens.MouseToCell( X,Y, my_col, my_row );
  if (my_row < 1) or (my_col < 1) then
    exit;
  SgPens.Col := my_col;
  SgPens.Row := my_row;
  UnHilite;

  T:= gettickcount;                                     // check for doubleclick
  if T - SgPenT0 < 500 then begin
    FormParamAssist.ShowModal(my_row-1);                         // start dialog

    SgJobDefaults.Cells[1,4]:= string(Materials[Job.material].Name);//update GUI
    JobToPenGridList;
    SgPens.Cells[3,my_row]:=   FloatToStr(job.pens[my_row-1].diameter);
    SgPens.Cells[13,my_row]:=  IntToStr(job.pens[my_row-1].blades);
  end;

  SgPenT0 := T;

  with SgPens do begin
    Options:= Options - [goEditing, goAlwaysShowEditor];
    case my_Col of
    1:                                                                  // Color
      begin
        Options:= Options - [goEditing];
        ColorDialog1.Color:= job.pens[my_row-1].color;
        if not ColorDialog1.Execute then Exit;
        Cells[1,my_row]:= IntToStr(ColorDialog1.Color);
      end;
    2:                                                                 // Enable
      begin
        Options:= Options - [goEditing];
        job.pens[my_row-1].enable:= not job.pens[my_row-1].enable;
        if job.pens[my_row-1].enable then
          Cells[2,my_row]:= 'ON'
        else
          Cells[2,my_row]:= 'OFF';
      end;
    3:                                                               // Diameter
      begin
        Options:= Options + [goEditing];
      end;
    4, 5, 6, 7, 10, 13:                     // Z, F, Xofs, Yofs, Z/Cycle, Blades
      begin
        Options:= Options + [goEditing];
      end;
    8:  // Scale
      begin
        Options:= Options + [goEditing];
        job.pens[my_row-1].Scale:= StrToFloatDef(Cells[8,my_row],100);
      end;
    9:  // Shapes
     if my_row > 0 then begin
        perform( WM_CANCELMODE, 0, 0 ); // verhindert Mausaktion in Stringgrid
        uncheck_ms;
        PopupMenuShape.Items[ord(job.pens[Row-1].shape)].Checked:= true;
        PopupMenuShape.Popup(X+left+Form1.left, Y+ top+Form1.top);
      end;
    12:  // Tooltip
      if my_row > 0 then begin
        perform( WM_CANCELMODE, 0, 0 ); // verhindert Mausaktion in Stringgrid
        uncheck_mtt;
        PopupMenuTooltip.Items[ord(job.pens[Row-1].tooltip)].Checked:= true;
        PopupMenuTooltip.Popup(X+left+Form1.left, Y+ top+Form1.top);
      end;

    end; //case
    PenGridListToJob;
    apply_pen_change; // setzt Timeouts über ListBlocks auf 1
    Repaint;
    if (my_Col = 1) or (my_Col = 9) then begin
      Form4.FormRefresh(nil);  // sofortiges Update für Enable und Shape
    end;
  end;
end;

