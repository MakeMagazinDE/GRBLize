// #############################################################################
// HPGL Import
// #############################################################################

function get_hpgl_val(var my_pos: Integer; var my_line: string; var my_result: LongInt):boolean;
var
  my_str: String;
  my_char: char;
begin
  while (my_line[my_pos] in ['a'..'z', 'A'..'Z', ' ', ',']) and (my_pos <= length(my_line)) do
    inc(my_pos);
  result:= false;
  if (my_pos > length(my_line)) then
    exit;
  my_str:= '';
  while (my_line[my_pos] in ['0'..'9', '.',  '+', '-']) and (my_pos <= length(my_line)) do begin
    my_char:= my_line[my_pos];
    my_str:= my_str+ my_char;
    inc(my_pos);
    result:= true;
  end;
  if result then
    my_result:= StrToInt(my_str);
end;

function get_hpgl_cmd(var my_pos: Integer; var my_line: string): THPGL_cmd;
begin
  if my_line[my_pos] = ';' then begin
    result:= cmd_exit;
    exit;
  end;
  if my_pos >= length(my_line) then begin
    result:= cmd_exit;
    exit;
  end;
  if my_line[my_pos] in ['0'..'9', '-', '+'] then begin
    result:= cmd_number;
    exit;
  end;
  if pos('PA',my_line) = my_pos then begin
    result:= cmd_pa;
    my_pos:= my_pos+2;
    exit;
  end;
  if pos('PU',my_line) = my_pos then begin
    result:= cmd_pu;
    my_pos:= my_pos+2;
    exit;
  end;
  if pos('PD',my_line) = my_pos then begin
    result:= cmd_pd;
    my_pos:= my_pos+2;
    exit;
  end;
  if pos('SP',my_line) = my_pos then begin
    result:= cmd_sp;
    my_pos:= my_pos+2;
    exit;
  end;
  if pos('IN',my_line) = my_pos then begin
    result:= cmd_in;
    my_pos:= my_pos+2;
    exit;
  end;
  if pos('LT',my_line) = my_pos then begin
    result:= cmd_none;
    my_pos:= my_pos+2;
    exit;
  end;
  result:= cmd_exit;  // alle anderen Befehle ignorieren
end;


procedure hpgl_import_line(my_str: String; fileID, penOverride: Integer);
// Actions: none, lift, seek, drill, mill
var
  my_x, my_y: Integer;
  my_pos: Integer;
  my_cmd: THPGL_cmd;
  my_valid: boolean;
  my_pen: Integer;

begin
  my_pos:= 1;
  repeat
    my_cmd:= get_hpgl_cmd(my_pos, my_str);
    if my_cmd = cmd_exit then
      exit;
    case my_cmd of
      cmd_pa:
        begin
          my_valid:= get_hpgl_val(my_pos, my_str, my_x);
          my_valid:= my_valid and get_hpgl_val(my_pos, my_str, my_y);
          if my_valid then begin
            LastPoint.x:= my_x;
            LastPoint.y:= my_y;
          end;
          if LastAction >= mill then begin // war unten
            append_point(fileID, CurrentBlockID, LastPoint);
            blockArrays[fileID, CurrentBlockID].pen:= CurrentPen;
          end;
        end;
      cmd_pu:
        begin
          my_valid:= get_hpgl_val(my_pos, my_str, my_x);
          my_valid:= my_valid and get_hpgl_val(my_pos, my_str, my_y);
          if my_valid then begin
            LastPoint.x:= my_x;
            LastPoint.y:= my_y;
          end;
          LastAction:= seek;
        end;
      cmd_pd:
        begin
          if LastAction < mill then begin // war unten
            CurrentBlockID:= new_block(fileID);
            append_point(fileID, CurrentBlockID, LastPoint);
          end;

          my_valid:= get_hpgl_val(my_pos, my_str, my_x);
          my_valid:= my_valid and get_hpgl_val(my_pos, my_str, my_y);
          if my_valid then begin
            LastPoint.x:= my_x;
            LastPoint.y:= my_y;
          end;
          append_point(fileID, CurrentBlockID, LastPoint);
          blockArrays[fileID, CurrentBlockID].pen:= CurrentPen;
          LastAction:= mill;
        end;
      cmd_in:
        begin
          get_hpgl_val(my_pos, my_str, my_x); // Dummies, ignored
          get_hpgl_val(my_pos, my_str, my_y);
          LastAction:= lift;
        end;
      cmd_sp:
        begin
          my_valid:= get_hpgl_val(my_pos, my_str, my_pen);
          if penOverride >= 0 then
            my_pen:= penoverride;
          if my_valid and (my_pen < 10) then begin
            CurrentPen:= my_pen;
            job.pens[my_pen].used:= true;
            // job.enables[my_pen]:= true;
          end else
            CurrentPen:= 0;
          LastAction:= lift;
        end;
    end;
  until false;
end;

// #############################################################################

procedure hpgl_fileload(my_name:String; fileID, penOverride: Integer);
// Liest File in FileBuffer und liefert Länge zurück
var
  my_ReadFile: TextFile;
  i: Integer;
  my_line: String;
  my_char: char;
  my_sl: TStringList;

begin
  if not FileExists(my_name) then begin
    FileParamArray[fileID].valid := false;
    exit;
  end;
  FileParamArray[fileID].bounds.min.x := high(Integer);
  FileParamArray[fileID].bounds.min.y := high(Integer);
  FileParamArray[fileID].bounds.max.x := low(Integer);
  FileParamArray[fileID].bounds.max.y := low(Integer);
  my_sl:= TStringList.Create;
  my_line:='';
  FileMode := fmOpenRead;
  AssignFile(my_ReadFile, my_name);
  Reset(my_ReadFile);
  while not Eof(my_ReadFile) do begin
    Read(my_ReadFile,my_char);
    if my_char >= #32 then
      my_line:= my_line + my_char;
    if my_char= ';' then begin
      my_sl.Add(my_line);
      my_line:='';
    end;
  end;
  CloseFile(my_ReadFile);
  my_line:='SP0;';
  my_sl.Add(my_line);
  my_line:='PA0 0;';
  my_sl.Add(my_line);

  CurrentPen:= 0;
  LastAction:= lift;
  for i:= 0 to my_sl.count-1 do begin
    hpgl_import_line(my_sl[i], fileID, penOverride);
  end;
  my_sl.free;
  FileParamArray[fileID].valid := true;
  file_rotate_mirror(fileID);
  block_scale_file(fileID);
end;

