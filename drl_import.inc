// #############################################################################
// Excellon Import
// #############################################################################

function get_drill_val(var my_pos: Integer; var my_line: string; var my_result: LongInt):boolean;
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

function get_drill_cmd(var my_pos: Integer; var my_line: string): THPGL_cmd;
begin
  if my_line[my_pos] = ';' then begin  // Kommentar
    result:= cmd_nextline;
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
  if pos('X',my_line) = my_pos then begin
    result:= cmd_pa;
    my_pos:= my_pos+2;
    exit;
  end;
  if pos('Y',my_line) = my_pos then begin
    result:= cmd_pa;
    my_pos:= my_pos+2;
    exit;
  end;
  if pos('T',my_line) = my_pos then begin
    result:= cmd_sp;
    my_pos:= my_pos+2;
    exit;
  end;
  if pos('INCH',my_line) = my_pos then begin
    result:= cmd_nextline;
    my_pos:= my_pos+4;
    exit;
  end;
  if pos('M48',my_line) = my_pos then begin
    result:= cmd_nextline;
    my_pos:= my_pos+3;
    exit;
  end;
  result:= cmd_exit;  // alle anderen Befehle ignorieren
end;

procedure drill_import_line(my_str: String; fileID, penOverride: Integer);
// Actions: none, lift, seek, drill, mill
var
  my_x, my_y: Integer;
  my_pos: Integer;
  my_cmd: THPGL_cmd;
  my_valid: boolean;
  my_pen: Integer;
  my_import_entry: Timport_record;

begin
  my_pos:= 1;
  repeat
    with my_import_entry do begin  // mit letzten Werten vorbelegen
      if penOverride >= 0 then
        Pen:= penoverride
      else
        Pen:= CurrentPen;
      X:= Last_X;
      Y:= Last_Y;
      Z:= 0;
      action:= PendingAction;
    end;
    my_cmd:= get_hpgl_cmd(my_pos, my_str);
    if my_cmd = cmd_exit then
      exit;
    case my_cmd of
      cmd_pa:
        begin
          my_valid:= get_hpgl_val(my_pos, my_str, my_x);
          my_valid:= my_valid and get_hpgl_val(my_pos, my_str, my_y);
          if my_valid then begin
            Last_X:= my_x;
            Last_Y:= my_y;
            my_import_entry.X:= Last_X;
            my_import_entry.Y:= Last_Y;
            append_importArray(my_import_entry, fileID);
          end;
        end;
      cmd_in:
        begin
          get_hpgl_val(my_pos, my_str, my_x); // Dummies, ignored
          get_hpgl_val(my_pos, my_str, my_y);
          PendingAction:= lift;
        end;
      cmd_sp:
        begin
          my_valid:= get_hpgl_val(my_pos, my_str, my_pen);
          if penOverride >= 0 then
            my_pen:= penoverride;
          if my_valid and (my_pen < 9) then begin
            CurrentPen:= my_pen;
            job.pens[my_pen].used:= true;
            // job.enables[my_pen]:= true;
          end else
            CurrentPen:= 0;
          PendingAction:= lift;
        end;
    end;
  until false;
end;

// #############################################################################

procedure drill_fileload(my_name:String; fileID, penOverride: Integer);
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
  my_sl:= TStringList.Create;
  my_line:='';
  FileMode := fmOpenRead;
  AssignFile(my_ReadFile, my_name);
  Reset(my_ReadFile);
  // Tool-Tabelle laden
  while not Eof(my_ReadFile) do begin
    Readln(my_ReadFile,my_line);
    my_sl.Add(my_line);
    if my_line = '%' then
      exit;
  end;
  if my_line <> '%' then
    showmessage('Drill file invalid!');

  CloseFile(my_ReadFile);
  Last_x:= 0;
  Last_y:= 0;
  CurrentPen:= 0;
  CurrentAction:= none;
  PendingAction:= lift;
  for i:= 0 to my_sl.count-1 do begin
//    drill_import_line(my_sl[i], fileID, penOverride);
  end;
  my_sl.free;
  FileParamArray[fileID].valid := true;
end;


