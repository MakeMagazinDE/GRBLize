// #############################################################################
// ############################### FILES AND JOBS ##############################
// #############################################################################

procedure PenGridListToJob;
var i, j: Integer;
begin
  for i:= 0 to c_numOfFiles do
    job.fileDelimStrings[i]:= Form1.SgFiles.Rows[i+1].DelimitedText;
  for i := 1 to 32 do with Form1.SgPens do begin
    // Color und Enable in DrawCell erledigt!
    j:= i-1;
    job.pens[j].color:= StrToIntDef(Cells[1,i],0);
    job.pens[j].enable:= (Cells[2,i]) = 'ON';
    job.pens[j].diameter:= StrToFloatDef(Cells[3,i],0.3);
    job.pens[j].z_end:= StrToFloatDef(Cells[4,i],0);
    job.pens[j].speed:= StrToIntDef(Cells[5,i],250);
    job.pens[j].offset.x:= round(StrToFloatDef(Cells[6,i],0) * c_hpgl_scale);
    job.pens[j].offset.y:= round(StrToFloatDef(Cells[7,i],0) * c_hpgl_scale);
    job.pens[j].scale:= StrToFloatDef(Cells[8,i],100);
    job.pens[j].shape:= Tshape(StrToIntDef(Cells[9,i],0));
    job.pens[j].z_inc:= StrToFloatDef(Cells[10,i],1);
    job.pens[j].atc:= StrToIntDef(Cells[11,i],0);
    job.pens[j].tooltip:= StrToIntDef(Cells[12,i],0);
  end;
  NeedsRedraw:= true;
  NeedsRelist:= true;
end;

procedure JobToPenGridList;
var i: Integer;
begin
  for i := 0 to 31 do with Form1.SgPens do begin
    if i < 10 then
      Cells[0,i+1]:= 'P' + IntToStr(i)
    else
      Cells[0,i+1]:= 'D' + IntToStr(i-10);
    Cells[1,i+1]:= IntToStr(job.pens[i].color);
    if job.pens[i].enable then
      Cells[2,i+1]:= 'ON'
    else
      Cells[2,i+1]:= 'OFF';
    // Color und Enable in DrawCell erledigt!
    Cells[3,i+1]:=  FormatFloat('0.0',job.pens[i].diameter);
    Cells[4,i+1]:=  FormatFloat('0.0',job.pens[i].z_end);
    Cells[5,i+1]:=  IntToStr(job.pens[i].speed);
    Cells[6,i+1]:=  FormatFloat('00.0',job.pens[i].offset.x / c_hpgl_scale);
    Cells[7,i+1]:=  FormatFloat('00.0',job.pens[i].offset.y / c_hpgl_scale);
    Cells[8,i+1]:=  FormatFloat('00.0',job.pens[i].scale);
    // Shape in DrawCell erledigt!
    Cells[9,i+1]:=  IntToStr(ord(job.pens[i].shape));
    Cells[10,i+1]:= FormatFloat('0.0',job.pens[i].z_inc);
    Cells[11,i+1]:= IntToStr(job.pens[i].atc);
    Cells[12,i+1]:= IntToStr(job.pens[i].tooltip);
  end;
  Form1.SgPens.Repaint;
  for i:= 0 to c_numOfFiles do
    Form1.SgFiles.Rows[i+1].DelimitedText:= job.fileDelimStrings[i];
end;

// #############################################################################
// ################################## FILES ####################################
// #############################################################################


procedure ClearFiles;
var i: Integer;
begin
  init_blockarrays;
  for i := 0 to c_numOfFiles do with Form1.SgFiles do begin
    Cells[0,i+1]:= '';
    Cells[1,i+1]:= 'OFF';
    Cells[2,i+1]:= '0°';
    Cells[3,i+1]:= 'OFF';
    Cells[4,i+1]:= '0';
    Cells[5,i+1]:= '0';
    Cells[6,i+1]:= '100';
    Cells[6,i+1]:= 'YES';
    job.fileDelimStrings[i]:= '"",-1,0°,OFF,0,0,100';
    with FileParamArray[i] do begin
      bounds.min.x := high(Integer);
      bounds.min.y := high(Integer);
      bounds.max.x := low(Integer);
      bounds.max.y := low(Integer);
      valid := false;
      isdrillfile:= false;
    end;
  end;

  with job do begin
    for i := 0 to 31 do begin
      pens[i].used:= false;
    end;
  end;
  JobToPenGridList;
  UnHilite;
  setlength(final_array,0);
  NeedsRedraw:= true;
  NeedsRelist:= true;
end;

procedure InitJob;
var i: Integer;
begin
  Form1.SgPens.Rows[0].DelimitedText:=
    'P/D,Clr,Ena,Dia,Z,F,Xofs,Yofs,"XY %",Shape,"Z-/Cyc",ATC,Tip';
  Form1.SgFiles.Rows[0].DelimitedText:=
    '"File (click to open)",Replce,Rotate,Mirror,Xofs,Yofs,"XY %"';
  Form1.SgBlocks.Rows[0].DelimitedText:=
    '#,P/D,Ena,Dia,Shape,Bounds,Center,Points';
  Form1.SgAppdefaults.Rows[0].DelimitedText:= 'Parameter,Value';

  with job do begin

    for i := 0 to 31 do begin
      pens[i]:= PenInit;
      pens[i].offset.x:= 0;
      pens[i].offset.y:= 0;
      pens[i].atc:= 0;
    end;
    pens[0].color:=clblack;
    pens[1].color:=$00004080;
    pens[2].color:=clred;
    pens[3].color:=$000080FF;
    pens[4].color:=clyellow;
    pens[5].color:=cllime;
    pens[6].color:=$00FF8000;
    pens[7].color:=clfuchsia;
    pens[8].color:=clgray;
    pens[9].color:=clsilver;
    pens[10].color:=clmaroon;
    pens[11].color:=clolive;
    pens[12].color:=clnavy;
    pens[13].color:=clpurple;
    pens[14].color:=clteal;
    pens[15].color:=clskyblue;
    pens[16].color:=clmoneygreen;
    pens[17].color:=clblue;
    pens[18].color:=clmedgray;
    pens[19].color:=clwhite;
    for i := 20 to 31 do begin
      pens[i].color:=clgray;
    end;
    for i := 10 to 31 do begin
      pens[i].shape:= drillhole;
      pens[i].z_end:= 2.0;
      pens[i].z_inc:= 3.0;
      pens[i].speed:= 500;
    end;
  end;
  with Form1.SgAppdefaults do begin
    RowCount:= 34;
    Rows[1].DelimitedText:='"Part Size X",250';
    Rows[2].DelimitedText:='"Part Size Y",150';
    Rows[3].DelimitedText:='"Part Size Z",5';
    Rows[4].DelimitedText:='"Z Feed",200';
    Rows[5].DelimitedText:='"Z Lift above Part",10';
    Rows[6].DelimitedText:='"Z Up above Part",5';
    Rows[7].DelimitedText:='"Z Gauge",10';
    Rows[8].DelimitedText:='"Optimize Drill Path",ON';
    Rows[9].DelimitedText:= '"Use Excellon Drill Diameters",ON';
    Rows[10].DelimitedText:= '"Tool Change Pause",OFF';
    Rows[11].DelimitedText:='"Tool Change X absolute",10';
    Rows[12].DelimitedText:='"Tool Change Y absolute",100';
    Rows[13].DelimitedText:='"Tool Change Z absolute",-5';
    Rows[14].DelimitedText:='"Park Position on End",ON';
    Rows[15].DelimitedText:='"Park X absolute",200';
    Rows[16].DelimitedText:='"Park Y absolute",100';
    Rows[17].DelimitedText:='"Park Z absolute",-5';
    Rows[18].DelimitedText:='"Cam X Offset","-20"';
    Rows[19].DelimitedText:='"Cam Y Offset","40"';
    Rows[20].DelimitedText:='"Cam Z Height above Part",20';
    Rows[21].DelimitedText:='"Use Tool Z Probe",OFF';
    Rows[22].DelimitedText:='"Probe X absolute",30';
    Rows[23].DelimitedText:='"Probe Y absolute",30';
    Rows[24].DelimitedText:='"Probe Z absolute",-5';
    Rows[25].DelimitedText:='"Invert Z in G-Code",OFF';
    Rows[26].DelimitedText:='"Scale Z Feed",1';
    Rows[27].DelimitedText:='"Spindle Accel Time (s)",4';
    Rows[28].DelimitedText:='"ATC enable",OFF';
    Rows[29].DelimitedText:='"ATC zero X absolute",50';
    Rows[30].DelimitedText:='"ATC zero Y absolute",20';
    Rows[31].DelimitedText:='"ATC pickup height Z abs",-20';
    Rows[32].DelimitedText:='"ATC row X distance",20';
    Rows[33].DelimitedText:='"ATC row Y distance",0';
  end;

  ClearFiles;
end;


procedure DefaultsGridListToJob;
begin
  with Form1.SgAppdefaults do begin
    if RowCount < 34 then begin
      showMessage('Job File invalid. Check number of #Default entries!' +
        #13 + 'Job will be reset to default values.');
      InitJob;
      exit;
    end;
    job.partsize_x:= StrToFloatDef(Cells[1,1], 0);
    job.partsize_y:= StrToFloatDef(Cells[1,2], 0);
    job.partsize_z:= StrToFloatDef(Cells[1,3], 0);

    job.z_feed:= StrToIntDef(Cells[1,4], 200);
    job.z_penlift:= StrToFloatDef(Cells[1,5], 10.0);
    job.z_penup:= StrToFloatDef(Cells[1,6], 5.0);
    job.z_gauge:= StrToFloatDef(Cells[1,7], 10);

    job.optimize_drills:= Cells[1,8] = 'ON';
    job.use_excellon_dia:= Cells[1,9] = 'ON';

    job.toolchange_pause:= Cells[1,10] = 'ON';
    Form1.CheckPenChangePause.Checked:= job.toolchange_pause;

    job.toolchange_x:= StrToFloatDef(Cells[1,11], 0);
    job.toolchange_y:= StrToFloatDef(Cells[1,12], 0);
    job.toolchange_z:= StrToFloatDef(Cells[1,13], 0);

    job.parkposition_on_end:= Cells[1,14] = 'ON';
    Form1.CheckEndPark.Checked:= job.parkposition_on_end;

    job.park_x:= StrToFloatDef(Cells[1,15], 0);
    job.park_y:= StrToFloatDef(Cells[1,16], 0);
    job.park_z:= StrToFloatDef(Cells[1,17], 0);

    job.cam_x:= StrToFloatDef(Cells[1,18], 0);
    job.cam_y:= StrToFloatDef(Cells[1,19], 0);
    job.cam_z:= StrToFloatDef(Cells[1,20], 0);

    job.use_probe:= Cells[1,21] = 'ON';
    job.probe_x:= StrToFloatDef(Cells[1,22], 0);
    job.probe_y:= StrToFloatDef(Cells[1,23], 0);
    job.probe_z:= StrToFloatDef(Cells[1,24], 0);

    job.invert_z:= Cells[1,25] = 'ON';
    job.z_feedmult:= StrToFloatDef(Cells[1,26], 1);
    if job.z_feedmult < 0.1 then
      job.z_feedmult:= 0.1;
    job.spindle_wait:= StrToIntDef(Cells[1,27], 3);
    job.atc_enabled:= Cells[1,28] = 'ON';
    Form1.CheckUseATC.Checked:= job.atc_enabled;
    job.atc_zero_x:= StrToFloatDef(Cells[1,29], 50);
    job.atc_zero_y:= StrToFloatDef(Cells[1,30], 20);
    job.atc_pickup_z:= StrToFloatDef(Cells[1,31], -20);
    job.atc_delta_x:= StrToFloatDef(Cells[1,32], 20);
    job.atc_delta_y:= StrToFloatDef(Cells[1,33], 0);
  end;
end;


Procedure OpenFilesInGrid;
var
  i: Integer; my_path, my_ext: String;
begin
  PenGridListToJob;
  init_blockArrays;
  with Form1.SgFiles do
    for i:= 1 to c_numOfFiles +1 do begin
      if Cells[2, i] = '90°' then
        FileParamArray[i-1].rotate:= deg90
      else if Cells[2, i] = '270°' then
        FileParamArray[i-1].rotate:= deg270
      else if Cells[2, i] = '180°' then
        FileParamArray[i-1].rotate:= deg180
      else
        FileParamArray[i-1].rotate:= deg0;
      FileParamArray[i-1].penoverride:= StrToIntDef(Cells[1, i], -1);
      FileParamArray[i-1].mirror:= Cells[3, i] = 'ON';
      FileParamArray[i-1].offset.X:= round(StrToFloatDef(Cells[4, i], 0) * c_hpgl_scale);
      FileParamArray[i-1].offset.Y:= round(StrToFloatDef(Cells[5, i], 0) * c_hpgl_scale);
      FileParamArray[i-1].scale:= StrToFloatDef(Cells[6, i], 100.0);
      my_path:= Cells[0,i];
      my_ext:= AnsiUpperCase(ExtractFileExt(my_path));
      if my_ext = '' then
        continue;
      FileParamArray[i-1].isdrillfile := (my_ext = '.DRL');
      FileParamArray[i-1].enable:= true;
      if FileParamArray[i-1].isdrillfile then begin
        drill_fileload(my_path, i-1, StrToIntDef(Cells[1, i], -1), job.use_excellon_dia);
      end else if (my_ext = '.HPGL') or (my_ext = '.PLT') then
        hpgl_fileload(my_path, i-1, StrToIntDef(Cells[1, i], -1))
      else
        ShowMessage('Unknown File Extension:' + ExtractFileName(my_path));
    end;
  JobToPenGridList;
  param_change;
  NeedsRelist:= true;
  NeedsRedraw:= true;
  Form1.SgPens.Repaint;
  Form4.FormRefresh(nil);
end;

Procedure OpenJobFile(my_job_name: String);
var
// mySaveFile: File of Tjob;
 sl: TstringList;
 i, j, s, my_len, my_row: Integer;

begin
  JobSettingsPath:= my_job_name;
  sl:= Tstringlist.Create;
  if FileExists(my_job_name) then begin
    sl.LoadfromFile(my_job_name);
    if sl.strings[0]='#Files' then begin
      s:= 1;
      my_row:= 0;
      for i := s to sl.Count-1 do begin
        inc(my_row);
        if sl.strings[i]='#End' then
          break;
        if sl.strings[i]='#Pens' then
          break;
        Form1.SgFiles.Rows[my_row].DelimitedText:= sl.Strings[i];
      end;
      s:=i+1;
      my_row:= 0;
      for i := s to sl.Count-1 do begin
        inc(my_row);
        if sl.strings[i]='#End' then
          break;
        if sl.strings[i]='#Defaults' then
          break;
        Form1.SgPens.Rows[my_row].DelimitedText:= sl.Strings[i];
      end;
      s:=i+1;
      my_row:= 0;
      for i := s to sl.Count-1 do begin
        inc(my_row);
        if sl.strings[i]='#End' then
          break;
        if sl.strings[i]='#Blocks' then
          break;
        Form1.SgAppdefaults.Rowcount:= my_row+1;
        Form1.SgAppdefaults.Rows[my_row].DelimitedText:= sl.Strings[i];
      end;

      Form1.Caption:= c_ProgNameStr + '[' + JobSettingsPath + ']';
      PenGridListToJob;
      DefaultsGridListToJob;
      OpenFilesInGrid;
      s:=i+1;
      my_row:= 1;
      my_len:= length(final_array);
      for i := s to sl.Count-1 do begin
        if sl.strings[i]='#End' then
          break;
        if sl.strings[i]='#Comment' then
          break;
        if my_row <= my_len then begin
          Form1.SgBlocks.Rowcount:= my_row+1;
          Form1.SgBlocks.Rows[my_row].DelimitedText:= sl.Strings[i];
          for j:= 0 to length(ShapeArray)-1 do
            if Form1.SgBlocks.Cells[4,my_row] = ShapeArray[ord(j)] then
              final_array[my_row-1].shape:= Tshape(j);
          final_array[my_row-1].enable:= Form1.SgBlocks.Cells[2,my_row] = 'ON';
        end;
        inc(my_row);
      end;
      s:=i+1;
      Form1.MemoComment.Clear;
      for i := s to sl.Count-1 do begin
        if sl.strings[i]='#End' then
          break;
        Form1.MemoComment.Lines.Add(sl.Strings[i]);
      end;
    end;
  end else
    InitJob;
  sl.Free;
end;


procedure SaveJob;
var
// mySaveFile: File of Tjob;
 sl: TstringList;
 i: Integer;
begin
  JobToPenGridList;
  sl:= Tstringlist.Create;
  sl.Add('#Files');
  for i:= 1 to Form1.SgFiles.Rowcount - 1 do
    sl.Add(Form1.SgFiles.Rows[i].CommaText);
  sl.Add('#Pens');
  for i:= 1 to Form1.SgPens.Rowcount - 1 do
    sl.Add(Form1.SgPens.Rows[i].CommaText);
  sl.Add('#Defaults');
  for i:= 1 to Form1.SgAppdefaults.Rowcount - 1 do
    sl.Add(Form1.SgAppdefaults.Rows[i].CommaText);
  sl.Add('#Blocks');
  list_blocks;
  if Form1.SgBlocks.Rowcount > 1 then
    for i:= 1 to Form1.SgBlocks.Rowcount - 1 do
      if Form1.SgBlocks.Cells[0,i] <> '' then
        sl.Add(Form1.SgBlocks.Rows[i].CommaText);
  sl.Add('#Comment');
  if Form1.MemoComment.Lines.Count > 0 then
    for i:= 0 to Form1.MemoComment.Lines.Count - 1 do
      sl.Add(Form1.MemoComment.Lines.Strings[i]);
  sl.Add('#End');
  sl.SaveToFile(JobSettingsPath);
  sl.Free;
end;


procedure TForm1.JobOpenExecute(Sender: TObject);
begin
  if OpenJobDialog.Execute then begin
    InitJob;
    DefaultsGridListToJob;
    OpenJobFile(OpenJobDialog.Filename);
  end;
end;

procedure TForm1.JobSaveAsExecute(Sender: TObject);
var
  my_ext: String;
begin
  if SaveJobDialog.Execute then begin
    JobSettingsPath := SaveJobDialog.Filename;
    my_ext:= AnsiUpperCase(ExtractFileExt(JobSettingsPath));
    if my_ext <> '.JOB' then
        JobSettingsPath:= JobSettingsPath + '.job';
    Form1.Caption:= c_ProgNameStr + '[' + JobSettingsPath + ']';
    SaveJob;
  end;
end;

procedure TForm1.JobSaveExecute(Sender: TObject);
begin
  if FileExists(JobSettingsPath) then
    SaveJob
  else
    JobSaveAsExecute(Sender);
end;



procedure TForm1.FileNew1Execute(Sender: TObject);
begin
  InitJob;
  DefaultsGridListToJob;
  if FileExists('default.job') then
    OpenJobFile('default.job');
  JobSettingsPath:= 'new.job';
  draw_cnc_all;
  Form4.FormRefresh(nil);
end;

// #############################################################################
// ########################## JOB DEFAULTS #####################################
// #############################################################################

procedure TForm1.BitBtnClearFilesClick(Sender: TObject);
begin
  if fActivated then
    exit;
  ClearFiles;
  draw_cnc_all;
  Form4.FormRefresh(nil);
end;


procedure TForm1.SgAppdefaultsDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  aRect: TRect;
  aStr: String;

begin
  Rect.Left:= Rect.Left-4; // Workaround für XE8-Darstellung
  aStr:= SgAppdefaults.Cells[ACol, ARow];
  if aRow = 0 then with SgAppdefaults,Canvas do begin
    Font.Style := [fsBold];
    TextRect(Rect, Rect.Left + 2, Rect.Top + 2, aStr);
  end else if (aRow < 8) and (aCol = 0) then with SgAppdefaults,Canvas do begin
    Font.Color := clred;
    TextRect(Rect, Rect.Left + 2, Rect.Top + 2, aStr);
  end else if (aCol = 1) and ((aStr= 'ON') or (aStr= 'OFF')) then // ON, OFF
    with SgAppdefaults,Canvas do begin
      FrameRect(Rect);
      inc(Rect.Left);
      inc(Rect.Top);
      Brush.Color := clgray;
      FrameRect(Rect);
      Brush.Color := cl3Dlight;
      InflateRect(Rect, -1, -1);
      Font.Color := clblack;
      if aStr = 'ON' then
        Font.Style := [fsBold]
      else
        Font.Style := [];
      aRect := Rect;
      FillRect(Rect);
      aStr:= Cells[ACol, ARow];
      aRect.Top := aRect.Top + 1; // adjust top to center vertical
      DrawText(Canvas.Handle, PChar(aStr), Length(aStr), aRect, DT_CENTER);
    end;
end;

procedure TForm1.SgAppdefaultsExit(Sender: TObject);
begin
  with SgAppdefaults do
    Options:= Options - [goEditing, goAlwaysShowEditor];
  DefaultsGridListToJob;
  PenGridListToJob;
  OpenFilesInGrid;
end;

procedure TForm1.SgAppdefaultsKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) or (Key = #10) then begin
    SgAppdefaultsExit(Sender);;
  end;
end;


procedure TForm1.SgAppdefaultsMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
// wird vor SgAppdefaultsClick aufgerufen!
begin
  with SgAppdefaults do begin
    Options:= Options - [goEditing, goAlwaysShowEditor];
    if Col = 1 then begin
      if Cells[1, Row] = 'ON' then begin
        Cells[1, Row]:= 'OFF';
        DefaultsGridListToJob;
        OpenFilesInGrid;
      end else if Cells[1, Row] = 'OFF' then begin
        Cells[1, Row]:= 'ON';
        DefaultsGridListToJob;
        OpenFilesInGrid;
      end else
        Options:= Options + [goEditing, goAlwaysShowEditor];
    end;
  end;
end;

procedure TForm1.SgAppdefaultsClick(Sender: TObject);
begin
  with SgAppdefaults do
    Options:= Options - [goEditing, goAlwaysShowEditor];
  NeedsRedraw:= true;
  NeedsRelist:= true;
end;

// #############################################################################
// ########################### Stringgrid Handler ##############################
// #############################################################################


procedure TForm1.SgFilesDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  aRect: TRect;
  aStr: String;
begin
  Rect.Left:= Rect.Left-4; // Workaround für XE8-Darstellung
  if aRow = 0 then with SgFiles,Canvas do begin
    Font.Style := [fsBold];
    TextRect(Rect, Rect.Left + 2, Rect.Top + 2, Cells[ACol, ARow]);
  end else with SgFiles,Canvas do begin
{    if (ACol = Col) and (ARow= Row) and (aCol <> 0) then begin
      Brush.Color := clHighlight;
      Font.Color:=clwhite;
      TextRect(Rect, Rect.Left + 2, Rect.Top + 2, cells[acol, arow]);
      Font.Color:=clblack;
    end;
}
    Font.Color:=clblack;
    Pen.Color := cl3Dlight;
    aStr:= Cells[ACol, ARow];
    case aCol of
      0:
        begin
          aStr:= extractFilename(Cells[0,aRow]);
          FrameRect(Rect);
          inc(Rect.Left);
          inc(Rect.Top);
          Brush.Color := clgray;
          FrameRect(Rect);
          Brush.Color := cl3Dlight;
          InflateRect(Rect, -1, -1);
          TextRect(Rect, Rect.Left + 2, Rect.Top + 1, aStr);
        end;
      1,2,3:
        begin
          FrameRect(Rect);
          inc(Rect.Left);
          inc(Rect.Top);
          Brush.Color := clgray;
          FrameRect(Rect);
          Brush.Color := cl3Dlight;
          InflateRect(Rect, -1, -1);
          Font.Style := [];
          if aCol = 1 then begin
            if aStr = '-1' then
              aStr:= 'OFF'
            else
              if astr = '10' then
                aStr:= 'Drill 10'
              else
                aStr:= 'Pen '+ aStr;
          end;
          if aStr <> 'OFF' then
            Font.Style := [fsBold];
          if aStr = '0°' then
            Font.Style := [];
          FillRect(Rect);
          aRect := Rect;
          aRect.Top := aRect.Top + 1; // adjust top to center
          DrawText(Canvas.Handle, PChar(aStr), Length(aStr), aRect, DT_CENTER);
        end;
      7:  // Clear-"Button"
        begin
          FrameRect(Rect);
          inc(Rect.Left);
          inc(Rect.Top);
          Brush.Color := clgray;
          FrameRect(Rect);
          Brush.Color := cl3Dlight;
          InflateRect(Rect, -1, -1);
          Font.Style := [];
          aStr:= 'CLR';
          Font.Style := [];
          FillRect(Rect);
          aRect := Rect;
          aRect.Top := aRect.Top + 1; // adjust top to center
          DrawText(Canvas.Handle, PChar(aStr), Length(aStr), aRect, DT_CENTER);
        end;
    end;
  end;
end;


procedure TForm1.ComboBox1Exit(Sender: TObject);
begin
  with sender as TComboBox do begin
    hide;
    SgFiles.Options:= SgFiles.Options - [goEditing, goAlwaysShowEditor];
    if ItemIndex >= 0 then
      with SgFiles do
        if (Row > 0) and (Col= 1) then begin
          Cells[col, row] := IntToStr(ItemIndex-1); //  := Items[ItemIndex];
          job.fileDelimStrings[Row-1]:= Rows[Row].DelimitedText;
          UnHilite;
          OpenFilesInGrid;
          Repaint;
        end;
  end;
  SgFiles.Options:= SgFiles.Options - [goEditing];
end;


procedure TForm1.SgFilesMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var R: TRect;
  org: TPoint;
    i: Integer;
begin
  with SgFiles do begin
    Options:= Options - [goEditing, goAlwaysShowEditor];
    if (Row > 0) and (Col > 0)then begin
      case Col of
        1:
          begin
            R := SgFiles.CellRect(Col, Row);
            org := self.ScreenToClient(self.ClientToScreen(R.TopLeft));
            perform( WM_CANCELMODE, 0, 0 ); // verhindert Mausaktion in Stringgrid
            with ComboBox1 do begin
              SetBounds(org.X-10, org.Y-2, R.Right-R.Left+10, Form1.Height);
              ItemIndex := Items.IndexOf('Pen '+SgFiles.Cells[Col, Row]);
              if ItemIndex < 0 then
                ItemIndex:= 1;
              Show;
              BringToFront;
              SetFocus;
              DroppedDown := true;
            end;
            exit;
          end;
        2:
          begin
            if Cells[2, Row] = '0°' then
              Cells[2, Row]:= '90°'
            else if Cells[2, Row] = '90°' then
              Cells[2, Row]:= '180°'
            else if Cells[2, Row] = '180°' then
              Cells[2, Row]:= '270°'
            else
              Cells[2, Row]:= '0°';
          end;
        3:
          begin
            if Cells[3, Row] = 'ON' then
              Cells[3, Row]:= 'OFF'
            else
              Cells[3, Row]:= 'ON';
          end;
        4,5,6:
          begin
            Options:= Options + [goEditing, goAlwaysShowEditor];
          end;
        7:
          begin
            Cells[0, Row]:= '';
            Cells[1, Row]:= '-1';
            Cells[2, Row]:= '0°';
            Cells[3, Row]:= 'OFF';
            for i:= 0 to c_numOfPens do
              job.pens[i].used:= false;
          end;
        end;
      job.fileDelimStrings[Row-1]:= Rows[Row].DelimitedText;
      UnHilite;
      OpenFilesInGrid;
    end;
  end;
end;

procedure TForm1.SgFilesKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) or (Key = #10) then
    with SgFiles do begin
      job.fileDelimStrings[Row-1]:= Rows[Row].DelimitedText;
      Options:= Options - [goEditing, goAlwaysShowEditor];
      Repaint;
      UnHilite;
      PenGridListToJob;
      OpenFilesInGrid;
    end;
end;


procedure TForm1.SgFilesClick(Sender: TObject);
// wird nach Loslassen der Maustaste ausgeführt!
begin
  with SgFiles do begin
    Options:= Options - [goEditing, goAlwaysShowEditor];
    if (Row > 0) and (Col = 0) then begin
      OpenFileDialog.FilterIndex:= 0;
      if OpenFileDialog.Execute then
        Cells[0, Row]:= OpenFileDialog.Filename
      else
        Cells[0, Row]:= '';
      job.fileDelimStrings[Row-1]:= Rows[Row].DelimitedText;
      UnHilite;
      OpenFilesInGrid;
    end;
  end;
end;


