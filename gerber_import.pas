unit gerber_import;

{ Verarbeitete Formate für Gerber-Daten:
  "xxx_front" / "xxx_back"
  "xxx_top" / "xxx_bottom"
  Die Bottom-Daten werden durch GRBLize gespiegelt. Bei Eagle führt das zu
  Abweichungen zwischen den Gerber- und den Bohr bzw- Dimensionsdaten.

  "xxx_01" / "xxx_16"
  Das Spiegeln der Unterseite erfolgt bei der Generierung der Gerberdaten, nicht
  durch GRBLize!
}

interface

uses ShellApi, Winapi.Windows, MMsystem, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Forms,
  Vcl.Controls, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls, Vcl.Dialogs,
  import_files, grbl_com, Vcl.ComCtrls;

function CallPcb2Gcode(source_path: String;
                       Mirrored:    boolean;
                       my_offset:   Double;
                       Dpi:         String):String;

type
  TFormGerber = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    EditInflate: TEdit;
    Memo2: TMemo;
    PaintBox1: TPaintBox;
    OpenFileDialog: TOpenDialog;
    InflateBar: TTrackBar;
    InflateGroup: TGroupBox;
    CheckMirror: TCheckBox;
    PCBBox: TGroupBox;
    ComboThickness: TComboBox;
    Label1: TLabel;
    TimerInflateBar: TTimer;
    procedure OKBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure InflateBarChange(Sender: TObject);
    procedure EditInflateKeyPress(Sender: TObject; var Key: Char);
    procedure InflateEditExit(Sender: TObject);
    procedure InflateChange;
    procedure CheckMirrorClick(Sender: TObject);
    procedure InflateBarTimer(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormGerber: TFormGerber;
  GerberFileName, ConvertedFileName: String;
  GerberFileNumber: Integer;
  img: TImage;
  image_loaded: Boolean;


implementation

{$R *.dfm}

uses grbl_player_main;

procedure ExecuteFile(const AFilename: String;
              AParameter, ACurrentDir: String;
                         AWait, AHide: Boolean);
var
  si: TStartupInfo;
  pi: TProcessInformation;

begin
  if Length(ACurrentDir) = 0 then
    ACurrentDir := ExtractFilePath(AFilename)
  else if AnsiLastChar(ACurrentDir) = '\' then
    Delete(ACurrentDir, Length(ACurrentDir), 1);

  FillChar(si, SizeOf(si), 0);
  with si do begin
    cb := SizeOf(si);
    dwFlags := STARTF_USESHOWWINDOW;
    if AHide then
      wShowWindow := SW_HIDE
    else
      wShowWindow := SW_NORMAL;
  end;
  FillChar(pi, SizeOf(pi), 0);
  AParameter := Format('"%s" %s', [AFilename, TrimRight(AParameter)]);

{  if CreateProcess(Nil, PChar(AParameter), Nil, Nil, False,
                   CREATE_DEFAULT_ERROR_MODE or CREATE_NEW_CONSOLE or
                   NORMAL_PRIORITY_CLASS, Nil, PChar(ACurrentDir), si, pi) then
}
  if CreateProcess(Nil, PChar(AParameter), Nil, Nil, false, 0, Nil, PChar(ACurrentDir), si, pi) then
  try
    if AWait then
      while WaitForSingleObject(pi.hProcess, 50) <> Wait_Object_0 do begin


      end;
    TerminateProcess(pi.hProcess, Cardinal(-1));
  finally
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
  end;
end;

function CopyFileEx(const ASource, ADest: string; ARenameCheck: boolean = false): boolean;
var
  sh: TSHFileOpStruct;
begin
  sh.Wnd := Application.Handle;
  sh.wFunc := FO_COPY;
  // String muss mit #0#0 terminiert werden, um das Listenende zu setzen
  sh.pFrom := PChar(ASource + #0#0);
  sh.pTo := PChar(ADest + #0#0);
  sh.fFlags := fof_Silent or fof_MultiDestFiles;
  if ARenameCheck then
    sh.fFlags := sh.fFlags or fof_RenameOnCollision;
  Result:=ShFileOperation(sh)=0;
end;

function RenameFileBlanks(my_file: String): String;
var my_path, my_name: String;
begin
    my_path:= ExtractFilePath(my_file);
    my_name:= ExtractFileName(my_file);
    result:= my_file;
    if pos(#32,my_name) > 0 then begin
      FormGerber.Memo2.Lines.Add('Gerber file copied/renamed, blank characters removed');
      my_name:= StringReplace(my_name, ' ', '', [rfReplaceAll, rfIgnoreCase]);
      my_path:= my_path + my_name;
      if FileExists(my_path) then
        DeleteFile(my_path);
      CopyFileEx(my_file, my_path, false);
      result:= my_path;
    end;
end;

{
command line only options:
  --noconfigfile [=arg(=1)] (=0) ignore any configuration file
  -? [ --help ]                  produce help message
  --version                      show the current software version
generic options (CLI and config files):
  --front arg                           front side RS274-X .gbr
  --back arg                            back side RS274-X .gbr
  --outline arg                         pcb outline polygon RS274-X .gbr
  --drill arg                           Excellon drill file
  --svg arg                             SVG output file. EXPERIMENTAL
  --zwork arg                           milling depth in inches (Z-coordinate
                                        while engraving)
  --zsafe arg                           safety height (Z-coordinate during
                                        rapid moves)
  --offset arg                          distance between the PCB traces and the
                                        end mill path in inches; usually half
                                        the isolation width
  --mill-feed arg                       feed while isolating in [i/m] or [mm/m]
  --mill-speed arg                      spindle rpm when milling
  --milldrill [=arg(=1)] (=0)           drill using the mill head
  --nog81 [=arg(=1)] (=0)               replace G81 with G0+G1
  --extra-passes arg (=0)               specify the the number of extra
                                        isolation passes, increasing the
                                        isolation width half the tool diameter
                                        with each pass
  --fill-outline [=arg(=1)] (=0)        accept a contour instead of a polygon
                                        as outline (you likely want to enable
                                        this one)
  --outline-width arg                   width of the outline
  --cutter-diameter arg                 diameter of the end mill used for
                                        cutting out the PCB
  --zcut arg                            PCB cutting depth in inches
  --cut-feed arg                        PCB cutting feed in [i/m] or [mm/m]
  --cut-speed arg                       spindle rpm when cutting
  --cut-infeed arg                      maximum cutting depth; PCB may be cut
                                        in multiple passes
  --cut-front [=arg(=1)] (=0)           cut from front side. Default is back
                                        side.
  --zdrill arg                          drill depth
  --zchange arg                         tool changing height
  --drill-feed arg                      drill feed in [i/m] or [mm/m]
  --drill-speed arg                     spindle rpm when drilling
  --drill-front [=arg(=1)] (=0)         drill through the front side of board
  --onedrill [=arg(=1)] (=0)            use only one drill bit size
  --metric [=arg(=1)] (=0)              use metric units for parameters. does
                                        not affect gcode output
  --metricoutput [=arg(=1)] (=0)        use metric units for output
  --optimise [=arg(=1)] (=0)            Reduce output file size by up to 40%
                                        while accepting a little loss of
                                        precision.
  --bridges arg (=0)                    add bridges with the given width to the
                                        outline cut
  --bridgesnum arg (=2)                 specify how many bridges should be
                                        created
  --zbridges arg                        bridges heigth (Z-coordinates while
                                        engraving bridges, default to zsafe)
  --al-front [=arg(=1)] (=0)            enable the z autoleveller for the front
                                        layer
  --al-back [=arg(=1)] (=0)             enable the z autoleveller for the back
                                        layer
  --software arg                        choose the destination software (useful
                                        only with the autoleveller). Supported
                                        softwares are linuxcnc, mach3, mach4
                                        and custom
  --al-x arg                            width of the x probes
  --al-y arg                            width of the y probes
  --al-probefeed arg                    speed during the probing
  --al-probe-on arg (=(MSG, Attach the probe tool)@M0 ( Temporary machine stop. ))
                                        execute this commands to enable the
                                        probe tool (default is M0)
  --al-probe-off arg (=(MSG, Detach the probe tool)@M0 ( Temporary machine stop. ))
                                        execute this commands to disable the
                                        probe tool (default is M0)
  --al-probecode arg (=G31)             custom probe code (default is G31)
  --al-probevar arg (=2002)             number of the variable where the result
                                        of the probing is saved (default is
                                        2002)
  --al-setzzero arg (=G92 Z0)           gcode for setting the actual position
                                        as zero (default is G92 Z0)
  --dpi arg (=1000)                     virtual photoplot resolution
  --zero-start [=arg(=1)] (=0)          set the starting point of the project
                                        at (0,0)
  --g64 arg                             maximum deviation from toolpath,
                                        overrides internal calculation
  --mirror-absolute [=arg(=1)] (=0)     mirror back side along absolute zero
                                        instead of board center

  --output-dir arg                      output directory
  --basename arg                        prefix for default output file names
  --front-output arg (=front.ngc)       output file for front layer
  --back-output arg (=back.ngc)         output file for back layer
  --outline-output arg (=outline.ngc)   output file for outline
  --drill-output arg (=drill.ngc)       output file for drilling
  --preamble-text arg                   preamble text file, inserted at the
                                        very beginning as a comment.
  --preamble arg                        gcode preamble file, inserted at the
                                        very beginning.
  --postamble arg                       gcode postamble file, inserted before
                                        M9 and M2.
}


procedure Mirror(my_picture: TPicture);
var
  MemBmp: TBitmap;
  Dest: TRect;
begin { Mirror }
  if Assigned(my_picture.Graphic) then begin
    MemBmp := TBitmap.Create;
    try
      MemBmp.PixelFormat := pf24bit;
      MemBmp.HandleType := bmDIB;
      MemBmp.Width := my_picture.Graphic.Width;
      MemBmp.Height := my_picture.Height;
      MemBmp.Canvas.Draw(0, 0, my_picture.Graphic);

      //SpiegelnVertikal(MemBmp);
      //SpiegelnHorizontal(MemBmp);
      Dest.Left := MemBmp.Width;
      Dest.Top := 0;
      Dest.Right := -MemBmp.Width;
      Dest.Bottom := MemBmp.Height;
      StretchBlt(MemBmp.Canvas.Handle, Dest.Left, Dest.Top, Dest.Right, Dest.Bottom,
                 MemBmp.Canvas.Handle, 0, 0, MemBmp.Width, MemBmp.Height,
                 SRCCOPY);

      my_picture.Graphic.Assign(MemBmp);
    finally
      FreeAndNil(MemBmp)
    end; { try }
  end; { Assigned(Picture.Graphic) }
end; { Mirror }

function CallPcb2Gcode(source_path: String;
                       Mirrored:    boolean;
                       my_offset:   Double;
                       Dpi:         String):String;
var my_converter_path, my_side, my_arg: String;
    target_ext, S: string;
begin
  Result := '';                           // Leerstring entspricht Fehlermeldung
  my_converter_path:= ExtractFilePath(Application.ExeName) + 'pcb2gcode\pcb2gcode.exe';
  if not FileExists(my_converter_path) then          // Konverter nicht gefunden
    exit;

  target_ext:= '.ncb';
  S:= ansiuppercase(ExtractFileName(source_path));
  if (pos(  'TOP',S) > 0) or
     (pos('FRONT',S) > 0) or
     (pos(  '_01',S) > 0) then target_ext:= '.ncf';

  my_side:= '--front'; if Mirrored then my_side:= '--back';

  ConvertedFileName:= ChangeFileExt(source_path, target_ext);

  my_arg:= my_side + #32 + source_path
    + ' --nog81 --dpi ' + Dpi
    + ' --zsafe 1 --zchange 30 --zwork -0.2'
    + ' --offset ' + FloatToStrDot(my_offset)
    + ' --mill-feed 200'
    + ' --optimise=1 --mill-speed 3000 --metric=1 --metricoutput=1 '
    + my_side + '-output ' + ConvertedFileName;
  ExecuteFile(my_converter_path, my_arg, ExtractFilePath(my_converter_path), true, true);
  Result := my_arg;
end;

procedure TFormGerber.InflateChange;
var CmdStr, my_png_path: String;
begin
  Paintbox1.canvas.Brush.Color:= clsilver;
  Paintbox1.canvas.FillRect(rect(0,0,PaintBox1.Width,PaintBox1.Height));
  Caption:= 'Convert Gerber to GCode: ' + ExtractFileName(GerberFileName);

  my_png_path:= ExtractFilePath(Application.ExeName) + 'pcb2gcode\outp1_traced.png';
  if FileExists(my_png_path) then DeleteFile(my_png_path);

  Memo2.Lines.Add('Converted file will be imported as #' + IntToStr(GerberFileNumber));
  Memo2.Lines.Add('Please wait...');
  Application.ProcessMessages;
  Screen.Cursor:= crHourglass;

  CmdStr := CallPcb2Gcode(GerberFileName,
                          CheckMirror.Checked,
                          FileParamArray[GerberFileNumber-1].gbr_inflate,
                          '500');

  if CmdStr = '' then begin
    Memo2.lines.add('PCB2GCODE converter not found.');
    exit;
  end;

  Memo2.lines.add(CmdStr);

  FormGerber.BringToFront;
  Screen.Cursor:= crDefault;
//  Application.ProcessMessages;
  if FileExists(ConvertedFileName) then begin
    Memo2.lines.add('Converted file written to ');
    Memo2.lines.add(ConvertedFileName);
    Caption:= 'Convert Gerber to GCode: ' + ExtractFileName(ConvertedFileName);
  end;
  my_png_path:= ExtractFilePath(Application.ExeName) + 'pcb2gcode\outp1_traced.png';
  if FileExists(my_png_path) then begin
    OKbtn.Enabled:= true;
    Memo2.lines.add('Loading preview...');
//    Application.ProcessMessages;
    img.Picture.LoadFromFile(my_png_path);
    image_loaded:= true;
    // Image ist idR sehr groß, muss skaliert werden
    if CheckMirror.Checked then Mirror(img.picture);
//    Application.ProcessMessages;
    paint;
  end else begin
    Memo2.lines.add('pcb2gcode failed: No layout image found.');
    OKbtn.Enabled:= false;
    image_loaded:= false;
  end;
  Memo2.lines.add('Done.');
end;

procedure TFormGerber.InflateBarChange(Sender: TObject);
begin
                 // first end the windows event handling before serve the change
                 // handle only after MouseUp
  if GetAsyncKeyState(VK_LBUTTON) = 0 then TimerInflateBar.Enabled:= true;
end;

procedure TFormGerber.CheckMirrorClick(Sender: TObject);
begin
  InflateChange;
end;

procedure TFormGerber.EditInflateKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then InflateEditExit(Sender);
end;

procedure TFormGerber.InflateEditExit(Sender: TObject);
var v, v0: double;
begin
  v0:= -1;                                // limit value to limits of InflateBar
  v:= 10*StrToFloatDef(EditInflate.Text, 0.1);
  if v < InflateBar.Min then v0:= InflateBar.Min;
  if v > InflateBar.Max then v0:= InflateBar.Max;
  if v0 <> -1 then EditInflate.Text:= FloatToStr(v/10);
  if abs(InflateBar.Position - v) > 0.9 then InflateBar.Position:= round(v);
  InflateChange;
end;

procedure blank_warning;
begin
  FormGerber.Caption:= 'Convert Gerber to GCode: ' + 'FILE PATH INVALID';
  FormGerber.Memo2.Lines.Add('ERROR: File path may not contain spaces!');
  FormGerber.Memo2.Lines.Add('PCB2GCODE converter will fail otherwise.');
  PlaySound('SYSTEMHAND', 0, SND_ASYNC);
end;

procedure set_mirrored;
var my_filename: String;
begin
  my_filename:= ansiuppercase(ExtractFileName(GerberFileName));
  if (pos(  'TOP',my_filename) > 0) or
     (pos('FRONT',my_filename) > 0) or
     (pos(  '_01',my_filename) > 0) or
     (pos(  '_16',my_filename) > 0) then begin
    FormGerber.CheckMirror.checked:= false;
  end else begin;
    FormGerber.Memo2.Lines.Add('Assume PCB should be mirrored.');
    FormGerber.CheckMirror.checked:= true;
  end;
end;

procedure TFormGerber.CancelBtnClick(Sender: TObject);
begin
  GerberFileName:='';
  ConvertedFileName:='';
  GerberFileNumber:= 1;
  Memo2.Lines.Add('Gerber import cancelled');
  close;
end;

procedure TFormGerber.FormActivate(Sender: TObject);
begin
  img := TImage.create(nil);
  OKbtn.Enabled:= false;
  Memo2.lines.clear;
  image_loaded:= false;
  if FileExists(GerberFileName) then begin
    GerberFileName:= RenameFileBlanks(GerberFileName);
    if pos(#32,GerberFileName) > 0 then
      blank_warning
    else begin
      set_mirrored;
      Caption:= 'Convert Gerber to GCode: ' + ExtractFileName(GerberFileName);
      InflateEditExit(Sender);
    end;
  end else begin
    Memo2.Lines.Add('Please open a Gerber File.');
    Caption:= 'Convert Gerber to GCode: ' + 'FILE NOT SELECTED';
  end;
end;

procedure TFormGerber.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  image_loaded:= false;
  img.Free;
end;

procedure TFormGerber.FormCreate(Sender: TObject);
begin
  GerberFileNumber:= 1;
  image_loaded:= false;
end;

procedure TFormGerber.FormPaint(Sender: TObject);
var
  img_height_f, img_width_f: Double;
  height_fac, width_fac, size_fac: Double;
begin
// Image ist idR sehr groß, muss skaliert werden
  if image_loaded then begin
    img_height_f:= img.picture.Graphic.Height;
    img_width_f:= img.picture.Graphic.Width;
    width_fac:= img_width_f / PaintBox1.Width;
    height_fac:= img_height_f / PaintBox1.Height;
    if width_fac > height_fac then
      size_fac:= width_fac
    else
      size_fac:= height_fac;
    Paintbox1.Canvas.StretchDraw(rect(0,0,round(img_width_f / size_fac),
      round(img_height_f / size_fac)),img.picture.Graphic);
  end else begin
    Paintbox1.canvas.Brush.Color:= clsilver;
    Paintbox1.canvas.FillRect(rect(0,0,PaintBox1.Width,PaintBox1.Height));
  end;
end;

procedure TFormGerber.OKBtnClick(Sender: TObject);
begin
  if image_loaded and FileExists(ConvertedFileName) then begin

    Form1.sgFiles.Cells[0, GerberFileNumber]:= ConvertedFileName;
    Form1.sgFiles.Cells[1, GerberFileNumber]:= '9';
    job.fileDelimStrings[GerberFileNumber-1]:=
      ShortString(Form1.sgFiles.Rows[GerberFileNumber].DelimitedText);

    Form1.SgJobDefaults.Cells[1, 3]:= ComboThickness.Text;
    job.partsize_z:= StrToFloatDef(ComboThickness.Text, 1.6);

    FileParamArray[GerberFileNumber].gbr_name:=    GerberFileName;
    FileParamArray[GerberFileNumber].gbr_mirror:=  CheckMirror.Checked;
    FileParamArray[GerberFileNumber].gbr_inflate:= StrToFloatDef(EditInflate.Text, 0.1);

    Memo2.Lines.Add('Added file '+ ConvertedFileName);
    OpenFilesInGrid;
  end else
    Memo2.Lines.Add('Error: File not Found!');
  close;
end;

procedure TFormGerber.InflateBarTimer(Sender: TObject);
begin
  TimerInflateBar.Enabled:= false;                              // disable timer
  EditInflate.Text:= FloatToStr(InflateBar.Position/10);
  InflateEditExit(Sender);
end;

end.
