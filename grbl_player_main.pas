unit grbl_player_main;
// CNC-Steuerung für GRBL-JOG-Platine mit GRBL 0.8c/jog.2 Firmware
// oder GRBL 0.9j mit DEFINE GRBL115


interface

uses
  Math, StdCtrls, ComCtrls, ToolWin, Buttons, ExtCtrls, ImgList,
  Controls, StdActns, Classes, ActnList, Menus, GraphUtil,
  SysUtils, StrUtils, Windows, Graphics, Forms, Messages,
  Dialogs, Spin, FileCtrl, Grids, Registry, ShellApi, MMsystem,
  VFrames, ExtDlgs, XPMan, CheckLst, drawing_window,
  glscene_view, GLColor, ValEdit, System.ImageList, System.Actions,
  FTDItypes, deviceselect, grbl_com, Vcl.ColorGrd;

const
  c_ProgNameStr: String = 'GRBLize ';
  c_VerStr: String = '1.2';

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
    Label13: TLabel;
    BtnRefreshGrblSettings: TBitBtn;
    CheckEndPark: TCheckBox;
    MposX: TLabel;
    MposY: TLabel;
    MposZ: TLabel;
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
    SgJobDefaults: TStringGrid;
    MemoComment: TMemo;
    Label3: TLabel;
    TimerStatus: TTimer;
    BtnEmergStop: TBitBtn;
    PanelLED: TPanel;
    CheckUseATC: TCheckBox;
    ComboBoxTip: TComboBox;
    Panel3: TPanel;
    Panel1: TPanel;
    Panel4: TPanel;
    Panel2: TPanel;
    Label6: TLabel;
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
    TimerBlink: TTimer;
    Label23: TLabel;
    ProgressBar1: TProgressBar;
    SgAppDefaults: TStringGrid;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Bevel8: TBevel;
    LabelWorkX: TLabel;
    LabelWorkY: TLabel;
    LabelWorkZ: TLabel;
    Label4: TLabel;
    TrackBarSimSpeed: TTrackBar;
    ComboBoxGtip: TComboBox;
    ComboBoxGdia: TComboBox;
    Bevel7: TBevel;
    Label8: TLabel;
    Label10: TLabel;
    BtnRunGcode: TSpeedButton;
    Label19: TLabel;
    EditZoffs: TEdit;
    ComboBoxATC: TComboBox;
    Label20: TLabel;
    CheckFixedProbeZ: TCheckBox;
    BtnZcontact: TSpeedButton;
    LabelTableX: TLabel;
    LabelTableY: TLabel;
    LabelTableZ: TLabel;
    Label31: TLabel;
    Label21: TLabel;
    LabelToolReference: TLabel;
    Bevel6: TBevel;
    Bevel9: TBevel;
    Bevel10: TBevel;
    BtnProbeTLC: TSpeedButton;
    BtnMoveToolChange: TSpeedButton;
    Label22: TLabel;
    BtnMoveWorkZero: TSpeedButton;
    BtnMovePark: TSpeedButton;
    Label9: TLabel;
    CheckPartProbeZ: TCheckBox;
    BtnUnload: TButton;
    BtnLoad: TButton;
    PanelZdone: TPanel;
    Label14: TLabel;
    BtnHomeCycle: TSpeedButton;
    PanelATC0: TPanel;
    PanelATC1: TPanel;
    PanelATC2: TPanel;
    PanelATC3: TPanel;
    PanelATC4: TPanel;
    PanelATC5: TPanel;
    PanelATC6: TPanel;
    PanelATC7: TPanel;
    PanelATC8: TPanel;
    PanelATC9: TPanel;
    Label32: TLabel;
    PanelToolInSpindle: TPanel;
    Label33: TLabel;
    BtnMoveToATC: TButton;
    Label34: TLabel;
    Label35: TLabel;
    Label36: TLabel;
    Label37: TLabel;
    Label38: TLabel;
    Label39: TLabel;
    Label40: TLabel;
    Label41: TLabel;
    Label42: TLabel;
    Label43: TLabel;
    Label44: TLabel;
    BtnListAssignments: TButton;
    Bevel12: TBevel;
    LabelHintZ: TLabel;
    ToolBar1: TToolBar;
    ToolButton9: TToolButton;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    LabelFaults: TLabel;
    PanelToolReferenced: TPanel;
    LabelHintZ2: TLabel;
    CheckBoxSim: TCheckBox;
    BtnCancel: TSpeedButton;
    BtnConnect: TBitBtn;
    PanelToolCompensated: TPanel;
    BtnListTools: TButton;
    BtnResetRef: TButton;
    TabSheet2: TTabSheet;
    BtnGerberConvert: TButton;
    Memo2: TMemo;
    RadioGroup1: TRadioGroup;
    RadioButtonFront: TRadioButton;
    RadioButtonBack: TRadioButton;
    EditInflate: TEdit;
    Label29: TLabel;
    PanelYdone: TPanel;
    PanelXdone: TPanel;
    Label24: TLabel;
    PaintBox1: TPaintBox;
    Label30: TLabel;
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
    procedure SgJobDefaultsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ShowSpindleCam1Click(Sender: TObject);
    procedure Show3DPreview1Click(Sender: TObject);
    procedure ShowDrawing1Click(Sender: TObject);
    procedure SgJobDefaultsExit(Sender: TObject);
    procedure SgJobDefaultsKeyPress(Sender: TObject; var Key: Char);
    procedure SgJobDefaultsClick(Sender: TObject);
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
    procedure SgJobDefaultsDrawCell(Sender: TObject; ACol, ARow: Integer;
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
    procedure BtnCancelClick(Sender: TObject);
    procedure BitBtnClearFilesClick(Sender: TObject);
    procedure FileNew1Execute(Sender: TObject);
    procedure SgPensDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure JobSaveExecute(Sender: TObject);
    procedure JobSaveAsExecute(Sender: TObject);
    procedure BtnConnectClick(Sender: TObject);
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
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CheckBoxSimClick(Sender: TObject);
    procedure BitBtnJogMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BitBtnJogMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BtnLoadGrblSetupClick(Sender: TObject);
    procedure BtnSaveGrblSetupClick(Sender: TObject);
    procedure TimerBlinkTimer(Sender: TObject);
    procedure Panel4Click(Sender: TObject);
    procedure SgAppDefaultsKeyPress(Sender: TObject; var Key: Char);
    procedure SgAppDefaultsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SgAppDefaultsDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure SgAppDefaultsClick(Sender: TObject);
    procedure SgAppDefaultsExit(Sender: TObject);
    procedure BtnProbeTLCclick(Sender: TObject);
    procedure BtnZcontactClick(Sender: TObject);
    procedure CheckFixedProbeZClick(Sender: TObject);
    procedure BtnUnloadClick(Sender: TObject);
    procedure BtnLoadClick(Sender: TObject);
    procedure PanelATCClick(Sender: TObject);
    procedure BtnMoveToATCClick(Sender: TObject);
    procedure BtnListAssignmentsClick(Sender: TObject);
    procedure CheckUseATCClick(Sender: TObject);
    procedure BtnRescanClick(Sender: TObject);
    procedure BtnListToolsClick(Sender: TObject);
    procedure BtnResetRefClick(Sender: TObject);
    procedure BtnGerberConvertClick(Sender: TObject);
    procedure ComboBoxTipMouseLeave(Sender: TObject);
    procedure ComboBoxTipKeyPress(Sender: TObject; var Key: Char);

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


  procedure WaitForIdle;
  procedure SendSingleCommandStr(my_command: String);
  procedure SendGrblAndWaitForIdle;
  procedure list_Blocks;
  procedure EnableStatus;  // automatische Upates freischalten
  procedure DisableStatus;  // automatische Upates freischalten


type

    T3dFloat = record
      X: Double;
      Y: Double;
      Z: Double;
    end;
    t_mstates = (idle, run, hold, alarm, zero);
    t_rstates = (s_reset, s_send, s_receive, s_wait, s_wait_status, s_idle_loop, s_disable, s_cancel);
    t_pstates = (s_notprobed, s_probed_manual, s_probed_contact);


var
  CancelJob: Boolean = false;     // Abbruch aller Schleifen
  CancelSim: Boolean = false;     // Abbruch der Simulation
  SendActive: Boolean = false;    // true bis GRBL-Sendeschleife beendet
  JobRunning: Boolean = false;    // true sobald Job gestartet wurde
  JobWasCancelled: Boolean = false;    // true sobald laufender Job abgebrochen wurde

  Form1: TForm1;
  LEDbusy: TLed;
  DeviceList: TStringList;
  TimeOutValue,LEDtimer: Integer;  // Timer-Tick-Zähler
  TimeOut: Boolean;

  ComPortAvailableList: Array[0..31] of Integer;
  ComPortUsed: Integer;
  Scale: Double;
  JobSettingsPath: String;

  grbl_mpos, grbl_wpos, old_grbl_wpos: T3dFloat;
  grbl_busy: Boolean;

  MouseJogAction: Boolean;
  open_request, ftdi_was_open, com_was_open: boolean;
  WorkZeroX, WorkZeroY, WorkZeroZ: Double;  // Absolutwerte Werkstück-Null
  JogX, JogY, JogZ: Double;  // Absolutwerte Jogpad
  HomingPerformed: Boolean;

  MposOnFixedProbe, MposOnPartGauge: Double;
  MposOnFixedProbeReference, ToolDelta: Double;
  FirstToolReferenced, CurrentToolCompensated: Boolean;
  WorkZeroXdone, WorkZeroYdone, WorkZeroZdone: Boolean;
  ProbedState: t_pstates;

  ToolInSpindle: Integer; // ATC-Tool in der Maschine, 0 = Dummy
  ResponseFaultCounter: Integer;
  SpindleRunning: Boolean;

  StatusTimerDisabled, TimerBlinkToggle: Boolean;
  StatusTimerResponseStr: String;
  SendListActive, SendListRequest, SendListDone: Boolean;
  SendListIdx: Integer;

  StatusTimerState: t_rstates; // (none, status, response);
  MachineState: t_mstates;  // (idle, run, hold, alarm)GRBL ist in Ruhe wenn state_idle
  StatusTimerDisableRequest, StatusTimerEnableRequest : boolean;
  CancelRequest: Boolean;
  StatusTimerLoopCount: Integer;

  LastRequest: Dword; // Wann zuletzt Status angefordert?
  LastResponseStr:String;

  // für Simulation
  gcsim_x, gcsim_y, gcsim_z: Double;
  gcsim_x_old, gcsim_y_old, gcsim_z_old: Double;
  gcsim_offset_x, gcsim_offset_y, gcsim_offset_z: Double;
  gcsim_seek: Boolean;
  gcsim_dia: Double;
  gcsim_feed: Integer;
  gcsim_active: Boolean;
  gcsim_tooltip: Integer;
  gcsim_color: TColor;

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
    Form1.PanelLED.Color:= $00000040;
    Form1.PanelLED.Font.Color:= clgray;
  end;
  IsOn:= led_on;
end;

procedure button_enable(my_state: Boolean);
begin
  with Form1 do begin
    BtnMoveWorkZero.Enabled:= my_state;
    BtnMovePark.Enabled:= my_state;
    BtnMoveToolChange.Enabled:= my_state;
    BtnMoveToATC.Enabled:= my_state;
    BtnUnload.Enabled:= my_state;
    BtnLoad.Enabled:= my_state;
    BtnZeroX.Enabled:= my_state;
    BtnZeroY.Enabled:= my_state;
    BtnZeroZ.Enabled:= my_state;
    Form1.BtnProbeTLC.Enabled:= my_state and Form1.CheckFixedProbeZ.checked;
    BtnZcontact.Enabled:= my_state and CheckPartProbeZ.Checked;
    BtnEmergStop.Enabled:= not Form1.CheckBoxSim.checked;

    if WorkZeroXdone then
      PanelXdone.Color:= cllime
    else
      if TimerBlinkToggle then
        PanelXdone.Color:= $00000020
      else
        PanelXdone.Color:= clred;

    if WorkZeroYdone then
      PanelYdone.Color:= cllime
    else
      if TimerBlinkToggle then
        PanelYdone.Color:= $00000020
      else
        PanelYdone.Color:= clred;

    if (WorkZeroZdone and (ProbedState <> s_notprobed)) then
      PanelZdone.Color:= cllime
    else
      if TimerBlinkToggle then
        PanelZdone.Color:= $00000020
      else
        PanelZdone.Color:= clred;
  end;
end;

procedure button_run_enable(my_state: Boolean);
begin
  with Form1 do begin
    BtnRunGcode.Enabled:= my_state;
    BtnRunjob.Enabled:= my_state;
    BtnMoveWorkZero.Enabled:= my_state;
  end;
end;

procedure SetAllbuttons;
var is_idle, is_probed, is_notbusy: boolean;
begin
  is_idle:= MachineState = idle;
  is_probed:= ProbedState <> s_notprobed;
  is_notbusy:= not LEDbusy.Checked;

  if (Form1.BtnCancel.Tag = 1) then begin
    button_enable(false);
    button_run_enable(false);
    with Form1 do begin
      if TimerBlinkToggle then
        BtnCancel.Font.Color:= clred
      else
        BtnCancel.Font.Color:= clblack;
    end;
  end else begin
    button_enable(HomingPerformed or Form1.CheckBoxSim.checked);
    button_run_enable((is_notbusy and HomingPerformed
      and is_probed) or Form1.CheckBoxSim.checked);
    with Form1 do begin
      BtnCancel.Font.Color:= clred;
      if CheckBoxSim.checked then begin
        BtnRunJob.Caption:= 'Simulate Job';
        BtnRunGcode.Caption:= 'Sim G-Code File';
      end else begin
        BtnRunJob.Caption:= 'Run Job';
        BtnRunGcode.Caption:= 'Run G-Code File';
      end;

      if grbl_is_connected and is_idle then begin
        BtnHomeCycle.Enabled:= is_idle;
        BtnSendGrblSettings.Enabled:= true;
        BtnRefreshGrblSettings.Enabled:= true;
        if (not HomingPerformed) and TimerBlinkToggle then
          BtnHomeCycle.Font.Color:= cllime
        else
          BtnHomeCycle.Font.Color:= clgreen;
      end else begin
        BtnHomeCycle.Enabled:= true;
        BtnSendGrblSettings.Enabled:= false;
        BtnRefreshGrblSettings.Enabled:= false;
      end;
    end;
  end;
end;


procedure ResetToolflags;
// Nach Homing, Connect etc: Unkalibrierter Zustand
begin
  drawing_tool_down:= false;
  Form1.ProgressBar1.position:= 0;
  if Form1.CheckBoxSim.Checked then begin
    FirstToolReferenced:=true;
    CurrentToolCompensated:= true;
    WorkZeroXdone:= true;
    WorkZeroYdone:= true;
    WorkZeroZdone:= true;
    ProbedState:= s_probed_manual;
    HomingPerformed:= true;
  end else begin
    FirstToolReferenced:=false;
    CurrentToolCompensated:= false;
    WorkZeroXdone:= false;
    WorkZeroYdone:= false;
    WorkZeroZdone:= false;
    ProbedState:= s_notprobed;
  end;
end;

procedure ResetCoordinates;
// willkürliche Ausgangswerte, auch für Simulation
begin
  grbl_mpos.x:= 50;
  grbl_mpos.y:= 70;
  grbl_mpos.z:= -40;
  grbl_wpos.x:= 0;
  grbl_wpos.y:= 0;
  grbl_wpos.z:= job.z_penlift;
  WorkZeroX:= grbl_mpos.x - grbl_wpos.x;
  WorkZeroY:= grbl_mpos.y - grbl_wpos.y;
  WorkZeroZ:= grbl_mpos.z - grbl_wpos.z;
  with Form1 do begin
    MPosX.Caption:= FormatFloat('000.00', grbl_mpos.x);
    MPosY.Caption:= FormatFloat('000.00', grbl_mpos.y);
    MPosZ.Caption:= FormatFloat('000.00', grbl_mpos.z);
    PosX.Caption:=  FormatFloat('000.00', grbl_wpos.x);
    PosY.Caption:=  FormatFloat('000.00', grbl_wpos.y);
    PosZ.Caption:=  FormatFloat('000.00', grbl_wpos.z);
    LabelWorkX.Caption:= FormatFloat('000.00', WorkZeroX);
    LabelWorkY.Caption:= FormatFloat('000.00', WorkZeroY);
    LabelWorkZ.Caption:= FormatFloat('000.00', WorkZeroZ);
  end;
end;

procedure ResetSimulation;
// willkürliche Ausgangswerte, auch für Simulation
begin
  ResetCoordinates;
  gcsim_x:= grbl_wpos.x;
  gcsim_y:= grbl_wpos.y;
  gcsim_z:= grbl_wpos.z;
  gcsim_x_old:= gcsim_x;
  gcsim_y_old:= gcsim_y;
  gcsim_z_old:= gcsim_z;
  gcsim_offset_x:= grbl_mpos.x - gcsim_x;
  gcsim_offset_y:= grbl_mpos.y - gcsim_y;
  gcsim_offset_z:= grbl_mpos.z - gcsim_z;
  gcsim_dia:= 3;
  JogX:= grbl_wpos.x;
  JogY:= grbl_wpos.y;
  JogZ:= grbl_wpos.z;
  WorkZeroX:= gcsim_offset_x;
  WorkZeroY:= gcsim_offset_y;
  WorkZeroZ:= gcsim_offset_z;
  GLSsimMillAtPosMM(gcsim_x, gcsim_y, gcsim_z, gcsim_dia, false, true);
  GLSsetSimPositionMMxyz(gcsim_x, gcsim_y, gcsim_z);
  SetDrawingToolPosMM(grbl_wpos.X, grbl_wpos.Y, grbl_wpos.Z);
  GLSsetSimToolMM(gcsim_dia, gcsim_tooltip, clGray);
  Form4.GLSsetATCandProbe;
  Form4.FormRefresh(nil);
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

begin
  Show;
  SendListRequest:= false;
  SendListDone:= true;
  SendListActive:= false;
  Width:= Constraints.MaxWidth;
  grbl_receveivelist:= TStringList.create;
  grbl_sendlist:= TStringList.create;
  grbl_is_connected:= false;
  grbl_delay_short:= 15;   // Könnte man von Baudrate abhängig machen
  grbl_delay_long:= 40;
  LEDbusy:= Tled.Create;
  InitJob;
  UnHilite;
  Caption := c_ProgNameStr;
  Form1.Show;
  SpindleRunning:= false;
  if not IsFormOpen('deviceselectbox') then
    deviceselectbox := Tdeviceselectbox.Create(Self);
  deviceselectbox.hide;

  grbl_ini:= TRegistry.Create;
  try
    grbl_ini.RootKey := HKEY_CURRENT_USER;
    grbl_ini.OpenKey('SOFTWARE\Make\GRBlize\'+c_VerStr,true);
    if grbl_ini.ValueExists('MainFormTop') then
      Top:= grbl_ini.ReadInteger('MainFormTop');
    if grbl_ini.ValueExists('MainFormLeft') then
      Left:= grbl_ini.ReadInteger('MainFormLeft');
    if grbl_ini.ValueExists('MainFormPage') then
      PageControl1.ActivePageIndex:= grbl_ini.ReadInteger('MainFormPage');
    if grbl_ini.ValueExists('SettingsPath') then
      JobSettingsPath:= grbl_ini.ReadString('SettingsPath')
    else
      JobSettingsPath:= ExtractFilePath(Application.ExeName)+'default.job';
    if grbl_ini.ValueExists('FTDIdeviceSerial') then
      ftdi_serial:= grbl_ini.ReadString('FTDIdeviceSerial')
    else
      ftdi_serial:= 'NONE';
    if grbl_ini.ValueExists('FTDIdeviceOpen') then
      ftdi_was_open:= grbl_ini.ReadBool('FTDIdeviceOpen')
    else
      ftdi_was_open:= false;
    if grbl_ini.ValueExists('DrawingFormVisible') then
      WindowMenu1.Items[0].Checked:= grbl_ini.ReadBool('DrawingFormVisible');

    if grbl_ini.ValueExists('CamFormVisible') then
      WindowMenu1.Items[1].Checked:= grbl_ini.ReadBool('CamFormVisible');

    if grbl_ini.ValueExists('SceneFormVisible') then
      WindowMenu1.Items[2].Checked:= grbl_ini.ReadBool('SceneFormVisible');
    if grbl_ini.ValueExists('ComBaudrate') then
      deviceselectbox.EditBaudrate.Text:= grbl_ini.ReadString('ComBaudrate');
    if grbl_ini.ValueExists('ComPort') then
      com_name:= grbl_ini.ReadString('ComPort')
    else
      com_name:= '';
    deviceselectbox.ComboBoxCOMport.Text:= com_name;
    if grbl_ini.ValueExists('ComOpen') then
      com_was_open:= grbl_ini.ReadBool('ComOpen')
    else
      com_was_open:= false;
  finally
    grbl_ini.Free;
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

  Combobox1.Parent := SgFiles;
  ComboBox1.Visible := False;
  ComboboxTip.Parent := SgPens;
  ComboBoxTip.Visible := False;
  SgFiles.Row:=1;
  SgFiles.Col:=4;

  LoadIniFile;
  BtnProbeTLC.Enabled:= CheckFixedProbeZ.Checked;
  BtnZcontact.Enabled:= CheckPartProbeZ.Checked;
  CheckUseATC.Enabled:= CheckFixedProbeZ.Checked;
  if not CheckFixedProbeZ.Checked then begin
    CheckUseATC.Checked:= false;
  end;
  if FileExists(JobSettingsPath) then
    OpenJobFile(JobSettingsPath)
  else
    Form1.FileNew1Execute(sender);

  SgGrblSettings.FixedCols:= 1;
  SgAppdefaults.FixedCols:= 1;

  Form4.FormRefresh(nil);

  BringToFront;
  Memo1.lines.add(SetUpFTDI);

  ResetSimulation;
  ResetCoordinates;
  ResetToolflags;

  ToolInSpindle:= 0; // Dummy aus Slot 0
  CheckBoxSim.Checked:= true;
  EnableStatus;
  if ftdi_was_open or com_was_open then begin
    BtnConnect.Enabled:= true;
    BtnConnect.SetFocus;
  end else
    BtnRescan.SetFocus;
{
  if ftdi_was_open then
    OpenFTDIport
  else if com_was_open then
    OpenCOMport;
}
  CheckEndPark.Checked:= job.parkposition_on_end;
  CheckFixedProbeZ.Checked:= job.use_fixed_probe;
  CheckUseATC.Checked:= job.atc_enabled;
  CheckPartProbeZ.Checked:= job.use_part_probe;

  param_change;
  Form4.FormRefresh(nil);
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
  grbl_ini:= TRegistry.Create;
  try
    grbl_ini.RootKey := HKEY_CURRENT_USER;
    grbl_ini.OpenKey('SOFTWARE\Make\GRBlize\'+c_VerStr, true);
    grbl_ini.WriteInteger('MainFormTop',Top);
    grbl_ini.WriteInteger('MainFormLeft',Left);
//    grbl_ini.WriteBool('MainFormJogpad', CheckBoxJogpad.Checked);
    grbl_ini.WriteInteger('MainFormPage',PageControl1.ActivePageIndex);
    grbl_ini.WriteString('SettingsPath',JobSettingsPath);
    grbl_ini.WriteBool('DrawingFormVisible',Form1.WindowMenu1.Items[0].Checked);
    grbl_ini.WriteBool('CamFormVisible',Form1.WindowMenu1.Items[1].Checked);
    grbl_ini.WriteBool('CamOn', CamIsOn);
    grbl_ini.WriteBool('SceneFormVisible',Form1.WindowMenu1.Items[2].Checked);
    if ftdi_isopen then
      grbl_ini.WriteString('FTDIdeviceSerial', ftdi_serial)
    else
      grbl_ini.WriteString('FTDIdeviceSerial', 'NONE');
    grbl_ini.WriteBool('FTDIdeviceOpen',ftdi_isopen);
    grbl_ini.WriteString('ComBaudrate', deviceselectbox.EditBaudrate.Text);
    grbl_ini.WriteString('ComPort', com_name);
    grbl_ini.WriteBool('ComOpen', com_isopen);
  finally
    grbl_ini.Free;
  end;

  TimerDraw.Enabled:= false;

  if com_isopen then
    COMclose;
  if ftdi_isopen then begin
    ftdi_isopen:= false;
    ftdi.closeDevice;
    freeandnil(ftdi);
  end;
  grbl_is_connected:= false;
  SaveIniFile;

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
  if LEDbusy.Checked then
    PageControl1.TabIndex:= 4;
  SgPens.Col:= 3;
  SgPens.Row:= 1;
  Form4.FormRefresh(sender);
end;

procedure TForm1.Panel4Click(Sender: TObject);
begin
  SendSingleCommandStr('$X'); // clear Alarm Lock
end;


// #############################################################################

procedure TForm1.ComboBoxGdiaChange(Sender: TObject);
begin
  GLSsetSimToolMM(ComboBoxGdia.ItemIndex +1, gcsim_tooltip, clGray);
end;

procedure TForm1.ComboBoxGtipChange(Sender: TObject);
begin
  GLSsetSimToolMM(gcsim_dia, ComboBoxGTip.ItemIndex, clGray);
end;


procedure TForm1.BtnResetRefClick(Sender: TObject);
// Reset für erstes Werkzeug. Aktuell (evt. neu eingesetztes) Werkzeug
// wird auf jeden Fall neu kalibriert.
begin
  if (abs(MposOnFixedProbe) < job.table_z) then
// letztes Werkzeug gilt als Referenzlänge
    MposOnFixedProbeReference:= MposOnFixedProbe
  else begin
// letztes Werkzeug gilt als Referenz
    MposOnFixedProbeReference:= 0;
    MposOnFixedProbe:= 0;
  end;
  ToolDelta:= 0;
  FirstToolReferenced:= false;
  // geht automatisch auf Cancel Tool Delta mit G49
  NewG43Offset(ToolDelta);
  CurrentToolCompensated:= false;
end;


//##############################################################################

procedure ExecuteFile(const AFilename: String;
                 AParameter, ACurrentDir: String; AWait, AHide: Boolean);
var
  si: TStartupInfo;
  pi: TProcessInformation;

begin
  if Length(ACurrentDir) = 0 then
    ACurrentDir := ExtractFilePath(AFilename)
  else if AnsiLastChar(ACurrentDir) = '\' then
    Delete(ACurrentDir, Length(ACurrentDir), 1);

  FillChar(si, SizeOf(si), 0);
  with si do begin
    cb := SizeOf(si);
    dwFlags := STARTF_USESHOWWINDOW;
    if AHide then
      wShowWindow := SW_HIDE
    else
      wShowWindow := SW_NORMAL;
  end;
  FillChar(pi, SizeOf(pi), 0);
  AParameter := Format('"%s" %s', [AFilename, TrimRight(AParameter)]);

  if CreateProcess(Nil, PChar(AParameter), Nil, Nil, False,
                   CREATE_DEFAULT_ERROR_MODE or CREATE_NEW_CONSOLE or
                   NORMAL_PRIORITY_CLASS, Nil, PChar(ACurrentDir), si, pi) then
  try
    if AWait then
      while WaitForSingleObject(pi.hProcess, 50) <> Wait_Object_0 do begin


      end;
    TerminateProcess(pi.hProcess, Cardinal(-1));
  finally
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
  end;
end;


procedure TForm1.BtnGerberConvertClick(Sender: TObject);
var my_converter_path, my_source_path,
  my_dest_path, my_side, my_arg: String;
  my_offset: Double;
  img: TImage;
  height, width, heightfac, widthfac, sizefac: Integer;
begin
  Memo2.lines.clear;
  my_converter_path:= ExtractFilePath(Application.ExeName) + 'pcb2gcode\pcb2gcode.exe';
  if not FileExists(my_converter_path) then begin
    Memo2.lines.add('PCB2GCODE converter not found.');
    exit;
  end;
  OpenFileDialog.FilterIndex:= 4;
  if OpenFileDialog.Execute then
    my_source_path:= OpenFileDialog.Filename
  else
    exit;
  if RadioButtonFront.Checked then
    my_side:= '--front'
  else
    my_side:= '--back';

  Paintbox1.canvas.Brush.Color:= clwhite;
  Paintbox1.canvas.FillRect(rect(0,0,600,400));

  my_dest_path:= ChangeFileExt(my_source_path, '.nc' + my_side[3]);
  Memo2.lines.add('Converting Gerber file');
  Memo2.lines.add(my_source_path);
  Memo2.lines.add('to G-Code file');
  Memo2.lines.add(my_dest_path);
  Memo2.lines.add('Please wait...');
  my_offset:= StrToFloatDef(EditInflate.Text, 0.1);
  my_arg:= my_side + #32 + my_source_path
    + ' --zsafe 1 --zchange 30 --zwork -0.2'
    + ' --offset ' + FloatToStrDot(my_offset)
    + ' --mill-feed 200'
    + ' --optimise=1 --mill-speed 6000 --metric=1 --metricoutput=1 '
    + my_side + '-output ' + my_dest_path;
//  Memo2.lines.add(my_arg);
  ExecuteFile(my_converter_path, my_arg, ExtractFilePath(my_converter_path), true, false);
  Memo2.lines.add('');
  mdelay(500);
  Memo2.lines.add('Done.');
  Memo2.lines.add('Please import created G-Code file in Job page.');

  my_converter_path:= ExtractFilePath(Application.ExeName) + 'pcb2gcode\outp1_traced.png';
  img := TImage.create(nil);
  img.Picture.LoadFromFile(my_converter_path);
  // Image ist idR sehr groß, muss skaliert werden
  height:= img.picture.Graphic.Height;
  width:= img.picture.Graphic.Width;
  widthfac:= width div 550 + 1;
  heightfac:= height div 400 + 1;
  if widthfac > heightfac then
    sizefac:= widthfac
  else
    sizefac:= heightfac;
  if sizefac > 10 then
    sizefac:= 10;
  height:= height div sizefac;
  width:= width div sizefac;
  Paintbox1.Canvas.StretchDraw(rect(0,0,width, height),img.picture.Graphic);
  img.Free;
end;

//##############################################################################

procedure TForm1.CheckBoxSimClick(Sender: TObject);
begin
  if Form1.CheckBoxSim.Checked then begin
    ResetCoordinates;
    Form4.GLSsetATCandProbe;
  end else begin

  end;

end;

procedure TForm1.CheckFixedProbeZClick(Sender: TObject);
begin
  BtnProbeTLC.Enabled:= CheckFixedProbeZ.Checked;
  CheckUseATC.Enabled:= CheckFixedProbeZ.Checked;
  if not CheckFixedProbeZ.Checked then begin
    CheckUseATC.Checked:= false;
  end;
  if Form1.Show3DPreview1.Checked then begin
    ResetCoordinates;
    Form4.GLSsetATCandProbe;
  end;
end;

procedure TForm1.CheckUseATCClick(Sender: TObject);
begin
  if Form1.Show3DPreview1.Checked then begin
    ResetCoordinates;
    Form4.GLSsetATCandProbe;
  end;
end;

// #############################################################################
// ############################## T I M E R ####################################
// #############################################################################


procedure TForm1.TimerBlinkTimer(Sender: TObject);
begin
  LabelFaults.Caption:= 'ResponseFaults: ' + IntToStr(ResponseFaultCounter);
  if Form1.CheckFixedProbeZ.Checked then begin
    if (not FirstToolReferenced) then begin
      PanelToolReferenced.Caption:= 'No REF';
      BtnProbeTLC.Caption:= 'Probe REF';
      if TimerBlinkToggle then
        PanelToolReferenced.Color:= clTeal + $00404000
      else
        PanelToolReferenced.Color:= clTeal;
    end else begin
      PanelToolReferenced.Caption:= 'REF OK';
      PanelToolReferenced.Color:= clTeal + $00404000;
      BtnProbeTLC.Caption:= 'Probe TLC';
    end;
    if (not CurrentToolCompensated) then begin
      PanelToolCompensated.Caption:= 'No TLC';
      if TimerBlinkToggle then
        PanelToolCompensated.Color:= clTeal + $00404000
      else
        PanelToolCompensated.Color:= clTeal;
    end else begin
      PanelToolCompensated.Caption:= 'TLC OK';
      PanelToolCompensated.Color:= clTeal + $00404000;
    end;
  end else begin
    PanelToolReferenced.Caption:= 'Disabled';
    PanelToolCompensated.Caption:= 'Disabled';
  end;

  if CheckBoxSim.checked then begin
    WorkZeroX:= gcsim_offset_x;
    WorkZeroY:= gcsim_offset_y;
    WorkZeroZ:= gcsim_offset_z;
  end;

  TimerBlinkToggle:= not TimerBlinkToggle;

  // weniger aktuelle Sachen updaten
  SetDrawingToolPosMM(grbl_wpos.X, grbl_wpos.Y, grbl_wpos.Z);
  ATCcolors(TimerBlinkToggle);
  if TimerBlinkToggle then begin
    LabelWorkX.Caption:= FormatFloat('000.00', WorkZeroX);
    LabelWorkY.Caption:= FormatFloat('000.00', WorkZeroY);
    LabelWorkZ.Caption:= FormatFloat('000.00', WorkZeroZ);
    MPosX.Caption:= FormatFloat('000.00', grbl_mpos.x);
    MPosY.Caption:= FormatFloat('000.00', grbl_mpos.y);
    MPosZ.Caption:= FormatFloat('000.00', grbl_mpos.z);
  end else begin
    LabelToolReference.Caption:= FormatFloat('00.00', ToolDelta);
    LabelTableX.Caption:= FormatFloat('000.00', job.table_x);
    LabelTableY.Caption:= FormatFloat('000.00', job.table_y);
    LabelTableZ.Caption:= FormatFloat('000.00', job.table_z);
    LabelHintZ.Caption:= '(+' + FormatFloat('00.00', job.z_gauge)+' mm)';
    LabelHintZ2.Caption:= '(+' + FormatFloat('00.00', job.z_penlift)+' mm)';
  end;

  SetAllButtons;
end;

procedure TForm1.TimerDrawElapsed(Sender: TObject);
begin
  if NeedsRedraw and Form1.WindowMenu1.Items[0].Checked then begin
    draw_cnc_all;
  end;
  NeedsRedraw:= false;
end;

// #############################################################################
// ########################## TIMER HANDLING ###################################
// #############################################################################

function DecodeStatus(my_response: String; var pos_changed: Boolean): Boolean;
// liefert Busy-Status TRUE wenn GRBL-Status nicht IDLE ist
// setzt pos_changed wenn sich Position änderte
var
  my_str: String;
  my_start_idx: Integer;
  is_valid, is_jogging: Boolean;

begin
  result:= false;
  pos_changed:= false;

//  update_abs:= false;
//  Form1.EditStatus.Text:= my_response;

  // Format bei GRBL 0.9j: <Idle,MPos:0.000,0.000,0.000,WPos:0.000,0.000,0.000>
  if (pos('>', my_response) < 1) then begin  // nicht vollständig
    inc(ResponseFaultCounter);
    exit;
  end;
  if (my_response[1] = '<') then begin
    my_response:= StringReplace(my_response,'<','',[rfReplaceAll]);
    my_response:= StringReplace(my_response,'>','',[rfReplaceAll]);
    my_response:= StringReplace(my_response,':',',',[rfReplaceAll]);
  end else begin
    inc(ResponseFaultCounter);
    exit;
  end;

  is_valid:= false;
  with Form1 do begin
    grbl_receveivelist.clear;
    grbl_receveivelist.CommaText:= my_response;
    if grbl_receveivelist.Count < 2 then
      exit;   // Meldung unvollständig
    my_Str:= grbl_receveivelist[0];
    if (my_Str = 'Idle') or (my_Str = 'Zero') then begin
      Panel1.Color:= clLime;
      Panel1.Font.Color:= clwhite;
      is_valid:= true;
      if (my_Str = 'Zero') then
        MachineState:= zero
      else
        MachineState:= idle;
    end else begin
      Panel1.Color:= $00004000;
      Panel1.Font.Color:= clgray;
    end;

    if (my_Str = 'Queue') or (my_Str =  'Hold') then begin
      is_valid:= true;
      Panel2.Color:= clAqua;
      Panel2.Font.Color:= clwhite;
      result:= true;
      MachineState:= hold;
    end else begin
      Panel2.Color:= $00400000;
      Panel2.Font.Color:= clgray;
    end;

    is_jogging:= AnsiContainsStr(my_Str,'Jog');
    if (my_Str = 'Run') or is_jogging then begin
      is_valid:= true;
      Panel3.Color:= clFuchsia;
      Panel3.Font.Color:= clwhite;
      result:= true;
      MachineState:= run;
    end else begin
      Panel3.Color:= $00400040;
      Panel3.Font.Color:= clgray;
    end;

    if my_Str = 'Alarm' then begin
      is_valid:= true;
      Panel4.Color:= clRed;
      Panel4.Font.Color:= clwhite;
      MachineState:= alarm;
    end else begin
      Panel4.Color:= $00000040;
      Panel4.Font.Color:= clgray;
    end;
    // keine gültige Statusmeldung?
    if not is_valid then begin
      inc(ResponseFaultCounter);
      exit;
    end;

    if is_jogging then begin  // Kurzmeldung von GRBL-JOG 0.9j
      if my_Str = 'JogX' then begin
        grbl_wpos.x:= StrDotToFloat(grbl_receveivelist[1]);
        PosX.Caption:= FormatFloat('000.00', grbl_wpos.x);
      end;
      if my_Str = 'JogY' then begin
        grbl_wpos.y:= StrDotToFloat(grbl_receveivelist[1]);
        PosY.Caption:= FormatFloat('000.00', grbl_wpos.y);
      end;
      if my_Str = 'JogZ' then begin
        grbl_wpos.z:= StrDotToFloat(grbl_receveivelist[1]);
        PosZ.Caption:= FormatFloat('000.00', grbl_wpos.z);
      end;
    end else begin
      my_start_idx:= grbl_receveivelist.IndexOf('MPos');
      if my_start_idx >= 0 then begin
        grbl_mpos.x:= StrDotToFloat(grbl_receveivelist[my_start_idx+1]);
        grbl_mpos.y:= StrDotToFloat(grbl_receveivelist[my_start_idx+2]);
        grbl_mpos.z:= StrDotToFloat(grbl_receveivelist[my_start_idx+3]);
      end;
      my_start_idx:= grbl_receveivelist.IndexOf('WPos');
      if my_start_idx >= 0 then begin
        grbl_wpos.x:= StrDotToFloat(grbl_receveivelist[my_start_idx+1]);
        grbl_wpos.y:= StrDotToFloat(grbl_receveivelist[my_start_idx+2]);
        grbl_wpos.z:= StrDotToFloat(grbl_receveivelist[my_start_idx+3]);
        PosX.Caption:= FormatFloat('000.00', grbl_wpos.x);
        PosY.Caption:= FormatFloat('000.00', grbl_wpos.y);
        PosZ.Caption:= FormatFloat('000.00', grbl_wpos.z);
      end;

    end;
  end;

  if (old_grbl_wpos.X <> grbl_wpos.X) or (old_grbl_wpos.Y <> grbl_wpos.Y) then begin
    pos_changed:= true;
    old_grbl_wpos:= grbl_wpos;
    NeedsRedraw:= true;
  end;
end;


procedure TForm1.TimerStatusElapsed(Sender: TObject);
// alle 25 ms aufgerufen. Statemachine, über Semaphoren gesteuert.
var pos_changed, my_error: Boolean;
  my_str, my_response: String;
begin
  if Form1.CheckBoxSim.Checked then
    StatusTimerState:= s_disable;
  case StatusTimerState of
    s_reset:
  // Zurücksetzen
      begin
        grbl_rx_clear; // letzte Antwort verwerfen
        if SendListRequest then begin  // hat Vorrang
          if grbl_sendlist.Count > 0 then
            StatusTimerState:= s_send
          else
            SendListDone:= true;
          SendListIdx:= 0;
          exit;
        end;
        if StatusTimerDisableRequest then
          StatusTimerState:= s_disable
        else begin
          grbl_rx_clear; // letzte Antwort verwerfen
          if grbl_is_connected then
            grbl_sendStr('?', false);   // neuen Status anfordern
          StatusTimerState:= s_idle_loop;
        end;
      end;

    s_send:
      begin
        SendListRequest:= false;
        if (SendListIdx >= grbl_sendlist.Count) or CancelRequest then begin
          grbl_sendlist.Clear;
          SendListIdx:= 0;
          SendListActive:= false;
          SendListDone:= true;
          if CancelRequest then begin
            StatusTimerState:= s_cancel;
            Form1.Memo1.lines.add('G-Code block processing cancelled');
          end else
            StatusTimerState:= s_reset;
          exit;
        end;

        if not grbl_is_connected then
          exit;

        my_str:= grbl_sendlist[SendListIdx];
        ProgressBar1.position:= SendListIdx;
        if length(my_str) > 1 then
          if (my_str[1] = '/') or (my_str[1] = '(') then
            inc(SendListIdx) // Index erhöhen wenn Kommentar
          else begin
            SendListActive:= true;
            // alles OK, neuen Befehl senden
            Form1.Memo1.lines.add(my_str);
            grbl_rx_clear; // letzte Antwort verwerfen
            grbl_sendStr(my_str + #13, false);
            StatusTimerState:= s_receive;
          end else

       end;
        // ohne erneuten Timeraufruf gleich weiter mit Empfang, fall bereits eingetroffen
    s_receive:
      begin
        if CancelRequest then begin
          grbl_sendlist.Clear;
          SendListIdx:= 0;
          SendListActive:= false;
          SendListDone:= true;
          StatusTimerState:= s_cancel;
          Form1.Memo1.lines.add('G-Code block processing cancelled');
          exit;
        end;
        if (grbl_receiveCount = 0) then begin // noch warten
// Zwischendurch-Abfragen führen immer wieder zu Kommunikationproblemen,
// deshalb vorerst abgeschaltet lassen.
//            StatusTimerState:= s_wait;
          exit;
        end;
        my_error:= false;
        LastResponseStr:= uppercase(grbl_receiveStr(10)); // reicht für OK
{
// Zwischendurch-Abfragen führen immer wieder zu Kommunikationproblemen,
// deshalb vorerst abgeschaltet lassen.
        if Pos('<', LastResponseStr) > 0 then begin
        // Zufällig noch eine übriggebliebene Status-Antwort?
        // Dekodieren un zur Sicherheit Empfang nochmal abrufen
          DecodeStatus(LastResponseStr, pos_changed);
          LastResponseStr:= uppercase(grbl_receiveStr(5))
        end;
}
        if pos('OK', LastResponseStr) > 0 then begin
        // nur nächsten Befehl anwählen, wenn OK,
        // sonst gleichen Befehl nochmal senden
          inc(SendListIdx);
          StatusTimerState:= s_send;
        end else begin
        // nicht OK, Alarmzustand, timeout oder Fehler
          if pos('ALARM', LastResponseStr) > 0 then begin
            Form1.Memo1.lines.add(LastResponseStr);
            Form1.Memo1.lines.add('ALARM state, processing cancelled');
            my_error:= true;
          end else if pos('ERROR', LastResponseStr) > 0 then begin
            Form1.Memo1.lines.add(LastResponseStr);
            Form1.Memo1.lines.add('ERROR state, processing cancelled');
            my_error:= true;
          end else begin
          // Bei Kommunikationsfehlern wird letzter Befehl nochmal gesendet
            Form1.Memo1.lines.add('SYNC FAULT, acknowledge missed');
            StatusTimerState:= s_send;
          end;
        end;
        if my_error then begin
          grbl_sendlist.Clear;
          SendListIdx:= 0;
          SendListActive:= false;
          SendListDone:= true;
          StatusTimerState:= s_reset;
          exit;
        end;
      end;

{
// Zwischendurch-Abfragen führen immer wieder zu Kommunikationproblemen,
// deshalb vorerst abgeschaltet lassen.
    s_wait:
      begin
        inc(StatusTimerLoopCount);
        if grbl_receiveCount > 0 then
        // könnte ein OK sein, wieder auf s_receive gehen
          StatusTimerState:= s_receive
        // wartet auf OK, gelegentlich neuen Status anfordern
        else if (StatusTimerLoopCount mod 5 = 0) and grbl_is_connected then begin
            grbl_sendStr('?', false);   // neuen Status anfordern
            StatusTimerState:= s_wait_status;  // und darauf warten
          end;
      end;

    s_wait_status:
      begin
        // wartet auf Status, muss inzwischen eingetroffen sein
        DecodeStatus(grbl_receiveStr(20), pos_changed);
        StatusTimerState:= s_receive;
      end;
}

    s_idle_loop:
      begin
    // Status auslesen
        if StatusTimerDisableRequest then
          StatusTimerState:= s_disable
        else begin
          StatusTimerEnableRequest:= false;  // erledigt
          pos_changed:= false;
          if grbl_is_connected then
            DecodeStatus(grbl_receiveStr(25), pos_changed); // muss eingetroffen sein
          SetDrawingToolPosMM(grbl_wpos.X, grbl_wpos.Y, grbl_wpos.Z);
          StatusTimerState:= s_reset;
          if (MachineState = zero) then begin
            Memo1.lines.add('');
            if HomingPerformed then begin
              WorkZeroX:= grbl_mpos.x;
              WorkZeroY:= grbl_mpos.y;
              WorkZeroZ:= grbl_mpos.Z - job.z_gauge;

              JogX:= WorkZeroX;
              JogY:= WorkZeroY;
              JogZ:= WorkZeroZ;

              Memo1.lines.add('Zero request from machine panel, will set X, Y to zero');
              Memo1.lines.add('and Z to Z gauge height from Job Defaults');
              my_str:= 'G92 X0 Y0 Z'+FloatToStrDot(job.z_gauge);
              my_response:= uppercase(grbl_sendStr(my_str + #13, true));
              Form1.Memo1.lines.add(my_str);
              ProbedState:= s_probed_manual;
              MachineState:= idle;
            end else
              Memo1.lines.add('Zero request ignored - no Home Cycle performed');
          end;
        end;
        CancelRequest:= false;
      end;

    s_cancel:
      begin
        grbl_sendlist.Clear;
        SendListIdx:= 0;
        if not grbl_is_connected then begin
          StatusTimerState:= s_reset;
          exit;
        end;
        if JobRunning then begin
          TimerStatus.enabled:= false;
          grbl_rx_clear; // letzte Antwort verwerfen
          grbl_sendStr('!', false);   // Feed Hold
          Memo1.lines.add('Cancel Job');
          Memo1.lines.add('=========================================');
          Memo1.lines.add('Feed hold, wait for stop...');
          repeat
            grbl_sendStr('?', false); // Position für Offsets anfordern
            mdelay(50);
            DecodeStatus(grbl_receiveStr(50), pos_changed);
          until not pos_changed;
          mdelay(100);
          Memo1.lines.add('Reset GRBL by CTRL-X');
          grbl_sendStr(#24, false);   // Reset CTRL-X, Maschine steht
          mdelay(250);
          SendListRequest:= false;
          SendActive:= false;
          CancelRequest:= false;
          Memo1.lines.add('Feed release, restore offsets');
          grbl_sendStr('~', false);   // Feed Hold löschen
          TimerStatus.enabled:= true;
        end;
        StatusTimerState:= s_reset;
        SendListDone:= true;
      end;

    s_disable:
  // abzuschalten
      begin
  // ggf. eintreffeden Müll löschen, der nach dem letzten Status-Request auflief.
        TimerStatus.enabled:= false;
        StatusTimerDisabled:= true;
        if CancelRequest then
          CancelRequest:= false;
      end;
  else
    StatusTimerState:= s_reset;
  end;
end;

// #############################################################################
// ########################### MAIN GCODE OUTPUT ###############################
// #############################################################################


procedure DisableStatus;
begin
  if StatusTimerDisabled then
    exit;
  StatusTimerDisableRequest:= true;
  repeat
    Application.ProcessMessages;
  until (StatusTimerDisabled) or (Form1.BtnCancel.Tag = 1);
  grbl_wait_for_timeout(20);
end;

procedure EnableStatus;
begin
  StatusTimerDisableRequest:= false;
  StatusTimerDisabled:= false;
  StatusTimerState:= s_reset;
  Form1.TimerStatus.enabled:= true;
  StatusTimerEnableRequest:= true;
{
  repeat
    Application.ProcessMessages;
  until (not StatusTimerEnableRequest) or CancelWait;
}
end;

// <Idle,MPos:40.001,35.989,-19.999,WPos:40.001,35.989,-19.999>  3-stellig, 61 Zeichen
// <Idle,MPos:40.00,35.98,-19.99,WPos:40.00,35.98,-19.99>  2-stellig 55 Zeichen
// 1 Zeichen dauert bei 19200  Bd 1/1920 s  = ca. 0,5 ms,   d.h. 35 ms für gesamten Satz
// 1 Zeichen dauert bei 115200 Bd 1/11520 s = ca. 0,086 ms, d.h. 7 ms für gesamten Satz

procedure WaitForIdle;
// Warte auf Idle
begin
  if Form1.CheckBoxSim.Checked then
    exit;
  mdelay(100);
  while (MachineState = run) do begin // noch beschäftigt?
    if (Form1.BtnCancel.Tag = 1) or CancelRequest then
      exit;     // Schleife abbrechen
    Application.ProcessMessages;
  end;
end;

procedure SendSingleCommandStr(my_command: String);
// Sende einzelnen Befehl, wird in TimerStatus ausgeführt
begin
  grbl_addStr(my_command);
  SendGrblAndWaitForIdle;
end;

procedure SendGrblAndWaitForIdle;
// Sende Befehlesliste und warte auf Idle
// lohnt, wenn mehrere Befehle abzuarbeiten sind
var
  my_str: String;
  i: Integer;
  pos_changed, response_error: Boolean;
begin
  NeedsRedraw:= true;
  if grbl_sendlist.Count = 0 then
    exit;
  if SendActive then begin  // nicht reentrant!
    Form1.Memo1.lines.add('WARNING: Send is active, ignored');
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
    exit;
  end;
  if (Form1.BtnCancel.Tag = 1) then
    exit;
  Form1.ProgressBar1.Max:= grbl_sendlist.Count;
  SendActive:= true;
  if Form1.CheckBoxSim.checked then begin
    gcsim_active:= true;          // für Cadencer-Prozess
    gcsim_render_final:= false;   // wird bei bedarf (z<0) in InterpretGcodeLine gesetzt
    LastResponseStr:='OK';
    for i:= 0 to grbl_sendlist.Count-1 do begin   // Alle Gcodes simulieren
      if CancelSim then
        break;
      if i mod 10 = 0 then begin            // etwas anderes passiert?
        Form1.ProgressBar1.position:= i;
        Application.ProcessMessages;
      end;
      my_str:= grbl_sendlist[i];
      if Form1.TrackbarSimSpeed.Position < 10 then
        Form1.Memo1.lines.add(my_str);
      InterpretGcodeLine(my_str);
    end;
    if gcsim_render_final then
      GLSfinalize3Dview;
    gcsim_active:= false;
  end else if grbl_is_connected then begin
    // Liste wird in Timerabgearbeitet
    SendListDone:= false;
    SendListRequest:= true;
    repeat
      application.ProcessMessages;
    until SendListDone;
  end;
  // falls wg. speed abgeschaltet
  Form4.GLLinesPath.Visible:= Form4.CheckToolpathVisible.Checked;
  Form4.GLDummyCubeTool.visible:= true;

  Form1.ProgressBar1.position:= 0;
  grbl_sendlist.Clear;
  SendActive:= false;
end;

// #############################################################################
// ######################### M A I N   M E N U #################################
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

