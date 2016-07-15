// #############################################################################
// ############################ Hilfsfunktionen ################################
// #############################################################################

function extract_float(const grbl_str: string; var start_idx: integer; is_dotsep: Boolean): Double;
var i: Integer;
  my_str: string;
  my_Settings: TFormatSettings;
begin
  my_Settings.Create;
  my_str:= '';
  if start_idx >= length(grbl_str) then
    exit;
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

function pen_description(const pen: Integer): String;
var my_str: string;
  my_tooltip: Integer;
begin
  my_tooltip:= job.pens[pen].tooltip;
  if job.pens[pen].shape = drillhole then
    my_tooltip:= 6;
  my_str:= 'HPGL pen #' + IntToStr(pen)
    + #13 +'diameter: ' + FormatFloat('00.00',job.pens[pen].diameter) + ' mm'
    + #13 +'type: ' + ToolTipArray[my_tooltip];
  result:= my_str;
end;


function get_current_gauge: Double;
begin
  if ProbedState= s_probed_manual then
     result:= job.z_gauge
  else if ProbedState= s_probed_contact then
     result:= job.probe_z_gauge
  else
     result:= 10;  // Sicherheitsabstand im Fehlerfall
end;

procedure spindle_on_off(const switch_on: Boolean);
begin
  if SpindleRunning = switch_on then
    exit;
  WaitForIdle;
  if switch_on then begin
    Form1.Memo1.lines.add('Spindle ON, acceleration wait '+ IntToStr(job.spindle_wait) + ' sec');
    SendSingleCommandStr('M3');
  end else begin
    Form1.Memo1.lines.add('Spindle OFF, brake wait '+ IntToStr(job.spindle_wait div 2) + ' sec');
    SendSingleCommandStr('M5');
  end;
  if not Form1.CheckBoxSim.checked then begin
    if switch_on then
      mdelay(job.spindle_wait * 1000)  // Spindel-Hochlaufzeit
    else
      mdelay(job.spindle_wait * 500)  // Spindel-Bremszeit
  end else
    mdelay(500);  // Simulation
  SpindleRunning:= switch_on;
end;

function machine_busy_msg: Boolean;
begin
  if MachineState <> idle then begin
    Form1.Memo1.lines.add('');
    Form1.Memo1.lines.add('WARNING: Machine not idle, command ignored');
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
  end;
  result:= MachineState <> idle;
end;

// #############################################################################
// ################################ Z PROBING ##################################
// #############################################################################

// Straight Probe Command G38.2 Z-20 F100   -- Z in Maschinenkoordinaten!
// Wenn #define MESSAGE_PROBE_COORDINATES:
// Bei Erreichen des Z-Kontakts:
// [PRB:0.000,0.000,-10.553:1]  -- Maschinenkoordinaten!
// ok
// oder im Fehlerfall:
// ALARM: Probe fail
// [PRB:0.000,0.000,-10.553:0]
// ok
// Wenn MESSAGE_PROBE_COORDINATES abgeschaltet:
// G38.2 Z-1 F100
// ok -- wenn angekommen und gestoppt
// oder im Fehlerfall:
// ALARM: Probe fail
// ok
// ?<Alarm,MPos:0.000,0.000,-1.001,WPos:0.000,0.000,-1.001>

function sim_not_supportet(const do_reset: Boolean): Boolean;
begin
  if Form1.CheckBoxSim.checked then begin
    Form1.Memo1.lines.add('Not supported in simulation');
    if do_reset then begin
      Form1.Memo1.lines.add('Coordinates reset to sim');
      ResetSimulation;
    end;
    result:= true;
  end else
    result:= false;
end;

function extract_probe_pos(my_line: String): Double;
// Z Messtaster-Wert holen. Achtung: DisableStatus vorher ausführen!
// [PRB:0.000,0.000,-10.553:1]  -- Maschinenkoordinaten!
// T_parseReturnType = (p_none, p_endofline, p_letters, p_number);
var
  my_pos: Integer;
  my_val: Double;
  my_str: String;
begin
  result:= 0;
  my_pos:= pos('PRB:',my_line);
  if my_pos > 0 then begin
    my_pos:= my_pos + 4;
    ParseLine(my_pos, my_line, my_val, my_str); // X-Wert
    ParseLine(my_pos, my_line, my_val, my_str); // Y-Wert
    if ParseLine(my_pos, my_line, my_val, my_str) = p_number then
      result:= my_val;
  end;
end;

function probe_z: double;
var my_zval: Double;
  pos_changed: Boolean;
  my_response: String;
begin
// von aktueller Position ausgehend Z nach unten fahren.
// Stoppt wenn Kontakt erreicht.
// Untere Z-Position: Travel Z minus Längensensor-Höhe,
// verhindert, dass das Werkzeug in den Tisch rammt
// nach Stopp durch Kontakt steht Maschinenposition in grbl_mpos.Z
// wird in result übernommen, Z kehrt danach auf 0 zurück
  Form1.Memo1.lines.add('Probing Z (20 mm max.), wait for contact');
  result:= 0;
  if grbl_is_connected and (not Form1.CheckBoxSim.checked) then begin
    if (MachineState = alarm) then
      exit;
    WaitForIdle;
    DisableStatus;
    my_response:= grbl_SendStr('G38.2 Z' + FloatToStrDot(grbl_mpos.Z - 25) + ' F200' + #13, true);
    Form1.Memo1.lines.add(my_response);
    my_zval:= extract_probe_pos(my_response);
    grbl_wait_for_timeout(50);
    if (MachineState = alarm) or (my_zval = 0) then begin
      MessageDlg('Probing failed. ALARM LOCK set,'
        + #13 + 'click ALARM panel to clear.', mtWarning, [mbOK], 0);
      Form1.Memo1.lines.add('ALARM lock set by GRBL');
    end else begin
      // 2 mm abheben und nochmal
      grbl_SendStr('G0 G53 Z' + FloatToSTrDot(my_zval + 2) + #13, true);
      my_response:= grbl_SendStr('G38.2 Z' + FloatToStrDot(my_zval - 5) + ' F50' + #13, true);
      grbl_wait_for_timeout(50);
      Form1.Memo1.lines.add(my_response);
      my_zval:= extract_probe_pos(my_response);
      Form1.Memo1.lines.add('Probe contact at Z = ' + FloatToStr(my_zval));
      result:= my_zval;
    end;
    EnableStatus;
  end;
end;

function probe_z_fixed: double;
var my_zval: Double;
begin
  if (MachineState = alarm) then
    exit;
  // Probe an Fixed-Position anfahren, grbl_mpos.Z merken und zurück nach oben
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move to reference probe');
  grbl_moveZ(0, true);
  grbl_moveXY(job.probe_x, job.probe_y, true);
  grbl_moveZ(job.probe_z, true);
  SendListToGrbl;
  mdelay(250);
  WaitForIdle;
  result:= 0;
  my_zval:= probe_z;
  if my_zval = 0 then
    ResetToolflags
  else begin
    WaitForIdle;
    result:= my_zval;
   end;
end;

procedure CancelG43offset;
// WorkZero muss anhand Messklotz oder Kontakthöhe gesetzt sein
var my_dlg_result: integer;
begin
  if (MachineState = alarm) then
    exit;
  WaitForIdle;
  Form1.Memo1.lines.add('Cancel Tool Length Offset (TLO)');
  SendSingleCommandStr('G49');
end;

procedure NewG43offset(my_delta: Double);
// WorkZero muss anhand Messklotz oder Kontakthöhe gesetzt sein
var my_dlg_result: integer;
begin
  if (MachineState = alarm) then
    exit;
  if FirstToolReferenced then begin
    WaitForIdle;
    Form1.Memo1.lines.add('Set new Tool Length Offset (TLO) to '+FloatToStrDot(ToolDelta)+ ' mm');
    SendSingleCommandStr('G43.1 Z'+FloatToStrDot(ToolDelta));
  end else begin
    Form1.Memo1.lines.add('Tool Length Reference not set, will cancel TLO');
    SendSingleCommandStr('G49');
  end;
end;

function DoTLCandConfirm(confirm: boolean): boolean;
// WorkZero muss anhand Messklotz oder Kontakthöhe gesetzt sein
// liefert true wenn erfolgreich
// wenn bereits FirstToolReferenced TRUE ist, wird ein neuer Längenoffset gesetzt.
// Sonst gilt dieses Tool als Referenz mit Delta = 0.
var my_dlg_result: integer;
begin
  my_dlg_result:= mrOK;
  result:= false;
  if isCancelled then
    exit;
  if (MachineState = alarm) then
    exit;
  if not Form1.CheckFixedProbeZ.Checked then
    my_dlg_result:= MessageDlg('Ready to set Tool Length Offset/Reference (TLC).'
    +#13+'Is Z probe sensor placed in fixed position?', mtConfirmation, mbYesNo, 0);

  if my_dlg_result = mrOK then begin
    if confirm then
      my_dlg_result:= MessageDlg('Please clear machine to probe Tool Length Offset/Reference (TLC).',
        mtConfirmation, mbOKCancel,0);
    if my_dlg_result = mrOK then begin
      LEDbusy.Checked:= true;
      CancelG43offset;
      Form1.Memo1.lines.add('Tool Length Offset/Reference (TLC)');
      SendSingleCommandStr('G0 G53 Z0');
      MposOnFixedProbe:= probe_z_fixed; // festen Sensor anfahren
      if (MachineState = alarm) then
        exit;
      SendSingleCommandStr('G0 G53 Z0');
      result:= true;

      ToolDelta:= MposOnFixedProbe - MposOnFixedProbeReference; // Differenz zu erstem Werkzeug
      if not FirstToolReferenced then begin
        MposOnFixedProbeReference:= MposOnFixedProbe;
        ToolDelta:= 0;
        FirstToolReferenced:= true;
      end else
        NewG43Offset(ToolDelta);
      CurrentToolCompensated:= true;
    end;
  end;
end;


// #############################################################################
// #################### R E F E R E N C E  B U T T O N S #######################
// #############################################################################

procedure TForm1.BtnZeroXClick(Sender: TObject);
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Manual Work/part X zero');
  drawing_tool_down:= false;
  WorkZeroXdone:= true;
  SendSingleCommandStr('G92 X0');
  WorkZeroX:= grbl_mpos.X;
  JogX:= WorkZeroX;
  NeedsRedraw:= true;
end;

procedure TForm1.BtnZeroYClick(Sender: TObject);
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Manual Work/part Y zero');
  drawing_tool_down:= false;
  WorkZeroYdone:= true;
  SendSingleCommandStr('G92 Y0');
  WorkZeroY:= grbl_mpos.Y;
  JogY:= WorkZeroY;
  NeedsRedraw:= true;
end;

procedure TForm1.BtnZeroZClick(Sender: TObject);
// manuelle Z-Höhe mit Messklotz
begin
  WaitForIdle;
  Memo1.lines.add('');
  Memo1.lines.add('Manual Work/part Z zero, will set Z to ');
  Memo1.lines.add('Z Gauge value ' + FormatFloat('00.00', job.z_gauge) + ' mm above part');
  MposOnPartGauge:= grbl_mpos.Z;
  WorkZeroZ:= MposOnPartGauge - job.z_gauge;
  ProbedState:= s_probed_manual;
  WorkZeroZdone:= true;
  JogZ:= WorkZeroZ;

  if sim_not_supportet(false) then begin
    ToolDelta:= 0; // erstes Werkzeug
    FirstToolReferenced:= true;
    CurrentToolCompensated:= true;
    exit;
  end;
  FirstToolReferenced:= false;
  CurrentToolCompensated:= false;
  CancelG43offset;
  SendSingleCommandStr('G92 Z'+FloatToStrDot(job.z_gauge));
  if CheckPartProbeZ.Checked then
    DoTLCandConfirm(true);
  NeedsRedraw:= true;
end;

procedure TForm1.BtnZeroAllClick(Sender: TObject);
begin
  BtnZeroXClick(Sender);
  BtnZeroYClick(Sender);
  BtnZeroZClick(Sender);
end;

// #############################################################################

procedure TForm1.BtnZcontactClick(Sender: TObject);
// Werkstück-Probekontakt anfahren. Tool muss über Kontakt sein
var my_dlg_result: integer;
begin
  WaitForIdle;
  my_dlg_result:= MessageDlg('Ready to probe Z from current position.'
    +#13+'Is tool placed above Z part probe sensor?', mtConfirmation, mbYesNo,0);
  if my_dlg_result = mrYes then begin
    LEDbusy.Checked:= true;
    Memo1.lines.add('');
    Memo1.lines.add('Probe tool on part (movable probe), will set Z to ');
    Memo1.lines.add('Z Gauge value ' + FormatFloat('00.00', job.probe_z_gauge) + ' mm above part');
    FirstToolReferenced:= false;
    CurrentToolCompensated:= false;
    CancelG43offset;
    MposOnPartGauge:= probe_z;
    if MposOnPartGauge = 0 then begin
      ResetToolflags;
      Memo1.lines.add('WARNING: Z height invalid.');
      PlaySound('SYSTEMHAND', 0, SND_ASYNC);
      SendSingleCommandStr('G0 G53 Z0');
    end else begin
      ProbedState:= s_probed_contact;
      WorkZeroZdone:= true;
      WorkZeroZ:= MposOnPartGauge - job.probe_z_gauge;
      SendSingleCommandStr('G92 Z'+FloatToStrDot(job.probe_z_gauge));
      SendSingleCommandStr('G0  G53 Z'+FloatToStrDot(grbl_mpos.z + 5));  // leicht abheben
      DoTLCandConfirm(true);  // ist erstes Werkzeug!
    end;
  end;
  ZeroRequestDone:= true;
end;

procedure TForm1.BtnProbeTLCclick(Sender: TObject);
// Tool-Delta setzen.
var my_dlg_result: integer;
begin
  WaitForIdle;
  DoTLCandConfirm(false);
end;


// #############################################################################
// #############################################################################

function ManualToolchange(pen: Integer): Integer;
// zur Wechselposition bewegen, auf Aufnahme eines neuen Werkzeugs warten,
// Werkzeug ausmessen und G92-ProbeOffset setzen
// liefert False wenn abgebrochen
var my_dlg_result: integer;
begin
// Neues Werkzeug manuell aufnehmen
  result:= mrNo;
  if isCancelled then
    exit;
  spindle_on_off(false);
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  Form1.Memo1.lines.add('Move to manual tool change position');
  grbl_moveXY(job.toolchange_x, job.toolchange_y, true);
  grbl_moveZ(job.toolchange_z, true);
// manuelle Wechselposition
  SendListToGrbl;
  my_dlg_result:= mrOK;
  if (pen >= 0) then
    my_dlg_result:= MessageDlg('Tool Change Pause. Change tool manually to'
      + #13 + pen_description(pen)
      + #13 + 'Click YES when done. Clear machine for TLC.'
      + #13 + 'Click NO to keep current tool.'
      + #13 + 'All tools must have same length if TLC disabled.', mtConfirmation, mbYesNocancel, 0)
  else
    my_dlg_result:= MessageDlg('Tool Change Pause. Change tool manually.'
      + #13 + 'Click YES when done. Clear machine for TLC.'
      + #13 + 'Click NO to keep current tool.'
      + #13 + 'All tools must have same length if TLC disabled.', mtConfirmation, mbYesNocancel, 0);
  if Form1.CheckFixedProbeZ.checked and (my_dlg_result = mrYES) then begin
    CurrentToolCompensated:= false;
    if DoTLCandConfirm(false) then
      Form1.Memo1.lines.add('Tool changed, new Tool Delta Z applied');
  end else
    Form1.Memo1.lines.add('Tool not changed, Tool Delta Z retained');
  ToolInSpindle:= 10; // unknown Tool
  if Form1.Show3DPreview1.checked then
    Form4.GLSupdateATC;
  result:= my_dlg_result;
end;


procedure TForm1.BtnMoveToolChangeClick(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  ManualToolchange(-1);
end;

// #############################################################################


procedure TForm1.BtnListToolsClick(Sender: TObject);
var i, my_tooltip, my_pen: Integer;
  my_first: boolean;
  my_dia: Double;
  my_str: String;
begin
  Memo1.lines.add('');
  Memo1.lines.add('List of enabled tools used in job:');
  Memo1.lines.add('=========================================');
  if Form1.CheckUseATC.Checked then
    Memo1.lines.add('Load collet with dummy tool (ATC slot 0 empty)!');
  if length(final_array) > 0 then begin
    my_pen:= final_array[0].pen;
  end;
  for i:= 0 to 31 do begin
    if job.pens[i].enable and  job.pens[i].used then begin
      my_tooltip:= job.pens[i].tooltip;
      if job.pens[i].shape = drillhole then
        my_tooltip:= 6;
      my_str:= '// Tool #' + IntToStr(i) +' = '
        + FormatFloat('0.00',job.pens[i].diameter) + ' mm, ' + ToolTipArray[my_tooltip];
      if (not Form1.CheckUseATC.Checked) and (my_pen = i) then
        my_str:= my_str + ', tool must be in collet';
      my_first:= false;
      Memo1.lines.add(my_str);
    end;
  end;
  Memo1.lines.add('=========================================');
  Memo1.lines.add('');
end;


// #############################################################################
// ################### M O V E  AND  J O G  B U T T O N S ######################
// #############################################################################


procedure TForm1.BtnMoveParkClick(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move to park position');
  spindle_on_off(false);
  drawing_tool_down:= false;
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  grbl_moveXY(job.park_x, job.park_y, true);
  grbl_moveZ(job.park_z, true);
  SendListToGrbl;
  NeedsRedraw:= true;
end;

procedure TForm1.BtnMoveFix1Click(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move to fixture 1 zero');
  spindle_on_off(false);
  drawing_tool_down:= false;
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  grbl_moveXY(job.fix1_x, job.fix1_y, true);
  grbl_moveZ(job.fix1_z, true);
  SendListToGrbl;
  mdelay(250);
  NeedsRedraw:= true;
  WaitForIdle;
  BtnZeroXClick(Sender);
  BtnZeroYClick(Sender);
//  BtnZeroZClick(Sender);
end;

procedure TForm1.BtnMoveFix2Click(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move to fixture 2 zero');
  spindle_on_off(false);
  drawing_tool_down:= false;
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  grbl_moveXY(job.fix2_x, job.fix2_y, true);
  grbl_moveZ(job.fix2_z, true);
  SendListToGrbl;
  mdelay(250);
  NeedsRedraw:= true;
  WaitForIdle;
  BtnZeroXClick(Sender);
  BtnZeroYClick(Sender);
//  BtnZeroZClick(Sender);
end;


procedure TForm1.BtnSetParkClick(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  job.park_x:= grbl_mpos.x;
  job.park_y:= grbl_mpos.y;
  job.park_z:= grbl_mpos.z;
  with Form1.SgAppDefaults do begin
    Cells[1,6]:= FormatFloat('0.00', job.park_x);
    Cells[1,7]:= FormatFloat('0.00', job.park_y);
    Cells[1,8]:= FormatFloat('0.00', job.park_z);
  end;
  SaveIniFile;
end;

procedure TForm1.BtnSetFix1Click(Sender: TObject);
// Fixture-Position in Tabelle auf aktuelle Maschinenposition setzen
begin
  if machine_busy_msg then
    exit;
  job.fix1_x:= grbl_mpos.x;
  job.fix1_y:= grbl_mpos.y;
  job.fix1_z:= grbl_mpos.z;
  with Form1.SgAppDefaults do begin
    Cells[1,29]:= FormatFloat('0.00', job.fix1_x);
    Cells[1,30]:= FormatFloat('0.00', job.fix1_y);
    Cells[1,31]:= FormatFloat('0.00', job.fix1_z);
  end;
  SaveIniFile;
end;

procedure TForm1.BtnSetFix2Click(Sender: TObject);
// Fixture-Position in Tabelle auf aktuelle Maschinenposition setzen
begin
  if machine_busy_msg then
    exit;
  job.fix2_x:= grbl_mpos.x;
  job.fix2_y:= grbl_mpos.y;
  job.fix2_z:= grbl_mpos.z;
  with Form1.SgAppDefaults do begin
    Cells[1,32]:= FormatFloat('0.00', job.fix2_x);
    Cells[1,33]:= FormatFloat('0.00', job.fix2_y);
    Cells[1,34]:= FormatFloat('0.00', job.fix2_z);
  end;
  SaveIniFile;
end;

procedure TForm1.BtnMoveWorkZeroClick(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  Memo1.lines.add('');
  if ProbedState <> s_notprobed then begin
    LEDbusy.Checked:= true;
    Memo1.lines.add('Move to tool part zero');
    Memo1.lines.add('Pen Lift value ' + FormatFloat('00.00', job.z_penlift) + ' mm above part');
    spindle_on_off(false);
    drawing_tool_down:= false;
    grbl_moveZ(0, true);
    grbl_moveXY(0,0, false);
    grbl_moveZ(job.z_penlift, false);
    SendListToGrbl;
  end else
    Memo1.lines.add('Tool was not zeroed on part. No action taken.');
  NeedsRedraw:= true;
end;

procedure StartJogAction(sender: TObject; tag: Integer);
var dx, dy, dz: Double;
  my_str: string;
//  first_loop_done: Boolean;
  my_delay: Integer;
begin
  if sim_not_supportet(false) then
    exit;
  WaitForIdle;
  dx:= 0;
  dy:= 0;
  dz:= 0;
  case tag of   // Welcher Jog-Button?
    0: dx:= 0.1;
    1: dx:= 1;
    2: dx:= 10;
    3: dx:= -0.1;
    4: dx:= -1;
    5: dx:= -10;
    10: dy:= 0.1;
    11: dy:= 1;
    12: dy:= 10;
    13: dy:= -0.1;
    14: dy:= -1;
    15: dy:= -10;
    20: dz:= 0.1;
    21: dz:= 1;
    22: dz:= 10;
    23: dz:= -0.1;
    24: dz:= -1;
    25: dz:= -10;
  end;
  MouseJogAction := True;
  //my_delay:= (12 - Form1.TrackBarRepeatRate.Position) * 20;
{
  first_loop_done:= false;
  repeat
}
    JogX:= grbl_mpos.X + dx;
    JogY:= grbl_mpos.Y + dy;
    JogZ:= grbl_mpos.Z + dz;
    if dx <> 0 then
      SendSingleCommandStr('G0 G53 X' + FloatToStrDot(JogX));
    if dy <> 0 then
      SendSingleCommandStr('G0 G53 Y' + FloatToStrDot(JogY));
    if dz <> 0 then
      SendSingleCommandStr('G0 G53 Z' + FloatToStrDot(JogZ));
{
    if not first_loop_done then
      mdelay(300)
    else
      mdelay(my_delay);
    first_loop_done:= true;
  until MouseJogAction = False; // stop when cancelled
}
  NeedsRedraw:= true;
end;


procedure TForm1.BitBtnJogMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  WaitForIdle;
  if HomingPerformed then
    StartJogAction(Sender, (Sender as TBitBtn).Tag);
end;

procedure TForm1.BitBtnJogMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  MouseJogAction := False; // cancel notification
end;

// #############################################################################
// ######################## R U N  J O B  B U T T O N S ########################
// #############################################################################

procedure CancelJob;
begin
  Form1.BtnCancel.tag:= 2;
end;

procedure ExitJobMsg;
begin
  Form1.BtnRunjob.tag:= 0;
  WaitForIdle;
  drawing_tool_down:= false;
  Form1.Memo1.lines.add('Job ended.');
  Form1.Memo1.lines.add('');
  NeedsRedraw:= true;
  Form1.ProgressBar1.position:= 0;
  Form1.BtnCancel.tag:= 0;
end;

function BitChangeStr(const my_entry: Tfinal): String;
begin
  result:='// Bit change: ' + FormatFloat('0.00', job.pens[my_entry.pen].diameter)
    + ' ' + IntToStr(job.pens[my_entry.pen].tooltip)+' '+ IntToStr(job.pens[my_entry.pen].color);
end;

procedure TForm1.BtnRunJobClick(Sender: TObject);
var i, my_len, p, last_pen, my_old_atc_tool, my_new_atc_tool, my_btn: Integer;
  my_entry: Tfinal;
  my_atc_x, my_atc_y, my_dia: Double;
  is_firstloop, not_loaded_flag, atc_used_flag: Boolean;
  tool_is_different: Boolean;
begin
  DefaultsGridListToJob;
  PenGridListToJob;
  if machine_busy_msg then
    exit;
  BtnRunjob.tag:= 1;
  Memo1.lines.clear;
  gcsim_dia:= Form1.ComboBoxGdia.ItemIndex+1;
  gcsim_tooltip:= Form1.ComboBoxGtip.ItemIndex;
  Form4.FormRefresh(nil);
  Memo1.lines.Clear;
  Memo1.lines.add('Job run started.');
  Memo1.lines.add('=========================================');
  my_len:= length(final_array);
  if my_len < 1 then
     exit;
  Form1.Memo1.lines.add('');
  my_entry:= final_array[0];
  last_pen:= my_entry.pen;
  is_firstloop := true;
  atc_used_flag:= false;
  my_old_atc_tool:= 0;
  grbl_addStr(BitChangeStr(my_entry));

  if CheckUseATC.Checked then begin
    CurrentToolCompensated:= false;
    FirstToolReferenced:= false;
    BtnListAssignmentsClick(nil);
    my_btn := MessageDlg('Make sure spindle collet is loaded with '
      + #13 + 'probe/dummy tool 0, ATC slot 0 is empty'
      + #13 + 'and ATC tray is loaded with tools listed.', mtConfirmation, mbOKCancel, 0);
    if my_btn = mrCancel then begin
      ExitJobMsg;
      exit;
    end;
  end else begin
    last_pen:= my_entry.pen;
    my_btn := MessageDlg('Make sure spindle collet is loaded with'
      + #13 + 'tool #'+ inttostr(last_pen) + ': ' + FormatFloat('0.00', job.pens[last_pen].diameter) + 'mm, '
      + ToolTipArray[job.pens[last_pen].tooltip]
      + #13 + 'and tool is referenced/zeroed on work part.', mtConfirmation, mbOKCancel, 0);
    if my_btn = mrCancel then begin
      ExitJobMsg;
      exit;
    end;

  end;

  if (length(my_entry.millings) > 0) then begin
    LEDbusy.Checked:= true;
    SendSingleCommandStr('G0 G53 Z0');
    spindle_on_off(true);
    grbl_go_start_path(my_entry.millings[length(my_entry.millings)-1],
        my_entry.pen, job.pens[my_entry.pen].offset);
    SendListToGrbl;
  end;

  for i:= 0 to my_len-1 do begin
    if isCancelled then begin
      CancelJob;
      exit;
    end;
    my_entry:= final_array[i];
    if not my_entry.enable then
      continue;
    if length(my_entry.millings) = 0 then
      continue;
    not_loaded_flag:= false;
    // Slot für benötigtes Werkzeug leer?
    for p:= 1 to 9 do begin // ATC-Array absuchen
      if job.pens[my_entry.pen].atc = 0 then // gar nicht im ATC?
        not_loaded_flag:= true
      else if not atcArray[p].loaded and (atcArray[p].pen = my_entry.pen) then
        not_loaded_flag:= true;
    end;

    tool_is_different:= (my_entry.pen <> last_pen);
    if tool_is_different then
    // evt. (fast) gleicher Durchmesser und gleiche Form? Dann nicht wechseln
      if (CompareValue(job.pens[my_entry.pen].diameter, job.pens[last_pen].diameter, 0.05) = 0)
        and (job.pens[my_entry.pen].tooltip = job.pens[last_pen].tooltip) then
          tool_is_different:= false;

    if (length(my_entry.millings) > 0) and tool_is_different then begin
      // Werkzeug muss gewechselt werden
      Memo1.lines.add('');
      SendSingleCommandStr('G0 G53 Z0'); // move Z up
      if isCancelled then begin
        CancelJob;
        exit;
      end;
      if CheckUseATC.Checked then begin
// Zuletzt benutztes Werkzeug (oder Probe/Dummy nach Start) wieder ablegen
        if not_loaded_flag then begin
          Memo1.lines.add('');
          Memo1.lines.add('HPGL Pen #' + intToStr(my_entry.pen)
          + ' skipped, slot is empty.');
          Memo1.lines.add('');
          continue;
        end;
        atc_used_flag:= true;
        my_new_atc_tool:= job.pens[my_entry.pen].atc;
        if atcArray[my_new_atc_tool].loaded then begin
          if not UnloadTool(my_old_atc_tool) then
            break;
          if not LoadTool(my_new_atc_tool) then  // neues Werkzeug aufnehmen
            break;
        end;
        my_old_atc_tool:= my_new_atc_tool;
        if isCancelled then begin
          CancelJob;
          exit;
        end;
      end else
        if tool_is_different then begin
          if ManualToolchange(my_entry.pen) = mrCancel then
            break;
          SendSingleCommandStr('G0 G53 Z0'); // move Z up
          spindle_on_off(true);
          if (length(my_entry.millings) > 0) then begin
            grbl_go_start_path(my_entry.millings[length(my_entry.millings)-1],
                my_entry.pen, job.pens[my_entry.pen].offset);
            SendListToGrbl;
          end else
            SendSingleCommandStr('G0 X0 Y0'); // move to Zero
        end;
      last_pen:= my_entry.pen;
      is_firstloop := false;
    end;

    // kompletten Milling- oder Drill-Pfad abfahren
    if (length(my_entry.millings) > 0) then begin
      LEDbusy.Checked:= true;
      for p:= length(my_entry.millings)-1  downto 0 do begin
        if isCancelled then
          break;
        Application.ProcessMessages;
        Memo1.lines.add('');
        Memo1.lines.add('Run block '+ IntToStr(i) + ' path '+ IntToStr(p));
        Memo1.lines.add('=========================================');
        grbl_addStr(BitChangeStr(my_entry));
        if my_entry.shape = drillhole then
          grbl_drillpath(my_entry.millings[p], my_entry.pen, job.pens[my_entry.pen].offset)
        else
          grbl_millpath(my_entry.millings[p], my_entry.pen, job.pens[my_entry.pen].offset, my_entry.closed);
         SendListToGrbl;
      end;
    end;
  end; // Ende der Block-Schleife
  if isCancelled then begin
    CancelJob;
    exit;
  end;
  Memo1.lines.add('Blocks done.');
  WaitForIdle;
// grbl_millpath und grbl_drillpath enden mit job.z_penup, deshalb:
  SendSingleCommandStr('G0 G53 Z0'); // move Z up
  spindle_on_off(false);

  if not isCancelled then begin
    // Immer abschließende Aktion wenn ATC enabled
    if atc_used_flag then begin
      // Zuletzt benutztes Werkzeug wieder ablegen
      if UnloadTool(ToolInSpindle) then
        LoadTool(0);
    end;

    if CheckEndPark.Checked and HomingPerformed then
      BtnMoveParkClick(nil)
    else begin
      SendSingleCommandStr('G0 X0 Y0'); // Work Zero
    end;
  end;
  ExitJobMsg;
end;

procedure TForm1.BtnRunGcodeClick(Sender: TObject);
// G-Code-Datei abspielen
var
  my_ReadFile: TextFile;
  my_line, old_line: String;
  pos0, pos1: Integer;
  new_z, z_offs: Double;
  my_Settings: TFormatSettings;
  cancel_save: Boolean;
begin
  DefaultsGridListToJob;
  PenGridListToJob;
  if machine_busy_msg then
    exit;
  BtnRunjob.tag:= 1;
  Memo1.lines.Clear;
  Memo1.lines.add('G-Code file run started.');
  mdelay(grbl_delay_long);
  if Form4.ComboBoxSimType.ItemIndex = 1 then
    Form4.ComboBoxSimType.ItemIndex:= 2;
  GLSsetSimToolMM(ComboBoxGdia.ItemIndex+1, ComboBoxGTip.ItemIndex, clGray); // Werkzeugform und Farbe
  Form4.FormRefresh(nil);  // Ansicht löschen

  OpenFileDialog.FilterIndex:= 2;
  if not OpenFileDialog.Execute then begin
    ExitJobMsg;
    exit;
  end;
  my_line:='';
  FileMode := fmOpenRead;
  AssignFile(my_ReadFile, OpenFileDialog.FileName);
  CurrentPen:= 0;
  PendingAction:= lift;
  Reset(my_ReadFile);
  z_offs:= StrToFloatDef(EditZoffs.Text, 0);
  if z_offs <> 0 then
    Memo1.lines.add('Using Z offset' + EditZoffs.Text);
  my_Settings.Create;
  my_Settings.DecimalSeparator:= '.';
  while not Eof(my_ReadFile) do begin
    if isCancelled then begin
      CancelJob;
      CloseFile(my_ReadFile);
      exit;
    end;
    LEDbusy.Checked:= true;
    Readln(my_ReadFile, my_line);

    pos0:= pos('Z', my_line);
    if pos0 > 0 then begin
    // Z mit Offset versehen
      if not (pos('G53', my_line) > 0) then begin
        pos1:= pos0+1;
        new_z:= extract_float(my_line, pos1, true); // GCode-Dezimaltrenner
        old_line:= my_line;
        new_z:= new_z + z_offs;
        my_line:= copy(old_line, 0, pos0) + FormatFloat('0.00', new_z, my_Settings)
          + copy(old_line, pos1 - 1, 80);  // bis zum Ende der Zeile
      end;
    end;
    grbl_addStr(my_line);
    if grbl_sendlist.Count > 100 then
      SendListToGrbl;
  end;
  CloseFile(my_ReadFile);
  SendListToGrbl;
  WaitForIdle;
  SendSingleCommandStr('G0 G53 Z0'); // move Z up
  spindle_on_off(false);

  if not isCancelled then begin
    // Immer abschließende Aktion wenn ATC enabled
    if CheckEndPark.Checked and HomingPerformed then
      BtnMoveParkClick(nil)
    else begin
      SendSingleCommandStr('G0 X0 Y0'); // Work Zero
    end;
  end;
  ExitJobMsg;
end;


