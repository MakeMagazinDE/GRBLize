unit drawing_window;
// 2D-Visualisierung der Fr�swege und Bohrl�cher f�r GRBLize CNC-Steuerung


interface

uses
  Math, StdCtrls, ComCtrls, ToolWin, Buttons, ExtCtrls, ImgList,
  Controls, StdActns, Classes, ActnList, Menus, GraphUtil,
  SysUtils, StrUtils, Windows, Graphics, Forms, Registry,  // Messages,
  Dialogs, Spin, ShellApi, VFrames, ExtDlgs, grbl_com, XPMan, CheckLst, Clipper,
  System.UItypes, System.Types, MMsystem, import_files;

type
  TForm2 = class(TForm)
    DrawingBox: TPaintBox;
    PopupMenuObject: TPopupMenu;
    pu_ObjectEnabled: TMenuItem;
    N1: TMenuItem;
    pu_online: TMenuItem;
    pu_inside: TMenuItem;
    pu_outside: TMenuItem;
    pu_pocket: TMenuItem;
    N2: TMenuItem;
    PopupMenuPart: TPopupMenu;
    pu_moveZero2: TMenuItem;
    pu_isAtZero2: TMenuItem;
    pu_isatCenter1: TMenuItem;
    N5: TMenuItem;
    pu_camIsAtZero2: TMenuItem;
    pu_moveCamToZero2: TMenuItem;
    pu_camIsAtCenter: TMenuItem;
    pu_moveCamToCenter: TMenuItem;
    Panel1: TPanel;
    BtnZoomReset: TButton;
    TrackBarZoom: TTrackBar;
    CheckBoxDimensions: TCheckBox;
    CheckBoxDirections: TCheckBox;
    StaticText2: TStaticText;
    StaticText3: TStaticText;
    CheckBoxToolpath: TCheckBox;
    Label1: TLabel;
    Drill1: TMenuItem;
    pu_moveCenter1: TMenuItem;
    PopupMenuPoint: TPopupMenu;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem12: TMenuItem;
    pu_MoveToPoint: TMenuItem;
    MenuItem18: TMenuItem;
    pu_MoveCamToPoint: TMenuItem;
    N3: TMenuItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure pu_camIsAtPointClick(Sender: TObject);
    procedure pu_camIsAtCenterClick(Sender: TObject);
    procedure pu_moveCamToPointClick(Sender: TObject);
    procedure pu_moveCamToCenterClick(Sender: TObject);
    procedure pu_moveCamToPartZeroClick(Sender: TObject);
    procedure pu_camIsAtPartZeroClick(Sender: TObject);
    procedure pu_toolIsAtCenterClick(Sender: TObject);
    procedure pu_moveToolToCenterClick(Sender: TObject);
    procedure pu_toolisAtPartZeroClick(Sender: TObject);
    procedure pu_moveToolToPartZeroClick(Sender: TObject);
    procedure BtnZoomResetClick(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure DrawingBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
        Y: Integer);
    procedure DrawingBoxMouseUp(Sender: TObject; Button: TMouseButton;
        Shift: TShiftState; X, Y: Integer);
    procedure DrawingBoxMouseDown(Sender: TObject; Button: TMouseButton;
        Shift: TShiftState; X, Y: Integer);
    procedure pu_PathEnabledClick(Sender: TObject);
    procedure pu_radioClick(Sender: TObject);
    procedure pu_moveToolToPointClick(Sender: TObject);
    procedure pu_toolisatpointClick(Sender: TObject);
    procedure CheckBoxDirectionsClick(Sender: TObject);
    procedure CheckBoxDimensionsClick(Sender: TObject);
    procedure ScrollBarChange(Sender: TObject);
    procedure TrackBarZoomChange(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure pu_ObjectenabledClick(Sender: TObject);

  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    DrawingBitmap: TBitmap;
  end;

const
  c_center_offs_x: Integer = 40;
  c_center_offs_y: Integer = 40;

var
  Scale: Double;
  Form2: TForm2;
  fActivated, fCamPresent : boolean;

  drawing_offset_x, drawing_offset_y: Integer;
  scaled_X, scaled_Y: Double;
  bm_scroll: Tpoint;
  mouse_start: Tpoint;
  NeedsRedraw, drawing_tool_down  : Boolean;
  HilitePen, HiliteBlock, HilitePath, HilitePoint: Integer;
  drawing_ToolPos: TFloatPoint; // in mm!

procedure UnHilite;
procedure draw_cnc_all;
procedure hilite_to(var x,y: Double);
procedure hilite_center_to(var x,y: Double);
procedure Uncheck_Popups;
procedure SetDrawingToolPosMM(x, y, z: Double);
procedure SetAllPosZupMM(x, y: Double);


implementation

uses grbl_player_main, glscene_view;

{$R *.dfm}

// #############################################################################
// Umrechnungen
// #############################################################################

function x_to_screen(x: Integer):Integer;
// von HPGL-Scaling auf Bitmap-Scale
begin
  x_to_screen:= round(x * Scale * 25) div 1000 + drawing_offset_x;
end;

function y_to_screen(y: Integer):Integer;
// von HPGL-Scaling auf Bitmap-Scale
begin
  y_to_screen:= drawing_offset_y - round(y * Scale * 25) div 1000;
end;

function FloatPointToOffsGraph(pf: TFloatPoint; po: TIntPoint):Tpoint;
// Float-Point in mm auf Grafik umrechnen inkl. Offset
begin
  pf.x:= pf.X + (po.X / c_hpgl_scale);  // pf in mm
  FloatPointToOffsGraph.x:= round(pf.x * Scale) + drawing_offset_x;  // neue Grafik-Kordinaten
  pf.Y:= pf.Y + (po.Y / c_hpgl_scale);  // pf in mm
  FloatPointToOffsGraph.Y:= drawing_offset_Y - round(pf.Y * Scale);  // neue Grafik-Kordinaten
end;

function HPGLPointToOffsGraph(pi, po: TIntPoint):Tpoint;
// HPGL-Point auf Grafik umrechnen inkl. Offset
var pf: TFloatPoint;
begin
  pf.X:= (pi.X + po.X) / c_hpgl_scale;  // pf in mm
  HPGLPointToOffsGraph.x:= round(pf.x * Scale) + drawing_offset_x;  // neue Grafik-Kordinaten
  pf.Y:= (pi.Y + po.Y) / c_hpgl_scale;  // pf in mm
  HPGLPointToOffsGraph.Y:= drawing_offset_Y - round(pf.Y * Scale);  // neue Grafik-Kordinaten
end;

// #############################################################################

procedure UnHilite;
begin
  HilitePen:=0;
  HiliteBlock:=-1;
  HilitePath:=-1;
  HilitePoint:=-1;
end;

procedure search_entry_in_drawing(mx, my: Integer);
// sucht im BlockArray nach passenden Screen-Koordinaten
// (Maus-XY) innerhalb Drawingbox
// Liefert BlockArray-Index mit am besten passenden Eintrag zur�ck
// oder -1 falls nichts gefunden (Klick au�erhalb)
var i, f, p: Integer;
  x1, x2, y1, y2, dx, dy, dxy, old_dxy: Integer;
  my_bounds: Tbounds;
  my_point, my_offset: TintPoint;

begin
  UnHilite;
  old_dxy:= high(old_dxy);

  if length(final_array) < 1 then
    exit;
  // zun�chst Punkt suchen wg. Drills
  for f:= 0 to length(final_array) - 1 do begin // penPathArray
    my_bounds:= final_array[f].bounds; // Bounds im Path #
    my_offset:= job.pens[final_array[f].pen].offset;
    for p:= 0 to length(final_array[f].millings) - 1 do // Milling-# im Block (Childs)
      for i:= 0 to length(final_array[f].millings[p]) - 1 do begin // Milling Path
        my_point:= final_array[f].millings[p,i]; // Point im Milling Path #
        my_offset:= job.pens[final_array[f].pen].offset;

        x1:= x_to_screen(my_point.x + my_offset.x);
        if mx < x1 - 7 then
          continue;

        y1:= y_to_screen(my_point.y + my_offset.y);
        if my > y1 + 7 then
          continue;

        x2:= x_to_screen(my_point.x + my_offset.x);
        if mx > x2 + 7 then
          continue;

        y2:= y_to_screen(my_point.y + my_offset.y);
        if my < y2 - 7 then
          continue
        else begin  // Abstand Maus zum Mittelpunkt
          dx:= mx - (x_to_screen(my_bounds.min.x + my_offset.x)
            + x_to_screen(my_bounds.max.x + my_offset.x)) div 2;
          dy:= my - (y_to_screen(my_bounds.min.y + my_offset.y)
            + x_to_screen(my_bounds.max.y + my_offset.y)) div 2;
          dxy:= round(sqrt(dx*dx + dy*dy));
          if dxy < old_dxy then begin
            HilitePoint:= i;
            HilitePath:= p;
            HiliteBlock:= f;
            HilitePen:= final_array[f].pen;
          end;
        end;
      end;
  end;
  if HilitePoint >= 0 then
    exit;
  // kein Punkt gefunden, ggf. Pfad suchen
  for f:= 0 to length(final_array) - 1 do begin // penPathArray
    my_bounds:= final_array[f].bounds; // Bounds im Path #
    my_offset:= job.pens[final_array[f].pen].offset;

    x1:= x_to_screen(my_bounds.min.x + my_offset.x);
    if mx < x1 - 4 then
      continue;

    y1:= y_to_screen(my_bounds.min.y + my_offset.y);
    if my > y1 + 4 then
      continue;

    x2:= x_to_screen(my_bounds.max.x + my_offset.x);
    if mx > x2 + 4 then
      continue;

    y2:= y_to_screen(my_bounds.max.y + my_offset.y);
    if my < y2 - 4 then
      continue
    else begin  // Abstand Maus zum Mittelpunkt
      dx:= mx - (x_to_screen(my_bounds.min.x + my_offset.x)
        + x_to_screen(my_bounds.max.x + my_offset.x)) div 2;
      dy:= my - (y_to_screen(my_bounds.min.y + my_offset.y)
        + x_to_screen(my_bounds.max.y + my_offset.y)) div 2;
      dxy:= round(sqrt(dx*dx + dy*dy));
      if dxy < old_dxy then begin
        HiliteBlock:= f;
        HilitePen:= final_array[f].pen;
      end;
    end;
  end;
end;

// #############################################################################
// Drawing-Routinen f�r Screen
// #############################################################################


procedure set_drawing_scales;
begin
  drawing_offset_x:= c_center_offs_x + bm_scroll.x;
  drawing_offset_y:= Form2.DrawingBox.Height + bm_scroll.y - c_center_offs_y;
  Scale:= Int(Form2.TrackBarZoom.Position) * 1.0;
end;

procedure add_scroll_offset(var p:Tpoint);
begin
  p.x:= p.x + drawing_offset_x;
  p.y:= drawing_offset_y - p.y;
end;

// #############################################################################

procedure ArrowTo(RC:TCanvas; xa,ya,xe,ye,pb,pl:integer; Fill:boolean);
var
  m,t,sqm : double;
  x1,y1,x2,y2,xs,ys,la : double;
begin
  la:=sqrt(sqr(xe-xa)+sqr(ye-ya));
  if la<0.01 then exit;
  t:=(la-pl)/la;
  xs:=xa+t*(xe-xa);
  if xe<>xa then
    begin
      m:=(ye-ya)/(xe-xa);
      ys:=ya+t*m*(xe-xa);
      if m<>0 then
        begin
          sqm:=sqrt(1+1/sqr(m));
          x1:=xs+pb/sqm;
          y1:=ys-(x1-xs)/m;
          x2:=xs-pb/sqm;
          y2:=ys-(x2-xs)/m;
        end
      else
        begin
          x1:=xs; x2:=xs;
          y1:=ys+pb/1.0;
          y2:=ys-pb/1.0;
        end;
    end
  else
    begin
      xs:=xa;
      ys:=ya+t*(ye-ya);
      x1:=xs-pb/1.0;
      x2:=xs+pb/1.0;
      y1:=ys; y2:=ys;
    end;
  RC.MoveTo(xa,ya);
  RC.LineTo(round(xs),round(ys));
  if Fill then
    begin
      RC.Brush.Color:= RC.Pen.Color;
      RC.Brush.Style:= bsSolid;
      RC.Polygon([Point(xe,ye),Point(round(x1),round(y1)), Point(round(x2),round(y2)),Point(xe,ye)]);
    end
  else
    RC.Polyline([Point(xe,ye),Point(round(x1),round(y1)), Point(round(x2),round(y2)),Point(xe,ye)]);
end;

procedure draw_arrow(p1, p2: Tpoint; arrow_ena, both_ends: Boolean);
var
  pb, pl: Integer;
  pp2: TPoint;

begin
  if not arrow_ena then
    with Form2.DrawingBitmap do begin
      Canvas.moveto(p1.X, p1.Y);
      Canvas.lineto(p2.X, p2.Y);
      exit;
    end;
  pb:= 3;
  pl:= pb * 5;
  pp2.X:= p2.x - (p2.x  - p1.x) div 3;
  pp2.Y:= p2.y - (p2.y  - p1.y) div 3;
  with Form2.DrawingBitmap do begin
    if both_ends then begin
      ArrowTo(Canvas, pp2.X, pp2.Y, p2.X, p2.Y, pb, pl, true);
      ArrowTo(Canvas, pp2.X, pp2.Y, p1.X, p1.Y, pb, pl, true);
    end else begin
      ArrowTo(Canvas, p1.X, p1.Y, pp2.X, pp2.Y, pb, pl, true);
      Canvas.lineto(p2.X, p2.Y);
    end;
  end;
end;


function colorDim(AColor: TColor; luminosity: Integer): TColor;
var
  H, S, L: Word;
begin
  ColorRGBToHLS(AColor, H, L, S);
  Result := ColorHLSToRGB(H, luminosity, S);
end;

procedure update_drawing;
var
  my_rect: TRect;
begin
  with Form2.DrawingBox do begin
    my_rect:= Rect(0, 0, Width, Height);
    Canvas.Draw(0, 0, Form2.DrawingBitmap);
  end;
end;


function get_bm_point(var my_path: Tpath; my_idx: Integer; my_offset: TIntPoint; var pt: TPoint): Boolean;
// Holt einen Punkt und Punkt mit Offset aus BlockArray-Path
// liefert FALSE, wenn Array-Grenze �berschritten
begin
  get_bm_point:= false;
  if my_idx >= length(my_path) then
    exit;
  pt.x:= Round((my_path[my_idx].x+ my_offset.X) * Scale * 25) div 1000;  // neue Kordinaten
  pt.x:= pt.x + drawing_offset_x ;
  pt.y:= Round((my_path[my_idx].y + my_offset.Y) * Scale * 25) div 1000;
  pt.y:= drawing_offset_y - pt.y;
  get_bm_point:= true;
end;

procedure draw_move(p1, p2: TPoint; my_color: Tcolor; enable, force_arrows: Boolean);
// Linie des Millings oder Outlines malen
var
  vlen_ok: Boolean;
  pv: TPoint;
  temp_pen_color, temp_brush_color: Tcolor;
  dx, dy: Double;
begin
  if not Form2.CheckBoxToolpath.Checked then
    exit;
  with Form2.DrawingBitmap do begin
    temp_pen_color:= Canvas.Pen.Color;
    Canvas.Pen.Color:= my_color;
    pv.X:= p1.X - p2.x;
    pv.Y:= p1.Y - p2.Y;
    enable:= enable and Form2.CheckBoxDirections.Checked;
    if enable then
      Canvas.Pen.Style:= psSolid      // psDashDot , psDot
    else
      Canvas.Pen.Style:= psDot;       // psDashDot , psDot
    if enable or force_arrows then begin
      dx:= sqr(pv.X);
      dy:= sqr(pv.Y);
      vlen_ok:= sqrt(dx + dy) > 50;
      temp_brush_color:= Canvas.Brush.Color;
      draw_arrow(p1, p2, vlen_ok, false); // lang genug, Pfeile malen
      Canvas.Brush.Color:= temp_brush_color;
    end;
    Canvas.Pen.Color:= temp_pen_color;
    Canvas.Pen.Style:= psSolid;      // psDashDot , psDot
  end;
end;

procedure draw_toolvec(p1, p2: TPoint; enable, is_hipath: Boolean;
  line_color, fill_color1, fill_color2: Tcolor; radius: Integer);
begin
  with Form2.DrawingBitmap do begin
    Canvas.Pen.Width := 1;
    Canvas.Pen.Color:= line_color;   // ggf. Hilite gesamt, sonst normal
    if is_hipath then
      fill_color2:= fill_color2 or clgray;
    draw_move(p1, p2, fill_color2, enable, false);

    if is_hipath then
      Canvas.brush.Color:= clgray      // Kreisf�llung
    else
      Canvas.brush.Color:= fill_color1;   // Kreisf�llung
    if radius < 3 then
      Canvas.ellipse(p2.x-2, p2.y-2, p2.x+2, p2.y+2)
    else
      Canvas.ellipse(p2.x-radius, p2.y-radius, p2.x+radius, p2.y+radius);

    Canvas.Pen.Mode := pmMerge;
    if radius > 7 then begin
      Canvas.Pen.Color:= line_color;    // Werkzeugweg mit Dicke
      Canvas.moveto(p2.x-5, p2.y);
      Canvas.lineto(p2.x+5, p2.y);
      Canvas.moveto(p2.x, p2.y-5);
      Canvas.lineto(p2.x, p2.y+5);
    end;
    Canvas.Pen.Color:= fill_color1;    // Werkzeugweg mit Dicke
    Canvas.Pen.Width := radius*2 -1;
    Canvas.moveto(p1.x, p1.y);
    Canvas.lineto(p2.x, p2.y);
    Canvas.Pen.Mode := pmCopy;
    Canvas.Pen.Width := 1;
  end;
end;

// #############################################################################
// alle Milling-Pfade oder alle Bohrungen eines Blocks zeichnen
// #############################################################################
procedure set_colors(is_enabled, is_highlited: Boolean; var my_pen_color,
                 my_line_color, my_fill_color1, my_fill_color2: Tcolor);

const
  c_disabled: Tcolor = $00404040;

begin
  if is_enabled then begin
    if is_highlited then
        my_line_color:= clWhite
      else
        my_line_color:= my_pen_color;
  end else begin
    my_pen_color:= c_disabled;
    if is_highlited then
      my_line_color:= clsilver
    else
      my_line_color:= c_disabled;
  end;
  my_fill_color1:= colorDim(my_pen_color, 25);
  my_fill_color2:= colorDim(my_pen_color, 50);
end;

procedure draw_final_entry(my_final_entry: Tfinal; is_highlited: Boolean; var last_point: TPoint);
// Eintrag aus finalem Array zeichnen einschlie�lich mill-Pfaden
// liefert zuletzt gezeichnete Screen-Koordinaten zur�ck f�r n�chsten Entry

var i, p: Integer;
  p1, p2, po1: Tpoint;
  pmin, pmax: TPoint;
  pf: TpointFloat;
  my_pathlen, my_pathcount, my_radius: Integer;
  my_pen_color, my_line_color, my_fill_color1, my_fill_color2, my_fill_color3: Tcolor;
  vlen_ok: boolean;
  has_multiple_millings: Boolean;
  my_offset: TIntPoint;

begin
  if length(my_final_entry.outlines) = 0 then
    exit;
  my_pathcount:= length(my_final_entry.millings);
  has_multiple_millings:= my_pathcount > 1;
  my_radius:= round(job.pens[my_final_entry.pen].tipdia * Scale) div 2 + 1;
  if my_radius < 1 then
    my_radius:= 1;
  my_offset:= job.pens[my_final_entry.pen].offset;
  if (my_final_entry.shape = drillhole) or
     (not has_multiple_millings) or
     (not my_final_entry.enable) or
     (my_final_entry.out_of_work) then begin
   // Default-Farben der Drill-Vektoren und falls es nur einen Milling Path gibt
    my_pen_color:= job.pens[my_final_entry.pen].Color;
    set_colors( (my_final_entry.enable and not my_final_entry.out_of_work),
      is_highlited, my_pen_color, my_line_color, my_fill_color1, my_fill_color2);
    my_fill_color3:= colorDim(my_pen_color, 80);
  end;


  with Form2.DrawingBitmap do begin

// -----------------------------------------------------------------------------
// Bohrungen des milling-Pfads malen falls Drill-Shape
// -----------------------------------------------------------------------------

    if my_final_entry.shape = drillhole then begin
      Canvas.Pen.Width := 1;
      Canvas.Pen.Mode:= pmCopy;
      if my_pathcount > 0 then begin
        my_pathlen:= length(my_final_entry.millings[0]);
        if not get_bm_point(my_final_entry.millings[0], 0, my_offset, po1) then
          exit; // erster Punkt in po1
        p1:= po1;
        for i:= 0 to my_pathlen - 1 do begin
          if not get_bm_point(my_final_entry.millings[0], i, my_offset, p2) then
            break;
          Canvas.Pen.Mode := pmMerge;
          if my_final_entry.enable then
            draw_move(p1, p2, my_fill_color2, true, false);
          Canvas.Pen.Mode := pmCopy;
          draw_toolvec(p2, p2, my_final_entry.enable, is_highlited,
                my_line_color, my_fill_color2, my_fill_color3, my_radius);
          if is_highlited and (HilitePath = 0) and (HilitePoint = i) then begin
            Canvas.Pen.Width := 2;
            Canvas.Pen.Color:= clred;
            Canvas.ellipse(p2.x-8, p2.y-8, p2.x+8, p2.y+8);
            Canvas.Pen.Width := 3;
            Canvas.Pen.Color:= clWhite;
            Canvas.ellipse(p2.x-5, p2.y-5, p2.x+5, p2.y+5);
            Canvas.Pen.Width := 1;
          end;
          p1:= p2;
        end;
        if my_final_entry.enable then begin
//          draw_move(last_point, po1, clgray, true, false); // Seek-Linie zum ersten Punkt
          last_point:= p2;                          // neuer letzter Punkt
        end;
      end;
      exit;  // keine weitere Aktion erforderlich
    end;

// -----------------------------------------------------------------------------
// Werkzeugweg mit Werkzeugdurchmesser malen, ggf. mit Pfeilen
// -----------------------------------------------------------------------------

    if Form2.CheckBoxToolpath.checked then begin
      my_pathcount:= length(my_final_entry.millings);
      if my_pathcount > 0 then begin
        Canvas.Pen.Width := 1;
        Canvas.Pen.Mode:= pmCopy;
        for p:= my_pathcount - 1 downto 0 do begin // innere Child-Pfade zuerst
          my_pathlen:= length(my_final_entry.millings[p]);
          if my_pathlen = 0 then
            continue;
          if has_multiple_millings and my_final_entry.enable then begin
            my_pen_color:= job.pens[my_final_entry.pen].Color;
            set_colors(my_final_entry.milling_enables[p], is_highlited, my_pen_color,
                 my_line_color, my_fill_color1, my_fill_color2);
          end;
          if not get_bm_point(my_final_entry.millings[p], 0, my_offset, p1) then
            break;
          po1:= p1;
          for i:= 0 to my_pathlen - 1 do begin
            if not get_bm_point(my_final_entry.millings[p], i, my_offset, p2) then
              break;
            draw_toolvec(p1, p2, my_final_entry.enable, is_highlited,
              my_line_color, my_fill_color1, my_fill_color2, my_radius);
            p1:= p2;
          end; // for points

          if my_final_entry.closed then begin
          // letzte Verbindung zum 1. Punkt po1
            p2:= po1;
            draw_toolvec(p1, p2, my_final_entry.enable, is_highlited,
              my_line_color, my_fill_color1, my_fill_color2, my_radius);
          end;  // if closed
        end;    // for my_pathcount

        if my_final_entry.enable then begin
          draw_move(last_point, po1, clgray, true, false); // Seek-Linie zum ersten Punkt
          last_point:= p2;                          // neuer letzter Punkt
        end;
      end;
    end;

// -----------------------------------------------------------------------------
// Kontur/Outline malen
// -----------------------------------------------------------------------------

    my_pathcount:= length(my_final_entry.outlines);
    if my_pathcount = 0 then
      exit;
    for p:= my_pathcount - 1 downto 0 do begin // innere Child-Pfade zuerst
      Canvas.Pen.Width := 1;
      Canvas.Pen.Mode:= pmCopy;
      if my_final_entry.enable then
        Canvas.Pen.Style:= psSolid      // psDashDot , psDot
      else
        Canvas.Pen.Style:= psDot;       // psDashDot , psDot
      if has_multiple_millings and my_final_entry.enable then begin
        my_pen_color:= job.pens[my_final_entry.pen].Color;
        if p <= high(my_final_entry.milling_enables) then begin
          set_colors(my_final_entry.milling_enables[p], is_highlited, my_pen_color,
               my_line_color, my_fill_color1, my_fill_color2);
          if my_final_entry.milling_enables[p] then
            Canvas.Pen.Style:= psSolid      // psDashDot , psDot
          else
            Canvas.Pen.Style:= psDot;       // psDashDot , psDot
        end;
      end;
      Canvas.Pen.Color:= my_line_color;  // Linienfarbe
      Canvas.brush.Color:= colorDim(my_line_color, 90);
      my_pathlen:= length(my_final_entry.outlines[p]);
      if my_pathlen = 0 then
        continue;
      get_bm_point(my_final_entry.outlines[p], 0, my_offset, po1);
      Canvas.moveto(po1.x, po1.y);        // zum ersten Punkt
      for i:= 1 to my_pathlen - 1 do begin
        if not get_bm_point(my_final_entry.outlines[p], i, my_offset, p1) then
          break;
        if is_highlited and (HilitePath = p) then begin
          if HilitePoint = i then begin
            Canvas.Pen.Width := 2;
            Canvas.Pen.Color:= clred;
            Canvas.ellipse(p1.x-8, p1.y-8, p1.x+8, p1.y+8);
            Canvas.Pen.Width := 3;
            Canvas.Pen.Color:= clWhite;
            Canvas.ellipse(p1.x-5, p1.y-5, p1.x+5, p1.y+5);
          end;
          Canvas.Pen.Color:= clWhite;
          Canvas.Pen.Width := 1;
        end;
        Canvas.lineto(p1.x, p1.y);
      end;
      if my_final_entry.closed then begin
        Canvas.lineto(po1.x, po1.y);        // zur�ck zum ersten Punkt
      end;
    end;
    Canvas.Pen.Style:= psSolid;     // psDashDot , psDot

// -----------------------------------------------------------------------------
// Dimensionspfeile zeichnen
// -----------------------------------------------------------------------------

    if Form2.CheckBoxDimensions.Checked and my_final_entry.enable then begin
      Canvas.Pen.Color:= my_fill_color1 or $00404040;  // Linienfarbe
      Canvas.Brush.Color:= Canvas.Pen.Color;
      Canvas.Font.Color:= clwhite;  // Zeichenfarbe
      pmin:= HPGLPointToOffsGraph(my_final_entry.bounds.min, my_offset);
      pmax:= HPGLPointToOffsGraph(my_final_entry.bounds.max, my_offset);
      p1.x:= pmin.x;
      p1.y:= (pmin.y + pmax.y) div 2;
      p2.x:= pmax.x;
      p2.y:= p1.y;
      vlen_ok:= abs(p2.x - p1.x) > 100;
      Canvas.font.Orientation:= 0;
      if vlen_ok then begin           // X-Vektorl�nge in mm anzeigen
        draw_arrow(p1, p2, true, true);
        pf.x:= (my_final_entry.bounds.max.x - my_final_entry.bounds.min.x) / 40;
        p1.x:= (pmax.x + pmin.x) div 2;
        Canvas.TextOut(p1.x+12, p1.y-7, FormatFloat('0.0', abs(pf.x)) + ' mm');
      end;
      p1.x:= (pmin.x + pmax.x) div 2;
      p1.y:= pmin.y;
      p2.x:= p1.x;
      p2.y:= pmax.y;
      vlen_ok:= abs(p2.y - p1.y) > 100;
      Canvas.font.Orientation:= 900;
      if vlen_ok then begin           // X-Vektorl�nge in mm anzeigen
        draw_arrow(p1, p2, true, true);
        pf.y:= (my_final_entry.bounds.max.y - my_final_entry.bounds.min.y) / 40;
        p1.y:= (pmax.y + pmin.y) div 2;
        Canvas.TextOut(p1.X-7, p1.y-10, FormatFloat('0.0', abs(pf.y)) + ' mm');
      end;
      Canvas.font.Orientation:= 0;
    end;

  end;
end;

// #############################################################################

procedure draw_tool;

var
  po1: Tpoint;

begin
  po1 := FloatPointToOffsGraph(drawing_ToolPos, ZeroPoint);

  with Form2.DrawingBitmap do begin
    // Cursorlinien zeichnen
    Canvas.Pen.Color:= clgray;
    Canvas.Pen.Mode:= pmMerge;
    Canvas.Brush.Color:= clnone;
    Canvas.Pen.Width := 1;
    Canvas.Pen.Style:= psDot;     // psDashDot , psDot
    Canvas.moveto(po1.x, Height);
    Canvas.lineto(po1.x, 0);
    Canvas.moveto(0, po1.y);
    Canvas.lineto(Width, po1.y);
    Canvas.Pen.Style:= psSolid;
    Canvas.Pen.Mode:= pmCopy;

    Canvas.Brush.Color:= clsilver;
    Canvas.font.Color:= clblack;
    Canvas.TextOut(po1.x-13,po1.y-21, 'TOOL');

    Canvas.Pen.Color:= clgray;
    if drawing_tool_down then
      Canvas.Brush.Color:= clwhite
    else
      Canvas.Brush.Color:= clnone;
    Canvas.Pen.Width := 2;
    Canvas.Ellipse(po1.x-6,po1.y-6,po1.x+6,po1.y+6);
    Canvas.Brush.Color:= clnone;

    Canvas.Pen.Color:= clred;
    po1.x:= po1.x + round(job.cam_x * scale);
    po1.y:= po1.y - round(job.cam_y * scale);
    Canvas.Ellipse(po1.x-6,po1.y-6,po1.x+6,po1.y+6);
    Canvas.Brush.Color:= clred;
    Canvas.TextOut(po1.x-11,po1.y-21, 'CAM');
    Canvas.Pen.Width := 1;
    Canvas.Brush.Color:= clnone;
    Canvas.Pen.Color:= clgray;
  end;
end;

// #############################################################################

procedure draw_grid(my_bitmap: TBitmap);
var p1, po1, pmax: Tpoint;
  my_delta, my_ruler: Integer;
  my_div, my_subdiv, my_text_x: Integer;
begin
  with my_bitmap do begin
    Canvas.Brush.Style := bsClear;
    Canvas.Brush.Color:= $00101010;
    Canvas.FillRect(rect(0,0, Width, Height));
    Canvas.Pen.mode:= pmCopy;
    Canvas.Pen.Width:= 1;
    Canvas.font.color:= clgray;

    // vertikale Linien ab Offset
    po1.X:= 0;
    po1.Y:= 0;
    add_scroll_offset(po1);
    p1:= po1;

    pmax.X:= round(job.partsize_x * Scale);
    pmax.Y:= round(job.partsize_y * Scale);
    add_scroll_offset(pmax);

    if Scale > 4 then begin
      my_div:= 10;
      my_subdiv:= 1;
    end else
    if Scale > 1 then begin
      my_div:= 20;
      my_subdiv:= 5;
    end else begin
      my_div:= 50;
      my_subdiv:= 10;
    end;
    my_delta:= round(my_subdiv * Scale);
    my_ruler:= 0;
    // vertikale Linien bis Offset
    repeat
      p1.X:= p1.X + my_delta;
      my_ruler:= my_ruler + my_subdiv;
      if (my_ruler mod my_div) = 0 then begin
        Canvas.Pen.Color:= $00303030;
        Canvas.moveto(p1.X, p1.Y);
        Canvas.lineto(p1.X, pmax.y);
        my_text_x:= 6; // Center Text
        if my_ruler >= 100 then
          my_text_x:= 9;
        if my_ruler >= 1000 then
          my_text_x:= 12;
        Canvas.TextOut(p1.X-my_text_x, p1.Y+2, IntToSTr(my_ruler));
      end else begin
        Canvas.Pen.Color:= $00202020;
        Canvas.moveto(p1.X, p1.Y);
        Canvas.lineto(p1.X, pmax.y);
      end;
    until (p1.X > width) or (p1.X >= pmax.X);
    // horizontale Linien bis Offset
    p1:= po1;
    my_ruler:= 0;
    repeat
      p1.Y:= p1.Y - my_delta;
      my_ruler:= my_ruler + my_subdiv;
      if (my_ruler mod my_div) = 0 then begin
        Canvas.Pen.Color:= $00303030;
        Canvas.Pen.mode:= pmCopy;
        Canvas.moveto(p1.X, p1.Y);
        Canvas.lineto(pmax.X, p1.Y);
        my_text_x:= 14;
        if my_ruler >= 100 then
          my_text_x:= 20;
        if my_ruler >= 1000 then
          my_text_x:= 26;
        Canvas.TextOut(p1.X-my_text_x, p1.Y-7, IntToSTr(my_ruler));
      end else begin
        Canvas.Pen.Color:= $00202020;
        Canvas.moveto(p1.X, p1.Y);
        Canvas.lineto(pmax.X, p1.Y);
      end;
    until (p1.Y < 0) or (p1.Y - pmax.Y <= 0);
  end;
end;

procedure draw_cnc_all;
var
  j: Integer;
  po1, po2, pmax: Tpoint;
begin
  if not Form1.ShowDrawing1.Checked then
    exit;
  set_drawing_scales;
  draw_grid(Form2.DrawingBitmap);

  with Form2.DrawingBitmap do begin
    po1.x := 0;
    po1.y := 0;
    add_scroll_offset(po1);
    po2:= po1;
    Canvas.Pen.Color:= clwhite;
    if length(final_Array) > 0 then
      for j:= 0 to length(final_Array) - 1 do begin
        draw_final_entry(final_Array[j], HiliteBlock = j, po1);
//       Application.ProcessMessages;     // sehr langsam!
      end;
    draw_move(po1, po2, clgray, true, false);

    Canvas.Pen.Color:= clgray;

    draw_tool;

    // Null-Linien zeichnen
    pmax.X:= round(job.partsize_x * Scale);
    pmax.Y:= round(job.partsize_y * Scale);
    add_scroll_offset(pmax);

    po1.x := 0;
    po1.y := 0;
    add_scroll_offset(po1);

    Canvas.Pen.Mode:= pmCopy;
    Canvas.Brush.Color:= clgray;
    Canvas.font.Color:= clblack;
    Canvas.TextOut(po1.x-11,po1.y+8, 'NULL');
    Canvas.Pen.Color:= clgray;
    Canvas.Brush.Color:= clnone;

    Canvas.Pen.Width := 1;
    Canvas.moveto(po1.x, po1.y);
    Canvas.lineto(po1.x, po1.y);
    Canvas.lineto(pmax.X, po1.y);
    Canvas.lineto(pmax.X, pmax.y);
    Canvas.lineto(po1.X, pmax.y);
    Canvas.lineto(po1.x, po1.y);
    if (HiliteBlock < 0) then
      Canvas.Pen.Width := 2;
    Canvas.Ellipse(po1.x-6,po1.y-6,po1.x+6,po1.y+6);
  end;
  if not fActivated then
    update_drawing;
end;

// #############################################################################
// ############################ DRAWING FORM ###################################
// #############################################################################


procedure TForm2.FormCreate(Sender: TObject);
var
  grbl_ini:TRegistry;
begin
  grbl_ini:= TRegistry.Create;
  try
    grbl_ini.RootKey := HKEY_CURRENT_USER;
    grbl_ini.OpenKey('SOFTWARE\Make\GRBlize\'+c_VerStr,true);
    if grbl_ini.ValueExists('DrawingFormTop') then
      Top:= grbl_ini.ReadInteger('DrawingFormTop');
    if grbl_ini.ValueExists('DrawingFormLeft') then
      Left:= grbl_ini.ReadInteger('DrawingFormLeft');
    if grbl_ini.ValueExists('DrawingFormWidth') then
      Width:= grbl_ini.ReadInteger('DrawingFormWidth');
    if grbl_ini.ValueExists('DrawingFormHeight') then
      Height:= grbl_ini.ReadInteger('DrawingFormHeight');
    if grbl_ini.ValueExists('DrawShowDirections') then
      CheckBoxDirections.Checked:= grbl_ini.ReadBool('DrawShowDirections');
    if grbl_ini.ValueExists('DrawShowDimensions') then
      CheckBoxDimensions.Checked:= grbl_ini.ReadBool('DrawShowDimensions');
    if grbl_ini.ValueExists('DrawShowToolpath') then
      CheckBoxToolPath.Checked:= grbl_ini.ReadBool('DrawShowToolpath');
  finally
    grbl_ini.Free;
  end;
  if Top > Screen.Height-50 then
    Top:= round((Screen.Height-Height)/2);
  if Left > Screen.Width-50 then
    Left:= round((Screen.Width-Width)/2);

  DrawingBitmap:= TBitmap.create;
  DrawingBitmap.Height:= 800;
  DrawingBitmap.Width:= 1200;

  bm_scroll.x:= 0;
  bm_scroll.y:= ClientHeight - DrawingBox.Height;
// if form_visible then
//    show;
end;

procedure TForm2.FormClose(Sender: TObject; var Action: TCloseAction);
var
  grbl_ini:TRegistry;
begin
  grbl_ini:= TRegistry.Create;
  try
    grbl_ini.RootKey := HKEY_CURRENT_USER;
    grbl_ini.OpenKey('SOFTWARE\Make\GRBlize\'+c_VerStr, true);
    grbl_ini.WriteInteger('DrawingFormTop',Top);
    grbl_ini.WriteInteger('DrawingFormLeft',Left);
    grbl_ini.WriteInteger('DrawingFormWidth',Width);
    grbl_ini.WriteInteger('DrawingFormHeight',Height);
    grbl_ini.WriteBool('DrawShowDirections', Form2.CheckBoxDirections.Checked);
    grbl_ini.WriteBool('DrawShowDimensions', Form2.CheckBoxDimensions.Checked);
    grbl_ini.WriteBool('DrawShowToolpath', Form2.CheckBoxToolPath.Checked);
  finally
    grbl_ini.Free;
  end;

  Form1.WindowMenu1.Items[0].Checked:= false;
end;

procedure TForm2.FormActivate(Sender: TObject);
begin
  draw_cnc_all;
end;

// #############################################################################
// #############################################################################

procedure hilite_center_to(var x, y: Double);
// setzt drawing_ToolPos-Koordinaten in Plotter-Units
var ZeroOfs, pt: TIntpoint;
begin
  if (HiliteBlock >= 0) then begin
    pt:= final_Array[HiliteBlock].bounds.mid;
    ZeroOfs:= job.pens[final_Array[HiliteBlock].pen].offset;
    pt.X := pt.X + ZeroOfs.X;
    pt.Y := pt.Y + ZeroOfs.Y;
    x:= pt.X / c_hpgl_scale;
    y:= pt.Y / c_hpgl_scale;
  end;
end;

procedure hilite_to(var x,y: Double);
// setzt drawing_ToolPos-Koordinaten in Plotter-Units
var ZeroOfs, pt: TIntpoint;
begin
  if (HilitePoint >= 0) then begin
    pt:= final_Array[HiliteBlock].millings[HilitePath, HilitePoint];
    ZeroOfs:= job.pens[final_Array[HiliteBlock].pen].offset;
    pt.X := pt.X + ZeroOfs.X;
    pt.Y := pt.Y + ZeroOfs.Y;
    x:= pt.X / c_hpgl_scale;
    y:= pt.Y / c_hpgl_scale;
  end else if (HiliteBlock >= 0) then begin
    pt:= final_Array[HiliteBlock].bounds.min;
    ZeroOfs:= job.pens[final_Array[HiliteBlock].pen].offset;
    pt.X := pt.X + ZeroOfs.X;
    pt.Y := pt.Y + ZeroOfs.Y;
    x:= pt.X / c_hpgl_scale;
    y:= pt.Y / c_hpgl_scale;
  end;
end;

// #############################################################################
// #############################################################################


procedure Uncheck_PopupPoint;
var i: Integer;
begin
  for i:= 1 to Form2.PopupMenuPoint.Items.Count-1 do
    Form2.PopupMenuPoint.Items[i].Checked:= false;
end;

procedure Uncheck_PopupObject;
var i: Integer;
begin
  for i:= 1 to Form2.PopupMenuObject.Items.Count-1 do
    Form2.PopupMenuObject.Items[i].Checked:= false;
end;

procedure Uncheck_Popups;
begin
  Uncheck_PopupPoint;
  Uncheck_PopupObject;
end;

procedure TForm2.DrawingBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
// Grafik verschieben
begin
  if (ssLeft in Shift) then begin
    bm_scroll.x:= bm_scroll.x + X - mouse_start.x;
    bm_scroll.y:= bm_scroll.y + Y - mouse_start.y;
    mouse_start.x:= X;
    mouse_start.y:= Y;
    set_drawing_scales;
    draw_grid(Form2.DrawingBitmap);
    NeedsRedraw:= true;
    Application.ProcessMessages;
  end;
end;

procedure TForm2.DrawingBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
// Select/Move mit linker Maustaste
// Popup-Menu mit rechter Maustaste
var pt: TPoint;
  move_enabled: boolean;
begin
  if (ssLeft in Shift) then begin
    SetCursor(Screen.Cursors[crSize]);
    mouse_start.x:= X;
    mouse_start.y:= Y;
    search_entry_in_drawing(x,y);
    NeedsRedraw:= true;
  end;
  if (ssRight in Shift) then begin
    // if HiliteBlock < 0 then
    //  search_entry_in_drawing(x,y);
    // draw_cnc_all;
    pt.x := X + 15;
    pt.y := Y - 10;
    pt := DrawingBox.ClientToScreen(pt);
    move_enabled:= WorkZeroXdone and WorkZeroYdone;
    pu_MoveCamToCenter.Enabled:= move_enabled;
    pu_MoveCenter1.Enabled:= move_enabled;
    pu_moveZero2.Enabled:= move_enabled;
    pu_moveCamToZero2.Enabled:= move_enabled;
    pu_moveToPoint.Enabled:= move_enabled;
    pu_moveCamToPoint.Enabled:= move_enabled;

    if (HiliteBlock >= 0) then begin
      uncheck_Popups;
      if final_array[HiliteBlock].closed then begin
        MenuItem4.Enabled:= true;
        MenuItem6.Enabled:= true;
      end else begin
        MenuItem4.Enabled:= false;
        MenuItem6.Enabled:= false;
      end;
      if (HilitePath >= 0) then begin
        if length(final_array[HiliteBlock].millings) > 1 then
          PopupMenuPoint.Items[0].Checked:= final_array[HiliteBlock].milling_enables[HilitePath]
        else begin
          PopupMenuPoint.Items[0].Checked:= final_array[HiliteBlock].enable;
        end;
      end;
      PopupMenuObject.Items[0].Checked:= final_array[HiliteBlock].enable;
      PopupMenuPoint.Items[ord(final_array[HiliteBlock].shape)+2].Checked:= true;
      PopupMenuObject.Items[ord(final_array[HiliteBlock].shape)+2].Checked:= true;
      if HilitePoint >= 0 then
        PopupMenuPoint.Popup(pt.X, pt.Y)
      else
        PopupMenuObject.Popup(pt.X, pt.Y);
    end else
      PopupMenuPart.Popup(pt.X, pt.Y);
  end;
end;

procedure TForm2.DrawingBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
//  draw_cnc_all;
  Cursor := crCross;
  NeedsRedraw:= true;
  TrackBarZoom.SetFocus;
end;

// #############################################################################
// #############################################################################


procedure TForm2.BtnZoomResetClick(Sender: TObject);
// Center Scrollbars
begin
  TrackBarZoom.Position:= 4;
  bm_scroll.x:= 0;
  bm_scroll.y:= ClientHeight - DrawingBox.Height;
  NeedsRedraw:= true;
end;

procedure TForm2.ScrollBarChange(Sender: TObject);
begin
  NeedsRedraw:= true;
end;

procedure TForm2.CheckBoxDimensionsClick(Sender: TObject);
begin
  NeedsRedraw:= true;
end;

procedure TForm2.CheckBoxDirectionsClick(Sender: TObject);
begin
  NeedsRedraw:= true;
end;




// #############################################################################
// #############################################################################

procedure TForm2.pu_PathEnabledClick(Sender: TObject);
begin
  if (HiliteBlock >= 0) then begin
    PopupMenuPoint.Items[0].Checked:= not PopupMenuPoint.Items[0].Checked;
    // Block hat mehrere Pfade. nur einzelnen Pfad behandeln
    if (HilitePath >= 0) then
      final_array[HiliteBlock].milling_enables[HilitePath]:= PopupMenuPoint.Items[0].Checked;
    if length(final_array[HiliteBlock].millings) = 1 then
      final_array[HiliteBlock].enable:= PopupMenuPoint.Items[0].Checked;
    final_array[HiliteBlock].enable:= is_any_milling_enabled(final_array[HiliteBlock]);
    ListBlocks;
    NeedsRedraw:= true;
  end;
end;


procedure TForm2.pu_ObjectEnabledClick(Sender: TObject);
begin
  if (HiliteBlock >= 0) then begin
    PopupMenuObject.Items[0].Checked:= not PopupMenuObject.Items[0].Checked;
    final_array[HiliteBlock].enable:= PopupMenuObject.Items[0].Checked;
    ListBlocks;
    NeedsRedraw:= true;
  end;
end;


procedure TForm2.pu_RadioClick(Sender: TObject);
var my_idx: Integer;
  my_shape: Tshape;
begin
  Uncheck_Popups;
  if (HiliteBlock >= 0) then begin
    my_idx:= TMenuItem(Sender).MenuIndex;
    PopupMenuPoint.Items[my_idx].Checked:= true;
    PopupMenuObject.Items[my_idx].Checked:= true;
    my_shape:= Tshape(my_idx-2);
    final_array[HiliteBlock].shape:= Tshape(my_idx-2);
    if (my_shape = inside) or  (my_shape = pocket) then
      final_array[HiliteBlock].closed:= true
    else
      final_array[HiliteBlock].closed:= final_array[HiliteBlock].was_closed;
    item_change(HiliteBlock);
    NeedsRedraw:= true;
    GLSneedsRedrawTimeout:= 2;
    GLSneedsATCupdateTimeout:= 3;
  end;
end;


// #############################################################################
// #############################################################################


procedure SetDrawingToolPosMM(x, y, z: Double);
begin
  drawing_ToolPos.X:= x;
  drawing_ToolPos.Y:= y;
  drawing_tool_down:= z <= 0;
end;

procedure SetAllPosZupMM(x, y: Double);
begin
  drawing_ToolPos.X:= x;
  drawing_ToolPos.Y:= y;
  drawing_tool_down:= false;
end;

// #############################################################################

procedure TForm2.pu_toolisAtPartZeroClick(Sender: TObject);
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Manual Work/part Y zero');

  grbl_offsXY(0, 0);
  SendListToGrbl;

  WorkZero.X:= grbl_mpos.X;
  Jog.X:= WorkZero.X;
  WorkZero.Y:= grbl_mpos.Y;
  Jog.Y:= WorkZero.Y;
  WorkZeroXdone:= true;
  WorkZeroYdone:= true;
  NeedsRedraw:= true;
end;

procedure TForm2.pu_toolisatpointClick(Sender: TObject);
var x,y: Double;
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Offset to point');
  hilite_to(x,y);

  grbl_offsXY(x, y);
  SendListToGrbl;

  WorkZero.X:= grbl_mpos.X - x;
  Jog.X:= WorkZero.X;
  WorkZero.Y:= grbl_mpos.Y - y;
  Jog.Y:= WorkZero.Y;
  WorkZeroXdone:= true;
  WorkZeroYdone:= true;
  NeedsRedraw:= true;
end;

procedure TForm2.pu_toolIsAtCenterClick(Sender: TObject);
var x,y: Double;
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Offset tool to center');
  hilite_center_to(x,y);

  grbl_offsXY(x, y);
  SendListToGrbl;

  WorkZero.X:= grbl_mpos.X - x;
  Jog.X:= WorkZero.X;
  WorkZero.Y:= grbl_mpos.Y - y;
  Jog.Y:= WorkZero.Y;
  WorkZeroXdone:= true;
  WorkZeroYdone:= true;
  NeedsRedraw:= true;
end;

// #############################################################################

procedure TForm2.pu_camIsAtPartZeroClick(Sender: TObject);
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Offset cam to part zero');

  grbl_offsXY(-job.cam_x, -job.cam_y);
  SendListToGrbl;

  WorkZero.X:= grbl_mpos.X + job.cam_x;
  Jog.X:= WorkZero.X;
  WorkZero.Y:= grbl_mpos.Y + job.cam_x;
  Jog.Y:= WorkZero.Y;
  WorkZeroXdone:= true;
  WorkZeroYdone:= true;
  NeedsRedraw:= true;
end;

procedure TForm2.pu_camIsAtPointClick(Sender: TObject);
var x,y: Double;
begin
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Offset cam to point');
  hilite_to(x,y);

  x:= x - job.cam_x;
  y:= y - job.cam_y;
  grbl_offsXY(x, y);
  SendListToGrbl;

  WorkZero.X:= grbl_mpos.X - x;
  Jog.X:= WorkZero.X;
  WorkZero.Y:= grbl_mpos.Y - y;
  Jog.Y:= WorkZero.Y;
  WorkZeroXdone:= true;
  WorkZeroYdone:= true;
  NeedsRedraw:= true;
end;

procedure TForm2.pu_camIsAtCenterClick(Sender: TObject);
var x,y: Double;
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Offset cam to center');
  hilite_center_to(x,y);

  x:= x - job.cam_x;
  y:= y - job.cam_y;
  grbl_offsXY(x, y);
  SendListToGrbl;

  WorkZero.X:= grbl_mpos.X - x;
  Jog.X:= WorkZero.X;
  WorkZero.Y:= grbl_mpos.Y - y;
  Jog.Y:= WorkZero.Y;
  WorkZeroXdone:= true;
  WorkZeroYdone:= true;
  NeedsRedraw:= true;
end;

// #############################################################################

procedure TForm2.pu_moveToolToPartZeroClick(Sender: TObject);
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move tool to part zero');

  if WorkZeroXdone and WorkZeroYdone then begin
    grbl_moveZ(0, true);  // move Z up
    grbl_moveXY(0, 0, false);
    if WorkZeroAllDone then begin
      grbl_moveZ(job.z_penlift, false);
    end else begin
      Form1.Memo1.lines.add('WARNING: Z Zero not set!');
      PlaySound('SYSTEMHAND', 0, SND_ASYNC);
    end;
    SendListToGrbl;
  end else begin
    Form1.Memo1.lines.add('WARNING: X,Y Zero not set!');
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
  end;
end;

procedure TForm2.pu_moveToolToPointClick(Sender: TObject);
var x,y: Double;
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move tool to point');
  hilite_to(x, y);

  if WorkZeroXdone and WorkZeroYdone then begin
    grbl_moveZ(0, true);  // move Z up
    grbl_moveXY(x, y, false);
    if WorkZeroAllDone then begin
      grbl_moveZ(job.z_penlift, false);
    end else begin
      Form1.Memo1.lines.add('WARNING: Z Zero not set!');
      PlaySound('SYSTEMHAND', 0, SND_ASYNC);
    end;
    SendListToGrbl;
  end else begin
    Form1.Memo1.lines.add('WARNING: X,Y Zero not set!');
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
  end;
end;

procedure TForm2.pu_moveToolToCenterClick(Sender: TObject);
var x,y: Double;
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move tool to center');
  hilite_center_to(x,y);

  if WorkZeroXdone and WorkZeroYdone then begin
    grbl_moveZ(0, true);  // move Z up
    grbl_moveXY(x, y, false);
    if WorkZeroAllDone then begin
      grbl_moveZ(job.z_penlift, false);
    end else begin
      Form1.Memo1.lines.add('WARNING: Z Zero not set!');
      PlaySound('SYSTEMHAND', 0, SND_ASYNC);
    end;
    SendListToGrbl;
  end else begin
    Form1.Memo1.lines.add('WARNING: X,Y Zero not set!');
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
  end;
end;

// #############################################################################

procedure TForm2.pu_moveCamToPartZeroClick(Sender: TObject);
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move cam to part zero');

  if WorkZeroXdone and WorkZeroYdone then begin
    grbl_moveZ(0, true);  // move Z up absolute
    grbl_moveXY(-job.cam_x,-job.cam_y, false);
    grbl_moveZ(job.cam_z_abs, true);
    SendListToGrbl;
  end else begin
    Form1.Memo1.lines.add('WARNING: X,Y Zero not set!');
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
  end;
end;

procedure TForm2.pu_moveCamToPointClick(Sender: TObject);
var x,y: Double;
begin
  WaitForIdle;
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move cam to point');
  hilite_to(x,y);
  x:= x - job.cam_x;
  y:= y - job.cam_y;

  if WorkZeroXdone and WorkZeroYdone then begin
    grbl_moveZ(0, true);  // move Z up
    grbl_moveXY(x, y, false);
    grbl_moveZ(job.cam_z_abs, true);
    SendListToGrbl;
  end else begin
    Form1.Memo1.lines.add('WARNING: X,Y Zero not set!');
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
  end;
end;

procedure TForm2.pu_moveCamToCenterClick(Sender: TObject);
var x,y: Double;
begin
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move cam to center');
  hilite_center_to(x, y);
  x:= x - job.cam_x;
  y:= y - job.cam_y;

  if WorkZeroXdone and WorkZeroYdone then begin
    grbl_moveZ(0, true);  // move Z up
    grbl_moveXY(x, y, false);
    grbl_moveZ(job.cam_z_abs, true);
    SendListToGrbl;
  end else begin
    Form1.Memo1.lines.add('WARNING: X,Y Zero not set!');
    PlaySound('SYSTEMHAND', 0, SND_ASYNC);
  end;
end;

// #############################################################################
// #############################################################################

procedure TForm2.TrackBarZoomChange(Sender: TObject);
begin
  NeedsRedraw:= true;
end;


procedure TForm2.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  p: TPoint;
  pos, diff, max: Integer;
begin
  Handled:= true;
  p := DrawingBox.ScreenToClient(MousePos);
  p.x:= (p.X - drawing_offset_x);
  p.y:= (p.y - drawing_offset_y);
  pos:= TrackBarZoom.Position;
  max:= TrackBarZoom.Max;
  diff:= pos div 4;
  if diff = 0 then
    diff:= 1;  //  diff:=  abs(WheelDelta div 120);

  if WheelDelta < 0 then begin
// Mittelpunkt neu setzen anhand Maus-Posititon
    if pos < max then begin
      if (diff + pos) > max then
        diff:= max - pos;
      TrackBarZoom.Position:= pos + diff;
      bm_scroll.x:= bm_scroll.x - round(diff * p.x / Scale);
      bm_scroll.y:= bm_scroll.y - round(diff * p.y / Scale);
     end;
  end else begin
    if pos > diff then begin
      TrackBarZoom.Position:= pos - diff;
      bm_scroll.x:= bm_scroll.x + round(diff * p.x / Scale);
      bm_scroll.y:= bm_scroll.y + round(diff * p.y / Scale);
    end;
  end;
  TrackBarZoom.Perform(CN_HSCROLL, SB_ENDSCROLL, 0);
  NeedsRedraw:= true;
end;

procedure TForm2.FormResize(Sender: TObject);
begin
  NeedsRedraw:= true;
end;

procedure TForm2.FormPaint(Sender: TObject);
begin
  NeedsRedraw:= true;
end;

end.

