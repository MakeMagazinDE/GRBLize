
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
  job.pens[tool_idx].diameter:= 3.175;
  job.pens[tool_idx].shape:= contour;
  job.pens[tool_idx].tipdia:= 0.2;
  job.pens[tool_idx].z_end:= 0.2;
  job.pens[tool_idx].tooltip:= 1;
  job.pens[tool_idx].tooltip:= 1;
  job.pens[tool_idx].speed:= 500;
  job.pens[tool_idx].force_closed:= true;
end;

procedure ProveNewGBR(FileName:string;i: integer);
var GbrName, CmdStr: string;
begin
   GbrName := ChangeFileExt(FileName, '.gbr');              // Quelle ist *.gbr?
   if not FileExists(GbrName) then begin
     GbrName := ChangeFileExt(FileName, '.gbl');            // Quelle ist *.gbl?
     if not FileExists(GbrName) then exit;// Quelle nicht gefunden, nur NC laden
   end;
                // TestS enthält nun den Namen der ursprünglichen Gerber-Datei!!
   if FileAge(FileName) < FileAge(GbrName) then
     CmdStr := CallPcb2Gcode(GbrName,
                             pos('front',GbrName) > 0,
                             FileParamArray[i-1].user1,
                             '500');
end;

Procedure OpenFilesInGrid;
var
  i, pen_override: Integer;
  my_path, my_ext: String;
  use_excellon: Boolean;
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
      FileParamArray[i-1].scale:= StrToFloatDef(Cells[6, i], 100.0);
      FileParamArray[i-1].user1:= StrToFloatDef(Cells[7, i], 0.2);

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
        Cells[8, i]:= 'Drill'; // Replace Pen
        use_excellon:= job.use_excellon_dia and (pen_override < 0);
        drill_fileload(my_path, i-1, StrToIntDef(Cells[1, i], -1), use_excellon);
      end else if (my_ext = '.HPGL') or (my_ext = '.HPG') or (my_ext = '.PLT') or (my_ext = '.PEN') then begin
        Cells[8, i]:= 'Plot'; // Replace Pen
        hpgl_fileload(my_path, i-1, StrToIntDef(Cells[1, i], -1))
      end else if (my_ext = '.NC') or (my_ext = '.NGC') or (my_ext = '.TAP') or (my_ext = '.CNC') then begin
        Cells[8, i]:= 'GCode'; // Remark
        gcode_fileload(my_path, i-1, -1);
      end else if (my_ext = '.NCF') then begin
        ProveNewGBR(my_path,i);
        Cells[8, i]:= 'PCB top'; // Remark
        Cells[1, i]:= '8'; // Replace Pen
        gcode_fileload(my_path, i-1, 8);
        SetPCBmillTool(8);
      end else if (my_ext = '.NCB') then begin
        ProveNewGBR(my_path,i);
        Cells[8, i]:= 'PCB botm'; // Remark
        Cells[1, i]:= '9'; // Replace Pen
        gcode_fileload(my_path, i-1, 9);
        SetPCBmillTool(9);
        job.pens[9].force_closed:= true;
      end else if (my_ext = '.SVG') then begin
        Cells[8, i]:= 'SVG'; // Remark
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
  NeedsRedraw:= true;

  Form1.SgPens.Repaint;
  GLSneedsATCupdateTimeout:= 1;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Mill/drill files (re)loaded.');
end;

Procedure OpenJobFile;
var i, my_date: integer;
    my_path:    String;

  ///// load Job-File in Windows-Ini-Format ////////////////////////////////////
  procedure LoadIniFormat;
  var Ini:                  TIniFile;
      i, j, k, LengthFinal: integer;
      Section, Name:        string;
      sl_p:                 TstringList;
  begin
    Ini := TIniFile.Create(JobSettingsPath);                        // open file

// offen: - Fehlerbehandlung bei Files, wenn etwas nicht gesetzt ist
    try
{
  // load defaults first, because size of table influence the settings of blocks
    s:= sl.indexof('#Defaults');
    if s >= 0 then begin
      inc(s);
      my_row:= 1;
      for i := s to sl.Count-1 do begin
        if AnsiContainsStr(sl.strings[i],'#') then
          break;
        Form1.SgJobDefaults.Rowcount:= my_row+1;
        Form1.SgJobDefaults.Rows[my_row].DelimitedText:= sl.Strings[i];
        inc(my_row);
      end;
      Form1.SgJobDefaults.Repaint;
    end;
}
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
{
    s:= sl.indexof('#Files');
    if s >= 0 then begin
      inc(s);
      my_row:= 1;
      for i := s to sl.Count-1 do begin
        if AnsiContainsStr(sl.strings[i],'#') then
          break;
        Form1.SgFiles.Rows[my_row].DelimitedText:= sl.Strings[i];
        inc(my_row);
      end;
      Form1.SgFiles.Repaint;
      OpenFilesInGrid;
    end;
}
      with Form1.SgFiles do begin
        for i:= 1 to c_numOfFiles do begin                          // files table
          Section:= 'File' + IntToStr(i);
          Cells[0,i]:= Ini.ReadString(Section, 'Name',    Cells[0,i]);
          Cells[1,i]:= Ini.ReadString(Section, 'Replace', Cells[1,i]);
          Cells[2,i]:= Ini.ReadString(Section, 'Rotate',  Cells[2,i]);
          Cells[3,i]:= Ini.ReadString(Section, 'Mirror',  Cells[3,i]);
          Cells[4,i]:= Ini.ReadString(Section, 'Xofs',    Cells[4,i]);
          Cells[5,i]:= Ini.ReadString(Section, 'Yofs',    Cells[5,i]);
          Cells[6,i]:= Ini.ReadString(Section, 'Scale',   Cells[6,i]);
          Cells[7,i]:= Ini.ReadString(Section, 'User1',   Cells[7,i]);
          Cells[8,i]:= Ini.ReadString(Section, 'Remark',  Cells[8,i]);
          Cells[9,i]:= Ini.ReadString(Section, 'Date',    Cells[9,i]);
        end;
        Repaint;
        OpenFilesInGrid;
      end;

{
    s:= sl.indexof('#Pens');
    if s >= 0 then begin
      inc(s);
      my_row:= 1;
      for i := s to sl.Count-1 do begin
        if AnsiContainsStr(sl.strings[i],'#') then
          break;
        Form1.SgPens.Rows[my_row].DelimitedText:= sl.Strings[i];
        inc(my_row);
      end;
      Form1.SgPens.Repaint;
      PenGridListToJob;
      apply_pen_change;
    end;
}
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
          Cells[13,i]:= Ini.ReadString(Section, 'Blade',    Cells[13,i]);
        end;
        Repaint;
        PenGridListToJob;
        apply_pen_change;
      end;

// wird hier nicht nur "Enable" gebraucht? Alles andere sollte doch nicht änderbar sein!!!

{
    s:= sl.indexof('#Blocks');
    if s >= 0 then begin
      inc(s);
      my_row:= 1;
      my_len:= length(final_array);
      for i := s to sl.Count-1 do begin
        if AnsiContainsStr(sl.strings[i],'#') then
          break;
        if my_row <= my_len then begin
          Form1.SgBlocks.Rowcount:= my_row+1;
          Form1.SgBlocks.Rows[my_row].DelimitedText:= sl.Strings[i];
          for j:= 0 to high(ShapeArray) do
            if Form1.SgBlocks.Cells[4,my_row] = ShapeArray[ord(j)] then
              final_array[my_row-1].shape:= Tshape(j);
          final_array[my_row-1].enable:= Form1.SgBlocks.Cells[2,my_row] = 'ON';
          enable_all_millings(final_array[my_row-1], final_array[my_row-1].enable);
          inc(my_row);
        end;
      end;
      Form1.SgBlocks.Repaint;
    end;
}
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

{
    s:= sl.indexof('#PathEnables');
    if s >= 0 then begin
      sl_p:= Tstringlist.Create;
      inc(s);
      j:= 0;
      for i := s to sl.Count-1 do begin
        if AnsiContainsStr(sl.strings[i],'#') then
          break;
        sl_p.Clear;
        sl_p.CommaText:= sl.strings[i];
        if j <= high(final_array) then
          if (sl_p.Count-1) <= high(final_array[j].milling_enables) then begin
            for k := 0 to sl_p.Count-1 do
              if (j <= high(final_array)) and (k <= high(final_array[j].milling_enables)) then
                final_array[j].milling_enables[k]:= sl_p[k] = '1';
            inc(j);
          end;
      end;
      sl_p.Free;
    end;
}

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
{
    s:= sl.indexof('#Comment');
    if s >= 0 then begin
      inc(s);
      Form1.MemoComment.Clear;
      for i := s to sl.Count-1 do begin
        if AnsiContainsStr(sl.strings[i],'#') then
          break;
        Form1.MemoComment.Lines.Add(sl.Strings[i]);
      end;
    end;
}
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
  // sind Files noch aktuell?
  for i:= 1 to c_numOfFiles +1 do begin
    my_path:= Form1.SgFiles.Cells[0,i];
    if (length(my_path) < 4) or (not FileExists(my_path)) then
      continue;
    my_date:= FileAge(Form1.SgFiles.Cells[0,i]);
    if my_date <> StrToIntDef(Form1.SgFiles.Cells[9,i],0) then begin
      PlaySound('SYSTEMHAND', 0, SND_ASYNC);
      Form1.Memo1.lines.add('');
      Form1.Memo1.lines.add('WARNING: One or more mill/drill file(s)');
      Form1.Memo1.lines.add('have been changed since last job was saved.');
      Form1.Memo1.lines.add('All mill paths will be rebuild and enabled!');
      OpenFilesInGrid;
      break;
    end;
  end;
  for i := 0 to high(final_array) do
    final_array[i].enable:= is_any_milling_enabled(final_array[i]);
  ListBlocks;
  NeedsRedraw:= true;
end;

procedure SaveJob;
var i, p, my_date:   Integer;
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
      my_filename:= Form1.SgFiles.Cells[0,i];
      if (length(my_filename) <= 3) then continue;                 // line empty
      if FileExists(my_filename)                             // save change date
        then my_date:= FileAge(Form1.SgFiles.Cells[0,i])
        else my_date:= 0;
      Ini.WriteString(Section, 'Name',    Form1.SgFiles.Cells[0,i]);
      Ini.WriteString(Section, 'Date',    IntToStr(my_date));
      Ini.WriteString(Section, 'Replace', Form1.SgFiles.Cells[1,i]);
      Ini.WriteString(Section, 'Rotate',  Form1.SgFiles.Cells[2,i]);
      Ini.WriteString(Section, 'Mirror',  Form1.SgFiles.Cells[3,i]);
      Ini.WriteString(Section, 'Xofs',    Form1.SgFiles.Cells[4,i]);
      Ini.WriteString(Section, 'Yofs',    Form1.SgFiles.Cells[5,i]);
      Ini.WriteString(Section, 'Scale',   Form1.SgFiles.Cells[6,i]);
      Ini.WriteString(Section, 'User1',   Form1.SgFiles.Cells[7,i]);
      Ini.WriteString(Section, 'Remark',  Form1.SgFiles.Cells[8,i]);
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
  with SgJobDefaults do
    Options:= Options - [goEditing, goAlwaysShowEditor];
  OpenFilesInGrid;
  NeedsRedraw:= true;
  ListBlocks;
end;

procedure TForm1.SgJobDefaultsKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) or (Key = #10) then begin
    SgJobDefaultsExit(Sender);;
  end;
end;


procedure TForm1.SgJobDefaultsMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
// wird vor SgJobDefaultsClick aufgerufen!
var
  my_row, my_col, i: integer;
begin
  SgJobDefaults.MouseToCell( X,Y, my_col, my_row );
  if (my_row < 1) or (my_col < 1) then
    exit;
  with SgJobDefaults do begin
    Options:= Options - [goEditing, goAlwaysShowEditor];
    if my_Col = 1 then begin
      if Cells[1, my_row] = 'ON' then begin
        Cells[1, my_row]:= 'OFF';
        OpenFilesInGrid;
      end else if Cells[1, my_row] = 'OFF' then begin
        Cells[1, my_row]:= 'ON';
      end else if (my_row = 4) then begin                            // Material
        for i:= 0 to PopupMenuMaterial.Items.Count - 1 do           // set focus
          PopupMenuMaterial.Items[i].Checked:= job.Material = i;
                                                                   // start menu
        PopupMenuMaterial.Popup(X+left+Form1.left, Y+ top+Form1.top);
      end else
        Options:= Options + [goEditing, goAlwaysShowEditor];
    end;
  end;
end;

procedure TForm1.SgJobDefaultsClick(Sender: TObject);
begin
  with SgJobDefaults do
    Options:= Options - [goEditing, goAlwaysShowEditor];
//  if SgJobDefaults.Row > 7 then
              // adapt parameters also after leaving cell by click to other cell
  OpenFilesInGrid;
  NeedsRedraw:= true;
  ListBlocks;
end;

// #############################################################################
// GRBLize Defaults auf Defaults-Seite!
// #############################################################################

procedure TForm1.SgAppDefaultsExit(Sender: TObject);
begin
  with SgAppDefaults do
    Options:= Options - [goEditing, goAlwaysShowEditor];
  DefaultsGridListToJob;
end;


procedure TForm1.SgAppDefaultsKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) or (Key = #10) then begin
    SgAppDefaultsExit(Sender);;
  end;
end;

procedure TForm1.SgAppDefaultsDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  aRect: TRect;
  aStr: String;

begin
//  Rect.Left:= Rect.Left-4; // Workaround für XE8-Darstellung
  aStr:= SgAppDefaults.Cells[ACol, ARow];
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
end;

procedure TForm1.SgAppDefaultsMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var pt: TPoint;
  my_row, my_col: integer;
begin
  SgAppDefaults.MouseToCell( X,Y, my_col, my_row );
  if (my_row < 1) or (my_col < 1) then
    exit;
  pt.X:= X;
  pt.Y:= Y;
  with SgAppDefaults do begin
    Options:= Options - [goEditing];
    if Col = 1 then begin
      if Cells[1, my_Row] = 'ON' then
         Cells[1, my_Row]:= 'OFF'
      else if Cells[1, my_Row] = 'OFF' then begin
        Cells[1, my_Row]:= 'ON';
      end else
        Options:= Options + [goEditing, goAlwaysShowEditor];
    end;
  end;
  DefaultsGridListToJob;
end;

procedure TForm1.SgAppDefaultsClick(Sender: TObject);
begin
  with SgAppDefaults do
    Options:= Options - [goEditing, goAlwaysShowEditor];
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
//  Rect.Left:= Rect.Left-4; // Workaround für XE8-Darstellung
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
          job.fileDelimStrings[Row-1]:= ShortString(Rows[Row].DelimitedText);
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
  my_row, my_col: integer;
  my_ext: String;
begin
  SgFiles.MouseToCell( X,Y, my_col, my_row );
  if (my_row < 1) then
    exit;
  with SgFiles do begin
    Options:= Options - [goEditing, goAlwaysShowEditor];
    case Col of
      0:
        begin
          UnHilite;
          OpenFileDialog.FilterIndex:= 0;
          if OpenFileDialog.Execute then begin
            Cells[0, Row]:= OpenFileDialog.Filename;
            job.fileDelimStrings[Row-1]:= ShortString(Rows[Row].DelimitedText);
            UnHilite;
            my_ext:= AnsiUpperCase(ExtractFileExt(OpenFileDialog.Filename));
            if (my_ext = '.GBR') or (my_ext = '.GBL') or (my_ext = '.GTL') then begin
              sgFiles.Cells[0, Row]:= '';
              ConvertedFileName:='';
              GerberFileName:= OpenFileDialog.Filename;
              GerberFileNumber:= Row;
              FormGerber.ShowModal;
            end else
              OpenFilesInGrid;
          end;
        end;
      1:
        begin
          R := SgFiles.CellRect(my_Col, my_Row);
          org := self.ScreenToClient(self.ClientToScreen(R.TopLeft));
          perform( WM_CANCELMODE, 0, 0 ); // verhindert Mausaktion in Stringgrid
          with ComboBox1 do begin
            SetBounds(org.X-10, org.Y-2, R.Right-R.Left+10, Form1.Height);
            ItemIndex := Items.IndexOf('Pen '+SgFiles.Cells[my_Col, my_Row]);
            if ItemIndex < 0 then
              ItemIndex:= 1;
            Show;
            BringToFront;
            SetFocus;
            DroppedDown := true;
          end;
        end;
      2:
        begin
          if Cells[2, my_Row] = '0°' then
            Cells[2, my_Row]:= '90°'
          else if Cells[2, my_Row] = '90°' then
            Cells[2, my_Row]:= '180°'
          else if Cells[2, my_Row] = '180°' then
            Cells[2, my_Row]:= '270°'
          else
            Cells[2, my_Row]:= '0°';
          Repaint;
          OpenFilesInGrid;
        end;
      3:
        begin
          if Cells[3, my_Row] = 'ON' then
            Cells[3, my_Row]:= 'OFF'
          else
            Cells[3, my_Row]:= 'ON';
          Repaint;
          OpenFilesInGrid;
        end;
      4,5,6, 8:
        begin
//          Options:= Options + [goEditing, goAlwaysShowEditor];
          Options:= Options + [goEditing, goAlwaysShowEditor];
        end;
      7:
        begin
          UnHilite;
          Cells[0, my_Row]:= '';
          Cells[1, my_Row]:= '-1';
          Cells[2, my_Row]:= '0°';
          Cells[3, my_Row]:= 'OFF';
          Cells[8, my_Row]:= '';
          for i:= 0 to c_numOfPens do
            job.pens[i].used:= false;
          OpenFilesInGrid;
        end;
     end;
    job.fileDelimStrings[my_Row-1]:= ShortString(Rows[my_Row].DelimitedText);
  end;
end;

procedure TForm1.SgFilesKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) or (Key = #10) then
    with SgFiles do begin
      job.fileDelimStrings[Row-1]:= ShortString(Rows[Row].DelimitedText);
      Repaint;
      OpenFilesInGrid;
    end;
end;

procedure TForm1.SgFilesExit(Sender: TObject);
begin

end;

procedure TForm1.SgFilesClick(Sender: TObject);
begin
  SgFiles.Options:= SgFiles.Options - [goEditing, goAlwaysShowEditor];
end;


