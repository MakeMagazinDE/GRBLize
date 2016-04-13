// #############################################################################
// HPGL Import
// #############################################################################

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

procedure hpgl_import_line(my_line: String; fileID, penOverride: Integer);
// Actions: none, lift, seek, drill, mill
var
  my_x, my_y: Integer;
  my_pos: Integer;
  my_cmd: THPGL_cmd;
  my_valid: boolean;
  my_pen: Integer;
  xx, yy: Double;
  dummy_str: String;

begin
  my_pos:= 1;
  repeat
    my_cmd:= get_hpgl_cmd(my_pos, my_line);
    if my_cmd = cmd_exit then
      exit;
    case my_cmd of
      cmd_pa:
        begin
          my_valid:= ParseLine(my_pos, my_line, xx, dummy_str) = p_number;
          my_valid:= my_valid and (ParseLine(my_pos, my_line, yy, dummy_str) = p_number);
          if my_valid then begin
            LastPoint.x:= round(xx);
            LastPoint.y:= round(yy);
          end;
          if LastAction >= mill then begin // war unten
            append_point(fileID, CurrentBlockID, LastPoint);
            blockArrays[fileID, CurrentBlockID].pen:= CurrentPen;
          end;
        end;
      cmd_pu:
        begin
          my_valid:= ParseLine(my_pos, my_line, xx, dummy_str) = p_number;
          my_valid:= my_valid and (ParseLine(my_pos, my_line, yy, dummy_str) = p_number);
          if my_valid then begin
            LastPoint.x:= round(xx);
            LastPoint.y:= round(yy);
          end;
          LastAction:= seek;
        end;
      cmd_pd:
        begin
          if LastAction <= seek then begin
          // war oben, letzte Koordinaten sind erster Punkt im Block
            CurrentBlockID:= new_block(fileID);
            append_point(fileID, CurrentBlockID, LastPoint);
            blockArrays[fileID, CurrentBlockID].pen:= CurrentPen;
          end;

          my_valid:= ParseLine(my_pos, my_line, xx, dummy_str) = p_number;
          my_valid:= my_valid and (ParseLine(my_pos, my_line, yy, dummy_str) = p_number);
          if my_valid then begin
            LastPoint.x:= round(xx);
            LastPoint.y:= round(yy);
          end;
          append_point(fileID, CurrentBlockID, LastPoint);
          LastAction:= mill;
        end;
      cmd_in:
        begin
          ParseLine(my_pos, my_line, xx, dummy_str);
          ParseLine(my_pos, my_line, xx, dummy_str);
          LastAction:= lift;
        end;
      cmd_sp:
        begin
          my_valid:= ParseLine(my_pos, my_line, xx, dummy_str) = p_number;
          my_pen:= round(xx);
          if penOverride >= 0 then
            my_pen:= penoverride;
          if my_valid and (my_pen < 10) then begin
            CurrentPen:= my_pen;
            job.pens[my_pen].used:= true;
            job.pens[my_pen].enable:= true;
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

  CurrentPen:= 0;
  LastAction:= lift;
  LastPoint.x:= 0;
  LastPoint.y:= 0;
  for i:= 0 to my_sl.count-1 do begin
    hpgl_import_line(my_sl[i], fileID, penOverride);
  end;
  my_sl.free;
  FileParamArray[fileID].valid := true;
  file_rotate_mirror(fileID, true); // auto close path
  block_scale_file(fileID);
end;

// #############################################################################
// SVG Import
// #############################################################################

procedure svg_fileload(my_name:String; fileID, penOverride: Integer);
// SEHR simpler svg-Parser nur für pcb2gcode-SVGs!
// nutzt
// function ParseLine(var position: Integer; var linetoparse: string;
//                    var value: Double; var letters: String): T_parseReturnType;
// SVG-Zeilen können SEHR lang sein, StringList hat deshalb wenig Vorteile

var
  my_ReadFile: TextFile;
  i, n, my_pos: Integer;
  my_line, my_str, my_cmd_str: String;
  my_cmd, my_dummy: char;
  my_val: Double;

  next_is_first_point: boolean;
  my_x, my_y: integer;  // gebraucht werden HPGL-Koordinaten!
  my_firstpoint: TIntpoint;  // gebraucht werden HPGL-Koordinaten!

begin
  if not FileExists(my_name) then begin
    FileParamArray[fileID].valid := false;
    exit;
  end;
  if penOverride < 1 then
    penOverride:= 9;
  job.pens[penOverride].used:= true;
  FileParamArray[fileID].bounds.min.x := high(Integer);
  FileParamArray[fileID].bounds.min.y := high(Integer);
  FileParamArray[fileID].bounds.max.x := low(Integer);
  FileParamArray[fileID].bounds.max.y := low(Integer);

  my_line:= '';
  my_cmd_str:= '';

  FileMode := fmOpenRead;
  AssignFile(my_ReadFile, my_name);
  Reset(my_ReadFile);
  while not Eof(my_ReadFile) do begin
    Readln(my_ReadFile, my_line);
    if pos('<path', my_line) > 0 then
      break;
  end;
  next_is_first_point:= true;
  while not Eof(my_ReadFile) do begin
    my_pos:= pos(' d="', my_line) + 3;
    if my_pos > 3 then
      repeat
        if ParseLine(my_pos, my_line, my_val, my_cmd_str) = p_letters then begin
          my_cmd:= my_cmd_str[1]; // ist immer nur ein Buchstabe
          case my_cmd of
            'M':
              begin
                // c_hpgl_scale * Punkt US-amer.?
                if ParseLine(my_pos, my_line, my_val, my_cmd_str) = p_number then
                  LastPoint.x:= round(my_val * c_hpgl_scale * 0.352777);
                if ParseLine(my_pos, my_line, my_val, my_cmd_str) = p_number then
                  LastPoint.y:= round(my_val * c_hpgl_scale * 0.352777);

                if next_is_first_point or (LastAction = lift) then begin
                  my_firstpoint.x:= LastPoint.x + 0;
                  my_firstpoint.y:= LastPoint.y + 0;
                end;
                next_is_first_point:= false;
                LastAction:= lift;
              end;
            'L':
              begin
                if LastAction = lift then begin
                  CurrentBlockID:= new_block(fileID);
                  blockArrays[fileID, CurrentBlockID].pen:= penOverride;
                  append_point(fileID, CurrentBlockID, LastPoint);
                end;
                if ParseLine(my_pos, my_line, my_val, my_cmd_str) = p_number then
                  LastPoint.x:= round(my_val * c_hpgl_scale * 0.352777);
                if ParseLine(my_pos, my_line, my_val, my_cmd_str) = p_number then
                  LastPoint.y:= round(my_val * c_hpgl_scale * 0.352777);
                LastAction:= mill;
                next_is_first_point:= false;
                append_point(fileID, CurrentBlockID, LastPoint);
              end;
            'Z':
              begin
                next_is_first_point:= true;
                LastAction:= lift;
                append_point(fileID, CurrentBlockID, my_firstpoint);
              end;
          end;
        end;
        inc(my_pos);
      until my_pos >= length(my_line) - 3;
    Readln(my_ReadFile, my_line);
  end;

  CloseFile(my_ReadFile);

  CurrentPen:= 0;
  LastAction:= lift;
  LastPoint.x:= 0;
  LastPoint.y:= 0;
  blockArrays[fileID, CurrentBlockID].closed:= false;
  FileParamArray[fileID].valid := true;
  file_rotate_mirror(fileID, false); // kein Auto-close!
  block_scale_file(fileID);
end;


// #############################################################################
// GCode 2D Import, berücksichtigt kein Z bzw. nur über/unter Null
// #############################################################################

procedure gcode_import_line(my_line: String; fileID, penOverride: Integer);
// Simpler Gcode-Parser für 2D-Daten. Ignoriert Z-Tiefe, sondern entscheidet
// anhandh G0/G1, ob verfahren oder gefräst wird.
// Einfaches Format, zeilenorientiert.
// nutzt
// function ParseLine(var position: Integer; var linetoparse: string;
//                    var value: Double; var letters: String): T_parseReturnType;
// Actions: none, lift, seek, drill, mill
var
  my_cmd: char;
  my_pos, my_len: Integer;
  my_valid: boolean;
  my_pen: Integer;
  my_dval: Double;
  my_cmd_str, my_dummy_str: String;
  got_new_xy: Boolean;
  my_action: tAction;

begin
  if penOverride < 1 then
    penOverride:= 9;
  job.pens[penOverride].used:= true;
  FileParamArray[fileID].bounds.min.x := high(Integer);
  FileParamArray[fileID].bounds.min.y := high(Integer);
  FileParamArray[fileID].bounds.max.x := low(Integer);
  FileParamArray[fileID].bounds.max.y := low(Integer);
  my_pos:= 1;
  my_len:= length(my_line) - 1;
  if my_pos > my_len then // Leerzeile
    exit;
  got_new_xy:= false;
  repeat
    if (my_line[my_pos] = '(') or (my_line[my_pos] = '/') then   // Kommentar
      break;
    if ParseLine(my_pos, my_line, my_dval, my_cmd_str) = p_letters then begin
      my_cmd:= my_cmd_str[1];
      case my_cmd of
        'G':
          begin
            if ParseLine(my_pos, my_line, my_dval, my_cmd_str) = p_number then begin
              if my_dval = 0 then
                my_action:= seek
              else if my_dval = 1 then
                my_action:= mill
              else
                break; // alles andere in dieser Zeile ignorieren
            end;
          end;
        'X':
          if ParseLine(my_pos, my_line, my_dval, my_cmd_str) = p_number then begin
            LastPoint.x:= round(my_dval * c_hpgl_scale);
            got_new_xy:= true;
          end;
        'Y':
          if ParseLine(my_pos, my_line, my_dval, my_cmd_str) = p_number then begin
            LastPoint.y:= round(my_dval * c_hpgl_scale);
            got_new_xy:= true;
          end;
        'Z':
          ParseLine(my_pos, my_line, my_dval, my_cmd_str); // war eigentlich schon durch G0/G1 klar

        'M':
          begin // Modale Maschinenbefehle abbrechen, irrelevant
            my_action:= none;
            break;
          end;

        'F', 'S':
          ParseLine(my_pos, my_line, my_dval, my_cmd_str); // dummy
      end;
    end;
    inc(my_pos);
  until my_pos > my_len;
  if (LastAction = none) or ((my_action >= mill) and (LastAction < mill)) then begin
    CurrentBlockID:= new_block(fileID);
    blockArrays[fileID, CurrentBlockID].pen:= penOverride;
  end;
  if got_new_xy and (my_action >= mill) then begin
    append_point(fileID, CurrentBlockID, LastPoint);
  end;
  LastAction:= my_action;
end;

// #############################################################################

procedure gcode_fileload(my_name:String; fileID, penOverride: Integer);
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
  my_sl.loadfromfile(my_name);

  CurrentPen:= 0;
  LastAction:= none;
  LastPoint.x:= 0;
  LastPoint.y:= 0;
  for i:= 0 to my_sl.count-1 do begin
    gcode_import_line(my_sl[i], fileID, penOverride);
  end;
  my_sl.free;
  FileParamArray[fileID].valid := true;
  file_rotate_mirror(fileID, true); // auto close path
  block_scale_file(fileID);
end;


