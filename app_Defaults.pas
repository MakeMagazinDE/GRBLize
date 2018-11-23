// AppDefaults StringGrid Handler
unit app_defaults;

interface

uses Classes, Grids, ParamAssist, import_files;

const
    defHeadline            = 0;
    defToolchangePause     = 1;
    defToolchangeX         = 2;
    defToolchangeY         = 3;
    defToolchangeZ         = 4;
    defParkpositionOnEnd   = 5;
    defParkX               = 6;
    defParkY               = 7;
    defParkZ               = 8;
    defCamXoff             = 9;
    defCamYoff             = 10;
    defCamZabs             = 11;
    defUseFixedProbe       = 12;
    defProbeX              = 13;
    defProbeY              = 14;
    defProbeZ              = 15;
    defUsePartProbe        = 16;
    defProbeZgauge         = 17;
    defInvertZ             = 18;
    defSpindleWait         = 19;
    defMaxRotation         = 20;
    defAtcEnabled          = 21;
    defAtcZeroX            = 22;
    defAtcZeroY            = 23;
    defAtcPickupZ          = 24;
    defAtcDeltaX           = 25;
    defAtcDeltaY           = 26;
    defTableX              = 27;
    defTableY              = 28;
    defTableZ              = 29;
    defFix1X               = 30;
    defFix1Y               = 31;
    defFix1Z               = 32;
    defFix2X               = 33;
    defFix2Y               = 34;
    defFix2Z               = 35;
    defAtcToolReleaseCmd   = 36;
    defAtcToolClampCmd     = 37;
    defJoypadFeedVeryFast  = 38;
    defJoypadFeedFast      = 39;
    defJoypadFeedSlow      = 40;
    defJoypadFeedVerySlow  = 41;
    defJoypadZaxisButton   = 42;
    defJoypadFastJogButton = 43;
    defJoypadZeroAllButton = 44;
    defJoypadFloodToggle   = 45;
    defJoypadSpindleToggle = 46;
    defJoypadFeedHold      = 47;
    defPositivMachineSpace = 48;
    defTouchKeyboard       = 49;

type
  T_machine_options = record   // Ausstattungsdetails
    NewGrblVersion: boolean;
    SPI: Boolean;
    Display: Boolean;
    Panel: Boolean;
    Caxis: Boolean;
    VariableSpindle: Boolean;
    MistCoolant: Boolean;
    HomingLock: Boolean;
    DeviceAddressed: Boolean;
    DeviceAddress: Integer;
    SingleAxisHoming: Boolean;
    HomingOrigin: Boolean;  // HOMING_FORCE_SET_ORIGIN set
    PositiveSpace: Boolean; // derived from AppDefaults Table
  end;

var
  MachineOptions:  T_machine_options;    // Ausstattungsdetails

procedure InitMachineOptions;
procedure CalcTipDia;
procedure PenGridListToJob;
procedure JobToPenGridList;
procedure ClearFiles;
procedure InitJob;
procedure InitAppdefaults;
procedure AppDefaultGridListToJob;
Procedure LoadIniFile;
procedure SaveIniFile;
procedure LoadStringGrid(aGrid: TStringGrid; const my_fileName: string);
function  get_AppDefaults_float(sg_row: Integer): double;
function  get_AppDefaults_bool(sg_row: Integer): boolean;
function  get_AppDefaults_int(sg_row: Integer): Integer;
function  get_AppDefaults_str(sg_row: Integer): String;
procedure set_AppDefaults_int(sg_row, new_val: Integer);
procedure set_AppDefaults_bool(sg_row: Integer; new_val: boolean);

implementation

uses
  SysUtils, StrUtils, System.IniFiles, Forms, grbl_com, grbl_player_main,
  drawing_window, Graphics;

procedure InitMachineOptions;
begin
  with MachineOptions do begin
    SPI:= false;
    Display:= false;
    Panel:= false;
    Caxis:= false;
    VariableSpindle:= false;
    MistCoolant:= false;
    HomingLock:= false;
    DeviceAddressed:= false;
    DeviceAddress:= 0;
    HomingOrigin:= false;  // HOMING_FORCE_SET_ORIGIN
    SingleAxisHoming:= false;
    NewGrblVersion:= false;
    MachineOptions.PositiveSpace:= get_AppDefaults_bool(defPositivMachineSpace);
  end;
end;

// #############################################################################
// ############################### FILES AND JOBS ##############################
// #############################################################################

procedure CalcTipDia;
var j: Integer;
begin
  for j := 0 to 31 do begin
    case job.pens[j].tooltip of
      1:
        job.pens[j].tipdia:= job.pens[j].z_end * 0.53; // tan(30°) * 2
      2:
        job.pens[j].tipdia:= job.pens[j].z_end * 0.82;
      3:
        job.pens[j].tipdia:= job.pens[j].z_end * 1.15;
      4:
        job.pens[j].tipdia:= job.pens[j].z_end * 2;
    else
      job.pens[j].tipdia:= job.pens[j].diameter;
    end;
    if job.pens[j].tipdia > job.pens[j].diameter then
      job.pens[j].tipdia:= job.pens[j].diameter;
  end;
end;


procedure PenGridListToJob;
var i, j: Integer;
begin
  for i:= 0 to c_numOfFiles do
    job.fileDelimStrings[i]:= ShortString(Form1.SgFiles.Rows[i+1].DelimitedText);
  for i := 1 to 32 do with Form1.SgPens do begin
    // Color und Enable in DrawCell erledigt!
    j:= i-1;
    job.pens[j].color:= StrToIntDef(Cells[1,i],0);
    job.pens[j].enable:= (Cells[2,i]) = 'ON';

    job.pens[j].z_end:= StrToFloatDef(Cells[4,i],0);
    job.pens[j].speed:= StrToIntDef(Cells[5,i],250);
    job.pens[j].offset.x:= round(StrToFloatDef(Cells[6,i],0) * c_hpgl_scale);
    job.pens[j].offset.y:= round(StrToFloatDef(Cells[7,i],0) * c_hpgl_scale);
    job.pens[j].scale:= StrToFloatDef(Cells[8,i],100);
    job.pens[j].shape:= Tshape(StrToIntDef(Cells[9,i],0));
    job.pens[j].z_inc:= StrToFloatDef(Cells[10,i],1);
    job.pens[j].tooltip:= StrToIntDef(Cells[12,i],0);
    job.pens[j].atc:= StrToIntDef(Cells[11,i],0);
    job.pens[j].diameter:= StrToFloatDef(Cells[3,i],1);
    job.pens[j].blades:= StrToIntDef(Cells[13,i],0);
    CalcTipDia;
  end;
  NeedsRedraw:= true;
end;

procedure JobToPenGridList;
var i: Integer;
begin
  for i := 0 to 31 do with Form1.SgPens do begin
    if i < 10 then
      Cells[0,i+1]:= 'P' + IntToStr(i)
    else
      Cells[0,i+1]:= 'D' + IntToStr(i);
    Cells[1,i+1]:= IntToStr(job.pens[i].color);
    if job.pens[i].enable then
      Cells[2,i+1]:= 'ON'
    else
      Cells[2,i+1]:= 'OFF';
    // Color und Enable in DrawCell erledigt!
    Cells[3,i+1]:=  FormatFloat('0.00',job.pens[i].diameter);
    Cells[4,i+1]:=  FormatFloat('0.00',job.pens[i].z_end);
    Cells[5,i+1]:=  IntToStr(job.pens[i].speed);
    Cells[6,i+1]:=  FormatFloat('00.0',job.pens[i].offset.x / c_hpgl_scale);
    Cells[7,i+1]:=  FormatFloat('00.0',job.pens[i].offset.y / c_hpgl_scale);
    Cells[8,i+1]:=  FormatFloat('00.0',job.pens[i].scale);
    // Shape in DrawCell erledigt!
    Cells[9,i+1]:=  IntToStr(ord(job.pens[i].shape));
    Cells[10,i+1]:= FormatFloat('0.0',job.pens[i].z_inc);
    Cells[11,i+1]:= IntToStr(job.pens[i].atc);
    Cells[12,i+1]:= IntToStr(job.pens[i].tooltip);
    Cells[13,i+1]:= IntToStr(job.pens[i].blades);
  end;
  Form1.SgPens.Repaint;
  for i:= 0 to c_numOfFiles do
    Form1.SgFiles.Rows[i+1].DelimitedText:= string(job.fileDelimStrings[i]);
end;

procedure ClearFiles;
var i: Integer;
begin
  init_blockarrays;
  for i := 0 to c_numOfFiles do with Form1.SgFiles do begin
    job.fileDelimStrings[i]:= '"",-1,0°,OFF,0,0,100,100,0,""';
    Form1.SgFiles.Rows[i+1].DelimitedText:= string(job.fileDelimStrings[i]);

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
  ClearATCarray;
  UpdateATC;
  ListBlocks;
end;

procedure InitJob;
var i: Integer;
begin
  Form1.SgPens.Rows[0].DelimitedText:=
    'P/D,Clr,Ena,Dia,Z,F,Xofs,Yofs,"XY %",Shape,"Z-/Cyc",ATC,Tip,Blades';
  Form1.SgFiles.Rows[0].DelimitedText:=
    '"File (click to open)",Replce,Rotate,Mirror,Xofs,Yofs,"X %","Y %",Clear,"Remark"';
  Form1.SgBlocks.Rows[0].DelimitedText:=
    '#,Tool,Ena,Dia,Shape,"Polygons [closed vectors] -open vectors-"';
  Form1.SgJobdefaults.Rows[0].DelimitedText:= 'Parameter,Value';
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
    pens[8].color:= $00FFFF00;   // old $A2DCA2
    pens[9].color:= $00DCA2A2;
    pens[10].color:=clsilver;
    pens[11].color:= 11254230;
    pens[12].color:=11579647;
    pens[13].color:=10801663;
    pens[14].color:=9367540;
    pens[15].color:=10485663;
    pens[16].color:=15913395;
    pens[17].color:=16755455;
    pens[18].color:=12632256;
    pens[19].color:=15987699;;
    for i := 20 to 31 do begin
      pens[i].color:=clgray;
    end;
    for i := 10 to 31 do begin
      pens[i].shape:= drillhole;
      pens[i].tooltip:= 6;
      pens[i].diameter:= 1.0;
      pens[i].tipdia:= 1.0;
      pens[i].z_end:= 2.5;
      pens[i].z_inc:= 3.0;
      pens[i].speed:= 400;
    end;
    rotation:= 0;
  end;
  with Form1.SgJobDefaults do begin
    RowCount:= 11;
    Rows[ 1].DelimitedText:='"Part Size X",250';
    Rows[ 2].DelimitedText:='"Part Size Y",150';
    Rows[ 3].DelimitedText:='"Part Size Z",5';
    Rows[ 4].DelimitedText:='"Material",'+string(Materials[5].Name);// Weichholz
    Rows[ 5].DelimitedText:='"Z Feed for Milling",100';
    Rows[ 6].DelimitedText:='"Z Lift above Part",10';
    Rows[ 7].DelimitedText:='"Z Up above Part",5';
    Rows[ 8].DelimitedText:='"Z Gauge Height",10';
    Rows[ 9].DelimitedText:='"Optimize Drill Path",ON';
    Rows[10].DelimitedText:= '"Use Excellon Drill Diameters",ON';
  end;
  ClearFiles;
end;

///// AppDefaults StringGrid Handling //////////////////////////////////////////

procedure InitAppdefaults;
begin
  with Form1.SgAppDefaults do begin
    RowCount:= 50;
    Rows[defHeadline].DelimitedText:=            'Parameter,Value';
    Rows[defToolchangePause].DelimitedText:=     '"Enable Tool Change in Job",OFF';
    Rows[defToolchangeX].DelimitedText:=         '"Tool Change Position X absolute",10';
    Rows[defToolchangeY].DelimitedText:=         '"Tool Change Position Y absolute",100';
    Rows[defToolchangeZ].DelimitedText:=         '"Tool Change Position Z absolute",-5';
    Rows[defParkpositionOnEnd].DelimitedText:=   '"Park Position on End",ON';
    Rows[defParkX].DelimitedText:=               '"Park X absolute",100';
    Rows[defParkY].DelimitedText:=               '"Park Y absolute",100';
    Rows[defParkZ].DelimitedText:=               '"Park Z absolute",0';
    Rows[defCamXoff].DelimitedText:=             '"Cam X Offset","-20"';
    Rows[defCamYoff].DelimitedText:=             '"Cam Y Offset","20"';
    Rows[defCamZabs].DelimitedText:=             '"Cam Z absolute",0';
    Rows[defUseFixedProbe].DelimitedText:=       '"Enable fixed Z Probe",OFF';
    Rows[defProbeX].DelimitedText:=              '"Fixed Probe X absolute",30';
    Rows[defProbeY].DelimitedText:=              '"Fixed Probe Y absolute",30';
    Rows[defProbeZ].DelimitedText:=              '"Fixed Probe Z absolute",-5';
    Rows[defUsePartProbe].DelimitedText:=        '"Enable Floating Z Probe",OFF';
    Rows[defProbeZgauge].DelimitedText:=         '"Floating Z Probe ON Height",25';
    Rows[defInvertZ].DelimitedText:=             '"Invert Z in G-Code",OFF';
    Rows[defSpindleWait].DelimitedText:=         '"Spindle Accel Time (s)",4';
    Rows[defMaxRotation].DelimitedText:=         '"max. Rotation",10000';
    Rows[defAtcEnabled].DelimitedText:=          '"ATC enable",OFF';
    Rows[defAtcZeroX].DelimitedText:=            '"ATC zero X absolute",50';
    Rows[defAtcZeroY].DelimitedText:=            '"ATC zero Y absolute",20';
    Rows[defAtcPickupZ].DelimitedText:=          '"ATC pickup height Z abs",-20';
    Rows[defAtcDeltaX].DelimitedText:=           '"ATC row X distance",20';
    Rows[defAtcDeltaY].DelimitedText:=           '"ATC row Y distance",0';
    Rows[defTableX].DelimitedText:=              '"Table max travel X",200';
    Rows[defTableY].DelimitedText:=              '"Table max travel Y",200';
    Rows[defTableZ].DelimitedText:=              '"Table max travel Z",60';
    Rows[defFix1X].DelimitedText:=               '"Fixture 1 Zero X","50,00"';
    Rows[defFix1Y].DelimitedText:=               '"Fixture 1 Zero Y","70,00"';
    Rows[defFix1Z].DelimitedText:=               '"Fixture 1 Zero Z","-25,00"';
    Rows[defFix2X].DelimitedText:=               '"Fixture 2 Zero X","50,00"';
    Rows[defFix2Y].DelimitedText:=               '"Fixture 2 Zero Y","70,00"';
    Rows[defFix2Z].DelimitedText:=               '"Fixture 2 Zero Z","-25,00"';
    Rows[defAtcToolReleaseCmd].DelimitedText:=   '"ATC tool release Cmd","M8"';
    Rows[defAtcToolClampCmd].DelimitedText:=     '"ATC tool clamp Cmd","M9"';
    Rows[defJoypadFeedVeryFast].DelimitedText:=  '"Joypad Feed very fast","4000"';
    Rows[defJoypadFeedFast].DelimitedText:=      '"Joypad Feed fast","2000"';
    Rows[defJoypadFeedSlow].DelimitedText:=      '"Joypad Feed slow","500"';
    Rows[defJoypadFeedVerySlow].DelimitedText:=  '"Joypad Feed very slow","200"';
    Rows[defJoypadZaxisButton].DelimitedText:=   '"Joypad Z axis (R, U, V or Z)",Z';
    Rows[defJoypadFastJogButton].DelimitedText:= '"Joypad Fast Jog Button",4';
    Rows[defJoypadZeroAllButton].DelimitedText:= '"Joypad ZeroAll Button",0';
    Rows[defJoypadFloodToggle].DelimitedText:=   '"Joypad FloodToggle Button",2';
    Rows[defJoypadSpindleToggle].DelimitedText:= '"Joypad SpindleToggle Button",3';
    Rows[defJoypadFeedHold].DelimitedText:=      '"Joypad FeedHold Button",1';
    Rows[defPositivMachineSpace].DelimitedText:= '"Positive Machine Space",OFF';
    Rows[defTouchKeyboard].DelimitedText:=       '"TouchKeyboard",OFF';
  end;
  ClearFiles;
  Form1.Memo1.lines.add('Job/application default settings applied');
end;

procedure AppDefaultGridListToJob;
begin
  with Form1.SgAppDefaults do begin
    if RowCount < 3 then begin
      InitAppdefaults;
    end;
    job.toolchange_pause:=          get_AppDefaults_bool(defToolchangePause);
    Form1.CheckToolChange.Checked:= job.toolchange_pause;

    job.toolchange_x:=              get_AppDefaults_float(defToolchangeX);
    job.toolchange_y:=              get_AppDefaults_float(defToolchangeY);
    job.toolchange_z:=              get_AppDefaults_float(defToolchangeZ);

    job.parkposition_on_end:=       get_AppDefaults_bool(defParkpositionOnEnd);
    Form1.CheckEndPark.Checked:=    job.parkposition_on_end;

    job.park_x:=                    get_AppDefaults_float(defParkX);
    job.park_y:=                    get_AppDefaults_float(defParkY);
    job.park_z:=                    get_AppDefaults_float(defParkZ);

    job.cam_x:=                     get_AppDefaults_float(defCamXoff);
    job.cam_y:=                     get_AppDefaults_float(defCamYoff);
    job.cam_z_abs:=                 get_AppDefaults_float(defCamZabs);

    job.use_fixed_probe:=           get_AppDefaults_bool(defUseFixedProbe);
    Form1.CheckTLCprobe.Checked:=   job.use_fixed_probe;

    job.probe_x:=                   get_AppDefaults_float(defProbeX);
    job.probe_y:=                   get_AppDefaults_float(defProbeY);
    job.probe_z:=                   get_AppDefaults_float(defProbeZ);

    job.use_part_probe:=            Cells[1,defUsePartProbe] = 'ON';

    job.probe_z_gauge:=             get_AppDefaults_float(defProbeZgauge);

    job.invert_z:=                  get_AppDefaults_bool(defInvertZ);
    job.spindle_wait:=              get_AppDefaults_int(defSpindleWait);

    job.max_rotation:=              get_AppDefaults_int(defMaxRotation);

    job.atc_enabled:=               get_AppDefaults_bool(defAtcEnabled);
    Form1.CheckUseATC2.Checked:=    job.atc_enabled;

    job.atc_zero_x:=                get_AppDefaults_float(defAtcZeroX);
    job.atc_zero_y:=                get_AppDefaults_float(defAtcZeroY);
    job.atc_pickup_z:=              get_AppDefaults_float(defAtcPickupZ);
    job.atc_delta_x:=               get_AppDefaults_float(defAtcDeltaX);
    job.atc_delta_y:=               get_AppDefaults_float(defAtcDeltaY);
    job.table_x:=                   get_AppDefaults_float(defTableX);
    job.table_y:=                   get_AppDefaults_float(defTableY);
    job.table_z:=                   get_AppDefaults_float(defTableZ);

    job.fix1_x:=                    get_AppDefaults_float(defFix1X);
    job.fix1_y:=                    get_AppDefaults_float(defFix1Y);
    job.fix1_z:=                    get_AppDefaults_float(defFix1Z);
    job.fix2_x:=                    get_AppDefaults_float(defFix2X);
    job.fix2_y:=                    get_AppDefaults_float(defFix2Y);
    job.fix2_z:=                    get_AppDefaults_float(defFix2Z);
  end;
end;

Procedure LoadIniFile;
var IniName: String;
    Ini:     TMemIniFile;

  procedure ReadDef(Field:integer; Group, Key: string);
  begin
    with Form1.SgAppDefaults do
        Cells[1,field]:= Ini.ReadString(Group, Key, Cells[1, field]);
  end;

begin
  InitAppdefaults;                                         // set default values
  IniName:= ExtractFilePath(Application.exename) + 'GRBLize.ini';
  if FileExists(IniName) then begin
    Ini := TMemIniFile.Create(ExtractFilePath(Application.exename) + 'GRBLize.ini');
    try
      ReadDef(defToolchangePause,    'ToolChange',  'EnableInJob');
      ReadDef(defToolchangeX,        'ToolChange',  'PosXabsolute');
      ReadDef(defToolchangeY,        'ToolChange',  'PosYabsolute');
      ReadDef(defToolchangeZ,        'ToolChange',  'PosZabsolute');
      ReadDef(defParkpositionOnEnd,  'Park',        'OnEnd');
      ReadDef(defParkX,              'Park',        'PosXabsolute');
      ReadDef(defParkY,              'Park',        'PosYabsolute');
      ReadDef(defParkZ,              'Park',        'PosZabsolute');
      ReadDef(defCamXoff,            'Cam',         'PosXoffset');
      ReadDef(defCamYoff,            'Cam',         'PosYoffset');
      ReadDef(defCamZabs,            'Cam',         'PosZabsolute');
      ReadDef(defUseFixedProbe,      'FixedZProbe', 'Enable');
      ReadDef(defProbeX,             'FixedZProbe', 'PosXabsolute');
      ReadDef(defProbeY,             'FixedZProbe', 'PosYabsolute');
      ReadDef(defProbeZ,             'FixedZProbe', 'PosZabsolute');
      ReadDef(defUsePartProbe,       'FloatZProbe', 'Enable');
      ReadDef(defProbeZgauge,        'FloatZProbe', 'Height');
      ReadDef(defSpindleWait,        'Spindle',     'AccelTime');
      ReadDef(defMaxRotation,        'Spindle',     'MaxRotation');
      ReadDef(defAtcEnabled,         'ATC',         'Enable');
      ReadDef(defAtcZeroX,           'ATC',         'ZeroXabsolute');
      ReadDef(defAtcZeroY,           'ATC',         'ZeroYabsolute');
      ReadDef(defAtcPickupZ,         'ATC',         'PickupHeightZabs');
      ReadDef(defAtcDeltaX,          'ATC',         'RowXdistance');
      ReadDef(defAtcDeltaY,          'ATC',         'RowYdistance');
      ReadDef(defAtcToolReleaseCmd,  'ATC',         'ToolReleaseCmd');
      ReadDef(defAtcToolClampCmd,    'ATC',         'ToolClampCmd');
      ReadDef(defTableX,             'Table',       'MaxTravelX');
      ReadDef(defTableY,             'Table',       'MaxTravelY');
      ReadDef(defTableZ,             'Table',       'MaxTravelZ');
      ReadDef(defFix1X,              'Fix1',        'ZeroX');
      ReadDef(defFix1Y,              'Fix1',        'ZeroY');
      ReadDef(defFix1Z,              'Fix1',        'ZeroZ');
      ReadDef(defFix2X,              'Fix2',        'ZeroX');
      ReadDef(defFix2Y,              'Fix2',        'ZeroY');
      ReadDef(defFix2Z,              'Fix2',        'ZeroZ');
      ReadDef(defJoypadFeedVeryFast, 'Jogpad',      'FeedVeryFast');
      ReadDef(defJoypadFeedFast,     'Jogpad',      'FeedFast');
      ReadDef(defJoypadFeedSlow,     'Jogpad',      'FeedSlow');
      ReadDef(defJoypadFeedVerySlow, 'Jogpad',      'FeedVerySlow');
      ReadDef(defJoypadZaxisButton,  'Jogpad',      'Zaxis');
      ReadDef(defJoypadFastJogButton,'Jogpad',      'FastJogButton');
      ReadDef(defJoypadZeroAllButton,'Jogpad',      'ZeroAllButton');
      ReadDef(defJoypadFloodToggle,  'Jogpad',      'FloodToggleButton');
      ReadDef(defJoypadSpindleToggle,'Jogpad',      'SpindleToggleButton');
      ReadDef(defJoypadFeedHold,     'Jogpad',      'FeedHoldButton');
      ReadDef(defPositivMachineSpace,'Other',       'PositiveMachineSpace');
      ReadDef(defInvertZ,            'Other',       'InvertZinG-Code');
      ReadDef(defTouchKeyboard,      'Other',       'TouchKeyboard');
    finally
      Ini.Free;
    end;
  end;
end;

procedure SaveIniFile;
var Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create(ExtractFilePath(Application.exename) + 'GRBLize.ini');
  Ini.AutoSave:= true;
  try
    with Form1.SgAppDefaults do begin
      Ini.WriteString('ToolChange',  'EnableInJob',          Cells[1, defToolchangePause]);
      Ini.WriteString('ToolChange',  'PosXabsolute',         Cells[1, defToolchangeX]);
      Ini.WriteString('ToolChange',  'PosYabsolute',         Cells[1, defToolchangeY]);
      Ini.WriteString('ToolChange',  'PosZabsolute',         Cells[1, defToolchangeZ]);
      Ini.WriteString('Park',        'OnEnd',                Cells[1, defParkpositionOnEnd]);
      Ini.WriteString('Park',        'PosXabsolute',         Cells[1, defParkX]);
      Ini.WriteString('Park',        'PosYabsolute',         Cells[1, defParkY]);
      Ini.WriteString('Park',        'PosZabsolute',         Cells[1, defParkZ]);
      Ini.WriteString('Cam',         'PosXoffset',           Cells[1, defCamXoff]);
      Ini.WriteString('Cam',         'PosYoffset',           Cells[1,defCamYoff]);
      Ini.WriteString('Cam',         'PosZabsolute',         Cells[1,defCamZabs]);
      Ini.WriteString('FixedZProbe', 'Enable',               Cells[1,defUseFixedProbe]);
      Ini.WriteString('FixedZProbe', 'PosXabsolute',         Cells[1,defProbeX]);
      Ini.WriteString('FixedZProbe', 'PosYabsolute',         Cells[1,defProbeY]);
      Ini.WriteString('FixedZProbe', 'PosZabsolute',         Cells[1,defProbeZ]);
      Ini.WriteString('FloatZProbe', 'Enable',               Cells[1,defUsePartProbe]);
      Ini.WriteString('FloatZProbe', 'Height',               Cells[1,defProbeZgauge]);
      Ini.WriteString('Spindle',     'AccelTime',            Cells[1,defSpindleWait]);
      Ini.WriteString('Spindle',     'MaxRotation',          Cells[1,defMaxRotation]);
      Ini.WriteString('ATC',         'Enable',               Cells[1,defAtcEnabled]);
      Ini.WriteString('ATC',         'ZeroXabsolute',        Cells[1,defAtcZeroX]);
      Ini.WriteString('ATC',         'ZeroYabsolute',        Cells[1,defAtcZeroY]);
      Ini.WriteString('ATC',         'PickupHeightZabs',     Cells[1,defAtcPickupZ]);
      Ini.WriteString('ATC',         'RowXdistance',         Cells[1,defAtcDeltaX]);
      Ini.WriteString('ATC',         'RowYdistance',         Cells[1,defAtcDeltaY]);
      Ini.WriteString('ATC',         'ToolReleaseCmd',       Cells[1,defAtcToolReleaseCmd]);
      Ini.WriteString('ATC',         'ToolClampCmd',         Cells[1,defAtcToolClampCmd]);
      Ini.WriteString('Table',       'MaxTravelX',           Cells[1,defTableX]);
      Ini.WriteString('Table',       'MaxTravelY',           Cells[1,defTableY]);
      Ini.WriteString('Table',       'MaxTravelZ',           Cells[1,defTableZ]);
      Ini.WriteString('Fix1',        'ZeroX',                Cells[1,defFix1X]);
      Ini.WriteString('Fix1',        'ZeroY',                Cells[1,defFix1Y]);
      Ini.WriteString('Fix1',        'ZeroZ',                Cells[1,defFix1Z]);
      Ini.WriteString('Fix2',        'ZeroX',                Cells[1,defFix2X]);
      Ini.WriteString('Fix2',        'ZeroY',                Cells[1,defFix2Y]);
      Ini.WriteString('Fix2',        'ZeroZ',                Cells[1,defFix2Z]);
      Ini.WriteString('Jogpad',      'FeedVeryFast',         Cells[1,defJoypadFeedVeryFast]);
      Ini.WriteString('Jogpad',      'FeedFast',             Cells[1,defJoypadFeedFast]);
      Ini.WriteString('Jogpad',      'FeedSlow',             Cells[1,defJoypadFeedSlow]);
      Ini.WriteString('Jogpad',      'FeedVerySlow',         Cells[1,defJoypadFeedVerySlow]);
      Ini.WriteString('Jogpad',      'Zaxis',                Cells[1,defJoypadZaxisButton]);
      Ini.WriteString('Jogpad',      'FastJogButton',        Cells[1,defJoypadFastJogButton]);
      Ini.WriteString('Jogpad',      'ZeroAllButton',        Cells[1,defJoypadZeroAllButton]);
      Ini.WriteString('Jogpad',      'FloodToggleButton',    Cells[1,defJoypadFloodToggle]);
      Ini.WriteString('Jogpad',      'SpindleToggleButton',  Cells[1,defJoypadSpindleToggle]);
      Ini.WriteString('Jogpad',      'FeedHoldButton',       Cells[1,defJoypadFeedHold]);
      Ini.WriteString('Other',       'PositiveMachineSpace', Cells[1,defPositivMachineSpace]);
      Ini.WriteString('Other',       'InvertZinG-Code',      Cells[1,defInvertZ]);
      Ini.WriteString('Other',       'TouchKeyboard',        Cells[1,defTouchKeyboard]);
    end;
  finally
    Ini.Free;
  end;
end;

procedure LoadStringGrid(aGrid: TStringGrid; const my_fileName: string);
var
  my_StringList, my_Line: TStringList;
  aCol, aRow: Integer;
begin
  aGrid.RowCount := 2;                                 //clear any previous data
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
  MachineOptions.PositiveSpace:= get_AppDefaults_bool(defPositivMachineSpace);
end;


function get_AppDefaults_float(sg_row: Integer): double;
begin
  result:= 0;
  if sg_row < Form1.SgAppDefaults.RowCount then
    result:= StrToFloatDef(Form1.SgAppDefaults.Cells[1,sg_row],0);
end;

function get_AppDefaults_bool(sg_row: Integer): boolean;
begin
  result:= false;
  if sg_row < Form1.SgAppDefaults.RowCount then
    result:= Form1.SgAppDefaults.Cells[1,sg_row] = 'ON';
end;

function get_AppDefaults_int(sg_row: Integer): Integer;
begin
  result:= 0;
  if sg_row < Form1.SgAppDefaults.RowCount then
    result:= StrToIntDef(Form1.SgAppDefaults.Cells[1,sg_row],0);
end;

function get_AppDefaults_str(sg_row: Integer): String;
begin
  result:= '';
  if sg_row < Form1.SgAppDefaults.RowCount then
    result:= Form1.SgAppDefaults.Cells[1,sg_row];
end;

procedure set_AppDefaults_int(sg_row, new_val: Integer);
begin
  if sg_row < Form1.SgAppDefaults.RowCount then
    Form1.SgAppDefaults.Cells[1,sg_row]:= IntToStr(new_val);
end;

procedure set_AppDefaults_bool(sg_row: Integer; new_val: boolean);
begin
  if sg_row < Form1.SgAppDefaults.RowCount then
    if new_val then
      Form1.SgAppDefaults.Cells[1,sg_row]:= 'ON'
    else
      Form1.SgAppDefaults.Cells[1,sg_row]:= 'OFF';
end;

end.