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
    mdelay(500);  // Spindel-Hochlaufzeit
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
  end;
  result:= Form1.CheckBoxSim.checked;
end;

function probe_z: double;
var my_zval: Double;
begin
// von aktueller Position ausgehend Z nach unten fahren.
// Stoppt wenn Kontakt erreicht.
// Untere Z-Position: Travel Z minus Längensensor-Höhe,
// verhindert, dass das Werkzeug in den Tisch rammt
// nach Stopp durch Kontakt steht Maschinenposition in grbl_mpos.Z
// wird in result übernommen, Z kehrt danach auf 0 zurück
  Form1.Memo1.lines.add('Probing Z (20 mm max.), wait for contact');
  result:= 0;
  if sim_not_supportet(false) then
    exit;
  WaitForIdle;
  grbl_addStr('G38.2 Z' + FloatToStrDot(grbl_mpos.Z - 20) + ' F200');
  SendGrblAndWaitForIdle;
  mdelay(100);
  my_zval:= grbl_mpos.Z;
  Form1.Memo1.lines.add(LastResponseStr);
  if LastResponseStr <> 'OK' then begin
    MessageDlg('Probing failed. ALARM LOCK set,'
      + #13 + 'click Cancel to clear.', mtWarning, [mbOK], 0);
    Form1.Memo1.lines.add('ALARM lock set by GRBL');
  end else begin
    // 2 mm abheben und nochmal
    grbl_moveZ(grbl_mpos.Z + 2, true);
    grbl_addStr('G38.2 Z' + FloatToStrDot(my_zval - 5) + ' F50');
    SendGrblAndWaitForIdle;
    mdelay(100);
    result:= grbl_mpos.Z;
  end;
end;

function probe_z_fixed: double;
var my_zval: Double;
begin
// Probe an Fixed-Position anfahren, grbl_mpos.Z merken und zurück nach oben
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move to reference probe');
  grbl_moveZ(0, true);
  grbl_moveXY(job.probe_x, job.probe_y, true);
  grbl_moveZ(job.probe_z, true);
  SendGrblAndWaitForIdle;
  result:= 0;
  my_zval:= probe_z;
  if my_zval = 0 then
    ResetToolflags
  else begin
    WaitForIdle;
    result:= my_zval;
   end;
end;


// #############################################################################
// #################### R E F E R E N C E  B U T T O N S #######################
// #############################################################################

procedure TForm1.BtnZeroXClick(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Manual Work/part X zero');
  drawing_tool_down:= false;
  WorkZeroXdone:= true;
  if sim_not_supportet(false) then
    exit;
  SendSingleCommandStr('G92 X0');
  WorkZeroX:= grbl_mpos.X;
  NeedsRedraw:= true;
end;

procedure TForm1.BtnZeroYClick(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Manual Work/part Y zero');
  drawing_tool_down:= false;
  WorkZeroYdone:= true;
  if sim_not_supportet(false) then
    exit;
  SendSingleCommandStr('G92 Y0');
  WorkZeroY:= grbl_mpos.Y;
  NeedsRedraw:= true;
end;

// #############################################################################

procedure CancelG43offset;
// WorkZero muss anhand Messklotz oder Kontakthöhe gesetzt sein
var my_dlg_result: integer;
begin
  WaitForIdle;
  Form1.Memo1.lines.add('Cancel Tool Length Offset (TLO)');
  SendSingleCommandStr('G49');
end;

procedure NewG43offset(my_delta: Double);
// WorkZero muss anhand Messklotz oder Kontakthöhe gesetzt sein
var my_dlg_result: integer;
begin
  if FirstToolReferenced then begin
    WaitForIdle;
    Form1.Memo1.lines.add('Set new Tool Length Offset (TLO) to '+FloatToStrDot(ToolDelta)+ ' mm');
    SendSingleCommandStr('G43.1 Z'+FloatToStrDot(ToolDelta));
  end else begin
    Form1.Memo1.lines.add('Tool Length Reference not set, will cancel TLO');
    SendSingleCommandStr('G49');
  end;
end;

function TLCconfirm(confirm: boolean): boolean;
// WorkZero muss anhand Messklotz oder Kontakthöhe gesetzt sein
// liefert true wenn erfolgreich
// wenn bereits FirstToolReferenced TRUE ist, wird ein neuer Längenoffset gesetzt.
// Sonst gilt dieses Tool als Referenz mit Delta = 0.
var my_dlg_result: integer;
begin
  my_dlg_result:= mrOK;
  result:= false;
  if CancelSim then
    exit;
  if not Form1.CheckFixedProbeZ.Checked then
    my_dlg_result:= MessageDlg('Ready to set Tool Length Offset/Reference (TLC).'
    +#13+'Is Z probe sensor placed in fixed position?', mtConfirmation, mbYesNo, 0);

  if my_dlg_result = mrOK then begin
    LEDbusy.Checked:= true;
    if confirm then
      my_dlg_result:= MessageDlg('Please clear machine to probe Tool Length Offset/Reference (TLC).',
        mtConfirmation, mbOKCancel,0);
    if my_dlg_result = mrOK then begin
      CancelG43offset;
      Form1.Memo1.lines.add('Tool Length Offset/Reference (TLC)');
      SendSingleCommandStr('G0 G53 Z0');
      MposOnFixedProbe:= probe_z_fixed; // festen Sensor anfahren
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
    LEDbusy.Checked:= false;
  end;
end;

procedure TForm1.BtnZeroZClick(Sender: TObject);
// manuelle Z-Höhe mit Messklotz
begin
  if machine_busy_msg then
    exit;
  Memo1.lines.add('');
  Memo1.lines.add('Manual Work/part Z zero, will set Z to ');
  Memo1.lines.add('Z Gauge value ' + FormatFloat('00.00', job.z_gauge) + ' mm above part');
  MposOnPartGauge:= grbl_mpos.Z;
  WorkZeroZ:= MposOnPartGauge - job.z_gauge;
  ProbedState:= s_probed_manual;
  WorkZeroZdone:= true;
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
    TLCconfirm(true);
end;

procedure TForm1.BtnZcontactClick(Sender: TObject);
// Werkstück-Probekontakt anfahren. Tool muss über Kontakt sein
var my_dlg_result: integer;
begin
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  my_dlg_result:= MessageDlg('Ready to probe Z from current position.'
    +#13+'Is tool placed above Z part probe sensor?', mtConfirmation, mbYesNo,0);
  if my_dlg_result = mrYes then begin
    Memo1.lines.add('');
    Memo1.lines.add('Probe tool on part (movable probe), will set Z to ');
    Memo1.lines.add('Z Gauge value ' + FormatFloat('00.00', job.probe_z_gauge) + ' mm above part');
    FirstToolReferenced:= false;
    CurrentToolCompensated:= false;
    CancelG43offset;
    MposOnPartGauge:= probe_z;
    if MposOnPartGauge = 0 then begin
      ResetToolflags;
      Memo1.lines.add('Warning: Z height invalid.');
      PlaySound('SYSTEMHAND', 0, SND_ASYNC);
      SendSingleCommandStr('G0 G53 Z0');
    end else begin
      ProbedState:= s_probed_contact;
      WorkZeroZdone:= true;
      WorkZeroZ:= MposOnPartGauge - job.probe_z_gauge;
      SendSingleCommandStr('G92 Z'+FloatToStrDot(job.probe_z_gauge));
      SendSingleCommandStr('G0  G53 Z'+FloatToStrDot(grbl_mpos.z + 5));  // leicht abheben
      TLCconfirm(true);  // ist erstes Werkzeug!
    end;
  end;
  LEDbusy.Checked:= false;
end;

procedure TForm1.BtnProbeTLCclick(Sender: TObject);
// Tool-Delta setzen.
var my_dlg_result: integer;
begin
  if machine_busy_msg then
    exit;
  TLCconfirm(false);
end;

// #############################################################################
// ##########################   A T C  B U T T O N S  ##########################
// #############################################################################

function ManualToolchange(pen: Integer): Integer;
// zur Wechselposition bewegen, auf Aufnahme eines neuen Werkzeugs warten,
// Werkzeug ausmessen und G92-ProbeOffset setzen
// liefert False wenn abgebrochen
var my_dlg_result: integer;
begin
// Neues Werkzeug manuell aufnehmen
  result:= mrNo;
  if CancelSim then
    exit;
  spindle_on_off(false);
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  Form1.Memo1.lines.add('Move to manual tool change position');
  grbl_moveXY(job.toolchange_x, job.toolchange_y, true);
  grbl_moveZ(job.toolchange_z, true);
// manuelle Wechselposition
  SendGrblAndWaitForIdle;
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
    if TLCconfirm(false) then
      Form1.Memo1.lines.add('Tool changed, new Tool Delta Z applied');
  end else
    Form1.Memo1.lines.add('Tool not changed, Tool Delta Z retained');
  ToolInSpindle:= 10; // unknown Tool
  if Form1.Show3DPreview1.checked then
    Form4.GLSupdateATC;
  result:= my_dlg_result;
end;

function UnloadTool(tool_idx: Integer): boolean;
// Werkzeug ablegen, Spannzange offen lassen
// liefert TRUE wenn erfolgreich
var my_atc_x, my_atc_y: Double;
begin
  result:= true;
  if Form1.CheckUseATC.Checked then begin
    spindle_on_off(false);
    if atcArray[tool_idx].inslot then begin
      MessageDlg('ATC Slot #' + IntToStr(tool_idx)
        +' is occupied. No action taken. Job cancelled.', mtWarning, [mbOK], 0);
      result:= false;
      exit;
    end;
    my_atc_x:= job.atc_zero_x + (tool_idx * job.atc_delta_x);
    my_atc_y:= job.atc_zero_y + (tool_idx * job.atc_delta_y);
    Form1.Memo1.lines.add('');
    Form1.Memo1.lines.add('Unload tool at ATC slot #'+ IntToStr(tool_idx));
    grbl_moveZ(0, true);  // move Z up
    grbl_moveXY(my_atc_x, my_atc_y, true);
    SendGrblAndWaitForIdle;
    grbl_moveZ(job.atc_pickup_z + 10, true);  // move Z down
    grbl_addStr('M8');                // Ausblasen
    SendGrblAndWaitForIdle;
    atcArray[tool_idx].inslot:= true;
//    atcArray[tool_idx].tool_pen:= tool_idx;
    ATCtoPanel;
    if Form1.Show3DPreview1.Checked then
      Form4.GLSupdateATC;
    grbl_moveSlowZ(job.atc_pickup_z, true);  // move Z down
    mdelay(200);
    grbl_moveZ(0, true);     // move Z up
    SendGrblAndWaitForIdle;
  end else
   Form1.Memo1.lines.add('ATC not enabled. No action taken.');
  ToolInSpindle:= -1; // kein Tool
end;

function LoadTool(tool_idx: Integer): boolean;
var my_atc_x, my_atc_y: Double;
begin
// Neues Werkzeug aufnehmen
  result:= true;
  if Form1.CheckUseATC.Checked then begin
    GLSsetSimToolMM(atcArray[tool_idx].diameter, atcArray[tool_idx].tooltip, clGray);
    if (ToolInSpindle = tool_idx) then begin
      Form1.Memo1.lines.add('');
      Form1.Memo1.lines.add('ATC tool #'+IntToStr(tool_idx)+ ' already loded');
      result:= false;
      exit;
    end;
    spindle_on_off(false);
    if not atcArray[tool_idx].inslot then begin
      MessageDlg('ATC Slot #' + IntToStr(tool_idx)
      +' is empty. No action taken. Job cancelled.', mtWarning, [mbOK], 0);
      result:= false;
      exit;
    end;
    if ToolInSpindle >= 0 then
      UnloadTool(ToolInSpindle);
    CurrentToolCompensated:= false;
    my_atc_x:= job.atc_zero_x + (tool_idx * job.atc_delta_x);
    my_atc_y:= job.atc_zero_y + (tool_idx * job.atc_delta_y);
    Form1.Memo1.lines.add('');
    Form1.Memo1.lines.add('Load tool at ATC slot #'+ IntToStr(tool_idx));
    grbl_moveZ(0, true);  // move Z up
    grbl_moveXY(my_atc_x, my_atc_y, true);
    grbl_moveZ(job.atc_pickup_z + 20, true);  // move Z down
    grbl_moveSlowZ(job.atc_pickup_z, true);  // move Z down
    SendGrblAndWaitForIdle;
    mdelay(200);
    SendSingleCommandStr('M9');
    mdelay(100);
    atcArray[tool_idx].inslot:= false;
    ATCtoPanel;
    if Form1.Show3DPreview1.Checked then
      Form4.GLSupdateATC;
    grbl_moveZ(0, true);  // move Z up
    TLCconfirm(false);
  end else
    Form1.Memo1.lines.add('ATC not enabled. No action taken.');
  ToolInSpindle:= tool_idx;
end;

// #############################################################################

procedure TForm1.BtnMoveToATCClick(Sender: TObject);
// nur zum ATC-Slot bewegen, zum Test der Koordinaten
var
  my_atc: Integer;
  my_atc_x, my_atc_y: Double;
begin
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  my_atc:= ComboBoxATC.ItemIndex;
  Form1.Memo1.lines.add('');
  Memo1.lines.add('Move to ATC #'+IntToStr(my_atc)+' position (Z up)');
  my_atc_x:= job.atc_zero_x + (my_atc * job.atc_delta_x);
  my_atc_y:= job.atc_zero_y + (my_atc * job.atc_delta_y);
  grbl_moveXY(my_atc_x, my_atc_y, true);
  //grbl_moveZ(job.atc_pickup_z + 10, true);  // move Z down near pickup-Höhe
  SendGrblAndWaitForIdle;
  NeedsRedraw:= true;
  LEDbusy.Checked:= false;
end;

procedure TForm1.BtnMoveToolChangeClick(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  ManualToolchange(-1);
end;

procedure TForm1.BtnLoadClick(Sender: TObject);
// Werkzeug aus Slot oder manuell aufnehmen
var atc: Integer;
begin
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  if Form1.CheckUseATC.Checked then begin
    LoadTool(ComboBoxATC.ItemIndex)
  end else
    BtnMoveToolChangeClick(sender);
  LEDbusy.Checked:= false;
  CurrentToolCompensated:= false;
end;

procedure TForm1.BtnUnloadClick(Sender: TObject);
// Werkzeug in freien Slot einsetzen
begin
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  if Form1.CheckUseATC.Checked then begin
    UnloadTool(ComboBoxATC.ItemIndex)
  end else
    BtnMoveToolChangeClick(sender);
  LEDbusy.Checked:= false;
  CurrentToolCompensated:= false;
end;

procedure TForm1.PanelATCClick(Sender: TObject);
// ATC-Belegung manuell durch Anklicken der Panels ändern
var i: Integer;
  my_loaded: boolean;
  my_dia: Double;
  my_str: String;
begin
  i:= (Sender as TPanel).Tag;
  atcArray[i].loaded:= not atcArray[i].loaded;
  atcArray[i].inslot:= atcArray[i].loaded;
  if atcArray[i].enable then begin
    if atcArray[i].loaded then begin
      my_str:= 'HPGL Pen #'+IntToStr(atcArray[i].pen) + ': '
      + FloatToStr(atcArray[i].diameter)+' mm ' + ToolTipArray[atcArray[i].tooltip];
      (Sender as TPanel).Color:= atcArray[i].color;
    end else begin
      my_str:= 'Unloaded';
      (Sender as TPanel).Color:= clBtnFace;
    end;
  end else begin
    if atcArray[i].used then begin
      (Sender as TPanel).Font.Color:= clblack;
      my_str:= 'Disabled';
    end else begin
     (Sender as TPanel).Font.Color:= clgray;
      my_str:= 'Disabled, unused in Job';
    end;
    if atcArray[i].loaded then begin
      my_str:= 'Undefined Tool';
      (Sender as TPanel).Color:= clsilver;
    end else begin
      my_str:= 'Was unloaded';
      (Sender as TPanel).Color:= clBtnFace;
    end;
  end;
  (Sender as TPanel).Hint:= my_str;
  Form4.GLSupdateATC;
end;


procedure TForm1.BtnListToolsClick(Sender: TObject);
var i, my_tooltip: Integer;
  my_first: boolean;
  my_dia: Double;
  my_str: String;
begin
  Memo1.lines.add('');
  Memo1.lines.add('List of enabled tools used in job:');
  Memo1.lines.add('=========================================');
  if Form1.CheckUseATC.Checked then
    Memo1.lines.add('Load collet with dummy tool (ATC slot 0 empty)!');
  my_first:= true;
  for i:= 0 to 31 do begin
    if job.pens[i].enable and  job.pens[i].used then begin
      my_tooltip:= job.pens[i].tooltip;
      if job.pens[i].shape = drillhole then
        my_tooltip:= 6;
      my_str:= 'Tool #' + IntToStr(i) +' = '
        + FormatFloat('0.00',job.pens[i].diameter) + ' mm, ' + ToolTipArray[my_tooltip];
      if (not Form1.CheckUseATC.Checked) and my_first then
        my_str:= my_str + ', tool must be in collet';
      my_first:= false;
      Memo1.lines.add(my_str);
    end;
  end;
  Memo1.lines.add('=========================================');
  Memo1.lines.add('');
end;

procedure TForm1.BtnListAssignmentsClick(Sender: TObject);
var i: Integer;
  my_loaded: boolean;
  my_dia: Double;
  my_str: String;
begin
  Memo1.lines.add('');
  Memo1.lines.add('List of ATC slot assignments:');
  Memo1.lines.add('=========================================');
  Memo1.lines.add('Slot #0 must be EMPTY, probe/dummy tool is in collet');
  for i:= 1 to 9 do begin
    if atcArray[i].loaded then begin
      if atcArray[i].pen = 0 then
        my_str:= 'Slot #' + IntToStr(i) + ' is UNDEFINED'
      else
        my_str:= 'Slot #' + IntToStr(i)
        +' is HPGL Pen #'+IntToStr(atcArray[i].pen) + ': '
        + FloatToStr(atcArray[i].diameter)+' mm '
        + ToolTipArray[atcArray[i].tooltip];
    end else
      my_str:= 'Slot #' + IntToStr(i) +' is DISABLED';
    if not atcArray[i].used then
      my_str:= my_str + ' (unused in job)';
    Memo1.lines.add(my_str);
  end;
  Memo1.lines.add('=========================================');
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
  SendGrblAndWaitForIdle;
  NeedsRedraw:= true;
  LEDbusy.Checked:= false;
end;

procedure TForm1.BtnMoveWorkZeroClick(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  Memo1.lines.add('');
  if ProbedState <> s_notprobed then begin
    Memo1.lines.add('Move to tool part zero');
    Memo1.lines.add('Pen Lift value ' + FormatFloat('00.00', job.z_penlift) + ' mm above part');
    spindle_on_off(false);
    drawing_tool_down:= false;
    grbl_moveZ(0, true);
    grbl_moveXY(0,0, false);
    grbl_moveZ(job.z_penlift, false);
    SendGrblAndWaitForIdle;
    if Form1.ShowDrawing1.Checked then
      SetDrawingToolPosMM(0, 0, job.z_penlift);
  end else
    Memo1.lines.add('Tool was not zeroed on part. No action taken.');
  NeedsRedraw:= true;
  LEDbusy.Checked:= false;
end;

procedure StartJogAction(sender: TObject; tag: Integer);
var dx, dy, dz: Double;
  my_str: string;
//  first_loop_done: Boolean;
  my_delay: Integer;
begin
  if sim_not_supportet(false) then
    exit;
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
  if HomingPerformed and (Form1.BtnCancel.Tag = 0) then
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


procedure TForm1.BtnRunJobClick(Sender: TObject);
var i, my_len, p, last_pen, my_old_atc_tool, my_new_atc_tool, my_btn: Integer;
  my_entry: Tfinal;
  my_atc_x, my_atc_y: Double;
  my_str: String;
  is_firstloop, not_loaded_flag, atc_used_flag: Boolean;
  tool_is_different: Boolean;
begin
  DefaultsGridListToJob;
  PenGridListToJob;
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  JobRunning:= true;
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
  LEDbusy.Checked:= true;
  last_pen:= 0;
  Form1.Memo1.lines.add('');
  my_str:= ', Mill';
  if CheckUseATC.Checked then begin
    CurrentToolCompensated:= false;
    FirstToolReferenced:= false;
    BtnListAssignmentsClick(nil);
    my_btn := MessageDlg('Make sure spindle is loaded with '
      + #13 + 'probe/dummy tool 0, ATC slot 0 is empty'
      + #13 + 'and ATC tray is loaded with tools listed.', mtConfirmation, mbOKCancel, 0);
    if my_btn = mrCancel then begin
      LEDbusy.Checked:= false;
      Memo1.lines.add('Job ended.');
      LEDbusy.Checked:= false;
      JobRunning:= false;
      exit;
    end;
  end;
  is_firstloop := true;
  atc_used_flag:= false;
  my_old_atc_tool:= 0;

  my_entry:= final_array[0];
  if (length(my_entry.millings) > 0) then begin
    SendSingleCommandStr('G0 G53 Z0');
    SendSingleCommandStr('G0 X0 Y0'); // move to Zero
    spindle_on_off(true);
  end;

  for i:= 0 to my_len-1 do begin
    if (BtnCancel.Tag = 1) then begin
      LEDbusy.Checked:= false;
      JobRunning:= false;
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
        and (job.pens[my_entry.pen].tooltip = job.pens[last_pen].tooltip)
        and (job.pens[my_entry.pen].speed = job.pens[last_pen].speed) then
        tool_is_different:= false;

    if (length(my_entry.millings) > 0) and tool_is_different then begin
      // Werkzeug muss gewechselt werden
      Memo1.lines.add('');
      SendSingleCommandStr('G0 G53 Z0'); // move Z up
      if (BtnCancel.Tag = 1) then begin
        LEDbusy.Checked:= false;
        JobRunning:= false;
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
        if (BtnCancel.Tag = 1) then begin
          LEDbusy.Checked:= false;
          JobRunning:= false;
          exit;
        end;
      end else
        if not is_firstloop then begin
          if (BtnCancel.Tag = 1) then begin
            LEDbusy.Checked:= false;
            JobRunning:= false;
            exit;
          end;
          if ManualToolchange(my_entry.pen) = mrCancel then
            break;
          if (Form1.BtnCancel.Tag = 1) then begin
            LEDbusy.Checked:= false;
            JobRunning:= false;
            exit;
          end;
          spindle_on_off(true);
        end;
      last_pen:= my_entry.pen;
      is_firstloop := false;
    end;

    // kompletten Milling- oder Drill-Pfad abfahren
    if (length(my_entry.millings) > 0) then begin
      if (BtnCancel.Tag = 1) then begin
        LEDbusy.Checked:= false;
        JobRunning:= false;
        exit;
      end;
      for p:= length(my_entry.millings)-1  downto 0 do begin
        if (Form1.BtnCancel.Tag = 1) then begin
          LEDbusy.Checked:= false;
          JobRunning:= false;
          exit;
        end;
        Application.ProcessMessages;
        Memo1.lines.add('');
        Memo1.lines.add('Run block '+ IntToStr(i) + ' path '+ IntToStr(p));
        Memo1.lines.add('=========================================');
//        Memo1.lines.add('Bit change: ' + FormatFloat('0.00', job.pens[my_entry.pen].diameter)
//          + ' ' + IntToStr(job.pens[my_entry.pen].tooltip)+' '+ IntToStr(job.pens[my_entry.pen].color));
        grbl_addStr('//Bit change: ' + FormatFloat('0.00', job.pens[my_entry.pen].diameter)
          + ' ' + IntToStr(job.pens[my_entry.pen].tooltip)+' '+ IntToStr(job.pens[my_entry.pen].color));
        if my_entry.shape = drillhole then
          grbl_drillpath(my_entry.millings[p], my_entry.pen, job.pens[my_entry.pen].offset)
        else
          grbl_millpath(my_entry.millings[p], my_entry.pen, job.pens[my_entry.pen].offset, my_entry.closed);
         SendGrblAndWaitForIdle;
      end;
    end;
  end; // Ende der Block-Schleife
  if (BtnCancel.Tag = 1) then begin
    LEDbusy.Checked:= false;
    JobRunning:= false;
    exit;
  end;
  Memo1.lines.add('Blocks done.');
// grbl_millpath und grbl_drillpath enden mit job.z_penup, deshalb:
  SendSingleCommandStr('G0 G53 Z0'); // move Z up
  spindle_on_off(false);

  if not (Form1.BtnCancel.Tag = 1) then begin
    // Immer abschließende Aktion wenn ATC enabled
    if atc_used_flag then begin
      // Zuletzt benutztes Werkzeug wieder ablegen
      if UnloadTool(ToolInSpindle) then
        LoadTool(0);
    end;

    if CheckEndPark.Checked and (HomingPerformed or CheckboxSim.checked) then
      BtnMoveParkClick(nil)
    else begin
      SendSingleCommandStr('G0 X0 Y0'); // Work Zero
    end;
  end;
  Memo1.lines.add('Job ended.');
  Memo1.lines.add('');
  drawing_tool_down:= false;
  NeedsRedraw:= true;
  Form1.ProgressBar1.position:= 0;
  LEDbusy.Checked:= false;
  JobRunning:= false;
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
  LEDbusy.Checked:= true;
  JobRunning:= true;
  Memo1.lines.Clear;
  Memo1.lines.add('G-Code file run started.');
  mdelay(grbl_delay_long);
  if Form4.ComboBoxSimType.ItemIndex = 1 then
    Form4.ComboBoxSimType.ItemIndex:= 2;
  GLSsetSimToolMM(ComboBoxGdia.ItemIndex+1, ComboBoxGTip.ItemIndex, clGray); // Werkzeugform und Farbe
  Form4.FormRefresh(nil);  // Ansicht löschen

  OpenFileDialog.FilterIndex:= 2;
  if not OpenFileDialog.Execute then begin
    LEDbusy.Checked:= true;
    JobRunning:= false;
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
    if (BtnCancel.Tag = 1) then begin
      LEDbusy.Checked:= false;
      JobRunning:= false;
      exit;
    end;
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
      SendGrblAndWaitForIdle;
  end;
  CloseFile(my_ReadFile);
  SendGrblAndWaitForIdle;

  SendSingleCommandStr('G0 G53 Z0'); // move Z up
  spindle_on_off(false);

  if not (BtnCancel.Tag = 1) then begin
    // Immer abschließende Aktion wenn ATC enabled
    if CheckEndPark.Checked and (HomingPerformed or CheckboxSim.checked) then
      BtnMoveParkClick(nil)
    else begin
      SendSingleCommandStr('G0 X0 Y0'); // Work Zero
    end;
  end;
  Memo1.lines.add('Job ended.');
  Memo1.lines.add('');
  NeedsRedraw:= true;
  Form1.ProgressBar1.position:= 0;
  LEDbusy.Checked:= false;
  JobRunning:= false;
end;

procedure reset_atc;
var
  i: Integer;
begin
  for i:= 0 to 31 do
    SetATCtoolFromJob(i);
  ATCtoPanel;
  if Form1.Show3DPreview1.Checked then
    Form4.FormRefresh(nil);
  if Form1.CheckUseATC.Checked then
    MessageDlg('ATC may not match GRBLize setup.'
    + #13 + 'Sort ATC tools manually.', mtWarning, [mbOK], 0);
  NeedsRedraw:= true;
end;

procedure TForm1.BtnEmergencyStopClick(Sender: TObject);
var
  my_response: String;
begin
  LEDbusy.Checked:= true;
  CancelRequest:= true;
  ResetToolflags;
  Memo1.lines.add('');
  Memo1.lines.add('Emergency Stop');
  Memo1.lines.add('=========================================');
  // E-Stop ausführen
  if grbl_is_connected and (not Form1.CheckBoxSim.checked) then begin
    grbl_sendStr(#24, false);   // Soft Reset CTRL-X, Stepper sofort stoppen
    mdelay(250);
    DisableStatus;
    grbl_wait_for_timeout(250);
    MessageDlg('EMERGENCY STOP. Steps missed if running.'
      + #13 + 'Click <Home Cycle> or <Alarm> panel'
      + #13 + 'to release ALARM LOCK.', mtWarning, [mbOK], 0);
    EnableStatus;  // automatische Upates freischalten
  end else begin
    Memo1.lines.add('Reset GRBL Simulation');
  end;
  HomingPerformed:= false;
  grbl_sendlist.Clear;
  reset_atc;
  Memo1.lines.add('Done. Please re-run Home Cycle.');
  Memo1.lines.add('');
  LEDbusy.Checked:= false;
end;

procedure TForm1.BtnCancelClick(Sender: TObject);
var
  my_response: String;
  my_job_running: Boolean;
begin
  my_job_running:= JobRunning;

  if (BtnCancel.Tag = 1) then begin
    CancelSim:= false;
    CancelJob:= false;
    SendSingleCommandStr('$X'); // Unlock Alarm State
    if JobWasCancelled then begin
      Memo1.lines.add('');
      Memo1.lines.add('Unlock Alarm State, restore offsets');
      grbl_offsXY(grbl_mpos.x - WorkZeroX, grbl_mpos.y - WorkZeroY);
      grbl_offsZ(grbl_mpos.z - WorkZeroZ);
      grbl_moveZ(0, true);
      SendGRBLandWaitForIdle;
      spindle_on_off(false);
      Memo1.lines.add('Done.');
    end;
    JobWasCancelled:= false;
    BtnCancel.Caption:= 'CANCEL';
    BtnCancel.tag:= 0;
  end else begin
    BtnCancel.tag:= 1;
    BtnCancel.Caption:= 'RESET';
    reset_atc;
    CancelSim:= true;
    if CheckBoxSim.Checked then begin
      Memo1.lines.add('');
      Memo1.lines.add('Cancel Job Simulation');
      Memo1.lines.add('=========================================');
      CancelJob:= true;
      mdelay(500);
      ResetSimulation;
      Memo1.lines.add('Feed hold and reset simulation.');
      Memo1.lines.add('Click RESET for idle.');
      Memo1.lines.add('');
    end else begin
      if my_job_running then begin
        CancelJob:= true;  // alle Schleifen abbrechen
        JobWasCancelled:= true;
        CancelRequest:= true;
        repeat
          Application.processMessages;
        until not CancelRequest;  // bis TimerStatus Cancel behandelt hat
      end;
    end;
  end;
end;


procedure TForm1.BtnHomeCycleClick(Sender: TObject);
var
  my_response: String;
begin
  CancelJob:= false;
  CancelSim:= false;
  BtnCancel.Caption:= 'CANCEL';
  BtnCancel.tag:= 0;
  LEDbusy.Checked:= true;
  Memo1.lines.add('');
  Memo1.lines.add('Home cycle initiated');
  DefaultsGridListToJob;
  if sim_not_supportet(true) then
    ResetSimulation
  else begin
    spindle_on_off(false);
    ResetToolflags;
    DisableStatus;
    my_response:= grbl_sendStr('$h'+#13, true);
    Memo1.lines.add(uppercase(my_response));
    if my_response <> 'ok' then begin
      MessageDlg('Homing failed. ALARM LOCK cleared,'
        + #13 + 'but do not rely on machine status.', mtWarning, [mbOK], 0);
      grbl_sendStr('$X'+#13, false);   // Clear Lock
      grbl_wait_for_timeout(200);
    end;
    EnableStatus;  // automatische Upates freischalten
  end;
  HomingPerformed:= true;
  Memo1.lines.add('Done.');
  Memo1.lines.add('');
  LEDbusy.Checked:= false;
end;

