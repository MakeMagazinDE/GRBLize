// #############################################################################
// Excellon Import
// #############################################################################

//function ParseLine(var position: Integer; var linetoparse: string;
//  var value: Double; var letters: String): T_parseReturnType;
// Zerlegt String nach Zahlen und Buchtstaben(ketten),
// beginnt my_line an Position my_pos nach Buchstaben oder Zahlen abzusuchen.
// Wurde eine Zahl gefunden, ist Result = p_number, ansonsten p_letter.
// Wurde nichts (mehr) gefunden, ist Result = p_endofline.
// POSITION zeigt zum Schluss auf das Zeichen NACH dem letzten gültigen Wert.
// T_parseReturnType = (p_none, p_endofline, p_letters, p_number);
{
function get_drill_val(var my_pos: Integer; var my_line: string;
                       var my_result: LongInt; getInt: Boolean): boolean;
var
  my_str: String;
  my_char: char;
  my_double, my_dec_fac: Double;
begin
  result:= false;
  if my_pos > length(my_line) then
    exit;
  while (my_line[my_pos] in ['0'..'9', '.',  '+', '-']) do begin
    my_char:= my_line[my_pos];
    my_str:= my_str+ my_char;
    inc(my_pos);
    result:= true;
    if (my_pos > length(my_line)) then
      break;
  end;
  if result then begin
    if getInt then
      my_result:= StrToIntDef(my_str,0)
    else begin
      my_double:= StrDotToFloat(my_str); // Default Fließkommawert
      // Enthält String einen Dezimalpunkt?
      if use_inches_in_drillfile then begin
      // Enthält String einen Dezimalpunkt?
        if not AnsiContainsStr(my_str, '.') then begin
          my_dec_fac:= power(10,4); // 4 = Anzahl der Nachkommastellen
          my_double:= my_double * 25.4 / my_dec_fac;
        end;
      end else begin
      // Enthält String einen Dezimalpunkt?
        if not AnsiContainsStr(my_str, '.') then begin
          my_dec_fac:= power(10,3); // 3 = Anzahl der Nachkommastellen
          my_double:= my_double / my_dec_fac;
        end;
      end;
      my_result:= round(my_double * int(c_hpgl_scale));
    end;
  end;
end;
}
procedure drill_import_line(my_line: String; fileID, penOverride: Integer; fac: Double);
// Actions: none, lift, seek, drill, mill
var
  my_x, my_y: double;
  my_pos: Integer;
  my_char: char;
  my_tool, my_block_Idx: Integer;
  num_dec_digits: Integer; // Anzahl Dezimalstellen
  my_val, my_fac: Double;

begin
  my_pos:= 1;
  repeat
    if my_pos > length(my_line) then
      exit;
    my_char:= my_line[my_pos];
    if my_char = ';' then
      exit;
    if not ParseCommand(my_pos, my_line, my_val, my_char) then
      exit;
    case my_char of
      'M': // M-Befehl, z.B. M30 = Ende
        exit;
      'T': // Tool change
        begin
          my_tool:= round(my_val);
          PendingAction:= lift;
          if (my_tool < 22) then
            CurrentPen:= my_tool + 10;
          if penOverride >= 0 then
            CurrentPen:= penoverride;
        end;
      'X':
        begin
          if PendingAction = lift then
            new_block(fileID);
          PendingAction:= none;
          if use_inches_in_drillfile then begin
          // Enthält String einen Dezimalpunkt?
            my_fac:= 25.4;                   // 4 = Anzahl der Nachkommastellen
            num_dec_digits:= 4;
          end else begin
          // Enthält String einen Dezimalpunkt?
            my_fac:= 1;
            num_dec_digits:= 3;             // 3 = Anzahl der Nachkommastellen
          end;

          if not AnsiContainsStr(my_line, '.') then
            my_fac:= my_fac / power(10, num_dec_digits);
          // es folgt immer ein Y-Wert
          if ParseCommand(my_pos, my_line, my_y, my_char) then
            my_x:= my_val * my_fac;
            my_y:= my_y * my_fac;
            LastPoint.X:= round(my_x * c_hpgl_scale);
            LastPoint.Y:= round(my_y * c_hpgl_scale);
            my_block_Idx:= length(blockArrays[fileID])-1;
            append_point(fileID, my_block_idx, LastPoint);
            blockArrays[fileID, my_block_idx].pen:= CurrentPen;
            check_filebounds(FileID, LastPoint);

//            blockArrays[fileID, my_block_idx].enable:= true;
          end;
        end;
  until false;
end;

// #############################################################################
{
procedure quickSort_path_X(var my_path: Tpath; iLo, iHi: Integer) ;
// evt später benötigt: Quicksort in einer bestimmten Richtung
// Hie X-Richtung
var
   pLo, pHi, Pivot: Integer;
   temp_pt: TintPoint;
begin
  pLo := iLo;
  pHi := iHi;
  Pivot := my_path[(pLo + pHi) div 2].x;
  repeat
    while my_path[pLo].x < Pivot do Inc(pLo) ;
    while my_path[pHi].x > Pivot do Dec(pHi) ;
    if pLo <= pHi then begin
      temp_pt := my_path[pLo];
      my_path[pLo] := my_path[pHi];
      my_path[pHi] := temp_pt;
      Inc(pLo) ;
      Dec(pHi) ;
    end;
  until pLo > pHi;
  if pHi > iLo then quickSort_path_X(my_path, iLo, pHi) ;
  if pLo < iHi then quickSort_path_X(my_path, pLo, iHi) ;
end;
}

procedure optimize_path(var my_path: Tpath);
// Optimierung eines Bohrloch-Pfades (Handlungsreisenden-Problem),
// hier (suboptimal) nach der Nearest-Neighbour-Methode gelöst
var
  i, p, my_len, found_idx: integer;
  optimized_path: Tpath;
  prefer_x, prefer_y: Integer;
  found_array: Array of Boolean;
  last_x, last_y, dx, dy,
  last_dx, last_dy, dv, dvo: Double;

begin
  my_len:= length(my_path);
  if my_len < 4 then
    exit; // zu kurz, drei Punkte sind immer optimal verbunden
  setlength(found_array, my_len);
  setlength(optimized_path, my_len);

  for i:= 0 to my_len-1 do
    found_array[i]:= false;
  // ausgehend vom Nullpunkt
  last_x:= 0;
  last_y:= 0;
  prefer_x:= 5;
  prefer_y:= 5;
  found_idx:= 0;

  for i:= 0 to my_len-1 do begin
    // alle nicht besuchten Punkte absuchen
    dvo:= high(Integer);
    for p:= 0 to my_len-1 do begin
      if found_array[p] then
        continue; // bereits besucht
      // finde nächstliegenden Punkt mit Vorzugsrichtung
      dx:= abs(my_path[p].x - last_x); // Abstand zum letzten gefundenen Punkt
      dy:= abs(my_path[p].y - last_y);
      dv:= sqrt(sqr(dx/prefer_x) + sqr(dy/prefer_y));
      // schneller und ausreichend: Absolutwerte addieren
      //dv:= ((dx * prefer_y) + (dy * prefer_x)) div 10;
      if dv <= dvo then begin
        found_idx:= p; // wird "mitgezogen"
        dvo:= dv;
        last_dx:= dx;
        last_dy:= dy;
      end;
    end;
    last_x:= my_path[found_idx].x;
    last_y:= my_path[found_idx].y;
    found_array[found_idx]:= true;
    optimized_path[i].x:= round(last_x);
    optimized_path[i].y:= round(last_y);
    // Abstand zum letzten gefundenen Punkt
    if last_dx > last_dy then begin     // bewegt sich in X-Richtung
      prefer_y:= 5;
      if prefer_x < 10 then
        inc(prefer_x);
    end else if last_dx < last_dy then begin  // bewegt sich in Y-Richtung
      prefer_x:= 5;
      if prefer_y < 10 then
        inc(prefer_y);
    end;
  end;
  my_path:= optimized_path;
end;

procedure optimize_drillfile(fileID: Integer);
var i: Integer;
begin
  if length(blockArrays[fileID]) = 0 then
    exit;
  for i:= 0 to length(blockArrays[fileID])-1 do
    // if job.pens[blockArrays[fileID, i].pen].enable then
      optimize_path(blockArrays[fileID, i].outline_raw);
end;

// #############################################################################
// EXCELLON DRILL (DRL) Import
// #############################################################################

// nach Vorschlag von Frank Kaiser frank.kaiser@fuxbau.netgeändert

procedure drill_fileload(my_name:String; fileID, penOverride: Integer; useDrillDia: Boolean);
// Liest File in FileBuffer und liefert Länge zurück
var
  my_ReadFile: TextFile;
  my_line: String;
  my_tool, my_pos: integer;
  my_val, my_fac: Double;
  invalid_header, my_valid: boolean;
  my_char: char;
  FirstLine : boolean;

begin
  if not FileExists(my_name) then begin
    FileParamArray[fileID].valid := false;
    exit;
  end;
  FileParamArray[fileID].bounds.min.x := high(Integer);
  FileParamArray[fileID].bounds.min.y := high(Integer);
  FileParamArray[fileID].bounds.max.x := low(Integer);
  FileParamArray[fileID].bounds.max.y := low(Integer);
  use_inches_in_drillfile:= false; // default METRIC
  my_line:='';
  FileMode := fmOpenRead;
  AssignFile(my_ReadFile, my_name);
  CurrentPen:= 10;
  PendingAction:= lift;
  invalid_header:= true;
  FirstLine := true;
  Reset(my_ReadFile);

  ///// Header mit Tool-Tabelle laden //////////////////////////////////////////
  my_fac:= 0.001;
  while not Eof(my_ReadFile) do begin
    Readln(my_ReadFile,my_line);
    if length(my_line) > 0 then begin
      if my_line[1] = ';' then
        continue;
      if my_line[1] = '(' then
        continue;
      if my_line[1] = '/' then
        continue;
    end;

    my_pos:= 1;

    if (my_line = '%') and FirstLine then begin
      FirstLine := false;
      if Eof(my_ReadFile) then break
      else begin
        Readln(my_ReadFile,my_line);
        ParseCommand(my_pos, my_line, my_val, my_char);
        if (my_char <> 'M') or (my_val <> 48) then break;
        continue;
      end;
    end;

    if AnsiContainsStr(my_line, 'INCH') then
      use_inches_in_drillfile:= true;
    if AnsiContainsStr(my_line, 'METRIC') then
      use_inches_in_drillfile:= false;

    ParseCommand(my_pos, my_line, my_val, my_char);

    if my_char = 'M' then begin
      if my_val = 71 then use_inches_in_drillfile:= false;
      if my_val = 72 then use_inches_in_drillfile:= true;
      continue;
    end;

    if my_char = 'T' then begin
      if pos('.',my_line) > 0 then
        my_fac:= 1;
      my_tool:= round(my_val + 10);
      repeat
        my_valid:= ParseCommand(my_pos, my_line, my_val, my_char);
      until (my_char = 'C') or (not my_valid);
      if (my_char = 'C') and (my_tool < 32) then begin
        my_val:= my_val * my_fac;
        if use_inches_in_drillfile then
          my_val:= my_val * 25.4;
        if useDrillDia then begin
          job.pens[my_tool].diameter:= my_val;
          job.pens[my_tool].tipdia:= my_val;
          job.pens[my_tool].used:= true;
          job.pens[my_tool].shape:= drillhole;
        end;
      end;
      continue;
    end;

    if (my_line = '%') or (my_line = 'M95') then begin
      invalid_header:= false;
      break;
    end;
  end;
  if invalid_header then begin
    CloseFile(my_ReadFile);
    Form1.Memo1.lines.add('');
    Form1.Memo1.lines.add('WARNING: Invalid drill file:');
    Form1.Memo1.lines.add(my_name);
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
    exit;
  end;

  ///// read body //////////////////////////////////////////////////////////////
  while not Eof(my_ReadFile) do begin
    Readln(my_ReadFile,my_line);
    drill_import_line(my_line, fileID, penOverride, my_fac);
  end;

  CloseFile(my_ReadFile);
  FileParamArray[fileID].valid := true;
  file_rotate_mirror(fileID, false);
  if job.optimize_drills then
    optimize_drillfile(fileID);
  block_scale_file(fileID);
end;

