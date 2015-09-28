unit grbl_player_main;
// CNC-Steuerung für GRBL-JOG-Platine mit GRBL 0.8c/jog.2 Firmware
// oder GRBL 0.9j mit DEFINE GRBL115

interface

uses
  Math, StdCtrls, ComCtrls, ToolWin, Buttons, ExtCtrls, ImgList,
  Controls, StdActns, Classes, ActnList, Menus, GraphUtil,
  SysUtils, StrUtils, Windows, Graphics, Forms, Messages,
  Dialogs, Spin, FileCtrl, Grids, Registry, ShellApi,
  VFrames, ExtDlgs, XPMan, CheckLst, drawing_window,
  glscene_view, GLColor, ValEdit, System.ImageList, System.Actions,
  FTDItypes, deviceselect, grbl_com;

const
  c_ProgNameStr: String = 'GRBLize ';
  c_VerStr: String = '1.0a';

type
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    FileNewItem: TMenuItem;
    FileOpenItem: TMenuItem;
    FileSaveItem: TMenuItem;
    FileSaveAsItem: TMenuItem;
    FileExitItem: TMenuItem;
    Edit0: TMenuItem;
    CutItem: TMenuItem;
    CopyItem: TMenuItem;                                                               
    PasteItem: TMenuItem;
    Help1: TMenuItem;
    HelpAboutItem: TMenuItem;
    ActionList1: TActionList;
    FileNew1: TAction;
    FileOpen1: TAction;
    FileSave1: TAction;
    FileSaveAs1: TAction;
    FileExit1: TAction;
    EditCut1: TEditCut;
    EditCopy1: TEditCopy;
    EditPaste1: TEditPaste;
    HelpAbout1: TAction;
    ImageList1: TImageList;
    ToolBar1: TToolBar;
    ToolButton9: TToolButton;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    BtnRescan: TButton;
    DeviceView: TEdit;
    OpenFileDialog: TOpenDialog;
    TimerDraw: TTimer;
    BtnClose: TButton;
    XPManifest1: TXPManifest;
    N7: TMenuItem;
    OpenJobDialog: TOpenDialog;
    SaveJobDialog: TSaveDialog;
    PageControl1: TPageControl;
    TabSheetPens: TTabSheet;
    Label7: TLabel;
    SgPens: TStringGrid;
    TabSheetGroups: TTabSheet;
    TabSheetDefaults: TTabSheet;
    TabSheetRun: TTabSheet;
    Memo1: TMemo;
    SgGrblSettings: TStringGrid;
    Bevel3: TBevel;
    PosX: TLabel;
    BtnZeroX: TSpeedButton;
    PosY: TLabel;
    BtnZeroY: TSpeedButton;
    PosZ: TLabel;
    BtnZeroZ: TSpeedButton;
    Label11: TLabel;
    BtnSendGrblSettings: TBitBtn;
    ColorDialog1: TColorDialog;
    Bevel4: TBevel;
    BtnRunJob: TSpeedButton;
    BtnStop: TSpeedButton;
    BtnMoveWorkZero: TSpeedButton;
    BtnMovePark: TSpeedButton;
    BtnMoveToolChange: TSpeedButton;
    Label13: TLabel;
    Bevel2: TBevel;
    Label14: TLabel;
    BtnRefreshGrblSettings: TBitBtn;
    CheckPenChangePause: TCheckBox;
    CheckEndPark: TCheckBox;
    MposX: TLabel;
    MposY: TLabel;
    MposZ: TLabel;
    BtnHomeCycle: TSpeedButton;
    ComboBox1: TComboBox;
    TabSheet1: TTabSheet;
    SgFiles: TStringGrid;
    Label1: TLabel;
    Label5: TLabel;
    SgBlocks: TStringGrid;
    Label12: TLabel;
    Bevel1: TBevel;
    Label2: TLabel;
    WindowMenu1: TMenuItem;
    ShowDrawing1: TMenuItem;
    Show3DPreview1: TMenuItem;
    ShowSpindleCam1: TMenuItem;
    SgAppdefaults: TStringGrid;
    MemoComment: TMemo;
    Label3: TLabel;
    TimerStatus: TTimer;
    BtnEmergStop: TBitBtn;
    PanelLED: TPanel;
    BtnRunGcode: TSpeedButton;
    CheckUseATC: TCheckBox;
    ComboBoxTip: TComboBox;
    ComboBoxGtip: TComboBox;
    Label4: TLabel;
    Label8: TLabel;
    ComboBoxGdia: TComboBox;
    Panel3: TPanel;
    Panel1: TPanel;
    Panel4: TPanel;
    Panel2: TPanel;
    Label6: TLabel;
    TrackBarSimSpeed: TTrackBar;
    Label10: TLabel;
    TimerSim: TTimer;
    CheckBoxSim: TCheckBox;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    BitBtn6: TBitBtn;
    BitBtn7: TBitBtn;
    BitBtn8: TBitBtn;
    BitBtn9: TBitBtn;
    BitBtn10: TBitBtn;
    BitBtn11: TBitBtn;
    BitBtn12: TBitBtn;
    Bevel5: TBevel;
    CheckBoxJogpad: TCheckBox;
    TrackBarRepeatRate: TTrackBar;
    Label9: TLabel;
    Label15: TLabel;
    BitBtn13: TBitBtn;
    BitBtn14: TBitBtn;
    BitBtn15: TBitBtn;
    BitBtn16: TBitBtn;
    BitBtn17: TBitBtn;
    BitBtn18: TBitBtn;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    BtnLoadGrblSetup: TSpeedButton;
    BtnSaveGrblSetup: TSpeedButton;
    EditStatus: TEdit;
    procedure RunGcode;
    procedure BtnEmergencyStopClick(Sender: TObject);
    procedure TimerStatusElapsed(Sender: TObject);
    procedure SgPensMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PageControl1Change(Sender: TObject);
    procedure SgBlocksClick(Sender: TObject);
    procedure SgBlocksMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SgFilesMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SgAppdefaultsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ShowSpindleCam1Click(Sender: TObject);
    procedure Show3DPreview1Click(Sender: TObject);
    procedure ShowDrawing1Click(Sender: TObject);
    procedure SgAppdefaultsExit(Sender: TObject);
    procedure SgAppdefaultsKeyPress(Sender: TObject; var Key: Char);
    procedure SgAppdefaultsClick(Sender: TObject);
    procedure SgPensKeyPress(Sender: TObject; var Key: Char);
    procedure SgFilesKeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox1Exit(Sender: TObject);
    procedure SgBlocksDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure BtnMoveToolChangeClick(Sender: TObject);
    procedure BtnMoveParkClick(Sender: TObject);
    procedure BtnMoveWorkZeroClick(Sender: TObject);
    procedure SgGrblSettingsDrawCell(Sender: TObject; ACol,
      ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure BtnRefreshGrblSettingsClick(Sender: TObject);
    procedure SgAppdefaultsDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure BtnHomeCycleClick(Sender: TObject);
    procedure BtnZeroZClick(Sender: TObject);
    procedure BtnZeroYClick(Sender: TObject);
    procedure BtnZeroXClick(Sender: TObject);
    procedure BtnSendGrblSettingsClick(Sender: TObject);
    procedure HelpAbout1Execute(Sender: TObject);
    procedure SgFilesDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure SgFilesClick(Sender: TObject);
    procedure SgPensMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure SgPensMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure BtnStopClick(Sender: TObject);
    procedure RunJob;
    procedure BitBtnClearFilesClick(Sender: TObject);
    procedure FileNew1Execute(Sender: TObject);
    procedure SgPensDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure JobSaveExecute(Sender: TObject);
    procedure JobSaveAsExecute(Sender: TObject);
    procedure BtnRescanClick(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
    procedure FileExitItemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure JobOpenExecute(Sender: TObject);
    procedure TimerDrawElapsed(Sender: TObject);
    procedure SgPensTopLeftChanged(Sender: TObject);
    procedure ComboBoxTipExit(Sender: TObject);
    procedure ComboBoxGtipChange(Sender: TObject);
    procedure ComboBoxGdiaChange(Sender: TObject);
    procedure BtnRunJobClick(Sender: TObject);
    procedure BtnRunGcodeClick(Sender: TObject);
    procedure TimerSimElapsed(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CheckBoxSimClick(Sender: TObject);
    procedure BitBtnJogMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BitBtnJogMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CheckBoxJogpadClick(Sender: TObject);
    procedure BtnLoadGrblSetupClick(Sender: TObject);
    procedure BtnSaveGrblSetupClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TLed = class
    private
      IsOn: Boolean;
      procedure SetLED(led_on: Boolean);
    public
      property Checked: Boolean read IsOn write SetLED;
    end;


  procedure CheckResponse;
  procedure SendGrblAndWaitForIdle;

  
type

    T3dFloat = record
      X: Double;
      Y: Double;
      Z: Double;
    end;
var
  Form1: TForm1;
  LEDbusy: TLed;
  DeviceList: TStringList;
  TimeOutValue,LEDtimer: Integer;  // Timer-Tick-Zähler
  TimeOut: Boolean;
  TimerCount1:Integer;
  CancelWait: Boolean;
  CancelGrbl, CancelJob: Boolean;

  ComPortAvailableList: Array[0..31] of Integer;
  ComPortUsed: Integer;
  NeedsRelist: boolean;
  Scale: Double;
  JobSettingsPath: String;
  HomingPerformed: Boolean;
  grbl_mpos, grbl_wpos, old_grbl_wpos: T3dFloat;
  grbl_busy: Boolean;
  TimerGrblCount: Integer;
  SimRunTrigger: Boolean; //Start-Flag für Grbl-Timer
  TimerStatusFinished: Boolean;
  MouseJogAction: Boolean;

implementation

uses import_files, Clipper, About, bsearchtree, cam_view;

{$R *.dfm}

// #############################################################################
// #############################################################################


procedure TLed.SetLED(led_on: boolean);
// liefert vorherigen Zustand zurück
begin
  if led_on then begin
    Form1.PanelLED.Color:= clred;
    Form1.PanelLED.Font.Color:= clWhite;
  end else begin
    Form1.PanelLED.Color:= clmaroon;
    Form1.PanelLED.Font.Color:= clgray;
  end;
  IsOn:= led_on;
end;


// #############################################################################
// #############################################################################

procedure DisableButtons;
begin
  with Form1 do begin
    BtnHomeCycle.Enabled:= false;
    BtnRefreshGrblSettings.Enabled:= false;
    BtnSendGrblSettings.Enabled:= false;
    BtnMoveToolChange.Enabled:= false;
    BtnMovePark.Enabled:= false;
  end;
end;

procedure EnableRunButtons;
begin
  with Form1 do begin
    BtnMoveToolChange.Enabled:= true;
    BtnMovePark.Enabled:= true;
    BtnHomeCycle.Enabled:= true;
    BtnRefreshGrblSettings.Enabled:= true;
    BtnSendGrblSettings.Enabled:= true;
  end;
end;

procedure EnableNotHomedButtons;
begin
  with Form1 do begin
    BtnMoveToolChange.Enabled:= false;
    BtnMovePark.Enabled:= false;
    BtnHomeCycle.Enabled:= true;
    BtnRefreshGrblSettings.Enabled:= true;
    BtnSendGrblSettings.Enabled:= true;
  end;
end;

procedure DisableTimerStatus;
begin
{
  if Form1.TimerStatus.enabled then begin
    TimerStatusFinished:= false;
    repeat
      Application.ProcessMessages;
    until TimerStatusFinished;
    Form1.TimerStatus.enabled:= false;
  end else
    TimerStatusFinished:= true;
}
  if Form1.TimerStatus.enabled then begin
    Form1.TimerStatus.enabled:= false;
    mdelay(Form1.TimerStatus.Interval + 10);
  end;
  while grbl_receiveCount > 0 do begin
    grbl_receiveStr(c_delay_short);   // Dummy lesen
    mdelay(c_delay_short);
  end;
end;

procedure CheckResponse;
begin
  grbl_sendlist.Clear;
  if ftdi_isopen then begin
    if grbl_Resync then begin
    end else begin
      showmessage('GRBL not responding or busy!');
      Form1.BtnCloseClick(nil);
    end;
  end;
end;

// #############################################################################
// ############################# I N C L U D E S ###############################
// #############################################################################



{$I page_blocks.pas}
{$I page_job.pas}
{$I page_pens.pas}
{$I page_grblsetup.pas}
{$I page_run.pas}
{$I gcode_interpreter.pas}



// #############################################################################
// ############################ M A I N  F O R M ###############################
// #############################################################################



function IsFormOpen(const FormName : string): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := Screen.FormCount - 1 DownTo 0 do
    if (Screen.Forms[i].Name = FormName) then
    begin
      Result := True;
      Break;
    end;
end;


procedure TForm1.FormCreate(Sender: TObject);
var
  grbl_ini: TRegistry;
  my_ftdi_was_open: Boolean;
  vid, pid: word;
  my_device: fDevice;
  my_description: String;

begin
  SimRunTrigger:= false;
  TimerGrblCount:= 0;
  grbl_receveivelist:= TStringList.create;
  grbl_receveivelist.clear;
  grbl_sendlist:= TStringList.create;
  grbl_sendlist.clear;
  sim_sendlist:= Tstringlist.Create;
  sim_sendlist.Clear;
  LEDbusy:= Tled.Create;
  TimerCount1:= 0;
  InitJob;
  UnHilite;
  Caption := 'GRBLize';
  BtnRescan.Visible:= true;
  BtnClose.Visible:= false;
  Form1.Show;
  grbl_ini:= TRegistry.Create;
  LEDbusy.Checked:= true;
  try
    grbl_ini.RootKey := HKEY_CURRENT_USER;
    grbl_ini.OpenKey('SOFTWARE\Make\GRBlize\'+c_VerStr,true);
    if grbl_ini.ValueExists('MainFormTop') then
      Top:= grbl_ini.ReadInteger('MainFormTop');
    if grbl_ini.ValueExists('MainFormLeft') then
      Left:= grbl_ini.ReadInteger('MainFormLeft');
    if grbl_ini.ValueExists('MainFormJogpad') then
      CheckBoxJogpad.Checked:= grbl_ini.ReadBool('MainFormJogpad');
    if grbl_ini.ValueExists('SettingsPath') then
      JobSettingsPath:= grbl_ini.ReadString('SettingsPath')
    else
      JobSettingsPath:= ExtractFilePath(Application.ExeName)+'default.job';
    if grbl_ini.ValueExists('SettingsDeviceSerial') then
      ftdi_serial:= grbl_ini.ReadString('SettingsDeviceSerial')
    else
      ftdi_serial:= 'NONE';
    if grbl_ini.ValueExists('SettingsDeviceOpen') then
      my_ftdi_was_open:= grbl_ini.ReadBool('SettingsDeviceOpen')
    else
      my_ftdi_was_open:= false;
    if grbl_ini.ValueExists('DrawingFormVisible') then
      WindowMenu1.Items[0].Checked:= grbl_ini.ReadBool('DrawingFormVisible');
    if grbl_ini.ValueExists('CamFormVisible') then
      WindowMenu1.Items[1].Checked:= grbl_ini.ReadBool('CamFormVisible');
    if grbl_ini.ValueExists('SceneFormVisible') then
      WindowMenu1.Items[2].Checked:= grbl_ini.ReadBool('SceneFormVisible');
  finally
    grbl_ini.Free;
  end;

  Form1.Memo1.lines.add('// ' + SetUpFTDI);
  if (ftdi_device_count > 0) and my_ftdi_was_open then
    if ftdi.isPresentBySerial(ftdi_serial) then begin
      // Öffnet Device nach Seriennummer
      // Stellt sicher, dass das beim letzten Form1.Close
      // geöffnete Device auch weiterhin verfügbar ist.
      Memo1.lines.add('// ' + InitFTDIbySerial(ftdi_serial));
      if ftdi_isopen then begin
        ftdi.getDeviceInfo(my_device, pid, vid, ftdi_serial, my_description);
        BtnRescan.Visible:= false;
        BtnClose.Visible:= true;
        DeviceView.Text:= ftdi_serial + ' - ' + my_description;
      end;
    end;

  if not IsFormOpen('Form4') then
    Form4 := TForm4.Create(Self);
  if WindowMenu1.Items[2].Checked then
    Form4.show
  else
    Form4.hide;

  if not IsFormOpen('Form3') then
    Form3 := TForm3.Create(Self);
  if WindowMenu1.Items[1].Checked then
    Form3.show
  else
    Form3.hide;

  if not IsFormOpen('Form2') then
    Form2 := TForm2.Create(Self);
  if WindowMenu1.Items[0].Checked then
    Form2.show
  else
    Form2.hide;

  if not IsFormOpen('deviceselectbox') then
    deviceselectbox := Tdeviceselectbox.Create(Self);
  deviceselectbox.hide;

  SetSimPositionMMxyz(0, 0, 30);
  SetDrawingToolPosMM(0, 0, 30);
  SetSimToolMM(ComboBoxGdia.ItemIndex, ComboBoxGTip.ItemIndex, clGray);
  CheckBoxJogpadClick(sender);

  HomingPerformed:= false;
  Combobox1.Parent := SgFiles;
  ComboBox1.Visible := False;
  ComboboxTip.Parent := SgPens;
  ComboBoxTip.Visible := False;
  SgFiles.Row:=1;
  SgFiles.Col:=4;

  if FileExists(JobSettingsPath) then
    OpenJobFile(JobSettingsPath)
  else
    Form1.FileNew1Execute(sender);

  TimerDraw.Enabled:= true;
  TimerSim.Enabled:= true;
  CheckResponse;
  LEDbusy.Checked:= false;
  TimerStatus.Enabled:= not Form1.CheckBoxSim.checked;
  DisableButtons;
  SgGrblSettings.FixedCols:= 1;
  SgAppdefaults.FixedCols:= 1;
end;


procedure TForm1.FileExitItemClick(Sender: TObject);
begin
  Close;
end;


procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Application.Terminate;
end;


procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  grbl_ini:TRegistry;
begin
  CancelGrbl:= true;
  CancelJob:= true;
  CancelWait:= true;

  if ftdi_isopen then begin
    ftdi_isopen:= false;
    ftdi.closeDevice;
    freeandnil(ftdi);
  end;
  TimerDraw.Enabled:= false;
  TimerStatus.Enabled:= false;
  TimerSim.Enabled:= false;
  grbl_ini:=TRegistry.Create;
  try
    grbl_ini.RootKey := HKEY_CURRENT_USER;
    grbl_ini.OpenKey('SOFTWARE\Make\GRBlize\'+c_VerStr, true);
    grbl_ini.WriteInteger('MainFormTop',Top);
    grbl_ini.WriteInteger('MainFormLeft',Left);
    grbl_ini.WriteBool('MainFormJogpad', CheckBoxJogpad.Checked);
    grbl_ini.WriteString('SettingsPath',JobSettingsPath);
    grbl_ini.WriteBool('DrawingFormVisible',Form1.WindowMenu1.Items[0].Checked);
    grbl_ini.WriteBool('CamFormVisible',Form1.WindowMenu1.Items[1].Checked);
    grbl_ini.WriteBool('SceneFormVisible',Form1.WindowMenu1.Items[2].Checked);
    if ftdi_isopen then
      grbl_ini.WriteString('SettingsDeviceSerial', ftdi_serial)
    else
      grbl_ini.WriteString('SettingsDeviceSerial', 'NONE');
    grbl_ini.WriteBool('SettingsDeviceOpen',ftdi_isopen);
  finally
    grbl_ini.Free;
  end;
  mdelay(200);
  if IsFormOpen('AboutBox') then
    AboutBox.Close;
  if IsFormOpen('DeviceSelectbox') then
    DeviceSelectbox.Close;
  if IsFormOpen('Form4') then
    Form4.Close;
  if IsFormOpen('Form3') then
    Form3.Close;
  if IsFormOpen('Form2') then
    Form2.Close;
end;

procedure TForm1.PageControl1Change(Sender: TObject);
begin
  SgPens.Col:= 3;
  SgPens.Row:= 1;
end;

// #############################################################################

procedure TForm1.ComboBoxGdiaChange(Sender: TObject);
begin
  SetSimToolMM(ComboBoxGdia.ItemIndex +1, sim_tooltip, clGray);
end;

procedure TForm1.ComboBoxGtipChange(Sender: TObject);
begin
  SetSimToolMM(sim_dia, ComboBoxGTip.ItemIndex, clGray);
end;

procedure TForm1.CheckBoxJogpadClick(Sender: TObject);
begin
  if CheckBoxJogpad.Checked then
    Width:= Constraints.MaxWidth
  else
    Width:= Constraints.MinWidth;
end;

procedure TForm1.CheckBoxSimClick(Sender: TObject);
begin
  TimerStatus.Enabled:= not Form1.CheckBoxSim.checked;
end;


// #############################################################################
// ############################## T I M E R ####################################
// #############################################################################

procedure TForm1.TimerDrawElapsed(Sender: TObject);
begin
  inc(TimerCount1);
  if (TimerCount1 = 10) and (not HomingPerformed) and ftdi_isopen then
    Form1.BtnHomeCycle.Font.Color:= clPurple;
  if (TimerCount1 = 20) and (not HomingPerformed) and ftdi_isopen then
    Form1.BtnHomeCycle.Font.Color:= clfuchsia;
  if (TimerCount1 >= 20) then begin
    TimerCount1:= 0;
    if not ftdi_isopen then begin
      grbl_wpos.z:= job.z_gauge;
      PosZ.Caption:= FormatFloat('000.00', grbl_wpos.z);
    end;
  end;
  if NeedsRelist and (Form1.PageControl1.TabIndex = 2) then begin
    list_blocks;
    NeedsRelist:= false;
  end;
  if NeedsRedraw and Form1.WindowMenu1.Items[0].Checked then begin
    draw_cnc_all;
    NeedsRedraw:= false;
  end;
end;

procedure TForm1.TimerSimElapsed(Sender: TObject);
var
  my_str: String;
  my_count: Integer;
begin
  TimerSim.Enabled:= false;    // Re-Entry verhindern
  if SimRunTrigger then begin
    my_count:= sim_sendlist.count;
    if my_count > 0 then begin
      my_str:= sim_sendlist.Strings[0];
      sim_sendlist.Delete(0);
      InterpretGcodeLine(my_str);
      if my_count = 1 then // war letzter Eintrag
        Finalize3Dview;
      sim_active:= true;  // muss nach Finalize3Dview aktiviert werden
    end else begin
      sim_active:= false;
      SimRunTrigger:= false;
    end;
  end;
  TimerSim.Enabled:= true;
end;


procedure TForm1.TimerStatusElapsed(Sender: TObject);
// alle 100 ms aufgerufen. Zeit reicht zum Empfang der Statusmeldung
var pos_changed: Boolean;
begin
  pos_changed:= false;
  getStatus(pos_changed); // dauert maximal ca. 80 ms
  if pos_changed then begin
    SetDrawingToolPosMM(grbl_wpos.X, grbl_wpos.Y, grbl_wpos.Z);
    SetSimPosColorMM(grbl_wpos.X, grbl_wpos.Y, grbl_wpos.z, sim_color);
    TimerStatus.Interval:= 100
  end else
    TimerStatus.Interval:= 250;
  TimerStatusFinished:= true;
end;


procedure SendGrblAndWaitForIdle;
// Resync und warten auf Idle
var
  my_str, my_response: String;
  i, my_count: Integer;
  pos_changed: Boolean;
begin
  my_count:= grbl_sendlist.Count;
  if my_count = 0 then
    exit;
  LEDbusy.Checked:= true;
  if Form1.CheckBoxSim.checked then begin
    for i:= 0 to my_count-1 do begin   // Alle Gcodes in sim-Stringlist übertragen
      my_str:= grbl_sendlist[i];
      sim_sendlist.Add(my_str);
      if Form1.CheckBoxSim.checked then
        Form1.Memo1.lines.add(my_str + ' // sim');
    end;
    SimRunTrigger:= true;             // parallel Abarbeitung in TimerSim starten
  end else if ftdi_isopen then begin
    DisableTimerStatus;
    my_count:= grbl_sendlist.Count;
    for i:= 0 to my_count-1 do begin
      if i mod 10 = 0 then begin           // alle 10 Zeilen Status anfordern
        getStatus(pos_changed);       // ist ein Dummy
        SetDrawingToolPosMM(grbl_wpos.X, grbl_wpos.Y, grbl_wpos.Z);
        SetSimPosColorMM(grbl_wpos.X, grbl_wpos.Y, grbl_wpos.z, sim_color);
      end;
      my_str:= grbl_sendlist.Strings[i];
      if length(my_str) > 1 then
        if my_str[1] <> '/' then begin
          // Befehl ist kein Kommentar, also abschicken
          my_response:= grbl_sendStr(my_str + #13, true);
          Form1.Memo1.lines.add(my_str + ' // ' + my_response);
        end;
      if CancelJob then begin
        // Schleife abbrechen und auf penlift-Höhe gehen
        grbl_sendlist.Clear;
        Form1.Memo1.lines.add(' // JOB CANCELLED');
        my_str:= 'M5';
        my_response:= grbl_sendStr(my_str + #13, true);
        my_str:= 'G0 Z'+ FormatFloat('0.00', job.z_penlift);
        my_response:= grbl_sendStr(my_str + #13, true);
        Form1.Memo1.lines.add(my_str + ' // ' + my_response);
        break;
      end;
    end;
    while getstatus(pos_changed) do  // noch beschäftigt?
      mdelay(c_delay_long);
  end;
  grbl_sendlist.Clear;
  Form1.TimerStatus.Enabled:= not Form1.CheckBoxSim.checked;
  LEDbusy.Checked:= false;
end;



// #############################################################################

procedure TForm1.ShowDrawing1Click(Sender: TObject);
begin
  WindowMenu1.Items[0].Checked:= not WindowMenu1.Items[0].Checked;
  if WindowMenu1.Items[0].Checked then begin
    Form2.Show;
    NeedsRedraw:= true;
  end else
    Form2.Hide;
end;

procedure TForm1.ShowSpindleCam1Click(Sender: TObject);
begin
  WindowMenu1.Items[1].Checked:= not WindowMenu1.Items[1].Checked;
  if WindowMenu1.Items[1].Checked then
    Form3.Show
  else
    Form3.Hide;
end;


procedure TForm1.Show3DPreview1Click(Sender: TObject);
begin
  WindowMenu1.Items[2].Checked:= not WindowMenu1.Items[2].Checked;
  if WindowMenu1.Items[2].Checked then begin
    Form4.Show;
    Form4.FormRefresh(Sender);
  end else
    Form4.Hide;
end;

procedure TForm1.HelpAbout1Execute(Sender: TObject);
begin
  AboutBox.ProgName.Caption:= c_ProgNameStr;
  AboutBox.VersionInfo.Caption:= c_VerStr;
  Aboutbox.ShowModal;
end;

end.

