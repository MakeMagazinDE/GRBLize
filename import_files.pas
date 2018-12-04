unit import_files;

interface
uses
  SysUtils, StrUtils, Windows, Classes, Forms, Controls, Menus, MMSystem,
  Math, StdCtrls, Graphics, FileCtrl, Dialogs, Clipper;

const
  c_hpgl_scale = 40;
  c_numOfFiles = 8 -1;
  c_numOfPens = 32 -1;

type

  Thpgl_cmd = (cmd_none, cmd_pa, cmd_pu, cmd_pd, cmd_sp, cmd_in, cmd_aa,
              cmd_number, cmd_drill, cmd_exit, cmd_nextline);
  Tshape  = (contour, inside, outside, pocket, drillhole);
  Trotate = (deg0, deg90, deg180, deg270);
  Taction = (none, lift, seek, mill, drill);
  T_parseReturnType = (p_none, p_endofline, p_letters, p_number);
  TPtType = set of (t_mill, t_hilite);

  TFloatPoint = record
    X: Double;
    Y: Double;
  end;

  TfloatBounds = record
    min: TFloatPoint;
    max: TFloatPoint;
    mid: TFloatPoint;
  end;

  Tatc_record = record
//    enable: boolean; // ... und Pen ist eingeschaltet
    used: boolean; // ... und Pen ist eingeschaltet
    isInSpindle: boolean; // Flag wird von Wechsler-Routine aktualisiert
    pen: Integer;
    TREFok: boolean;
    TLCok: boolean;
    TLCref: Double;
    TLCdelta: Double;
  end;

  Tbounds = record
    min: TIntPoint;
    max: TIntPoint;
    mid: TIntPoint;
  end;

  Tpen_record = record
    used: boolean;
    enable: boolean;
    shape: Tshape;
    color: TColor;
    diameter: Double;
    tipdia: Double;
    offset: TIntPoint;    // in HPGL Plotter units 40/mm
    scale: Double;
    speed: Integer;
    z_end: Double;
    z_inc: Double;
    atc: Integer;
    tooltip: Integer;
    blades: integer;
    force_closed: Boolean;
  end;

  Tjob = record
    fileDelimStrings: Array[0..c_numOfFiles] of String[255];
    pens: Array[0..31] of Tpen_record;
    partsize_x: Double;
    partsize_y: Double;
    partsize_z: Double;
    material: Integer;
    z_feed: Integer;
    z_penlift: Double;
    z_penup: Double;
    z_gauge: Double;
    cam_x: Double;
    cam_y: Double;
    cam_z_abs: Double;
    park_x: Double;
    park_y: Double;
    park_z: Double;
    toolchange_x: Double;
    toolchange_y: Double;
    toolchange_z: Double;
    probe_x: Double;
    probe_y: Double;
    probe_z: Double;
    probe_z_gauge: Double;
    invert_z: Boolean;
    parkposition_on_end: Boolean;
    toolchange_pause: Boolean;
    use_excellon_dia: Boolean;
    optimize_drills: Boolean;
    use_fixed_probe: Boolean;
    use_part_probe: Boolean;
    spindle_wait: Integer; // Hochlaufzeit
    rotation: integer;
    max_rotation: integer;
    atc_enabled: Boolean;
    atc_zero_x: Double;
    atc_zero_y: Double;
    atc_pickup_z: Double;
    atc_delta_x: Double;
    atc_delta_y: Double;
    table_x: Double;
    table_y: Double;
    table_z: Double;
    fix1_x: Double;
    fix1_y: Double;
    fix1_z: Double;
    fix2_x: Double;
    fix2_y: Double;
    fix2_z: Double;
  end;

  Tfile_param = record
    valid: boolean;
    enable: boolean;
    penoverride: Integer;
    rotate: Trotate;
    mirror: Boolean;
    isdrillfile:Boolean;
    bounds: Tbounds;
    offset: TintPoint;
    scale:  TFloatPoint;
    scale_y: Double;
    gbr_inflate: Double;                                   // used for PCBs only
    gbr_name:    string;                                   // used for PCBs only
    gbr_mirror:  boolean;                                  // used for PCBs only

  end;

  Tblock_record = record
    enable:      boolean;
    pen:         Integer;
    fileID:      Integer;                                   // von welchem File?
    closed:      boolean;   // closed Polygon (TRUE) oder offener Linienpfad (FALSE)
    isChild:     boolean;                                    // hat einen Parent
    parentID:    Integer;         // -1 wenn kein Parent gefunden, sonst Block-#
    isParent:    boolean;                                  // hat eine ChildList
    childList:   Array of Integer;
    bounds:      Tbounds;
    outline_raw: Tpath;                // outline path original (Integer Points)
    outline:     Tpath;                              // skaliert und mit Offsets
    hilite:      TPath;                                         // hilite points
  end;

  Tfinal = record
    enable: Boolean;
    out_of_work: Boolean;
    pen: Integer;
    shape: Tshape;
    closed: Boolean;
    fileID: Integer;   // von welchem File?
    was_closed: Boolean;
    bounds: Tbounds;
    outlines: Tpaths;
    millings: Tpaths;
    hilites:  TPaths;
    milling_enables: array of Boolean; // äußere [0] und Child-Pfade
  end;


const
  ActionArray: Array [0..4] of String[7] =
   ('none', 'lift', 'seek', 'drill', 'mill');
  ShapeArray: Array [0..4] of String[15] =
   ('Contour', 'Inside', 'Outside', 'Pocket', 'Drill');
  ShapeColorArray: Array [0..4] of Tcolor =
   (clBlack, clBlue, clRed, clFuchsia, clgreen);
  ToolTipArray: Array [0..7] of String[15] =
   ('Flat Tip', 'Cone 30°', 'Cone 45°', 'Cone 60°', 'Cone 90°','Ball Tip','Drill', 'Dummy');
  zeroPoint: TIntPoint = (
    X: 0;
    Y: 0;
    );

  PenInit: Tpen_record = (
      used: false;
      enable: false;
      shape: contour;
      color: clblack;
      diameter: 2.0;
      tipdia: 2.0;
      scale: 100;
      speed: 400;
      z_end: 2.0;
      z_inc: 1.0;
      blades: 2;
    );

  BlockZeroEntry: Tblock_record =
    ( enable: false;
      pen: -1;
      fileID: 0;
      closed: false;
      isChild: false;
      parentID: -1;
      isParent: false;
    );

var
  job:            Tjob;
  FileParamArray: Array[0..c_numOfFiles] of Tfile_param;
  blockArrays:    Array[0..c_numOfFiles] of Array of Tblock_record;

  jp_old: TIntPoint;
  use_inches_in_drillfile: Boolean;

  final_array: Array of Tfinal;
  final_bounds: Tbounds; // Abmessungen gesamt inkl. Offsets in HPGL-Units, wird in ListBlocks gesetzt
  final_bounds_mm: TfloatBounds; // Abmessungen gesamt inkl. Offsets in mm, wird in ListBlocks gesetzt
  ATCarray: Array[0..31] of Tatc_record;

  CurrentPen, PendingPen: Integer;
  LastAction, PendingAction: Taction;
  CurrentBlockID,
  CurrentfileID: Integer;
  Last_z: Double;
  LastPoint: TIntPoint;
  FileIndex: Integer;

  procedure init_blockArrays;
  function point_in_bounds(my_point: TIntPoint; my_bounds: Tbounds): Boolean;
  function bounds_in_bounds(my_bounds1, my_bounds2: Tbounds): Boolean;

  procedure  hpgl_fileload(my_name:String; fileID, penOverride: Integer);
  procedure   dim_fileload(my_name:String; fileID, penOverride: Integer);
  procedure   svg_fileload(my_name:String; fileID, penOverride: Integer);
  procedure drill_fileload(my_name:String; fileID, penOverride: Integer; useDrillDia: Boolean);
  procedure gcode_fileload(my_name:String; fileID, penOverride: Integer);

  procedure apply_pen_change;
  procedure item_change(arr_idx: Integer);

  function RoundToDigits(zahl: double; n: integer): double;
  function FloatToStrDot(my_val: Double):String;
  function StrDotToFloat(my_str: String): Double;


// alle Pfad-Enables des übergebenen Blocks auf enable_status setzen
  procedure enable_all_millings(var my_entry: Tfinal; enable_status: Boolean);
// ein bestimmtes Pfad-Enable des übergebenen Blocks auf enable_status setzen
  procedure enable_single_milling(var my_entry: Tfinal; path_idx: Integer; enable_status: Boolean);
  function is_any_milling_enabled(var my_entry: Tfinal):Boolean;

  // sucht in Array my_path nach Punkt mit geringstem Abstand zu last_xy
  function find_nearest_point(var search_path: Tpath; last_x, last_y: Integer): Integer;

// Zerlegt String nach Zahlen und Buchtstaben(ketten),
// beginnt my_line an Position my_pos nach Buchstaben oder Zahlen anbzusuchen.
// Wurde eine Zahl gefunden, ist Result = p_number, ansonsten p_letter.
// Wurde nichts (mehr) gefunden, ist Result = p_endofline.
// POSITION zeigt zum Schluss auf das Zeichen NACH dem letzten gültigen Wert.
// T_parseReturnType = (p_none, p_endofline, p_letters, p_number);
  function ParseLine(var position: Integer; const linetoparse: string;
                     var value: Double; var letters: String): T_parseReturnType;

// Dekodiert einen einzelnes Befehlsbuchstaben/Wert-Paar, beginnend an Position
// Liefert Buchstaben in "letter" und folgenden Wert in "value" zurück
// Ergebnis ist TRUE, wenn Befehlsbuchstaben/Wert-Paar gefunden wurde
// POSITION zeigt zum Schluss auf das Zeichen NACH dem letzten gültigen Wert.
  function ParseCommand(var position: Integer; var linetoparse: string;
    var value: Double; var letter: char): boolean;


implementation

uses grbl_player_main;

procedure enable_all_millings(var my_entry: Tfinal; enable_status: Boolean);
// alle Pfad-Enables des übergebenen Blocks auf enable_status setzen
var i: Integer;
begin
  if length(my_entry.millings) > 0 then
    for i := 0 to high(my_entry.millings) do
      my_entry.milling_enables[i]:= enable_status;
  if length(my_entry.millings) = 1 then
    my_entry.enable:= enable_status;
end;

function is_any_milling_enabled(var my_entry: Tfinal):Boolean;
var i: Integer;
begin
  result:= false;
  if length(my_entry.millings) > 0 then
    for i := 0 to high(my_entry.millings) do
      if my_entry.milling_enables[i] then begin
        result:= true;
        break;
      end;
end;

procedure enable_single_milling(var my_entry: Tfinal; path_idx: Integer; enable_status: Boolean);
// ein bestimmtes Pfad-Enable des übergebenen Blocks auf enable_status setzen
begin
  if (path_idx < length(my_entry.millings)) and (length(my_entry.millings) > 0) then
    my_entry.milling_enables[path_idx]:= enable_status;
  if length(my_entry.millings) = 1 then
    my_entry.enable:= enable_status;
end;

function RoundToDigits(zahl: double; n: integer): double;
// Runde Zahl auf n Nachkommastellen
var multi: double;
begin
  multi:=IntPower(10, n);
  zahl:=round(zahl*multi);
  result:=zahl/multi;
end;

function FloatToStrDot(my_val: Double):String;
var my_Settings: TFormatSettings;
begin
  my_Settings.Create;
  my_Settings.DecimalSeparator := '.';
  FloatToStrDot:= FormatFloat('0.00',my_val,my_Settings);
end;

function StrDotToFloat(my_str: String): Double;
var my_Settings: TFormatSettings;
begin
  my_Settings.Create;
  my_Settings.DecimalSeparator := '.';
  StrDotToFloat:= StrToFloatDef(my_str,0,my_Settings);
end;

function ParseLine (var position: Integer; const linetoparse: string;
  var value: Double; var letters: String): T_parseReturnType;
// Zerlegt String nach Zahlen und Buchtstaben(ketten),
// beginnt my_line an Position my_pos nach Buchstaben oder Zahlen anbzusuchen.
// Wurde eine Zahl gefunden, ist Result = p_number, ansonsten p_letter.
// Wurde nichts (mehr) gefunden, ist Result = p_endofline.
// POSITION zeigt zum Schluss auf das Zeichen NACH dem letzten gültigen Wert.
// T_parseReturnType = (p_none, p_endofline, p_letters, p_number);
var
  my_str: String;
  my_char: char;
  my_end, i: integer;
begin
  my_end:= length(linetoparse);
  value:= 0;
  letters:= '';

  result:= p_none;
  if (position > my_end) then
    exit;
  // Leer- und Steuerzeichen überspringen
  repeat
    my_char := linetoparse[position]; // erstes Zeichen
    inc(position);
  until CharInSet(my_char, ['0'..'9', '.',  '+', '-', 'A'..'z']) or (position > my_end);

  dec(position);   // Zeigt auf erstes relevantes Zeichen oder Ende
  if position > my_end then
    exit;

  my_char := linetoparse[position]; // erstes relevantes Zeichen

  if my_char = 'T' then begin
  value:= 0;

  end;
  my_str:='';
  if CharInSet(my_char, ['A'..'z']) then begin
    result:= p_letters;
    for i:= position to my_end do begin
      if not CharInSet(linetoparse[i], ['A'..'z']) then
        break;
      my_str:= my_str+ linetoparse[i];
    end;
    position:= i;
    letters:= my_str;
  end else if CharInSet(my_char, ['0'..'9', '.',  '+', '-', 'e', 'E']) then begin
    result:= p_number;
    for i:= position to my_end do begin
      if not CharInSet(linetoparse[i], ['0'..'9', '.',  '+', '-', 'e', 'E']) then
        break;
      my_str:= my_str+ linetoparse[i];
    end;
    position:= i;
    value:= StrDotToFloat(my_str);
  end;
end;

function ParseCommand(var position: Integer; var linetoparse: string;
  var value: Double; var letter: char): boolean;
// Dekodiert einen einzelnes Befehlsbuchstaben/Wert-Paar, beginnend an Position
// Liefert Buchstaben in "letter" und folgenden Wert in "value" zurück
// Ergebnis ist TRUE, wenn Befehlsbuchstaben/Wert-Paar gefunden wurde
var
  my_str: String;
begin
  letter:= #13;
  result:= false;
  if position < length(linetoparse) then begin
    letter:= linetoparse[position];
    inc(position);
    if (letter >= 'A') and (letter <= 'z') then begin
      ParseLine(position, linetoparse, value, my_str);
      result:= true;
    end;
  end;
end;

// #############################################################################
// #############################################################################

procedure init_blockArrays;
var i: Integer;
begin
  CurrentBlockID:= 0;
  for i := 0 to c_numOfFiles do begin
    SetLength(blockArrays[i], 0);
  end;
end;

function new_block(fileID: Integer): Integer;
// hängt leeren Block an
var my_len: Integer;
begin
  my_len:= length(blockArrays[fileID]);
  SetLength(blockArrays[fileID], my_len+1);
  blockArrays[fileID,my_len]:= BlockZeroEntry;
  SetLength(blockArrays[fileID,my_len].outline_raw, 0);
  SetLength(blockArrays[fileID,my_len].outline, 0);
  new_block:= my_len;
end;

procedure append_point(fileID, blockID: Integer; new_pt: TintPoint; AType: TPtType);
// für File-Import:
// hängt übergebenen Punkt an Block-Pfad an und setzt File-Bounds
var l: Integer;
begin
  // Bounds des Files neu setzen
  if new_pt.X < FileParamArray[fileID].bounds.min.x then
    FileParamArray[fileID].bounds.min.x:= new_pt.X;
  if new_pt.X > FileParamArray[fileID].bounds.max.x then
    FileParamArray[fileID].bounds.max.x:= new_pt.X;

  if new_pt.Y < FileParamArray[fileID].bounds.min.y then
    FileParamArray[fileID].bounds.min.y:= new_pt.Y;
  if new_pt.Y > FileParamArray[fileID].bounds.max.y then
    FileParamArray[fileID].bounds.max.y:= new_pt.Y;

  // Bounds des Blocks neu setzen
  if new_pt.X < blockArrays[fileID, blockID].bounds.min.x then
    blockArrays[fileID, blockID].bounds.min.x:= new_pt.X;
  if new_pt.X > blockArrays[fileID, blockID].bounds.max.x then
    blockArrays[fileID, blockID].bounds.max.x:= new_pt.X;

  if new_pt.Y < blockArrays[fileID, blockID].bounds.min.y then
    blockArrays[fileID, blockID].bounds.min.y:= new_pt.Y;
  if new_pt.Y > FileParamArray[fileID].bounds.max.y then
    blockArrays[fileID, blockID].bounds.max.y:= new_pt.Y;

  if t_hilite in AType then begin
    l:= length(blockArrays[fileID, blockID].hilite);
    SetLength(blockArrays[fileID, blockID].hilite, l+1);
    blockArrays[fileID, blockID].hilite[l]:= new_pt;
  end;

  if t_mill in AType  then begin
    l:= length(blockArrays[fileID, blockID].outline_raw);
    SetLength(blockArrays[fileID, blockID].outline_raw, l+1);
    blockArrays[fileID, blockID].outline_raw[l]:= new_pt;
    SetLength(blockArrays[fileID, blockID].outline, l+1);
    blockArrays[fileID, blockID].outline[l]:= new_pt;
  end;
end;

// #############################################################################

procedure file_rotate_mirror(fileID: Integer; auto_close_polygons: boolean);
// Jeden Block prüfen, ob geschlossener Pfad; danach outline_raw-Pfade
// rotieren und spiegeln
// Verwendet beim Import gesetzte File-Bounds
// muss gleich nach Import geschehen
var FParam:                             Tfile_param;
    b, p, BlockLen, PathLen, HiliteLen: integer;
    FirstPt, LastPt, Pt:                TintPoint;
    a, c:                               double;
begin
  FParam:= FileParamArray[fileID];
  if not FParam.valid then exit;                                 // entry unused

  BlockLen:= length(blockArrays[fileID]);
  if BlockLen = 0 then exit;                           // keine Blöcke enthalten

  for b:= 0 to BlockLen - 1 do begin
                                                         // handle closed pathes
    PathLen:= length(blockArrays[fileID, b].outline_raw);
    if PathLen = 0 then continue;                       // keine Pfade enthalten

  // letzten Eintrag entfernen, falls gleich erstem Punkt, dafür "closed" setzen
    FirstPt:= blockArrays[fileID,b].outline_raw[0];
    LastPt:=  blockArrays[fileID,b].outline_raw[PathLen-1];
    if (FirstPt.X = LastPt.X) and (FirstPt.Y = LastPt.Y) and
       (PathLen > 1) and auto_close_polygons then begin
      dec(PathLen);
      blockArrays[fileID,b].closed:= true;
      setlength(blockArrays[fileID,b].outline_raw, PathLen);
      setlength(blockArrays[fileID,b].outline, PathLen);

      HiliteLen:= length(blockArrays[fileID, b].hilite);
      if  HiliteLen > 1 then begin
        FirstPt:= blockArrays[fileID,b].hilite[0];
        LastPt:=  blockArrays[fileID,b].hilite[HiliteLen-1];
        if (FirstPt.X = LastPt.X) and (FirstPt.Y = LastPt.Y) then
          setlength(blockArrays[fileID,b].Hilite, HiliteLen-1);
      end;
    end;

    for p:= 0 to PathLen - 1 do begin               // rework all points of path
      Pt:= blockArrays[fileID, b].outline_raw[p];

      if FParam.rotate <> deg0 then begin                    // rotation of file
        c:=sqrt(Pt.X*Pt.X + Pt.Y*Pt.Y);                           // hypothenuse
        a:=arccos(Pt.X/c);                                              // angle
        case FParam.rotate of
          deg90:  a:=a+pi/2;
          deg180: a:=a+pi;
          deg270: a:=a+3*pi/2;
        end;
        Pt.X:=round(c*cos(a));
        Pt.Y:=round(c*sin(a));
      end;

      if FParam.mirror then Pt.X:= -Pt.X;                   // mirroring of file
                                                  // skaling and offsets of file
      Pt.X:= FParam.offset.X + (round(Pt.X * 10 * FParam.scale.X) div 1000);
      Pt.Y:= FParam.offset.y + (round(Pt.Y * 10 * FParam.scale.Y) div 1000);

      blockArrays[fileID, b].outline_raw[p]:= Pt;
    end;
  end;
end;

procedure block_scale(fileID, blockID: Integer);
// Block mit Pen-Skalierung versehen
var i, my_pen, my_len: Integer;
  my_bounds: Tbounds;
  my_pt: TintPoint;
begin
  if not FileParamArray[fileID].valid then
    exit;
  if length(blockArrays[fileID]) = 0 then
    exit; // kein Block vorhanden
  my_len:= length(blockArrays[fileID,blockID].outline_raw);
  if my_len = 0 then
    exit; // kein Path vorhanden
  my_pen:= blockArrays[fileID, blockID].pen;
  if my_pen < 0 then
    exit; // kein Pen vorhanden

  my_bounds.min.x:= high(Integer);
  my_bounds.min.y:= high(Integer);
  my_bounds.max.x:= low(Integer);
  my_bounds.max.y:= low(Integer);
  for i:= 0 to my_len-1 do begin
    my_pt:= blockArrays[fileID, blockID].outline_raw[i];
    // Skalierung des Blocks
    my_pt.X:= round(my_pt.X * 10 * job.pens[my_pen].scale) div 1000;
    my_pt.Y:= round(my_pt.Y * 10 * job.pens[my_pen].scale) div 1000;

    if my_pt.X < my_bounds.min.x then
      my_bounds.min.x:= my_pt.X;
    if my_pt.X > my_bounds.max.x then
      my_bounds.max.x:= my_pt.X;

    if my_pt.Y < my_bounds.min.y then
      my_bounds.min.y:= my_pt.Y;
    if my_pt.Y > my_bounds.max.y then
      my_bounds.max.y:= my_pt.Y;
    blockArrays[fileID, blockID].outline[i]:= my_pt;
  end;
  blockArrays[fileID, blockID].enable:= FileParamArray[fileID].enable and job.pens[my_pen].enable;
  my_bounds.mid.x:= (my_bounds.min.x + my_bounds.max.x) div 2;
  my_bounds.mid.y:= (my_bounds.min.y + my_bounds.max.y) div 2;
  blockArrays[fileID,blockID].bounds:= my_bounds;
end;

procedure block_scale_file(fileID: Integer);
// skaliert Pens/Tools über gesamtes File
var
  my_blockID, my_blockcount: Integer;
begin
  my_blockcount:= length(blockArrays[fileID]);
  if my_blockcount = 0 then
    exit;
  if FileParamArray[fileID].valid then
    for my_blockID:= 0 to my_blockcount - 1 do
      block_scale(fileID, my_blockID);
end;

procedure block_scale_all;
// skaliert Pens/Tools über alle Files
var
  i: Integer;
begin
  for i:= 0 to c_numOfFiles do
    block_scale_file(i);
end;

procedure block_scale_pen(penID: Integer);
// skaliert Pens/Tools über alle Files
var
  my_fileID, my_blockID, my_blockcount: Integer;
begin
  for my_fileID:= 0 to c_numOfFiles do begin
    my_blockcount:= length(blockArrays[my_fileID]);
    if FileParamArray[my_fileID].valid then
      for my_blockID:= 0 to my_blockcount - 1 do begin
        if blockArrays[my_fileID, my_blockID].pen = penID then
          block_scale(my_fileID, my_blockID);
      end;
  end;
end;

function bounds_in_bounds(my_bounds1, my_bounds2: Tbounds): Boolean;
// liefert TRUE wenn my_bounds1 innerhalb oder auf my_bounds2
begin
  bounds_in_bounds:= false;
  if my_bounds1.min.x < my_bounds2.min.x then
    exit;
  if my_bounds1.min.y < my_bounds2.min.y then
    exit;
  if my_bounds1.max.x > my_bounds2.max.x then
    exit;
  if my_bounds1.max.y > my_bounds2.max.y then
    exit;
  bounds_in_bounds:= true;
end;

function point_in_bounds(my_point: TIntPoint; my_bounds: Tbounds): Boolean;
begin
  point_in_bounds:= false;
  if my_point.x < my_bounds.min.x then
    exit;
  if my_point.x > my_bounds.max.x then
    exit;
  if my_point.y < my_bounds.min.y then
    exit;
  if my_point.y > my_bounds.max.y then
    exit;
  point_in_bounds:= true;
end;

function find_nearest_point(var search_path: Tpath; last_x, last_y: Integer): Integer;
// sucht in Array my_path nach Punkt mit geringstem Abstand zu last_xy
var
  p, temp_idx, lastdv, dv, dx, dy, my_len: Integer;
begin
  my_len:= length(search_path);
  lastdv:= high(Integer);
  temp_idx:= 0;
  for p:= 0 to my_len-1 do begin
    dx:= search_path[p].x;
    dy:= search_path[p].y;
    // ist dieser Punkt ist gleich dem Ausgangspunkt?
    if (dx = last_x) and (dy = last_y) then
      continue; // wenn ja, überspringen
    // finde nächstliegenden Punkt
    dx:= abs(dx - last_x); // Abstand zum Ausgangspunkt
    dy:= abs(dy - last_y);
    // dv:= round(sqrt(sqr(dx) + sqr(dy)));
    // schneller und ausreichend: Absolutwerte addieren
    dv:= dx + dy;
    if dv <= lastdv then begin
      temp_idx:= p; // wird "mitgezogen"
      lastdv:= dv;
    end;
  end;
  find_nearest_point:= temp_idx;
end;

// #############################################################################
{$I hpgl_import.inc}
{$I drill_import.inc}
// #############################################################################


procedure add_outline_to_final(my_path: Tpath; my_Idx: Integer);
var my_len: Integer;
begin
  if (length(my_path) > 0) and (my_Idx < length(final_array)) then begin
    my_len:= length(final_array[my_Idx].outlines);
    setlength(final_array[my_Idx].outlines, my_len+1);
    final_array[my_Idx].outlines[my_len]:= my_path;
  end;
end;

procedure add_hilite_to_final(APath: Tpath; AIdx: Integer);
var len: Integer;
begin
  if (length(APath) > 0) and (AIdx < length(final_array)) then begin
    len:= length(final_array[AIdx].hilites);
    setlength(final_array[AIdx].hilites, len+1);
    final_array[AIdx].hilites[len]:= APath;
  end;
end;

function add_block_to_final(my_block: Tblock_record): Integer;
// erzeugt neuen final_array-Eintrag, gibt Index zu neuem final zurück
var
  i: Integer;
begin
  i:= length(final_array);
//  if my_block.enable then begin
    setlength(final_array, i+1);
    // diese Werte können nachträglich geändert werden:
    final_array[i].shape:= job.pens[my_block.pen].shape;
    // diese Werte liegen seit Import fest:
    final_array[i].enable:= my_block.enable;
                          // handle out_of_work independently from manual enable
    final_array[i].out_of_work:= my_block.enable;
    final_array[i].pen:= my_block.pen;
    if job.pens[my_block.pen].force_closed then
      final_array[i].closed:= true  // ist ein Gerber-Import
    else
      final_array[i].closed:= my_block.closed;
    final_array[i].was_closed:= my_block.closed;
    final_array[i].bounds:= my_block.bounds;

    // ersten Outline-Pfad übertragen
    setlength(final_array[i].outlines, 1);
    setlength(final_array[i].outlines[0], 1);
    final_array[i].outlines[0]:= my_block.outline;

    if length(my_block.hilite) > 0 then begin      // Hiliting points übertragen
      setlength(final_array[i].hilites, 1);
      setlength(final_array[i].hilites[0], 1);
      final_array[i].hilites[0]:= my_block.hilite;
    end;

    //  end;
  add_block_to_final:= i;
end;


procedure make_final_array(fileID: Integer);
// Blocks zusammensuchen, Childs adoptieren
// Berücksichtigt nur eine Verwandschaftsebene!
// Trägt Werte aus Pen-Array ein
var i, c, p, m: Integer;
  my_len: Integer;
begin

  for p:= 0 to length(blockArrays[fileID])-1 do begin    // Parent-Loop (p)
    if blockArrays[fileID, p].parentID >= 0 then
      continue;                                 // ist bereits Parent
    if not blockArrays[fileID, p].enable then
      continue;                                 // nicht aktiv
    if not blockArrays[fileID, p].closed then
      continue;                                 // nicht geschlossen
    if job.pens[blockArrays[fileID,0].pen].Shape in [drillhole, contour] then
      continue;                                 // ist bereits Parent
    // Child-Objekte erstellen
    for c:= 0 to length(blockArrays[fileID])-1 do begin  // Child-Loop (c)
      if p = c then
        continue;                               // sind wir selbst
      if not blockArrays[fileID, c].enable  then
        continue;                               // nicht aktiv
      if blockArrays[fileID,c].pen <> blockArrays[fileID,p].pen then
        continue;                               // nicht mein Pen
      if not blockArrays[fileID,c].closed then
        continue;                               // ist nur eine Linie
      if blockArrays[fileID,c].parentID >= 0 then       // ist bereits Parent
        continue;
      if not bounds_in_bounds(blockArrays[fileID,c].bounds, blockArrays[fileID,p].bounds) then
        continue;   // Child ist nicht in Parent-Bounds

      // ist Outline von Block [k] in Outline von Block [i] enthalten?
      // if PointInPolygon (blockArray[c].bounds.mid, blockArray[p].outline) <> 0 then begin
      blockArrays[fileID,c].parentID:= p;
      blockArrays[fileID,c].isChild:= true;
      // Parent setzen
      my_len:= length(blockArrays[fileID,p].childList);
      setlength(blockArrays[fileID,p].childList, my_len+1);
      blockArrays[fileID,p].childList[my_len]:= c;
      blockArrays[fileID,p].isParent:= true;
     // end;
    end;
  end;

  for p:= 0 to length(blockArrays[fileID])-1 do begin
    if not blockArrays[fileID,p].closed then begin
      add_block_to_final(blockArrays[fileID,p]);     // ist nur eine Linie
      continue;
    end;
    if not blockArrays[fileID,p].isChild then begin // ist ersteinmal kein Child
      m:= add_block_to_final(blockArrays[fileID,p]);          // also hinzufügen
      if blockArrays[fileID,p].isParent then                // hat Block Childs?
        for i:= 0 to length(blockArrays[fileID,p].childList)-1 do begin  // Child-Loop (c)
          c:= blockArrays[fileID,p].childList[i];
          add_outline_to_final(blockArrays[fileID,c].outline, m);
          add_hilite_to_final(blockArrays[fileID,c].outline, m);
        end;
    end;
  end;
end;

// #############################################################################
// #############################################################################
// CLIPPER tools
// #############################################################################
// #############################################################################


procedure compile_milling(var my_final_entry: Tfinal);
// Wrapper für ClipperOffset für einzelnen Pen, mehrere Blocks
// erstellt milling-Paths-Array mit ggf. mehreren Pfadgruppen
// Milling-Pfade [0] sind immer outline

var i, j, rp, mp: Integer;
  my_radius, my_dia: Double;
  result_paths: Tpaths;
  my_poly_end: TEndType;
  my_cclw: boolean;
  my_millingcount, my_pointcount: Integer; // millcount, pointcount
begin
// Offenbar seit Delphi XE8 funktioniert der Offset
// von innenliegenden Objekten mit Clipper nicht mehr.
// temporärer Workaround: Einzelne Objekte anlegen, keine Childs.
  with TClipperOffset.Create() do
  try
    if (my_final_entry.shape = drillhole) or (my_final_entry.shape = contour) then begin
      my_final_entry.millings:= my_final_entry.outlines;
      exit; // weiter mit finally...
    end;
    my_radius:= job.pens[my_final_entry.pen].tipdia * (c_hpgl_scale div 2);  // = mm * 40plu / 2
    my_dia:= job.pens[my_final_entry.pen].tipdia/2;

    if (my_final_entry.shape = inside) or (my_final_entry.shape = pocket) then begin
      my_radius:= -my_radius;
    end;

    if length(my_final_entry.outlines)> 1 then begin
      my_cclw:= Orientation(my_final_entry.outlines[0]); // ist Richtung Parent CCLW?
      for i:= 1 to length(my_final_entry.outlines)-1 do begin
        // wenn Parent Counterclockwise ist und auch Child, dann Child-Richtung umkehren
        if Orientation(my_final_entry.outlines[i]) xor (not my_cclw) then
          // Childs umkehren, damit sie ein "Loch" sind
          my_final_entry.outlines[i]:= ReversePath(my_final_entry.outlines[i]);
      end;
    end;
    Clear;
    ArcTolerance:= 3;
    if my_final_entry.closed then
      my_poly_end:= etClosedPolygon
    else
      my_poly_end:= etOpenRound;
    AddPaths(my_final_entry.outlines, jtRound, my_poly_end);
    Execute(result_paths, my_radius);
    my_final_entry.millings:= result_paths;
    if my_final_entry.shape = pocket then begin
      my_radius:= my_radius + 5;
      if abs(my_radius) < 20 then // 0,5 mm
        my_radius:= -20;
      for i:= 0 to 99 do begin
        Clear;
        AddPaths(result_paths, jtRound, my_poly_end);
        Execute(result_paths, my_radius);
        if length(result_paths) = 0 then
          break;
        rp:= length(result_paths);
        mp:= length(my_final_entry.millings);
        setlength(my_final_entry.millings, mp + rp);
        for j:= 0 to rp-1 do
          my_final_entry.millings[mp+j]:= CleanPolygon(result_paths[j], my_dia);
      end;
    end;
    // falls Clipper keine Pfade erzeugt hat, Kontur nehmen - sonst scheitert ListBlocks!
    if length(my_final_entry.millings) = 0 then begin
      my_final_entry.millings:= my_final_entry.outlines;
    end else
      // Außenkonturen einzelner Linien müssen geschlossen werden. Ersten als letzten Punkt anfügen
      if (my_final_entry.shape = outside) then begin
        my_millingcount:= length(my_final_entry.millings);
        if my_millingcount > 0 then
          for i:= 0 to my_millingcount - 1 do begin
            my_pointcount:= length(my_final_entry.millings[i]);
            setLength(my_final_entry.millings[i], my_pointcount + 1); // anfügen
            my_final_entry.millings[i,my_pointcount]:= my_final_entry.millings[i,0];
          end;
      end;

  finally
    my_millingcount:= length(my_final_entry.millings);
    // Enable-Flag-Array für einzelne Milling-Pfade erstellen
    setLength(my_final_entry.milling_enables, my_millingcount);
    if my_millingcount > 0 then
      for i := 0 to my_millingcount-1 do
        my_final_entry.milling_enables[i]:= my_final_entry.enable; // vorbelegen
    Free;
  end;
end;

// #############################################################################
// #############################################################################


procedure apply_pen_change;
// alle Änderungen, Offset etc.
var i: Integer;
begin
  block_scale_all;
  setlength(final_array, 0);
  for i:= 0 to c_numOfFiles do
    if FileParamArray[i].valid then
      make_final_array(i);
  // Werkzeugkorrektur-Offsets für fertiges BlockArray
  for i:= 0 to high(final_array) do begin
    compile_milling(final_array[i]);
// alle Pfad-Enables des übergebenen Blocks auf enable_status setzen
    enable_all_millings(final_array[i], final_array[i].enable);
  end;
  ListBlocks;
end;

procedure item_change(arr_idx: Integer);
// Parameter-Änderungen in Final-Array anwenden
begin
  if (arr_idx < length(final_array)) and (arr_idx >= 0) then
    compile_milling(final_array[arr_idx]);
  ListBlocks;
end;

end.

