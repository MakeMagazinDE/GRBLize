unit grbl_player_main;
// CNC-Steuerung für GRBL-JOG-Platine mit GRBL 0.8c/jog.2 Firmware
// oder GRBL 0.9j mit DEFINE GRBL115

{$DEFINE GRBL_11}
{$DEFINE FOUR_AXIS}

{$IFDEF GRBL_11}
//  {.$EXTENSION 11.exe}
{$ELSE}
//  {.$EXTENSION 09.exe}
{$ENDIF}

interface

uses
  Math, StdCtrls, ComCtrls, ToolWin, Buttons, ExtCtrls, ImgList,
  Controls, StdActns, Classes, ActnList, Menus, GraphUtil,
  SysUtils, StrUtils, Windows, Graphics, Forms, Messages,
  Dialogs, Spin, FileCtrl, Grids, Registry, ShellApi, MMsystem,
  VFrames, ExtDlgs, XPMan, CheckLst, drawing_window,
  glscene_view, GLColor, ValEdit, System.ImageList, System.Actions,
  FTDItypes, deviceselect, grbl_com, Vcl.ColorGrd, Vcl.Samples.Gauges, System.UItypes,
  app_defaults;

const
  c_ProgNameStr: String = 'GRBLize ';
  c_VerStr: String = '1.5c';
  c_unloadATCstr: String = 'M8';
  c_loadATCstr: String = 'M9';
{$IFDEF GRBL_11}
  c_Grbl_VerStr: String = 'for GRBL 1.1 ';
{$ELSE}
  c_Grbl_VerStr: String = 'for GRBL 0.9 ';
{$ENDIF}

type
  TPOVControl = record   // Joystick control
    up,down,left,right:boolean;
    raw: Integer;
    active: Boolean;
  end;

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
    PanelBusy: TPanel;
    PanelRun: TPanel;
    PanelReady: TPanel;
    PanelAlarm: TPanel;
    PanelHold: TPanel;
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
    CheckTLCprobe: TCheckBox;
    LabelTableX: TLabel;
    LabelTableY: TLabel;
    LabelTableZ: TLabel;
    Label31: TLabel;
    Bevel6: TBevel;
    Bevel9: TBevel;
    CheckPartProbeZ: TCheckBox;
    PanelZdone: TPanel;
    LabelHintZ: TLabel;
    ToolBar1: TToolBar;
    ToolButton9: TToolButton;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    CheckBoxSim: TCheckBox;
    BtnCancel: TSpeedButton;
    BtnConnect: TBitBtn;
    PanelYdone: TPanel;
    PanelXdone: TPanel;
    BtnZeroAll: TSpeedButton;
    Label48: TLabel;
    GerberImport1: TMenuItem;
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
    BtnMoveXYzero: TSpeedButton;
    BtnMoveToolChange: TSpeedButton;
    LabelHintZ2: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Memo1: TMemo;
    Label13: TLabel;
    Bevel4: TBevel;
    Bevel10: TBevel;
    PanelAlive: TPanel;
    EditFirstToolDia: TEdit;
    CheckToolChange: TCheckBox;
    CheckUseATC2: TCheckBox;
    sgATC: TStringGrid;
    LabelATCmsg: TLabel;
    BtnSetPark: TButton;
    BtnSetFix1: TButton;
    BtnSetFix2: TButton;
    BtnHomeOverride: TSpeedButton;
    Bevel11: TBevel;
    Label10: TLabel;
    Label24: TLabel;
    PopupMenuATC: TPopupMenu;
    pu_MovetoATCslot: TMenuItem;
    pu_LoadFromATCslot: TMenuItem;
    N1: TMenuItem;
    pu_ProbeToolLengthRef: TMenuItem;
    pu_ProbetoolLengthComp: TMenuItem;
    BtnRunTool: TSpeedButton;
    BtnMoveMillCenter: TSpeedButton;
    BtnZcontact: TSpeedButton;
    Label9: TLabel;
    Bevel2: TBevel;
    Label14: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    BtnMoveZzero: TSpeedButton;
    Action1: TAction;
    PopupMenuShape: TPopupMenu;
    ms_contour: TMenuItem;
    ms_inside: TMenuItem;
    ms_outside: TMenuItem;
    ms_pocket: TMenuItem;
    ms_drill: TMenuItem;
    PopupMenuTooltip: TPopupMenu;
    mt_flat: TMenuItem;
    mt_cone30: TMenuItem;
    mt_cone45: TMenuItem;
    mt_cone60: TMenuItem;
    mt_cone90: TMenuItem;
    mt_ballnose: TMenuItem;
    mt_drill: TMenuItem;
    PopupMenuBlockShape: TPopupMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    TabUtils: TTabSheet;
    MemoUtils1: TMemo;
    BtnUtilsSquare: TSpeedButton;
    ScrollUtilsFeed: TScrollBar;
    LabelUtilsFeed: TLabel;
    EditUtilsZend: TEdit;
    EditUtilsZinc: TEdit;
    Label30: TLabel;
    BtnUtilsReset: TBitBtn;
    EditCornerX: TEdit;
    EditCornerY: TEdit;
    Label34: TLabel;
    Label35: TLabel;
    BtnSetCorner: TButton;
    Label29: TLabel;
    BtnUtilsCircle: TSpeedButton;
    BtnSetRadius: TButton;
    Label37: TLabel;
    EditRadius: TEdit;
    BtnCirclePocket: TSpeedButton;
    BtnCircleOutline: TSpeedButton;
    Label38: TLabel;
    BtnSquareOutline: TSpeedButton;
    BtnSquarePocket: TSpeedButton;
    Label32: TLabel;
    EditToolDia: TEdit;
    Label33: TLabel;
    UpDown1: TUpDown;
    UpDown2: TUpDown;
    UpDown3: TUpDown;
    Label36: TLabel;
    Label19: TLabel;
    LabelJoyInfo: TLabel;
    LabelJoySend: TLabel;
    BtnReloadAll: TButton;
    PanelPinState: TPanel;
    LabelStatusFaults: TLabel;
    LabelResponse: TLabel;
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
    procedure BtnMoveXYzeroClick(Sender: TObject);
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
    procedure ComboBoxGtipChange(Sender: TObject);
    procedure ComboBoxGdiaChange(Sender: TObject);
    procedure RunGcode(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CheckBoxSimClick(Sender: TObject);
    procedure BitBtnJogMouseDown(Sender: TObject; Button: TMouseButton;
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
    procedure BtnZcontactClick(Sender: TObject);
    procedure CheckTLCprobeClick(Sender: TObject);
    procedure BtnRescanClick(Sender: TObject);
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
    procedure PanelAliveClick(Sender: TObject);
    procedure PanelReadyClick(Sender: TObject);
    procedure CheckToolChangeClick(Sender: TObject);
    procedure PanelHoldClick(Sender: TObject);
    procedure BtnRunJobClick(Sender: TObject);
    procedure CheckUseATC2Click(Sender: TObject);
    procedure pu_MovetoATCslotClick(Sender: TObject);
    procedure pu_LoadFromATCslotClick(Sender: TObject);
    procedure pu_ProbeToolLengthRefClick(Sender: TObject);
    procedure sgATCMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pu_ProbetoolLengthCompClick(Sender: TObject);
    procedure BtnRunToolClick(Sender: TObject);
    procedure BtnMoveMillCenterClick(Sender: TObject);
    procedure BtnMoveZzeroClick(Sender: TObject);
    procedure mt_Click(Sender: TObject);
    procedure ms_Click(Sender: TObject);
    procedure mbs_click(Sender: TObject);
    procedure BtnUtilsSquareClick(Sender: TObject);
    procedure ScrollUtilsFeedChange(Sender: TObject);
    procedure BtnUtilsResetClick(Sender: TObject);
    procedure BtnSetCornerClick(Sender: TObject);
    procedure EditCornerKeyPress(Sender: TObject; var Key: Char);
    procedure BtnSetRadiusClick(Sender: TObject);
    procedure BtnUtilsCircleClick(Sender: TObject);
    procedure BtnCircleOutlineClick(Sender: TObject);
    procedure BtnCirclePocketClick(Sender: TObject);
    procedure BtnSquareOutlineClick(Sender: TObject);
    procedure BtnSquarePocketClick(Sender: TObject);
    procedure EditRadiusKeyPress(Sender: TObject; var Key: Char);
    procedure PageControl1DrawTab(Control: TCustomTabControl; TabIndex: Integer;
      const Rect: TRect; Active: Boolean);
    procedure PageControl1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure UpDown1ChangingEx(Sender: TObject; var AllowChange: Boolean;
      NewValue: Integer; Direction: TUpDownDirection);
    procedure UpDown2ChangingEx(Sender: TObject; var AllowChange: Boolean;
      NewValue: Integer; Direction: TUpDownDirection);
    procedure UpDown3ChangingEx(Sender: TObject; var AllowChange: Boolean;
      NewValue: Integer; Direction: TUpDownDirection);
    procedure SgFilesExit(Sender: TObject);
    procedure SgFilesClick(Sender: TObject);
    procedure BtnReloadAllClick(Sender: TObject);


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

  { TGamepad - A wrapper class for the Windows-Joystick-API}
  TGamepad = class
    private
      FRange:integer;
      FDeadZone:integer;
      function GetButton(index:integer):boolean;
      function GetX:integer;
      function GetY:integer;
      function GetZ:integer;
      function GetR:integer;
      function GetU:integer;
      function GetV:integer;
      function GetAnalogActive:Boolean;
      function GetPOV:TPOVControl;
      procedure UpdateDeviceNr(nr:cardinal);
    protected
      Device:TJoyInfoEx;
      DeviceInfo:TJoyCaps;
      FDeviceNr:Cardinal;
      CenterX,CenterY,CenterZ:Integer;
      CenterR,CenterU,CenterV:Integer;
    public
      property DeviceNr:Cardinal read FDeviceNr write UpdateDeviceNr;
      procedure Update;
      procedure Calibrate;
      constructor Create;
      property X:integer read GetX;
      property Y:integer read GetY;
      property Z:integer read GetZ;
      property R:integer read GetR;
      property U:integer read GetU;
      property V:integer read GetV;
      property IsAnalogActive:Boolean read GetAnalogActive;
      property Range:integer read FRange write FRange;
      property DeadZone:integer read FDeadZone write FDeadZone;
      property POV:TPOVControl read GetPov;
      property Buttons[index:integer]:boolean read GetButton;
  end;

  function DecodeStatus(my_response: String): Boolean;
  procedure DisplayMachinePosition;
  procedure DisplayWorkPosition;

  procedure WaitForIdle;

  // dekodiert Antwort von GRBL und zeigt ggf. Meldungszeile:
  function ResponseMsg(my_str:String): boolean;
  // bei abgeschaltetem Status senden und empfangen:
  function SendReceive(my_cmd: String; my_timeout: Integer): String;
  function SendReceiveAndDwell(my_cmd: String): String;

  procedure SendSingleCommandStr(my_command: String);
  procedure SendSingleCommandAndDwell(my_command: String);

  procedure SendListToGrbl;

  function ListBlocks: boolean;
  procedure EnableStatus;  // automatische Upates freischalten
  procedure DisableStatus;  // automatische Upates freischalten
  function isCancelled: Boolean;
  function isJobRunning: Boolean;
  function isEmergency: Boolean;
  function isWaitExit: Boolean;
  function isSimActive: Boolean;
  function isGrblActive: Boolean;

  function ManualToolchange(atc_idx_old, atc_idx_new: Integer; do_tlc: boolean): Boolean;
  procedure ChangeATCtool(atc_idx_old, atc_idx_new: Integer; do_tlc: boolean);
  procedure UnloadATCtool(atc_idx: Integer);
  procedure LoadATCtool(atc_idx: Integer; do_tlc: boolean);
  procedure OpenFilesInGrid;
  procedure ForceToolPositions(x, y, z: Double);

  procedure AutoAssignATCtoolsToJob;
  procedure UpdateATC;
  procedure ClearATCarray;
  procedure InvalidateTLCs;
  procedure ClearAlarmLock;

type

    T3dFloat = record
      X: Double;
      Y: Double;
      Z: Double;
    end;
    t_mstates = (none, idle, run, hold, alarm, zero);
    t_rstates = (s_reset, s_request, s_receive, s_sim);
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
  JobSettingsPath: String;

  grbl_mpos, grbl_wpos, old_grbl_wpos, grbl_wco: T3dFloat;
  grbl_feed_ov, grbl_seek_ov, grbl_speed_ov: Integer;
  grbl_feed, grbl_speed: Integer;
  MouseJogAction: Boolean;
  open_request, ftdi_was_open, com_was_open: boolean;
  WorkZeroX, WorkZeroY, WorkZeroZ: Double;  // Absolutwerte Werkstück-Null
  JogX, JogY, JogZ: Double;  // Absolutwerte Jogpad
  HomingPerformed: Boolean;

  MposOnFixedProbe, MposOnPartGauge: Double;
  MposOnFixedProbeReference: Double;
  WorkZeroXdone, WorkZeroYdone, WorkZeroZdone, WorkZeroAllDone: Boolean;
//  ProbedState: t_pstates;

  LastToolUsed: Integer = 1;  // Zuletzt Benutztes Tool im Job, 0 = unused
  ToolInSpindle: Integer = 1; // ATC-Tool in der Maschine, 0 = unused
  StatusFaultCounter: Integer = 0;
  SpindleRunning: Boolean;

  TimerBlinkToggle: Boolean;

//  StatusTimerState: t_rstates; // (none, status, response);
  MachineState: t_mstates;  // (idle, run, hold, alarm)GRBL ist in Ruhe wenn state_idle

  LastResponseStr:String;

  // für Simulation
  gcsim_x_old, gcsim_y_old, gcsim_z_old: Double;
  gcsim_seek: Boolean;
  gcsim_dia: Double;
  gcsim_feed: Integer;
  gcsim_active: Boolean;
  gcsim_tooltip: Integer;
  gcsim_color: TColor;
  StopWatch: TStopwatch;
  StartupDone: Boolean = false;
  SquareCorner_wpos, SquareCorner_mpos: T3dFloat;
  InstantZ_end, InstantZ_inc: Double;
  SquarePocket: Boolean;
  SquareCornerManualEnter, SquareCornerSetToMpos: Boolean;
  CirclePocket: Boolean;
  CircleRadiusManualEnter, CircleRadiusSetToMpos: Boolean;
  CircleRadius: Double;
  CircleRadius_wpos, CircleRadius_mpos: T3dFloat;

  JoyPad: TGamepad;
  JoyPadWasActive: Boolean = false;
  SavedPortnameForSim: String;

const
   // für Simulation
  c_zero_x = 50;
  c_zero_y = 50;
  c_zero_z = -25;
  c_numATCslots = 9;

  SettingCodes_11_3: Array[0..35] of String[31] = (
    'Step pulse time',
    'Step idle delay',
    'Step pulse invert mask',
    'Step direction invert mask',
    'Invert step enable pin',
    'Invert limit pins',
    'Invert probe pin',
    'Status report options',
    'Junction deviation',
    'Arc tolerance',
    'Report in inches',
    'Soft limits enable',
    'Hard limits enable',
    'Homing cycle enable',
    'Homing direction invert mask',
    'Homing locate feed rate',
    'Homing search seek rate',
    'Homing switch debounce delay',
    'Homing switch pull-off distance',
    'Maximum spindle speed',
    'Minimum spindle speed',
    'Laser-mode enable',
    'X-axis travel resolution',
    'Y-axis travel resolution',
    'Z-axis travel resolution',
    'X-axis maximum rate',
    'Y-axis maximum rate',
    'Z-axis maximum rate',
    'X-axis acceleration',
    'Y-axis acceleration',
    'Z-axis acceleration',
    'X-axis maximum travel',
    'Y-axis maximum travel',
    'Z-axis maximum travel',
    '(none)',
    '(none)'
    );

  SettingCodes_11_4: Array[0..39] of String[31] = (
    'Step pulse time',
    'Step idle delay',
    'Step pulse invert mask',
    'Step direction invert mask',
    'Invert step enable pin',
    'Invert limit pins',
    'Invert probe pin',
    'Status report options',
    'Junction deviation',
    'Arc tolerance',
    'Report in inches',
    'Soft limits enable',
    'Hard limits enable',
    'Homing cycle enable',
    'Homing direction invert mask',
    'Homing locate feed rate',
    'Homing search seek rate',
    'Homing switch debounce delay',
    'Homing switch pull-off distance',
    'Maximum spindle speed',
    'Minimum spindle speed',
    'Laser-mode enable',
    'X-axis travel resolution',
    'Y-axis travel resolution',
    'Z-axis travel resolution',
    'C-axis travel resolution',
    'X-axis maximum rate',
    'Y-axis maximum rate',
    'Z-axis maximum rate',
    'C-axis maximum rate',
    'X-axis acceleration',
    'Y-axis acceleration',
    'Z-axis acceleration',
    'C-axis acceleration',
    'X-axis maximum travel',
    'Y-axis maximum travel',
    'Z-axis maximum travel',
    'C-axis maximum travel',
    '(none)',
    '(none)'
    );

implementation

uses import_files, Clipper, About, bsearchtree, cam_view, gerber_import;

{$R *.dfm}

// #############################################################################
// #############################################################################

{$I joypad.inc}

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

function isSimActive: Boolean;
begin
  result:= (not grbl_is_connected) or Form1.CheckBoxSim.checked;
end;

function isGrblActive: Boolean;
begin
  result:= (not Form1.CheckBoxSim.checked) and grbl_is_connected;
end;

procedure TLed.SetLED(led_on: boolean);
// liefert vorherigen Zustand zurück
begin
  if led_on and (not IsOn) then begin
    Form1.PanelBusy.Color:= clred;
    Form1.PanelBusy.Font.Color:= clWhite;
    Screen.Cursor:= crHourGlass;
  end;
  if (not led_on) and IsOn then begin
    Form1.PanelBusy.Color:= $00000040;
    Form1.PanelBusy.Font.Color:= clgray;
    Screen.Cursor:= crDefault;
  end;
  IsOn:= led_on;
end;

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
    BtnMovePark.Enabled:= my_state;
    BtnMoveFix1.Enabled:= my_state;
    BtnMoveFix2.Enabled:= my_state;
    BtnMoveToolChange.Enabled:= my_state;
    BtnZeroX.Enabled:= my_state;
    BtnZeroY.Enabled:= my_state;
    BtnZeroZ.Enabled:= my_state;
    BtnZeroAll.Enabled:= my_state;
//    Form1.BtnProbeTLC.Enabled:= my_state and Form1.CheckFixedProbeZ.checked;
    BtnZcontact.Enabled:= my_state and CheckPartProbeZ.Checked;
    BtnEmergStop.Enabled:= isGrblActive;

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

    if WorkZeroZdone then
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
    BtnRunTool.Enabled:= my_state and (length(final_array) > 0);
    Form3.BtnMoveToolZero.Enabled:= my_state;
    Form3.BtnMoveCamZero.Enabled:= my_state;
  end;
end;

procedure SetToolChangeChecks(pause_is_enabled: Boolean);
begin
  with Form1 do begin
    CheckToolChange.Checked:= pause_is_enabled;
    if pause_is_enabled then begin
      CheckPartProbeZ.Enabled:= true;
      CheckTLCprobe.Enabled:= true;
      CheckTLCprobe.Checked:= job.use_fixed_probe;
      CheckUseATC2.Checked:= job.atc_enabled;
      CheckPartProbeZ.Checked:= job.use_part_probe;
    end else begin
      CheckUseATC2.Checked:= false;
      CheckPartProbeZ.Checked:= false;
      CheckPartProbeZ.Enabled:= false;
      CheckTLCprobe.Enabled:= false;
      CheckTLCprobe.Checked:= false;
    end;
  end;
end;

// #############################################################################

procedure uncheck_ms;
var i: Integer;
begin
  for i:= 0 to Form1.PopupMenuShape.Items.Count - 1 do
    Form1.PopupMenuShape.Items[i].Checked:= false;
end;

procedure uncheck_mbs;
var i: Integer;
begin
  for i:= 0 to Form1.PopupMenuBlockShape.Items.Count - 1 do
    Form1.PopupMenuBlockShape.Items[i].Checked:= false;
end;

procedure uncheck_mtt;
var i: Integer;
begin
  for i:= 0 to Form1.PopupMenuTooltip.Items.Count - 1 do
    Form1.PopupMenuTooltip.Items[i].Checked:= false;
end;


procedure SetAllbuttons;
var is_idle, is_running: boolean;
begin
  WorkZeroAllDone:= WorkZeroXdone and WorkZeroYdone and WorkZeroZdone;
  is_running:= isJobRunning;
  if grbl_is_connected then begin
    Form1.CheckBoxSim.Enabled:= not is_running;
  end else begin
    Form1.CheckBoxSim.Checked:= true;
    Form1.CheckBoxSim.Enabled:= false;
  end;
  is_idle:= MachineState = idle;
  Form1.BtnCancel.Enabled:= is_running;
  Form1.BtnMoveMillCenter.Enabled:= WorkZeroXdone and WorkZeroYdone;
  Form1.BtnMoveXYZero.Enabled:= WorkZeroXdone and WorkZeroYdone;
  Form1.BtnMoveZzero.Enabled:= WorkZeroAllDone;

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
    with Form1 do begin
      BtnCancel.Font.Color:= clred;
      if isSimActive then begin
        button_run_enable((not is_running) and WorkZeroAllDone);
      end else begin
        button_run_enable(is_idle and HomingPerformed and WorkZeroAllDone);
      end;
    end;
  end;
  with Form1 do begin
    if (not HomingPerformed) and TimerBlinkToggle then
      BtnHomeCycle.Font.Color:= cllime
    else
      BtnHomeCycle.Font.Color:= clgreen;
    if grbl_is_connected then begin
      BtnSendGrblSettings.Enabled:= true;
      BtnRefreshGrblSettings.Enabled:= true;
    end else begin
      BtnSendGrblSettings.Enabled:= false;
      BtnRefreshGrblSettings.Enabled:= false;
    end;
  end;
end;


procedure ResetToolflags;
// Nach Homing, Connect etc: Unkalibrierter Zustand
begin
  SpindleRunning:= false;
  drawing_tool_down:= false;
  Form1.ProgressBar1.position:= 0;
  if isSimActive then begin
    WorkZeroXdone:= true;
    WorkZeroYdone:= true;
    WorkZeroZdone:= false;
    WorkZeroAllDone:= true;
  end else begin
    WorkZeroXdone:= false;
    WorkZeroYdone:= false;
    WorkZeroZdone:= false;
    WorkZeroAllDone:= false;
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
  InvalidateTLCs;
  UpdateATC;
end;

procedure ForceToolPositions(x, y, z: Double);
begin
  if Form1.ShowDrawing1.Checked then
    SetDrawingToolPosMM(x, y, z);
  if Form1.Show3DPreview1.Checked and isSimActive then begin
    GLSsetToolPosMM(x, y, z)
  end;
end;


procedure ResetSimulation;
// willkürliche Ausgangswerte, auch für Simulation
begin
  Form1.Memo1.lines.add('Reset Simulation');
  ResetCoordinates;
  gcsim_x_old:= grbl_wpos.x;
  gcsim_y_old:= grbl_wpos.y;
  gcsim_z_old:= grbl_wpos.z;
  WorkZeroX:= grbl_mpos.x - grbl_wpos.x;
  WorkZeroY:= grbl_mpos.y - grbl_wpos.y;
  WorkZeroZ:= grbl_mpos.z - grbl_wpos.z;
  JogX:= grbl_wpos.x;
  JogY:= grbl_wpos.y;
  JogZ:= grbl_wpos.z;
  ForceToolPositions(grbl_wpos.X, grbl_wpos.Y, grbl_wpos.Z);
  GLSspindle_on_off(false);
  GLSneedsRedrawTimeout:= 0;
  GLSneedsATCupdateTimeout:= 0;
  HomingPerformed:= true;
  MachineState:= idle;
end;

// #############################################################################
// ############################# I N C L U D E S ###############################
// #############################################################################

{$I page_blocks.inc}
{$I page_job.inc}
{$I page_pens.inc}
{$I page_grblsetup.inc}
{$I page_run.inc}
{$I page_atc.inc}
{$I gcode_interpreter.inc}


// #############################################################################
// ###################### M A I N  F O R M  O P E N ############################
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
  StartupDone:= false;
  Show;
  Memo1.lines.Clear;
{$IFDEF GRBL_11}
  Memo1.lines.add('GRBLize for GRBL 1.1');
  Memo1.lines.add('with joystick/gamepad support');
{$ELSE}
  Memo1.lines.add('GRBLize for GRBL 0.9');
{$ENDIF}
  StopWatch:= TStopWatch.Create() ;
  Width:= Constraints.MaxWidth;
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
  JoyPad := TGamepad.Create;
  try
    grbl_ini.RootKey := HKEY_CURRENT_USER;
    grbl_ini.OpenKey('SOFTWARE\Make\GRBlize\'+c_VerStr,true);
    if grbl_ini.ValueExists('MainFormTop') then
      Top:= grbl_ini.ReadInteger('MainFormTop');
    if grbl_ini.ValueExists('MainFormLeft') then
      Left:= grbl_ini.ReadInteger('MainFormLeft');
    if grbl_ini.ValueExists('MainFormPage') then
      PageControl1.ActivePageIndex:= grbl_ini.ReadInteger('MainFormPage');


    if ParamStr(1) <> '' then begin
      JobSettingsPath:= ParamStr(1);
    end else begin
      if grbl_ini.ValueExists('SettingsPath') then
        JobSettingsPath:= grbl_ini.ReadString('SettingsPath')
      else
        JobSettingsPath:= ExtractFilePath(Application.ExeName)+'default.job';
    end;
    if grbl_ini.ValueExists('FTDIdeviceSerial') then
      ftdi_serial:= grbl_ini.ReadString('FTDIdeviceSerial')
    else
      ftdi_serial:= 'NONE';
    if grbl_ini.ValueExists('FTDIdeviceOpen') then
      ftdi_was_open:= grbl_ini.ReadBool('FTDIdeviceOpen')
    else
      ftdi_was_open:= false;
    if grbl_ini.ValueExists('DrawingFormVisible') then
      ShowDrawing1.Checked:= grbl_ini.ReadBool('DrawingFormVisible');
    if grbl_ini.ValueExists('CamFormVisible') then
      ShowSpindleCam1.Checked:= grbl_ini.ReadBool('CamFormVisible');

    if grbl_ini.ValueExists('SceneFormVisible') then
      Show3DPreview1.Checked:= grbl_ini.ReadBool('SceneFormVisible');
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
  if Show3DPreview1.Checked then
    Form4.show
  else
    Form4.hide;

  if not IsFormOpen('Form3') then
    Form3 := TForm3.Create(Self);
  if ShowSpindleCam1.Checked then
    Form3.show
  else
    Form3.hide;

  if not IsFormOpen('Form2') then
    Form2 := TForm2.Create(Self);
  if Showdrawing1.Checked then
    Form2.show
  else
    Form2.hide;

  Combobox1.Parent := SgFiles;
  ComboBox1.Visible := False;
  SgFiles.Row:=1;
  SgFiles.Col:=4;

  LoadIniFile;
//  BtnProbeTLC.Enabled:= CheckFixedProbeZ.Checked;
  BtnZcontact.Enabled:= CheckPartProbeZ.Checked;
  CheckUseATC2.Enabled:= CheckTLCprobe.Checked;
  if not CheckTLCprobe.Checked then begin
    CheckUseATC2.Checked:= false;
  end;

  SgGrblSettings.FixedCols:= 1;
  SgAppdefaults.FixedCols:= 1;

  BringToFront;
  Memo1.lines.add(''+ SetUpFTDI);

  if ftdi_was_open or com_was_open then begin
    BtnConnect.Enabled:= true;
    BtnConnect.SetFocus;
  end else
    BtnRescan.SetFocus;
  UpdateATC;
  if FileExists(JobSettingsPath) then
    OpenJobFile
  else
    Form1.FileNew1Execute(sender);
  SetToolChangeChecks(job.toolchange_pause);
  ResetCoordinates;
  ResetToolflags;
  Form1.Memo1.lines.add('');
  ResetSimulation;
  if ftdi_was_open then
    OpenFTDIport
  else if com_was_open then
    OpenCOMport;
  SavedPortnameForSim:= DeviceView.Text;
  PortOpenedCheck;
  EnableStatus;
  StartupDone:= true;
  if Show3DPreview1.Checked then
    Form4.FormReset;
  BtnUtilsResetClick(Sender);
  grbl_sendStr(#$85, false);  // Jog Cancel
  grbl_sendStr(#$90, false);  // Feed Reset
end;

// #############################################################################
// ###################### M A I N  F O R M  C L O S E ##########################
// #############################################################################

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
    grbl_ini.WriteBool('DrawingFormVisible',Form1.ShowDrawing1.Checked);
    grbl_ini.WriteBool('CamFormVisible',Form1.ShowSpindleCam1.Checked);
    grbl_ini.WriteBool('CamOn', CamIsOn);
    grbl_ini.WriteBool('SceneFormVisible',Form1.Show3DPreview1.Checked);
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

// #############################################################################


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


procedure TForm1.PageControl1Change(Sender: TObject);
begin
  SgPens.Col:= 3;
  SgPens.Row:= 1;
  Repaint;
end;


procedure TForm1.PageControl1DrawTab(Control: TCustomTabControl;
  TabIndex: Integer; const Rect: TRect; Active: Boolean);
// PageControl1.OwnerDraw := True !
var
  CaptionX: Integer;
  CaptionY: Integer;
  TabCaption: string;
begin
  with Control.Canvas do begin
    if TabIndex = 4 then
      Font.Color:= clteal;
    if TabIndex = 3 then
      Font.Color:= clgreen;
    if Active then
//      Brush.Color:= clwindow;
      Brush.Color:= cl3Dlight;
    FillRect(Rect);

    TabCaption := PageControl1.Pages[TabIndex].Caption;
    CaptionX := Rect.Left + ((Rect.Right - Rect.Left - TextWidth(TabCaption)) div 2);
    CaptionY := Rect.Top + ((Rect.Bottom - Rect.Top - TextHeight('Gg')) div 2);

    TextOut(CaptionX, CaptionY, TabCaption);
//    TextRect(Rect, Rect.Left + 2, Rect.Top + 2, TabCaption);
  end;
end;



procedure TForm1.PageControl1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Repaint;
end;

// #############################################################################

procedure TForm1.ComboBoxGdiaChange(Sender: TObject);
begin
  GLSsetToolDia(ComboBoxGdia.ItemIndex +1, gcsim_tooltip);
end;

procedure TForm1.ComboBoxGtipChange(Sender: TObject);
begin
  GLSsetToolDia(gcsim_dia, ComboBoxGTip.ItemIndex);
end;

procedure TForm1.BtnCancelMouseEnter(Sender: TObject);
begin
  Screen.Cursor:= crDefault;
end;

procedure TForm1.BtnCancelMouseLeave(Sender: TObject);
begin
  if isJobRunning then
    Screen.Cursor:= crHourGlass;
end;

//##############################################################################
//##############################################################################

procedure TForm1.CheckBoxSimClick(Sender: TObject);
begin
  ResetToolflags;
  if isSimActive then begin
    SavedPortnameForSim:= DeviceView.Text;
    ResetSimulation;
    ResetCoordinates;
    Form4.FormReset;
    GLSsetATCandProbe;
    ForceToolPositions(grbl_wpos.X, grbl_wpos.Y, grbl_wpos.Z);
    HomingPerformed:= true;
    DeviceView.Text:= 'SIMULATION';
    DeviceView.Font.Color:= clred;
    DeviceView.Font.Style:= [fsbold];
  end else begin
    EnableStatus;
    DeviceView.Font.Color:= clWindowText;
    DeviceView.Font.Style:= [];
    DeviceView.Text:= SavedPortnameForSim;
  end;
end;

// #############################################################################
// ############################## UTILS PAGE ###################################
// #############################################################################

//  UtilsLLpt, SquareCorner: TpointFloat;
//  UtilsFeed: Integer;
//  InstantZ_start, InstantZ_end, InstantZ_inc: Double;

// ######################### UTILS SQUARE ######################################

procedure TForm1.BtnSetCornerClick(Sender: TObject);
begin
  SquareCorner_mpos:= grbl_mpos;
  EditCornerX.Text:= 'MPOS';
  EditCornerY.Text:= 'MPOS';
  Memo1.Lines.Add('');
  Memo1.Lines.Add('Upper right corner');
  Memo1.Lines.Add('set to machine position');
  Memo1.Lines.Add('X: ' + FormatFloat('000.00', SquareCorner_mpos.x)
    + '   Y: ' + FormatFloat('000.00', SquareCorner_mpos.y));
  SquareCornerManualEnter:= false;
  SquareCornerSetToMpos:= true;
end;


procedure TForm1.BtnUtilsSquareClick(Sender: TObject);
var
  x1, x2, y1, y2, z, pocket_step: Double;
  outline_only: Boolean;
begin
  Memo1.Lines.Add('');
  if SquareCornerManualEnter then begin
    if (not WorkZeroXdone) or (not WorkZeroYdone) then begin
      Memo1.Lines.Add('##### Error: Machine XY not zeroed on part!');
      exit;
    end;
    if (abs(grbl_wpos.x) > 2) or (abs(grbl_wpos.y) > 2) then begin
      Memo1.Lines.Add('##### Error: Tool not near zero position!');
      exit;
    end;
    SquareCorner_wpos.X:=StrToFloatDef(EditCornerX.Text,0);
    SquareCorner_wpos.Y:=StrToFloatDef(EditCornerY.Text,0);
    Memo1.Lines.Add('Square corner set manually');
  end else begin
    if not SquareCornerSetToMpos then begin
      Memo1.Lines.Add('##### Error: Upper right corner not set!');
      exit;
    end;
    // Maschinenkoordinaten gesetzt, ändern auf Werkstück
    SquareCorner_wpos.X:= SquareCorner_mpos.X - grbl_mpos.x;
    SquareCorner_wpos.Y:= SquareCorner_mpos.Y - grbl_mpos.y;
    SquareCorner_wpos.Z:= SquareCorner_mpos.Z - grbl_mpos.z;
    EditCornerX.Text:= FormatFloat('0.00', SquareCorner_wpos.X);
    EditCornerY.Text:= FormatFloat('0.00', SquareCorner_wpos.Y);
    WorkZeroXdone:= false;    // wurde überschrieben
    WorkZeroYdone:= false;
    Memo1.Lines.Add('Lower left square corner set to zero');
  end;

  if (SquareCorner_wpos.X >= 0) and  (SquareCorner_wpos.Y >= 0) then begin
    Memo1.Lines.Add('');
    Memo1.Lines.Add('Upper right corner set to');
    Memo1.Lines.Add('X:' + FormatFloat('000.00', SquareCorner_wpos.x)
      + '  Y:' + FormatFloat('000.00', SquareCorner_wpos.y));
  end else begin
    Memo1.Lines.Add('');
    Memo1.Lines.Add('##### Error: Corner positions invalid!');
    exit;
  end;
  WorkZeroZdone:= false;  // hat sich geändert!
  BtnRunJob.Tag:= 1; // Run-Status, ForceToolPos verhindern
  if not SquareCornerManualEnter then
    grbl_offsXY(0,0);
  grbl_offsZ(0);          // User hatte Werkstück-Oberfläche angefahren
  grbl_moveZ(2, false);   // leicht anheben
  SendListToGrbl;
  spindle_on_off(true);

  InstantZ_end:= -abs(StrToFloatDef(EditUtilsZend.Text,0));
  InstantZ_inc:= abs(StrToFloatDef(EditUtilsZinc.Text,0));
  pocket_step:= StrToFloatDef(EditToolDia.Text,2) * 0.75;
  outline_only:= not SquarePocket;

  z:= 0;
  grbl_moveZ(2, false);
  grbl_moveXY(0, 0, false);
  grbl_moveSlowZ(0, false);
  try
    repeat
      z:= z - InstantZ_inc;
      if z < InstantZ_end then begin
        z:= InstantZ_end;
        InstantZ_inc:= 0;
      end;
      x1:= 0;
      x2:= SquareCorner_wpos.X;
      y1:= 0;
      y2:= SquareCorner_wpos.Y;
      grbl_moveXY(x1, y1, false);
      SendListToGrbl;
      repeat
        grbl_millZF(z, 50);
        grbl_millXYF(x1, y1, ScrollUtilsFeed.Position);
        grbl_millXY(x2, y1);
        grbl_millXY(x2, y2);
        grbl_millXY(x1, y2);
        grbl_millXY(x1, y1);
        if isCancelled then
          exit;  // "finally" wird trotzdem ausgeführt!
        SendListToGrbl;

        x2:= x2 - pocket_step;
        y2:= y2 - pocket_step;
        x1:= x1 + pocket_step;
        y1:= y1 + pocket_step;
      until (x1 > x2) or (y1 > y2) or outline_only;
    until (z <= InstantZ_end);
//    grbl_moveZ(InstantZ_start + job.z_penlift, false);
    grbl_moveZ(2, false);
    grbl_moveXY(0, 0, false);
    grbl_moveSlowZ(0, false);
    SendListToGrbl;
  finally
    WaitForIdle;
    ExitJobMsg(false);
    WorkZeroZdone:= false;  // hat sich geändert!
    if not SquareCornerManualEnter then begin
      WorkZeroXdone:= false;  // hat sich geändert!
      WorkZeroYdone:= false;
    end;
  end;
end;

procedure TForm1.ScrollUtilsFeedChange(Sender: TObject);
begin
  LabelUtilsFeed.Caption:= 'Feed: ' + IntToStr(ScrollUtilsFeed.Position);
end;

procedure TForm1.EditCornerKeyPress(Sender: TObject; var Key: Char);
begin
  // Werte von Hand eingetragen
  SquareCornerManualEnter:= true;
  SquareCornerSetToMpos:= false;
  if EditCornerX.Text = 'MPOS' then
    EditCornerX.Text:= '';
  if EditCornerY.Text = 'MPOS' then
    EditCornerY.Text:= '';

end;


procedure TForm1.BtnSquareOutlineClick(Sender: TObject);
begin
  BtnSquareOutline.Visible:= false;
  BtnSquarePocket.Visible:= true;
  SquarePocket:= true;
end;

procedure TForm1.BtnSquarePocketClick(Sender: TObject);
begin
  BtnSquareOutline.Visible:= true;
  BtnSquarePocket.Visible:= false;
  SquarePocket:= false;
end;

// ######################### UTILS CIRCLE ######################################

procedure TForm1.BtnSetRadiusClick(Sender: TObject);
begin
  CircleRadius_mpos:= grbl_mpos;
  EditRadius.Text:= 'MPOS';
  Memo1.Lines.Add('');
  Memo1.Lines.Add('Circle radius (outer edge)');
  Memo1.Lines.Add('set to machine position');
  Memo1.Lines.Add('X: ' + FormatFloat('000.00', CircleRadius_mpos.x)
    + '   Y: ' + FormatFloat('000.00', CircleRadius_mpos.y));
  CircleRadiusManualEnter:= false;
  CircleRadiusSetToMpos:= true;
end;

procedure TForm1.BtnUtilsCircleClick(Sender: TObject);
var my_radius, z, pocket_step: Double;
  outline_only: Boolean;
  my_str: String;

begin
  Memo1.Lines.Add('');
  if CircleRadiusManualEnter then begin
    if (not WorkZeroXdone) or (not WorkZeroYdone) then begin
      Memo1.Lines.Add('##### Error: Machine XY not zeroed on part!');
      exit;
    end;
    if (abs(grbl_wpos.x) > 2) or (abs(grbl_wpos.y) > 2) then begin
      Memo1.Lines.Add('##### Error: Tool not near zero position!');
      exit;
    end;
    CircleRadius:=StrToFloatDef(EditRadius.Text,0);
    Memo1.Lines.Add('Circle radius set manually');
  end else begin
    if not CircleRadiusSetToMpos then begin
      Memo1.Lines.Add('##### Error: Circle radius (outer edge) not set!');
      exit;
    end;
    // Maschinenkoordinaten gesetzt, ändern auf Werkstück
    CircleRadius_wpos.X:= CircleRadius_mpos.X - grbl_mpos.x;
    CircleRadius_wpos.Y:= CircleRadius_mpos.Y - grbl_mpos.y;
    CircleRadius:= sqrt(sqr(CircleRadius_wpos.X) + sqr(CircleRadius_wpos.Y));
    EditRadius.Text:= FormatFloat('0.00', CircleRadius);
    WorkZeroXdone:= false;    // wurde überschrieben
    WorkZeroYdone:= false;
    Memo1.Lines.Add('Circle center set to zero');
  end;

  if (CircleRadius > 0) then begin
    Memo1.Lines.Add('');
    Memo1.Lines.Add('Circle radius set to: ' + FormatFloat('000.00', CircleRadius));
  end else begin
    Memo1.Lines.Add('');
    Memo1.Lines.Add('##### Error: Radius invalid!');
    exit;
  end;

  WorkZeroZdone:= true;  // hat sich geändert!
  BtnRunJob.Tag:= 1;      // Run-Status, ForceToolPos verhindern

  if not CircleRadiusManualEnter then
    grbl_offsXY(0,0);     // User hatte Nullpunkt angefahren
  grbl_offsZ(0);          // User hatte Werkstück-Oberfläche angefahren
  grbl_moveZ(2, false);   // leicht anheben
  SendListToGrbl;
  spindle_on_off(true);

  InstantZ_end:= -abs(StrToFloatDef(EditUtilsZend.Text,0));
  InstantZ_inc:= abs(StrToFloatDef(EditUtilsZinc.Text,0));
  pocket_step:= StrToFloatDef(EditToolDia.Text,2) * 0.75;
  outline_only:= not CirclePocket;

  z:= 0;
  grbl_moveXY(CircleRadius, 0, false);
  grbl_moveSlowZ(0, false);
  try
    repeat
      z:= z - InstantZ_inc;
      if z < InstantZ_end then begin
        z:= InstantZ_end;
        InstantZ_inc:= 0;
      end;
      my_radius:= CircleRadius;
      grbl_moveXY(my_radius, 0, false);
      SendListToGrbl;
      repeat
        grbl_millZF(z, 50);
        grbl_millXYF(my_radius, 0, ScrollUtilsFeed.Position);
        // ganzer Kreis
        my_str:= 'G2 X' + FloatToSTrDot(my_radius) + 'Y0' + 'I'
          + FloatToSTrDot(-my_radius) + 'J0';
        grbl_addStr(my_str);
        if isCancelled then
          exit;  // "finally" wird trotzdem ausgeführt!
        SendListToGrbl;
        my_radius:= my_radius - pocket_step;
      until (my_radius < 1.5) or outline_only;
    until (z <= InstantZ_end);
  //    grbl_moveZ(InstantZ_start + job.z_penlift, false);
    grbl_moveZ(2, false);
    grbl_moveXY(0, 0, false);
    grbl_moveSlowZ(0, false);
    SendListToGrbl;
  finally
    WaitForIdle;
    ExitJobMsg(false);
    WorkZeroZdone:= false;  // hat sich geändert!
    if not CircleRadiusManualEnter then begin
      WorkZeroXdone:= false;  // hat sich geändert!
      WorkZeroYdone:= false;
    end;
  end;
end;

procedure TForm1.BtnCircleOutlineClick(Sender: TObject);
begin
  BtnCircleOutline.Visible:= false;
  BtnCirclePocket.Visible:= true;
  CirclePocket:= true;
end;

procedure TForm1.BtnCirclePocketClick(Sender: TObject);
begin
  BtnCircleOutline.Visible:= true;
  BtnCirclePocket.Visible:= false;
  CirclePocket:= false;
end;

procedure TForm1.EditRadiusKeyPress(Sender: TObject; var Key: Char);
begin
  CircleRadiusManualEnter:= true;
  CircleRadiusSetToMpos:= false;
end;

procedure TForm1.BtnUtilsResetClick(Sender: TObject);
begin
  BtnCircleOutline.Visible:= true;
  BtnCirclePocket.Visible:= false;
  BtnSquareOutline.Visible:= true;
  BtnSquarePocket.Visible:= false;
  CirclePocket:= false;
  SquarePocket:= false;
  SquareCornerManualEnter:= false;
  SquareCornerSetToMpos:= false;
  CircleRadiusManualEnter:= false;
  CircleRadiusSetToMpos:= false;
  EditCornerX.Text:= '0,00';
  EditCornerY.Text:= '0,00';
  EditRadius.Text:= '0,00';
  EditToolDia.Text:= '2,00';
  UpDown1.Position:= 0;
  UpDown2.Position:= 0;
  UpDown3.Position:= 0;
  if PageControl1.TabIndex = 4 then begin
    Memo1.Lines.clear;
    Memo1.Lines.Add('Corner/center reset');
  end;
end;


procedure TForm1.UpDown1ChangingEx(Sender: TObject; var AllowChange: Boolean;
  NewValue: Integer; Direction: TUpDownDirection);
var new_val: Double;
begin
  new_val:= StrToFloatDef(EditToolDia.Text,2);
  new_val:= RoundToDigits(new_val, 1);
  if Direction = updUp then
    new_val:= new_val + 0.5;
  if Direction = updDown then
    new_val:= new_val - 0.5;
  if new_val < 0.5 then
    new_val:= 0.5;
  EditToolDia.Text:= FormatFloat('0.00',new_val);
end;

procedure TForm1.UpDown2ChangingEx(Sender: TObject; var AllowChange: Boolean;
  NewValue: Integer; Direction: TUpDownDirection);
var new_val: Double;
begin
  new_val:= StrToFloatDef(EditUtilsZend.Text,0);
  new_val:= RoundToDigits(new_val, 1);
  if Direction = updUp then
    new_val:= new_val + 0.1;
  if Direction = updDown then
    new_val:= new_val - 0.1;
  if new_val < 0 then
    new_val:= 0;
  EditUtilsZend.Text:= FormatFloat('0.00',new_val);
end;

procedure TForm1.UpDown3ChangingEx(Sender: TObject; var AllowChange: Boolean;
  NewValue: Integer; Direction: TUpDownDirection);
var new_val: Double;
begin
  new_val:= StrToFloatDef(EditUtilsZinc.Text,0.5);
  new_val:= RoundToDigits(new_val, 1);
  if Direction = updUp then
    new_val:= new_val + 0.1;
  if Direction = updDown then
    new_val:= new_val - 0.1;
  if new_val < 0.1 then
    new_val:= 0.1;
  EditUtilsZinc.Text:= FormatFloat('0.00',new_val);
end;

// #############################################################################
// #############################################################################

procedure TForm1.CheckTLCprobeClick(Sender: TObject);
begin
//  BtnProbeTLC.Enabled:= CheckFixedProbeZ.Checked;
  CheckUseATC2.Enabled:= CheckTLCprobe.Checked;
  if not CheckTLCprobe.Checked then begin
    CheckUseATC2.Checked:= false;
  end;
  if Form1.CheckBoxSim.Checked then
    ResetCoordinates;
  if Form1.Show3DPreview1.Checked then
    GLSsetATCandProbe;
end;

procedure TForm1.CheckToolChangeClick(Sender: TObject);
begin
  job.toolchange_pause:= CheckToolChange.Checked;
  SetToolChangeChecks(job.toolchange_pause);
end;


// #############################################################################
// ############################## T I M E R ####################################
// #############################################################################

// Drei Timer verwendet:
// TimerBlinkTimer lässt die Buttons und Panels blinken und aktualisiert "langsame" Datenanzeigen
// TimerDrawElapsed aktualisiert alle -zig ms die Zeichnung
// TimerStatusElapsed holt alle 25 ms aktuelle Positionsdaten wenn "idle"

procedure TForm1.TimerBlinkTimer(Sender: TObject);
begin

  TimerBlinkToggle:= not TimerBlinkToggle;

  // weniger aktuelle Sachen updaten
  if TimerBlinkToggle then begin
    LabelWorkX.Caption:= FormatFloat('000.00', WorkZeroX);
    LabelWorkY.Caption:= FormatFloat('000.00', WorkZeroY);
    LabelWorkZ.Caption:= FormatFloat('000.00', WorkZeroZ);
  end else begin
    LabelTableX.Caption:= FormatFloat('000.00', job.table_x);
    LabelTableY.Caption:= FormatFloat('000.00', job.table_y);
    LabelTableZ.Caption:= FormatFloat('000.00', job.table_z);
    LabelHintZ.Caption:=  FormatFloat('00.00', job.z_gauge)+' mm';
    LabelHintZ2.Caption:= FormatFloat('00.00', job.z_penlift)+' mm';
  end;

  SetAllButtons;
  if (MachineState = idle) and (not isJobRunning) then begin
    LEDbusy.Checked:= false;
    ForceToolPositions(grbl_wpos.X, grbl_wpos.Y, grbl_wpos.Z);
  end;
end;

// #############################################################################

procedure TForm1.TimerDrawElapsed(Sender: TObject);
begin
  if NeedsRedraw and Form1.WindowMenu1.Items[0].Checked then begin
    draw_cnc_all;
  end;
  NeedsRedraw:= false;
end;

// #############################################################################

{$IFDEF GRBL_11}
{$I decodestatus_11.inc}
{$ELSE}
{$I decodestatus_09.inc}
{$ENDIF}


procedure HandleZeroRequest;
// wenn Zero-Button auf Maschinen-Panel gedrückt
var my_str, my_response: String;

begin
  Form1.Memo1.lines.add('');
  if HomingPerformed then with Form1 do begin
    TimerStatus.Enabled:= false;
    grbl_wait_for_timeout(50);
    grbl_rx_clear;
    WorkZeroX:= grbl_mpos.x;
    WorkZeroY:= grbl_mpos.y;
    WorkZeroZ:= grbl_mpos.Z - job.z_gauge;

    JogX:= WorkZeroX;
    JogY:= WorkZeroY;
    JogZ:= WorkZeroZ;

    MposOnPartGauge:= grbl_mpos.Z;
    WorkZeroZ:= MposOnPartGauge - job.z_gauge;

    Memo1.lines.add('Zero request from machine panel, will set X, Y to zero');
    Memo1.lines.add('and Z to Z gauge height from Job Defaults');
    PlaySound('SYSTEMEXCLAMATION', 0, SND_ASYNC);

    my_str:= 'G94';
    my_response:= uppercase(grbl_SendWithShortTimeout(my_str));
    Form1.Memo1.lines.add(my_str);
    my_str:= 'G92 X0 Y0 Z'+FloatToStrDot(job.z_gauge);
    my_response:= uppercase(grbl_SendWithShortTimeout(my_str));
    Form1.Memo1.lines.add(my_str);
    WorkZeroXdone:= true;
    WorkZeroYdone:= true;
    WorkZeroZdone:= true;

    InvalidateTLCs;
    repeat
      DecodeStatus(grbl_statusStr); // muss eingetroffen sein
    until MachineState <> zero;
    TimerStatus.Enabled:= true;
  end else
    Form1.Memo1.lines.add('WARNING: Zero request ignored - no Home Cycle performed');
end;

// #############################################################################
function joy_get_swapped_z: Integer;
begin
  result:= 0;
  with Form1.SgAppDefaults do begin
  if RowCount < 44 then
    exit;
  if Cells[1,39] = 'R' then
    result := JoyPad.R
  else if Cells[1,39] = 'U' then
    result := JoyPad.U
  else if Cells[1,39] = 'V' then
    result := JoyPad.V
  else
    result := JoyPad.Z;
  end;
end;

procedure joy_wait_btn_release(btn_idx: Integer);
begin
  DisableStatus;
  while JoyPad.Buttons[btn_idx] do
    JoyPad.update;
  EnableStatus;
end;


procedure TForm1.TimerStatusElapsed(Sender: TObject);
// alle 25 ms aufgerufen. Statemachine, über Semaphoren gesteuert.
type
  TprioDir = (dir_none, dir_x, dir_y, dir_z);
const
  c_jp_feedscale = 50;
var
  i: integer;
  old_machine_state: t_mstates;
{$IFDEF GRBL_11}
  btn_idx, feed, feed_old, z_temp: integer;
  feed_v: TIntPoint; // Feed-Vektor
  my_str, feed_str: String;
  fast_jog, jog_sent: boolean;
{$ENDIF}

begin
  try
    if isJobRunning or isEmergency then
      exit;
    if isSimActive then
      exit;
    TimerStatus.Tag:= 1;
    grbl_rx_clear; // letzte Antwort verwerfen
    grbl_sendRealTimeCmd('?');   // neuen Status anfordern
    old_machine_state:= MachineState;
    DecodeStatus(grbl_receiveStr(25)); // muss eingetroffen sein
    if (MachineState = zero) then
      HandleZeroRequest;
    if (MachineState = alarm) and (old_machine_state <> alarm) then
      Form1.Memo1.lines.add('ALARM state, reset machine and perform home cycle');
    if (MachineState = hold) and (old_machine_state <> hold) then
      Form1.Memo1.lines.add('HOLD state, press CONTINUE or click READY panel');
    ForceToolPositions(grbl_wpos.X, grbl_wpos.Y, grbl_wpos.Z);
{$I joypad_handling.inc}
  finally
    TimerStatus.Tag:= 0;
  end;
end;

// #############################################################################

procedure DisableStatus;
// Maschinenstatus-Timer sicher abschalten
begin
  if Form1.TimerStatus.Tag > 0 then
    sleep(25);
  Form1.TimerStatus.Enabled:= false;
end;

procedure EnableStatus;
// Maschinenstatus-Timer einschalten
begin
  Form1.TimerStatus.Enabled:= true;
end;

// #############################################################################
// ########################### MAIN GCODE OUTPUT ###############################
// #############################################################################


procedure WaitForIdle;
// Warte auf Idle
var pos_changed: Boolean;
begin
  if isGrblActive then
    while (MachineState = run) do begin // noch beschäftigt?
      sleep(50);
      if not Form1.TimerStatus.enabled then
        DecodeStatus(grbl_statusStr);
      Application.processmessages;
      if isCancelled or isEmergency or isWaitExit then
        break;
    end;
end;

function ResponseMsg(my_str:String): boolean;
// dekodiert Antwort von GRBL (normalerweise 'ok') und zeigt ggf. Meldungszeile
begin
  result:= AnsiUpperCase(my_str) = 'OK';
  if (not result) and (length(my_str) > 0) then begin
    if AnsiContainsStr(my_str, '>') then
      exit; // war eine im Timer angeforderte Statusmeldung
    if AnsiContainsStr(my_str, '[') then
      Form1.Memo1.lines.add('GRBL response: ' + my_str)
    else
      Form1.Memo1.lines.add('WARNING: unexpected response "' + my_str + '"');
  end;
end;


function SendReceive(my_cmd: String; my_timeout: Integer): String;
// bei abgeschaltetem Status senden und empfangen
begin
  if isGRBLactive then begin
    Form1.Memo1.lines.add(my_cmd);
    if my_timeout > 0 then begin
      grbl_SendStr(my_cmd + #13, false);
      result:= ansiuppercase(grbl_receiveStr(my_timeout));
    end else
      result:= ansiuppercase(grbl_SendStr(my_cmd + #13, true));
    ResponseMsg(result);
  end else begin
    Form1.Memo1.lines.add(my_cmd);
    InterpretGcodeLine(my_cmd);
    NeedsRedraw:= true;
  end;
end;

function SendReceiveAndDwell(my_cmd: String): String;
// bei abgeschaltetem Status senden und empfangen, warten bis Bewegung beendet
// Sende einzelnen Befehl, hierfür 100 ms Timeout
begin
  if isGRBLactive then begin
    Form1.Memo1.lines.add(my_cmd);
    grbl_SendStr(my_cmd + #13, false);
    result:= grbl_receiveStr(100);
    if ResponseMsg(result) then
      result:= grbl_SendStr('G4 P0' + #13, true);
    ResponseMsg(result);
  end else begin
    Form1.Memo1.lines.add(my_cmd);
    InterpretGcodeLine(my_cmd);
    NeedsRedraw:= true;
  end;
end;

procedure SendSingleCommandStr(my_command: String);
// Sende einzelnen Befehl, 100 ms Timeout
begin
  if isGrblActive then begin
    DisableStatus;
    SendReceive(my_command, 200);
    EnableStatus;
  end else begin
    Form1.Memo1.lines.add(my_command);
    InterpretGcodeLine(my_command);
    NeedsRedraw:= true;
  end;
end;

procedure SendSingleCommandAndDwell(my_command: String);
// Sende einzelnen Befehl, 100 ms Timeout
begin
  if isGrblActive then begin
    DisableStatus;
    SendReceiveAndDwell(my_command);
    EnableStatus;
  end else begin
    Form1.Memo1.lines.add(my_command);
    InterpretGcodeLine(my_command);
    NeedsRedraw:= true;
  end;
end;

procedure ClearAlarmLock;
begin
  Form1.Memo1.lines.add('');
  HomingPerformed:= false;
  Form1.Memo1.lines.add('Unlock ALARM state');
  if isGrblActive then begin
    ResetToolflags;
    DisableStatus;  // Koordinaten-Abfrage abschalten
    grbl_sendRealTimeCmd(#24);   // Reset
    sleep(100);
    grbl_wait_for_timeout(50);
    grbl_sendStr('$X'+#13, false);   // Clear Lock
    grbl_wait_for_timeout(100);
    EnableStatus;   // Koordinaten-Abfrage freischalten
  end else
    ResetSimulation;
  Form1.Memo1.lines.add('Proceed with care!');
end;


procedure CancelMachine;
// Abbruch eines Jobs. Maschine in sicheren Zustand bringen
var pos_changed: Boolean;
begin
  with Form1 do begin
    gcsim_active:= false;
    Memo1.lines.add('');
    Memo1.lines.add('Cancel Job');
    Memo1.lines.add('=========================================');
    Memo1.lines.add('Feed hold, wait for stop...');
    grbl_sendRealTimeCmd('!');   // Feed Hold
    mdelay(100);
    grbl_rx_clear; // letzte Antwort verwerfen
    repeat
      pos_changed:= DecodeStatus(grbl_statusStr);
    until (not pos_changed) and (MachineState = hold) or isEmergency;
    mdelay(100);
    Memo1.lines.add('Reset GRBL');
    grbl_sendRealTimeCmd(#24);   // Reset CTRL-X, Maschine steht
    sleep(200);
    Form1.Memo1.lines.add(grbl_receiveStr(20));
    Form1.Memo1.lines.add(grbl_receiveStr(20));
    // Locked/Alarm-Meldung, sonst #Timeout
    Form1.Memo1.lines.add(grbl_receiveStr(20));

    SpindleRunning:= false;
    SendActive:= false;
    Memo1.lines.add('Feed release');
    grbl_sendRealTimeCmd('~');   // Feed Hold löschen
    grbl_rx_clear; // letzte Antwort verwerfen
    Memo1.lines.add('Unlock Alarm State');
    grbl_sendStr('$X' + #13, false);   // Unlock
    grbl_wait_for_timeout(100);
    Memo1.lines.add('Move Z up, restore Offsets');
    grbl_sendStr('G0 G53 Z0' + #13, true);   // Move up
    grbl_sendStr('G4 P1' + #13, true);       // Dwell/Pause
    Memo1.lines.add('');
    grbl_sendStr('G92 Z'+FloatToStrDot(-WorkZeroZ) + #13, true); // wir sind auf 0
    grbl_sendStr('G92 X'+ FloatToSTrDot(grbl_mpos.X - WorkZeroX)
      +' Y'+ FloatToSTrDot(grbl_mpos.Y - WorkZeroY) + #13, true);
    Memo1.lines.add('Done.');
    repeat
      Application.processmessages;
    until BtnRunjob.tag = 0;  // bis Job-Schleife beendet
  end;
end;

procedure CancelSim;
// Abbruch eines simulierten Jobs
begin
  with Form1 do begin
    PanelAlive.tag:= 0;  // Receive Cancel löschen
    Memo1.lines.add('');
    Memo1.lines.add('Cancel Job Simulation');
    Memo1.lines.add('=========================================');
    spindle_on_off(false);
    SendSingleCommandAndDwell('G0 G53 Z0');
    Memo1.lines.add('Done.');
  end;
end;

procedure SendListToGrbl;
// Sende Befehlesliste und warte auf Idle
// lohnt, wenn mehrere Befehle abzuarbeiten sind
var
  my_str: String;
  i: Integer;
begin
  NeedsRedraw:= true;
  if grbl_sendlist.Count = 0 then
    exit;
  if isCancelled then
    exit;
  Form1.ProgressBar1.Max:= grbl_sendlist.Count;

  ShowAliveState(s_alive_wait_indef);
  if isGrblActive then begin
    if SendActive then begin  // nicht reentrant!
      Form1.Memo1.lines.add('WARNING: Send is active, ignored');
      PlaySound('SYSTEMHAND', 0, SND_ASYNC);
      exit;
    end;
    if MachineState = alarm then begin
      Form1.Memo1.lines.add('ALARM state, command ignored.');
      PlaySound('SYSTEMHAND', 0, SND_ASYNC);
      grbl_sendlist.Clear;
      exit;
    end;
    DisableStatus;
    SendActive:= true;
    grbl_rx_clear; // letzte Antwort verwerfen
    for i:= 0 to grbl_sendlist.Count-1 do begin
      my_str:= grbl_sendlist[i];
      Form1.ProgressBar1.position:= i;
      if length(my_str) > 1 then begin
        if (my_str[1] <> '/') and (my_str[1] <> '(') then begin
          // alles OK, neuen Befehl senden
          Form1.Memo1.lines.add(my_str);
          if isCancelled then begin
            CancelMachine;
            break;
          end;
          LastResponseStr:= ansiuppercase(grbl_sendStr(my_str + #13, true));
          // wenn nicht OK, Alarmzustand, timeout oder Fehler
          if pos('OK', LastResponseStr) = 0 then begin
            if pos('ALARM', LastResponseStr) > 0 then begin
              Form1.Memo1.lines.add(LastResponseStr);
              Form1.Memo1.lines.add('ALARM state, reset machine and perform home cycle');
              Form1.Memo1.lines.add('Processing cancelled');
              PlaySound('SYSTEMHAND', 0, SND_ASYNC);
             break;
            end else if pos('ERROR', LastResponseStr) > 0 then begin
              Form1.Memo1.lines.add(LastResponseStr);
              Form1.Memo1.lines.add('ERROR state, communication fault');
              Form1.Memo1.lines.add('Processing cancelled');
              PlaySound('SYSTEMHAND', 0, SND_ASYNC);
              break;
            end;
            MessageDlg('Error ' + LastResponseStr + ' occured. Machine stopped.',
              mtConfirmation, [mbCancel],0);
          end;
        end;
      end;
    end;
    EnableStatus;
  end else begin
    gcsim_active:= true;          // für Cadencer-Prozess
    for i:= 0 to grbl_sendlist.Count-1 do begin
      my_str:= grbl_sendlist[i];
      Form1.ProgressBar1.position:= i;
      if isCancelled then begin
        CancelSim;
        break;
      end;
      if length(my_str) > 1 then begin
        if (my_str[1] <> '/') and (my_str[1] <> '(') then begin
          // alles OK, neuen Befehl senden
          Form1.Memo1.lines.add(my_str);
          InterpretGcodeLine(my_str);
          NeedsRedraw:= true;
        end;
      end;
      DisplayWorkPosition;
      DisplayMachinePosition;
    end;
    gcsim_active:= false;
  end;
  ShowAliveState(s_alive_responded);
  grbl_sendlist.Clear;
  Form1.ProgressBar1.position:= 0;

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
  ShowSpindleCam1.Checked:= not ShowSpindleCam1.Checked;
  if ShowSpindleCam1.Checked then
    Form3.Show
  else
    Form3.Hide;
end;

procedure TForm1.CheckUseATC2Click(Sender: TObject);
begin
// Verwendete Werkzeuge in Pen/Tools-Liste (Job) eintragen
  ListBlocks;
  if isSimActive then
    ResetCoordinates;
  GLSneedsRedrawTimeout:= 0;
  GLSneedsATCupdateTimeout:= 0;
end;


procedure TForm1.Show3DPreview1Click(Sender: TObject);
begin
  if isSimActive then
    ResetCoordinates;
  Show3DPreview1.Checked:= not Show3DPreview1.Checked;
  if Show3DPreview1.Checked then begin
    GLSneedsRedrawTimeout:= 0;
    GLSneedsATCupdateTimeout:= 0;
    Form4.Show;
    GLSsetToolToATCidx(ToolInSpindle);
    GLScenterBlock(final_bounds);
    ForceToolPositions(grbl_wpos.X, grbl_wpos.Y, grbl_wpos.Z);
  end else
    Form4.Hide;
end;

procedure TForm1.HelpAbout1Execute(Sender: TObject);
begin
  AboutBox.ProgName.Caption:= c_ProgNameStr + c_VerStr;
  AboutBox.VersionInfo.Caption:= c_Grbl_VerStr;
  Aboutbox.ShowModal;
end;

procedure TForm1.mbs_click(Sender: TObject);
// Shapes im Block-Stringgrid!
var my_shape: Tshape;
begin
  with SgBlocks do begin
    my_shape:= TShape(PopupMenuBlockShape.Items.IndexOf(TMenuItem(Sender)));
    final_array[HiliteBlock].shape:= my_shape;
    Cells[4,row]:= ShapeArray[ord(my_shape)];
    item_change(HiliteBlock);
  end;
end;

procedure TForm1.ms_Click(Sender: TObject);
begin
  with SgPens do begin
    job.pens[row-1].shape:= TShape(PopupMenuShape.Items.IndexOf(TMenuItem(Sender)));
    Cells[col, row] := IntToStr(ord(job.pens[row-1].shape));
  end;
  apply_pen_change;
  NeedsRedraw:= true;
  GLSneedsRedrawTimeout:= 0;
  GLSneedsATCupdateTimeout:= 0;
end;


procedure TForm1.mt_Click(Sender: TObject);
begin
  with SgPens do begin
    job.pens[row-1].tooltip:= PopupMenuTooltip.Items.IndexOf(TMenuItem(Sender));
    Cells[col, row] := IntToStr(job.pens[row-1].tooltip);
    if job.pens[row-1].tooltip = 6 then begin
      job.pens[row-1].shape:= drillhole;
      Cells[9,row]:= IntToStr(ord(job.pens[Row-1].shape));
    end;
  end;
  CalcTipDia;
  apply_pen_change;
  NeedsRedraw:= true;
  GLSneedsRedrawTimeout:= 0;
  GLSneedsATCupdateTimeout:= 0;

end;

procedure TForm1.pu_LoadFromATCslotClick(Sender: TObject);
// Werkzeug aus Slot oder manuell aufnehmen
begin
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  if Form1.CheckUseATC2.Checked then
    LoadATCtool(sgATC.Row, false); // legt altes Tool automatisch ab
  WorkZeroZdone:= false;
end;

procedure TForm1.pu_MovetoATCslotClick(Sender: TObject);
var
  my_atc: Integer;
  my_atc_x, my_atc_y: Double;
begin
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  my_atc:= sgATC.Row-1;
  Form1.Memo1.lines.add('');
  Memo1.lines.add('Move to ATC #'+IntToStr(my_atc)+' position (Z up)');
  my_atc_x:= job.atc_zero_x + (my_atc * job.atc_delta_x);
  my_atc_y:= job.atc_zero_y + (my_atc * job.atc_delta_y);
  grbl_moveXY(my_atc_x, my_atc_y, true);
  //grbl_moveZ(job.atc_pickup_z + 10, true);  // move Z down near pickup-Höhe
  SendListToGrbl;
  NeedsRedraw:= true;
end;


procedure TForm1.BtnMoveMillCenterClick(Sender: TObject);
begin
  Memo1.lines.add('');
  Memo1.lines.add('Move to job center position (Z up)');
  grbl_moveZ(0, true);
  grbl_moveXY(final_bounds_mm.mid.x, final_bounds_mm.mid.y, false);
  SendListToGrbl;
end;

// #############################################################################

procedure TForm1.BtnEmergencyStopClick(Sender: TObject);
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
  if not isSimActive then begin
    grbl_sendRealTimeCmd(#24);   // Soft Reset CTRL-X, Stepper sofort stoppen
    sleep(200);
    Form1.Memo1.lines.add(grbl_receiveStr(20));
    Form1.Memo1.lines.add(grbl_receiveStr(20));
    // Locked/Alarm-Meldung, sonst #Timeout
    Form1.Memo1.lines.add(grbl_receiveStr(20));
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
  ClearATCarray;
  UpdateATC;
  Memo1.lines.add('Done. Please re-run Home Cycle.');
  Memo1.lines.add('');
end;

procedure TForm1.BtnCancelClick(Sender: TObject);
begin
  grbl_sendRealTimeCmd(#$85);  // Jog Cancel
  grbl_sendRealTimeCmd(#$90);  // Feed Reset
  if not isJobRunning then
    exit;
  BtnCancel.tag:= 1;
  BtnRunJob.Tag:= 0;
  Memo1.lines.add('');
  Memo1.lines.add('Processing Cancel Request...');
  // Wird von Run-Thread erledigt
end;

procedure TForm1.BtnHomeOverrideClick(Sender: TObject);
begin
  BtnEmergStop.tag:= 0;
  BtnCancel.tag:= 0;
  BtnRunjob.tag:= 0;
  Memo1.lines.add('');
  if isSimActive then
    Memo1.lines.add('Home Cycle Override always on in simulation mode.')
  else
    Memo1.lines.add('Home Cycle Override initiated');
  DefaultsGridListToJob;
  if isGrblActive then begin
    LEDbusy.Checked:= true;
    spindle_on_off(false);
    ResetToolflags;
    Memo1.lines.add('WARNING: Home Cycle override - do not rely on machine position!');
    ClearAlarmlock;
  end else
    ResetSimulation;
  Memo1.lines.add('Proceed with care!');
  HomingPerformed:= true;
  Memo1.lines.add('');
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
  InvalidateTLCs;
  CancelG43offset;
  if isGrblActive then begin
    LEDbusy.Checked:= true;
    spindle_on_off(false);
    ResetToolflags;
    DisableStatus;
    my_response:= ansiuppercase(grbl_sendStr('$h'+#13, true));
    Memo1.lines.add(my_response);
    if my_response <> 'OK' then begin
      Memo1.lines.add('WARNING: Home Cycle failed - do not rely on machine position!');
      MessageDlg('Home Cycle failed. ALARM LOCK cleared,'
        + #13 + 'but do not rely on machine position.', mtWarning, [mbOK], 0);
      ClearAlarmlock;
    end;
    EnableStatus;  // automatische Upates freischalten
  end else
    ResetSimulation;
  HomingPerformed:= true;
  Memo1.lines.add('Done.');
  Memo1.lines.add('');
  GLSclearPathNodes;
end;

procedure TForm1.PanelReadyClick(Sender: TObject);
begin
  // Clear HOLD runtime cmd
  Memo1.lines.add('Machine CONTINUE, Receive resumed');
  grbl_sendRealTimeCmd('~');
  PanelAlive.tag := 0;
  Memo1.lines.add('Clear HOLD state');
  if isGrblActive then
    EnableStatus;  // Koordinaten-Abfrage freischalten
end;

procedure TForm1.pu_ProbetoolLengthCompClick(Sender: TObject);
// Tool-Delta setzen.
begin
  if sgATC.Row > 1 then begin
    WaitForIdle;
    if ToolInSpindle = sgATC.Row then
      DoTLCandConfirm(false, sgATC.Row) // erstes Tool im Array = 1!
    else
      ChangeATCtool(ToolInSpindle, sgATC.Row, true);
  end;
  UpdateATC;
end;

procedure TForm1.pu_ProbeToolLengthRefClick(Sender: TObject);
// Reset für erstes Werkzeug. Aktuell (evt. neu eingesetztes) Werkzeug
// wird auf jeden Fall neu kalibriert.
begin
  if (abs(MposOnFixedProbe) < job.table_z) then
// letztes Werkzeug gilt als Referenzlänge wenn gültig
    MposOnFixedProbeReference:= MposOnFixedProbe
  else begin
    MposOnFixedProbeReference:= 0;
    MposOnFixedProbe:= 0;
  end;

  // geht automatisch auf Cancel Tool Delta mit G49
  WaitForIdle;
  InvalidateTLCs;
  NewG43Offset(0);
  DoTLCandConfirm(false, sgATC.Row); // erstes Tool im Array = 1!
  UpdateATC;
end;

procedure TForm1.sgATCMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
// Popup-Menu mit rechter Maustaste
var pt: TPoint;
  my_row, my_col, i, k: integer;
begin
  sgATC.MouseToCell( X,Y, my_col, my_row );
  if my_row < 1 then
    exit;
  pt.X:= X;
  pt.Y:= Y;
  pt := sgATC.ClientToScreen(pt);
  if my_row <> ToolInSpindle then // anderes Tool gewählt
    WorkZeroZDone:= false;
  sgATC.Col := 1;

  if button = mbRight then begin
    pu_ProbeToolLengthRef.Enabled:= true;
    if my_row = ToolInSpindle then begin // First Tool Used, Reference
      pu_ProbetoolLengthComp.Enabled:= false;
    end else begin
      pu_ProbetoolLengthComp.Enabled:= atcArray[my_row].TREFok;
    end;
    pu_LoadFromATCslot.Enabled:= not pu_ProbetoolLengthComp.Enabled;
    pu_LoadfromATCslot.Enabled:= CheckUseATC2.Checked;
    PopupMenuATC.Popup(pt.X, pt.Y);
  end;

  ToolInSpindle := my_row;
  k:= CountUsedATCtools;
  for i:= 1 to k do      // atcArray[0] ist unbenutzt!
    atcArray[i].isInSpindle:= false;
  atcArray[ToolInSpindle].isInSpindle:= true;
  GLSsetToolToATCidx(ToolInSpindle);
  GLSupdateATC;
  UpdateATC;
end;

procedure TForm1.PanelHoldClick(Sender: TObject);
begin
  // Set HOLD runtime cmd
  Memo1.lines.add('Machine HOLD');
  grbl_sendRealTimeCmd('!');
end;


procedure TForm1.PanelAlarmClick(Sender: TObject);
begin
  BtnEmergStop.tag:= 0;
  BtnCancel.tag:= 0;
  BtnRunjob.tag:= 0;
  ClearAlarmLock;
end;

procedure TForm1.PanelAliveClick(Sender: TObject);
begin
  PanelAlive.tag := 1;
  Memo1.lines.add('WARNING: Receive cancelled');
  Memo1.lines.add('Click READY panel to resume');
end;

procedure TForm1.BtnReloadAllClick(Sender: TObject);
begin
  OpenFilesInGrid;
end;


// #############################################################################
// #################### R E F E R E N C E  B U T T O N S #######################
// #############################################################################

procedure TForm1.BtnZeroXClick(Sender: TObject);
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Manual Work/part X zero');
  drawing_tool_down:= false;
  WorkZeroXdone:= true;
  SendSingleCommandStr('G92 X0');
  WorkZeroX:= grbl_mpos.X;
  JogX:= WorkZeroX;
  NeedsRedraw:= true;
end;

procedure TForm1.BtnZeroYClick(Sender: TObject);
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Manual Work/part Y zero');
  drawing_tool_down:= false;
  WorkZeroYdone:= true;
  SendSingleCommandStr('G92 Y0');
  WorkZeroY:= grbl_mpos.Y;
  JogY:= WorkZeroY;
  NeedsRedraw:= true;
end;

procedure TForm1.BtnZeroZClick(Sender: TObject);
// manuelle Z-Höhe mit Messklotz
begin
  WaitForIdle;
  Memo1.lines.add('');
  Memo1.lines.add('Manual Work/part Z zero, will set Z to ');
  Memo1.lines.add('Z Gauge value ' + FormatFloat('00.00', job.z_gauge) + ' mm above part');
  MposOnPartGauge:= grbl_mpos.Z;
  WorkZeroZ:= MposOnPartGauge - job.z_gauge;
  WorkZeroZdone:= true;
  JogZ:= WorkZeroZ;
  if isSimActive then
    ResetSimulation;
  InvalidateTLCs;
  CancelG43offset;
  SendSingleCommandStr('G92 Z'+FloatToStrDot(job.z_gauge));
// vorerst nicht nötig, da erstes Tool ohnehin immer TLC'd wird:
{
  if CheckPartProbeZ.Checked then
    DoTLCandConfirm(true, 1);
}
  NeedsRedraw:= true;
  UpdateATC;
end;

procedure TForm1.BtnZeroAllClick(Sender: TObject);
begin
  BtnZeroXClick(Sender);
  BtnZeroYClick(Sender);
  BtnZeroZClick(Sender);
end;

// #############################################################################

procedure TForm1.BtnZcontactClick(Sender: TObject);
// Werkstück-Probekontakt anfahren. Tool muss über Kontakt sein
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
    if isSimActive then
      ResetSimulation;
    InvalidateTLCs;
    CancelG43offset;
    MposOnPartGauge:= probe_z;
    if MposOnPartGauge = 0 then begin
      ResetToolflags;
      Memo1.lines.add('WARNING: Z height invalid.');
      PlaySound('SYSTEMHAND', 0, SND_ASYNC);
    end else begin
      WorkZeroZdone:= true;
      WorkZeroZ:= MposOnPartGauge - job.probe_z_gauge;
      JogZ:= WorkZeroZ;
      DisableStatus;
      SendReceiveAndDwell('G0 G53 Z0' + #13);  // Ganz oben
      // WorkZero ist negativ. Wird sind um -Workzero über dem Werkstück
      grbl_SendStr('G92 Z'+FloatToStrDot(-WorkZeroZ) + #13, true);
      EnableStatus;
// vorerst nicht nötig, da erstes Tool ohnehin immer TLC'd wird:
{
      if CheckPartProbeZ.Checked then
        DoTLCandConfirm(true, 1);  // ist erstes Werkzeug!
}
    end;
    NeedsRedraw:= true;
    sgATC.Row:= ToolInSpindle;
    UpdateATC;
  end;
end;


// #############################################################################
// #############################################################################

procedure TForm1.BtnMoveToolChangeClick(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  spindle_on_off(false);
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  Form1.Memo1.lines.add('Move to manual tool change position');
  grbl_moveXY(job.toolchange_x, job.toolchange_y, true);
  grbl_moveZ(job.toolchange_z, true);
// manuelle Wechselposition
  SendListToGrbl;

// vorerst nicht nötig, da erstes Tool ohnehin immer TLC'd wird:
{
  if Form1.CheckTLCprobe.checked then begin
    if MessageDlg('Manual Tool Change'
    + #13 + 'For this job, load spindle with:'
    + #13 + #13 + pen_description(atcArray[FirstToolUsed].pen)
    + #13 + #13 + 'Click OK when tool has been changed'
    + #13 + 'to proceed with TLC probing. If using ATC,'
    + #13 + 'first slot (#1) must be empty.',
    mtConfirmation, mbOKCancel, 0) = mrCancel then
      exit;
    if DoTLCandConfirm(false, 1) then
      Form1.Memo1.lines.add('Tool changed, new Tool Delta Z applied');
  end else
}
    if MessageDlg('Manual Tool Change'
    + #13 + 'For this job, load spindle with:'
    + #13 + #13 + pen_description(atcArray[ToolInSpindle].pen)
    + #13 + #13 + 'Click OK when tool has been changed.',
    mtConfirmation, mbOKCancel, 0) = mrCancel then
      exit;
  if Form1.Show3DPreview1.checked then
    GLSupdateATC;
  InvalidateTLCs;
  CancelG43offset;
  WorkZeroZdone:= false;
end;


// #############################################################################
// ################### M O V E  AND  J O G  B U T T O N S ######################
// #############################################################################


procedure TForm1.BtnMoveParkClick(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move to park position');
  spindle_on_off(false);
  drawing_tool_down:= false;
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  grbl_moveXY(job.park_x, job.park_y, true);
  grbl_moveZ(job.park_z, true);
  SendListToGrbl;
  NeedsRedraw:= true;
end;

procedure TForm1.BtnMoveFix1Click(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move to fixture 1 zero');
  spindle_on_off(false);
  drawing_tool_down:= false;
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  grbl_moveXY(job.fix1_x, job.fix1_y, true);
  grbl_moveZ(job.fix1_z, true);
  SendListToGrbl;
  mdelay(250);
  NeedsRedraw:= true;
  WaitForIdle;
  BtnZeroXClick(Sender);
  BtnZeroYClick(Sender);
//  BtnZeroZClick(Sender);
end;

procedure TForm1.BtnMoveFix2Click(Sender: TObject);
begin
  if machine_busy_msg then
    exit;
  LEDbusy.Checked:= true;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move to fixture 2 zero');
  spindle_on_off(false);
  drawing_tool_down:= false;
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  grbl_moveXY(job.fix2_x, job.fix2_y, true);
  grbl_moveZ(job.fix2_z, true);
  SendListToGrbl;
  mdelay(250);
  NeedsRedraw:= true;
  WaitForIdle;
  BtnZeroXClick(Sender);
  BtnZeroYClick(Sender);
//  BtnZeroZClick(Sender);
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
    // nur anheben, wenn X/Y nicht in Nullpunkt-Nähe
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

procedure TForm1.BitBtnJogMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var dx, dy, dz: Double;
  f: Integer;
  first_loop_done: boolean;
begin
  if isSimActive then
    exit;
  WaitForIdle;
  dx := 0;
  dy := 0;
  dz := 0;
  case (Sender as TBitBtn).tag of   // Welcher Jog-Button?
    0: dx:= 0.1;
    1: dx:= 1;
    2: dx:= 10;
    3: dx:= -0.1;
    4: dx:= -1;
    5: dx:= -10;
    10: dy:= 0.1;
    11: dy:= 1;
    12: dy:= 10;
    13: dy:= -0.1;
    14: dy:= -1;
    15: dy:= -10;
    20: dz:= 0.1;
    21: dz:= 1;
    22: dz:= 10;
    23: dz:= -0.1;
    24: dz:= -1;
    25: dz:= -10;
  end;
{$IFDEF GRBL_11}
  if (abs(dx)>5) or (abs(dy)>5) or (abs(dz)>5) then
    f:= get_AppDefaults_int(37) // JogSpeed Fast
  else
    if (abs(dx)>0.5) or (abs(dy)>0.5) or (abs(dz)>0.5) then
      f:= get_AppDefaults_int(38) // JogSpeed Slow
    else
      f:= get_AppDefaults_int(38) div 5;

  if get_AppDefaults_bool(45) then begin // Positive Machine Space
    if dx > 0 then
      SendSingleCommandStr('$J=G53 X' + FloatToStrDot(job.table_x) + 'F'+ IntToStr(f));
    if dx < 0 then
      SendSingleCommandStr('$J=G53 X1 F'+ IntToStr(f));

    if dy > 0 then
      SendSingleCommandStr('$J=G53 Y' + FloatToStrDot(job.table_y) + 'F'+ IntToStr(f));
    if dy < 0 then
      SendSingleCommandStr('$J=G53 Y1 F'+ IntToStr(f));

    if dz > 0 then
      SendSingleCommandStr('$J=G53 Z-1 F'+ IntToStr(f div 3));
    if dz < 0 then
      SendSingleCommandStr('$J=G53 Z-' + FloatToStrDot(job.table_z) + 'F'+ IntToStr(f div 3));
  end else begin
    if dx > 0 then
      SendSingleCommandStr('$J=G53 X-1 F'+ IntToStr(f));
    if dx < 0 then
      SendSingleCommandStr('$J=G53 X-' + FloatToStrDot(job.table_x) + 'F'+ IntToStr(f));

    if dy > 0 then
      SendSingleCommandStr('$J=G53 Y-' + FloatToStrDot(job.table_y) + 'F'+ IntToStr(f));
    if dy < 0 then
      SendSingleCommandStr('$J=G53 Y-1 F'+ IntToStr(f));

    if dz > 0 then
      SendSingleCommandStr('$J=G53 Z-' + FloatToStrDot(job.table_z) + 'F'+ IntToStr(f div 3));
    if dz < 0 then
      SendSingleCommandStr('$J=G53 Z-1 F'+ IntToStr(f div 3));
  end;
  while GetAsyncKeyState(VK_LBUTTON) < 0 do begin
    Application.ProcessMessages;
    sleep(25);
  end;
  grbl_sendRealTimeCmd(#$85);   // Jog Cancel

{$ELSE}
  //my_delay:= (12 - Form1.TrackBarRepeatRate.Position) * 20;
  first_loop_done:= false;
  repeat
    JogX:= grbl_mpos.X + dx;
    JogY:= grbl_mpos.Y + dy;
    JogZ:= grbl_mpos.Z + dz;
    if dx <> 0 then
      SendSingleCommandStr('G0 G53 X' + FloatToStrDot(JogX));
    if dy <> 0 then
      SendSingleCommandStr('G0 G53 Y' + FloatToStrDot(JogY));
    if dz <> 0 then
      SendSingleCommandStr('G0 G53 Z' + FloatToStrDot(JogZ));
    if not first_loop_done then
      mdelay(300)
    else
      mdelay(100);
    first_loop_done:= true;
  until GetAsyncKeyState(VK_LBUTTON) = 0; // stop when mouse released
  NeedsRedraw:= true;
{$ENDIF}

end;

end.
