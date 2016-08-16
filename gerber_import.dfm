object FormGerber: TFormGerber
  Left = 227
  Top = 108
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeToolWin
  BorderWidth = 4
  Caption = 'Convert Gerber to GCode'
  ClientHeight = 519
  ClientWidth = 731
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  OnPaint = FormPaint
  DesignSize = (
    731
    519)
  PixelsPerInch = 96
  TextHeight = 13
  object PaintBox1: TPaintBox
    Left = 0
    Top = 108
    Width = 730
    Height = 410
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = clSilver
    ParentColor = False
  end
  object Label29: TLabel
    Left = 8
    Top = 60
    Width = 54
    Height = 13
    Caption = 'Inflate (mm)'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Label30: TLabel
    Left = 8
    Top = 37
    Width = 320
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'FILE NOT SELECTED'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    WordWrap = True
  end
  object Label1: TLabel
    Left = 77
    Top = 60
    Width = 73
    Height = 13
    Caption = 'Resolution (dpi)'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Memo2: TMemo
    Left = 334
    Top = 5
    Width = 299
    Height = 97
    Anchors = [akTop, akRight]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 7
  end
  object OKBtn: TButton
    Left = 646
    Top = 44
    Width = 75
    Height = 25
    Hint = 'Accept plot and import to GRBLize files'
    Anchors = [akTop, akRight]
    Caption = 'OK'
    Default = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ModalResult = 1
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    OnClick = OKBtnClick
  end
  object CancelBtn: TButton
    Left = 646
    Top = 8
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Cancel = True
    Caption = 'Abbrechen'
    ModalResult = 2
    TabOrder = 1
    OnClick = CancelBtnClick
  end
  object BtnGerberConvert: TButton
    Left = 97
    Top = 7
    Width = 85
    Height = 25
    Hint = 'Start Conversion (may take a few seconds) with new parameters'
    Caption = 'Start Over'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 6
    OnClick = BtnGerberConvertClick
  end
  object BtnOpenGerber: TButton
    Left = 6
    Top = 7
    Width = 85
    Height = 25
    Hint = 'Select Gerber file for conversion'
    Caption = 'Open Gerber'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 8
    OnClick = BtnOpenGerberClick
  end
  object RadioGroup1: TRadioGroup
    Left = 159
    Top = 61
    Width = 169
    Height = 41
    Caption = 'PCB Side'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
  end
  object RadioButtonBack: TRadioButton
    Left = 244
    Top = 78
    Width = 77
    Height = 17
    Hint = 'Gerber file is PCB bottom. Plot will be mirrored'
    Caption = 'Back/Bottom'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
  end
  object RadioButtonFront: TRadioButton
    Left = 169
    Top = 78
    Width = 69
    Height = 17
    Hint = 'Gerber file is PCB top'
    Caption = 'Front/Top'
    Checked = True
    ParentShowHint = False
    ShowHint = True
    TabOrder = 4
    TabStop = True
  end
  object EditInflate: TEdit
    Left = 8
    Top = 76
    Width = 63
    Height = 21
    Hint = 'Offset to track/pad outline'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    Text = '0,2'
  end
  object EditDPI: TEdit
    Left = 77
    Top = 76
    Width = 63
    Height = 21
    Hint = 
      'Resolution of virtual photo plot (higher values increase computi' +
      'ng time)'
    NumbersOnly = True
    ParentShowHint = False
    ShowHint = True
    TabOrder = 9
    Text = '500'
  end
  object OpenFileDialog: TOpenDialog
    Filter = 
      'Vector/Drill Files|*.plt;*.hpgl; *.hpg;*.pen;*.drl;*.svg|G-Code ' +
      'Files|*.tap; *.dat; *.nc?; *.gc?; *.ngc|GRBL Setup|*.grb|Gerber ' +
      'Files|*.gbr|All Files|*.*'
    FilterIndex = 0
    Options = [ofFileMustExist, ofEnableSizing]
    Left = 664
    Top = 75
  end
end
