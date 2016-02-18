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
    BtnCamAtZero: TSpeedButton;
    ColorDialog1: TColorDialog;
    Label1: TLabel;
    BtnCamAtPoint: TSpeedButton;
    Timer1: TTimer;
    Label2: TLabel;
    BtnMoveCamZero: TSpeedButton;
    Label3: TLabel;
    Label4: TLabel;
    BtnMoveToolZero: TSpeedButton;
    BtnMoveCamPoint: TSpeedButton;
    BtnMoveToolPoint: TSpeedButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnCamAtPointClick(Sender: TObject);
    procedure BtnCamAtZeroClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OverlayColorClick(Sender: TObject);
    procedure RadioGroupCamClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure BtnMoveCamZeroClick(Sender: TObject);
    procedure BtnMoveCamPointClick(Sender: TObject);
    procedure BtnMoveToolPointClick(Sender: TObject);
    procedure BtnMoveToolZeroClick(Sender: TObject);

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
  fActivated, fCamPresent, CamIsOn : boolean;
  overlay_color: Tcolor;

implementation

uses grbl_player_main, import_files, drawing_window, grbl_com, glscene_view;

{$R *.dfm}

procedure TForm3.RadioGroupCamClick(Sender: TObject);
begin
  case RadioGroupCam.ItemIndex of
    0:
      begin
      Label1.Caption:='  Webcam/Video Device off';
        if fActivated then begin
          CamIsOn:= false;
          fActivated := false;
          fVideoImage.VideoStop;
        end;
      end;
    1:
      if fCamPresent then begin
        Label1.Caption:='    Initializing Webcam...';
        Application.ProcessMessages;
        if not fActivated then
          fVideoImage.VideoStart(DeviceList[0]);
        fActivated:= true;
        CamIsOn:= true;
      end else
        RadioGroupCam.ItemIndex:= 0;
  end;
  Repaint;
end;

procedure TForm3.OnNewVideoFrame(Sender : TObject; Width, Height: integer; DataPtr: pointer);
var
  r : integer;
  bm_center_x, bm_center_y: Integer;
begin
  // Retreive latest video image
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
  grbl_ini:TRegistry;
  form_visible: boolean;

begin
  grbl_ini:= TRegistry.Create;
  try
    grbl_ini.RootKey := HKEY_CURRENT_USER;
    grbl_ini.OpenKey('SOFTWARE\Make\GRBlize\'+c_VerStr,true);
    if grbl_ini.ValueExists('CamFormTop') then
      Top:= grbl_ini.ReadInteger('CamFormTop');
    if grbl_ini.ValueExists('CamFormLeft') then
      Left:= grbl_ini.ReadInteger('CamFormLeft');
    if grbl_ini.ValueExists('CamOn') then
      CamIsOn:= grbl_ini.ReadBool('CamOn');
    if grbl_ini.ValueExists('CamFormVisible') then
      form_visible:= grbl_ini.ReadBool('CamFormVisible');
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
    CamIsOn:= false;
  end else begin
    fCamPresent:= true;
    fVideoImage:= TVideoImage.Create;
    fVideoImage.OnNewVideoFrame := OnNewVideoFrame;
    Label1.Caption:='  Webcam/Video Device off';
    if CamIsOn then
//      RadioGroupCam.ItemIndex:= 1;
  end;
end;

procedure TForm3.FormClose(Sender: TObject; var Action: TCloseAction);
var
  grbl_ini:TRegistry;
begin
  grbl_ini:= TRegistry.Create;
  try
    grbl_ini.RootKey := HKEY_CURRENT_USER;
    grbl_ini.OpenKey('SOFTWARE\Make\GRBlize\'+c_VerStr, true);
    grbl_ini.WriteInteger('CamFormTop',Top);
    grbl_ini.WriteInteger('CamFormLeft',Left);
    grbl_ini.WriteBool('CamOn', CamIsOn);
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

procedure TForm3.BtnCamAtZeroClick(Sender: TObject);
begin
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Offset cam to part zero');
  grbl_offsXY(-job.cam_x, -job.cam_y);
  SendGrblAndWaitForIdle;
end;

procedure TForm3.BtnCamAtPointClick(Sender: TObject);
var x,y: Double;
begin
  if (HilitePoint < 0) and (HiliteBlock < 0) then
    exit;
  Form1.Memo1.lines.add('');
  if HilitePoint >= 0 then begin
    Form1.Memo1.lines.add('Offset cam to point');
    hilite_to(x,y);
  end else begin
    Form1.Memo1.lines.add('Offset cam to center');
    hilite_center_to(x,y);
  end;
  x:= x - job.cam_x;
  y:= y - job.cam_y;
  grbl_offsXY(x, y);
  SendGrblAndWaitForIdle;
end;

procedure TForm3.BtnMoveCamPointClick(Sender: TObject);
var x,y: Double;
begin
  if (HilitePoint < 0) and (HiliteBlock < 0) then
    exit;
  Form1.Memo1.lines.add('');
  if HilitePoint >= 0 then begin
    Form1.Memo1.lines.add('Move cam to point');
    hilite_to(x,y);
  end else begin
    Form1.Memo1.lines.add('Move cam to center');
    hilite_center_to(x, y);
  end;
  x:= x - job.cam_x;
  y:= y - job.cam_y;
  grbl_moveZ(0, true);  // move Z up
  grbl_moveXY(x, y, false);
  SendGrblAndWaitForIdle;
  grbl_moveZ(job.cam_z_abs, true);
  SendGrblAndWaitForIdle;
end;

procedure TForm3.BtnMoveCamZeroClick(Sender: TObject);
begin
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move cam to part zero');
  grbl_moveZ(0, true);  // move Z up
  grbl_moveXY(-job.cam_x,-job.cam_y, false);
  grbl_moveZ(job.cam_z_abs, true);
  SendGrblAndWaitForIdle;
end;

procedure TForm3.BtnMoveToolPointClick(Sender: TObject);
var x,y: Double;
begin
  Form1.Memo1.lines.add('');
  if HilitePoint >= 0 then begin
    Form1.Memo1.lines.add('Move tool to point');
    hilite_to(x,y);
  end else begin
    Form1.Memo1.lines.add('Move tool to center');
    hilite_center_to(x,y);
  end;
  grbl_moveZ(0, true);  // move Z up absolute
  grbl_moveXY(x, y, false);
  SendGrblAndWaitForIdle;
  grbl_moveZ(job.z_penlift, false);
  SendGrblAndWaitForIdle;
end;

procedure TForm3.BtnMoveToolZeroClick(Sender: TObject);
begin
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Move tool to part zero');
  grbl_moveZ(0, true);  // move Z up absolute
  grbl_moveXY(0,0, false);
  grbl_moveZ(job.z_penlift, false);
  SendGrblAndWaitForIdle;
end;

procedure TForm3.Timer1Timer(Sender: TObject);
begin
  if (HilitePoint < 0) and (HiliteBlock < 0) then begin
    BtnCamAtPoint.Enabled:= false;
    BtnMoveToolPoint.Enabled:= false;
    BtnMoveCamPoint.Enabled:= false;
  end else begin
    BtnCamAtPoint.Enabled:= true;
    BtnMoveToolPoint.Enabled:= true;
    BtnMoveCamPoint.Enabled:= true;
    if HilitePoint >= 0 then begin
      BtnCamAtPoint.Caption:= 'Hilite Point';
      BtnMoveCamPoint.Caption:= 'Hilite Point';
      BtnMoveToolPoint.Caption:= 'Hilite Point';
    end else begin
      BtnCamAtPoint.Caption:= 'Object Center';
      BtnMoveCamPoint.Caption:= 'Object Center';
      BtnMoveToolPoint.Caption:= 'Object Center';
    end;
  end;
end;

end.
