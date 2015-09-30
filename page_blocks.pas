// #############################################################################
// ############################ BLOCKS GRID PAGE ###############################
// #############################################################################


procedure list_Blocks;
var i, my_len, my_row, my_pathcount: Integer;
  my_entry: Tfinal;
  x1, y1, x2, y2: Double;
begin
  with Form1.SgBlocks do begin
    Rowcount:= 2;
    Rows[1].clear;
    my_len:= length(final_array);
    if my_len < 1 then
      exit;
    for i:= 0 to my_len-1 do begin
      my_entry:= final_array[i];
      my_pathcount:= length(my_entry.millings);
      if my_pathcount = 0 then
        continue;
      // '#,Pen,Ena,Dia,Shape,Bounds,Center';
      my_row:= Rowcount - 1;
      Cells[0,my_row]:= IntToStr(my_row);
      Cells[1,my_row]:= IntToStr(my_entry.pen);
      if my_entry.enable then
        Cells[2,my_row]:= 'ON'
      else
        Cells[2,my_row]:= 'OFF';
      x1:= my_entry.bounds.min.x / c_hpgl_scale;
      y1:= my_entry.bounds.min.y / c_hpgl_scale;
      x2:= my_entry.bounds.max.x / c_hpgl_scale;
      y2:= my_entry.bounds.max.y / c_hpgl_scale;
      Cells[3,my_row]:= FormatFloat('0.0', job.pens[my_entry.pen].diameter);
      Cells[4,my_row]:= ShapeArray[ord(my_entry.shape)];
      Cells[5,my_row]:= FormatFloat('0.00', x1) + '/' + FormatFloat('0.00', y1)
          + ' - ' + FormatFloat('0.00', x2) + '/' + FormatFloat('0.00', y2);
      x1:= my_entry.bounds.mid.x / c_hpgl_scale;
      y1:= my_entry.bounds.mid.y / c_hpgl_scale;
      Cells[6,my_row]:= FormatFloat('0.00', x1) + '/' + FormatFloat('0.00', y1);
      Cells[7,my_row]:= IntToStr(length(my_entry.millings[0]));
      Rowcount:= Rowcount + 1;
    end;
    Rowcount:= Rowcount - 1;
    Col:= 1;
    if (HiliteBlock >= 0) and (HiliteBlock < RowCount) then
      Row:= HiliteBlock + 1
    else
      Row:= 1;
  end;
end;


procedure TForm1.SgBlocksDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  i: Integer;
  aRect: TRect;
  aStr: String;
begin
  Rect.Left:= Rect.Left-4; // Workaround für XE8-Darstellung
  with SgBlocks,Canvas do begin
    aStr:= Cells[ACol, ARow];
    if (aRow = 0) or (aCol = 0) then begin
      Font.Style := [fsBold];
      TextRect(Rect, Rect.Left + 2, Rect.Top + 2, Cells[ACol, ARow]);
    end else if aRow <= length(final_array) then begin
      Font.Color := clblack;
      case aCol of
        2,4:
          begin  // ON, OFF
            FrameRect(Rect);
            inc(Rect.Left);
            inc(Rect.Top);
            Brush.Color := clgray;
            FrameRect(Rect);
            Brush.Color := cl3Dlight;
            InflateRect(Rect, -1, -1);
            if aStr = 'ON' then
              Font.Style := [fsBold]
            else
              Font.Style := [];
            FillRect(Rect);
            aRect := Rect;
            if aCol = 4 then begin
              i:= ord(final_array[aRow-1].shape);
              Font.Color:= ShapeColorArray[i];
              aStr:= ShapeArray[i];
            end;
            aRect.Top := aRect.Top + 1; // adjust top to center vertical
            DrawText(Canvas.Handle, PChar(aStr), Length(aStr), aRect, DT_CENTER);
          end;
        else begin
          if not final_array[aRow-1].enable then begin
            Brush.Color := clBtnFace;
            Font.Color:=clgrayText;
          end;
          if (HiliteBlock = aRow-1) then
            Font.Color := clred;
        end;
        TextRect(Rect, Rect.Left + 2, Rect.Top + 2, aStr);
      end;
    end;
  end;
end;

procedure TForm1.SgBlocksMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  my_bool: Boolean;
begin
  UnHilite;
  with SgBlocks do begin
    HiliteBlock:= Row - 1;
    my_bool:= false;
    if Col = 2 then begin
      if Cells[2, Row] = 'ON' then
        Cells[2, Row]:= 'OFF'
      else if Cells[2, Row] = 'OFF' then begin
        Cells[2, Row]:= 'ON';
        my_bool:= true;
      end;
      final_array[HiliteBlock].enable:= my_bool;
      Form4.FormRefresh(sender);
    end else if Col = 4 then begin
      if final_array[Row-1].shape = drillhole then
        final_array[Row-1].shape:= online
      else
        inc(final_array[HiliteBlock].shape);
      Cells[4,Row]:= ShapeArray[ord(final_array[HiliteBlock].shape)];
      item_change(HiliteBlock);
      Form4.FormRefresh(sender);
    end;
  end;
end;

procedure TForm1.SgBlocksClick(Sender: TObject);
// wird nach Loslassen der Maustaste ausgeführt!
begin
  SgBlocks.Repaint;
  NeedsRedraw:= true;
end;

