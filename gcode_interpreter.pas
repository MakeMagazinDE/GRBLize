// #############################################################################
// ############################# G-Code Interpreter ############################
// #############################################################################


// #############################################################################
// Werkzeugbewegung in XYZ (3D-Bresenham)
// #############################################################################

procedure bresenham3D(xf0, xf1, yf0, yf1, zf0, zf1: Double; fast_move: Boolean);
// Bresenham-Implementierung in 3D mit der Auflösung von 1/int_scale Schritten
// Berechnet Linie von xf0 nach xf1 usw.
var
  x, x0, x1, ix, ax, dx, dx2, sx, xx  :integer;
  y, y0, y1, iy, ay, dy, dy2, sy, yy  :integer;
  z, z0, z1, iz, az, dz, dz2, sz, zz  :integer;
  err_1, err_2, n          :integer;
  cx, cy, cz               :integer;
  int_scale: Double;
  my_speed, my_delay: Integer;

begin
  my_speed:= Form1.TrackbarSimSpeed.Position;
  if fast_move then begin
    int_scale:= gl_bresenham_scale div 2;  // gröbere Auflössung für Seeks
    my_speed:= 5 + my_speed;
    my_delay:= 20;
  end else begin
    int_scale:= gl_bresenham_scale;
    my_speed:= my_speed * gl_bresenham_scale div 2 + 1;
    my_delay:= 10;
  end;

{
  if my_speed > 10 then begin// Start und Ende immer zeichnen
    if Form1.Show3DPreview1.Checked then
      SimMillAtPos(xf0, yf0, zf0, sim_dia, true);
    if Form1.ShowDrawing1.Checked then
      SetDrawingToolPosMM(xf0, yf0, zf0, true);
  end;
}
  x0:= round(xf0*int_scale); x1:= round(xf1*int_scale);
  y0:= round(yf0*int_scale); y1:= round(yf1*int_scale);
  z0:= round(zf0*int_scale); z1:= round(zf1*int_scale);
  xx:= x0; yy:= y0; zz:= z0;
  dx:= x1 - x0;
  dy:= y1 - y0;
  dz:= z1 - z0;
  If (dx < 0) Then
    ix:= -1
  else
    ix:=  1;
  If (dy < 0) Then
    iy:= -1
  else
    iy:=  1;
  If (dz < 0) Then
    iz:= -1
  else
    iz:=  1;

  ax:= abs(dx); ay:= abs(dy); az:= abs(dz);
  dx2:= ax*2; dy2:= ay*2; dz2:= az*2;

  if (ax >= ay) and (ax >= az) then begin
    err_1:= dy2 - ax;
    err_2:= dz2 - ax;
    for n:= 0 to ax-1 do begin
      if (err_1 > 0) then begin
         yy:= yy + iy;
         err_1:= err_1 - dx2;
      end;
      if (err_2 > 0) then begin
         zz:= zz + iz;
         err_2:= err_2 -dx2;
      end;
      err_1:= err_1 + dy2;
      err_2:= err_2 + dz2;
      xx:= xx + ix;
      if Form1.Show3DPreview1.Checked then
        SimMillAtPos(xx/int_scale, yy/int_scale, zz/int_scale, sim_dia, false);
      if Form1.ShowDrawing1.Checked then
      // wird ansonsten von DecodeResponse gesetzt
        SetDrawingToolPosMM(xx/int_scale, yy/int_scale, zz/int_scale);
      if (n mod my_speed = 0) and (my_speed < 20) then
        mdelay(my_delay);
    end;
  end else if (ay >= ax) and (ay >= az) then begin
    err_1:= dx2 - ay;
    err_2:= dz2 - ay;
    for n:= 0 to ay-1 do begin
      if (err_1 > 0) then begin
         xx:= xx + ix;
         err_1:= err_1 - dy2;
      end;
      if (err_2 > 0) then begin
         zz:= zz + iz;
         err_2:= err_2 - dy2;
      end;
      err_1:= err_1 + dx2;
      err_2:= err_2 + dz2;
      yy:= yy + iy;
      if Form1.Show3DPreview1.Checked then
        SimMillAtPos(xx/int_scale, yy/int_scale, zz/int_scale, sim_dia, false);
      if Form1.ShowDrawing1.Checked then
      // wird ansonsten von DecodeResponse gesetzt
        SetDrawingToolPosMM(xx/int_scale, yy/int_scale, zz/int_scale);
      if (n mod my_speed = 0) and (my_speed < 20) then
        mdelay(my_delay);
    end;
  end else if (az >= ax) and (az >= ay) then begin
    err_1:= dy2 - az;
    err_2:= dx2 - az;
    for n:= 0 to az-1 do begin
      if (err_1 > 0) then begin
         yy:= yy + iy;
         err_1:= err_1 - dz2;
      end;
      if (err_2 > 0) then begin
         xx:= xx + ix;
         err_2:= err_2 - dz2;
      end;
      err_1:= err_1 + dy2;
      err_2:= err_2 + dx2;
      zz:= zz + iz;
      if Form1.Show3DPreview1.Checked then
        SimMillAtPos(xx/int_scale,yy/int_scale, zz/int_scale, sim_dia, false);
      if Form1.ShowDrawing1.Checked then
      // wird ansonsten von DecodeResponse gesetzt
        SetDrawingToolPosMM(xx/int_scale, yy/int_scale, zz/int_scale);
      if (n mod my_speed = 0) and (my_speed < 20) then
        mdelay(my_delay);
    end;
  end;
  if Form1.Show3DPreview1.Checked then
    SimMillAtPos(xf1, yf1, zf1, sim_dia, true);
  if Form1.ShowDrawing1.Checked then
    SetDrawingToolPosMM(xf1, yf1, zf1);
end;

// #############################################################################
// G-Code-interpreter
// #############################################################################

procedure MakeToolArray(z_down, dia: Double);
// Werkzeug für §D-Sim erstellen, Grundform ist ein Kreis in einem quadratischen Array
var
  ix, iy: Integer;
  vz, h, r: Double;  // Länge vom Kreismittelpunkt, Tool-Radius-Faktor
begin
  tool_array_size:= round(dia * gl_arr_scale);
  r:= dia/2;
  h:= 0;
  tool_mid:= round(r * gl_arr_scale);
  tool_mid_int:= round(tool_mid);
  setlength(tool_array, tool_array_size);
  for ix:= 0 to tool_array_size-1 do begin
    setlength(tool_array[ix], tool_array_size);
  end;
  for ix:= 0 to tool_array_size-1 do
    for iy:= 0 to tool_array_size-1 do begin
      vz:=sqrt(sqr(ix-tool_mid) + sqr(iy-tool_mid));
      if (vz <= tool_mid) and (z_down < 0) then begin // <= gewünschter Radius?
        // wir sind innerhalb der Kreisfläche. Jetzt Spitze bestimmen
        case sim_tooltip of
          0: // Flat tip
            h:= 0;   // neue Frästiefe an diesem Punkt des Werkzeugs
          1: // Cone 30°
            h:= vz*3 / gl_arr_scale ;
          2: // Cone 45°
            h:= vz*2 / gl_arr_scale ;
          3: // Cone 60°
            h:= vz*1.5 / gl_arr_scale ;
          4: // Cone 90°
            h:= vz / gl_arr_scale ;
          5: // Ball
            h:= (tool_mid - sqrt(sqr(tool_mid) - sqr(vz))) / gl_arr_scale;
        end;
        tool_array[ix,iy]:= (h + sim_z) / c_GLscale   // neue Frästiefe
      end else
        tool_array[ix,iy]:= 0;
    end;
end;


procedure InterpretGcodeLine(my_str: string);
// interpretiert GRBL-Befehl und stellt ihn in 3D-Simulation dar
var
  ix, iy, iz, ip: Integer;
  old_x, old_y, old_z: Double;
  new_dia: Double;
  new_color, new_tooltip: Integer;

  function extract_float(const grbl_str: string; var start_idx: integer; is_dotsep: Boolean): Double;
  var i: Integer;
    my_str: string;
    my_Settings: TFormatSettings;
  begin
    my_Settings.Create;
    my_str:= '';
    while grbl_str[start_idx] < #33 do
      inc(start_idx);
    for i:= start_idx to length(grbl_str) do begin
      if grbl_str[i] in ['0'..'9', '+', '-', ',', '.'] then
        my_str:= my_str + grbl_str[i]
      else
        break;
    end;
    start_idx:= i+1;
    If is_dotsep then begin
      my_Settings.DecimalSeparator:= '.';
      result:= StrToFloat(my_str, my_Settings);
    end else
      result:= StrToFloat(my_str);
  end;

  function extract_int(const grbl_str: string; var start_idx: integer): Integer;
  var i: Integer;
    my_str: string;
  begin
    my_str:= '';
    while grbl_str[start_idx] < #33 do
      inc(start_idx);
    for i:= start_idx to length(grbl_str) do begin
      if grbl_str[i] in ['0'..'9', '+', '-'] then
        my_str:= my_str + grbl_str[i]
      else
        break;
    end;
    start_idx:= i+1;
    result:= StrToInt(my_str);
  end;

begin
  if pos('M3', my_str) > 0 then
    tool_running:= true;
  if pos('M4', my_str) > 0 then
    tool_running:= true;
  if pos('M5', my_str) > 0 then
    tool_running:= false;
  if pos('G1', my_str) > 0 then
    sim_seek:= false;
  if pos('G0', my_str) > 0 then
    sim_seek:= true;
  if pos('G9', my_str) > 0 then
    exit;
  ip := pos('BITCHANGE:', my_str);  // ist eigentlich ein Kommentar
  if ip > 0 then begin
    ip := pos(':', my_str) + 1;
    new_dia:= extract_float(my_str, ip, false);
    new_tooltip:= extract_int(my_str, ip);
    new_color:= extract_int(my_str, ip);
    SetSimToolMM(new_dia, new_tooltip, new_color);
  end;
  if pos('//', my_str) > 0 then    // andere Kommentare
    exit;

  old_x:= sim_x;
  old_y:= sim_y;
  old_z:= sim_z;
  ix:= pos('X', my_str);
  iy:= pos('Y', my_str);
  iz:= pos('Z', my_str);
  if ix > 0 then begin
    inc(ix);
    sim_x:= extract_float(my_str, ix, true); // GCode-Dezimaltrenner
    if pos('G5', my_str) > 0 then begin
      sim_x:= -20;
    end;
  end;
  if iy > 0 then begin
    inc(iy);
    sim_y:= extract_float(my_str, iy, true); // GCode-Dezimaltrenner
    if pos('G5', my_str) > 0 then begin
      sim_y:= -20;
    end;
  end;
  if iz > 0 then begin
    inc(iz);
    sim_z:= extract_float(my_str, iz, true); // GCode-Dezimaltrenner
    if pos('G5', my_str) > 0 then begin
      sim_z:= 50;
    end;
  end;
  if Form1.Show3DPreview1.Checked then
    MakeToolArray(sim_z, sim_dia);
  bresenham3D(old_x, sim_x, old_y, sim_y, old_z, sim_z, sim_seek);
  LEDbusy3d.Checked:= false;
end;
