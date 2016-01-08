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
  show_tool: boolean;

begin
  my_speed:= Form1.TrackbarSimSpeed.Position;
  show_tool:= my_speed < 10;
  if fast_move then begin
    int_scale:= gl_bresenham_scale div 2;  // gröbere Auflössung für Seeks
    my_speed:= 5 + my_speed;
    my_delay:= 20;
  end else begin
    int_scale:= gl_bresenham_scale;
    my_delay:= 10 - my_speed;
    my_speed:= my_speed * gl_bresenham_scale div 2 + 1;
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
        SimMillAtPos(xx/int_scale, yy/int_scale, zz/int_scale, sim_dia, false, show_tool);
      if show_tool and Form1.ShowDrawing1.Checked then
      // wird ansonsten von DecodeResponse gesetzt
        SetDrawingToolPosMM(xx/int_scale, yy/int_scale, zz/int_scale);
      if (n mod my_speed = 0) then
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
        SimMillAtPos(xx/int_scale, yy/int_scale, zz/int_scale, sim_dia, false, show_tool);
      if show_tool and Form1.ShowDrawing1.Checked then
      // wird ansonsten von DecodeResponse gesetzt
        SetDrawingToolPosMM(xx/int_scale, yy/int_scale, zz/int_scale);
      if (n mod my_speed = 0) then
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
        SimMillAtPos(xx/int_scale,yy/int_scale, zz/int_scale, sim_dia, false, show_tool);
      if show_tool and Form1.ShowDrawing1.Checked then
      // wird ansonsten von DecodeResponse gesetzt
        SetDrawingToolPosMM(xx/int_scale, yy/int_scale, zz/int_scale);
      if (n mod my_speed = 0) then
        mdelay(my_delay);
    end;
  end;
  if Form1.Show3DPreview1.Checked then
    SimMillAtPos(xf1, yf1, zf1, sim_dia, true, show_tool);
  if show_tool and Form1.ShowDrawing1.Checked then
    SetDrawingToolPosMM(xf1, yf1, zf1);
end;

// #############################################################################
// G-Code-interpreter
// #############################################################################


procedure InterpretGcodeLine(my_str: string);
// interpretiert GRBL-Befehl und stellt ihn in 3D-Simulation dar
// beherrscht nur rudimentäre Funktionenm reicht aber für 90% der Daten

var
  idx, ip: Integer;
  old_x, old_y, old_z: Double;
  new_dia: Double;
  new_color, new_tooltip: Integer;


begin
  if pos('M3', my_str) > 0 then begin
    tool_running:= true;
    mdelay((12-Form1.TrackbarSimSpeed.Position)* 250);
    if Form1.Show3DPreview1.Checked then // wird vorher aufgerufen
      MakeToolArray(sim_dia);
  end;
  if pos('M4', my_str) > 0 then
    tool_running:= true;
  if pos('M5', my_str) > 0 then
    tool_running:= false;
  if pos('G1', my_str) > 0 then
    sim_seek:= false;
  if pos('G0', my_str) > 0 then
    sim_seek:= true;
  if pos('G9', my_str) > 0 then  // G92
    exit;
  ip := pos('BITCHANGE:', my_str);  // ist eigentlich ein Kommentar
  if ip > 0 then begin
    ip := pos(':', my_str) + 1;
    new_dia:= extract_float(my_str, ip, false);
    new_tooltip:= extract_int(my_str, ip);
    new_color:= extract_int(my_str, ip);
    SetSimToolMM(new_dia, new_tooltip, new_color);
    if Form1.Show3DPreview1.Checked then // wird vorher aufgerufen
      MakeToolArray(sim_dia);
  end;
  if (my_str[1] = '/') or (my_str[1] = '(') then // andere Kommentare
    exit;

  old_x:= sim_x;
  old_y:= sim_y;
  old_z:= sim_z;
  idx:= pos('X', my_str);
  if idx > 0 then begin
    inc(idx);
    sim_x:= extract_float(my_str, idx, true); // GCode-Dezimaltrenner
    if pos('G53', my_str) > 0 then begin
      sim_x:= 0;
    end;
  end;
  idx:= pos('Y', my_str);
  if idx > 0 then begin
    inc(idx);
    sim_y:= extract_float(my_str, idx, true); // GCode-Dezimaltrenner
    if pos('G53', my_str) > 0 then begin
      sim_y:= 0;
    end;
  end;
  idx:= pos('Z', my_str);
  if idx > 0 then begin
    inc(idx);
    sim_z:= extract_float(my_str, idx, true); // GCode-Dezimaltrenner
    if pos('G53', my_str) > 0 then begin
      sim_z:= job.z_penlift;
    end;
    if sim_z < 0 then
      sim_render_finel:= true;
  end;
  idx:= pos('F', my_str);
  if idx > 0 then begin
    inc(idx);
    sim_feed:= extract_int(my_str, idx);
  end;
  bresenham3D(old_x, sim_x, old_y, sim_y, old_z, sim_z, sim_seek);
  LEDbusy3d.Checked:= false;
end;
