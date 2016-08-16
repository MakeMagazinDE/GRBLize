// #############################################################################
// ############################ BLOCKS GRID PAGE ###############################
// #############################################################################

function ListBlocks: boolean;
// Listet Blocks im Path-Tab
// und stellt fest, ob Teile außerhalb des Werkstücks sind; liefert TRUE wenn ja
var i, my_len, my_row, my_pathcount: Integer;
  my_entry: Tfinal;
  x1, y1, x2, y2: Double;
  out_of_work: Boolean;
  my_offset: TIntPoint;
  my_bounds: Tbounds;
begin
  result:= false;
  try
    with Form1.SgBlocks do begin
      Rowcount:= 2;
  //    Rows[1].clear;
      my_len:= length(final_array);
      if my_len < 1 then begin
        HiliteBlock:= -1;
        final_bounds.min.x:= 0;
        final_bounds.min.y:= 0;
        final_bounds.max.x:= round(job.partsize_x * c_hpgl_scale);
        final_bounds.max.y:= round(job.partsize_y * c_hpgl_scale);
        exit;
      end;
      final_bounds.min.x:= high(integer);
      final_bounds.min.y:= high(integer);
      final_bounds.max.x:= low(integer);
      final_bounds.max.y:= low(integer);
      if HiliteBlock >= my_len then
        HiliteBlock:= my_len - 1;
      for i:= 0 to my_len-1 do begin
        my_entry:= final_array[i];
        my_pathcount:= length(my_entry.millings);
        out_of_work:= false;
        if my_pathcount < 1 then
          continue;
        // '#,Pen,Ena,Dia,Shape,Bounds,Center';
        my_row:= Rowcount - 1;
        Cells[0,my_row]:= IntToStr(my_row);
        Cells[1,my_row]:= IntToStr(my_entry.pen);
        my_bounds:= my_entry.bounds;
        my_offset:= job.pens[my_entry.pen].offset;
        my_bounds.min.x:= my_bounds.min.x + my_offset.x;
        my_bounds.min.y:= my_bounds.min.y + my_offset.y;
        my_bounds.max.x:= my_bounds.max.x + my_offset.x;
        my_bounds.max.y:= my_bounds.max.y + my_offset.y;
        my_bounds.mid.x:= my_bounds.mid.x + my_offset.x;
        my_bounds.mid.y:= my_bounds.mid.y + my_offset.y;
        if my_bounds.min.x < final_bounds.min.x then
          final_bounds.min.x:= my_bounds.min.x;
        if my_bounds.min.y < final_bounds.min.y then
          final_bounds.min.y:= my_bounds.min.y;
        if my_bounds.max.x > final_bounds.max.x then
          final_bounds.max.x:= my_bounds.max.x;
        if my_bounds.max.y > final_bounds.max.y then
          final_bounds.max.y:= my_bounds.max.y;

        x1:= my_bounds.min.x / c_hpgl_scale;
        y1:= my_bounds.min.y / c_hpgl_scale;
        x2:= my_bounds.max.x / c_hpgl_scale;
        y2:= my_bounds.max.y / c_hpgl_scale;
        if my_entry.enable then begin
          if (x1 < 0) then
            out_of_work:= true;
          if (y1 < 0) then
            out_of_work:= true;
          if (x2 > job.partsize_x) then
            out_of_work:= true;
          if (y2 > job.partsize_y) then
            out_of_work:= true;
        end;
        if out_of_work then begin
          // Form1.Memo1.lines.add('WARNING: Tool path ' + IntToStr(i+1) + ' outside work - disabled');
          my_entry.enable:= false;
          final_array[i].enable:= false;
          result:= true;
        end;
        if my_entry.enable then
          Cells[2,my_row]:= 'ON'
        else
          Cells[2,my_row]:= 'OFF';
        Cells[3,my_row]:= FormatFloat('0.0', job.pens[my_entry.pen].diameter);
        Cells[4,my_row]:= ShapeArray[ord(my_entry.shape)];
        Cells[5,my_row]:= FormatFloat('0.00', x1) + '/' + FormatFloat('0.00', y1)
            + ' - ' + FormatFloat('0.00', x2) + '/' + FormatFloat('0.00', y2);
        x1:= my_entry.bounds.mid.x / c_hpgl_scale;
        y1:= my_entry.bounds.mid.y / c_hpgl_scale;
        Cells[6,my_row]:= FormatFloat('0.00', x1) + '/' + FormatFloat('0.00', y1);
        Cells[7,my_row]:= IntToStr(length(my_entry.millings[0]));
        if my_entry.closed then
          Cells[7,my_row]:= '[' + IntToStr(length(my_entry.millings[0])) + ']'
        else
          Cells[7,my_row]:= '-' + IntToStr(length(my_entry.millings[0])) + '-';
        Rowcount:= Rowcount + 1;
      end;
      Rowcount:= Rowcount - 1;
      Col:= 1;
      if (HiliteBlock >= 0) and (HiliteBlock < RowCount) then
        Row:= HiliteBlock + 1
      else
        Row:= Rowcount - 1;
    end;
  finally
    if isSimActive then
      ResetCoordinates;
    if result then begin
      Form1.Memo1.lines.add('WARNING: Tool paths outside work area disabled');
    end;
    AutoAssignATCtoolsToJob;
    if Form1.CheckUseATC2.checked then
      Form1.LabelATCmsg.Caption:= 'ATC placement'
    else
      Form1.LabelATCmsg.Caption:= 'Tools used';
    final_bounds.mid.x:= (final_bounds.min.x + final_bounds.max.x) div 2;
    final_bounds.mid.y:= (final_bounds.min.y + final_bounds.max.y) div 2;
    final_bounds_mm.min.x:= final_bounds.min.x / c_hpgl_scale;
    final_bounds_mm.min.y:= final_bounds.min.y / c_hpgl_scale;
    final_bounds_mm.max.x:= final_bounds.max.x / c_hpgl_scale;
    final_bounds_mm.max.y:= final_bounds.max.y / c_hpgl_scale;
    final_bounds_mm.mid.x:= final_bounds.mid.x / c_hpgl_scale;
    final_bounds_mm.mid.y:= final_bounds.mid.y / c_hpgl_scale;
    GLSneedsATCupdateTimeout:= 0;
    GLSneedsRedrawTimeout:= 1;
    GLScenterBlock(final_bounds);
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
        1:
          begin
            if length(final_array) > 0 then
              i:= ord(final_array[aRow-1].pen)
            else
              i:= 0;
            Rect.Left:= Rect.Left + 24;
//            InflateRect(Rect, -1, -1);
            Brush.Color := clgray;
            FrameRect(Rect);
            InflateRect(Rect, -2, -2);
            Brush.Color := job.pens[i].color;
            FillRect(Rect);
          end;
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
  my_shape: Tshape;
  my_row, my_col: integer;
begin
  SgBlocks.MouseToCell( X,Y, my_col, my_row );
  if (my_row < 1) or (my_col < 1) then
    exit;
  UnHilite;
  with SgBlocks do begin
    HiliteBlock:= my_Row - 1;
    my_bool:= false;
    if my_col = 2 then begin
      if Cells[2, my_row] = 'ON' then
        Cells[2, my_row]:= 'OFF'
      else if Cells[2, my_row] = 'OFF' then begin
        Cells[2, my_row]:= 'ON';
        my_bool:= true;
      end;
      final_array[HiliteBlock].enable:= my_bool;
      GLSneedsRedrawTimeout:= 1;
      AutoAssignATCtoolsToJob;
    end else if my_col = 4 then begin
      my_shape:= final_array[HiliteBlock].shape;
      if my_shape >= drillhole then
        my_shape:= contour
      else
        inc(my_shape);
      if (ssRight in Shift) then      // reset to default mit rechter Maustaste
        my_shape:= contour;
      final_array[HiliteBlock].shape:= my_shape;
      Cells[4,my_Row]:= ShapeArray[ord(my_shape)];
      if (my_shape = inside) or  (my_shape = pocket) then
        final_array[HiliteBlock].closed:= true
      else
        final_array[HiliteBlock].closed:= final_array[HiliteBlock].was_closed;
      item_change(HiliteBlock);
      ListBlocks;
    end;
  end;
end;

procedure TForm1.SgBlocksClick(Sender: TObject);
// wird nach Loslassen der Maustaste ausgeführt!
begin
  SgBlocks.Repaint;
  NeedsRedraw:= true;
  GLSneedsATCupdateTimeout:= 0;
end;

