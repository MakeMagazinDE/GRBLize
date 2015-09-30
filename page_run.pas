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

// #############################################################################
// ######################## R U N  T A B  B U T T O N S ########################
// #############################################################################


procedure TForm1.BtnHomeCycleClick(Sender: TObject);
begin
  CancelWait:= false;
  CancelGrbl:= false;
  drawing_tool_down:= false;
  DisableButtons;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('// HOME CYCLE');
  grbl_addStr('$h');
  grbl_offsXY(0,0);
  grbl_offsZ(0);
  grbl_addStr('G92 Z'+FloatToStrDot(job.z_gauge));
  SendGrblAndWaitForIdle;
  HomingPerformed:= true;
  EnableRunButtons;
end;


procedure TForm1.BtnMoveWorkZeroClick(Sender: TObject);
begin
  CancelWait:= false;
  CancelGrbl:= false;
  drawing_tool_down:= false;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('// MOVE TOOL TO PART ZERO');
  grbl_addStr('M5');
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  grbl_moveXY(0,0, false);
  grbl_moveZ(job.z_penlift, false);
  SendGrblAndWaitForIdle;
  if Form1.Show3DPreview1.Checked then
    SimMillAtPos(0, 0, job.z_penlift, sim_dia, false, true);
  if Form1.ShowDrawing1.Checked then
    SetDrawingToolPosMM(0, 0, job.z_penlift);
end;

procedure StartJogAction(sender: TObject; tag: Integer);
var dx, dy, dz, x, y, z: Double;
  my_str: string;
  first_loop_done: Boolean;
  my_delay: Integer;
begin
  //DisableTimerStatus;
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
  x:= grbl_wpos.X; // derzeitige Position
  y:= grbl_wpos.Y;
  z:= grbl_wpos.Z;
  first_loop_done:= false;
  my_delay:= (12 - Form1.TrackBarRepeatRate.Position) * 20;
  repeat
    x:= x + dx;
    y:= y + dy;
    z:= z + dz;
    if dx <> 0 then
      my_str:= 'G0 X' + FloatToStrDot(x);
    if dy <> 0 then
      my_str:= 'G0 Y' + FloatToStrDot(y);
    if dz <> 0 then
      my_str:= 'G0 Z' + FloatToStrDot(z);
    if not Form1.CheckBoxSim.checked then begin
      grbl_sendStr(my_str + #13, true);
    end;
    Form1.Memo1.lines.add(my_str + ' // JOG');
    if not first_loop_done then
      mdelay(300)
    else
      mdelay(my_delay);
    first_loop_done:= true;
    SetDrawingToolPosMM(x, y, grbl_wpos.Z);
    SetSimPosColorMM(x, y, grbl_wpos.z, clGray);
  until MouseJogAction = False; // stop when cancelled
  grbl_wpos.X:= x;
  grbl_wpos.Y:= y;
end;


procedure TForm1.BitBtnJogMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  StartJogAction(Sender, (Sender as TBitBtn).Tag);
end;

procedure TForm1.BitBtnJogMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  MouseJogAction := False; // cancel notification
end;

procedure TForm1.BtnMoveParkClick(Sender: TObject);
begin
  CancelWait:= false;
  CancelGrbl:= false;
  drawing_tool_down:= false;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('// MOVE TO PARK POSITION');
  grbl_addStr('M5');
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  grbl_moveXY(job.park_x, job.park_y, true);
  grbl_moveZ(job.park_z, true);
  SendGrblAndWaitForIdle;
end;

procedure TForm1.BtnMoveToolChangeClick(Sender: TObject);
begin
  drawing_tool_down:= false;
  CancelWait:= false;
  CancelGrbl:= false;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('// MOVE TO TOOL CHANGE POSITION');
  grbl_addStr('M5');
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  grbl_moveXY(job.toolchange_x, job.toolchange_y, true);
  grbl_moveZ(job.toolchange_z, true);
  SendGrblAndWaitForIdle;
end;

Procedure SpindleAccelBrakeTime;
begin
  if not Form1.CheckBoxSim.checked then begin
    SendGrblAndWaitForIdle;
    mdelay(job.spindle_wait * 1000)  // Spindel-Hochlaufzeit
  end;
end;

procedure TForm1.RunJob;
// Pfade an GRBL senden
var i, my_len, p, last_pen, my_old_atc_tool, my_new_atc_tool, my_btn: Integer;
  my_entry: Tfinal;
  my_atc_x, my_atc_y: Double;
  my_str, my_list: String;
  my_has_atc: Boolean;

begin
  sim_dia:= Form1.ComboBoxGdia.ItemIndex+1;
  sim_tooltip:= Form1.ComboBoxGtip.ItemIndex;

  Form4.FormRefresh(nil);
  Memo1.lines.Clear;
  Memo1.lines.add('// RUN STARTED');
  my_len:= length(final_array);
  if my_len < 1 then
    exit;
  last_pen:= -1;
  Form1.Memo1.lines.add('');
  grbl_moveZ(0, true);
  SendGrblAndWaitForIdle;
  my_list:= '';
  my_str:= ', Mill';
  my_has_atc:= false;
  for i := 0 to SgPens.RowCount-1 do begin
    if i = 10 then
      my_str:= ', Drill';
    if job.pens[i].enable and (job.pens[i].atc <> 0) then begin
      my_list:= my_list + #13 + ('Pen/Tool #' + IntToStr(i)
        + my_str + ' Dia. '  + FloatToStr(job.pens[i].diameter)
        + 'mm at ATC #' + IntToStr(job.pens[i].atc));
      my_has_atc:= true;
    end;
  end;
  if CheckUseATC.Checked and not my_has_atc then begin
    my_btn := MessageDlg('No ATC tools found. Will disable <Use ATC> Chekbox.' +
      #13 + 'Continue?', mtError, mbOKCancel, 0);
    if my_btn = mrCancel then
      exit;
    CheckUseATC.Checked:= false;
  end else if CheckUseATC.Checked then begin
    my_btn := MessageDlg('Make sure spindle is loaded with probe/dummy tool 0, ATC slot 0 is empty' +
      #13 + 'and ATC tray is loaded with these tools:' +
      #13 + my_list, mtError, mbOKCancel, 0);
    if my_btn = mrCancel then
      exit;
  end else begin
    if CancelJob then
      exit;
    Memo1.lines.add('// SPINDLE ON');
    grbl_addStr('M3');
    Memo1.lines.add('// SPINDLE ACCEL WAIT '+ IntToStr(job.spindle_wait) + ' SEC');
    SpindleAccelBrakeTime;
 end;

  for i:= 0 to my_len-1 do begin
    if CancelJob then
      exit;
    my_entry:= final_array[i];
    if not my_entry.enable then
      continue;
    if length(my_entry.millings) = 0 then
      continue;
    if (length(my_entry.millings) > 0) and CheckPenChangePause.Checked
    and (my_entry.pen <> last_pen) and (not CancelJob) then begin
      Memo1.lines.add('');
      grbl_moveZ(0, true); // move Z up
      if last_pen = -1 then begin
        last_pen:= 0;
        Memo1.lines.add('// SPINDLE STOPPED');
      end else begin                    // bei erstem Werkzeug nicht warten
        grbl_addStr('M5');
        Memo1.lines.add('// SPINDLE BRAKE WAIT '+ IntToStr(job.spindle_wait) + ' SEC');
        SpindleAccelBrakeTime;
      end;

      my_old_atc_tool:= job.pens[last_pen].atc;
      my_new_atc_tool:= job.pens[my_entry.pen].atc;

// Zuletzt benutztes Werkzeug (oder Probe/Dummy nach Start) wieder ablegen
      Form1.Memo1.lines.add('');
      my_atc_x:= job.atc_zero_x + (my_old_atc_tool * job.atc_delta_x);
      my_atc_y:= job.atc_zero_y + (my_old_atc_tool * job.atc_delta_y);
      Memo1.lines.add('// UNLOAD TOOL #'+ IntToStr(last_pen));
      Memo1.lines.add('// ATC POSITION '+ IntToStr(my_old_atc_tool)
        + ' AT ' + FloatToStr(my_atc_x) + ',' + FloatToStr(my_atc_y));
      if CancelJob then
        exit;
      grbl_moveZ(0, true);  // move Z up
      grbl_moveXY(my_atc_x, my_atc_y, true);
      if CancelJob then
        exit;
      SendGrblAndWaitForIdle;
      if CancelJob then
        exit;
      grbl_moveZ(job.atc_pickup_z + 10, true);  // move Z down near pickup-Höhe
      grbl_addStr('M8');                // Ausblasen
      SendGrblAndWaitForIdle;
      mdelay(500);
      grbl_moveZ(0, true);     // move Z up
      SendGrblAndWaitForIdle;
      mdelay(500);

// Neues Werkzeug aufnehmen
      Form1.Memo1.lines.add('');
      my_atc_x:= job.atc_zero_x + (my_new_atc_tool * job.atc_delta_x);
      my_atc_y:= job.atc_zero_y + (my_new_atc_tool * job.atc_delta_y);
      Memo1.lines.add('// LOAD TOOL #'+ IntToStr(my_entry.pen));
      Memo1.lines.add('// ATC POSITION '+ IntToStr(my_new_atc_tool)
        + ' AT ' + FloatToStr(my_atc_x) + ',' + FloatToStr(my_atc_y));
      if CancelJob then
        exit;
      grbl_moveZ(0, true);  // move Z up
      grbl_moveXY(my_atc_x, my_atc_y, true);
      if CancelJob then
        exit;
      grbl_moveZ(job.atc_pickup_z + 20, true);  // move Z down
      grbl_moveSlowZ(job.atc_pickup_z, true);  // move Z down
      grbl_addStr('M9');                // pick up tool
      SendGrblAndWaitForIdle;
      mdelay(500);
      if CancelJob then
        exit;
      grbl_moveZ(0, true);  // move Z up
      SendGrblAndWaitForIdle;

      if CancelJob then
        exit;
      Form1.Memo1.lines.add('');
      grbl_addStr('M3');
      Memo1.lines.add('// SPINDLE ACCEL WAIT '+ IntToStr(job.spindle_wait) + ' SEC');
      SpindleAccelBrakeTime;

    end else if (length(my_entry.millings) > 0) and CheckPenChangePause.Checked
      and (my_entry.pen <> last_pen) and (not CancelJob) then begin
      Memo1.lines.add('');
      // move to tool change position
      // TO DO: Neuen Z-Wert ermöglichen
      Memo1.lines.add('// SPINDLE BRAKE WAIT '+ IntToStr(job.spindle_wait) + ' SEC');
      grbl_addStr('M5');
      SpindleAccelBrakeTime;
      if CancelJob then
        exit;
      grbl_moveZ(0, true);
      grbl_moveXY(job.toolchange_x, job.toolchange_y, true);
      if CancelJob then
        exit;
      grbl_moveZ(job.toolchange_z, true);
      Memo1.lines.add('// PEN/TOOL CHANGE');
      ShowMessage('Milling paused - Change pen/tool to '
        + #13+ FloatToStr(job.pens[my_entry.pen].diameter)+' mm when path finished'
        + #13+ 'and click OK when done. Will keep Z Zero Value.');
      Form1.Memo1.lines.add('');
      if CancelJob then
        exit;
      Memo1.lines.add('// SPINDLE ACCEL WAIT '+ IntToStr(job.spindle_wait) + ' SEC');
      grbl_addStr('M3');
      SpindleAccelBrakeTime;
      grbl_moveZ(0, true);
      SendGrblAndWaitForIdle;  // warte auf Idle wenn beendet
    end;
    last_pen:= my_entry.pen;

    // kompletten Milling- oder Drill-Pfad abfahren
    if (length(my_entry.millings) > 0) then
      for p:= 0  to length(my_entry.millings)-1 do begin
        if CancelJob then
          exit;
        Memo1.lines.add('');
        Memo1.lines.add('// RUN BLOCK '+ IntToStr(i) + ' PATH '+ IntToStr(p));
        grbl_addStr('// BITCHANGE: ' + FormatFloat('0.00', job.pens[my_entry.pen].diameter)
          + ' ' + IntToStr(job.pens[my_entry.pen].tooltip)+' '+ IntToStr(job.pens[my_entry.pen].color));
        if my_entry.shape = drillhole then
          grbl_drillpath(my_entry.millings[p], my_entry.pen, job.pens[my_entry.pen].offset)
        else
          grbl_millpath(my_entry.millings[p], my_entry.pen, job.pens[my_entry.pen].offset, my_entry.closed);
    end;
  end; // Ende der Block-Schleife

  // grbl_millpath und grbl_drillpath enden mit job.z_penup, deshalb:
  if CancelJob then
    exit;
  grbl_moveZ(0, true); // move Z up
  SendGrblAndWaitForIdle;
  // Immer abschließende Aktion wenn ATC enabled
  if (length(my_entry.millings) > 0) and CheckUseATC.Checked and (not CancelJob) then begin
    Memo1.lines.add('');
    Memo1.lines.add('// SPINDLE BRAKE WAIT '+ IntToStr(job.spindle_wait) + ' SEC');
    SpindleAccelBrakeTime;

    // Zuletzt benutztes Werkzeug wieder ablegen
    my_old_atc_tool:= job.pens[last_pen].atc;
    Form1.Memo1.lines.add('');
    my_atc_x:= job.atc_zero_x + (my_old_atc_tool * job.atc_delta_x);
    my_atc_y:= job.atc_zero_y + (my_old_atc_tool * job.atc_delta_y);
    Memo1.lines.add('// UNLOAD TOOL #'+ IntToStr(last_pen));
    Memo1.lines.add('// ATC POSITION '+ IntToStr(my_old_atc_tool)
      + ' AT ' + FloatToStr(my_atc_x) + ',' + FloatToStr(my_atc_y));
    if CancelJob then
      exit;
    grbl_moveZ(0, true);  // move Z up
    grbl_moveXY(my_atc_x, my_atc_y, true);
    SendGrblAndWaitForIdle;
    if CancelJob then
      exit;
    grbl_moveZ(job.atc_pickup_z + 10, true);  // move Z down
    grbl_addStr('M8');                // Ausblasen
    SendGrblAndWaitForIdle;
    mdelay(500);
    if CancelJob then
      exit;
    grbl_moveZ(0, true);  // move Z up
    SendGrblAndWaitForIdle;
    mdelay(500);
    if CancelJob then
      exit;

    // Probe/Dummy-Werkzeug aufnehmen
    Form1.Memo1.lines.add('');
    my_atc_x:= job.atc_zero_x;
    my_atc_y:= job.atc_zero_y;
    Memo1.lines.add('// LOAD PROBE TOOL #0');
    Memo1.lines.add('// ATC POSITION 0 AT ' + FloatToStr(my_atc_x) + ',' + FloatToStr(my_atc_y));
    if CancelJob then
      exit;
    grbl_moveZ(0, true);  // move Z up
    grbl_moveXY(my_atc_x, my_atc_y, true);
    SendGrblAndWaitForIdle;
    if CancelJob then
      exit;
    grbl_moveZ(job.atc_pickup_z + 20, true);  // move Z down
    SendGrblAndWaitForIdle;
    grbl_moveSlowZ(job.atc_pickup_z, true);  // move Z down
    grbl_addStr('M9');                // pick up tool
    SendGrblAndWaitForIdle;
    mdelay(500);
    if CancelJob then
      exit;
    grbl_moveZ(0, true);  // move Z up absolute
    SendGrblAndWaitForIdle;
  end;

  SendGrblAndWaitForIdle;
  Memo1.lines.add('// JOB END');
  if CheckEndPark.Checked and (HomingPerformed or CheckboxSim.checked) then
    BtnMoveParkClick(nil)
  else begin
    grbl_addStr('M5');
    grbl_moveXY(0,0, false);
  end;
  SendGrblAndWaitForIdle;
  Memo1.lines.add('// FINISHED');
  drawing_tool_down:= false;
end;

procedure TForm1.RunGcode;
// G-Code-Datei abspielen
var
  my_ReadFile: TextFile;
  my_line, old_line: String;
  pos0, pos1: Integer;
  new_z, z_offs: Double;
  my_Settings: TFormatSettings;

begin
  if Form4.ComboBoxSimType.ItemIndex = 1 then
    Form4.ComboBoxSimType.ItemIndex:= 2;
  SetSimToolMM(ComboBoxGdia.ItemIndex+1, ComboBoxGTip.ItemIndex, clGray); // Werkzeugform und Farbe
  Form4.FormRefresh(nil);  // Ansicht löschen

  OpenFileDialog.FilterIndex:= 2;
  if not OpenFileDialog.Execute then
    exit;
  my_line:='';
  FileMode := fmOpenRead;
  AssignFile(my_ReadFile, OpenFileDialog.FileName);
  CurrentPen:= 0;
  PendingAction:= lift;
  Reset(my_ReadFile);
  z_offs:= StrToFloatDef(EditZoffs.Text, 0);
  if z_offs <> 0 then
    Memo1.lines.add('// USING Z OFFSET' + EditZoffs.Text);
  my_Settings.Create;
  my_Settings.DecimalSeparator:= '.';
  while not Eof(my_ReadFile) do begin
    if CancelJob then
      break;
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
  end;
  CloseFile(my_ReadFile);

  Memo1.lines.add('// JOB END');
  if CheckEndPark.Checked and (HomingPerformed or CheckboxSim.checked) then
    BtnMoveParkClick(nil)
  else begin
    grbl_moveZ(0, true);  // move Z up absolute
    grbl_addStr('M5');
    grbl_moveXY(0,0, false);
  end;
  SendGrblAndWaitForIdle;
  Memo1.lines.add('// FINISHED');
  drawing_tool_down:= false;
end;

procedure TForm1.BtnRunJobClick(Sender: TObject);
begin
  Memo1.lines.clear;
  CancelWait:= false;
  CancelGrbl:= false;
  CancelJob:= false;
  CancelSim:= false;
  RunJob;
end;

procedure TForm1.BtnRunGcodeClick(Sender: TObject);
begin
  Memo1.lines.clear;
  CancelWait:= false;
  CancelGrbl:= false;
  CancelJob:= false;
  CancelSim:= false;
  RunGcode;
end;

procedure TForm1.BtnEmergencyStopClick(Sender: TObject);
var
  my_response: String;
begin
  bm_scroll.x:= 0;
  bm_scroll.y:= Form2.ClientHeight - Form2.DrawingBox.Height;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('// EMERGENCY STOP AND MACHINE RESET');
  CancelWait:= true;
  CancelGrbl:= true;
  CancelJob:= true;
  CancelSim:= true;
  while CancelGrbl or CancelJob do   // CancelGrbl wird im Timer gelöscht
    Application.ProcessMessages;
    // E-Stop ausführen
  if grbl_is_connected and (not Form1.CheckBoxSim.checked) then begin
    my_response:= grbl_sendStr(#24, true); // Ctrl-X Reset sofort senden
    grbl_receiveStr(100);
    Form1.Memo1.lines.add('// CTRL-X RESET: ' + my_response);
    grbl_receiveStr(100);
    Form1.Memo1.lines.add(' // ' + my_response);
    SendGrblAndWaitForIdle; // bitte nicht unterbrechen
    showmessage('EMERGENCY STOP. Steps missed - please run'
      + #13 + 'Home Cycle to release ALARM LOCK.');
    EnableNotHomedButtons;
  end else
    Form1.Memo1.lines.add('// CTRL-X RESET: #Device not open');
  HomingPerformed:= false;
  SendGrblAndWaitForIdle;
  drawing_tool_down:= false;
end;

procedure TForm1.BtnStopClick(Sender: TObject);
begin
  bm_scroll.x:= 0;
  bm_scroll.y:= Form2.ClientHeight - Form2.DrawingBox.Height;
  drawing_tool_down:= false;
  if Show3DPreview1.Checked then
    Form4.FormRefresh(Sender);
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('// CANCEL PROCESS, WAIT FOR MACHINE STOP');
  CancelWait:= false;
  CancelGrbl:= true;
  CancelJob:= true;
  CancelSim:= true;
  // neue Z-Höhe wird in Timer bei CancelGrbl gesetzt
  Form1.Memo1.lines.add('// MACHINE STOPPED AT Z = ' + FormatFloat('0.00', job.z_penlift) + ' mm');
end;

procedure TForm1.BtnZeroXClick(Sender: TObject);
begin
  CancelWait:= false;
  CancelGrbl:= false;
  CancelSim:= false;
  drawing_tool_down:= false;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('// SET X ZERO');
  grbl_addStr('G92 X0');
  SendGrblAndWaitForIdle;
end;

procedure TForm1.BtnZeroYClick(Sender: TObject);
begin
  CancelWait:= false;
  CancelGrbl:= false;
  CancelSim:= false;
  drawing_tool_down:= false;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('// SET Y ZERO');
  grbl_addStr('G92 Y0');
  SendGrblAndWaitForIdle;
end;

procedure TForm1.BtnZeroZClick(Sender: TObject);
begin
  CancelWait:= false;
  CancelGrbl:= false;
  CancelSim:= false;
  drawing_tool_down:= false;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('// SET Z ZERO');
  grbl_addStr('G92 Z'+FloatToStrDot(job.z_gauge));
  SendGrblAndWaitForIdle;
end;
