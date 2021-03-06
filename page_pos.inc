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
var my_btn    : Integer;
    xt, yt, zt: Double;
begin
  if isSimActive then exit;

  xt:= grbl_mpos.x; yt:= grbl_mpos.y; zt:= grbl_mpos.z;
  if CAM then begin
    xt:= xt + job.cam_x;
    yt:= yt + job.cam_y;
  end;

  // probe if position is on the table
  if (xt < 0) or (xt > job.table_x) or
     (yt < 0) or (yt > job.table_y) or
     (zt > 0) or (zt > job.table_z) then begin
    Form1.Memo1.lines.add('Error: Position outside the table!');
    MessageDlg('Position outside the table.' + #13 + 'NOT SET!', mtError, [mbOK], 0);
    exit;
  end;

  my_btn:= MessageDlg('Set ' + s + ' postion in application defaults.'
    + #13 + 'Proceed?', mtConfirmation, mbOKCancel, 0);
  if my_btn = mrCancel then exit;

  x:=xt; y:=yt; z:=zt;
  with Form1.SgAppDefaults do begin
    Cells[1,idx]  := FormatFloat('0.00', x);
    Cells[1,idx+1]:= FormatFloat('0.00', y);
    Cells[1,idx+2]:= FormatFloat('0.00', z);
  end;
//  SaveIniFile;
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
    // nur anheben, wenn X/Y nicht in Nullpunkt-N�he
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
var Feed: LongWord;
    Dist: Double;
    S:    String;
begin
  if JogDelay < 0 then
//  if (JogDirection.X = 0) and (JogDirection.Y = 0) and (JogDirection.Z = 0) then
    exit;                                                     // nothing to move

  if JogDistance > 500                                                // [10*mm]
  then Feed:= get_AppDefaults_int(defJoypadFeedVeryFast)    // JogSpeed VeryFast
  else
    if JogDistance > 50                                               // [10*mm]
    then Feed:= get_AppDefaults_int(defJoypadFeedFast)          // JogSpeed Fast
    else
      if JogDistance > 5                                              // [10*mm]
      then Feed:= get_AppDefaults_int(defJoypadFeedSlow)        // JogSpeed Slow
      else Feed:= get_AppDefaults_int(defJoypadFeedVerySlow);       // very slow

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

  if length(S) > 7 then                     // nur wenn sich die Position �ndert
//    grbl_SendWithShortTimeout(S + ' F'+ IntToStr(Feed));
    SendSingleCommandStr(S + ' F'+ IntToStr(Feed));

  NeedsRedraw:= true;
end;

procedure TForm1.StepJogging;
var S:             String;
    PositiveTable: boolean;
begin
  if JogDelay < 0 then
    exit;                                                     // nothing to move

  WaitForIdle;

  PositiveTable := true;       // prove coordinate system (positive or negative)
  if MachineOptions.NewGrblVersion then
    PositiveTable:= get_AppDefaults_bool(defPositivMachineSpace);

  Jog.X:= grbl_mpos.X + JogDirection.X;                // calculate new position
  Jog.Y:= grbl_mpos.Y + JogDirection.Y;
  Jog.Z:= grbl_mpos.Z + JogDirection.Z;

  if PositiveTable then begin                        // begrenzen auf Tischgr��e
    if Jog.X < 0             then Jog.X:= 0;
    if Jog.X > job.table_x   then Jog.X:= job.table_x;
    if Jog.Y < 0             then Jog.Y:= 0;
    if Jog.Y > job.table_y   then Jog.Y:= job.table_y;
    if Jog.Z > 0             then Jog.Z:= 0;
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
  if Jog.X <> grbl_mpos.X then            // nur wenn sich die X-Position �ndert
    S:= S + ' X' + FloatToStrDot(Jog.X);
  if Jog.Y <> grbl_mpos.Y then            // nur wenn sich die Y-Position �ndert
    S:= S + ' Y' + FloatToStrDot(Jog.Y);
  if Jog.Z <> grbl_mpos.Z then            // nur wenn sich die Z-Position �ndert
    S:= S + ' Z' + FloatToStrDot(Jog.Z);

  if length(S) > 6 then                     // nur wenn sich die Position �ndert
//    grbl_SendWithShortTimeout(S);
    SendSingleCommandStr(S);

  NeedsRedraw:= true;
end;

procedure TForm1.ResetJogging;
begin
  if JogDelay = c_JogDelay then            // SingleStep-Jogging not started yet
    StepJogging;
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
  if isSimActive then exit;
  if JogDelay <> -1 then exit;                      // new movement only in idle

  JogDirection.X := 0; JogDirection.Y := 0; JogDirection.Z := 0;
  case (Sender as TBitBtn).tag of                         // Welcher Jog-Button?
    0:  begin                      JogDirection.Y:=  1; end;             // Nord
    1:  begin JogDirection.X:=  1; JogDirection.Y:=  1; end;          // NordOst
    2:  begin JogDirection.X:=  1;                      end;              // Ost
    3:  begin JogDirection.X:=  1; JogDirection.Y:= -1; end;           // S�dost
    4:  begin                      JogDirection.Y:= -1; end;              // S�d
    5:  begin JogDirection.X:= -1; JogDirection.Y:= -1; end;          // S�dWest
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
    then JogDirection.Z:= JogDirection.Z * 100 / 10
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
  CntrDelay:= c_CntrDelay;
  ActiveCntrButtom:= (Sender as TSpeedButton);
end;

procedure TForm1.BtnCntrLongEvent;
begin
  CntrDelay:= -1;                                       // handling by LongEvent
  case ActiveCntrButtom.tag of
    0: SetDefaultToPos('PARK',      job.park_x, job.park_y, job.park_z, defParkX, fCamActivated);
    1: SetDefaultToPos('FIXTURE 1', job.fix1_x, job.fix1_y, job.fix1_z, defFix1X, fCamActivated);
    2: SetDefaultToPos('FIXTURE 2', job.fix2_x, job.fix2_y, job.fix2_z, defFix2X, fCamActivated);
    3: if fCamActivated and (HilitePoint >= 0) then BtnCamAtPointClick(nil);
    6: if fCamActivated then BtnCamAtZeroClick(nil)
       else begin
         BtnZeroXClick(nil); BtnZeroYClick(nil)
       end;
    7: BtnZeroZClick(nil);
  end;
  ActiveCntrButtom.Down:= false;
  ActiveCntrButtom.Repaint;
end;

procedure TForm1.BtnCntrMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if CntrDelay = -1 then exit;                       // was handled by LongEvent
  CntrDelay:= -1;                     // will be handled by short click handling

  if (Button = mbRight) then BtnCntrLongEvent else
    if (Button = mbLeft) then
      case ActiveCntrButtom.tag of
        0: MoveToPos('park', job.park_x, job.park_y, job.park_z, false, fCamActivated);
        1: MoveToPos('fix1', job.fix1_x, job.fix1_y, job.fix1_z, true,  fCamActivated);
        2: MoveToPos('fix2', job.fix2_x, job.fix2_y, job.fix2_z, true,  fCamActivated);
        3: if fCamActivated
             then BtnMoveCamPointClick(Sender)
             else BtnMoveToolPointClick(Sender);
        4: MoveToPos('job center', WorkZero.X+final_bounds_mm.mid.x, WorkZero.Y+final_bounds_mm.mid.y, 0, false, false);
        5: BtnZcontactClick(Sender);
        6: if fCamActivated
             then BtnMoveCamZeroClick(Sender)
             else BtnMoveXYzeroClick(Sender);
        7: BtnMoveZzeroClick(Sender);
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
// Werkst�ck-Probekontakt anfahren. Tool muss �ber Kontakt sein
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
//      ResetToolflags;                    // with fail of probe only Z is invalid
      WorkZeroZdone:= false;
      WorkZeroAllDone:= false;
      Memo1.lines.add('WARNING: Z height invalid.');
      PlaySound('SYSTEMHAND', 0, SND_ASYNC);
    end else begin
      WorkZeroZdone:= true;
      WorkZero.Z:= MposOnPartGauge - job.probe_z_gauge;
      Jog.Z:= WorkZero.Z;
      DisableStatus;
      SendReceiveAndDwell('G0 G53 Z0' + #13);                       // Ganz oben
               // WorkZero ist negativ. Wird sin um -Workzero �ber dem Werkst�ck
      grbl_SendStr('G92 Z'+FloatToStrDot(-WorkZero.Z) + #13, true);
      EnableStatus;
// vorerst nicht n�tig, da erstes Tool ohnehin immer TLC'd wird:
{
      if job.use_part_probe then
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
// manuelle Z-H�he mit Messklotz
begin
  SetZero(4);
// vorerst nicht n�tig, da erstes Tool ohnehin immer TLC'd wird:
{
  if job.use_part_probe then
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

