program GRBLize;
uses
  Forms,
  ABOUT in 'ABOUT.PAS' {AboutBox},
  grbl_com in 'grbl_com.pas',
  blinklist in 'ftdiclass\blinklist.pas',
  bsearchtree in 'ftdiclass\bsearchtree.pas',
  FTDIchip in 'ftdiclass\FTDIchip.pas',
  FTDIdll in 'ftdiclass\FTDIdll.pas',
  FTDIthread in 'ftdiclass\FTDIthread.pas',
  FTDItypes in 'ftdiclass\FTDItypes.pas',
  deviceselect in 'deviceselect.pas' {deviceselectbox},
  import_files in 'import_files.pas',
  clipper in 'clipper.pas',
  drawing_window in 'drawing_window.pas' {Form2},
  cam_view in 'cam_view.pas' {Form3},
  glscene_view in 'glscene_view.pas' {Form4},
  DirectDraw in 'DirectX\DirectDraw.pas',
  DirectShow9 in 'DirectX\DirectShow9.pas',
  DirectSound in 'DirectX\DirectSound.pas',
  DXTypes in 'DirectX\DXTypes.pas',
  Direct3D9 in 'DirectX\Direct3D9.pas',
  grbl_player_main in 'grbl_player_main.pas' {Form1},
  VFrames in 'VFrames.pas',
  gerber_import in 'gerber_import.pas' {FormGerber};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'GRBLize';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TFormGerber, FormGerber);
  Application.Run;
  Application.Terminate;
end.
