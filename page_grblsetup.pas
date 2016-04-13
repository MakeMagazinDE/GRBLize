// #############################################################################
// ########################## GRBL DEFAULT BUTTONS #############################
// #############################################################################

procedure OpenCOMport;
begin
  com_isopen:= COMopen(com_name);
  Form1.Memo1.lines.add(com_name + ' connected - please wait...');
  if com_isopen then begin
    Form1.CheckBoxSim.Checked:= false;
    COMSetup(trim(deviceselectbox.EditBaudrate.Text));
    Form1.DeviceView.Text:= 'Serial port ' + com_name;
    sleep(2000);  // Arduino Startup Time
    grbl_is_connected:= grbl_checkResponse;
    Form1.BtnRefreshGrblSettingsClick(nil);
    Form1.Memo1.lines.add('Ready - Home Cycle pending');
  end;
end;

procedure OpenFTDIport;
var
  vid, pid: word;
  my_device: fDevice;
  my_description: String;
begin
// darf nicht in FormCreate stehen, wird dort durch Application.processmessages in mdelay() gestört
  if (ftdi_device_count > 0) then
    if ftdi.isPresentBySerial(ftdi_serial) then begin
      Form1.CheckBoxSim.Checked:= false;
      // Öffnet Device nach Seriennummer
      // Stellt sicher, dass das beim letzten Form1.Close
      // geöffnete Device auch weiterhin verfügbar ist.
      Form1.Memo1.lines.add(InitFTDIbySerial(ftdi_serial,deviceselectbox.EditBaudrate.Text)
        + ' - please wait...');
      ftdi.getDeviceInfo(my_device, pid, vid, my_description, ftdi_serial);
      Form1.DeviceView.Text:= ftdi_serial + ' - ' + my_description;
      ftdi_isopen:= true;
      sleep(500);  // Arduino Startup Time
      grbl_is_connected:= grbl_checkResponse;
      Form1.BtnRefreshGrblSettingsClick(nil);
      Form1.Memo1.lines.add('Ready - Home Cycle pending');
    end;
end;

procedure TForm1.BtnRescanClick(Sender: TObject);
// Auswahl des Frosches unter FTDI-Devices
var i : Integer; LV : TListItem;
  COMAvailableList: Array[0..31] of Integer;
begin
// Alle verfügbaren COM-Ports prüfen, Ergebnisse in Array speichern
  com_isopen:= false;
  ftdi_isopen:= false;
  grbl_is_connected:= false;
  HomingPerformed:= false;
  com_name:='';
  SetUpFTDI;
  if ftdi_device_count > 0 then begin
    deviceselectbox.ListView1.Items.clear;
    for i := 0 to ftdi_device_count - 1 do begin
      LV := deviceselectbox.ListView1.Items.Add;
      LV.Caption := 'Device '+IntToStr(i);
      LV.SubItems.Add(ftdi_sernum_arr[i]);
      LV.SubItems.Add(ftdi_desc_arr[i]);
    end;
    deviceselectbox.ListView1.Items[0].Selected := true;
  end;
  deviceselectbox.ComboBoxCOMport.Items.clear;
  deviceselectbox.ComboBoxCOMport.Items.add('none (FTDI direct)');
  for i := 0 to 31 do begin
    if CheckCom(i) = 0 then begin
      deviceselectbox.ComboBoxCOMport.Items.add('COM' + IntToSTr(i));
    end;
  end;
  deviceselectbox.ComboBoxCOMport.ItemIndex:= 0; // Auswahl erzwingen
  deviceselectbox.ShowModal;
  if not (deviceselectbox.ModalResult=MrOK) then
    exit;
  if (deviceselectbox.ComboBoxCOMport.ItemIndex > 0) then begin
    com_selected_port:= deviceselectbox.ComboBoxCOMport.ItemIndex - 1;
    com_name:= deviceselectbox.ComboBoxCOMport.Text;
    OpenCOMport;
  end else if (ftdi_device_count > 0) then begin
    ftdi_selected_device:= deviceselectbox.ListView1.itemindex;
    ftdi_serial:= ftdi_sernum_arr[ftdi_selected_device];
    OpenFTDIport;
    Form1.CheckBoxSim.Checked:= false;
  end;
  if ftdi_isopen or com_isopen then begin
    BtnConnect.Enabled:= false;
    BtnRescan.Enabled:= false;
  end;
  ResetToolflags;
  HomingPerformed:= false;
end;

procedure TForm1.BtnConnectClick(Sender: TObject);
begin
  if ftdi_was_open then
    OpenFTDIport
  else if com_was_open then
    OpenCOMport;
  if ftdi_isopen or com_isopen then begin
    BtnConnect.Enabled:= false;
    BtnRescan.Enabled:= false;
  end;
  ResetToolflags;
  HomingPerformed:= false;
end;

procedure TForm1.BtnCloseClick(Sender: TObject);
begin
  CheckBoxSim.enabled:= false;
  CheckBoxSim.Checked:= true;
  ftdi_was_open:= ftdi_isopen;
  com_was_open:= com_isopen;
  if com_isopen then
    COMClose;
  if ftdi_isopen then
    ftdi.closeDevice;
  ftdi_isopen:= false;
  com_isopen:= false;
  grbl_is_connected:= false;
  DeviceView.Text:= 'SIMULATION';
  HomingPerformed:= false;
  Memo1.lines.add('COM/USB disconnected');
  Form1.CheckBoxSim.Checked:= true;
  BtnConnect.Enabled:= com_was_open;
  if com_was_open then
    BtnConnect.SetFocus;
  BtnRescan.Enabled:= true;
  ResetToolFlags;
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
  if grbl_is_connected then
    with Form1.SgGrblSettings do begin
      LEDbusy.Checked:= true;
      grbl_checkResponse;
      DisableStatus;
      Rowcount:= 2;
      grbl_sendStr(#24, false);   // Reset CTRL-X
      repeat
        my_str:= grbl_receiveStr(100);  // Dummy
        Application.ProcessMessages;
      until pos('Grbl', my_str) > 0;
      grbl_wait_for_timeout(100);
      Rows[0].text:= my_str;

      grbl_sendStr('$$' + #13, false);
      while not (BtnCancel.Tag = 1) do begin
        my_str:= grbl_receiveStr(250);
        if my_str='ok' then
          break;
        if pos('[',my_str) > 0 then
          continue;
        Cells[0,RowCount-1]:= my_str;
        Cells[1,RowCount-1]:= setting_val_extr(my_str);
        Rowcount:= RowCount+1;
      end;

      if Cells[0,Rowcount-1] = '' then
        Rowcount:= RowCount-1;
      Cells[1,0]:= 'Value';
      FixedCols:= 1;
      FixedRows:= 1;
      bm_scroll.x:= 0;
      bm_scroll.y:= Form2.ClientHeight - Form2.DrawingBox.Height;
      EnableStatus;  // automatische Upates freischalten
    end;
  LEDbusy.Checked:= false;
end;


procedure TForm1.BtnSendGrblSettingsClick(Sender: TObject);
var i : Integer;
  my_str0, my_str1: String;

begin
  if grbl_is_connected then begin
    LEDbusy.Checked:= true;
    grbl_checkResponse;
    DisableStatus;
    with SgGrblSettings do begin
      Progressbar1.max:= RowCount;
      if (RowCount < 3) then begin
        showmessage('GRBL settings are empty.');
        LEDbusy.Checked:= false;
        exit;
      end else for i:= 1 to Rowcount-1 do begin
        if (BtnCancel.Tag = 1) then
          break;
        if Cells[0,i] = '' then
          continue;
        my_str0:= Cells[0,i];
        my_str0:= copy(my_str0, 0, pos('=', my_str0));
        my_str1:= Cells[1,i];
        Progressbar1.Position:= i;
        grbl_sendStr(my_str0+my_str1+#13, true);
        mdelay(25);
      end;
    end;
    Progressbar1.Position:= 0;
    BtnRefreshGrblSettingsClick(Sender);
    EnableStatus;  // automatische Upates freischalten
  end;
  LEDbusy.Checked:= false;
end;

procedure LoadStringGrid(aGrid: TStringGrid; const my_fileName: string);
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
    LoadStringGrid(SgGrblSettings,OpenFileDialog.filename);
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

