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
  if my_line[my_pos] in ['0'..'9', '-', '+'] then begin
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
  dummy_str: String;

begin
  my_pos:= 1;
  repeat
    my_cmd:= get_hpgl_cmd(my_pos, my_line);
    if my_cmd = cmd_exit then
      exit;
    case my_cmd of
      cmd_pa:
        begin
          my_valid:= ParseLine(my_pos, my_line, xx, dummy_str) = p_number;
          my_valid:= my_valid and (ParseLine(my_pos, my_line, yy, dummy_str) = p_number);
          if my_valid then begin
            LastPoint.x:= round(xx);
            LastPoint.y:= round(yy);
          end;
          if LastAction >= mill then begin // war unten
            append_point(fileID, CurrentBlockID, LastPoint);
            blockArrays[fileID, CurrentBlockID].pen:= CurrentPen;
            check_filebounds(FileID, LastPoint);
          end;
        end;
      cmd_pu:
        begin
          my_valid:= ParseLine(my_pos, my_line, xx, dummy_str) = p_number;
          my_valid:= my_valid and (ParseLine(my_pos, my_line, yy, dummy_str) = p_number);
          if my_valid then begin
            LastPoint.x:= round(xx);
            LastPoint.y:= round(yy);
          end;
          LastAction:= seek;
        end;
      cmd_pd:
        begin
          if LastAction <= seek then begin
          // war oben, letzte Koordinaten sind erster Punkt im Block
            CurrentBlockID:= new_block(fileID);
            append_point(fileID, CurrentBlockID, LastPoint);
            blockArrays[fileID, CurrentBlockID].pen:= CurrentPen;
            check_filebounds(FileID, LastPoint);
          end;

          my_valid:= ParseLine(my_pos, my_line, xx, dummy_str) = p_number;
          my_valid:= my_valid and (ParseLine(my_pos, my_line, yy, dummy_str) = p_number);
          if my_valid then begin
            LastPoint.x:= round(xx);
            LastPoint.y:= round(yy);
          end;
          append_point(fileID, CurrentBlockID, LastPoint);
          check_filebounds(FileID, LastPoint);
          LastAction:= mill;
        end;
      cmd_in:
        begin
          ParseLine(my_pos, my_line, xx, dummy_str);
          ParseLine(my_pos, my_line, xx, dummy_str);
          LastAction:= lift;
        end;
      cmd_sp:
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
  file_rotate_mirror(fileID, true); // auto close path
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

type  // use of objects because type "string" can't part of a variant record
  TSvg = class(TObject)
      Pred              : TSvg;
      F                 : integer;
      penOverride       : integer;
      Matrix11, Matrix12,
      Matrix21, Matrix22: double;
      MoveX, MoveY      : double;
      ScaleX, ScaleY    : double;
      filled            : boolean;
      pen               : integer;
      Hmm               : double;                          // Seitenhöhe in [mm]
      Hpx               : double;                          // Seitenhöhe in [px]
      val               : double;
      ok                : boolean;         // vorheriger Verarbeitungsschritt ok
      constructor Create(const Predecessor: TSvg);                    overload;
      constructor Create(const Predecessor: TSvg; fid, pid: integer); overload;
      function  Analysis(const Line: string):boolean;                 virtual;
      function  Valid:boolean;                                        virtual;
      procedure Draw;                                                 virtual;
  end;

  TSvgGroup = class(TSvg)
    public
      function  Scale:double;                      // Skalierungsfaktor auf [mm]
      procedure AddPoint(Pf: TFloatPoint);
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
      procedure HandleQ();                    // quadratische Bezierkurve Beginn
      procedure HandleC();                        // kubische Bezierkurve Beginn
      procedure HandleA();                                 // elliptischer Bogen
      function  Analysis(const Line: string):boolean; override;
      function  Valid:boolean;                        override;
      procedure Draw;                                 override;
  end;

  TSvgRect = class(TSvgGroup)
      Width, Height, X, Y: double;
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

///// Class TSvg ///////////////////////////////////////////////////////////////
constructor TSvg.Create(const Predecessor: TSvg);
begin
  inherited Create;
  Pred       := Predecessor;        // Verketten mit vorhergehenden Definitionen
  ok         := true;
  if Predecessor = nil then begin
    Matrix11 := 1;                                              // Drehwinkel: 0
    Matrix12 := 0;
    Matrix21 := 0;
    Matrix22 := 1;
    MoveX    := 0;                                            // Verschiebung: 0
    MoveY    := 0;
    ScaleX   := 1;
    ScaleY   := 1;
    filled   := false;                                             // nur Kontur
    pen      := 1;                             // Stift muss gesetzt werden
    F        := MAXINT;                       // ID für Pfad muss gesetzt werden
    Hmm      := MAXDOUBLE;             // Seitenhöhe in [mm] muss gesetzt werden
    Hpx      := MAXDOUBLE;             // Seitenhöhe in [px] muss gesetzt werden
    val      := 0;
  end else begin
    Matrix11 := Pred.Matrix11;
    Matrix12 := Pred.Matrix12;
    Matrix21 := Pred.Matrix21;
    Matrix22 := Pred.Matrix22;
    MoveX    := Pred.MoveX;
    MoveY    := Pred.MoveY;
    ScaleX   := Pred.ScaleX;
    ScaleY   := Pred.ScaleY;
    filled   := Pred.filled;
    pen      := Pred.pen;
    F        := Pred.F;
    Hmm      := Pred.Hmm;
    Hpx      := Pred.Hpx;
    val      := Pred.val;
  end;
end;

///// Class TSvg ///////////////////////////////////////////////////////////////
constructor TSvg.Create(const Predecessor: TSvg; fid, pid: integer);
begin
  Create(Predecessor);
  F           := fid;
  penOverride := pid;
  if (pid >= 0) then Pen := pid;
end;

function TSvg.Analysis(const Line:string):boolean;
var i: integer;
    s: string;
begin
  Analysis := false;                         // letzte Zeile noch nicht erreicht

  i := pos(' height="', Line) + 9;
  if i > 9 then begin
    ok := false;
    if ParseLine(i, Line, Hmm, s) <> p_number then exit;   // Seitenhöhe in [mm]
  end;

  i := pos('viewBox="', Line) + 9;
  if i > 9
  then begin
    ok := false;
    if ParseLine(i, Line, val, s) <> p_number then exit;
    if ParseLine(i, Line, val, s) <> p_number then exit;
    if ParseLine(i, Line, val, s) <> p_number then exit;

    if ParseLine(i, Line, Hpx, s) <> p_number then exit;
  end;

  ok := true;
  Analysis := pos('</svg>',s) > 0                   // Analyse ist abgeschlossen
end;

function TSvg.Valid:boolean;
begin
  Valid := ok and
           (pen <> MAXINT) and                      // Stift muss gesetzt werden
           (Hmm <> MAXDOUBLE) and      // Seitenhöhe in [mm] muss gesetzt werden
           (Hpx <> MAXDOUBLE);         // Seitenhöhe in [px] muss gesetzt werden
end;

procedure TSvg.Draw;
begin
  job.pens[Pen].used:= true;                                     // Stift setzen
  job.pens[Pen].enable:= true;
end;

///// Class TSvgGroup //////////////////////////////////////////////////////////
function TSvgGroup.Scale:double;                   // Skalierungsfaktor auf [mm]
begin
  Scale := Hmm / Hpx;
end;

procedure TSvgGroup.AddPoint(Pf: TFloatPoint);
var Ph: TFloatPoint;
    Pi:  TIntpoint;
begin
// offen: Rotieren bzw. Verschieben rekursiv über alle Stufen?
  Ph.X :=   Matrix11 * Pf.X - Matrix12 * Pf.Y;           // Rotieren des Punktes
  Ph.Y := - Matrix21 * Pf.X + Matrix22 * Pf.Y;
  Ph.X := ScaleX * Ph.X;                                // Streckung des Punktes
  Ph.Y := ScaleY * Ph.Y;
  Ph.X := Ph.X + MoveX;                                // Verschieben des Punkte
  Ph.Y := Ph.Y + MoveY;
  Ph.Y := Hpx - Ph.Y; // Verschieben des Ursprungs (links oben nach links unten)

  Pi.x := round(Ph.X * c_hpgl_scale * Scale);        // Umrechnung Pixel in [mm]
  Pi.y := round(Ph.Y * c_hpgl_scale * Scale);        // & Skalierung auf 1/40mm
  check_filebounds(F, Pi);
  append_point(F, CurrentBlockID, Pi);
  blockArrays[F, CurrentBlockID].pen:= Pen;
end;

procedure TSvgGroup.EllypseAddMiddlePoint(P0, P                : TFloatPointP;
                                          rx, ry, cx, cy, x_rot: double);
var P1: TFloatPointP;
begin
// rx, ry, x_rot, cx, cy
  P1.t := (P0.t + P.t) / 2;             // Parameter zum Mittelpunkt bestimmen
  Vector2Rotate(rx*cos(P1.t),ry*sin(P1.t),x_rot,P1.P.X,P1.P.Y);
  P1.P.X := P1.P.X + cx;                          // Verschieben zum Nullpunkt
  P1.P.Y := P1.P.Y + cy;

  if Vector2DistP(P0.P, P.P, P1.P) < 4
  then begin
    AddPoint(P1.P);
    AddPoint(P.P);
  end else begin
    EllypseAddMiddlePoint(P0, P1, rx, ry, cx, cy, x_rot);
    EllypseAddMiddlePoint(P1,  P, rx, ry, cx, cy, x_rot);
  end;
end;

function TSvgGroup.Analysis(const Line: string):boolean;
var i, j   : integer;
    s      : string;
    NewPen : integer;
begin
  Analysis := false;                         // letzte Zeile noch nicht erreicht

  if pos('style="',Line) > 0 then begin
    i:= pos('stroke:#', Line) + 8;                      // Linienfarbe ermitteln
    j:= pos('fill:#', Line) + 6;                           // Füllung? ermitteln
    if (i > 8) or (j > 6)  then
    begin
      NewPen := MaxInt;

      if j > i then i := j;                          // nur fill wurde angegeben
      s := '';                                         // gültige zeichen suchen
      while (Line[i] in ['0'..'9','.','+','-','A'..'z']) and
            (i<=length(Line)) do begin
        s := s + Line[i];
        inc(i);
      end;

      if s = '000000' then NewPen := 0 else
      if s = '804000' then NewPen := 1 else
      if s = 'ff0000' then NewPen := 2 else
      if s = 'ff8000' then NewPen := 3 else
      if s = 'ffff00' then NewPen := 4 else
      if s = '00ff00' then NewPen := 5 else
      if s = '0080ff' then NewPen := 6 else
      if s = 'ff00ff' then NewPen := 7 else
      if s = '00ffff' then NewPen := 8;
    end;

    if NewPen = MaxInt then exit;

    Pen := NewPen;                                          // neue Farbe setzen
    filled := pos('fill:#',Line) <> 0;                // Objekt mit Hintergrund?
  end;

  i := pos('transform="matrix(',Line) + 18;                           // Drehung
  if i > 18 then begin
    ok := false;
    if ParseLine(i, Line, Matrix11, s) <> p_number then exit; inc(i);
    if ParseLine(i, Line, Matrix12, s) <> p_number then exit; inc(i);
    if ParseLine(i, Line, Matrix21, s) <> p_number then exit; inc(i);
    if ParseLine(i, Line, Matrix22, s) <> p_number then exit;
  end;

  i := pos('transform="translate(',Line) + 21;                   // Verschiebung
  if i > 21 then begin
    ok := false;
    if ParseLine(i, Line, MoveX, s) <> p_number then exit; inc(i);
    if ParseLine(i, Line, MoveY, s) <> p_number then exit;
  end;

  i := pos('transform="scale(',Line) + 17;                          // Streckung
  if i > 17 then begin
    ok := false;
    if ParseLine(i, Line, ScaleX, s) <> p_number then exit; inc(i);
    if ParseLine(i, Line, ScaleY, s) <> p_number then exit;
  end;

  ok := true;
  Analysis := pos('</g>',s) > 0
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
    AddPoint(P.P);
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

  AddPoint(P.P);

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
    PB.t := (PB0.t+PB1.t)/2;
    Vector2Scale(P0.P,P1,PB.t,P01);                  // P01: Mittelpunkt P0/P1
    Vector2Scale(P1,P2,PB.t,P12);                    // P12: Mittelpunkt P1/P2
    Vector2Scale(P01,P12,PB.t,PB.P);       // Zielpunkt: Mittelpunkt P012/P123

    if Vector2DistP(PB0.P, PB1.P, PB.P) < 4
    then begin
      AddPoint(PB.P);
      AddPoint(PB1.P);
    end
    else begin
      Bezier2AddPoint(PB0, PB);
      Bezier2AddPoint(PB, PB1);
    end;
  end;

begin
                                                   // Parameter: x1 y1 x2 y2 x y
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
      AddPoint(PB.P);
      AddPoint(PB1.P);
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
    AddPoint(P.P);         // wenn rx=0 oder ry=0 ==> gerade Linie (ungetestet!)
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
  Valid := ok and (inherited Valid) and (PLine <> '');
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
      if cmd = 'z' then cmd := 'Z';
      CmdContinue := false
    end;

    if ( (LastAction = lift) and
         ( (CmdContinue) or not (cmd in ['Z', 'M', 'm']) ) ) then begin
      CurrentBlockID:= new_block(F);
      blockArrays[F, CurrentBlockID].pen:= penOverride;
      AddPoint(PS);
    end;

    case upcase(cmd) of
      'M': HandleM;                                                 // Move
      'L': HandleL;                                                // Linie
      'Q': HandleQ;                      // quadratische Bezierkurve Beginn
      'C': HandleC;                          // kubische Bezierkurve Beginn
      'A': HandleA;                                   // elliptischer Bogen
      'Z': begin
             next_is_first_point:= true;
             LastAction:= lift;
             AddPoint(PS);
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
end;

function TSvgRect.Analysis(const Line: string):boolean;
var i: integer;
    s: string;
begin
  inherited Analysis(Line);

  Analysis := false;

  i := pos('width="', Line) + 7;
  if i > 7
  then begin
    ok := false;
    if ParseLine(i, Line, Width, s) <> p_number then exit;     // Breite in [px]
  end;

  i := pos('height="', Line) + 8;
  if i > 8
  then begin
    ok := false;
    if ParseLine(i, Line, Height, s) <> p_number then exit;      // Höhe in [px]
  end;

  i := pos('x="', Line) + 3;
  if i > 3
  then begin
    ok := false;
    if ParseLine(i, Line, X, s) <> p_number then exit;          // Links in [px]
  end;

  i := pos('y="', Line) + 3;
  if i > 3
  then begin
    ok := false;
    if ParseLine(i, Line, Y, s) <> p_number then exit;           // Oben in [px]
  end;

  ok := true;
  Analysis := pos('/>',Line) > 0
end;

function TSvgRect.Valid:boolean;
begin
  Valid := ok and
           (Width  <> MAXDOUBLE) and
           (Height <> MAXDOUBLE) and
           (X      <> MAXDOUBLE) and
           (Y      <> MAXDOUBLE);
end;

procedure TSvgRect.Draw;
var P: TFloatPoint;
begin
  inherited Draw;
  CurrentBlockID:= new_block(F);
  blockArrays[F, CurrentBlockID].pen:= penOverride;
  P.X := X; P.Y := Y;  AddPoint(P);
  P.Y := P.Y + Height; AddPoint(P);
  P.X := P.X + Width;  AddPoint(P);
  P.Y := P.Y - Height; AddPoint(P);
  P.X := P.X - Width;  AddPoint(P);
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
  i := pos('cx="', Line) + 4;
  if i > 4
  then begin
    ok := false;
    if ParseLine(i, Line, cx, s) <> p_number then exit;     // Zentrum.x in [px]
  end;

  i := pos('cy="', Line) + 4;
  if i > 4
  then begin
    ok := false;
    if ParseLine(i, Line, cy, s) <> p_number then exit;     // Zentrum.y in [px]
  end;

  i := pos('rx="', Line) + 4;
  if i > 4
  then begin
    ok := false;
    if ParseLine(i, Line, rx, s) <> p_number then exit;      // Radius.x in [px]
  end;

  i := pos('ry="', Line) + 4;
  if i > 4
  then begin
    ok := false;
    if ParseLine(i, Line, ry, s) <> p_number then exit;      // Radius.y in [px]
  end;

  ok := true;
  Analysis := pos('/>',Line) > 0
end;

function TSvgEllipse.Valid:boolean;
begin
  inherited Create;
  Valid := ok and
           (cx <> MAXDOUBLE) and
           (cy <> MAXDOUBLE) and
           (rx <> MAXDOUBLE) and
           (ry <> MAXDOUBLE);
end;

procedure TSvgEllipse.Draw;
var P0, P: TFloatPointP;
begin
  inherited Draw;
  CurrentBlockID:= new_block(F);
  blockArrays[F, CurrentBlockID].pen:= penOverride;

  P0.P.X := cx + rx; P0.P.Y := cy;      P0.t := 0;
  P.P.X  := cx;      P.P.Y  := cy + ry; P.t  := pi/2;
  EllypseAddMiddlePoint(P0, P, rx, ry, cx, cy, 0);

  P0    := P;
  P.P.X := cx - rx;  P.P.Y := cy;       P.t  := pi;
  EllypseAddMiddlePoint(P0, P, rx, ry, cx, cy, 0);

  P0    := P;
  P.P.X := cx;       P.P.Y := cy - ry;  P.t  := 3*pi/2;
  EllypseAddMiddlePoint(P0, P, rx, ry, cx, cy, 0);

  P0    := P;
  P.P.X := cx + rx;  P.P.Y := cy;       P.t  := 2*pi;
  EllypseAddMiddlePoint(P0, P, rx, ry, cx, cy, 0);
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
var i: integer;
    s: string;
begin
  inherited Analysis(Line);

  Analysis := false;

  i := pos('cx="', Line) + 4;
  if i > 4
  then begin
    ok := false;
    if ParseLine(i, Line, cx, s) <> p_number then exit;     // Zentrum.x in [px]
  end;

  i := pos('cy="', Line) + 4;
  if i > 4
  then begin
    ok := false;
    if ParseLine(i, Line, cy, s) <> p_number then exit;     // Zentrum.y in [px]
  end;

  i := pos('r="', Line) + 3;
  if i > 3
  then begin
    ok := false;
    if ParseLine(i, Line, r, s) <> p_number then exit;         // Radius in [px]
  end;

  ok := true;
  Analysis := pos('/>',Line) > 0
end;

function TSvgCircle.Valid:boolean;
begin
  inherited Create;
  Valid := ok and
           (cx <> MAXDOUBLE) and
           (cy <> MAXDOUBLE) and
           (r  <> MAXDOUBLE);
end;

procedure TSvgCircle.Draw;
var P0, P: TFloatPointP;
begin
  inherited Draw;
  CurrentBlockID:= new_block(F);
  blockArrays[F, CurrentBlockID].pen:= penOverride;

  P0.P.X := cx + r; P0.P.Y := cy;     P0.t := 0;
  P.P.X  := cx;     P.P.Y  := cy + r; P.t  := pi/2;
  EllypseAddMiddlePoint(P0, P, r, r, cx, cy, 0);

  P0    := P;
  P.P.X := cx - r;  P.P.Y := cy;      P.t  := pi;
  EllypseAddMiddlePoint(P0, P, r, r, cx, cy, 0);

  P0    := P;
  P.P.X := cx;      P.P.Y := cy - r;  P.t  := 3*pi/2;
  EllypseAddMiddlePoint(P0, P, r, r, cx, cy, 0);

  P0    := P;
  P.P.X := cx + r;  P.P.Y := cy;      P.t  := 2*pi;
  EllypseAddMiddlePoint(P0, P, r, r, cx, cy, 0);
end;

///// Load SVG-Files ///////////////////////////////////////////////////////////
procedure svg_fileload(my_name:String; fileID, penOverride: Integer);
var
  my_ReadFile : TextFile;
  s           : string;
  SVG, SVGtemp: TSvg;
begin
  if not FileExists(my_name) then begin
    FileParamArray[fileID].valid := false;
    exit;
  end;

//  if penOverride < 1 then penOverride:= 9;
//  job.pens[penOverride].used:= true;

  reset_filebounds(fileID);
  s := '';
  SVG := nil;

  FileMode := fmOpenRead;
  AssignFile(my_ReadFile, my_name);
  Reset(my_ReadFile);

  Readln(my_ReadFile, s);
  while not Eof(my_ReadFile) do begin
            // ==> neues SVG-Element anlegen und Daten aus bisherigem übernehmen
    if pos('<svg', s)     > 0 then SVG := TSvg.Create(nil, fileID, penOverride);
    if pos('<g', s)       > 0 then SVG := TSvgGroup.Create(SVG);
    if pos('<path', s)    > 0 then SVG := TSvgPath.Create(SVG);
    if pos('<rect', s)    > 0 then SVG := TSvgRect.Create(SVG);
    if pos('<ellipse', s) > 0 then SVG := TSvgEllipse.Create(SVG);
    if pos('<circle', s)  > 0 then SVG := TSvgCircle.Create(SVG);

    if SVG <> nil then begin
      if SVG.Analysis(s) then begin
        if SVG.valid then SVG.Draw;
        if SVG.Pred <> nil then begin
          SVGtemp := SVG.Pred;
          SVG.Destroy;
          SVG := SVGtemp;
        end;
      end;
    end;
    Readln(my_ReadFile, s);
  end;

  CloseFile(my_ReadFile);

  CurrentPen:= 0;
  LastAction:= lift;
  LastPoint.x:= 0;
  LastPoint.y:= 0;
  blockArrays[fileID, CurrentBlockID].closed:= false;
  FileParamArray[fileID].valid := true;
//  file_rotate_mirror(fileID, false); // kein Auto-close!
  file_rotate_mirror(fileID, true);
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
    append_point(fileID, CurrentBlockID, LastPoint);
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
  file_rotate_mirror(fileID, true); // auto close path
  block_scale_file(fileID);
end;


