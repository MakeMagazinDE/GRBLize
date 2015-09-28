// #############################################################################
// ######################## FTDI OPEN/CLOSE BUTTONS ############################
// ########################## GRBL DEFAULT BUTTONS #############################
// #############################################################################


procedure TForm1.BtnRescanClick(Sender: TObject);
// Auswahl des Frosches unter FTDI-Devices
var i : Integer; LV : TListItem;
begin
// Alle verfügbaren COM-Ports prüfen, Ergebnisse in Array speichern
  deviceselectbox.ListView1.Items.clear;
  SetUpFTDI;
  if ftdi_device_count > 0 then
    for i := 0 to ftdi_device_count - 1 do begin
      LV := deviceselectbox.ListView1.Items.Add;
      LV.Caption := 'Device '+IntToStr(i);
      LV.SubItems.Add(ftdi_sernum_arr[i]);
      LV.SubItems.Add(ftdi_desc_arr[i]);
    end
  else
    exit;
  deviceselectbox.ListView1.Items[0].Selected := true;
  deviceselectbox.ShowModal;
  if (deviceselectbox.ModalResult=MrOK) and (ftdi_device_count > 0) then begin
    ftdi_selected_device:= deviceselectbox.ListView1.itemindex;
    Memo1.lines.add('// ' + InitFTDI(ftdi_selected_device));
    if ftdi_isopen then begin
      BtnRescan.Visible:= false;
      BtnClose.Visible:= true;
      ftdi_serial:= ftdi_sernum_arr[ftdi_selected_device];
      DeviceView.Text:= ftdi_serial + ' - ' + ftdi_desc_arr[ftdi_selected_device];
      CheckBoxSim.enabled:= true;
      CheckBoxSim.Checked:= false;
      CheckResponse;
      EnableNotHomedButtons;
      Form1.BtnRefreshGrblSettingsClick(nil);
    end;
  end;
end;

procedure TForm1.BtnCloseClick(Sender: TObject);
begin
  CheckBoxSim.enabled:= false;
  CheckBoxSim.Checked:= true;
  CancelGrbl:= true;
  if ftdi_isopen then
    ftdi.closeDevice;
  ftdi_isopen:= false;
  BtnRescan.Visible:= true;
  BtnClose.Visible:= false;
  DeviceView.Text:= '(not selected)';
  DisableButtons;
  HomingPerformed:= false;
end;

// #############################################################################
// ########################## GRBL DEFAULT BUTTONS #############################
// #############################################################################

procedure TForm1.SgGrblSettingsDrawCell(Sender: TObject; ACol,
  ARow: Integer; Rect: TRect; State: TGridDrawState);
begin
  Rect.Left:= Rect.Left-4; // Workaround für XE8-Darstellung
  if aRow = 0 then with (Sender as TStringGrid),Canvas do begin
    Font.Style := [fsBold];
    TextRect(Rect, Rect.Left + 2, Rect.Top + 2, Cells[ACol, ARow]);
  end;
end;

function setting_val_extr(my_Str: String):String;
// Holt Wert aus "$x=1234.56 (blabla)"-Antwort
var
  my_pos1, my_pos2: Integer;
begin
  my_pos1:= Pos('=', my_str);
  my_pos2:= Pos(' ', my_str);
  if my_pos2 <= 0 then my_pos2:= length(my_Str)-1 else dec(my_pos2);
  result:= copy(my_str, my_pos1+1, my_pos2-my_pos1);
end;

procedure TForm1.BtnRefreshGrblSettingsClick(Sender: TObject);
var
  my_str: String;
begin
  CancelGrbl:= false;
  CancelWait:= false;
  if ftdi_isopen then
    with Form1.SgGrblSettings do begin
      LEDbusy.Checked:= true;
      DisableTimerStatus;
      mdelay(120);
      grbl_resync;
      Rowcount:= 2;
      grbl_sendStr(#24, false);   // Reset CTRL-X
      my_str:= grbl_receiveStr(500);
      my_str:= grbl_receiveStr(500);
      Rows[0].text:= my_str;

      grbl_sendStr('$$' + #13, false);
      while not CancelGrbl do begin
        my_str:= grbl_receiveStr(150);
        if my_str='ok' then
          break;
        Cells[0,RowCount-1]:= my_str;
        Cells[1,RowCount-1]:= setting_val_extr(my_str);
        Rowcount:= RowCount+1;
      end;

      if Cells[0,Rowcount-1] = '' then
        Rowcount:= RowCount-1;
      Cells[1,0]:= 'Value';
      FixedCols:= 1;
      FixedRows:= 1;
      TimerStatus.Enabled:= not Form1.CheckBoxSim.checked;
      Form1.BtnZeroXClick(nil);
      Form1.BtnZeroYClick(nil);
      Form1.BtnZeroZClick(nil);
      bm_scroll.x:= 0;
      bm_scroll.y:= Form2.ClientHeight - Form2.DrawingBox.Height;
      LEDbusy.Checked:= false;
   end;
end;


procedure TForm1.BtnSendGrblSettingsClick(Sender: TObject);
var i : Integer;
  my_str0, my_str1: String;

begin
  CancelGrbl:= false;
  CancelWait:= false;
  if ftdi_isopen then begin
    LEDbusy.Checked:= true;    // wird in BtnRefreshGrblSettingsClick zurückgesetzt
    TimerStatus.Enabled:= false;
    mdelay(120);
    grbl_resync;
    with SgGrblSettings do begin
      if RowCount < 3 then
        exit;
      if not grbl_resync then
        showmessage('GRBL Resync failed on Send Settings!')
      else for i:= 1 to Rowcount-1 do begin
        if CancelGrbl then
          break;
        if Cells[0,i] = '' then
          continue;
        my_str0:= Cells[0,i];
        my_str0:= copy(my_str0, 0, pos('=', my_str0));
        my_str1:= Cells[1,i];
        if my_str1 <> setting_val_extr(Cells[0,i]) then begin
          grbl_sendStr(my_str0+my_str1+#13, true);
        end;
      end;
    end;
    BtnRefreshGrblSettingsClick(Sender);
  end;
end;

procedure PopulateStringGrid(aGrid: TStringGrid; const my_fileName: string);
var
  my_StringList, my_Line: TStringList;
  aCol, aRow: Integer;
begin
  aGrid.RowCount := 2; //clear any previous data
  my_StringList := TStringList.Create;
  try
    my_Line := TStringList.Create;
    try
      my_StringList.LoadFromFile(my_fileName);
      aGrid.RowCount := my_StringList.Count;
      for aRow := 0 to my_StringList.Count-1 do
      begin
        my_Line.CommaText := my_StringList[aRow];
        for aCol := 0 to aGrid.ColCount-1 do
          if aCol < my_Line.Count then
            aGrid.Cells[aCol, aRow] := my_Line[aCol]
          else
            aGrid.Cells[aCol, aRow] := '0';
      end;
    finally
      my_Line.Free;
    end;
  finally
    my_StringList.Free;
  end;
end;

procedure TForm1.BtnLoadGrblSetupClick(Sender: TObject);
begin
  OpenFileDialog.FilterIndex:= 4;
  if OpenFileDialog.Execute then
    PopulateStringGrid(SgGrblSettings,OpenFileDialog.filename);
end;

procedure TForm1.BtnSaveGrblSetupClick(Sender: TObject);
var
  my_StringList: TStringList;
  aRow: Integer;
  my_str: String;
begin
  SaveJobDialog.FilterIndex:= 2;
  if SaveJobDialog.Execute then begin
    my_StringList := TStringList.Create;
    try
      for aRow := 0 to SgGrblSettings.Rowcount-1 do begin
        my_str := '"' + SgGrblSettings.Cells[0, aRow]
          + '","' + SgGrblSettings.Cells[1, aRow] +'"';
        my_StringList.Add(my_str);
      end;
      my_StringList.SaveToFile(SaveJobDialog.fileName);
    finally
      my_StringList.Free;
    end;
  end;
end;

// #############################################################################
// #############################################################################

