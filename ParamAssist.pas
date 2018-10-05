// Quelle: sorotec.de

unit ParamAssist;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Math,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.Menus,
  import_files;

type
  TFormParamAssist = class(TForm)
    EditDiameter: TEdit;
    LabelDiameter: TLabel;
    LabelBlades: TLabel;
    ComboBoxBlades: TComboBox;
    LabelRotation: TLabel;
    LabelFeed: TLabel;
    LabelDeep: TLabel;
    ViewRotation: TLabel;
    ViewFeed: TLabel;
    ViewDeep: TLabel;
    LabelMaterial: TLabel;
    ComboBoxMaterial: TComboBox;
    OKButton: TButton;
    CancelButton: TButton;
    constructor Create(AOwner: TComponent);       override;
    procedure CancelButtonClick(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
    procedure Calculate(Sender: TObject);
  private
    { Private-Deklarationen }
    Rotation: integer;
    Feed:     integer;
  public
    function ShowModal(Pen: Integer):integer; reintroduce;
    { Public-Deklarationen }
  end;

type
  TMaterial = record
    Name: string[30];  // Zahnvorschub [mm/Zahn/Umdrehung]
    Vcut: double;                 // Schnittgeschwindigkeit [m/min.]
    F0:   array[1..9] of double;  // Zahnvorschub [mm/Zahn/Umdrehung]
  end;

const
  Nmaterial = 9;
  Materials: array[0..Nmaterial-1] of TMaterial =
//                                        Durchmesser: Ø1mm   Ø2mm   Ø3mm   Ø4mm   Ø5mm   Ø6mm   Ø8mm   Ø10mm  Ø12mm
  ( ( Name: 'Guss-Aluminium';          Vcut: 200; F0: (0.010, 0.010, 0.010, 0.015, 0.015, 0.025, 0.030, 0.038, 0.050)),
    ( Name: 'Aluminium Knetlegierung'; Vcut: 500; F0: (0.010, 0.020, 0.025, 0.050, 0.050, 0.050, 0.064, 0.080, 0.100)),
    ( Name: 'Weichkunststoff';         Vcut: 600; F0: (0.025, 0.030, 0.035, 0.045, 0.065, 0.090, 0.100, 0.200, 0.300)),
    ( Name: 'Hartkunststoff';          Vcut: 550; F0: (0.015, 0.020, 0.025, 0.050, 0.060, 0.080, 0.089, 0.100, 0.150)),
    ( Name: 'Hartholz';                Vcut: 450; F0: (0.020, 0.025, 0.030, 0.055, 0.065, 0.085, 0.095, 0.095, 0.155)),
    ( Name: 'Weichholz';               Vcut: 500; F0: (0.025, 0.030, 0.035, 0.060, 0.070, 0.090, 0.100, 0.110, 0.160)),
    ( Name: 'MDF';                     Vcut: 450; F0: (0.050, 0.070, 0.100, 0.150, 0.200, 0.300, 0.400, 0.500, 0.600)),
    ( Name: 'Messing, Kupfer, Bronze'; Vcut: 365; F0: (0.015, 0.020, 0.025, 0.025, 0.030, 0.050, 0.056, 0.065, 0.080)),
    ( Name: 'Stahl';                   Vcut:  90; F0: (0.010, 0.010, 0.012, 0.025, 0.030, 0.038, 0.045, 0.050, 0.080)));

var
  FormParamAssist: TFormParamAssist;

implementation

{$R *.dfm}

constructor TFormParamAssist.Create(AOwner: TComponent);
var i: integer;
begin
  inherited Create(AOwner);
  for i:=0 to Nmaterial-1 do begin
    ComboBoxMaterial.Items.Add(string(Materials[i].Name));
  end;
end;

procedure TFormParamAssist.CancelButtonClick(Sender: TObject);
begin
  FormParamAssist.ModalResult:= mrCancel;
end;

procedure TFormParamAssist.OKButtonClick(Sender: TObject);
begin
//  if (CombolmlllBoxComPort.ItemIndex > 0) then
    FormParamAssist.ModalResult:= mrOK;
end;

function TFormParamAssist.ShowModal(Pen: Integer):integer;
begin
                                                          // set input parameter
  ComboBoxMaterial.ItemIndex:= job.material;
  EditDiameter.Text:=          FormatFloat('0.00',job.pens[Pen].diameter);
  ComboBoxBlades.ItemIndex:=   job.pens[Pen].Blades-1;
  Calculate(nil);

  Result:= inherited ShowModal;

  if Result = mrOK then begin
    job.material:=           ComboBoxMaterial.ItemIndex;
    job.pens[Pen].diameter:= StrToFloatDef(EditDiameter.Text, 0);
    job.pens[Pen].Blades:=   ComboBoxBlades.ItemIndex+1;
    job.rotation:=           Rotation;
    job.pens[Pen].speed:=    Feed;
  end;
end;

procedure TFormParamAssist.Calculate(Sender: TObject);
var Diameter: double;
    Material: integer;
    Blades:   integer;
    D:        integer;
begin                                    // calculation only if Visible, only in
//  if not Visible then exit;             // this case all Input value are updated

///// collect and check input values ///////////////////////////////////////////
  Material:= ComboBoxMaterial.ItemIndex;                        // read material
  if (Material < 0) or (Material >= Nmaterial) then begin
    exit;                                                  // Fehlermeldung!!!
  end;

  Diameter:= StrToFloatDef(EditDiameter.Text, 0);
  if (Diameter <= 0) or (Diameter > 14) then begin
    exit;                                                  // Fehlermeldung!!!
  end;
  if (Diameter < 1.5)  then D:= 1 else
  if (Diameter < 2.5)  then D:= 2 else
  if (Diameter < 3.5)  then D:= 3 else
  if (Diameter < 4.5)  then D:= 4 else
  if (Diameter < 5.5)  then D:= 5 else
  if (Diameter < 6.5)  then D:= 6 else
  if (Diameter < 8.5)  then D:= 7 else
  if (Diameter < 10.5) then D:= 8 else D:= 9;

  Blades:= ComboBoxBlades.ItemIndex + 1;
  if (Blades <= 0) or (Blades > 4) then begin
    exit;                                                  // Fehlermeldung!!!
  end;

///// calculation //////////////////////////////////////////////////////////////
                           // n [U/min] = (vc [m/min] *1000) / (3.14 * Ød1 [mm])
  Rotation:= round(RoundTo(Materials[Material].Vcut * 1000 / (3.1415 * Diameter),3));

        // Rotation muss noch auf max. Drehzahl der Maschine reduziert werden!!!
  if Rotation > job.max_rotation then Rotation:= job.max_rotation;
                                                              // vf = n * z * fz
  Feed:= round(Rotation * Blades * Materials[Material].F0[D]);

  ViewRotation.Caption:= FormatFloat('0',Rotation) + '/min';
  ViewFeed.Caption:=     FormatFloat('0',Feed)     + ' mm/min';

end;

end.
