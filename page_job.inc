
// #############################################################################
// ################################## FILES ####################################
// #############################################################################

procedure JobDefaultGridlistToJob;
begin
  with Form1.SgJobDefaults do begin
    if RowCount < 3 then InitJob;

    job.partsize_x:= StrToFloatDef(Cells[1,1], 0);
    job.partsize_y:= StrToFloatDef(Cells[1,2], 0);
    job.partsize_z:= StrToFloatDef(Cells[1,3], 0);

    job.Material:= Nmaterial;
    repeat
      dec(job.Material)
    until (Cells[1,4] = string(Materials[job.Material].Name)) or (job.Material = 0);

    job.z_feed:= StrToIntDef(Cells[1,5], 200);
    job.z_penlift:= StrToFloatDef(Cells[1,6], 10.0);
    job.z_penup:= StrToFloatDef(Cells[1,7], 5.0);
    job.z_gauge:= StrToFloatDef(Cells[1,8], 10);

    job.optimize_drills:= Cells[1,9] = 'ON';
    job.use_excellon_dia:= Cells[1,10] = 'ON';
  end;
end;

procedure SetPCBmillTool(tool_idx: Integer);
begin
  job.pens[tool_idx].diameter:= 0.2;
  job.pens[tool_idx].shape:= contour;
  job.pens[tool_idx].tipdia:= 0.2;
  job.pens[tool_idx].z_end:= 0.2;
  job.pens[tool_idx].tooltip:= 1;
  job.pens[tool_idx].tooltip:= 1;
  job.pens[tool_idx].speed:= 500;
  job.pens[tool_idx].force_closed:= true;
end;

procedure ProveNewGBR(FileName:string;i: integer);
begin
  if not FileExists(FileParamArray[i].gbr_name) then begin
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);// Quelle nicht gefunden, nur NC laden
    Form1.Memo1.lines.add('');
    Form1.Memo1.lines.add('WARNING: Mill file not found!');
    exit;
  end;
                                            // G-Code is older than gerber data?
  if FileAge(FileName) < FileAge(FileParamArray[i].gbr_name) then begin
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
    Form1.Memo1.lines.add('');
    Form1.Memo1.lines.add('WARNING: One or more mill/drill file(s)');
    Form1.Memo1.lines.add('have been changed since last job was saved.');
    Form1.Memo1.lines.add('All mill paths will be rebuild and enabled!');

    CallPcb2Gcode(FileParamArray[i].gbr_name,
                            FileParamArray[i].gbr_mirror,
                            FileParamArray[i].gbr_inflate,
                            '500');
  end;
end;

Procedure OpenFilesInGrid;
var
  i, pen_override: Integer;
  my_path, my_ext: String;
  use_excellon: Boolean;
  Sx, Sy: integer;
begin
  PenGridListToJob;
  DefaultsGridListToJob;
  init_blockArrays;
  for i:= 0 to 31 do begin
    job.pens[i].used:= false;
    job.pens[i].enable:= false;
    job.pens[i].force_closed:= false;
  end;
  with Form1.SgFiles do begin
    for i:= 1 to c_numOfFiles +1 do begin
      if Cells[2, i] = '90°' then
        FileParamArray[i-1].rotate:= deg90
      else if Cells[2, i] = '270°' then
        FileParamArray[i-1].rotate:= deg270
      else if Cells[2, i] = '180°' then
        FileParamArray[i-1].rotate:= deg180
      else
        FileParamArray[i-1].rotate:= deg0;
      FileParamArray[i-1].mirror:= Cells[3, i] = 'ON';
      FileParamArray[i-1].offset.X:= round(StrToFloatDef(Cells[4, i], 0) * c_hpgl_scale);
      FileParamArray[i-1].offset.Y:= round(StrToFloatDef(Cells[5, i], 0) * c_hpgl_scale);
      FileParamArray[i-1].scale.X:= StrToFloatDef(Cells[6, i], 100.0);
      FileParamArray[i-1].scale.Y:= StrToFloatDef(Cells[7, i], 100.0);

      my_path:= Cells[0,i];

      if length(my_path) < 3 then    // empty fields contains a space character,
        continue;                    // but at least an extesion is necessary

      if not FileExists(my_path) then begin
        Form1.Memo1.lines.add('ERROR: File not found (' + my_path + ')!');
        MessageDlg('ERROR: File not found (' + my_path + ')!', mtConfirmation, [mbCancel],0);
        continue;
      end;

      my_ext:= AnsiUpperCase(ExtractFileExt(my_path));
      if my_ext = '' then begin
        Form1.Memo1.lines.add('ERROR: No Extension (' + my_path + ')!');
        continue;
      end;
      FileParamArray[i-1].isdrillfile := (my_ext = '.DRL') or (my_ext = '.DRD');
      FileParamArray[i-1].enable:= true;
      pen_override:= StrToIntDef(Cells[1, i], -1);
      if FileParamArray[i-1].isdrillfile then begin
        Cells[9, i]:= 'Drill'; // Replace Pen
        use_excellon:= job.use_excellon_dia and (pen_override < 0);
        drill_fileload(my_path, i-1, StrToIntDef(Cells[1, i], -1), use_excellon);
      end else if (my_ext = '.HPGL') or (my_ext = '.HPG') or (my_ext = '.PLT') or (my_ext = '.PEN') then begin
        Cells[9, i]:= 'Plot'; // Replace Pen
        hpgl_fileload(my_path, i-1, StrToIntDef(Cells[1, i], -1))
      end else if (my_ext = '.NC') or (my_ext = '.NGC') or (my_ext = '.TAP') or (my_ext = '.CNC') then begin
        Cells[9, i]:= 'GCode'; // Remark
        gcode_fileload(my_path, i-1, -1);
      end else if (my_ext = '.DIM') then begin             // dimensions for PCB
        Cells[9, i]:= 'Dimensions'; // Replace Pen
        Cells[1, i]:= '7';                                        // Replace Pen
        dim_fileload(my_path, i-1, StrToIntDef(Cells[1, i], 7));
      end else if (my_ext = '.NCF') then begin
        ProveNewGBR(my_path,i);
        Cells[9, i]:= 'PCB top'; // Remark
        Cells[1, i]:= '8'; // Replace Pen
        gcode_fileload(my_path, i-1, 8);
        SetPCBmillTool(8);
      end else if (my_ext = '.NCB') then begin
        ProveNewGBR(my_path,i);
        Cells[9, i]:= 'PCB bottom'; // Remark
        Cells[1, i]:= '9'; // Replace Pen
        gcode_fileload(my_path, i-1, 9);
        SetPCBmillTool(9);
      end else if (my_ext = '.SVG') then begin
        Cells[9, i]:= 'SVG'; // Remark
        svg_fileload(my_path, i-1, -1);
      end else
        Form1.Memo1.lines.add('Unknown File Extension:' + ExtractFileName(my_path));
      FileParamArray[i-1].penoverride:= pen_override;
      if pen_override >= 0 then begin
        job.pens[pen_override].enable:= true;
        job.pens[pen_override].used:= true;
      end;
      job.fileDelimStrings[i-1]:= ShortString(Rows[i].DelimitedText);
    end;
  end;

  job.pens[0].enable:= false; // Tool 0 immer disabled
  for i:= 1 to 31 do begin
    job.pens[i].enable:= job.pens[i].used;
  end;

  JobToPenGridList;
  apply_pen_change;
  Form1.SgPens.Repaint;
  GLSneedsATCupdateTimeout:= 1;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Mill/drill files (re)loaded.');

                                       // set part dimensions (X and Y) and zoom
  if (final_bounds_mm.max.x > 10) and (final_bounds_mm.max.y > 10) then begin
                                                          // Dimension aufrunden
    job.partsize_x:= 10*round((final_bounds_mm.max.x+6)/10);
    job.partsize_y:= 10*round((final_bounds_mm.max.y+6)/10);
                                                        // Werkstückgröße setzen
    Form1.SgJobDefaults.Cells[1,1]:= FloatToStr(job.partsize_x);
    Form1.SgJobDefaults.Cells[1,2]:= FloatToStr(job.partsize_y);

    Sx:= round(Form2.DrawingBox.Width  / job.partsize_x) - 1;
    Sy:= round(Form2.DrawingBox.Height / job.partsize_y) - 1;

    if Sx < Sy then Form2.TrackBarZoom.Position:= Sx
               else Form2.TrackBarZoom.Position:= Sy;

    bm_scroll.x:= 0;
    bm_scroll.y:= Form2.ClientHeight - Form2.DrawingBox.Height;
  end;

  NeedsRedraw:= true;
end;

Procedure OpenJobFile;
var i: integer;

  ///// load Job-File in Windows-Ini-Format ////////////////////////////////////
  procedure LoadIniFormat;
  var Ini:                  TIniFile;
      i, j, k, LengthFinal: integer;
      Section, Name:        string;
      sl_p:                 TstringList;
      expand:               boolean;
  begin
    Ini := TIniFile.Create(JobSettingsPath);                        // open file

// offen: - Fehlerbehandlung bei Files, wenn etwas nicht gesetzt ist
    try

  // load defaults first, because size of table influence the settings of blocks
      with Form1.SgJobDefaults do begin
        Cells[1, 1]:= Ini.ReadString('Defaults', 'PartSizeX',    Cells[1, 1]);
        Cells[1, 2]:= Ini.ReadString('Defaults', 'PartSizeY',    Cells[1, 2]);
        Cells[1, 3]:= Ini.ReadString('Defaults', 'PartSizeZ',    Cells[1, 3]);
        Cells[1, 4]:= Ini.ReadString('Defaults', 'Material',     Cells[1, 4]);
        Cells[1, 5]:= Ini.ReadString('Defaults', 'ZFeedMilling', Cells[1, 5]);
        Cells[1, 6]:= Ini.ReadString('Defaults', 'ZLiftPart',    Cells[1, 6]);
        Cells[1, 7]:= Ini.ReadString('Defaults', 'ZUpPart',      Cells[1, 7]);
        Cells[1, 8]:= Ini.ReadString('Defaults', 'ZGauge',       Cells[1, 8]);
        Cells[1, 9]:= Ini.ReadString('Defaults', 'OptDrillPath', Cells[1, 9]);
        Cells[1,10]:= Ini.ReadString('Defaults', 'UseExcellon',  Cells[1,10]);
        Repaint;
      end;

      with Form1.SgFiles do begin
        for i:= 1 to c_numOfFiles do begin                        // files table
          Section:= 'File' + IntToStr(i);

          Cells[0,i]:= Ini.ReadString(Section, 'Name',    Cells[0,i]);

          expand:= false;                     // expand relativ path to job file
          if length(Cells[0,i]) > 0 then expand:= true;
          if length(Cells[0,i]) > 1 then
            if Cells[0,i][2]  = ':' then expand:= false;
          if expand then
            Cells[0,i]:= ExpandFileName(ExtractFileDir(JobSettingsPath) + '\' + Cells[0,i]);

          Cells[1,i]:= Ini.ReadString(Section, 'Replace', Cells[1,i]);
          Cells[2,i]:= Ini.ReadString(Section, 'Rotate',  Cells[2,i]);
          Cells[3,i]:= Ini.ReadString(Section, 'Mirror',  Cells[3,i]);
          Cells[4,i]:= Ini.ReadString(Section, 'Xofs',    Cells[4,i]);
          Cells[5,i]:= Ini.ReadString(Section, 'Yofs',    Cells[5,i]);
          Cells[6,i]:= Ini.ReadString(Section, 'ScaleX',  Cells[6,i]);
          Cells[7,i]:= Ini.ReadString(Section, 'ScaleY',  Cells[7,i]);
          Cells[9,i]:= Ini.ReadString(Section, 'Remark',  Cells[8,i]);
          FileParamArray[i].gbr_name:=               Ini.ReadString(Section,'GbrName',              FileParamArray[i].gbr_name);
          FileParamArray[i].gbr_mirror:=  StrToBool (Ini.ReadString(Section,'GbrMirror', BoolToStr (FileParamArray[i].gbr_mirror)));
          FileParamArray[i].gbr_inflate:= StrToFloat(Ini.ReadString(Section,'GbrInflate',FloatToStr(FileParamArray[i].gbr_inflate)));
        end;
        Repaint;
        OpenFilesInGrid;
      end;

      with Form1.SgPens do begin
        for i:=1 to c_numOfPens do begin                             // pens table
          Section:= 'Pen' + IntToStr(i-1);
          Cells[ 1,i]:= Ini.ReadString(Section, 'Color',    Cells[ 1,i]);
          Cells[ 2,i]:= Ini.ReadString(Section, 'Enable',   Cells[ 2,i]);
          Cells[ 3,i]:= Ini.ReadString(Section, 'Diameter', Cells[ 3,i]);
          Cells[ 4,i]:= Ini.ReadString(Section, 'Z',        Cells[ 4,i]);
          Cells[ 5,i]:= Ini.ReadString(Section, 'Feed',     Cells[ 5,i]);
          Cells[ 6,i]:= Ini.ReadString(Section, 'Xofs',     Cells[ 6,i]);
          Cells[ 7,i]:= Ini.ReadString(Section, 'Yofs',     Cells[ 7,i]);
          Cells[ 8,i]:= Ini.ReadString(Section, 'Scale',    Cells[ 8,i]);
          Cells[ 9,i]:= Ini.ReadString(Section, 'Shape',    Cells[ 9,i]);
          Cells[10,i]:= Ini.ReadString(Section, 'Zcycle',   Cells[10,i]);
          Cells[11,i]:= Ini.ReadString(Section, 'ATC',      Cells[11,i]);
          Cells[12,i]:= Ini.ReadString(Section, 'Tip',      Cells[12,i]);
          Cells[13,i]:= Ini.ReadString(Section, 'Blades',   Cells[13,i]);
        end;
        Repaint;
        PenGridListToJob;
        apply_pen_change;
      end;

      LengthFinal:= length(final_array);                               // Blocks
      i:= 1; Name:= 'Block1';
      while Ini.ValueExists('Blocks',Name) and (i<=LengthFinal) do begin
        Form1.SgBlocks.Rowcount:= i+1;
        Form1.SgBlocks.Rows[i].DelimitedText:= Ini.ReadString('Blocks', Name, '');
        for j:= 0 to high(ShapeArray) do
          if Form1.SgBlocks.Cells[4,i] = string(ShapeArray[ord(j)]) then
            final_array[i-1].shape:= Tshape(j);
        final_array[i-1].enable:= Form1.SgBlocks.Cells[2,i] = 'ON';
        enable_all_millings(final_array[i-1], final_array[i-1].enable);
        inc(i); Name:= 'Block' + IntToStr(i);
      end;
      Form1.SgBlocks.Repaint;

      i:= 1; Name:= 'Path1';                                      // PathEnables
      sl_p:= Tstringlist.Create;
      j:= 0;
      while Ini.ValueExists('PathEnable',Name) and (i<=LengthFinal) do begin
        sl_p.Clear;
        sl_p.CommaText:= Ini.ReadString('PathEnable', Name, '');
        if j <= high(final_array) then
          if (sl_p.Count-1) <= high(final_array[j].milling_enables) then begin
            for k := 0 to sl_p.Count-1 do
              if (j <= high(final_array)) and (k <= high(final_array[j].milling_enables)) then
                final_array[j].milling_enables[k]:= sl_p[k] = '1';
            inc(j);
          end;
        inc(i); Name:= 'Path' + IntToStr(i);
      end;
      sl_p.Free;

      Form1.MemoComment.Clear;
      i:= 1; Name:= 'Line1';
      while Ini.ValueExists('Comment',Name) do begin
        Form1.MemoComment.Lines.Add(Ini.ReadString('Comment', Name, ''));
        inc(i); Name:= 'Line' + IntToStr(i);
      end;

    finally
      Ini.Free;
    end;
  end;

//// load Job //////////////////////////////////////////////////////////////////
begin
  ResetToolFlags;
//  InitJob;          // wird schon in FormCreate bzw. JobOpenExecute aufgerufen
  Form1.Caption:= c_ProgNameStr + '[' + JobSettingsPath + ']';
  if not FileExists(JobSettingsPath) then begin
    PenGridListToJob;
    Form1.Memo1.lines.add('');
    Form1.Memo1.lines.add('Job reset and initialized.');
  end else begin
    LoadIniFormat;
    Form1.Memo1.lines.add('');
    Form1.Memo1.lines.add('Job and block/path settings applied.');
  end;
  for i := 0 to high(final_array) do
    final_array[i].enable:= is_any_milling_enabled(final_array[i]);
  ListBlocks;
  NeedsRedraw:= true;
end;

procedure SaveJob;
var i, p:               Integer;
    my_filename:        String;
    block_str, Section: String;
    Ini:                TIniFile;
begin
  JobToPenGridList;
  DeleteFile(JobSettingsPath);
  Ini := TIniFile.Create(JobSettingsPath);                          // open file

  try
    for i:= 1 to Form1.SgFiles.Rowcount-1 do begin                // files table
      Section:= 'File' + IntToStr(i);
                                   // save the relativ file name to the job file
      my_filename:= ExtractRelativePath(JobSettingsPath,Form1.SgFiles.Cells[0,i]);
      if (length(my_filename) <= 3) then continue;                 // line empty
      Ini.WriteString(Section, 'Name',    my_filename);
      Ini.WriteString(Section, 'Replace',   Form1.SgFiles.Cells[1,i]);
      Ini.WriteString(Section, 'Rotate',    Form1.SgFiles.Cells[2,i]);
      Ini.WriteString(Section, 'Mirror',    Form1.SgFiles.Cells[3,i]);
      Ini.WriteString(Section, 'Xofs',      Form1.SgFiles.Cells[4,i]);
      Ini.WriteString(Section, 'Yofs',      Form1.SgFiles.Cells[5,i]);
      Ini.WriteString(Section, 'ScaleX',    Form1.SgFiles.Cells[6,i]);
      Ini.WriteString(Section, 'ScaleY',    Form1.SgFiles.Cells[7,i]);
      Ini.WriteString(Section, 'Remark',    Form1.SgFiles.Cells[9,i]);
      Ini.WriteString(Section, 'GbrName',              FileParamArray[i].gbr_name);
      Ini.WriteString(Section, 'GbrMirror', BoolToStr (FileParamArray[i].gbr_mirror));
      Ini.WriteString(Section, 'GbrInflate',FloatToStr(FileParamArray[i].gbr_inflate));
    end;

    for i:=1 to Form1.SgPens.Rowcount-1 do begin                   // pens table
      Section:= 'Pen' + IntToStr(i-1);
      Ini.WriteString(Section, 'Color',    Form1.SgPens.Cells[ 1,i]);
      Ini.WriteString(Section, 'Enable',   Form1.SgPens.Cells[ 2,i]);
      Ini.WriteString(Section, 'Diameter', Form1.SgPens.Cells[ 3,i]);
      Ini.WriteString(Section, 'Z',        Form1.SgPens.Cells[ 4,i]);
      Ini.WriteString(Section, 'Feed',     Form1.SgPens.Cells[ 5,i]);
      Ini.WriteString(Section, 'Xofs',     Form1.SgPens.Cells[ 6,i]);
      Ini.WriteString(Section, 'Yofs',     Form1.SgPens.Cells[ 7,i]);
      Ini.WriteString(Section, 'Scale',    Form1.SgPens.Cells[ 8,i]);
      Ini.WriteString(Section, 'Shape',    Form1.SgPens.Cells[ 9,i]);
      Ini.WriteString(Section, 'Zcycle',   Form1.SgPens.Cells[10,i]);
      Ini.WriteString(Section, 'ATC',      Form1.SgPens.Cells[11,i]);
      Ini.WriteString(Section, 'Tip',      Form1.SgPens.Cells[12,i]);
      Ini.WriteString(Section, 'Blades',   Form1.SgPens.Cells[13,i]);
    end;

                                                                 // job defaults
    Ini.WriteString('Defaults', 'PartSizeX',    Form1.SgJobDefaults.Cells[1, 1]);
    Ini.WriteString('Defaults', 'PartSizeY',    Form1.SgJobDefaults.Cells[1, 2]);
    Ini.WriteString('Defaults', 'PartSizeZ',    Form1.SgJobDefaults.Cells[1, 3]);
    Ini.WriteString('Defaults', 'Material',     Form1.SgJobDefaults.Cells[1, 4]);
    Ini.WriteString('Defaults', 'ZFeedMilling', Form1.SgJobDefaults.Cells[1, 5]);
    Ini.WriteString('Defaults', 'ZLiftPart',    Form1.SgJobDefaults.Cells[1, 6]);
    Ini.WriteString('Defaults', 'ZUpPart',      Form1.SgJobDefaults.Cells[1, 7]);
    Ini.WriteString('Defaults', 'ZGauge',       Form1.SgJobDefaults.Cells[1, 8]);
    Ini.WriteString('Defaults', 'OptDrillPath', Form1.SgJobDefaults.Cells[1, 9]);
    Ini.WriteString('Defaults', 'UseExcellon',  Form1.SgJobDefaults.Cells[1,10]);

    ListBlocks;
    if Form1.SgBlocks.Rowcount > 1 then                                // Blocks
      for i:= 1 to Form1.SgBlocks.Rowcount - 1 do
        if Form1.SgBlocks.Cells[0,i] <> '' then
           Ini.WriteString('Blocks', 'Block'+IntToStr(i), Form1.SgBlocks.Rows[i].CommaText);

    for i:= 0 to high(final_array) do begin                       // PathEnables
      block_str:='';
      for p:= 0 to high(final_array[i].milling_enables) do
        if final_array[i].milling_enables[p] then
          block_str:= block_str + '1,'
        else
          block_str:= block_str + '0,';
      block_str:= copy(block_str, 0, length(block_str)-1);
      Ini.WriteString('PathEnable', 'Path'+IntToStr(i+1), block_str);
    end;

    if Form1.MemoComment.Lines.Count > 0 then
      for i:= 0 to Form1.MemoComment.Lines.Count - 1 do
        Ini.WriteString('Comment', 'Line'+IntToStr(i), Form1.MemoComment.Lines.Strings[i]);

  finally
    Ini.Free;
  end;
end;

procedure TForm1.FileNew1Execute(Sender: TObject);
begin
  InitJob;
  DefaultsGridListToJob;
  JobSettingsPath:= '';
  draw_cnc_all;
  Form1.Caption:= c_ProgNameStr;
end;

procedure TForm1.JobOpenExecute(Sender: TObject);
begin
  if OpenJobDialog.Execute then begin
    InitJob;
    JobSettingsPath:= OpenJobDialog.Filename;
    OpenJobFile;
  end;
end;

procedure TForm1.JobSaveExecute(Sender: TObject);
begin
  if FileExists(JobSettingsPath) then
    SaveJob
  else
    JobSaveAsExecute(Sender);
end;

procedure TForm1.JobSaveAsExecute(Sender: TObject);
var my_ext: String;
    i:      integer;
begin
  i:= 1;
  while (i<=c_numOfFiles) and (SaveJobDialog.Filename='') do begin
    if Trim(Form1.SgFiles.Cells[0,i]) <>'' then
      SaveJobDialog.Filename:= ChangeFileExt(Form1.SgFiles.Cells[0,i],'job');
    inc(i);
  end;
  if SaveJobDialog.Execute then begin
//  Application.ProcessMessages;
    JobSettingsPath := SaveJobDialog.Filename;
    my_ext:= AnsiUpperCase(ExtractFileExt(JobSettingsPath));
    if my_ext <> '.JOB' then
        JobSettingsPath:= JobSettingsPath + '.job';
    Form1.Caption:= c_ProgNameStr + '[' + JobSettingsPath + ']';
    SaveJob;
  end;
end;

// #############################################################################
// ########################## JOB DEFAULTS #####################################
// #############################################################################

procedure TForm1.SgJobDefaultsDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  aRect: TRect;
  aStr: String;

begin
//  Rect.Left:= Rect.Left-4; // Workaround für XE8-Darstellung
  aStr:= SgJobDefaults.Cells[ACol, ARow];
  if aRow = 0 then
    with SgJobDefaults,Canvas do begin
      Font.Style := [fsBold];
      TextRect(Rect, Rect.Left + 2, Rect.Top + 2, aStr);
    end;
  if (aCol = 1) and
     ((aStr= 'ON') or (aStr= 'OFF') or (aRow=4)) then // ON, OFF
    with SgJobDefaults,Canvas do begin
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

procedure TForm1.SgJobDefaultsExit(Sender: TObject);
begin
  SgEditorOff(SgJobDefaults);
  OpenFilesInGrid;
  NeedsRedraw:= true;
  ListBlocks;
end;

procedure TForm1.SgJobDefaultsKeyPress(Sender: TObject; var Key: Char);
begin
  if Key in [#10, #13, #27] then SgJobDefaultsExit(Sender);
end;

procedure TForm1.SgJobDefaultsSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
var i: integer;
    P: TPoint;
begin
  with SgJobDefaults do begin                // right col is for hide focus only
    if ACol = ColCount-1 then begin CanSelect:= false; exit end;
    SgEditorOff(SgJobDefaults);
    if (ACol < 1) or (ARow < 1) then exit;
    if ACol = 1 then begin
      if Cells[1, ARow] = 'ON' then begin
        Cells[1, ARow]:= 'OFF';
        OpenFilesInGrid;
      end else if Cells[1, ARow] = 'OFF' then begin
        Cells[1, ARow]:= 'ON';
      end else if (ARow = 4) then begin                              // Material
        for i:= 0 to PopupMenuMaterial.Items.Count - 1 do           // set focus
          PopupMenuMaterial.Items[i].Checked:= job.Material = i;
        P:= ClientToScreen(CellRect(ACol,ARow).BottomRight);       // start menu
        PopupMenuMaterial.Popup(P.X,P.Y-120);
      end else SgEditorOn(SgJobDefaults,ACol,ARow,true,true);
    end;
  end;
end;

// #############################################################################
// GRBLize Defaults auf Defaults-Seite!
// #############################################################################

procedure TForm1.SgAppDefaultsDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var aRect: TRect;
    aStr:  String;
begin
{  aStr:= SgAppDefaults.Cells[ACol, ARow];
  if aRow = 0 then with SgAppDefaults,Canvas do begin
    Font.Style := [fsBold];
    TextRect(Rect, Rect.Left + 2, Rect.Top + 2, aStr);
  end else with SgAppDefaults,Canvas do begin
    Pen.Color := cl3Dlight;
    Font.Color:=clblack;
    if (aCol = 1) and ((aStr= 'ON') or (aStr= 'OFF')) then begin // ON, OFF
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
}
  with SgAppDefaults,Canvas do begin
    aStr:= Cells[ACol, ARow];
    if aRow = 0 then begin
      Font.Style := [fsBold];
      TextRect(Rect, Rect.Left + 2, Rect.Top + 2, aStr);
    end else begin
      Pen.Color := cl3Dlight;
      Font.Color:=clblack;
      if (aCol = 1) and ((aStr= 'ON') or (aStr= 'OFF') or (ARow=defJoypadZaxisButton))
      then begin                                                      // ON, OFF
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
  end;
end;

procedure TForm1.SgAppDefaultsExit(Sender: TObject);
begin
  SgEditorOff(SgAppDefaults);
  DefaultsGridListToJob;
end;

procedure TForm1.SgAppDefaultsKeyPress(Sender: TObject; var Key: Char);
begin
  if Key in [#10, #13, #27] then SgAppDefaultsExit(Sender);
end;

procedure TForm1.SgAppDefaultsSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
begin
  with SgAppDefaults do begin                // right col is for hide focus only
    if ACol = ColCount-1 then begin CanSelect:= false; exit end;
    SgEditorOff(SgAppDefaults);
    if (ACol < 1) or (ARow < 1) then exit;
    if ACol = 1 then begin
      if Cells[1, ARow] = 'ON' then
         Cells[1, ARow]:= 'OFF'
      else if Cells[1, ARow] = 'OFF' then
        Cells[1, ARow]:= 'ON'
      else if ARow in [defJoypadZaxisButton] then
        case Cells[1,defJoypadZaxisButton][1] of
          #82: Cells[1,defJoypadZaxisButton]:= 'U';                       // 'R'
          #85: Cells[1,defJoypadZaxisButton]:= 'V';                       // 'U'
          #86: Cells[1,defJoypadZaxisButton]:= 'Z';                       // 'V'
          #90: Cells[1,defJoypadZaxisButton]:= 'R';                       // 'Z'
          else Cells[1,defJoypadZaxisButton]:= 'R';
        end
      else if ARow in [defAtcToolReleaseCmd,
                       defAtcToolClampCmd] then
        SgEditorOn(SgAppDefaults,ACol,ARow,false,false)
      else SgEditorOn(SgAppDefaults,ACol,ARow,true,true);
    end;
  end;
  DefaultsGridListToJob;
end;

// #############################################################################
// ########################### Stringgrid Handler ##############################
// #############################################################################

//##### SgFiles ################################################################

procedure TForm1.SgFilesDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  aRect: TRect;
  aStr: String;
begin
  if aRow = 0 then with SgFiles,Canvas do begin
    Font.Style := [fsBold];
    TextRect(Rect, Rect.Left + 2, Rect.Top + 2, Cells[ACol, ARow]);
  end else with SgFiles,Canvas do begin
    Pen.Color := cl3Dlight;
    Font.Color:=clblack;

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
      8:  // Clear-"Button"
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

procedure TForm1.SgFilesExit(Sender: TObject);
begin
  with SgFiles do begin
    job.fileDelimStrings[Row-1]:= ShortString(Rows[Row].DelimitedText);
    SgEditorOff(SgFiles);
    Repaint;
    OpenFilesInGrid;
  end;
  SgFiles.EditorMode:= false;
end;

procedure TForm1.SgFilesKeyPress(Sender: TObject; var Key: Char);
begin
  if Key in [#10, #13, #27] then SgFilesExit(Sender);
end;

procedure TForm1.ComboBox1Exit(Sender: TObject);
begin
  with (sender as TComboBox),SgFiles do begin
    TComboBox(sender).hide;
    Options:= Options - [goEditing, goAlwaysShowEditor];
    if (ItemIndex >= 0) then
      if (Row > 0) and (Col= 1) then begin
        Cells[Col, Row] := IntToStr(ItemIndex-1); //  := Items[ItemIndex];
        job.fileDelimStrings[Row-1]:= ShortString(Rows[Row].DelimitedText);
        UnHilite;
        OpenFilesInGrid;
        Repaint;
      end;
  end;
end;

procedure TForm1.SgFilesSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
var R:      TRect;
    org:    TPoint;
    i:      Integer;
    my_ext: String;
begin
  with SgFiles do begin                      // right col is for hide focus only
    if ACol = ColCount-1 then begin CanSelect:= false; exit end;
    SgEditorOff(SgFiles);
//    if (ACol < 1) then exit;
    case ACol of
      0:
        begin
          UnHilite;
          OpenFileDialog.FilterIndex:= 0;
          if OpenFileDialog.Execute then begin
            Cells[0, ARow]:= OpenFileDialog.Filename;
            job.fileDelimStrings[ARow-1]:= ShortString(Rows[ARow].DelimitedText);
            UnHilite;
            my_ext:= AnsiUpperCase(ExtractFileExt(OpenFileDialog.Filename));
            if (my_ext = '.GBR') or (my_ext = '.GBL') or (my_ext = '.GTL') then begin
              sgFiles.Cells[0, ARow]:= '';
              ConvertedFileName:='';
              GerberFileName:= OpenFileDialog.Filename;
              GerberFileNumber:= ARow;
              FormGerber.ShowModal;
            end else
              OpenFilesInGrid;
          end;
        end;
      1:
        begin
          R := SgFiles.CellRect(ACol, ARow);
          org := self.ScreenToClient(self.ClientToScreen(R.TopLeft));
          perform( WM_CANCELMODE, 0, 0 ); // verhindert Mausaktion in Stringgrid
          with ComboBox1 do begin
            SetBounds(org.X-10, org.Y-2, R.Right-R.Left+10, Form1.Height);
            ItemIndex := Items.IndexOf('Pen '+SgFiles.Cells[ACol, ARow]);
            if SgFiles.Cells[ACol, ARow] = '-1' then ItemIndex:= 0;
            if SgFiles.Cells[ACol, ARow] = '10' then ItemIndex:= 11;
            Show;
            BringToFront;
            SetFocus;
            DroppedDown := true;
          end;
        end;
      2:
        begin
          if Cells[2, ARow] = '0°' then
            Cells[2, ARow]:= '90°'
          else if Cells[2, ARow] = '90°' then
            Cells[2, ARow]:= '180°'
          else if Cells[2, ARow] = '180°' then
            Cells[2, ARow]:= '270°'
          else
            Cells[2, ARow]:= '0°';
          Repaint;
          OpenFilesInGrid;
        end;
      3:
        begin
          if Cells[3, ARow] = 'ON' then
            Cells[3, ARow]:= 'OFF'
          else
            Cells[3, ARow]:= 'ON';
          Repaint;
          OpenFilesInGrid;
        end;
      4,5,6,7: SgEditorOn(SgFiles,ACol,Arow,true,true);
      8:
        begin
          UnHilite;
          Rows[ARow].DelimitedText:= '"",-1,0°,OFF,0,0,100,100,0,""';
          for i:= 0 to c_numOfPens do job.pens[i].used:= false;
          OpenFilesInGrid;
        end;
      9: SgEditorOn(SgFiles,ACol,ARow,false,false)
    end;
    job.fileDelimStrings[ARow-1]:= ShortString(Rows[ARow].DelimitedText);
  end;
end;


//#### MemoComment #############################################################
procedure TForm1.MemoCommentClick(Sender: TObject);
begin
//  TouchKeyboardOn(MemoComment,0,0,false,false);
end;

procedure TForm1.MemoCommentExit(Sender: TObject);
begin
//  TouchKeyboardOff;
end;




