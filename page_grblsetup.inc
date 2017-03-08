// #############################################################################
// ########################## GRBL DEFAULT BUTTONS #############################
// #############################################################################

procedure OpenCOMport;
begin
  com_isopen:= COMopen(com_name);
  Form1.Memo1.lines.add(com_name + ' connected - please wait...');
  if com_isopen then begin
    COMSetup(trim(deviceselectbox.EditBaudrate.Text));
    Form1.DeviceView.Text:= 'Serial port ' + com_name;
    Form1.DeviceView.Font.Color:= clWindowText;
    Form1.DeviceView.Font.Style:= [];
    sleep(2000);  // Arduino Startup Time
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
      // Öffnet Device nach Seriennummer
      // Stellt sicher, dass das beim letzten Form1.Close
      // geöffnete Device auch weiterhin verfügbar ist.
      Form1.Memo1.lines.add(InitFTDIbySerial(ftdi_serial,deviceselectbox.EditBaudrate.Text)
        + ' - please wait...');
      ftdi.getDeviceInfo(my_device, pid, vid, my_description, ftdi_serial);
      Form1.DeviceView.Text:= ftdi_serial + ' - ' + my_description;
      Form1.DeviceView.Font.Color:= clWindowText;
      Form1.DeviceView.Font.Style:= [];
      ftdi_isopen:= true;
      sleep(500);  // Arduino Startup Time
    end;
end;

procedure PortOpenedCheck;
begin
  if ftdi_isopen or com_isopen then
    grbl_is_connected:= grbl_checkResponse;
  if grbl_is_connected then begin
    Form1.CheckBoxSim.enabled:= true;
    Form1.CheckBoxSim.Checked:= false;
    Form1.BtnConnect.Enabled:= false;
    Form1.BtnRescan.Enabled:= false;
    Form1.BtnRefreshGrblSettingsClick(nil);
  end;
  ResetToolflags;
end;

procedure TForm1.BtnRescanClick(Sender: TObject);
// Auswahl des Frosches unter FTDI-Devices
var i : Integer; LV : TListItem;
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
  if (deviceselectbox.ModalResult=MrOK) then begin
    if (deviceselectbox.ComboBoxCOMport.ItemIndex > 0) then begin
      com_selected_port:= deviceselectbox.ComboBoxCOMport.ItemIndex - 1;
      com_name:= deviceselectbox.ComboBoxCOMport.Text;
      OpenCOMport;
    end else if (ftdi_device_count > 0) then begin
      ftdi_selected_device:= deviceselectbox.ListView1.itemindex;
      ftdi_serial:= ftdi_sernum_arr[ftdi_selected_device];
      OpenFTDIport;
    end;
  end;
  PortOpenedCheck;
end;

procedure TForm1.BtnConnectClick(Sender: TObject);
begin
  if ftdi_was_open then
    OpenFTDIport
  else if com_was_open then
    OpenCOMport;
  PortOpenedCheck;
end;

procedure TForm1.BtnCloseClick(Sender: TObject);
begin
  ftdi_was_open:= ftdi_isopen;
  com_was_open:= com_isopen;
  if com_isopen then
    COMClose;
  if ftdi_isopen then
    ftdi.closeDevice;
  ftdi_isopen:= false;
  com_isopen:= false;
  if grbl_is_connected or com_was_open then begin
    BtnConnect.Enabled:= true;
  end;
  grbl_is_connected:= false;
  DeviceView.Text:= 'SIMULATION';
  DeviceView.Font.Color:= clred;
  DeviceView.Font.Style:= [fsbold];

  HomingPerformed:= false;
  Memo1.lines.add('COM/USB disconnected');
  CheckBoxSim.Checked:= true;
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
  if my_pos2 <= 0 then
    my_pos2:= length(my_Str)
  else
    dec(my_pos2);
  result:= copy(my_str, my_pos1+1, my_pos2-my_pos1);
end;

procedure TForm1.BtnRefreshGrblSettingsClick(Sender: TObject);
var
  my_str, my_str0: String;
begin
  if isGrblActive then
    with Form1.SgGrblSettings do begin
      DisableStatus;
      Rowcount:= 2;
      LEDbusy.Checked:= true;
      grbl_wait_for_timeout(100);

      Rows[0].text:= my_str;

      grbl_sendStr('$$' + #13, false);
      while not isWaitExit do begin
        LEDbusy.Checked:= true;
        my_str:= grbl_receiveStr(250);
        if my_str='ok' then
          break;
        if pos('[',my_str) > 0 then
          continue;
{$IFDEF GRBL_11}
        my_str0:= copy(my_str, 0, pos('=', my_str));
        Cells[0,RowCount-1]:= my_str0 + SettingCodes_11[RowCount-2];
{$ELSE}
        Cells[0,RowCount-1]:= my_str;
{$ENDIF}
        Cells[1,RowCount-1]:= setting_val_extr(my_str);
        if pos('$130', my_str) > 0 then begin
          job.table_x:= StrDotToFloat(setting_val_extr(my_str));
          Form1.SgAppDefaults.Rows[26].DelimitedText:=
            '"Max. Travel X (from GRBL)",'+FormatFloat('0.0',job.table_x);
        end;
        if pos('$131', my_str) > 0 then begin
          job.table_y:= StrDotToFloat(setting_val_extr(my_str));
          Form1.SgAppDefaults.Rows[27].DelimitedText:=
            '"Max. Travel Y (from GRBL)",'+FormatFloat('0.0',job.table_y);
        end;
        if pos('$132', my_str) > 0 then begin
          job.table_z:= StrDotToFloat(setting_val_extr(my_str));
          Form1.SgAppDefaults.Rows[28].DelimitedText:=
            '"Max. Travel Z (from GRBL)",'+FormatFloat('0.0',job.table_z);
        end;

        Rowcount:= RowCount+1;
      end;

      if Cells[0,Rowcount-1] = '' then
        Rowcount:= RowCount-1;
      Cells[0,0]:= 'Parameter';
      Cells[1,0]:= 'Value';
      FixedCols:= 1;
      FixedRows:= 1;
      bm_scroll.x:= 0;
      bm_scroll.y:= Form2.ClientHeight - Form2.DrawingBox.Height;
      LEDbusy.Checked:= false;
      EnableStatus;  // automatische Upates freischalten
    end;
  ResetToolflags;
end;


procedure TForm1.BtnSendGrblSettingsClick(Sender: TObject);
var i : Integer;
  my_str0, my_str1: String;

begin
  if isGrblActive then begin
    DisableStatus;
    grbl_checkResponse;
    with SgGrblSettings do begin
      Progressbar1.max:= RowCount;
      if (RowCount < 3) then begin
        showmessage('GRBL settings are empty.');
        exit;
      end else for i:= 1 to Rowcount-1 do begin
        LEDbusy.Checked:= true;
        if isWaitExit then
          break;
        if Cells[0,i] = '' then
          continue;
        my_str0:= Cells[0,i];
        my_str0:= copy(my_str0, 0, pos('=', my_str0));
        my_str1:= Cells[1,i];
        Progressbar1.Position:= i;
        grbl_sendStr(my_str0+my_str1+#13, true);
        mdelay(50);
      end;
    end;
    Progressbar1.Position:= 0;
    LEDbusy.Checked:= false;
    BtnRefreshGrblSettingsClick(Sender);
    EnableStatus;  // automatische Upates freischalten
  end;
  ResetToolflags;
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
  OpenFileDialog.FilterIndex:= 3;
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


procedure TForm1.BtnSetParkClick(Sender: TObject);
var my_btn: Integer;
begin
  if isSimActive then
    exit;
  my_btn:= MessageDlg('This will set PARK postion'
    + #13 + ' to current machine position'
    + #13 + 'in GRBLize Application defaults. Proceed?', mtConfirmation, mbOKCancel, 0);
  if my_btn = mrCancel then
    exit;

  job.park_x:= grbl_mpos.x;
  job.park_y:= grbl_mpos.y;
  job.park_z:= grbl_mpos.z;
  with Form1.SgAppDefaults do begin
    Cells[1,6]:= FormatFloat('0.00', job.park_x);
    Cells[1,7]:= FormatFloat('0.00', job.park_y);
    Cells[1,8]:= FormatFloat('0.00', job.park_z);
  end;
  SaveIniFile;
end;

procedure TForm1.BtnSetFix1Click(Sender: TObject);
// Fixture-Position in Tabelle auf aktuelle Maschinenposition setzen
var my_btn: Integer;
begin
  if isSimActive then
    exit;
  my_btn:= MessageDlg('This will set FIXTURE 1 postion'
    + #13 + ' to current machine position'
    + #13 + 'in GRBLize Application defaults. Proceed?', mtConfirmation, mbOKCancel, 0);
  if my_btn = mrCancel then
    exit;
  job.fix1_x:= grbl_mpos.x;
  job.fix1_y:= grbl_mpos.y;
  job.fix1_z:= grbl_mpos.z;
  with Form1.SgAppDefaults do begin
    Cells[1,29]:= FormatFloat('0.00', job.fix1_x);
    Cells[1,30]:= FormatFloat('0.00', job.fix1_y);
    Cells[1,31]:= FormatFloat('0.00', job.fix1_z);
  end;
  SaveIniFile;
end;

procedure TForm1.BtnSetFix2Click(Sender: TObject);
// Fixture-Position in Tabelle auf aktuelle Maschinenposition setzen
var my_btn: Integer;
begin
  if isSimActive then
    exit;
  my_btn:= MessageDlg('This will set FIXTURE 2 postion'
    + #13 + ' to current machine position'
    + #13 + 'in GRBLize Application defaults. Proceed?', mtConfirmation, mbOKCancel, 0);
  if my_btn = mrCancel then
    exit;
  job.fix2_x:= grbl_mpos.x;
  job.fix2_y:= grbl_mpos.y;
  job.fix2_z:= grbl_mpos.z;
  with Form1.SgAppDefaults do begin
    Cells[1,32]:= FormatFloat('0.00', job.fix2_x);
    Cells[1,33]:= FormatFloat('0.00', job.fix2_y);
    Cells[1,34]:= FormatFloat('0.00', job.fix2_z);
  end;
  SaveIniFile;
end;


