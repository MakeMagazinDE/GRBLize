// #############################################################################
// ############################ BLOCKS GRID PAGE ###############################
// #############################################################################

function ListBlocks: boolean;
// Listet Blocks im Path-Tab
// und stellt fest, ob Teile außerhalb des Werkstücks sind; liefert TRUE wenn ja
var i, j, my_len, my_millingcount, my_row, my_pathcount: Integer;
//  my_entry: Tfinal;
  x1, y1, x2, y2: Double;
//  out_of_work: Boolean;
  my_offset: TIntPoint;
  my_bounds: Tbounds;
  my_str: String;
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
        //my_entry:= final_array[i];
        my_pathcount:= length(final_array[i].millings);
        final_array[i].out_of_work:= false;
        if my_pathcount < 1 then
          continue;
        // '#,Pen,Ena,Dia,Shape,Bounds,Points';
        my_row:= Rowcount - 1;
        Cells[0,my_row]:= IntToStr(my_row);
        Cells[1,my_row]:= IntToStr(final_array[i].pen);
        my_bounds:= final_array[i].bounds;
        my_offset:= job.pens[final_array[i].pen].offset;
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
        if final_array[i].enable then begin
          if (x1 < 0) then
            final_array[i].out_of_work:= true;
          if (y1 < 0) then
            final_array[i].out_of_work:= true;
          if (x2 > job.partsize_x) then
            final_array[i].out_of_work:= true;
          if (y2 > job.partsize_y) then
            final_array[i].out_of_work:= true;
        end;
        if final_array[i].out_of_work then begin
          Form1.Memo1.lines.add('WARNING: Tool path ' + IntToStr(i+1) + ' outside work - disabled');
//          final_array[i].enable:= false;
          result:= true;
        end;
        Cells[3,my_row]:= FormatFloat('0.0', job.pens[final_array[i].pen].diameter);
        Cells[4,my_row]:= ShapeArray[ord(final_array[i].shape)];
        // Enable-Flag für einzelne Pfade setzen
        my_millingcount:= length(final_array[i].millings);
        my_str:='';
        if final_array[i].enable then begin
          Cells[2,my_row]:= 'ON';
          if my_millingcount > 0 then
            for j := 0 to my_millingcount-1 do begin
              if final_array[i].milling_enables[j] then
                if final_array[i].closed then
                  my_str:= my_str + '[' + IntToStr(length(final_array[i].millings[j])) + '] '
                else
                  my_str:= my_str + '-' + IntToStr(length(final_array[i].millings[j])) + '- ';
            end;
        end else
          Cells[2,my_row]:= 'OFF';
        Cells[5,my_row]:= my_str;
        Rowcount:= Rowcount + 1;
      end;
      Rowcount:= Rowcount - 1;
      Col:= 2;
      if (HiliteBlock >= 0) and (HiliteBlock < RowCount - 1) then
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
              aStr:= ShapeArray[i];
              Font.Color:= ShapeColorArray[i];
              if (not final_array[aRow-1].closed)
              and (final_array[aRow-1].shape in [inside, pocket]) then
              // inside und pocket müssen geschlossene Polygone sein
                Font.style:= [fsStrikeOut]
              else
                Font.style:= [];
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
  my_shape: Tshape;
  my_row, my_col, my_top: integer;
begin
  SgBlocks.MouseToCell( X,Y, my_col, my_row );
  if (my_row < 1) or (my_col < 1) then
    exit;
  SgBlocks.Col := my_col;
  SgBlocks.Row := my_row;
  with SgBlocks do begin
    HiliteBlock:= my_Row - 1;
    if my_col = 2 then begin
      my_top:=SgBlocks.toprow;
      final_array[my_row-1].enable:= not final_array[my_row-1].enable;
      enable_all_millings(final_array[my_row-1], final_array[my_row-1].enable);
      ListBlocks;
      GLSneedsRedrawTimeout:= 1;
      AutoAssignATCtoolsToJob;
      SgBlocks.toprow:= my_top;
    end else if (my_col = 4) and (my_row > 0) then begin
      perform( WM_CANCELMODE, 0, 0 ); // verhindert Mausaktion in Stringgrid
      uncheck_mbs;
      my_shape:= final_array[HiliteBlock].shape;
      PopupMenuBlockShape.Items[ord(my_shape)].Checked:= true;
      PopupMenuBlockShape.Popup(X+left+Form1.left, Y+ top+Form1.top);
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

