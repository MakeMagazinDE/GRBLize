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
  result:= 0;
  if start_idx >= length(grbl_str) then
    exit;
  while grbl_str[start_idx] < #33 do
    inc(start_idx);
  for i:= start_idx to length(grbl_str) do begin
    if CharInSet(grbl_str[i], ['0'..'9', '+', '-', ',', '.']) then
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
    if CharInSet(grbl_str[i], ['0'..'9', '+', '-']) then
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
  if pen < 0 then begin
    result:= '(undefined)';
    exit;
  end;
  my_tooltip:= job.pens[pen].tooltip;
  if job.pens[pen].shape = drillhole then
    my_tooltip:= 6;
  my_str:= 'Tool #' + IntToStr(pen)+ ': ' + FormatFloat('0.00',job.pens[pen].diameter) + ' mm'
    + #32 + string(ToolTipArray[my_tooltip]);
  result:= my_str;
end;

procedure spindle_on_off(const switch_on: Boolean);
begin
  if SpindleRunning = switch_on then
    exit;
  WaitForIdle;
  if switch_on then begin
    SendSingleCommandStr('M3S1000');
    Form1.Memo1.lines.add('Spindle ON, acceleration wait '+ IntToStr(job.spindle_wait) + ' sec');
  end else begin
    if isCancelled then
      SendSingleCommandStr('M5')  // Liste senden abgeschaltet!
    else begin
      grbl_sendlist.add('G4 P0');
      grbl_sendlist.add('M5');
      SendListToGrbl;
    end;
    Form1.Memo1.lines.add('Spindle OFF, brake wait '+ IntToStr(job.spindle_wait div 2) + ' sec');
  end;
  if isGrblActive then begin
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
var my_zval1, my_zval2, TargetZ: Double;
    my_cmd, my_response: String;
begin
// von aktueller Position ausgehend Z nach unten fahren.
// Stoppt wenn Kontakt erreicht.
// Untere Z-Position: Travel Z minus Längensensor-Höhe,
// verhindert, dass das Werkzeug in den Tisch rammt
// nach Stopp durch Kontakt steht Maschinenposition in grbl_mpos.Z
// wird in result übernommen, Z kehrt danach auf 0 zurück
  Form1.Memo1.lines.add('Probing Z (25 mm max.), wait for contact');
  result:= 0;
  if isGrblActive then
    try
      result:= 0;
      if (MachineState = alarm) then
        exit;
      WaitForIdle;
      grbl_wait_for_timeout(25);
      DisableStatus;

      WorkZeroZDone:= false;                                 // reset part ZeroZ
      grbl_sendStr('G92 Z'+FloatToStrDot(grbl_mpos.z) + #13, true);

      my_zval1:= grbl_mpos.Z;

      TargetZ := my_zval1 - 25;                          // auf max. Z begrenzen
      if -job.table_z > TargetZ then
        TargetZ := -job.table_z + 1;
      my_cmd:= 'G38.2 Z' + FloatToStrDot(TargetZ) + ' F200';
                     // wartet auf Probe-Meldung, z.B. [PRB:0.000,0.000,1.492:1]
      my_response:= SendReceive(my_cmd, 0);

      grbl_receiveStr(25); // 'ok'
      if pos('ALARM', ansiuppercase(my_response)) = 0 then
        my_zval1:= extract_probe_pos(my_response)
      else begin
        MachineState:= alarm;
        exit;
      end;

      // 2 mm abheben (falls möglich) und nochmal langsam
      if (my_zval1 + 2) > 0 then
        exit;  // result ist 0

      SendReceiveAndDwell('G0 G53 Z' + FloatToStrDot(my_zval1 + 2));

      // wartet auf Probe-Meldung, z.B. [PRB:0.000,0.000,1.492:1]

      TargetZ := my_zval1 - 1;                          // auf max. Z begrenzen
      if -job.table_z > TargetZ then
        TargetZ := -job.table_z + 1;
      my_cmd:= 'G38.2 Z' + FloatToStrDot(TargetZ) + ' F50';

      my_response:= SendReceive(my_cmd, 0);
      grbl_receiveStr(25); // 'ok'
      if pos('ALARM', ansiuppercase(my_response)) = 0 then
        my_zval2:= extract_probe_pos(my_response)
      else begin
        MachineState:= alarm;
        exit;
      end;

      Form1.Memo1.lines.add('Probe contact at Z = ' + FloatToStr(my_zval2));
      // liegen beide Werte im Toleranzbereich 0,1 mm?
      if CompareValue(my_zval1, my_zval2, 0.1) = 0 then
        result:= my_zval2
      else
        Form1.Memo1.lines.add('ERROR: Probe contact failure - exceed tolerance');

    finally
      if MachineState = alarm then begin
        Form1.Memo1.lines.add('ALARM lock set by GRBL');
        MessageDlg('Probing failed. ALARM LOCK set,'
          + #13 + 'by GRBL - will be cleared automatically.', mtWarning, [mbOK], 0);
        ClearAlarmLock;
      end else if result = 0 then
        MessageDlg('Probing failed, contact trigger exceeds'
          + #13 + 'limit of tolerance. Repeat procedure.', mtWarning, [mbOK], 0);

      grbl_wait_for_timeout(20);
      SendReceiveAndDwell('G0 G53 Z0');  // Z up
      // Workaround für GRBL-JOG mit Zero-Eingang als Limit-Switch:
      repeat
        GetStatus;
      until MachineState < zero;
      EnableStatus;
    end else if isSimActive then begin
      result:= -10;
      SendReceiveAndDwell('G0 G53 Z0');  // Z up
  end;
end;

function probe_z_fixed: double;
var my_zval: Double;
begin
  result:= 0;
  if (MachineState = alarm) then
    exit;
  // Probe an Fixed-Position anfahren, grbl_mpos.Z merken und zurück nach oben
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move to reference probe');
  grbl_moveZ(0, true);
  grbl_moveXY(job.probe_x, job.probe_y, true);
  grbl_moveZ(job.probe_z, true);
  grbl_sendlist.add('G4 P0');
  SendListToGrbl;
  my_zval:= probe_z;
  if my_zval = 0 then
    ResetToolflags
  else
    result:= my_zval;
end;

procedure CancelG43offset;
// WorkZero muss anhand Messklotz oder Kontakthöhe gesetzt sein
begin
  if (MachineState = alarm) then
    exit;
  WaitForIdle;
  Form1.Memo1.lines.add('Cancel Tool Length Offset (TLO)');
  SendSingleCommandStr('G49');
end;

procedure NewG43offset(my_delta: Double);
// WorkZero muss anhand Messklotz oder Kontakthöhe gesetzt sein
begin
  if (MachineState = alarm) then
    exit;
  WaitForIdle;
  Form1.Memo1.lines.add('Set new Tool Length Offset (TLO) to '+FloatToStrDot(my_delta)+ ' mm');
  SendSingleCommandStr('G43.1 Z'+FloatToStrDot(my_delta));
end;

procedure InvalidateTLCs;
var i: integer;
begin
  for i:= 0 to c_numATCslots do begin
    atcArray[i].TREFok:= false;
    atcArray[i].TLCok:= false;
    atcArray[i].TLCdelta:= 0.0;
  end;
end;

function DoTLCandConfirm(confirm: boolean; atc_idx: Integer): boolean;
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
  result:= true;
  if not (job.toolchange_pause and job.use_fixed_probe) then
    exit;
  if confirm then
    my_dlg_result:= MessageDlg('Please clear machine to probe Tool Length Offset/Reference (TLC).',
      mtConfirmation, mbOKCancel,0);
  if my_dlg_result = mrOK then begin
    result:= false;
    LEDbusy.Checked:= true;
    CancelG43offset;
    Form1.Memo1.lines.add('Tool Length Offset/Reference (TLC)');
    SendSingleCommandStr('G0 G53 Z0');
    MposOnFixedProbe:= probe_z_fixed; // festen Sensor anfahren
    if (MachineState = alarm) or (MposOnFixedProbe = 0) then
      exit;
    result:= true;
    if atc_idx = 1 then begin
      atcArray[1].TREFok:= true;
      MposOnFixedProbeReference:= MposOnFixedProbe;
      atcArray[1].TLCref:= MposOnFixedProbeReference;
      atcArray[1].TLCdelta:= 0;
    end else begin
      atcArray[atc_idx].TLCref:= 0;
      atcArray[atc_idx].TLCok:= true;
      // Differenz zu erstem Werkzeug
      atcArray[atc_idx].TLCdelta:= MposOnFixedProbe - MposOnFixedProbeReference;
      NewG43Offset(atcArray[atc_idx].TLCdelta);
    end;
    UpdateATC;
  end;
end;


// #############################################################################
// ######################## R U N  J O B  B U T T O N S ########################
// #############################################################################

function CountUsedATCtools: Integer;
// zählt tatsächlich benutzte Werkzeuge
var
  i: Integer;
begin
// atcArray[0] ist unbenutzt!
  for i:= 1 to c_numATCslots do
    if not atcArray[i].used then
     break;
  result:= i-1;
end;

function isToolDifferent(pen1, pen2: Integer): Boolean;
// evt. (fast) gleicher Durchmesser und gleiche Form? Dann "false" liefern
begin
  result:= pen1 <> pen2;
  if (CompareValue(job.pens[pen1].diameter, job.pens[pen2].diameter, 0.05) = 0)
    and (job.pens[pen1].tooltip = job.pens[pen2].tooltip) then
      result:= false;
end;

procedure ExitJobMsg(lift_tool: Boolean);
begin
  // falls wg. speed abgeschaltet
  GLSfinalize3Dview;
  grbl_sendlist.Clear;
  LastToolUsed:= ToolInSpindle;
  spindle_on_off(false);
  drawing_tool_down:= false;
  Form1.Memo1.lines.add('Job ended.');
  Form1.Memo1.lines.add('');
  NeedsRedraw:= true;
  Form1.ProgressBar1.position:= 0;
  Form1.BtnRunJob.enabled:= true;
  Form1.BtnRunTool.enabled:= true;
  Form1.BtnRunGcode.enabled:= true;
  Form1.BtnRunjob.tag:= 0;
  Form1.BtnCancel.tag:= 0;
  if lift_tool then
    SendSingleCommandAndDwell('G0 G53 Z0');
  Screen.Cursor:= crDefault;
//  UpdateATCsg;
end;

function BitChangeStr(const my_entry: Tfinal): String;
begin
  result:='// Bit change: ' + FormatFloat('0.00', job.pens[my_entry.pen].diameter)
    + ' ' + IntToStr(job.pens[my_entry.pen].tooltip)+' '+ IntToStr(job.pens[my_entry.pen].color);
end;

procedure run_path(my_entry: Tfinal);
// kompletten Milling- oder Drill-Pfad abfahren
var p: Integer;
begin
  if (length(my_entry.millings) > 0) then with Form1 do begin
    LEDbusy.Checked:= true;
    for p:= high(my_entry.millings) downto 0 do begin
      if isCancelled then
        break;
      Application.ProcessMessages;
      if my_entry.milling_enables[p] then begin
        Memo1.lines.add('');
        Memo1.lines.add('Run path '+ IntToStr(p));
        Memo1.lines.add('=========================================');
        grbl_sendlist.add(BitChangeStr(my_entry));
        if my_entry.shape = drillhole then
          grbl_drillpath(my_entry.millings[p], my_entry.pen, job.pens[my_entry.pen].offset)
        else
          grbl_millpath(my_entry.millings[p], my_entry.pen, job.pens[my_entry.pen].offset, my_entry.closed);
        SendListToGrbl;
      end;
    end;
  end;
end;

procedure TForm1.BtnRunToolClick(Sender: TObject);
// nur einzelnes Werkzeug abarbeiten
var i, my_len, atc_from_pens, my_btn, my_pen: Integer;
  my_entry: Tfinal;
begin
  try
    if machine_busy_msg then
      exit;
    my_len:= length(final_array);
    if my_len < 1 then
       exit;
    if isSimActive then
      ResetSimulation;
    DefaultsGridListToJob;
    PenGridListToJob;
    BtnRunjob.tag:= 1;
    Form4.GLLinesPath.Visible:= Form4.CheckToolpathVisible.Checked;
    Form4.GLDummyCubeTool.visible:= true;

    ToolInSpindle:= sgATC.Row;
    GLSsetToolToATCidx(ToolInSpindle);
    ForceToolPositions(grbl_wpos.x, grbl_wpos.y, grbl_wpos.z);
    Form1.Memo1.lines.add('');
    Memo1.lines.clear;
    my_btn := MessageDlg('Is machine zeroed with selected tool?'
      + #13 + 'Make sure spindle collet is loaded with:'
      + #13 + #13 + pen_description(atcArray[ToolInSpindle].pen)
      + #13 + #13 + 'Click OK to proceed, CANCEL to terminate job.', mtConfirmation, mbOKCancel, 0);
    Memo1.lines.Clear;
    Memo1.lines.add('Job run started.');
    Memo1.lines.add('=========================================');
    if my_btn = mrCancel then
      exit;

    // ATC- bzw. Tool-Liste abarbeiten
    SendSingleCommandStr('G0 G53 Z0');
// alle Pfade mit gleicher ATC-Nummer abarbeiten. ATC enthält immer die Liste
// der im Job benutzten Werkkzeuge.
    my_pen:= atcArray[ToolInSpindle].pen;
    GLSmakeToolArray(job.pens[my_pen].diameter);
    for i:= 0 to my_len-1 do begin
      my_entry:= final_array[i];
      if not my_entry.enable then
        continue;
      if length(my_entry.millings) = 0 then
        continue;
      atc_from_pens:= job.pens[my_entry.pen].atc;
      if atc_from_pens <> ToolInSpindle then
        continue;
      if isCancelled then
        exit;  // "finally" wird trotzdem ausgeführt!
      LEDbusy.Checked:= true;
      spindle_on_off(true);
      run_path(my_entry);
      Memo1.lines.add('Path done.');
    end;
    Memo1.lines.add('Blocks done.');
    WaitForIdle;
// grbl_millpath und grbl_drillpath enden mit job.z_penup, deshalb:
    SendSingleCommandStr('G0 G53 Z-1'); // move Z up
    spindle_on_off(false);

    if CheckEndPark.Checked then
      MoveToPos('park', job.park_x, job.park_y, job.park_z, false, false)
//      BtnMoveParkClick(nil)
    else begin
      SendSingleCommandStr('G0 X0 Y0'); // Work Zero
    end;
  finally
    ExitJobMsg(true);
  end;
  SetToolInSpindle(ToolInSpindle + 1);       // auf nächstes Tool weiterschalten
end;

procedure TForm1.BtnRunJobClick(Sender: TObject);
var i, atc_idx, my_len, atc_from_pens, my_btn, my_pen: Integer;
  my_entry: Tfinal;
  my_used_tools_count: Integer;
begin
  try
    BtnRunJob.enabled:= false;
    BtnRunTool.enabled:= false;
    BtnRunGcode.enabled:= false;
    SgATC.enabled:= false;
    DefaultsGridListToJob;
    PenGridListToJob;
    if machine_busy_msg then
      exit;
    my_len:= length(final_array);
    if my_len < 1 then
       exit;
    my_used_tools_count:= CountUsedATCtools; // tatsächlich benutzte Werkzeuge
    if my_used_tools_count < 1 then
       exit;
    for i := 0 to high(final_array) do
      final_array[i].enable:= is_any_milling_enabled(final_array[i]);
    if isSimActive then
      ResetSimulation;
    if ToolInSpindle <> 1 then begin
      PlaySound('SYSTEMHAND', 0, SND_ASYNC);
      Memo1.lines.add('');
      Memo1.lines.add('ERROR: Tool 1 is not in spindle.');
      exit;
    end;

    BtnRunjob.tag:= 1;
    GLSclearPathNodes;
    Form4.GLLinesPath.Visible:= Form4.CheckToolpathVisible.Checked;
    Form4.GLDummyCubeTool.visible:= true;
    GLSsetToolToATCidx(ToolInSpindle);

    Memo1.lines.clear;
    my_btn := MessageDlg('Is machine zeroed with first tool?'
      + #13 + 'Make sure spindle collet is loaded with:'
      + #13 + #13 + pen_description(atcArray[ToolInSpindle].pen)
      + #13 + #13 + 'Click OK to proceed, CANCEL to terminate job.', mtConfirmation, mbOKCancel, 0);
    Memo1.lines.Clear;
    Memo1.lines.add('Job run started.');
    Memo1.lines.add('=========================================');
    GLSneedsRedrawTimeout:= 1;
    GLSneedsATCupdateTimeout:= 1;
    if my_btn = mrCancel then
      exit;
    if (not atcArray[ToolInSpindle].TREFok) and CheckToolChange.checked then begin
      if not DoTLCandConfirm(false, ToolInSpindle) then
        exit;
    end;

    // ATC- bzw. Tool-Liste abarbeiten
    SendSingleCommandStr('G0 G53 Z0');
    for atc_idx:= 1 to my_used_tools_count do begin
// alle Pfade mit gleicher ATC-Nummer abarbeiten. ATC enthält immer die Liste
// der im Job benutzten Werkzeuge.
      GLSsetToolToATCidx(atc_idx);
      ForceToolPositions(grbl_wpos.x, grbl_wpos.y, grbl_wpos.z);
      my_pen:= atcArray[atc_idx].pen;
      GLSmakeToolArray(job.pens[my_pen].diameter);
      for i:= 0 to my_len-1 do begin
        my_entry:= final_array[i];
        if not my_entry.enable then
          continue;
        if length(my_entry.millings) = 0 then
          continue;
        atc_from_pens:= job.pens[my_entry.pen].atc;
        if atc_from_pens <> atc_idx then
          continue;
        if isCancelled then
          exit;  // "finally" wird trotzdem ausgeführt!
        LEDbusy.Checked:= true;
        spindle_on_off(true);
        run_path(my_entry); // Alle Pfade abarbeiten
        Memo1.lines.add('Path done.');
      end;

      if (not isCancelled) and CheckToolChange.checked then begin
// Werkzeugwechel
        spindle_on_off(false);
        SendSingleCommandStr('G0 G53 Z-1'); // move Z up
        GLSclearPathNodes;
        if job.toolchange_pause and
           job.use_fixed_probe  and
           job.atc_enabled then begin
// automatischer Werkzeugwechsel, zum Ende erstes Werkzeug wiederaufnehmen
          if atc_idx >= my_used_tools_count then
            ChangeATCtool(atc_idx, 1, true) // zurück zum ersten Tool
          else
            ChangeATCtool(atc_idx, atc_idx + 1, true); // nächstes Tool der Liste
        end else begin
// manueller Werkzeugwechsel, zum Ende Werkzeug belassen
          if atc_idx < my_used_tools_count then
            if not ManualToolchange(atc_idx, atc_idx + 1, true) then // OK für nächstes Tool?
              exit;
        end;
        if atc_idx < my_used_tools_count then begin
        // noch nicht fertig, Spindel starten und Ausgangsposition
          LEDbusy.Checked:= true;
          spindle_on_off(true);
          SendSingleCommandStr('G0 G53 Z0');
        end;
      end;
    end; // for loop

    Memo1.lines.add('Blocks done.');
    WaitForIdle;
// grbl_millpath und grbl_drillpath enden mit job.z_penup, deshalb:
    SendSingleCommandStr('G0 G53 Z-1'); // move Z up
    spindle_on_off(false);

    if CheckEndPark.Checked then
      MoveToPos('park', job.park_x, job.park_y, job.park_z, false, false)
//      BtnMoveParkClick(nil)
    else begin
      SendSingleCommandStr('G0 X0 Y0'); // Work Zero
    end;
  finally
    SgATC.enabled:= true;
    ExitJobMsg(true);
  end;
end;

procedure TForm1.RunGcode(Sender: TObject);
// G-Code-Datei abspielen
var
  my_ReadFile: TextFile;
  my_line: String;

begin
  DefaultsGridListToJob;
  PenGridListToJob;
  if machine_busy_msg then
    exit;
  try
    if isSimActive then
      ResetSimulation;
    BtnRunjob.tag:= 1;
    Memo1.lines.Clear;
    Memo1.lines.add('G-Code file run started.');
    mdelay(grbl_delay_long);
    if Form4.ComboBoxSimType.ItemIndex = 1 then
      Form4.ComboBoxSimType.ItemIndex:= 2;
    Form4.GLLinesPath.Visible:= Form4.CheckToolpathVisible.Checked;
    Form4.GLDummyCubeTool.visible:= true;
    ForceToolPositions(grbl_wpos.x, grbl_wpos.y, grbl_wpos.z);
    GLSneedsRedrawTimeout:= 1;
    GLSneedsATCupdateTimeout:= 1;
    GLSsetToolDia(ComboBoxGdia.ItemIndex+1, ComboBoxGTip.ItemIndex); // Werkzeugform und Farbe
    GLSsetToolColor(clgray);

    OpenFileDialog.FilterIndex:= 2;
    if not OpenFileDialog.Execute then
      exit;
    my_line:='';
    FileMode := fmOpenRead;
    AssignFile(my_ReadFile, OpenFileDialog.FileName);
    CurrentPen:= 0;
    PendingAction:= lift;
    Reset(my_ReadFile);
    while not Eof(my_ReadFile) do begin
      if isCancelled then begin
        CloseFile(my_ReadFile);
        exit;
      end;
      LEDbusy.Checked:= true;
      Readln(my_ReadFile, my_line);
      grbl_sendlist.add(my_line);
      if grbl_sendlist.Count > 100 then
        SendListToGrbl;
    end;
    CloseFile(my_ReadFile);
    SendListToGrbl;
    WaitForIdle;
    SendSingleCommandStr('G0 G53 Z-1'); // move Z up
    spindle_on_off(false);

    if not isCancelled then begin
      // Immer abschließende Aktion wenn ATC enabled
      if CheckEndPark.Checked and HomingPerformed then
        MoveToPos('park', job.park_x, job.park_y, job.park_z, false, false)
//        BtnMoveParkClick(nil)
      else begin
        SendSingleCommandStr('G0 X0 Y0'); // Work Zero
      end;
    end;
  finally
    ExitJobMsg(true);
  end;
end;

procedure TForm1.BtnMoveToolChangeClick(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  spindle_on_off(false);
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  Form1.Memo1.lines.add('Move to manual tool change position');
  grbl_moveXY(job.toolchange_x, job.toolchange_y, true);
  grbl_moveZ(job.toolchange_z, true);
// manuelle Wechselposition
  SendListToGrbl;

// vorerst nicht nötig, da erstes Tool ohnehin immer TLC'd wird:
{
  if job.toolchange_pause and job.use_fixed_probe then begin
    if MessageDlg('Manual Tool Change'
    + #13 + 'For this job, load spindle with:'
    + #13 + #13 + pen_description(atcArray[FirstToolUsed].pen)
    + #13 + #13 + 'Click OK when tool has been changed'
    + #13 + 'to proceed with TLC probing. If using ATC,'
    + #13 + 'first slot (#1) must be empty.',
    mtConfirmation, mbOKCancel, 0) = mrCancel then
      exit;
    if DoTLCandConfirm(false, 1) then
      Form1.Memo1.lines.add('Tool changed, new Tool Delta Z applied');
  end else
}
    if MessageDlg('Manual Tool Change'
    + #13 + 'For this job, load spindle with:'
    + #13 + #13 + pen_description(atcArray[ToolInSpindle].pen)
    + #13 + #13 + 'Click OK when tool has been changed.',
    mtConfirmation, mbOKCancel, 0) = mrCancel then
      exit;
  if Form1.Show3DPreview1.checked then
    GLSupdateATC;
  InvalidateTLCs;
  CancelG43offset;
  WorkZeroZdone:= false;
end;

procedure TForm1.BtnProbeZAssistentClick(Sender: TObject);
begin
  if machine_busy_msg or
     (MessageDlg('Calibrate tool length at last position?', mtConfirmation, mbOKCancel, 0) = mrCancel) then
    exit;

  MoveToPos('Z-Probe position', PosProbeZ.X, PosProbeZ.y, 0, false, false);

  BtnZcontactClick(Sender);
end;
