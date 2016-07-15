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
  FTDItypes, deviceselect, grbl_com, Vcl.ColorGrd, Vcl.Samples.Gauges;

const
  c_ProgNameStr: String = 'GRBLize ';
  c_VerStr: String = '1.3c';

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
    BtnRunJob: TSpeedButton;
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
    ComboBoxTip: TComboBox;
    Panel3: TPanel;
    PanelReady: TPanel;
    PanelAlarm: TPanel;
    Panel2: TPanel;
    Label6: TLabel;
    Bevel5: TBevel;
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
    ComboBoxGtip: TComboBox;
    ComboBoxGdia: TComboBox;
    Bevel7: TBevel;
    Label8: TLabel;
    BtnRunGcode: TSpeedButton;
    Label19: TLabel;
    EditZoffs: TEdit;
    CheckFixedProbeZ: TCheckBox;
    BtnZcontact: TSpeedButton;
    LabelTableX: TLabel;
    LabelTableY: TLabel;
    LabelTableZ: TLabel;
    Label31: TLabel;
    Bevel6: TBevel;
    Bevel9: TBevel;
    Label9: TLabel;
    CheckPartProbeZ: TCheckBox;
    PanelZdone: TPanel;
    Label44: TLabel;
    BtnListAssignments: TButton;
    LabelHintZ: TLabel;
    ToolBar1: TToolBar;
    ToolButton9: TToolButton;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    CheckBoxSim: TCheckBox;
    BtnCancel: TSpeedButton;
    BtnConnect: TBitBtn;
    BtnListTools: TButton;
    PanelYdone: TPanel;
    PanelXdone: TPanel;
    TabSheetATC: TTabSheet;
    BtnMoveToATC: TButton;
    BtnUnload: TButton;
    BtnLoad: TButton;
    BtnZeroAll: TSpeedButton;
    BtnSetFix1: TButton;
    BtnSetFix2: TButton;
    BtnSetPark: TButton;
    Label32: TLabel;
    sgATC: TStringGrid;
    Label48: TLabel;
    GerberImport1: TMenuItem;
    PanelToolInSpindle: TPanel;
    Label47: TLabel;
    CheckUseATC: TCheckBox;
    Bevel2: TBevel;
    Label24: TLabel;
    Label22: TLabel;
    BtnHomeOverride: TSpeedButton;
    BitBtn9: TBitBtn;
    BitBtn8: TBitBtn;
    BitBtn7: TBitBtn;
    BitBtn10: TBitBtn;
    BitBtn11: TBitBtn;
    BitBtn12: TBitBtn;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    BitBtn6: TBitBtn;
    Label17: TLabel;
    Label18: TLabel;
    BitBtn15: TBitBtn;
    BitBtn14: TBitBtn;
    BitBtn13: TBitBtn;
    BitBtn16: TBitBtn;
    BitBtn17: TBitBtn;
    BitBtn18: TBitBtn;
    BtnHomeCycle: TSpeedButton;
    BtnMovePark: TSpeedButton;
    BtnMoveFix1: TSpeedButton;
    BtnMoveFix2: TSpeedButton;
    Label20: TLabel;
    BtnMoveWorkZero: TSpeedButton;
    BtnMoveToolChange: TSpeedButton;
    LabelHintZ2: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Memo1: TMemo;
    Label13: TLabel;
    Label14: TLabel;
    BtnProbeTLC: TSpeedButton;
    PanelToolReferenced: TPanel;
    PanelToolCompensated: TPanel;
    Label21: TLabel;
    LabelToolReference: TLabel;
    BtnResetRef: TButton;
    Bevel4: TBevel;
    Bevel10: TBevel;
    PanelAlive: TPanel;
    Bevel11: TBevel;
    EditFirstToolDia: TEdit;
    LabelFaults: TLabel;
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
    procedure PanelAlarmClick(Sender: TObject);
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
    procedure ComboBoxTipMouseLeave(Sender: TObject);
    procedure ComboBoxTipKeyPress(Sender: TObject; var Key: Char);
    procedure BtnMoveFix2Click(Sender: TObject);
    procedure BtnMoveFix1Click(Sender: TObject);
    procedure BtnSetFix1Click(Sender: TObject);
    procedure BtnSetFix2Click(Sender: TObject);
    procedure BtnZeroAllClick(Sender: TObject);
    procedure BtnSetParkClick(Sender: TObject);
    procedure GerberImport1Click(Sender: TObject);
    procedure sgATCDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure sgATCSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure BtnCancelMouseEnter(Sender: TObject);
    procedure BtnCancelMouseLeave(Sender: TObject);
    procedure BtnHomeOverrideClick(Sender: TObject);
    procedure PanelToolReferencedClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure PanelAliveClick(Sender: TObject);
    procedure PanelReadyClick(Sender: TObject);

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

  function DecodeStatus(my_response: String; var pos_changed: Boolean): Boolean;
  procedure DisplayMachinePosition;
  procedure DisplayWorkPosition;

  procedure WaitForIdle;
  procedure SendSingleCommandStr(my_command: String);
  procedure SendListToGrbl;
  procedure ListBlocks;
  procedure EnableStatus;  // automatische Upates freischalten
  procedure DisableStatus;  // automatische Upates freischalten
  function isCancelled: Boolean;
  function isJobRunning: Boolean;
  function isEmergency: Boolean;
  function isWaitExit: Boolean;

  function UnloadTool(tool_idx: Integer): boolean;
  function LoadTool(tool_idx: Integer): boolean;
  procedure OpenFilesInGrid;
  procedure ForceToolPositions(x, y, z: Double);

type

    T3dFloat = record
      X: Double;
      Y: Double;
      Z: Double;
    end;
    t_mstates = (idle, run, hold, alarm, zero);
    t_alivestates = (s_alive_responded, s_alive_wait_indef, s_alive_wait_timeout);
    t_rstates = (s_reset, s_send, s_receive, s_wait, s_wait_status, s_idle_loop, s_disable, s_sim, s_cancel);
    t_pstates = (s_notprobed, s_probed_manual, s_probed_contact);


var
  SendActive: Boolean = false;    // true bis GRBL-Sendeschleife beendet

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
  StatusTimerLoopCount: Integer;

  LastRequest: Dword; // Wann zuletzt Status angefordert?
  LastResponseStr:String;
  ZeroRequestDone: Boolean;

  // für Simulation
  gcsim_x_old, gcsim_y_old, gcsim_z_old: Double;
  gcsim_seek: Boolean;
  gcsim_dia: Double;
  gcsim_feed: Integer;
  gcsim_active: Boolean;
  gcsim_tooltip: Integer;
  gcsim_color: TColor;
  AliveIndicatorDirection: Boolean;
  AliveCount: Integer;
  AliveState: t_alivestates;
  StopWatch: TStopwatch;

const
  c_zero_x = 50;
  c_zero_y = 50;
  c_zero_z = -25;

implementation

uses import_files, Clipper, About, bsearchtree, cam_view, gerber_import;

{$R *.dfm}

// #############################################################################
// #############################################################################

function isCancelled: Boolean;
begin
  result:= Form1.BtnCancel.Tag > 0;
end;

function isJobRunning: Boolean;
begin
  result:= (Form1.BtnRunJob.Tag > 0);
end;

function isEmergency: Boolean;
begin
  result:= Form1.BtnEmergStop.tag > 0;
end;

function isWaitExit: Boolean;
begin
  result:= Form1.PanelAlive.tag > 0;
end;

procedure TLed.SetLED(led_on: boolean);
// liefert vorherigen Zustand zurück
begin
  if led_on then begin
    Form1.PanelLED.Color:= clred;
    Form1.PanelLED.Font.Color:= clWhite;
    Screen.Cursor:= crHourGlass;
  end else begin
    Form1.PanelLED.Color:= $00000040;
    Form1.PanelLED.Font.Color:= clgray;
    Screen.Cursor:= crDefault;
  end;
  IsOn:= led_on;
end;

//##############################################################################

procedure DisplayMachinePosition;
begin
  with Form1 do begin
    MPosX.Caption:= FormatFloat('000.00', grbl_mpos.x);
    MPosY.Caption:= FormatFloat('000.00', grbl_mpos.y);
    MPosZ.Caption:= FormatFloat('000.00', grbl_mpos.z);
  end;
end;

procedure DisplayWorkPosition;
begin
  with Form1 do begin
    PosX.Caption:= FormatFloat('000.00', grbl_wpos.x);
    PosY.Caption:= FormatFloat('000.00', grbl_wpos.y);
    PosZ.Caption:= FormatFloat('000.00', grbl_wpos.z);
  end;
end;


procedure button_enable(my_state: Boolean);
begin
  if (MachineState >= run) then
    my_state:= false;
  with Form1 do begin
    BtnMoveWorkZero.Enabled:= my_state;
    BtnMovePark.Enabled:= my_state;
    BtnMoveFix1.Enabled:= my_state;
    BtnMoveFix2.Enabled:= my_state;
    BtnMoveToolChange.Enabled:= my_state;
    BtnMoveToATC.Enabled:= my_state;
    BtnUnload.Enabled:= my_state;
    BtnLoad.Enabled:= my_state;
    BtnZeroX.Enabled:= my_state;
    BtnZeroY.Enabled:= my_state;
    BtnZeroZ.Enabled:= my_state;
    BtnZeroAll.Enabled:= my_state;
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
    BtnRunJob.Enabled:= my_state and (length(final_array) > 0);
    BtnMoveWorkZero.Enabled:= my_state;
  end;
end;

procedure SetAllbuttons;
var is_idle, is_probed, is_notbusy: boolean;
  my_pen: Integer;
begin
  if not grbl_is_connected then begin
    Form1.CheckBoxSim.Checked:= true;
    Form1.CheckBoxSim.Enabled:= false;
  end;
  is_idle:= MachineState = idle;
  is_probed:= ProbedState <> s_notprobed;
  is_notbusy:= not isJobRunning;
  Form1.BtnCancel.Enabled:= not is_notbusy;
  if isCancelled then begin
    button_enable(false);
    button_run_enable(false);
    with Form1 do begin
      if TimerBlinkToggle then
        BtnCancel.Font.Color:= clred
      else
        BtnCancel.Font.Color:= clblack;
    end;
  end else begin
    button_enable(HomingPerformed);
    button_run_enable(is_idle and HomingPerformed and is_probed);
    with Form1 do begin
      BtnCancel.Font.Color:= clred;
      if CheckBoxSim.checked then begin
        BtnRunJob.Caption:= 'Simulate Job';
        BtnRunGcode.Caption:= 'Sim G-Code File';
      end else begin
        BtnRunJob.Caption:= 'Run Job';
        BtnRunGcode.Caption:= 'Run G-Code File';
      end;
    end;
  end;
  with Form1 do begin
    if (not HomingPerformed) and TimerBlinkToggle then
      BtnHomeCycle.Font.Color:= cllime
    else
      BtnHomeCycle.Font.Color:= clgreen;
    if grbl_is_connected and is_idle then begin
      BtnHomeCycle.Enabled:= is_idle;
      BtnSendGrblSettings.Enabled:= true;
      BtnRefreshGrblSettings.Enabled:= true;
    end else begin
      BtnHomeCycle.Enabled:= true;
      BtnSendGrblSettings.Enabled:= false;
      BtnRefreshGrblSettings.Enabled:= false;
    end;
    if length(final_array) > 0 then begin
      my_pen:= final_array[0].pen;
      EditFirstToolDia.Text:=  '#' + inttostr(my_pen)
        + ' = ' + FormatFloat('0.00', job.pens[my_pen].diameter) + ' mm'
        + #32 + ToolTipArray[job.pens[my_pen].tooltip];
    end else begin
      EditFirstToolDia.Text:=  '(probe dummy tool)';
    end;
  end;
end;


procedure ResetToolflags;
// Nach Homing, Connect etc: Unkalibrierter Zustand
begin
  SpindleRunning:= false;
  drawing_tool_down:= false;
  Form1.ProgressBar1.position:= 0;
  if Form1.CheckBoxSim.Checked then begin
    FirstToolReferenced:=true;
    CurrentToolCompensated:= true;
    WorkZeroXdone:= true;
    WorkZeroYdone:= true;
    WorkZeroZdone:= true;
    ProbedState:= s_probed_manual;
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
  grbl_mpos.x:= c_zero_x;
  grbl_mpos.y:= c_zero_y;
  grbl_mpos.z:= c_zero_z;
  grbl_wpos.x:= 0;
  grbl_wpos.y:= 0;
  grbl_wpos.z:= job.z_gauge;
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

procedure ForceToolPositions(x, y, z: Double);
begin
  if Form1.ShowDrawing1.Checked then
    SetDrawingToolPosMM(x, y, z);
  if Form1.Show3DPreview1.Checked and Form1.CheckBoxSim.Checked then begin
    GLSsetSimPositionMMxyz(x, y, z)
  end;
end;


procedure ResetSimulation;
// willkürliche Ausgangswerte, auch für Simulation
begin
  ResetCoordinates;
  gcsim_x_old:= grbl_wpos.x;
  gcsim_y_old:= grbl_wpos.y;
  gcsim_z_old:= grbl_wpos.z;
  WorkZeroX:= grbl_mpos.x - grbl_wpos.x;
  WorkZeroY:= grbl_mpos.y - grbl_wpos.y;
  WorkZeroZ:= grbl_mpos.z - grbl_wpos.z;
  gcsim_dia:= 3;
  JogX:= grbl_wpos.x;
  JogY:= grbl_wpos.y;
  JogZ:= grbl_wpos.z;
  ForceToolPositions(grbl_wpos.X, grbl_wpos.Y, -WorkZeroZ);
  GLSsimMillAtPosMM(grbl_wpos.x, grbl_wpos.y, grbl_wpos.z, gcsim_dia, false, true);
  GLSsetSimToolMM(gcsim_dia, gcsim_tooltip, clGray);
  GLSspindle_on_off(false);
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
{$I page_atc.inc}
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
  StopWatch:= TStopWatch.Create() ;
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

  SgGrblSettings.FixedCols:= 1;
  SgAppdefaults.FixedCols:= 1;

  Form4.FormRefresh(nil);

  BringToFront;
  Memo1.lines.add(''+ SetUpFTDI);

  ResetSimulation;
  ResetCoordinates;
  ResetToolflags;

  ToolInSpindle:= 0; // Dummy aus Slot 0
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

  Form4.FormRefresh(nil);
  UpdateATCsg;
  if FileExists(JobSettingsPath) then
    OpenJobFile
  else
    Form1.FileNew1Execute(sender);
  CheckEndPark.Checked:= job.parkposition_on_end;
  CheckFixedProbeZ.Checked:= job.use_fixed_probe;
  CheckUseATC.Checked:= job.atc_enabled;
  CheckPartProbeZ.Checked:= job.use_part_probe;
end;



procedure TForm1.GerberImport1Click(Sender: TObject);
begin
  GerberFileName:='';
  ConvertedFileName:='';
  GerberFileNumber:= 1;
  FormGerber.ShowModal;
end;

procedure TForm1.FileExitItemClick(Sender: TObject);
begin
  Close;
  StopWatch.free;
end;


procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Application.Terminate;
end;


procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  grbl_ini:TRegistry;
begin
  PanelAlive.tag:= 1;
  BtnCancel.tag:= 1;
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
  TimerStatus.Enabled:= false;
  TimerBlink.Enabled:= false;

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
var
  my_pen: Integer;
begin
  if LEDbusy.Checked then
    PageControl1.TabIndex:= 4;
  SgPens.Col:= 3;
  SgPens.Row:= 1;
  Form4.FormRefresh(sender);
end;

{procedure TForm1.PageControl1DrawTab(Control: TCustomTabControl;
  TabIndex: Integer; const Rect: TRect; Active: Boolean);
// PageControl1.OwnerDraw := True !
var
  CaptionX: Integer;
  CaptionY: Integer;
  TabCaption: string;
begin
  with Control.Canvas do begin
    if TabIndex = 3 then begin
      Font.Color := clred;
    end;
    if TabIndex = PageControl1.ActivePageIndex then
      Brush.Color := clSilver
    else
      Brush.Color := clBtnFace;

    TabCaption := PageControl1.Pages[TabIndex].Caption;
    CaptionX := Rect.Left + ((Rect.Right - Rect.Left - TextWidth(TabCaption)) div 2);
    CaptionY := Rect.Top + ((Rect.Bottom - Rect.Top - TextHeight('Gg')) div 2);

    FillRect(Rect);
    TextOut(CaptionX, CaptionY, TabCaption);
//    TextRect(Rect, Rect.Left + 2, Rect.Top + 2, TabCaption);
  end;
end;
}


procedure TForm1.PanelToolReferencedClick(Sender: TObject);
begin

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

procedure TForm1.BtnCancelMouseEnter(Sender: TObject);
begin
  Screen.Cursor:= crDefault;
end;

procedure TForm1.BtnCancelMouseLeave(Sender: TObject);
begin
  if (MachineState = run) or LEDbusy.Checked then
    Screen.Cursor:= crHourGlass;
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


procedure TForm1.Button1Click(Sender: TObject);
begin
  Form1.SgFiles.Cells[8,2]:='TEST';
end;

//##############################################################################


procedure TForm1.CheckBoxSimClick(Sender: TObject);
begin
  if Form1.CheckBoxSim.Checked then begin
    ResetCoordinates;
    Form4.GLSsetATCandProbe;
  end else begin
    ResetToolflags;
    HomingPerformed:= false;
    EnableStatus;
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

  TimerBlinkToggle:= not TimerBlinkToggle;

  // weniger aktuelle Sachen updaten
  if TimerBlinkToggle then begin
    LabelWorkX.Caption:= FormatFloat('000.00', WorkZeroX);
    LabelWorkY.Caption:= FormatFloat('000.00', WorkZeroY);
    LabelWorkZ.Caption:= FormatFloat('000.00', WorkZeroZ);
  end else begin
    LabelToolReference.Caption:= FormatFloat('00.00', ToolDelta);
    LabelTableX.Caption:= FormatFloat('000.00', job.table_x);
    LabelTableY.Caption:= FormatFloat('000.00', job.table_y);
    LabelTableZ.Caption:= FormatFloat('000.00', job.table_z);
    LabelHintZ.Caption:= '(+' + FormatFloat('00.00', job.z_gauge)+' mm)';
    LabelHintZ2.Caption:= '(+' + FormatFloat('00.00', job.z_penlift)+' mm)';
  end;

  SetAllButtons;
  Form4.LabelActive.Visible:= not CheckBoxSim.Checked;
  if (MachineState = idle) and (not isJobRunning) then begin
    LEDbusy.Checked:= false;
    Screen.Cursor:= crDefault;
  end;
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
  my_start_idx, x, y: Integer;
  is_valid, is_jogging: Boolean;
  alive_angle: Double;

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
    if AliveCount >= 7 then
      AliveIndicatorDirection:= false;
    if AliveCount <= 0 then
      AliveIndicatorDirection:= true;
    if AliveIndicatorDirection then
      inc(AliveCount)
    else
      dec(AliveCount);

    if (my_Str = 'Idle') or (my_Str = 'Zero') then begin
      PanelReady.Color:= clLime;
      PanelReady.Font.Color:= clwhite;
      is_valid:= true;
      if (my_Str = 'Zero') then
        MachineState:= zero
      else begin
        MachineState:= idle;
        ZeroRequestDone:= false;
      end;
    end else begin
      PanelReady.Color:= $00004000;
      PanelReady.Font.Color:= clgray;
    end;

    if (my_Str = 'Queue') or (my_Str =  'Hold') then begin
      ZeroRequestDone:= false;
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
      ZeroRequestDone:= false;
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
      ZeroRequestDone:= false;
      is_valid:= true;
      PanelAlarm.Color:= clRed;
      PanelAlarm.Font.Color:= clwhite;
      MachineState:= alarm;
      BtnEmergStop.tag:= 1;
    end else begin
      PanelAlarm.Color:= $00000040;
      PanelAlarm.Font.Color:= clgray;
    end;
    // keine gültige Statusmeldung?
    if not is_valid then begin
      ZeroRequestDone:= false;
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
        DisplayMachinePosition;
      end;
      my_start_idx:= grbl_receveivelist.IndexOf('WPos');
      if my_start_idx >= 0 then begin
        grbl_wpos.x:= StrDotToFloat(grbl_receveivelist[my_start_idx+1]);
        grbl_wpos.y:= StrDotToFloat(grbl_receveivelist[my_start_idx+2]);
        grbl_wpos.z:= StrDotToFloat(grbl_receveivelist[my_start_idx+3]);
        DisplayWorkPosition;
      end;

    end;
  end;

  if (MachineState = run) or (old_grbl_wpos.X <> grbl_wpos.X)
     or (old_grbl_wpos.Y <> grbl_wpos.Y) then begin
    pos_changed:= true;
    old_grbl_wpos:= grbl_wpos;
    NeedsRedraw:= true;
  end;
  if (MachineState = hold) then
    Form1.Cursor:= crHourGlass;
end;

procedure timer_send(my_str: String);
var
  my_response: String;
begin
  Form1.Memo1.lines.add(my_str);
  my_response:= grbl_sendStr(my_str + #13, true);
end;

procedure TimerSendListDone;
begin
  grbl_sendlist.Clear;
  SendListIdx:= 0;
  SendListActive:= false;
  SendListDone:= true;
end;

procedure TimerCommentDecode(my_str: String);
var idx, new_tooltip: Integer;
  new_color: TColor;
  new_dia: Double;
begin
  Form1.Memo1.lines.add(my_str);
  idx := pos('Bit change:', my_str);  // ist eigentlich ein Kommentar
  if idx > 0 then begin
    idx := pos(':', my_str) + 1;
    new_dia:= extract_float(my_str, idx, false);
    new_tooltip:= extract_int(my_str, idx);
    new_color:= extract_int(my_str, idx);
    GLSsetSimToolMM(new_dia, new_tooltip, new_color);
    if Form1.Show3DPreview1.Checked then // wird vorher aufgerufen
      GLSmakeToolArray(new_dia);
  end;
end;


procedure TForm1.TimerStatusElapsed(Sender: TObject);
// alle 25 ms aufgerufen. Statemachine, über Semaphoren gesteuert.
var pos_changed, my_error: Boolean;
  my_str, my_response: String;
begin
  if isEmergency then
    exit;
  if (not grbl_is_connected) or CheckBoxSim.checked then
    StatusTimerState:= s_sim
  else begin
    if SendListRequest then begin
      if grbl_sendlist.Count > 0 then
        StatusTimerState:= s_send
      else
        SendListDone:= true;
      SendListIdx:= 0;
      SendListRequest:= false;
    end;
    if StatusTimerDisableRequest then
      StatusTimerState:= s_disable;
  end;
  if BtnCancel.tag > 1 then      // hat Vorrang
    StatusTimerState:= s_cancel;

  case StatusTimerState of
    s_reset:
  // Zurücksetzen
      begin
        TimerStatus.Interval:= 50;
        grbl_rx_clear; // letzte Antwort verwerfen
        grbl_rx_clear; // letzte Antwort verwerfen
        if grbl_is_connected then
          grbl_sendStr('?', false);   // neuen Status anfordern
        StatusTimerState:= s_idle_loop;
      end;

    s_send:
      begin
        TimerStatus.Interval:= 20;
        if (SendListIdx >= grbl_sendlist.Count) then begin
          StatusTimerState:= s_reset;
          TimerSendListDone;
          exit;
        end;
        my_str:= grbl_sendlist[SendListIdx];
        ProgressBar1.position:= SendListIdx;
        if length(my_str) > 1 then begin
          if (my_str[1] = '/') or (my_str[1] = '(') then begin
            TimerCommentDecode(my_str);
            inc(SendListIdx); // Index erhöhen wenn Kommentar
          end else begin
            SendListActive:= true;
            // alles OK, neuen Befehl senden
            Form1.Memo1.lines.add(my_str);
            grbl_rx_clear; // letzte Antwort verwerfen
            grbl_sendStr(my_str + #13, false);
            StatusTimerState:= s_receive;
          end
        end;
      end;

    s_receive:
      begin
        if (grbl_receiveCount = 0) then begin // noch warten
// Zwischendurch-Abfragen führen immer wieder zu Kommunikationproblemen,
// deshalb vorerst abgeschaltet lassen.
//            StatusTimerState:= s_wait;
          AliveState:= s_alive_wait_indef;
          ShowAliveState;
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
          if pos('HOLD', LastResponseStr) > 0 then begin
            Form1.Memo1.lines.add(LastResponseStr);
            Form1.Memo1.lines.add('HOLD state, processing paused');
          end else if pos('ALARM', LastResponseStr) > 0 then begin
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
          TimerSendListDone;
          StatusTimerState:= s_reset;
        end;
      end;

    s_idle_loop:
      begin
    // Status auslesen
        TimerStatus.Interval:= 50;
        if StatusTimerDisableRequest then
          StatusTimerState:= s_disable
        else begin
          StatusTimerEnableRequest:= false;  // erledigt
          pos_changed:= false;
          if grbl_is_connected then
            DecodeStatus(grbl_receiveStr(25), pos_changed); // muss eingetroffen sein
          ForceToolPositions(grbl_wpos.X, grbl_wpos.Y, grbl_wpos.Z);
          StatusTimerState:= s_reset;
          SendListActive:= false;
          if (MachineState = zero) and (not ZeroRequestDone) then begin
            Memo1.lines.add('');
            if HomingPerformed then begin
              WorkZeroX:= grbl_mpos.x;
              WorkZeroY:= grbl_mpos.y;
              WorkZeroZ:= grbl_mpos.Z - job.z_gauge;

              JogX:= WorkZeroX;
              JogY:= WorkZeroY;
              JogZ:= WorkZeroZ;

              MposOnPartGauge:= grbl_mpos.Z;
              WorkZeroZ:= MposOnPartGauge - job.z_gauge;
              ProbedState:= s_probed_manual;

              Memo1.lines.add('Zero request from machine panel, will set X, Y to zero');
              Memo1.lines.add('and Z to Z gauge height from Job Defaults');
              my_str:= 'G94';
              my_response:= uppercase(grbl_sendStr(my_str + #13, true));
              Form1.Memo1.lines.add(my_str);
              my_str:= 'G92 X0 Y0 Z'+FloatToStrDot(job.z_gauge);
              my_response:= uppercase(grbl_sendStr(my_str + #13, true));
              Form1.Memo1.lines.add(my_str);
              WorkZeroXdone:= true;
              WorkZeroYdone:= true;
              WorkZeroZdone:= true;

              FirstToolReferenced:= false;
              CurrentToolCompensated:= false;
              MachineState:= idle;
            end else
              Memo1.lines.add('WARNING: Zero request ignored - no Home Cycle performed');
            ZeroRequestDone:= true;
          end;
        end;
      end;

    s_disable:
      begin
  // abzuschalten
  // ggf. eintreffeden Müll löschen, der nach dem letzten Status-Request auflief.
        TimerStatus.enabled:= false;
        StatusTimerDisabled:= true;
        SendListActive:= false;
      end;

    s_sim:
      begin
        TimerStatus.Interval:= 20;
        StatusTimerDisabled:= StatusTimerDisableRequest;
        if (SendListIdx >= grbl_sendlist.Count) or (grbl_sendlist.Count = 0) then begin
          TimerSendListDone;
          gcsim_active:= false;
          ForceToolPositions(grbl_wpos.X, grbl_wpos.Y, grbl_wpos.Z);
          exit;
        end;
        gcsim_active:= true;          // für Cadencer-Prozess
        gcsim_render_final:= false;   // wird bei bedarf (z<0) in InterpretGcodeLine gesetzt
        my_str:= grbl_sendlist[SendListIdx];
        ProgressBar1.position:= SendListIdx;
        if length(my_str) > 1 then begin
          if (my_str[1] = '/') or (my_str[1] = '(') then begin
            TimerCommentDecode(my_str);
            inc(SendListIdx); // Index erhöhen wenn Kommentar
          end else begin
            SendListActive:= true;
            // alles OK, neuen Befehl senden
            Form1.Memo1.lines.add(my_str);
            TimerStatus.enabled:= false;
            InterpretGcodeLine(my_str);
            TimerStatus.enabled:= true;
            NeedsRedraw:= true;
          end;
        end;
        inc(SendListIdx); // Index erhöhen
        DisplayWorkPosition;
        DisplayMachinePosition;
      end;

    s_cancel:
      begin
        TimerStatus.Interval:= 50;
        Memo1.lines.add('');
        Memo1.lines.add('Cancel Job');
        Memo1.lines.add('=========================================');
        Memo1.lines.add('Feed hold "!", wait for stop...');
        if grbl_is_connected and (not Form1.CheckBoxSim.Checked) then begin
          TimerStatus.enabled:= false;
          grbl_sendStr('!', false);   // Feed Hold
          mdelay(100);
          grbl_rx_clear; // letzte Antwort verwerfen
          repeat
            grbl_sendStr('?', false); // Position für Offsets anfordern
            mdelay(50);
            DecodeStatus(grbl_receiveStr(50), pos_changed);
          until (not pos_changed) and (MachineState = hold) or isEmergency;
          mdelay(100);
          Memo1.lines.add('Reset GRBL by "CTRL-X"');
          grbl_sendStr(#24, false);   // Reset CTRL-X, Maschine steht
          mdelay(250);
          SpindleRunning:= false;
          SendListRequest:= false;
          SendActive:= false;
          Memo1.lines.add('Feed release "~"');
          grbl_sendStr('~', false);   // Feed Hold löschen
          StatusTimerState:= s_reset;
          ResetATC;
          grbl_rx_clear; // letzte Antwort verwerfen
          Memo1.lines.add('');
          Memo1.lines.add('Unlock Alarm State');
          timer_send('$X');   // Unlock
          Memo1.lines.add('Move Z up');
          timer_send('G0 G53 Z0');   // Move up
          repeat
            grbl_sendStr('?', false); // Position für Offsets anfordern
            mdelay(50);
            DecodeStatus(grbl_receiveStr(50), pos_changed);
          until (not pos_changed) and (MachineState = idle) or isEmergency;
          Memo1.lines.add('Restore Offsets');
          timer_send('G92 Z'+FloatToStrDot(-WorkZeroZ)); // wir sind auf 0
          timer_send('G92 X'+ FloatToSTrDot(grbl_mpos.X - WorkZeroX)
            +' Y'+ FloatToSTrDot(grbl_mpos.Y - WorkZeroY));
          mdelay(100);
          TimerStatus.enabled:= true;
          Memo1.lines.add('Done.');
        end else begin
          Memo1.lines.add('Reset GRBL by "CTRL-X"');
          Memo1.lines.add('Feed release "~"');
          Memo1.lines.add('Unlock Alarm State');
          Memo1.lines.add('Move Z up');
          Memo1.lines.add('G0 G53 Z0');
          GLSspindle_on_off(false);
          ForceToolPositions(grbl_wpos.X, grbl_wpos.Y, 10);
          grbl_wpos.Z:= -WorkZeroZ;
          grbl_mpos.Z:= 0;
          DisplayWorkPosition;
          DisplayMachinePosition;
          Memo1.lines.add('Done.');
        end;
        TimerSendListDone;
        gcsim_active:= false;
        BtnCancel.tag:= 0;
        BtnRunjob.tag:= 0;
      end
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
  until (StatusTimerDisabled)  or isEmergency;
  StatusTimerDisableRequest:= false;
  grbl_wait_for_timeout(20);
end;

procedure EnableStatus;
begin
  StatusTimerDisableRequest:= false;
  StatusTimerDisabled:= false;
  StatusTimerState:= s_reset;
  Form1.TimerStatus.enabled:= true;
  StatusTimerEnableRequest:= true;
  Form1.TimerStatus.Interval:= 50;
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
  if not Form1.CheckBoxSim.Checked then
    repeat
      mdelay(50);
    until (MachineState <> run) or isCancelled or isEmergency or isWaitExit; // noch beschäftigt?
end;

procedure SendSingleCommandStr(my_command: String);
// Sende einzelnen Befehl, wird in TimerStatus ausgeführt
begin
  grbl_addStr(my_command);
  SendListToGrbl;
end;


procedure SendListToGrbl;
// Sende Befehlesliste und warte auf Idle
// lohnt, wenn mehrere Befehle abzuarbeiten sind
var
  my_str: String;
  i: Integer;
  pos_changed, response_error: Boolean;
begin
  gcsim_render_final:= false;
  NeedsRedraw:= true;
  if grbl_sendlist.Count = 0 then
    exit;
  if SendActive then begin  // nicht reentrant!
    Form1.Memo1.lines.add('WARNING: Send is active, ignored');
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
    exit;
  end;
  if isCancelled then
    exit;
  Form1.ProgressBar1.Max:= grbl_sendlist.Count;
  SendActive:= true;
  // Liste wird in Timerabgearbeitet
  SendListDone:= false;
  SendListRequest:= true;
  repeat
    mdelay(50);
  until SendListDone or isCancelled or isEmergency;
  // falls wg. speed abgeschaltet
  Form4.GLLinesPath.Visible:= Form4.CheckToolpathVisible.Checked;
  Form4.GLDummyCubeTool.visible:= true;

  Form1.ProgressBar1.position:= 0;
  grbl_sendlist.Clear;
  SendActive:= false;
  if gcsim_render_final then
    GLSfinalize3Dview;
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



procedure TForm1.BtnEmergencyStopClick(Sender: TObject);
var
  my_response: String;
begin
  PanelAlive.tag:= 1;
  BtnCancel.tag:= 1;
  BtnRunJob.Tag:= 0;
  button_enable(false);
  ResetToolflags;
  SendActive:= false;
  Memo1.lines.add('');
  Memo1.lines.add('WARNING: Emergency Stop');
  Memo1.lines.add('=========================================');
  // E-Stop ausführen
  if grbl_is_connected and (not CheckBoxSim.checked) then begin
    grbl_sendStr(#24, false);   // Soft Reset CTRL-X, Stepper sofort stoppen
    SpindleRunning:= false;
    mdelay(250);
    BtnEmergStop.tag:= 1;
    DisableStatus;
    grbl_wait_for_timeout(250);
    MessageDlg('EMERGENCY STOP. Steps missed if running.'
      + #13 + 'Click <Home Cycle> or <Alarm> panel'
      + #13 + 'to release ALARM LOCK.', mtWarning, [mbOK], 0);
    EnableStatus;  // automatische Upates freischalten
  end else begin
    Memo1.lines.add('Reset GRBL Simulation');
  end;
  HomingPerformed:= false;
  grbl_sendlist.Clear;
  ResetATC;
  Memo1.lines.add('Done. Please re-run Home Cycle.');
  Memo1.lines.add('');
end;

procedure TForm1.BtnCancelClick(Sender: TObject);
var
  my_response: String;
  pos_changed: Boolean;
begin
  if not isJobRunning then
    exit;
  BtnCancel.tag:= 1;
  BtnRunJob.Tag:= 0;
  Memo1.lines.add('');
  Memo1.lines.add('Processing Cancel Request...');
  // Wird von Timer-Interrupt erledigt
end;


procedure TForm1.BtnHomeCycleClick(Sender: TObject);
var
  my_response: String;
begin
  PanelAlive.tag:= 0;
  BtnEmergStop.tag:= 0;
  BtnCancel.Caption:= 'CANCEL';
  BtnCancel.tag:= 0;
  BtnRunjob.tag:= 0;
  Memo1.lines.add('');
  Memo1.lines.add('Home cycle initiated');
  DefaultsGridListToJob;
  if grbl_is_connected and (not CheckBoxSim.checked) then begin
    LEDbusy.Checked:= true;
    spindle_on_off(false);
    ResetToolflags;
    DisableStatus;
    my_response:= grbl_sendStr('$h'+#13, true);
    Memo1.lines.add(uppercase(my_response));
    if my_response <> 'ok' then begin
      MessageDlg('Homing failed. ALARM LOCK cleared,'
        + #13 + 'but do not rely on machine status.', mtWarning, [mbOK], 0);
      grbl_sendStr('$X'+#13, false);   // Clear Lock
      grbl_wait_for_timeout(200);
    end;
    EnableStatus;  // automatische Upates freischalten
  end else
    ResetSimulation;
  HomingPerformed:= true;
  Memo1.lines.add('Done.');
  Memo1.lines.add('');
end;

procedure TForm1.BtnHomeOverrideClick(Sender: TObject);
begin
  BtnEmergStop.tag:= 0;
  BtnCancel.tag:= 0;
  BtnRunjob.tag:= 0;
  Memo1.lines.add('');
  if CheckBoxSim.checked then
    Memo1.lines.add('Home Cycle Override always on in simulation mode.')
  else
    Memo1.lines.add('Home Cycle Override initiated');
  DefaultsGridListToJob;
  if sim_not_supportet(true) then
    ResetSimulation
  else begin
    LEDbusy.Checked:= true;
    spindle_on_off(false);
    ResetToolflags;
    if grbl_is_connected and (not CheckBoxSim.checked) then begin
      DisableStatus;
      Memo1.lines.add('WARNING: Home Cycle Override - do not rely on absolute positions!');
      grbl_sendStr('$X'+#13, false);   // Clear Lock
      grbl_wait_for_timeout(200);
      Memo1.lines.add('Unlock Alarm State');
      EnableStatus;  // automatische Upates freischalten
    end;
  end;
    Memo1.lines.add('Done. Proceed with care!');
  HomingPerformed:= true;
  Memo1.lines.add('');
end;

procedure TForm1.PanelReadyClick(Sender: TObject);
begin
  Memo1.lines.add('Receive resumed');
  PanelAlive.tag := 0;
end;

procedure TForm1.PanelAlarmClick(Sender: TObject);
begin
  BtnEmergStop.tag:= 0;
  BtnCancel.tag:= 0;
  BtnRunjob.tag:= 0;
  Memo1.lines.add('');
  DefaultsGridListToJob;
  if sim_not_supportet(true) then
    ResetSimulation
  else begin
    ResetToolflags;
    if grbl_is_connected and (not CheckBoxSim.checked) then begin
      DisableStatus;
      grbl_sendStr('$X'+#13, false);   // Clear Lock
      grbl_wait_for_timeout(200);
      Memo1.lines.add('Unlock Alarm State');
      EnableStatus;  // automatische Upates freischalten
    end;
  end;
    Memo1.lines.add('Done. Proceed with care!');
  Memo1.lines.add('');
end;

procedure TForm1.PanelAliveClick(Sender: TObject);
begin
  PanelAlive.tag := 1;
  Memo1.lines.add('WARNING: Receive cancelled');
  Memo1.lines.add('Click READY panel to resume');
end;

end.

