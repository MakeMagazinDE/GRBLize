unit cam_view;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls,  Buttons, StdCtrls, ComCtrls, Registry, 
  VFrames;

type
  TForm3 = class(TForm)
    VideoBox: TPaintBox;
    RadioGroupCam: TRadioGroup;
    TrackBar1: TTrackBar;
    StaticText1: TStaticText;
    StaticText6: TStaticText;
    OverlayColor: TPanel;
    BtnCamIsAtZero: TSpeedButton;
    ColorDialog1: TColorDialog;
    Label1: TLabel;
    BtnCamAtHilite: TSpeedButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnCamAtHiliteClick(Sender: TObject);
    procedure BtnCamIsAtZeroClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OverlayColorClick(Sender: TObject);
    procedure RadioGroupCamClick(Sender: TObject);

  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    fVideoImage: TVideoImage;
    fVideoBitmap: TBitmap;
    procedure OnNewVideoFrame(Sender : TObject; Width, Height: integer; DataPtr: pointer);
  end;

var
  Form3: TForm3;
  fActivated, fCamPresent : boolean;
  overlay_color: Tcolor;

implementation

uses grbl_player_main, import_files, drawing_window, grbl_com, glscene_view;

{$R *.dfm}

procedure TForm3.RadioGroupCamClick(Sender: TObject);
begin
  case RadioGroupCam.ItemIndex of
    0:
      if fActivated then begin
        fActivated := false;
        fVideoImage.VideoStop;
      end;
    1:
      if fCamPresent then begin
        if not fActivated then
          fVideoImage.VideoStart(DeviceList[0]);
        fActivated:= true;
      end else
        RadioGroupCam.ItemIndex:= 0;
  end;
  Form3.Repaint;
end;

procedure TForm3.OnNewVideoFrame(Sender : TObject; Width, Height: integer; DataPtr: pointer);
var
  r : integer;
  bm_center_x, bm_center_y: Integer;
begin
  // Retreive latest video image
  if not Form1.WindowMenu1.Items[0].Checked then
    exit;
  if not fActivated then
    exit;
  fVideoImage.GetBitmap(fVideoBitmap);
  with fVideoBitmap do begin
    // Paint a crosshair onto video image
    bm_center_x:= VideoBox.width div 2;
    bm_center_y:= VideoBox.height div 2;
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Width   := 1;
    Canvas.Pen.Color:= overlay_color;
    Canvas.moveto(0, bm_center_y);
    Canvas.lineto(Width,  bm_center_y);
    Canvas.moveto(bm_center_x, 0);
    Canvas.lineto(bm_center_x, Height);
    r := (VideoBox.height * TrackBar1.Position div 256);
    Canvas.ellipse(bm_center_x -r, bm_center_y -r,
        bm_center_x +r, bm_center_y +r);
    VideoBox.Canvas.Draw(0, 0, fVideoBitmap);
  end;
end;

procedure TForm3.OverlayColorClick(Sender: TObject);
begin
  ColorDialog1.Color:= OverlayColor.Color;
  if not ColorDialog1.Execute then Exit;
  OverlayColor.Color:= ColorDialog1.Color;
  overlay_color:= OverlayColor.Color;
end;

procedure TForm3.FormCreate(Sender: TObject);
var
  grbl_ini:TRegistryIniFile;
  form_visible: boolean;

begin
  grbl_ini:=TRegistryIniFile.Create('GRBLize');
  try
    Top:= grbl_ini.ReadInteger('CamForm','Top',110);
    Left:= grbl_ini.ReadInteger('CamForm','Left',110);
    form_visible:= grbl_ini.ReadBool('CamForm','Visible',false);
   finally
    grbl_ini.Free;
  end;

  fActivated:= false;
  // Create instance of our video image class.
  fVideoImage:= TVideoImage.Create;
  // Tell fVideoImage where to paint the images it receives from the camera
  // (Only in case we do not want to modify the images by ourselves)
  fVideoImage.SetDisplayCanvas(VideoBox.Canvas);
  fVideoBitmap:= TBitmap.create;
  fVideoBitmap.Height:= VideoBox.Height;
  fVideoBitmap.Width:= VideoBox.Width;


  // Create instance of our video image class.
  fVideoImage:= TVideoImage.Create;
  // Tell fVideoImage where to paint the images it receives from the camera
  // (Only in case we do not want to modify the images by ourselves)
  fVideoImage.SetDisplayCanvas(VideoBox.Canvas);

  overlay_color:= OverlayColor.Color;

  DeviceList := TStringList.Create;
  fVideoImage.GetListOfDevices(DeviceList);
  if DeviceList.Count < 1 then begin
    // If no camera has been found, terminate program
    fCamPresent:= false;
    DeviceList.Free;
    RadioGroupCam.ItemIndex:= 0;
    Label1.Caption:='No Webcam/Video Device found';
  end else begin
    fCamPresent:= true;
    fVideoImage:= TVideoImage.Create;
    fVideoImage.OnNewVideoFrame := OnNewVideoFrame;
    Label1.Caption:='  Webcam/Video Device off';
  end;
  if form_visible then
//    show;
end;

procedure TForm3.FormClose(Sender: TObject; var Action: TCloseAction);
var
  grbl_ini:TRegistryIniFile;
begin
  grbl_ini:=TRegistryIniFile.Create('GRBLize');
  try
    grbl_ini.WriteInteger('CamForm','Top',Top);
    grbl_ini.WriteInteger('CamForm','Left',Left);
  finally
    grbl_ini.Free;
  end;
  
  if fCamPresent then begin
    if fActivated then
      fVideoImage.VideoStop;
  end;
  fActivated := false;
  Form1.WindowMenu1.Items[1].Checked:= false;
end;

procedure TForm3.BtnCamIsAtZeroClick(Sender: TObject);
begin
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('// OFFSET CAM TO PART ZERO');
  grbl_offsXY(-job.cam_x, -job.cam_y);
  SetSimPositionMMxy(-job.cam_x, -job.cam_y);
  NeedsRedraw:= true;
  SendGrblAndWaitForIdle;
end;

procedure TForm3.BtnCamAtHiliteClick(Sender: TObject);
var x,y: Double;
begin
  if (HilitePoint < 0) and (HiliteBlock < 0) then
    exit;

  if HilitePoint >= 0 then begin
    hilite_to_toolcursor;
    Form1.Memo1.lines.add('');
    Form1.Memo1.lines.add('// OFFSET CAM TO POINT');
  end else begin
    hilite_center_to_toolcursor;
    Form1.Memo1.lines.add('');
    Form1.Memo1.lines.add('// OFFSET CAM TO CENTER');
  end;
  x:= drawing_ToolPos.X-job.cam_x;
  y:= drawing_ToolPos.Y-job.cam_y;
  grbl_offsXY(x, y);
  SetSimPositionMMxy(x, y);
  NeedsRedraw:= true;
  SendGrblAndWaitForIdle;
end;


end.
