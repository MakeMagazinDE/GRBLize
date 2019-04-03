// Offen:
// - SVG: Elypse: Mittelpunkte fehlen
// - SVG: Rotate als Transformation
// - SVG: Verzerren in X- bzw. Y-Richtung als Transformation

// #############################################################################
// HPGL Import
// #############################################################################

procedure reset_filebounds(FileID: Integer);
begin
  FileParamArray[fileID].bounds.min.x := high(Integer);
  FileParamArray[fileID].bounds.min.y := high(Integer);
  FileParamArray[fileID].bounds.max.x := low(Integer);
  FileParamArray[fileID].bounds.max.y := low(Integer);
end;

procedure check_filebounds(FileID: Integer; my_point: TIntPoint);
// Setzt anhand LastPoint die Originalumrisse in FileParamArray[fileID].bounds
begin
    // Original-Umrisse bestimmen
    if my_point.x < FileParamArray[fileID].bounds.min.x then
      FileParamArray[fileID].bounds.min.x:= my_point.x;
    if my_point.y < FileParamArray[fileID].bounds.min.y then
      FileParamArray[fileID].bounds.min.y:= my_point.y;

    if my_point.x > FileParamArray[fileID].bounds.max.x then
      FileParamArray[fileID].bounds.max.x:= my_point.x;
    if my_point.y > FileParamArray[fileID].bounds.max.y then
      FileParamArray[fileID].bounds.max.y:= my_point.y;
end;

// #############################################################################

function get_hpgl_cmd(var my_pos: Integer; var my_line: string): THPGL_cmd;
begin
  if my_line[my_pos] = ';' then begin
    result:= cmd_exit;
    exit;
  end;
  if my_pos >= length(my_line) then begin
    result:= cmd_exit;
    exit;
  end;
  if CharInSet(my_line[my_pos], ['0'..'9', '-', '+']) then begin
    result:= cmd_number;
    exit;
  end;
  if pos('PA',my_line) = my_pos then begin
    result:= cmd_pa;
    my_pos:= my_pos+2;
    exit;
  end;
  if pos('PU',my_line) = my_pos then begin
    result:= cmd_pu;
    my_pos:= my_pos+2;
    exit;
  end;
  if pos('PD',my_line) = my_pos then begin
    result:= cmd_pd;
    my_pos:= my_pos+2;
    exit;
  end;
  if pos('SP',my_line) = my_pos then begin
    result:= cmd_sp;
    my_pos:= my_pos+2;
    exit;
  end;
  if pos('IN',my_line) = my_pos then begin
    result:= cmd_in;
    my_pos:= my_pos+2;
    exit;
  end;
  if pos('LT',my_line) = my_pos then begin
    result:= cmd_none;
    my_pos:= my_pos+2;
    exit;
  end;
  if pos('AA',my_line) = my_pos then begin
    result:= cmd_aa;
    my_pos:= my_pos+2;
    exit;
  end;
  result:= cmd_exit;  // alle anderen Befehle ignorieren
end;

procedure hpgl_import_line(my_line: String; fileID, penOverride: Integer);
// Actions: none, lift, seek, drill, mill
var
  my_pos: Integer;
  my_cmd: THPGL_cmd;
  my_valid: boolean;
  my_pen: Integer;
  xx, yy: Double;
  ca, res, dir, a, dx, dy, r: Double;
  dummy_str: String;
  Pt: TIntPoint;

begin
  my_pos:= 1;
  repeat
    my_cmd:= get_hpgl_cmd(my_pos, my_line);
    if my_cmd = cmd_exit then
      exit;
    case my_cmd of
      cmd_pa:                                         // Stift bewegen, absolute
        begin
          my_valid:= ParseLine(my_pos, my_line, xx, dummy_str) = p_number;
          my_valid:= my_valid and (ParseLine(my_pos, my_line, yy, dummy_str) = p_number);
          if my_valid then begin
            LastPoint.x:= round(xx);
            LastPoint.y:= round(yy);
          end;
          if LastAction >= mill then begin                          // war unten
            append_point(fileID, CurrentBlockID, LastPoint, [t_mill,t_hilite]);
            blockArrays[fileID, CurrentBlockID].pen:= CurrentPen;
            check_filebounds(FileID, LastPoint);
          end;
        end;
      cmd_pu:                                                   // Stift anheben
        begin
          my_valid:=               ParseLine(my_pos, my_line, xx, dummy_str) = p_number;
          my_valid:= my_valid and (ParseLine(my_pos, my_line, yy, dummy_str) = p_number);
          if my_valid then begin
            LastPoint.x:= round(xx);
            LastPoint.y:= round(yy);
          end;
          LastAction:= seek;
        end;
      cmd_pd:                                                    // Stift senken
        begin
          if LastAction <= seek then begin
          // war oben, letzte Koordinaten sind erster Punkt im Block
            CurrentBlockID:= new_block(fileID);
            append_point(fileID, CurrentBlockID, LastPoint, [t_mill,t_hilite]);
            blockArrays[fileID, CurrentBlockID].pen:= CurrentPen;
            check_filebounds(FileID, LastPoint);
          end;

          my_valid:= ParseLine(my_pos, my_line, xx, dummy_str) = p_number;
          my_valid:= my_valid and (ParseLine(my_pos, my_line, yy, dummy_str) = p_number);
          if my_valid then begin
            LastPoint.x:= round(xx);
            LastPoint.y:= round(yy);
          end;
          append_point(fileID, CurrentBlockID, LastPoint, [t_mill,t_hilite]);
          check_filebounds(FileID, LastPoint);
          LastAction:= mill;
        end;
      cmd_in:                                                 // Initialisierung
        begin
          ParseLine(my_pos, my_line, xx, dummy_str);
          ParseLine(my_pos, my_line, xx, dummy_str);
          LastAction:= lift;
        end;
      cmd_sp:                                                 // Stift auswählen
        begin
          my_valid:= ParseLine(my_pos, my_line, xx, dummy_str) = p_number;
          my_pen:= round(xx);
          if penOverride >= 0 then
            my_pen:= penoverride;
          if my_valid and (my_pen < 10) then begin
            CurrentPen:= my_pen;
            job.pens[my_pen].used:= true;
            job.pens[my_pen].enable:= true;
          end else
            CurrentPen:= 0;
          LastAction:= lift;
        end;
      cmd_aa:        // Kreisbogen absolute x,y,CentralAngel[°] [,Resolution[°]]
        begin
          my_valid:=               ParseLine(my_pos, my_line, xx, dummy_str) = p_number;
          my_valid:= my_valid and (ParseLine(my_pos, my_line, yy, dummy_str) = p_number);
          my_valid:= my_valid and (ParseLine(my_pos, my_line, ca, dummy_str) = p_number);
          if not (ParseLine(my_pos, my_line, res, dummy_str) = p_number)
            then res:= 5;
          if my_valid then begin
            ca:=  pi * ca / 180;                            // convert to radian
            res:= pi * res/ 180;
            dx:= LastPoint.x-xx; dy:= LastPoint.y-yy;
            r:= sqrt( dx*dx + dy*dy );                       // calculate radius
            a:= arccos( dx / r );   // angle to LastPoint, correct for Q1 und Q2
            if dy < 0 then a:= 2*pi - a;                            // Q3 und Q4

            if LastAction >= mill then begin                         // was down
           // hilite the beginning, the center and (see below) the end of the arc
              append_point(fileID, CurrentBlockID, LastPoint, [t_hilite]);
              Pt.X:= round(xx); Pt.Y:= round(yy);
              append_point(fileID, CurrentBlockID, Pt, [t_hilite]);
              dir:= 1; if ca < 0 then begin dir:= -1; ca:= -ca; end;
              while ca > 0 do begin                      // calculate new points
                if res < ca then begin               // calc angle to next point
                  a:= a + (res * dir);
                  ca:= ca - res;
                end else begin
                  a:= a + (ca * dir);
                  ca:= 0;
                end;
                LastPoint.x:= round(xx + r*cos(a));  // calculate next LastPoint
                LastPoint.y:= round(yy + r*sin(a));
                append_point(fileID, CurrentBlockID, LastPoint, [t_mill]);
                blockArrays[fileID, CurrentBlockID].pen:= CurrentPen;
                check_filebounds(FileID, LastPoint);
              end;                                // point at the end of the arc
              append_point(fileID, CurrentBlockID, LastPoint, [t_hilite]);
            end else begin                                             // was up
              LastPoint.x:= round(xx + r*sin(a+ca));  // calculate new LastPoint
              LastPoint.y:= round(yy + r*cos(a+ca));
            end;
          end;
        end;
    end;
  until false;
end;

// #############################################################################

procedure hpgl_fileload(my_name:String; fileID, penOverride: Integer);
// Liest File in FileBuffer und liefert Länge zurück
var
  my_ReadFile: TextFile;
  i: Integer;
  my_line: String;
  my_char: char;
  my_sl: TStringList;

begin
  if not FileExists(my_name) then begin
    FileParamArray[fileID].valid := false;
    exit;
  end;
  reset_filebounds(fileID);
  my_sl:= TStringList.Create;
  my_line:='';
  FileMode := fmOpenRead;
  AssignFile(my_ReadFile, my_name);
  Reset(my_ReadFile);
  while not Eof(my_ReadFile) do begin
    Read(my_ReadFile,my_char);
    if my_char >= #32 then
      my_line:= my_line + my_char;
    if my_char= ';' then begin
      my_sl.Add(my_line);
      my_line:='';
    end;
  end;
  CloseFile(my_ReadFile);

  CurrentPen:= 0;
  LastAction:= lift;
  LastPoint.x:= 0;
  LastPoint.y:= 0;
  for i:= 0 to my_sl.count-1 do begin
    hpgl_import_line(my_sl[i], fileID, penOverride);
  end;
  my_sl.free;
  FileParamArray[fileID].valid := true;
  file_Rotate_Mirror_Scale_Offset(fileID, true); // auto close path
  block_scale_file(fileID);
end;

// #############################################################################
// Import Gerber-File mit Dimensionsdaten, contributed by Frank Kaiser
// #############################################################################


procedure dim_fileload(my_name:String; fileID, penOverride: Integer);
var Scale  : double;                          // scale between file and internal
    Xdec: integer;                          // decimal place for X/Y coordinates
    Ydec: integer;

  procedure dim_import_parameter(Line: String);
  var i:     integer;
      valid: boolean;
      xx, yy: double;
      dummy_str: String;
  //MOMM: MO - Mode;
  //      MM - [mm] (alternativ IN - inch)          Auswertung als Multiplikator
  //FSLAX34Y34  FS - Data Block Format;
  //            L  - führende 0en weglassen (T - nachfolgende 0en weglassen)
  //            A  - absolute Koordinaten (I - inkrementelle Koordinaten)
  //            X  - Format X-Koordinaten
  //            Y  - Format Y-Koordinaten                Auswertung Zahlenformat
  //LPD         LP - Data Block Format
  //            D  - dark (C - clear)                                 ignorieren
  //AMOC8       AM - Aperture Macro
  //            OC - Name des Macros
  //            8  - primitive (8 - Line                              ignorieren
  //5,1,8,0,0,1.08239X$1,22.5                                         ignorieren
  //ADD10C,0.254000       Blende 10: Kreis mit 0.254mm durchmesser    ignorieren
  begin
                                      // the following parameter will be ignored
    if pos('LPD',Line)    = 1 then exit;                               // ignore
    if pos('AMOC8',Line)  = 1 then exit;                               // ignore
    if pos('ADD10C',Line) = 1 then exit;                               // ignore

    if pos('MO',Line) = 1 then begin                                // unit mode
       if pos('MM',Line) = 3 then begin Scale:= 1;      exit end;
       if pos('IN',Line) = 3 then begin Scale:= 1/2.54; exit end;
    end;

    if pos('FSLA',Line) = 1                                // parameter format
    then begin
      i:= 5; valid:= true; xx:= 100; yy:= 100;
      while (length(Line)>i) do
      begin
        if Line[i] = 'X' then begin
           inc(i);
           valid:= valid and (ParseLine(i, Line, xx, dummy_str) = p_number);
           continue;
        end;

        if Line[i] = 'Y' then begin
           inc(i);
           valid:= valid and (ParseLine(i, Line, yy, dummy_str) = p_number);
           continue;
        end;
        inc(i);
      end;
      if valid and (xx<>100) and (yy<>100) then exit;
    end;

    Form1.Memo1.lines.add('ERROR: Unbekannter Parameter in DIM-File: ' + Line);
  end;

  procedure dim_import_cmd(line: String; fileID, penOverride: Integer);
  var i: Integer;
      xx, yy, dd: double;
      valid: boolean;
      dummy_str: String;
  // Actions: none, lift, seek, drill, mill
  //G04 EAGLE Gerber RS-274X export*  Kommentar                           ignore
  //G75*                  circular interpolation                          ignore
  //G01*                  linear interpolation                            ignore
  //D10*                  Blende 10 nutzen                                ignore
  //X0Y0D02*              Bewege nach <X,Y>, Lampe aus
  //X390400Y0D01*         Bewege nach <X,Y>, Linie
  //M00                   end of Gerber description                       ignore
  //M02                   end of Gerber description                       ignore
  begin
                                       // the following commands will be ignored
    if pos('D10',Line)    = 1 then exit;                               // ignore
    if pos('G04',Line)    = 1 then exit;                               // ignore
    if pos('G75',Line)    = 1 then exit;                               // ignore
    if pos('G01',Line)    = 1 then exit;                               // ignore
    if pos('M00',Line)    = 1 then exit;                               // ignore
    if pos('M02',Line)    = 1 then exit;                               // ignore

    if Line[1]='X' then begin
      i:= 2;
      valid:=            ParseLine(i, Line, xx, dummy_str) = p_number;
      valid:= valid and (Line[i]='Y'); inc(i);
      valid:= valid and (ParseLine(i, Line, yy, dummy_str) = p_number);
      valid:= valid and (Line[i]='D'); inc(i);
      valid:= valid and (ParseLine(i, Line, dd, dummy_str) = p_number);

      if valid then begin
        xx:= 40 * Scale * xx / power(10,Xdec);               // scale to 0.025mm
        yy:= 40 * Scale * yy / power(10,Ydec);

        if (dd > 1.5) then begin                                      // tool up
          LastPoint.x:= round(xx);
          LastPoint.y:= round(yy);
          LastAction:= seek;
        end else begin                                              // tool down
          if LastAction <= seek then begin
          // war oben, letzte Koordinaten sind erster Punkt im Block
            CurrentBlockID:= new_block(fileID);
            append_point(fileID, CurrentBlockID, LastPoint, [t_mill,t_hilite]);
            blockArrays[fileID, CurrentBlockID].pen:= CurrentPen;
            check_filebounds(FileID, LastPoint);
          end;
          LastPoint.x:= round(xx);
          LastPoint.y:= round(yy);
          append_point(fileID, CurrentBlockID, LastPoint, [t_mill,t_hilite]);
          check_filebounds(FileID, LastPoint);
          LastAction:= mill;
        end;
        exit;
      end;
    end;
    Form1.Memo1.lines.add('ERROR: Unbekanntes Kommando in DIM-File: ' + Line);
  end;

var
  my_ReadFile: TextFile;
  S: String;
  c: char;
  ParamMode: boolean;

begin
  if not FileExists(my_name) then begin
    FileParamArray[fileID].valid := false;
    exit;
  end;

  if (penOverride >= 0) and (penOverride < 10) then begin
    CurrentPen:= penOverride;
    job.pens[penOverride].used:= true;
    job.pens[penOverride].enable:= true;
  end else
    CurrentPen:= 0;

  LastAction:= lift;
  LastPoint.x:= 0;
  LastPoint.y:= 0;
  ParamMode:= false;
  Scale:= 1;                                  // scale between file and internal
  Xdec:= 4; Ydec:= 4;                               // default: 4 decimal places

  reset_filebounds(fileID);
  S:='';

  FileMode := fmOpenRead;
  AssignFile(my_ReadFile, my_name);
  Reset(my_ReadFile);
  while not Eof(my_ReadFile) do begin
    Read(my_ReadFile,c);
    if (c >= #32) and (c<>'%') then S:= S + c;
    if ParamMode then begin
      if c = '%' then begin
        dim_import_parameter(S);
        S:= '';
      end
    end else begin
      if c = '*' then begin
        dim_import_cmd(S, fileID, penOverride);
        S:='';
      end;
    end;
    if (c='%') then ParamMode:= Not ParamMode;
  end;
  CloseFile(my_ReadFile);
  FileParamArray[fileID].valid := true;
  file_Rotate_Mirror_Scale_Offset(fileID, true); // auto close path
  block_scale_file(fileID);
end;

// #############################################################################
// SVG Import, contributed by Frank Kaiser
// #############################################################################

type                                      // 2D-Punkt mit zusätzlichem Parameter
  TFloatPointP = record
    P : TFloatPoint;                                               // Koordinate
    t : double;                                                     // Parameter
  end;

type TArray33 = array[1..3,1..3] of double;

type
  TMatrix33 = class
    M : TArray33;
    constructor Create;                                                overload;
    constructor Create(const a11, a12, a13,
                             a21, a22, a23,
                             a31, a32, a33: double);                   overload;
    constructor Copy(const M0: TMatrix33);
    procedure   Product(M1:TMatrix33);
  end;

type TSvgState = (incomplete, error, corrupt, complete);
type  // use of objects because type "string" can't part of a variant record
  TSvg = class(TObject)
      Pred              : TSvg;
      F                 : integer;
      penOverride       : integer;
      M                 : TMatrix33;
      filled            : boolean;                // Kreis ausgefüllt ==> Bohren
                        // pen[0]: Anzahl der Tools für Pfad, pen[x]: Toolnummer
      pen               : array[0..c_numOfPens+1] of integer;
      Hmm               : double;                          // Seitenhöhe in [mm]
      Hpx               : double;                          // Seitenhöhe in [px]
      val               : double;
      state             : TSvgState;
      constructor Create(const Predecessor: TSvg);                    overload;
      constructor Create(const Predecessor: TSvg; fid, pid: integer); overload;
      destructor  Destroy;                                            override;
      function  Analysis(const Line: string):boolean;                 virtual;
      function  Valid:boolean;                                        virtual;
      procedure Draw;                                                 virtual;
      function  GetPen:integer;
      function  Find(const s0, s: string; var p: integer):boolean;
  end;

  TSvgGroup = class(TSvg)
    public
      function  Scale:double;                      // Skalierungsfaktor auf [mm]
      procedure AddPoint(Pf: TFloatPoint; AType: TPtType);
      procedure EllypseAddMiddlePoint(P0, P                : TFloatPointP;
                                      rx, ry, cx, cy, x_rot: double);
      function  Analysis(const Line: string):boolean; override;
  end;

  TSvgPath = class(TSvgGroup)
      PLine          : string;                                 // Pfaddefinition
      pw             : integer;                      // aktuelle Arbeitsposition
      cmd            : char;
      PS             : TFloatPoint;                     // Startpunkt des Pfades
      P0             : TFloatPointP;        // Startpunkt des aktuellen Segments
      P              : TFloatPointP;        // Endepunkt des aktuellen Segments
      CmdContinue    : boolean; // true ab zweitem Parametersatz eines Kommandos
      next_is_first_point: boolean;         // false ab zweitem Punkt des Pfades
      constructor Create(const Predecessor: TSvg);
      procedure HandleM();                                               // Move
      procedure HandleL();                                               // Line
      procedure HandleH();                                   // horizontale Line
      procedure HandleV();                                     // vertikale Line
      procedure HandleQ();                    // quadratische Bezierkurve Beginn
      procedure HandleC();                        // kubische Bezierkurve Beginn
      procedure HandleA();                                 // elliptischer Bogen
      function  Analysis(const Line: string):boolean; override;
      function  Valid:boolean;                        override;
      procedure Draw;                                 override;
  end;

  TSvgRect = class(TSvgGroup)
      Width, Height, X, Y, Rx, Ry: double;
      constructor Create(const Predecessor: TSvg);
      function  Analysis(const Line: string):boolean; override;
      function  Valid:boolean;                        override;
      procedure Draw;                                 override;
  end;

  TSvgEllipse = class(TSvgGroup)
      cx, cy, rx, ry: double;
      constructor Create(const Predecessor: TSvg);
      function  Analysis(const Line: string):boolean; override;
      function  Valid:boolean;                        override;
      procedure Draw;                                 override;
  end;

  TSvgCircle = class(TSvgGroup)
      cx, cy, r: double;
      constructor Create(const Predecessor: TSvg);
      function  Analysis(const Line: string):boolean; override;
      function  Valid:boolean;                        override;
      procedure Draw;                                 override;
  end;

///// Vektorfunktionen /////////////////////////////////////////////////////////
function Vector2DistP(P0, P1, P: TFloatPoint):double;
var dx, dy, Vx, Vy: double;
begin
   Vx := (P1.X-P0.X);
   Vy := (P1.Y-P0.Y);
   dx := (P.X-P0.X) * Vx;
   dy := (P.Y-P0.Y) * Vy;
   Vector2DistP := sqrt((dx*dx + dy*dy) / (Vx*Vx + Vy*Vy));
end;

procedure Vector2Scale(P0, P1: TFloatPoint; t: double; var P: TFloatPoint); overload;
begin
  P.X := P0.X + t*(P1.X-P0.X);
  P.Y := P0.Y + t*(P1.Y-P0.Y);
end;

function Vector2Scale(P0, P1: TFloatPoint; t: double):TFloatPoint; overload;
var P: TFloatPoint;
begin
  P.X := P0.X + t*(P1.X-P0.X);
  P.Y := P0.Y + t*(P1.Y-P0.Y);
  Vector2Scale:= P;
end;

procedure Vector2Rotate(x0,y0,Rot:double; var x, y: double);
begin
  x := x0*cos(rot) - y0*sin(rot);
  y := x0*sin(rot) + y0*cos(rot);
end;

function Vector2Angle(x0,y0,x1,y1:double):double;
var a : double;
begin
  a := arccos( ((x0*x1) + (y0*y1)) /
               (sqrt((x0*x0)+(y0*y0))*sqrt((x1*x1)+(y1*y1))) );
  if (x0*y1 - y0*x1) < 0 then a := -a;
  Vector2Angle := a;
end;

function Vector2DistP1(x0, y0, x, y, x1, y1: double):double;
var dx, dy, d: double;
begin
   dx := (x1-x0) * (x-x0);
   dy := (y1-y0) * (y-y0);
   d  := sqrt((dx*dx + dy*dy) / ((x-x0)*(x-x0) + (y-y0)*(y-y0)));
   Vector2DistP1 := d;
end;

///// Matrix33 /////////////////////////////////////////////////////////////////
constructor TMatrix33.Create;
begin
  inherited Create;
end;

constructor TMatrix33.Create(const a11, a12, a13,
                                   a21, a22, a23,
                                   a31, a32, a33: double);
begin
  Create;
  M[1,1]:= a11; M[1,2]:= a12; M[1,3]:= a13;
  M[2,1]:= a21; M[2,2]:= a22; M[2,3]:= a23;
  M[3,1]:= a31; M[3,2]:= a32; M[3,3]:= a33;
end;

constructor TMatrix33.Copy(const M0: TMatrix33);
var i, j: integer;
begin
  Create;
//  CopyArray(@M0.M,M,TArray33,9);
  for i:=1 to 3 do
    for j:=1 to 3 do M[i,j] := M0.M[i,j];
end;

procedure TMatrix33.Product(M1:TMatrix33);
var i, j, k: integer;
    M2     : TMatrix33;
begin
  M2 := TMatrix33.Create;
  for i:=1 to 3 do
    for j:=1 to 3 do
      for k:=1 to 3 do M2.M[i,j]:= M2.M[i,j] + M[i,k]*M1.M[k,j];
  M := M2.M;
end;

///// Class TSvg ///////////////////////////////////////////////////////////////
constructor TSvg.Create(const Predecessor: TSvg);
begin
  inherited Create;
  Pred       := Predecessor;        // Verketten mit vorhergehenden Definitionen
  state      := incomplete;
  if Predecessor = nil then begin
    M:= TMatrix33.Create(1,0,0,  0,1,0,   0,0,1);       // Transformationsmatrix
    filled   := false;                                             // nur Kontur
    pen[0]   := 0;                                   // noch kein Stift vergeben
    F        := MAXINT;                       // ID für Pfad muss gesetzt werden
    Hmm      := MAXDOUBLE;             // Seitenhöhe in [mm] muss gesetzt werden
    Hpx      := MAXDOUBLE;             // Seitenhöhe in [px] muss gesetzt werden
    val      := 0;
  end else begin
    M           := TMatrix33.Copy(Pred.M);
    filled      := Pred.filled;
    pen         := Pred.pen;
    penOverride := Pred.penOverride;
    F           := Pred.F;
    Hmm         := Pred.Hmm;
    Hpx         := Pred.Hpx;
    val         := Pred.val;
  end;
end;

constructor TSvg.Create(const Predecessor: TSvg; fid, pid: integer);
begin
  Create(Predecessor);
  F           := fid;
  penOverride := pid;
  if (pid >= 0) then begin
    Pen[0] := 1;
    Pen[1] := pid;
  end;
end;

destructor TSvg.Destroy;
begin
  M.Destroy;
  inherited Destroy;
end;

function TSvg.Analysis(const Line:string):boolean;
var i: integer;
    s: string;
begin
  Analysis := false;                         // letzte Zeile noch nicht erreicht
  if state <> incomplete then exit;
try
  if Find(' height="', Line, i) then
    if ParseLine(i, Line, Hmm, s) <> p_number then exit;   // Seitenhöhe in [mm]

  if Find('viewBox="', Line, i) then begin
    if ParseLine(i, Line, val, s) <> p_number then exit;
    if ParseLine(i, Line, val, s) <> p_number then exit;
    if ParseLine(i, Line, val, s) <> p_number then exit;
    if ParseLine(i, Line, Hpx, s) <> p_number then exit;
  end;

  state := incomplete;

finally
  if state = error then begin
    Form1.Memo1.lines.add('ERROR: Zeile nicht auswertbar: ' + Line);
    state:= corrupt;
  end;
  Analysis := pos('</svg>',Line) > 0                // Analyse ist abgeschlossen
end;

end;

function TSvg.Valid:boolean;
begin
  if (state = incomplete) and
       ((pen[0] > 0) or
        (Self.ClassType = TSvgGroup) or
        (Self.ClassType = TSvgGroup)) and                               // Stift muss gesetzt werden
     (Hmm <> MAXDOUBLE) and            // Seitenhöhe in [mm] muss gesetzt werden
     (Hpx <> MAXDOUBLE) then           // Seitenhöhe in [px] muss gesetzt werden
    state:= complete;
  Valid := state = complete;
end;

procedure TSvg.Draw;
begin                               // nur echte Elemente können werzeuge nutzen
  if ((Self.ClassType <> TSvg) and (Self.ClassType <> TSvgGroup)) then begin
    job.pens[GetPen].used:= true;                                // Stift setzen
    job.pens[GetPen].enable:= true;
  end;
end;

function TSvg.GetPen:integer;
var P: integer;
begin            // das blockarray wird erst mal nur für den ersten Pen angelegt
  P := pen[1];   // und, wenn vollständig, für alle weiteren Pens kopiert
  if penOverride >= 0 then P := penOverride;
  if (P<0) or (P >=32) then P := 0;
  GetPen:= P;
end;

function TSvg.Find(const s0, s: string; var p: integer):boolean;
begin
  p := pos(s0, s);
  if ((p = 0) or      // nicht gefunden oder Bezeichner hat noch eine "Vorsilbe"
      (p > 1) and CharInSet(s[p-1], ['0'..'9','A'..'z'])) then exit(false);
  p:= p + length(s0);
  state := error;    // neuen Parameter gefunden, unklar ob Einlesen erfolgreich
  Find:= true;
end;

///// Class TSvgGroup //////////////////////////////////////////////////////////
function TSvgGroup.Scale:double;                   // Skalierungsfaktor auf [mm]
begin
  Scale := Hmm / Hpx;
end;

procedure TSvgGroup.AddPoint(Pf: TFloatPoint; AType: TPtType);
var Ph: TFloatPoint;
    Pi: TIntpoint;
begin             // Matrixprodukt zur Transformation rekursiv über alle Gruppen
  Ph.X := M.M[1,1]*Pf.X + M.M[1,2]*Pf.Y + M.M[1,3];
  Ph.Y := M.M[2,1]*Pf.X + M.M[2,2]*Pf.Y + M.M[2,3];

  Ph.Y := Hpx - Ph.Y; // Verschieben des Ursprungs (links oben nach links unten)

  Pi.x := round(Ph.X * c_hpgl_scale * Scale);        // Umrechnung Pixel in [mm]
  Pi.y := round(Ph.Y * c_hpgl_scale * Scale);        // & Skalierung auf 1/40mm
  append_point(F, CurrentBlockID, Pi, AType);
  blockArrays[F, CurrentBlockID].pen:= GetPen;
  check_filebounds(F, Pi);
end;

procedure TSvgGroup.EllypseAddMiddlePoint(P0, P                : TFloatPointP;
                                          rx, ry, cx, cy, x_rot: double);
var P1: TFloatPointP;                       // P0: start point
begin                                       // P: end point
                                            // rx: first radius
                                            // ry: second radius
                                            // cx, cy: coordinates of the center
                                            // x_rot: rotation
  P1.t := (P0.t + P.t) / 2;               // Parameter zum Mittelpunkt bestimmen
  Vector2Rotate(rx*cos(P1.t),ry*sin(P1.t),x_rot,P1.P.X,P1.P.Y);
  P1.P.X := P1.P.X + cx;                            // Verschieben zum Nullpunkt
  P1.P.Y := P1.P.Y + cy;

  if Vector2DistP(P0.P, P.P, P1.P) < 4
  then begin
    AddPoint(P1.P,[t_mill]);
    AddPoint(P.P,[t_mill]);
  end else begin
    EllypseAddMiddlePoint(P0, P1, rx, ry, cx, cy, x_rot);
    EllypseAddMiddlePoint(P1,  P, rx, ry, cx, cy, x_rot);
  end;
end;

function TSvgGroup.Analysis(const Line: string):boolean;
var i, j, n, p      : integer;
    s, color        : string;
    ch              : char;
    a, b, c, d, e, f: double;
begin
  Analysis := false;                         // letzte Zeile noch nicht erreicht
  if state <> incomplete then exit;

try
  if pos('style="',Line) > 0 then begin
    state  := incomplete;
    i:= pos('stroke:#', Line) + 8;                      // Linienfarbe ermitteln
    j:= pos('fill:#', Line) + 6;                           // Füllung? ermitteln
    if (i > 8) or (j > 6)  then
    begin

      if j > i then i := j;                          // nur fill wurde angegeben
      s := '';                                         // gültige Zeichen suchen
      while CharInSet(Line[i], ['0'..'9','.','+','-','A'..'z']) and
            (i<=length(Line)) do begin
        s := s + upcase(Line[i]);
        inc(i);
      end;

      n:=0;
      for p:=0 to 9 do begin
        color:= IntToHex(int64(job.pens[p].color),6);
        ch:= color[1]; color[1]:= color[5]; color[5]:= ch;
        ch:= color[2]; color[2]:= color[6]; color[6]:= ch;
        if s = color then begin
          inc(n);
          pen[0]:= n;
          pen[n]:= p;
        end;
      end;
    end;

    filled := pos('fill:#',Line) <> 0;                // Objekt mit Hintergrund?
  end;

  if Find('transform="translate(',Line,i) then begin
    if ParseLine(i, Line, e, s) <> p_number then exit; inc(i);
    if ParseLine(i, Line, f, s) <> p_number then f := 0;
    M.Product(TMatrix33.Create(1,0,e,   0,1,f,   0,0,1));
  end;

  if Find('transform="scale(',Line,i) then begin        // Streckung - untested!
    if ParseLine(i, Line, a, s) <> p_number then exit; inc(i);
    if ParseLine(i, Line, d, s) <> p_number then d:= a;
    M.Product(TMatrix33.Create(a,0,0,   0,d,0,   0,0,1));
  end;

  if Find('transform="matrix(',Line,i) then begin                      // Matrix
    if ParseLine(i, Line, a, s) <> p_number then exit; inc(i);
    if ParseLine(i, Line, b, s) <> p_number then exit; inc(i);
    if ParseLine(i, Line, c, s) <> p_number then exit; inc(i);
    if ParseLine(i, Line, d, s) <> p_number then exit; inc(i);
    if ParseLine(i, Line, e, s) <> p_number then exit; inc(i);
    if ParseLine(i, Line, f, s) <> p_number then exit;
    M.Product(TMatrix33.Create(a,c,e,   b,d,f,   0,0,1));
  end;

  state:= incomplete;

finally
  if state = error then begin
    Form1.Memo1.lines.add('ERROR: Zeile nicht auswertbar: ' + Line);
    state:= corrupt;
  end;
//  i := pos('</g>',Line);
//  if i > 0 then
//     i:= i;
  Analysis := pos('</g>',Line) > 0
end;

end;

///// Class TsvgPath ///////////////////////////////////////////////////////////
constructor TSvgPath.Create(const Predecessor: TSvg);
begin
  inherited Create(Predecessor);
  PLine               := '';
  pw                  := 0;                          // aktuelle Arbeitsposition
  cmd                 := ' ';
  PS.X                := 0;                             // Startpunkt des Pfades
  PS.Y                := 0;
  P0.P.X              := 0;                 // Startpunkt des aktuellen Segments
  P0.P.Y              := 0;
  P0.t                := 0;
  P.P.X               := 0;                  // Endepunkt des aktuellen Segments
  P.P.Y               := 0;
  P.t                 := 0;
  CmdContinue         := false; // true ab zweitem Parametersatz eines Kommandos
  next_is_first_point := true;              // false ab zweitem Punkt des Pfades
end;

procedure TSvgPath.HandleM();
var s: string;
begin
  // Parameter einlesen
  if not CmdContinue then                                   // Fehlermeldung!!!!
    if ParseLine(pw, PLine, val, s) <> p_number then exit;
  P.P.X := val;
                                                            // Fehlermeldung!!!!
  if ParseLine(pw, PLine, val, s) <> p_number then exit;
  P.P.Y := val;

  if (cmd > 'Z')               // relative zu absoluten Koordinaten konvertieren
  then begin
    P.P.X := P0.P.X + P.P.X;
    P.P.Y := P0.P.Y + P.P.Y
  end;

  if CmdContinue
  then begin
    LastAction := mill;
    AddPoint(P.P,[t_mill,t_hilite]);
  end;

  if next_is_first_point or (LastAction = lift) then PS := P.P;
  next_is_first_point:= false;
  P0 := P;     // letzte Position als ersten Punkt für kommendes Segment sichern
end;

procedure TSvgPath.HandleL;
var s: string;
begin
  // Parameter einlesen
  if not CmdContinue then                                   // Fehlermeldung!!!!
    if ParseLine(pw, PLine, val, s) <> p_number then exit;
  P.P.X := val;
                                                            // Fehlermeldung!!!!
  if ParseLine(pw, PLine, val, s) <> p_number then exit;
  P.P.Y := val;

  // relative zu absoluten Koordinaten konvertieren
  if (cmd > 'Z') then begin
    P.P.X := P0.P.X + P.P.X;
    P.P.Y := P0.P.Y + P.P.Y
  end;

  AddPoint(P.P,[t_mill,t_hilite]);

  LastAction:= mill;
  next_is_first_point:= false;
  P0 := P;
end;

procedure TSvgPath.HandleH;
var s: string;
begin
  // Parameter einlesen
  if not CmdContinue then                                   // Fehlermeldung!!!!
    if ParseLine(pw, PLine, val, s) <> p_number then exit;
  P.P.X := val;

  P.P.Y := P0.P.Y;                                          // Y does not change

  // relative zu absoluten Koordinaten konvertieren
  if (cmd > 'Z') then P.P.X := P0.P.X + P.P.X;

  AddPoint(P.P,[t_mill,t_hilite]);

  LastAction:= mill;
  next_is_first_point:= false;
  P0 := P;
end;

procedure TSvgPath.HandleV;
var s: string;
begin
  // Parameter einlesen
  if not CmdContinue then                                   // Fehlermeldung!!!!
    if ParseLine(pw, PLine, val, s) <> p_number then exit;
  P.P.Y := val;

  P.P.X := P0.P.X;                                          // Y does not change

  // relative zu absoluten Koordinaten konvertieren
  if (cmd > 'Z') then P.P.Y := P0.P.Y + P.P.Y;

  AddPoint(P.P,[t_mill,t_hilite]);

  LastAction:= mill;
  next_is_first_point:= false;
  P0 := P;
end;

procedure TSvgPath.HandleQ;                   // quadratische Bezierkurve Beginn
var P1,P2   : TFloatPoint;       // Bezierparameter, gloable innerhalb C-Handler
    PB0, PB1: TFloatPointP;                     // Arbeitspunkte auf Bezierkurve
    s       : string;

  procedure Bezier2AddPoint(PB0, PB1: TFloatPointP);
  var P01, P12: TFloatPoint;
      PB      : TFloatPointP;
  begin
    PB.t:= (PB0.t+PB1.t)/2;
    Vector2Scale(P0.P,P1,PB.t,P01);                    // P01: Mittelpunkt P0/P1
    Vector2Scale(P1,P2,PB.t,P12);                      // P12: Mittelpunkt P1/P2
    Vector2Scale(P01,P12,PB.t,PB.P);         // Zielpunkt: Mittelpunkt P012/P123

    if Vector2DistP(PB0.P, PB1.P, PB.P) < 4
    then begin
      AddPoint(PB.P, [t_mill]);                  // additional calculated points
      AddPoint(PB1.P,[t_mill]);                  // are for milling only
    end
    else begin
      Bezier2AddPoint(PB0, PB);
      Bezier2AddPoint(PB, PB1);
    end;
  end;

begin                                              // Parameter: x1 y1 x2 y2 x y
  if not CmdContinue then                                             // read x1
    if ParseLine(pw, PLine, val, s) <> p_number then exit;
  P1.X := val;

  if ParseLine(pw, PLine, val, s) <> p_number then exit;              // read y1
  P1.Y := val;

  if ParseLine(pw, PLine, val, s) <> p_number then exit;              // read x2
  P2.X := val;

  if ParseLine(pw, PLine, val, s) <> p_number then exit;              // read y2
  P2.Y := val;

  // relative zu absoluten Koordinaten konvertieren
  if (cmd > 'Z')
  then begin
    P1.X := P0.P.X + P1.X;
    P1.Y := P0.P.Y + P1.Y;
    P2.X := P0.P.X + P2.X;
    P2.Y := P0.P.Y + P2.Y;
  end;

  AddPoint(P2,[t_hilite]);                   // set end point of the path hilite

  // Berechnung der neuen Wegpunkte
  PB0.P := P0.P; PB0.t := 0;
  PB1.P := P2;   PB1.t := 1;
  Bezier2AddPoint(PB0, PB1);

  LastAction:= mill;
  next_is_first_point:= false;

  P0.P := P2;
end;

procedure TSvgPath.HandleC;                       // kubische Bezierkurve Beginn
var P1, P2  : TFloatPoint;           // Hilfspunkte, gloable innerhalb C-Handler
    PB0, PB1: TFloatPointP;                     // Arbeitspunkte auf Bezierkurve
    s       : string;

  procedure Bezier3AddPoint(PB0, PB1: TFloatPointP);
  var P01, P12, P23, P012, P123: TFloatPoint;
      PB                       : TFloatPointP;
  begin
    PB.t := (PB0.t+PB1.t)/2;
    Vector2Scale(P0.P,P1,  PB.t,P01);                  // P01: Mittelpunkt P0/P1
    Vector2Scale(P1,  P2,  PB.t,P12);                  // P12: Mittelpunkt P1/P2
    Vector2Scale(P2,  P.P, PB.t,P23);                  // P23: Mittelpunkt P2/P3
    Vector2Scale(P01, P12, PB.t,P012);              // P012: Mittelpunkt P01/P12
    Vector2Scale(P12, P23, PB.t,P123);              // P123: Mittelpunkt P12/P23
    Vector2Scale(P012,P123,PB.t,PB.P);       // Zielpunkt: Mittelpunkt P012/P123

    if Vector2DistP(PB0.P, PB1.P, PB.P) < 4
    then begin
      AddPoint(PB.P,[t_mill]);
      AddPoint(PB1.P,[t_mill]);
    end
    else begin
      Bezier3AddPoint(PB0, PB);
      Bezier3AddPoint(PB, PB1);
    end;
  end;

begin                                              // Parameter: x1 y1 x2 y2 x y
  if not CmdContinue then                                             // read x1
    if ParseLine(pw, PLine, val, s) <> p_number then exit;
  P1.X := val;

  if ParseLine(pw, PLine, val, s) <> p_number then exit;              // read y1
  P1.Y := val;

  if ParseLine(pw, PLine, val, s) <> p_number then exit;              // read x2
  P2.X := val;

  if ParseLine(pw, PLine, val, s) <> p_number then exit;              // read y2
  P2.Y := val;

  if ParseLine(pw, PLine, val, s) <> p_number then exit;               // read x
  P.P.X := val;

  if ParseLine(pw, PLine, val, s) <> p_number then exit;               // read y
  P.P.Y := val;

  // relative zu absoluten Koordinaten konvertieren
  if (cmd > 'Z')
  then begin
    P1.X  := P0.P.X + P1.X;  P1.Y  := P0.P.Y + P1.Y;
    P2.X  := P0.P.X + P2.X;  P2.Y  := P0.P.Y + P2.Y;
    P.P.X := P0.P.X + P.P.X; P.P.Y := P0.P.Y + P.P.Y
  end;

  AddPoint(P2,[t_hilite]);

  // Berechnung der neuen Wegpunkte
  PB0.P := P0.P; PB0.t := 0;
  PB1.P := P.P;  PB1.t := 1;
  Bezier3AddPoint(PB0, PB1);

  LastAction:= mill;
  next_is_first_point:= false;

  P0 := P;
end;

procedure TSvgPath.HandleA;                                // elliptischer Bogen
var rx, ry, x_rot                      : double;
    large, sweep                       : boolean;
    x0s, y0s, L, R, a, cxs, cys, cx, cy: double;
    s                                  : string;
begin          // Parameter: rx ry x-axis-rotation large-arc-flag sweep-flag x y
  if not CmdContinue then                                             // read rx
    if ParseLine(pw, PLine, val, s) <> p_number then exit;
  rx := abs(val);               // es wird mit den Beträgen der Achsen gerechnet

  if ParseLine(pw, PLine, val, s) <> p_number then exit;              // read ry
  ry := abs(val);                // es wird mit den Bträgen der Achsen gerechnet

  if ParseLine(pw, PLine, val, s) <> p_number then exit; // read x-axis-rotation
  x_rot := Pi*val/180;                                // Umrechnen ins Winkelmaß

  if ParseLine(pw, PLine, val, s) <> p_number then exit;  // read large-arc-flag
  large := not(val = 0);

  if ParseLine(pw, PLine, val, s) <> p_number then exit;      // read sweep-flag
  sweep := not(val = 0);

  if ParseLine(pw, PLine, val, s) <> p_number then exit;               // read x
  P.P.X := val;

  if ParseLine(pw, PLine, val, s) <> p_number then exit;               // read y
  P.P.Y := val;

  // relative zu absoluten Koordinaten konvertieren
  if (cmd > 'Z') then begin
    P.P.X := P0.P.X + P.P.X;
    P.P.Y := P0.P.Y + P.P.Y
  end;

  // wenn x0=x und y0=y ==> keine Darstellung (ungetestet!)
  if (P0.P.X = P.P.X) and (P0.P.Y = P.P.Y) then exit;

  if (rx=0) or (ry=0) then begin
           // wenn rx=0 oder ry=0 ==> gerade Linie (ungetestet!)
    AddPoint(P.P,[t_mill,t_hilite]);
  end else begin

    // Wandlung in die Zentraldarstellung (siehe Wikipedia: SVG-Pfade)
    // offen: "wenn es keine Lösung zu den angegebenen Hauptachsen und dem
    //        Winkel gibt, so werden die Hauptachsen gleichmäßig hochskaliert,
    //        bis es eine Lösung gibt."


    // (x0',y0') = D(rot) ((x0 - x)/2,(y0 -y)/2)
    Vector2Rotate((P0.P.X-P.P.X)/2, (P0.P.Y-P.P.Y)/2, -x_rot, x0s, y0s);

    // L = x0'²/rx² + y0'²/ry²
    L :=  (x0s*x0s)/(rx*rx) + (y0s*y0s)/(ry*ry);

    // Falls L kleiner oder gleich 1 ist, bleiben rX und rY unkorrigiert,
    // ansonsten werden sie mit der Wurzel aus L multipliziert, damit ein
    // Ellipsenbogen möglich ist.

    if L <= 0 then begin rx := sqrt(L) * rx; ry := sqrt(L) * ry end;

    // R = rx²y0'² - ry²x0'²
    R := (rx*rx*y0s*y0s) + (ry*ry*x0s*x0s);

    // (cX',cY') = ± ((rx²*ry² - R) / R ) * (rx*y0'/ry , -ry*x0'/rx)
    // Das Vorzeichen ist +, falls large ungleich sweep ist und - sonst.
    a := sqrt( (rx*rx*ry*ry - R) / R );
    if (large = sweep) then a := -a;
    cxs :=  a*(rx*y0s/ry);
    cys := -a*(ry*x0s/rx);

    // c = D(-?) (cx',cy') + ((x0 + x)/2, (y0 + y)/2)
    Vector2Rotate(cxs, cys, x_rot, cx, cy);
    cx := cx + (P0.P.X + P.P.X)/2;
    cy := cy + (P0.P.Y + P.P.Y)/2;
                                   // Zeichenparameter für Anfangs- und Endpunkt
    P0.t := Vector2Angle(1, 0, (x0s-cxs)/rx, (y0s-cys)/ry );
    P.t  := Vector2Angle((x0s-cxs)/rx,( y0s-cys)/ry,(-x0s-cxs)/rx,(-y0s-cys)/ry );
    // if sweep = 0, then Δθ < 0, else if sweep = 1, then Δθ > 0.
    if sweep then P.t := P0.t + P.t                 // Zeichenrichtung berechnen
             else P.t := P0.t - P.t;

    // Berechnung der neuen Wegpunkte
    EllypseAddMiddlePoint(P0, P, rx, ry, cx, cy, x_rot);
  end;

  AddPoint(P.P,[t_hilite]);

  LastAction:= mill;
  next_is_first_point:= false;
  P0 := P;
end;

function TSvgPath.Analysis(const Line:string):boolean;
var i: integer;
begin
  inherited Analysis(Line);
  i:= pos(' d="', Line) + 4;                                    // Pfad kopieren
  if i > 4 then PLine := Copy(Line, i, MAXINT);
  Analysis := pos('/>',Line) > 0
end;

function TSvgPath.Valid:boolean;
begin
  if (state = incomplete) and
     (inherited Valid)    and
     (PLine <> '')
    then state:= complete;
  Valid := inherited Valid and (state = complete);
end;

procedure TSvgPath.Draw;
var s: string;
begin
  inherited Draw;

  next_is_first_point:= true;                  // für nächsten Pfad zurücksetzen
  LastAction := lift;
  P0.P.X := 0; P0.P.Y := 0;                   // Pfad startet immer am Nullpunkt
  pw := 1;                          // nur der Inhalt des Pfades wurde übergeben

  repeat
      // altes Kommndo wird fortgesetzt, jetzt steht der erste Parameter in val!
    if ParseLine(pw, PLine, val, s) <> p_letters then CmdContinue := true
    else begin
      cmd:= s[1];                 // neues Kommando, ist immer nur ein Buchstabe
      if cmd = 'z' then
        cmd := 'Z';
      CmdContinue := false
    end;

    if ( (LastAction = lift) and
       ( (CmdContinue) or not CharInSet(cmd, ['Z', 'M', 'm']) ) ) then begin
      CurrentBlockID:= new_block(F);
      AddPoint(PS,[t_mill,t_hilite]);
    end;

    case upcase(cmd) of
      'M': HandleM;                                                      // Move
      'L': HandleL;                                                     // Linie
      'H': HandleH;                                         // horizontale Linie
      'V': HandleV;                                           // vertikale Linie
      'Q': HandleQ;                           // quadratische Bezierkurve Beginn
      'C': HandleC;                               // kubische Bezierkurve Beginn
      'A': HandleA;                                        // elliptischer Bogen
      'Z': begin
             next_is_first_point:= true;
             LastAction:= lift;
             blockArrays[F, CurrentBlockID].closed:= true;
           end;
      else exit;
    end;
    inc(pw);
  until pw >= length(PLine);
end;

///// Class TsvgRect ///////////////////////////////////////////////////////////
constructor TSvgRect.Create(const Predecessor: TSvg);
begin
  inherited Create(Predecessor);
  Width  := MAXDOUBLE;
  Height := MAXDOUBLE;
  X      := MAXDOUBLE;
  Y      := MAXDOUBLE;
  Rx     := MAXDOUBLE;
  Ry     := MAXDOUBLE;
end;

function TSvgRect.Analysis(const Line: string):boolean;
var i: integer;
    s: string;
//    L0: string;
begin
  inherited Analysis(Line);

  Analysis := false;
  if state <> incomplete then exit;
try
  if Find('width="', Line, i) then
    if ParseLine(i, Line, Width, s) <> p_number then exit;     // Breite in [px]

  if Find('height="', Line, i) then
    if ParseLine(i, Line, Height, s) <> p_number then exit;      // Höhe in [px]

  if Find('x="', Line, i) then
    if ParseLine(i, Line, X, s) <> p_number then exit;          // Links in [px]

  if Find('y="', Line, i) then
    if ParseLine(i, Line, Y, s) <> p_number then exit;           // Oben in [px]

  if Find('rx="', Line, i) then
    if ParseLine(i, Line, Rx, s) <> p_number then exit;      // X-Radius in [px]

  if Find('ry="', Line, i) then
    if ParseLine(i, Line, Ry, s) <> p_number then exit;      // Y-Radius in [px]

  state := incomplete;

finally
  if state = error then begin
    Form1.Memo1.lines.add('ERROR: Zeile nicht auswertbar: ' + Line);
    state:= corrupt;
  end;
  Analysis := pos('/>',Line) > 0                    // Analyse ist abgeschlossen
end;

end;

function TSvgRect.Valid:boolean;
begin
  if (state = incomplete) and
           (Width  <> MAXDOUBLE) and
           (Height <> MAXDOUBLE) and
           (X      <> MAXDOUBLE) and
           (Y      <> MAXDOUBLE) then
    state:= complete;
  Valid := inherited Valid and (state = complete);
end;

procedure TSvgRect.Draw;
var P0, P: TFloatPointP;
begin
  inherited Draw;
  CurrentBlockID:= new_block(F);
  if Rx <> MAXDOUBLE
  then begin
    if Ry = MAXDOUBLE then Ry := Rx;
    P.P.X := X + Rx;
    P.P.Y := Y;
    AddPoint(P.P,[t_mill,t_hilite]);
    P.P.X := P.P.X + Width - 2*Rx;
    AddPoint(P.P,[t_mill,t_hilite]);

    P0 := P;                                  P0.t := 3*pi/2;
    P.P.X := P.P.X + Rx; P.P.Y := P.P.Y + Ry; P.t  := 2*pi;
    EllypseAddMiddlePoint(P0, P, Rx, Ry, P0.P.X, P.P.Y, 0);
    AddPoint(P.P,[t_hilite]);

    P.P.Y := P.P.Y + Height - 2*Ry;
    AddPoint(P.P,[t_mill,t_hilite]);

    P0 := P;                                  P0.t := 0;
    P.P.X := P.P.X - Rx; P.P.Y := P.P.Y + Ry; P.t  := pi/2;
    EllypseAddMiddlePoint(P0, P, Rx, Ry, P.P.X, P0.P.Y, 0);
    AddPoint(P.P,[t_hilite]);

    P.P.X := P.P.X - (Width - 2*Rx);
    AddPoint(P.P,[t_mill,t_hilite]);

    P0 := P;                                  P0.t := pi/2;
    P.P.X := P.P.X - Rx; P.P.Y := P.P.Y - Ry; P.t  := pi;
    EllypseAddMiddlePoint(P0, P, Rx, Ry, P0.P.X, P.P.Y, 0);
    AddPoint(P.P,[t_hilite]);

    P.P.Y := P.P.Y - (Height - 2*Ry);
    AddPoint(P.P,[t_mill,t_hilite]);

    P0 := P;                                  P0.t := pi;
    P.P.X := P.P.X + Rx; P.P.Y := P.P.Y - Ry; P.t  := 3*pi/2;
    EllypseAddMiddlePoint(P0, P, Rx, Ry, P.P.X, P0.P.Y, 0);
  end
  else begin
    P.P.X := X; P.P.Y := Y;  AddPoint(P.P,[t_mill,t_hilite]);
    P.P.Y := P.P.Y + Height; AddPoint(P.P,[t_mill,t_hilite]);
    P.P.X := P.P.X + Width;  AddPoint(P.P,[t_mill,t_hilite]);
    P.P.Y := P.P.Y - Height; AddPoint(P.P,[t_mill,t_hilite]);
    P.P.X := P.P.X - Width;  AddPoint(P.P,[t_mill]);
  end;
  blockArrays[F, CurrentBlockID].closed:= true;
end;


///// Class TSvgEllipse ////////////////////////////////////////////////////////
constructor TSvgEllipse.Create(const Predecessor: TSvg);
begin
  inherited Create(Predecessor);
  cx := MAXDOUBLE;
  cy := MAXDOUBLE;
  rx := MAXDOUBLE;
  ry := MAXDOUBLE;
end;

function TSvgEllipse.Analysis(const Line: string):boolean;
var i: integer;
    s: string;
begin
  inherited Analysis(Line);

  Analysis := false;
  if state <> incomplete then exit;
try
  if Find('cx="', Line, i) then
    if ParseLine(i, Line, cx, s) <> p_number then exit;     // Zentrum.x in [px]

  if Find('cy="', Line, i) then
    if ParseLine(i, Line, cy, s) <> p_number then exit;     // Zentrum.y in [px]

  if Find('rx="', Line, i) then
    if ParseLine(i, Line, rx, s) <> p_number then exit;      // Radius.x in [px]

  if Find('ry="', Line, i) then
    if ParseLine(i, Line, ry, s) <> p_number then exit;      // Radius.y in [px]

  state := incomplete;

finally
  if state = error then begin
    Form1.Memo1.lines.add('ERROR: Zeile nicht auswertbar: ' + Line);
    state:= corrupt;
  end;
  Analysis := pos('/>',Line) > 0                       // Analyse ist abgeschlossen
end;

end;

function TSvgEllipse.Valid:boolean;
begin
  if (state = incomplete) and
           (cx <> MAXDOUBLE) and
           (cy <> MAXDOUBLE) and
           (rx <> MAXDOUBLE) and
           (ry <> MAXDOUBLE) then
    state:= complete;
  Valid := inherited Valid and (state = complete);
end;

procedure TSvgEllipse.Draw;
var P0, P: TFloatPointP;
begin
  inherited Draw;
  CurrentBlockID:= new_block(F);

  P0.P.X := cx + rx; P0.P.Y := cy;      P0.t := 0;
  P.P.X  := cx;      P.P.Y  := cy + ry; P.t  := pi/2;
  EllypseAddMiddlePoint(P0, P, rx, ry, cx, cy, 0);
  AddPoint(P.P,[t_hilite]);

  P0    := P;
  P.P.X := cx - rx;  P.P.Y := cy;       P.t  := pi;
  EllypseAddMiddlePoint(P0, P, rx, ry, cx, cy, 0);
  AddPoint(P.P,[t_hilite]);

  P0    := P;
  P.P.X := cx;       P.P.Y := cy - ry;  P.t  := 3*pi/2;
  EllypseAddMiddlePoint(P0, P, rx, ry, cx, cy, 0);
  AddPoint(P.P,[t_hilite]);

  P0    := P;
  P.P.X := cx + rx;  P.P.Y := cy;       P.t  := 2*pi;
  EllypseAddMiddlePoint(P0, P, rx, ry, cx, cy, 0);
  AddPoint(P.P,[t_hilite]);

  blockArrays[F, CurrentBlockID].closed:= true;
end;

///// Class TSvgCircle /////////////////////////////////////////////////////////
constructor TSvgCircle.Create(const Predecessor: TSvg);
begin
  inherited Create(Predecessor);
  cx := MAXDOUBLE;
  cy := MAXDOUBLE;
  r  := MAXDOUBLE;
end;


function TSvgCircle.Analysis(const Line: string):boolean;
var i, Tool: integer;
    s      : string;
begin
  inherited Analysis(Line);

  Analysis := false;
  if state <> incomplete then exit;

  try
    if Find('cx="', Line, i) then
      if ParseLine(i, Line, cx, s) <> p_number then exit;   // Zentrum.x in [px]

    if Find('cy="', Line, i) then
      if ParseLine(i, Line, cy, s) <> p_number then exit;   // Zentrum.y in [px]

    if Find('r="', Line, i) then
      if ParseLine(i, Line, r, s) <> p_number then exit;       // Radius in [px]

    state := incomplete;

  finally
    if state = error then begin
      Form1.Memo1.lines.add('ERROR: Zeile nicht auswertbar: ' + Line);
      state:= corrupt;
    end;

    result := pos('/>',Line) > 0;                   // Analyse ist abgeschlossen

    if result and filled                             // Loch soll gebohrt werden
    then begin
      r := round(10 * r * Scale) / 10; // r in mm umrechnen und auf 0,1mm runden

      Tool:=10;
      while (Tool <= c_numOfPens)              and
            (Job.pens[Tool].used)              and
            (Job.pens[Tool].shape = drillhole) and
            (abs(Job.pens[Tool].diameter - 2*r) > 0.1) do Tool:=Tool+1;

      if Tool > c_numOfPens then begin               // ==> kein Platz mehr frei
        state:= corrupt;
        Form1.Memo1.lines.add('ERROR: Zu wenige Tools!');
      end else begin
        pen[0]:= 1;
        pen[pen[0]]:= Tool;         // Werkzeug neu setzen, Farbe wird ignoriert

        if (not Job.pens[Tool].used)          // Bohrer muss neu angelegt werden
        then begin
          job.pens[Tool].diameter:= 2*r;        // Attribute für Werkzeug setzen
          job.pens[Tool].tipdia:= 2*r;
          job.pens[Tool].used:= true;
          job.pens[Tool].shape:= drillhole;
        end;
      end;
    end;
  end;
end;

function TSvgCircle.Valid:boolean;
begin
  if (state = incomplete) and
     (cx <> MAXDOUBLE) and
     (cy <> MAXDOUBLE) and
     (r  <> MAXDOUBLE) then
    state:= complete;
  Valid := inherited Valid and (state = complete);
end;

procedure TSvgCircle.Draw;
var P0, P: TFloatPointP;
    i    : integer;
begin
  inherited Draw;

  if filled
  then begin
    CurrentBlockID:= MAXINT;   // wird der Bohrer schon genutzt? Block ermitteln
    if length(blockArrays[F]) > 0 then
      for i:= 0 to length(blockArrays[F])-1 do
        if (blockArrays[F, i].pen = pen[1]) and
           (job.pens[pen[1]].shape = drillhole)
        then begin
          CurrentBlockID := i;
          break;
        end;
                                               // Bohrer wird noch nicht genutzt
    if CurrentBlockID = MAXINT then CurrentBlockID:= new_block(F);

    P.P.X:= cx;
    P.P.Y:= cy;
    AddPoint(P.P,[t_mill,t_hilite]);                          // Punkt eintragen
  end else begin
    CurrentBlockID:= new_block(F);

    P0.P.X := cx + r; P0.P.Y := cy;     P0.t := 0;
    P.P.X  := cx;     P.P.Y  := cy + r; P.t  := pi/2;
    AddPoint(P.P,[t_hilite]);                                   // hilite Norden
    EllypseAddMiddlePoint(P0, P, r, r, cx, cy, 0);

    P0    := P;
    P.P.X := cx - r;  P.P.Y := cy;      P.t  := pi;
    AddPoint(P.P,[t_hilite]);                                   // hilite Westen
    EllypseAddMiddlePoint(P0, P, r, r, cx, cy, 0);

    P0    := P;
    P.P.X := cx;      P.P.Y := cy - r;  P.t  := 3*pi/2;
    AddPoint(P.P,[t_hilite]);                                    // hilite Süden
    EllypseAddMiddlePoint(P0, P, r, r, cx, cy, 0);

    P0    := P;
                      P.P.Y := cy;      P.t  := 2*pi;
    AddPoint(P.P,[t_hilite]);                              // hilite Mittelpunkt
    P.P.X := cx + r;
    AddPoint(P.P,[t_hilite]);                                    // hilite Osten
    EllypseAddMiddlePoint(P0, P, r, r, cx, cy, 0);

    blockArrays[F, CurrentBlockID].closed:= true;
  end;

end;

///// Load SVG-Files ///////////////////////////////////////////////////////////
procedure svg_fileload(my_name:String; fileID, penOverride: Integer);
var
  my_ReadFile : TextFile;
  s           : string;
  SVG, SVGtemp: TSvg;
  z, i, j, n  : integer;
begin
  if not FileExists(my_name) then begin
    FileParamArray[fileID].valid := false;
    exit;
  end;

  reset_filebounds(fileID);
  s := '';
  SVG := nil;
  z:= 1;

  FileMode := fmOpenRead;
  AssignFile(my_ReadFile, my_name);
  Reset(my_ReadFile);

  Readln(my_ReadFile, s);
  while not Eof(my_ReadFile) do begin
            // ==> neues SVG-Element anlegen und Daten aus bisherigem übernehmen
    if pos('<svg', s)     > 0 then
       if SVG = nil then SVG := TSvg.Create(nil, fileID, penOverride)
       else begin
         Form1.Memo1.lines.add('ERROR (Zeile ' + inttostr(z) + '): Unerwartetes SVG-Element!');
         exit;
       end;

    if pos('<g', s)       > 0 then
       if ((SVG.ClassType = TSvg) or (SVG.ClassType = TSvgGroup))
          then SVG:= TSvgGroup.Create(SVG)
          else begin
             Form1.Memo1.lines.add('ERROR (Zeile ' + inttostr(z) + '): Unerwartetes Group-Element!');
             exit;
          end;

    if pos('<path', s)    > 0 then
       if (SVG.ClassType = TSvgGroup) then SVG:= TSvgPath.Create(SVG)
          else begin
             Form1.Memo1.lines.add('ERROR (Zeile ' + inttostr(z) + '): Unerwartetes Path-Element!');
             exit;
          end;

    if pos('<rect', s)    > 0 then
       if (SVG.ClassType = TSvgGroup) then SVG:= TSvgRect.Create(SVG)
          else begin
             Form1.Memo1.lines.add('ERROR (Zeile ' + inttostr(z) + '): Unerwartetes Rect-Element!');
             exit;
          end;

    if pos('<ellipse', s) > 0 then
       if (SVG.ClassType = TSvgGroup) then SVG:= TSvgEllipse.Create(SVG)
          else begin
             Form1.Memo1.lines.add('ERROR (Zeile ' + inttostr(z) + '): Unerwartetes Ellipse-Element!');
             exit;
          end;

    if pos('<circle', s)  > 0 then
       if (SVG.ClassType = TSvgGroup) then SVG:= TSvgCircle.Create(SVG)
          else begin
             Form1.Memo1.lines.add('ERROR (Zeile ' + inttostr(z) + '): Unerwartetes Circle-Element!');
             exit;
          end;

    if SVG <> nil then begin
      if SVG.Analysis(s) then begin
        if not SVG.valid then Form1.Memo1.lines.add('ERROR (Zeile ' + inttostr(z) + '): Element nicht korrekt!')
        else begin
          n:= SVG.pen[0];
          for i:=1 to n do begin
            SVG.Draw;                                          // draw first pen
            if n > 1 then begin                                   // rotate pens
              for j:=n downto 1 do
                SVG.pen[j+1]:= SVG.pen[j];
              SVG.pen[1]:=SVG.pen[n+1];
            end;
          end;
        end;
        if SVG.Pred <> nil then begin
          SVGtemp := SVG.Pred;
          SVG.Destroy;
          SVG:= SVGtemp;
        end;
      end;
    end;
    Readln(my_ReadFile, s);
    z:= z+1;
  end;

  CloseFile(my_ReadFile);

  CurrentPen:= 0;
  LastAction:= lift;
  LastPoint.x:= 0;
  LastPoint.y:= 0;
  FileParamArray[fileID].valid := true;
  file_Rotate_Mirror_Scale_Offset(fileID, true);                  // Auto-close!
  block_scale_file(fileID);
end;

// #############################################################################
// GCode 2D Import, berücksichtigt kein Z bzw. nur über/unter Null
// #############################################################################

procedure gcode_import_line(my_line: String; fileID, penOverride: Integer);
// Simpler Gcode-Parser für 2D-Daten. Ignoriert Z-Tiefe, sondern entscheidet
// anhandh G0/G1, ob verfahren oder gefräst wird.
// Einfaches Format, zeilenorientiert.
// nutzt
// function ParseLine(var position: Integer; var linetoparse: string;
//                    var value: Double; var letters: String): T_parseReturnType;
// Actions: none, lift, seek, drill, mill
var
  my_cmd: char;
  my_pos, my_len: Integer;
  my_dval: Double;
  my_cmd_str: String;
  got_new_xy: Boolean;
  my_action: tAction;

begin
  if penOverride < 1 then
    penOverride:= 9;
  job.pens[penOverride].used:= true;
  my_pos:= 1;
  my_len:= length(my_line) - 1;
  if my_pos > my_len then // Leerzeile
    exit;
  got_new_xy:= false;
  my_action:= mill;
  repeat
    if (my_line[my_pos] = '(') or (my_line[my_pos] = '/') then   // Kommentar
      break;
    if ParseLine(my_pos, my_line, my_dval, my_cmd_str) = p_letters then begin
      my_cmd:= my_cmd_str[1];
      case my_cmd of
        'G':
          begin
            if ParseLine(my_pos, my_line, my_dval, my_cmd_str) = p_number then begin
              if my_dval = 0 then
                my_action:= seek
              else if my_dval = 1 then begin
                my_action:= mill;
                if LastAction <> mill then begin
                  // Pfadbeginn, neuen Block anlegen
                  CurrentBlockID:= new_block(fileID);
                  blockArrays[fileID, CurrentBlockID].pen:= penOverride;
                  // Immer als offene Linien behandeln, sonst werden innenliegende zu Childs
                  blockArrays[fileID, CurrentBlockID].closed:= false;
                end;
              end else
                break; // alles andere in dieser Zeile ignorieren
            end;
          end;
        'X':
          if ParseLine(my_pos, my_line, my_dval, my_cmd_str) = p_number then begin
            LastPoint.x:= round(my_dval * c_hpgl_scale);
            got_new_xy:= true;
          end;
        'Y':
          if ParseLine(my_pos, my_line, my_dval, my_cmd_str) = p_number then begin
            LastPoint.y:= round(my_dval * c_hpgl_scale);
            got_new_xy:= true;
          end;
        'Z':
          begin
            ParseLine(my_pos, my_line, my_dval, my_cmd_str);
            // war eigentlich schon durch G0/G1 klar
            if my_dval < 0 then
              my_action:= mill;
          end;
        'M':
          begin // Modale Maschinenbefehle abbrechen, irrelevant
            my_action:= none;
            break;
          end;

        'F', 'S':
          ParseLine(my_pos, my_line, my_dval, my_cmd_str); // dummy
      end;
    end;
    inc(my_pos);
  until my_pos > my_len;
  if got_new_xy and (my_action = mill)
  and (CurrentBlockID < length(blockArrays[fileID])) then begin
    append_point(fileID, CurrentBlockID, LastPoint, [t_mill,t_hilite]);
    check_filebounds(FileID, LastPoint);
  end;

  LastAction:= my_action;
end;

// #############################################################################

procedure gcode_fileload(my_name:String; fileID, penOverride: Integer);
// Liest File in FileBuffer und liefert Länge zurück
var
  i: Integer;
  my_sl: TStringList;

begin
  if not FileExists(my_name) then begin
    FileParamArray[fileID].valid := false;
    exit;
  end;
  reset_filebounds(fileID);
  my_sl:= TStringList.Create;
  my_sl.loadfromfile(my_name);

  CurrentPen:= 0;
  LastAction:= none;
  LastPoint.x:= 0;
  LastPoint.y:= 0;
  for i:= 0 to my_sl.count-1 do begin
    gcode_import_line(my_sl[i], fileID, penOverride);
  end;
  my_sl.free;
  FileParamArray[fileID].valid := true;
  file_Rotate_Mirror_Scale_Offset(fileID, true);              // auto close path
  block_scale_file(fileID);
end;


