// #############################################################################
// Excellon Import
// #############################################################################

function get_drill_val(var my_pos: Integer; var my_line: string;
                       var my_result: LongInt; getInt: Boolean): boolean;
var
  my_str: String;
  my_char: char;
  my_double: Double;
begin
  result:= false;
  if my_pos > length(my_line) then
    exit;
  while not (my_line[my_pos] in ['0'..'9', '.',  '+', '-']) do begin
    inc(my_pos);
    if (my_pos > length(my_line)) then
      exit;
  end;
  my_str:= '';
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
      my_double:= StrDotToFloat(my_str);
      if use_inches_in_drillfile then
        my_double:= my_double * 25.4;
      if not AnsiContainsStr(my_str, '.') then
        my_double:= my_double / 1000;
      my_result:= round(my_double * int(c_hpgl_scale));
    end;
  end;
end;

procedure drill_import_line(my_str: String; fileID, penOverride: Integer);
// Actions: none, lift, seek, drill, mill
var
  my_x, my_y: Integer;
  my_pos: Integer;
  my_valid: boolean;
  my_char: char;
  my_tool, my_block_Idx: Integer;

begin
  my_pos:= 1;
  repeat
    if my_pos > length(my_str) then
      exit;
    my_char:= my_str[my_pos];
    if my_char = ';' then
      exit;
    case my_char of
      'M': // M-Befehl, z.B. M30 = Ende
        exit;
      'T': // Tool change
        begin
          inc(my_pos);
          my_valid:= get_drill_val(my_pos, my_str, my_tool, true); // Integerwert
          if my_valid then begin
            PendingAction:= lift;
            if (my_tool < 22) then
              CurrentPen:= my_tool + 10;
            if penOverride >= 0 then
              CurrentPen:= penoverride;
          end;
        end;
      'X':
        begin
          if PendingAction = lift then
            new_block(fileID);
          PendingAction:= none;
          inc(my_pos);
          my_valid:= get_drill_val(my_pos, my_str, my_x, false);
          my_pos:= pos('Y', my_str) +1;
          my_valid:= my_valid and (my_pos > 0);
          my_valid:= my_valid and get_drill_val(my_pos, my_str, my_y, false);
          if my_valid then begin
            LastPoint.X:= my_x;
            LastPoint.Y:= my_y;
            my_block_Idx:= length(blockArrays[fileID])-1;
            append_point(fileID, my_block_idx, LastPoint);
            blockArrays[fileID, my_block_idx].pen:= CurrentPen;
          end;
        end;
    end;
    inc(my_pos);
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
  last_x, last_y, dx, dy,
  last_dx, last_dy, dv, dvo,
  prefer_x, prefer_y: Integer;
  found_array: Array of Boolean;


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
  prefer_x:= 10;
  prefer_y:= 10;

  for i:= 0 to my_len-1 do begin
    // alle nicht besuchten Punkte absuchen
    dvo:= high(Integer);
    for p:= 0 to my_len-1 do begin
      if found_array[p] then
        continue; // bereits besucht
      // finde nächstliegenden Punkt mit Vorzugsrichtung
      dx:= abs(my_path[p].x - last_x); // Abstand zum letzten gefundenen Punkt
      dy:= abs(my_path[p].y - last_y);

      dv:= round(sqrt(sqr(dx div prefer_x) + sqr(dy div prefer_y)));
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
    optimized_path[i].x:= last_x;
    optimized_path[i].y:= last_y;
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

procedure drill_fileload(my_name:String; fileID, penOverride: Integer; useDrillDia: Boolean);
// Liest File in FileBuffer und liefert Länge zurück
var
  my_ReadFile: TextFile;
  my_line, my_str: String;
  my_tool: integer;
  my_dia: Double;

begin
  if not FileExists(my_name) then begin
    FileParamArray[fileID].valid := false;
    exit;
  end;
  FileParamArray[fileID].bounds.min.x := high(Integer);
  FileParamArray[fileID].bounds.min.y := high(Integer);
  FileParamArray[fileID].bounds.max.x := low(Integer);
  FileParamArray[fileID].bounds.max.y := low(Integer);
  use_inches_in_drillfile:= true;
  my_line:='';
  FileMode := fmOpenRead;
  AssignFile(my_ReadFile, my_name);
  CurrentPen:= 10;
  PendingAction:= lift;

  Reset(my_ReadFile);
  // Header mit Tool-Tabelle laden
  while not Eof(my_ReadFile) do begin
    Readln(my_ReadFile,my_line);
    if AnsiContainsStr(my_line, 'INCH') then
      use_inches_in_drillfile:= true;
    if AnsiContainsStr(my_line, 'METRIC') then
      use_inches_in_drillfile:= false;
    if my_line[1] = 'T' then begin
      my_str:= copy(my_line, 2, pos('C',my_line)-2);
      my_tool:= StrToIntDef(my_str, 1) + 10;
      if (my_tool < 32) then begin
        my_str:= copy(my_line, pos('C',my_line)+1, 99);
        my_dia:= StrDotToFloat(my_str);
        if use_inches_in_drillfile then
          my_dia:= my_dia * 25.4;
        if useDrillDia then
          job.pens[my_tool].diameter:= my_dia;
        job.pens[my_tool].used:= true;
        job.pens[my_tool].shape:= drillhole;
      end;
    end;
    if my_line = '%' then
      break;
  end;
  if my_line <> '%' then begin
    showmessage('Drill file invalid!');
    CloseFile(my_ReadFile);
    exit;
  end;

  while not Eof(my_ReadFile) do begin
    Readln(my_ReadFile,my_line);
    drill_import_line(my_line, fileID, penOverride);
  end;
  drill_import_line('M30', fileID, penOverride);
  CloseFile(my_ReadFile);
  FileParamArray[fileID].valid := true;
  file_rotate_mirror(fileID);
  if job.optimize_drills then
    optimize_drillfile(fileID);
  block_scale_file(fileID);
end;


