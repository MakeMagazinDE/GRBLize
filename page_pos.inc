// #############################################################################
// ################### Page P o s i t i o n ####################################
// #############################################################################

procedure TForm1.MoveToPos(S: String; x, y, z: Double; Set0, CAM: boolean);
begin
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move to ' + S );
  spindle_on_off(false);
  drawing_tool_down:= false;
  if CAM then begin
    x:= x - job.cam_x;
    y:= y - job.cam_y;
  end;

  // probe if position is on the table
  if (x < 0) or (x >  job.table_x) or
     (y < 0) or (y >  job.table_y) or
     (z > 0) or (z < -job.table_z) then begin
    Form1.Memo1.lines.add('Error: Position outside the table!');
    MessageDlg('Position outside the table.' + #13 + 'NO MOVE!', mtError, [mbOK], 0);
  end;

  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  grbl_moveXY(x, y, true);
  grbl_moveZ(z, true);
  SendListToGrbl;
  mdelay(250);
  NeedsRedraw:= true;
  if Set0 then
    SetZero(3);
end;

procedure TForm1.SetDefaultToPos(s: String; var x,y,z: Double; idx: integer; CAM: boolean);
var my_btn: Integer;
begin
  if isSimActive then
    exit;
  my_btn:= MessageDlg('This will set ' + S + ' postion'
    + #13 + ' to current machine position'
    + #13 + 'in GRBLize Application defaults. Proceed?', mtConfirmation, mbOKCancel, 0);
  if my_btn = mrCancel then
    exit;
  x:= grbl_mpos.x; y:= grbl_mpos.y; z:= grbl_mpos.z;
  if CAM then begin
    x:= x - job.cam_x;
    y:= y - job.cam_y;
  end;

  // probe if position is on the table
  if (x < 0) or (x > job.table_x) or
     (y < 0) or (y > job.table_y) or
     (z > 0) or (z > job.table_z) then begin
    Form1.Memo1.lines.add('Error: Position outside the table!');
    MessageDlg('Position outside the table.' + #13 + 'NOT SET!', mtError, [mbOK], 0);
  end;

  with Form1.SgAppDefaults do begin
    Cells[1,idx]  := FormatFloat('0.00', x);
    Cells[1,idx+1]:= FormatFloat('0.00', y);
    Cells[1,idx+2]:= FormatFloat('0.00', z);
  end;
  SaveIniFile;
end;

procedure TForm1.BtnMoveXYzeroClick(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  Memo1.lines.add('');
  if WorkZeroXDone and WorkZeroYDone then begin
    LEDbusy.Checked:= true;
    Memo1.lines.add('Move tool to part XY zero');
    spindle_on_off(false);
    drawing_tool_down:= false;
    // nur anheben, wenn X/Y nicht in Nullpunkt-Nähe
    if (CompareValue(0, grbl_wpos.x, 1) <> 0) or (CompareValue(0, grbl_wpos.x, 1) <> 0) then
      grbl_moveZ(0, true);
    grbl_moveXY(0,0, false);
    SendListToGrbl;
  end else begin
    Form1.Memo1.lines.add('WARNING: XY Zero not set!');
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
  end;
  NeedsRedraw:= true;
end;

procedure TForm1.BtnMoveZzeroClick(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  Memo1.lines.add('');
  if WorkZeroAllDone then begin
    LEDbusy.Checked:= true;
    Memo1.lines.add('Move tool to part Z zero');
    Memo1.lines.add('Pen Lift value ' + FormatFloat('00.00', job.z_penlift) + ' mm above part');
    spindle_on_off(false);
    drawing_tool_down:= false;
    grbl_moveZ(job.z_penlift, false);
  end else begin
    Form1.Memo1.lines.add('WARNING: Z Zero not set!');
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
  end;
  SendListToGrbl;
  NeedsRedraw:= true;
end;

procedure TForm1.BtnMoveCamZeroClick(Sender: TObject);
begin
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move cam to part zero');

  if WorkZeroXdone and WorkZeroYdone then begin
    grbl_moveZ(0, true);  // move Z up absolute
    grbl_moveXY(-job.cam_x,-job.cam_y, false);
    grbl_moveZ(job.cam_z_abs, true);
    SendListToGrbl;
  end else begin
    Form1.Memo1.lines.add('WARNING: X,Y Zero not set!');
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
  end;
end;

procedure TForm1.BtnCamAtZeroClick(Sender: TObject);
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Offset cam to part zero');

  grbl_offsXY(-job.cam_x, -job.cam_y);
  SendListToGrbl;

  WorkZero.X:= grbl_mpos.X + job.cam_x;
  Jog.X:= WorkZero.X;
  WorkZero.Y:= grbl_mpos.Y + job.cam_y;
  Jog.Y:= WorkZero.Y;
  WorkZeroXdone:= true;
  WorkZeroYdone:= true;
  NeedsRedraw:= true;
end;

procedure TForm1.BtnMoveToolPointClick(Sender: TObject);
var x,y: Double;
begin
  Form1.Memo1.lines.add('');
  if HilitePoint >= 0 then begin
    Form1.Memo1.lines.add('Move tool to point');
    hilite_to(x,y);
  end else begin
    Form1.Memo1.lines.add('Move tool to center');
    hilite_center_to(x,y);
  end;

  if WorkZeroXdone and WorkZeroYdone then begin
    grbl_moveZ(0, true);  // move Z up absolute
    grbl_moveXY(x, y, false);
    if WorkZeroAllDone then begin
      grbl_moveZ(job.z_penlift, false);
    end else begin
      Form1.Memo1.lines.add('WARNING: Z Zero not set!');
      PlaySound('SYSTEMHAND', 0, SND_ASYNC);
    end;
    SendListToGrbl;
  end else begin
    Form1.Memo1.lines.add('WARNING: X,Y Zero not set!');
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
  end;

  SendListToGrbl;
end;

procedure TForm1.BtnMoveCamPointClick(Sender: TObject);
var x,y: Double;
begin
  if (HilitePoint < 0) and (HiliteBlock < 0) then
    exit;
  Form1.Memo1.lines.add('');
  if HilitePoint >= 0 then begin
    Form1.Memo1.lines.add('Move cam to point');
    hilite_to(x,y);
  end else begin
    Form1.Memo1.lines.add('Move cam to center');
    hilite_center_to(x, y);
  end;
  x:= x - job.cam_x;
  y:= y - job.cam_y;

  if WorkZeroXdone and WorkZeroYdone then begin
    grbl_moveZ(0, true);  // move Z up
    grbl_moveXY(x, y, false);
    grbl_moveZ(job.cam_z_abs, true);
    SendListToGrbl;
  end else begin
    Form1.Memo1.lines.add('WARNING: X,Y Zero not set!');
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
  end;
end;

procedure TForm1.BtnCamAtPointClick(Sender: TObject);
var x,y: Double;
begin
  if (HilitePoint < 0) and (HiliteBlock < 0) then
    exit;
  Form1.Memo1.lines.add('');
  if HilitePoint >= 0 then begin
    Form1.Memo1.lines.add('Offset cam to point');
    hilite_to(x,y);
  end else begin
    Form1.Memo1.lines.add('Offset cam to center');
    hilite_center_to(x,y);
  end;
  x:= x - job.cam_x;
  y:= y - job.cam_y;

  grbl_offsXY(x, y);
  SendListToGrbl;

  WorkZero.X:= grbl_mpos.X - x;
  Jog.X:= WorkZero.X;
  WorkZero.Y:= grbl_mpos.Y - y;
  Jog.Y:= WorkZero.Y;
  WorkZeroXdone:= true;
  WorkZeroYdone:= true;
  NeedsRedraw:= true;
end;

procedure TForm1.ContinueJogging;
var Feed: Integer;
    Dist: Double;
    S:    String;
begin
  if JogDelay < 0 then
//  if (JogDirection.X = 0) and (JogDirection.Y = 0) and (JogDirection.Z = 0) then
    exit;                                                     // nothing to move

  if (abs(JogDirection.X)>5) or
     (abs(JogDirection.Y)>5) or
     (abs(JogDirection.Z)>5) then
    Feed:= get_AppDefaults_int(37)                              // JogSpeed Fast
  else
    if (abs(JogDirection.X)>0.5) or
       (abs(JogDirection.Y)>0.5) or
       (abs(JogDirection.Z)>0.5) then
      Feed:= get_AppDefaults_int(38)                            // JogSpeed Slow
    else
      Feed:= get_AppDefaults_int(38) div 5;

// - using of relativ coordinates for jogging
// - movement will be limit by the soft limits of the mill
// - for continue movement this routine should be called by the timer
//   TimerStatus with an interval of about 50ms. So the planning buffer of GRBL
//   will be filled with jogging commands using only small distances
  Dist:= 3*TimerStatus.Interval * Feed/60/1000;  // max. movement in timerinterval

  S:= '$J=G91 ';

  if JogDirection.X < 0 then
    S:= S + ' X-' + FloatToStrDot(Dist);
  if JogDirection.X > 0 then
    S:= S + ' X'  + FloatToStrDot(Dist);
  if JogDirection.Y < 0 then
    S:= S + ' Y-' + FloatToStrDot(Dist);
  if JogDirection.Y > 0 then
    S:= S + ' Y' + FloatToStrDot(Dist);
  if JogDirection.Z < 0 then
    S:= S + ' Z-' + FloatToStrDot(Dist);
  if JogDirection.Z > 0 then
    S:= S + ' Z' + FloatToStrDot(Dist);

  if length(S) > 7 then                     // nur wenn sich die Position ändert
    SendSingleCommandStr(S + ' F'+ IntToStr(Feed));
{
  S:= '$J=G53 ';
  if get_AppDefaults_bool(45) then begin
  // Positive Machine Space (XY)
    if JogDirection.X > 0 then
      S:= S + ' X' + FloatToStrDot(job.table_x);
    if JogDirection.X < 0 then
      S:= S + ' X1';

    if JogDirection.Y > 0 then
      S:= S + ' Y' + FloatToStrDot(job.table_y);
    if JogDirection.Y < 0 then
      S:= S + ' Y1';

    if length(s) > 6 then
      S:= S + ' F'+ IntToStr(feed)
    else begin
      if JogDirection.Z > 0 then // Move Z up
        S:= S + ' Z-1 F'+ IntToStr(feed div 3);
      if JogDirection.Z < 0 then
        S:= S + ' Z' + FloatToStrDot(-job.table_z) + 'F'+ IntToStr(feed div 3);
    end;
  end else begin
  // Standard CNC: Negative machine space (XYZ)
    if JogDirection.X > 0 then
      S:= S + ' X-1';
    if JogDirection.X < 0 then
      S:= S + ' X' + FloatToStrDot(1-job.table_x);

    if JogDirection.Y > 0 then
      S:= S + ' Y-1';
    if JogDirection.Y < 0 then
      S:= S + ' Y' + FloatToStrDot(1-job.table_y);

    if length(s) > 6 then
      S:= S + ' F'+ IntToStr(feed)
    else begin
      if JogDirection.Z > 0 then // Move Z up
        S:= S + ' Z-1 F'+ IntToStr(feed div 3);
      if JogDirection.Z < 0 then
        S:= S + ' Z' + FloatToStrDot(1-job.table_z) + 'F'+ IntToStr(feed div 3);
    end;
  end;

  if length(S) > 6 then                 // nur wenn sich die Position ändert
    SendSingleCommandStr(S);
}//==> Warten auf OK!!!!!!!!!
  NeedsRedraw:= true;
end;

procedure TForm1.StepJogging;
var S:             String;
    PositiveTable: boolean;
begin
  if JogDelay < 0 then
//  if (JogDirection.X = 0) and (JogDirection.Y = 0) and (JogDirection.Z = 0) then
    exit;                                                     // nothing to move

  WaitForIdle;

  PositiveTable := true;       // prove coordinate system (positive or negative)
  if MachineOptions.NewGrblVersion then
    PositiveTable:= get_AppDefaults_bool(45);

  Jog.X:= grbl_mpos.X + JogDirection.X;                // calculate new position
  Jog.Y:= grbl_mpos.Y + JogDirection.Y;
  Jog.Z:= grbl_mpos.Z + JogDirection.Z;

  if PositiveTable then begin                        // begrenzen auf Tischgröße
    if Jog.X < 0             then Jog.X:= 0;
    if Jog.X > job.table_x   then Jog.X:= job.table_x;
    if Jog.Y < 0             then Jog.Y:= 0;
    if Jog.Y > job.table_y   then Jog.Y:= job.table_y;
    if Jog.Z > -1            then Jog.Z:= -1;
    if Jog.Z < 1-job.table_z then Jog.Z:= 1-job.table_z;
  end else begin
    if Jog.X > -1            then Jog.X:= -1;
    if Jog.X < 1-job.table_x then Jog.X:= 1-job.table_x;
    if Jog.Y > -1            then Jog.Y:= -1;
    if Jog.Y < 1-job.table_y then Jog.Y:= 1-job.table_y;
    if Jog.Z > -1            then Jog.Z:= -1;
    if Jog.Z < 1-job.table_z then Jog.Z:= 1-job.table_z;
  end;

  S:= 'G0 G53';
  if Jog.X <> grbl_mpos.X then            // nur wenn sich die X-Position ändert
    S:= S + ' X' + FloatToStrDot(Jog.X);
  if Jog.Y <> grbl_mpos.Y then            // nur wenn sich die Y-Position ändert
    S:= S + ' Y' + FloatToStrDot(Jog.Y);
  if Jog.Z <> grbl_mpos.Z then            // nur wenn sich die Z-Position ändert
    S:= S + ' Z' + FloatToStrDot(Jog.Z);

  if length(S) > 6 then                     // nur wenn sich die Position ändert
    SendSingleCommandStr(S);

  NeedsRedraw:= true;
end;

procedure TForm1.ResetJogging;
begin
  JogDelay:= -3;      // disable jogging, wait 2 tick before accept new requests
  JogDirection.X := 0;                                        // reset direction
  JogDirection.Y := 0;
  JogDirection.Z := 0;
  grbl_sendRealTimeCmd(#$85);                          // cancel jogging on mill
  mdelay(50);
  grbl_sendRealTimeCmd(#$85);                  // for safety, cancel second time
end;

procedure TForm1.BitBtnJogMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if isSimActive or (JogDelay <> -1) then
    exit;
//  ResetJogging;
  case (Sender as TBitBtn).tag of                         // Welcher Jog-Button?
    0:  begin                      JogDirection.Y:=  1; end;             // Nord
    1:  begin JogDirection.X:=  1; JogDirection.Y:=  1; end;          // NordOst
    2:  begin JogDirection.X:=  1;                      end;              // Ost
    3:  begin JogDirection.X:=  1; JogDirection.Y:= -1; end;           // Südost
    4:  begin                      JogDirection.Y:= -1; end;              // Süd
    5:  begin JogDirection.X:= -1; JogDirection.Y:= -1; end;          // SüdWest
    6:  begin JogDirection.X:= -1;                      end;             // West
    7:  begin JogDirection.X:= -1; JogDirection.Y:=  1; end;         // NordWest
    10: begin JogDirection.Z:=  1;                      end;              // Auf
    11: begin JogDirection.Z:= -1;                      end;               // Ab
    20: begin JogDistance:=1;    LabelJogDistance.Caption:= '0.1'; exit end;
    21: begin JogDistance:=10;   LabelJogDistance.Caption:= '1';   exit end;
    22: begin JogDistance:=100;  LabelJogDistance.Caption:= '10';  exit end;
    23: begin JogDistance:=1000; LabelJogDistance.Caption:= '100'; exit end;
  end;

  JogDirection.X:= JogDirection.X * JogDistance /10;
  JogDirection.Y:= JogDirection.Y * JogDistance /10;
  if JogDistance > 100          // limit moving in Z direction for safety reason
    then JogDirection.Z:= JogDirection.Z * 100
    else JogDirection.Z:= JogDirection.Z * JogDistance /10;

  JogDelay:= c_JogDelay;                          // delay in TimerStatus-Events
end;

procedure TForm1.BitBtnJogMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ResetJogging;
end;

procedure TForm1.BtnCntrMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if MouseDownStart = 0 then
    MouseDownStart:= MillisecondOfTheYear(Now);
end;

procedure TForm1.BtnCntrMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var D: int64;
begin
      // D: time [ms] of pressed mouse button, will be 0 in case of touch screen
  D:= MillisecondOfTheYear(Now) - MouseDownStart;
  MouseDownStart:= 0;

  if not fCamActivated then begin
    if (Button = mbLeft) and (D < 300) then             // move tool to position
      case (Sender as TSpeedButton).tag of
        0: MoveToPos('park position', job.park_x, job.park_y, job.park_z, false, false);
        1: MoveToPos('fix1 position', job.fix1_x, job.fix1_y, job.fix1_z, true,  false);
        2: MoveToPos('fix2 position', job.fix2_x, job.fix2_y, job.fix2_z, true,  false);
        3: BtnMoveToolPointClick(Sender);
        4: MoveToPos('job center', WorkZero.X+final_bounds_mm.mid.x, WorkZero.Y+final_bounds_mm.mid.y, 0, false, false);
        5: BtnZcontactClick(Sender);
        6: BtnMoveXYzeroClick(Sender);
        7: BtnMoveZzeroClick(Sender);
        //BtnMoveToolChangeClick(Sender);
      end;

    if (Button = mbRight) or (D > 300) then        // set value to tool position
      case (Sender as TSpeedButton).tag of
        0: SetDefaultToPos('PARK',      job.park_x, job.park_y, job.park_z, 6,  false);
        1: SetDefaultToPos('FIXTURE 1', job.fix1_x, job.fix1_y, job.fix1_z, 29, false);
        2: SetDefaultToPos('FIXTURE 2', job.fix2_x, job.fix2_y, job.fix2_z, 32, false);
        6: begin BtnZeroXClick(Sender); BtnZeroYClick(Sender) end;
        7: BtnZeroZClick(Sender);
        //SetDefaultToPos('ToolChange', job.toolchange_x,job.toolchange_y,job.toolchange_z, 2, false);
      end;

  end else begin
    if (Button = mbLeft) and (D < 300) then              // move CAM to position
      case (Sender as TSpeedButton).tag of
        0: MoveToPos('park', job.park_x, job.park_y, job.park_z, false, true);
        1: MoveToPos('fix1', job.fix1_x, job.fix1_y, job.fix1_z, true,  true);
        2: MoveToPos('fix2', job.fix2_x, job.fix2_y, job.fix2_z, true,  true);
        3: BtnMoveCamPointClick(Sender);
        4: MoveToPos('job center', WorkZero.X+final_bounds_mm.mid.x, WorkZero.Y+final_bounds_mm.mid.y, 0, false, false);
        5: BtnZcontactClick(Sender);
        6: BtnMoveCamZeroClick(Sender);
      end;

    if (Button = mbRight) or (D > 300) then         // set value to CAM position
      case (Sender as TSpeedButton).tag of
        0: SetDefaultToPos('PARK',      job.park_x, job.park_y, job.park_z, 6,  true);
        1: SetDefaultToPos('FIXTURE 1', job.fix1_x, job.fix1_y, job.fix1_z, 29, true);
        2: SetDefaultToPos('FIXTURE 2', job.fix2_x, job.fix2_y, job.fix2_z, 32, true);
        3: if HilitePoint >= 0 then BtnCamAtPointClick(Sender);
        6: BtnCamAtZeroClick(Sender);
        7: BtnZeroZClick(Sender);
      end;
  end;
end;

procedure TForm1.OverlayColorClick(Sender: TObject);
begin
  ColorDialog1.Color:= OverlayColor.Color;
  if not ColorDialog1.Execute then Exit;
  OverlayColor.Color:= ColorDialog1.Color;
  overlay_color:= OverlayColor.Color;
end;

procedure TForm1.RadioGroupCamClick(Sender: TObject);
begin
  if fCamPresent then begin
    CamIsOn:= RadioGroupCam.ItemIndex = 1;
    SwitchCam(CamIsOn)
  end else begin
    RadioGroupCam.ItemIndex:= 0;
  end;
  Repaint;
end;

procedure TForm1.OnNewVideoFrame(Sender : TObject; Width, Height: integer; DataPtr: pointer);
var
  r : integer;
  bm_center_x, bm_center_y: Integer;
begin
  inc(FrameCounter);
  // Retreive latest video image
  if not fCamActivated then
    exit;
  fVideoImage.GetBitmap(fVideoBitmap);
  with fVideoBitmap do begin
    // Paint a crosshair onto video image
    bm_center_x:= VideoBox.width div 2;
    bm_center_y:= VideoBox.height div 2;
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Width   := 1;
    Canvas.Pen.Color:= overlay_color;
    Canvas.moveto(0, bm_center_y);
    Canvas.lineto(Width,  bm_center_y);
    Canvas.moveto(bm_center_x, 0);
    Canvas.lineto(bm_center_x, Height);
    r := (VideoBox.height * TrackBar1.Position div 256);
    Canvas.ellipse(bm_center_x -r, bm_center_y -r,
        bm_center_x +r, bm_center_y +r);
    VideoBox.Canvas.Draw(0, 0, fVideoBitmap);
  end;
end;

procedure TForm1.SwitchCam(SwitchOn: boolean);
begin
  if fCamPresent and (SwitchOn <> fCamActivated) then begin
    if SwitchOn then begin
      Label43.Caption:='    Initializing Webcam...';
      LabelMoveTo.Caption:= 'Move CAM to...';
      Application.ProcessMessages;
      fVideoImage.VideoStart(DeviceList[0]);
    end else begin
      Label43.Caption:='  Webcam/Video Device off';
      LabelMoveTo.Caption:= 'Move Tool to...';
      fVideoImage.VideoStop;
      TabSheetPos.Refresh;
    end;
    fCamActivated := SwitchOn;
  end;
end;

procedure TForm1.BtnZcontactClick(Sender: TObject);
// Werkstück-Probekontakt anfahren. Tool muss über Kontakt sein
var my_dlg_result: integer;
begin
  WaitForIdle;
  if (CompareValue(final_bounds_mm.mid.x, grbl_wpos.X, 10) <> 0)
  or (CompareValue(final_bounds_mm.mid.y, grbl_wpos.y, 10) <> 0)
  or (grbl_mpos.z < -20) then
  // Nachfragen, falls nicht vorher Center Part angeklickt
    my_dlg_result:= MessageDlg('Ready to probe Z from current position.'
      +#13+'Is tool placed above Z floating probe sensor?', mtConfirmation, mbYesNo, 0)
  else
   my_dlg_result:= mrYes;

  if my_dlg_result = mrYes then begin
    LEDbusy.Checked:= true;
    Memo1.lines.add('');
    Memo1.lines.add('Probe tool on part (floating probe), will set Z to ');
    Memo1.lines.add('Z Gauge value ' + FormatFloat('00.00', job.probe_z_gauge) + ' mm above part');

    PosProbeZ.X:= grbl_wpos.x;                         // save probe coordinates
    PosProbeZ.Y:= grbl_wpos.y;

    if isSimActive then
      ResetSimulation;

    InvalidateTLCs;
    CancelG43offset;
    MposOnPartGauge:= probe_z;
    if MposOnPartGauge = 0 then begin
      ResetToolflags;
      Memo1.lines.add('WARNING: Z height invalid.');
      PlaySound('SYSTEMHAND', 0, SND_ASYNC);
    end else begin
      WorkZeroZdone:= true;
      WorkZero.Z:= MposOnPartGauge - job.probe_z_gauge;
      Jog.Z:= WorkZero.Z;
      DisableStatus;
      SendReceiveAndDwell('G0 G53 Z0' + #13);                       // Ganz oben
               // WorkZero ist negativ. Wird sin um -Workzero über dem Werkstück
      grbl_SendStr('G92 Z'+FloatToStrDot(-WorkZero.Z) + #13, true);
      EnableStatus;
// vorerst nicht nötig, da erstes Tool ohnehin immer TLC'd wird:
{
      if CheckPartProbeZ.Checked then
        DoTLCandConfirm(true, 1);  // ist erstes Werkzeug!
}
    end;
    NeedsRedraw:= true;
    sgATC.Row:= ToolInSpindle;
    UpdateATC;
  end;
end;

// #############################################################################
// #################### R E F E R E N C E  B U T T O N S #######################
// #############################################################################

procedure TForm1.SetZero(axes: integer);
begin
  WaitForIdle;
  HandleZeroRequest(axes);
end;

procedure TForm1.BtnZeroXClick(Sender: TObject);
begin
  SetZero(1);
end;

procedure TForm1.BtnZeroYClick(Sender: TObject);
begin
  SetZero(2);
end;

procedure TForm1.BtnZeroZClick(Sender: TObject);
// manuelle Z-Höhe mit Messklotz
begin
  SetZero(4);
// vorerst nicht nötig, da erstes Tool ohnehin immer TLC'd wird:
{
  if CheckPartProbeZ.Checked then
    DoTLCandConfirm(true, 1);
}
  if isSimActive then
    ResetSimulation;
end;

procedure TForm1.BtnZeroCClick(Sender: TObject);
begin
  SetZero(8);
end;

procedure TForm1.BtnZeroAllClick(Sender: TObject);
begin
  SetZero(15);
end;

