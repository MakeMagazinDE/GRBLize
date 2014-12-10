unit glscene_view;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  GLCadencer, GLScene, GLExtrusion, VectorGeometry, ExtCtrls, Registry, import_files,
  drawing_window,Clipper, GLMultiPolygon, GLWin32Viewer, GLGeomObjects, GLObjects, GLGraph,
  GLMisc, GLTexture, GLOutlineShader, GLSpaceText;

type
  TForm4 = class(TForm)
    GLSceneViewer1: TGLSceneViewer;
    GLScene1: TGLScene;
    GLCube1: TGLCube;
    GLLightSource1: TGLLightSource;
    GLCamera1: TGLCamera;
    GLExtrusionSolid1: TGLExtrusionSolid;
    GLArrowLineZ: TGLArrowLine;
    Timer1: TTimer;
    GLArrowLineY: TGLArrowLine;
    GLArrowLineX: TGLArrowLine;
    GLSpaceText1: TGLSpaceText;
    GLXYZGrid1: TGLXYZGrid;
    GLDummyCube1: TGLDummyCube;
    GLDummyCube2: TGLDummyCube;
    GLCylinder1: TGLCylinder;
    GLAnnulus1: TGLAnnulus;
    GLCylinder2: TGLCylinder;
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure GLSceneViewer1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Timer1Timer(Sender: TObject);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure GLSceneViewer1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GLSceneViewer1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormRefresh(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form4: TForm4;
  mx, my, mxo, myo, dx, dy, sx: Integer;
  auto_roll: Boolean;

implementation

uses grbl_player_main;

{$R *.dfm}

procedure TForm4.FormCreate(Sender: TObject);
var
  grbl_ini:TRegistryIniFile;
  form_visible: boolean;
begin
  grbl_ini:=TRegistryIniFile.Create('GRBLize');
  try
    Top:= grbl_ini.ReadInteger('SceneForm','Top',110);
    Left:= grbl_ini.ReadInteger('SceneForm','Left',110);
    form_visible:= grbl_ini.ReadBool('SceneForm','Visible',false);
  finally
    grbl_ini.Free;
  end;
  if form_visible then
//    show;
end;

procedure TForm4.FormClose(Sender: TObject; var Action: TCloseAction);
var
  grbl_ini:TRegistryIniFile;
begin
  grbl_ini:=TRegistryIniFile.Create('GRBLize');
  try
    grbl_ini.WriteInteger('SceneForm','Top',Top);
    grbl_ini.WriteInteger('SceneForm','Left',Left);
  finally
    grbl_ini.Free;
  end;
  Form1.WindowMenu1.Items[2].Checked:= false;
end;

procedure TForm4.FormRefresh(Sender: TObject);
const
  c_scale = 10.0;
//  c_hpgl_scale = 40;

var
  i, j, m, p, my_len, my_pen : Integer;
  x, y, z: Single;
  my_entry: Tfinal;
  my_Polygon: TGLPolygon;
  my_disk: TGLDisk;
  my_hole: TGLAnnulus;
  my_offset: TIntPoint;
  my_radius, my_dia, my_mill_color_corr: Double;
  outer_paths, inner_paths: Tpaths;
  my_poly_end: TEndType;
  my_mill_color: TColorVector;
  my_hpgl_div: Double;
  ZeroOfs: TIntpoint;
  p1: TIntpoint;
  
begin
  p1.X := ToolCursor.X;
  p1.Y := ToolCursor.Y;

  GLArrowLineZ.Position.Z:= job.partsize_z / c_scale;
  GLArrowLineZ.Position.X:= -job.partsize_x / (c_scale*2);
  GLArrowLineZ.Position.Y:= -job.partsize_y / (c_scale*2);

  GLCube1.CubeWidth:= job.partsize_x / c_scale + 2;
  GLCube1.CubeHeight:= job.partsize_y / c_scale + 2;

  GLXYZgrid1.Position.X:= -job.partsize_x / (c_scale*2) -1;
  GLXYZgrid1.Position.Y:= -job.partsize_y / (c_scale*2) -1;
  GLXYZgrid1.XSamplingScale.Max:= job.partsize_x / c_scale + 2;
  GLXYZgrid1.YSamplingScale.Max:= job.partsize_y / c_scale + 2;

  GLSpaceText1.Position.Y:= -job.partsize_y / (c_scale*2) -1.05;

  GLCylinder1.Position.X:= p1.X / (c_hpgl_scale * c_scale);
  GLCylinder1.Position.Y:= p1.Y / (c_hpgl_scale * c_scale);
  if ToolCursorBlock >= 0 then begin
    my_radius:= job.pens[final_Array[ToolCursorBlock].pen].diameter / (c_scale*2);
    GLCylinder1.Position.Z:= 0.2 + job.z_penlift / c_scale;
  end else begin
    my_radius:= 0;
    GLCylinder1.Position.Z:= 3 + job.z_penlift / c_scale;
  end;
  GLCylinder1.TopRadius:= my_radius ;
  GLCylinder1.BottomRadius:= my_radius;
  GLCylinder2.TopRadius:= my_radius;
  GLCylinder2.BottomRadius:= my_radius;

  my_hpgl_div:= c_hpgl_scale * c_scale;

  with GLExtrusionSolid1,Contours do begin
    DeleteChildren;
    Height:= job.partsize_z / c_scale;
    Position.X:= -job.partsize_x / (c_scale*2);
    Position.Y:= -job.partsize_y / (c_scale*2);
    Clear;
    // Werkstück erstellen
    with Add.Nodes do begin
      AddNode(0, 0, 0);
      AddNode(job.partsize_x / c_scale, 0, 0);
      AddNode(job.partsize_x / c_scale, job.partsize_y / c_scale, 0);
      AddNode(0, job.partsize_y / c_scale, 0);
    end;

    my_len:= length(final_array);
    if my_len < 1 then
      exit;

  // add an empty contour for the cutout
    Add;

{    with Add.Nodes do begin
      AddNode(3, 3, 0);
      AddNode(5, 3, 0);
      AddNode(5, 5, 0);
      AddNode(3, 5, 0);
    end;
}
    // Werkstück Outlines/Umrisse einsetzen; können auch mehrere sein
    for i:= 0 to length(final_array)-1 do begin
      my_entry:= final_array[i];
      if not my_entry.enable then
        continue;
      z:= -job.pens[my_entry.pen].z_end;
      if z >= 0 then
        continue;
      my_offset:= job.pens[my_entry.pen].offset;
      my_dia:= job.pens[my_entry.pen].diameter;

      if my_entry.shape = drillhole then begin
        if length(my_entry.millings[0]) > 0 then
          for p:= 0 to length(my_entry.millings[0])-1 do begin // Anzahl Pfade
            my_hole:= TGLannulus(GLExtrusionSolid1.AddNewChild(TGLannulus)); // Bohrloch erstellen
            my_disk:= TGLdisk(GLExtrusionSolid1.AddNewChild(TGLdisk)); // Bohrlochmitte erstellen
            my_hole.PitchAngle:= 90;
            my_hole.position.x:= int(my_entry.millings[0, p].x + my_offset.x) / my_hpgl_div;
            my_hole.position.y:= int(my_entry.millings[0, p].y + my_offset.y) / my_hpgl_div;
            my_hole.height:= job.partsize_z / c_scale + 0.02;
            my_hole.position.z:= my_hole.height / 2;
            my_hole.TopinnerRadius:= my_dia / (c_scale*2);

            my_hole.TopRadius:= my_hole.TopinnerRadius * 1.2;
            my_hole.BottominnerRadius:= my_hole.TopinnerRadius;
            my_hole.BottomRadius:= my_hole.TopRadius;
            my_hole.Material.FrontProperties.Emission.Color:= clrBlack;
            my_hole.Material.FrontProperties.Ambient.Color:= clrGray50;
            my_hole.Material.FrontProperties.Diffuse.Color:= clrGray25;

            my_disk.PitchAngle:= 0;
            my_disk.position.x:= my_hole.position.x;
            my_disk.position.y:= my_hole.position.y;
            my_disk.position.z:= my_hole.height - 0.01;
            my_disk.OuterRadius:= my_hole.TopinnerRadius;
            my_disk.Material.FrontProperties.Emission.Color:= clrBlack;
            my_disk.Material.FrontProperties.Ambient.Color:= clrGray25;
            my_disk.Material.FrontProperties.Diffuse.Color:= clrGray15;
          end;

        continue;
      end;

      my_radius:= my_dia * (c_hpgl_scale div 2);  // = mm * 40plu / 2 in HPGL-Units
      my_mill_color:= GLExtrusionSolid1.Material.FrontProperties.Diffuse.Color;
      my_mill_color_corr:= (5+my_dia*3) / (2+abs(z))  ; // je tiefer und enger, desto duster
      for j:= 0 to 2 do if z < 0 then
        my_mill_color[j]:= my_mill_color[j] - (my_mill_color[j] / my_mill_color_corr);

      z:= (z / c_scale) + (job.partsize_z / c_scale);  // Skalierung

      Add;

      with TClipperOffset.Create() do
      try
        Clear;
        ArcTolerance:= round(my_radius) div (c_hpgl_scale div 2) + 1;
        if my_entry.closed then
          my_poly_end:= etClosedPolygon
        else
          my_poly_end:= etOpenRound;
        AddPaths(my_entry.millings, jtRound, my_poly_end);
        Execute(outer_paths, my_radius);
        Execute(inner_paths, -my_radius);
      finally
        Free;
      end;

      if my_entry.shape <> pocket then
        for j:= 0 to length(inner_paths)-1 do
          inner_paths[j]:= ReversePath(inner_paths[j]);

      if length(outer_paths) > 0 then
        for m:= 0 to length(outer_paths)-1 do  // Anzahl Pfade
          if length(outer_paths[m]) > 0 then with Add.Nodes do begin
            if m = 0 then begin
              my_Polygon:= TGLPolygon(GLExtrusionSolid1.AddNewChild(TGLPolygon));
              my_Polygon.Position.Z:= z;  // inkl. Werkstück
              my_Polygon.Material.FrontProperties.Emission.Color:= clrBlack;
              my_Polygon.Material.FrontProperties.Ambient.Color:= my_mill_color ;
              my_Polygon.Material.FrontProperties.Diffuse.Color:= my_mill_color ;
            end;
            for p:= 0 to length(outer_paths[m])-1 do begin
              x:= int(outer_paths[m,p].x + my_offset.x) / my_hpgl_div;
              y:= int(outer_paths[m,p].y + my_offset.y) / my_hpgl_div;
              AddNode(x, y, 0);
    // Polygon für Werkstück Frästiefe erstellen; nur für Outline
              if m = 0 then
                my_Polygon.AddNode(x, y, 0);
            end;
          end;
      if my_entry.shape <> pocket then begin
        Add;
        if length(inner_paths) > 0 then
          for m:= 0 to length(inner_paths)-1 do  // Anzahl Pfade
            if length(inner_paths[m]) > 0 then with Add.Nodes do begin
              for p:= 0 to length(inner_paths[m])-1 do begin
                x:= int(inner_paths[m,p].x + my_offset.x) / my_hpgl_div;
                y:= int(inner_paths[m,p].y + my_offset.y) / my_hpgl_div;
                AddNode(x, y, 0);
              end;
            end;
        end;
    end;
  end;

end;


procedure TForm4.GLSceneViewer1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if (ssLeft in Shift) then begin
    if (ssShift in Shift) then begin
    // Sichtfeld verschieben, Cube2 ist Kamera Center
      GLdummycube2.Position.z:= GLdummycube2.Position.z - (my-y)/10;
      mx:=x; my:=y;
      exit;
    end;
    GLCamera1.MoveAroundTarget(my-y, mx-x);
    mx:=x; my:=y;
  end;
  if (ssRight in Shift) then begin
    GLCamera1.MoveAroundTarget(0, (sx-x));
    GLdummycube1.Roll(x-sx);
    sx:=x;
    auto_roll:= false;
  end;
end;

procedure TForm4.GLSceneViewer1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (ssLeft in Shift) or (ssRight in Shift) then begin
    mx:=x;
    my:=y;
    mxo:= mx;
    myo:= my;
    dx:= 0;
    dy:= 0;
    sx:= 0;
    auto_roll:= false;
  end;
end;

procedure TForm4.FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  GLCamera1.SceneScale:= GLCamera1.SceneScale * 1.333;
end;

procedure TForm4.FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  GLCamera1.SceneScale:= GLCamera1.SceneScale / 1.333;
end;

procedure TForm4.Timer1Timer(Sender: TObject);
begin
  if not auto_roll then begin
    dx:= (dx * 7 + (mxo-mx)) div 8;
    dy:= (dy * 7 + (myo-my)) div 8;
    mxo:= mx;
    myo:= my;
  end;
  if (abs(dx) > 2) or (abs(dy) > 2) then begin
    GLCamera1.MoveAroundTarget(dy, dx);
    dx:= dx * 98 div 100;
    dy:= dy * 98 div 100;
  end;
end;

procedure TForm4.GLSceneViewer1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  auto_roll:= true;
end;

procedure TForm4.FormActivate(Sender: TObject);
begin
  mxo:= 0;
  myo:= 0;
  mx:= 0;
  my:= 0;
  dx:= 0;
  dy:= 0;
end;

end.
