object FormParamAssist: TFormParamAssist
  Left = 0
  Top = 0
  Caption = 'Mill Parameter Assistent'
  ClientHeight = 277
  ClientWidth = 674
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object LabelDiameter: TLabel
    Left = 18
    Top = 57
    Width = 122
    Height = 24
    Caption = 'Diameter [mm]'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object LabelBlades: TLabel
    Left = 18
    Top = 89
    Width = 57
    Height = 24
    Caption = 'Blades'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object LabelRotation: TLabel
    Left = 18
    Top = 129
    Width = 68
    Height = 24
    Caption = 'Rotation'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object LabelFeed: TLabel
    Left = 18
    Top = 161
    Width = 45
    Height = 24
    Caption = 'Feed'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object LabelDeep: TLabel
    Left = 18
    Top = 193
    Width = 64
    Height = 24
    Caption = 'Z/Cycle'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object ViewRotation: TLabel
    Left = 140
    Top = 129
    Width = 86
    Height = 24
    Caption = '10000/min'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object ViewFeed: TLabel
    Left = 140
    Top = 161
    Width = 103
    Height = 24
    Caption = '400 mm/min'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object ViewDeep: TLabel
    Left = 140
    Top = 193
    Width = 47
    Height = 24
    Caption = '5 mm'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object LabelMaterial: TLabel
    Left = 18
    Top = 23
    Width = 65
    Height = 24
    Caption = 'Material'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object EditDiameter: TEdit
    Left = 140
    Top = 54
    Width = 213
    Height = 32
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    Text = 'Diameter'
    OnChange = Calculate
  end
  object ComboBoxBlades: TComboBox
    Left = 140
    Top = 86
    Width = 213
    Height = 32
    Style = csDropDownList
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnChange = Calculate
    Items.Strings = (
      '1'
      '2'
      '3'
      '4')
  end
  object ComboBoxMaterial: TComboBox
    Left = 140
    Top = 20
    Width = 213
    Height = 32
    Style = csDropDownList
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnChange = Calculate
  end
  object OKButton: TButton
    Left = 243
    Top = 224
    Width = 110
    Height = 40
    Caption = 'OK'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnClick = OKButtonClick
  end
  object CancelButton: TButton
    Left = 121
    Top = 224
    Width = 110
    Height = 40
    Caption = 'Cancel'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnClick = CancelButtonClick
  end
  object TouchKeyboard1: TTouchKeyboard
    Left = 366
    Top = 19
    Width = 300
    Height = 250
    GradientEnd = clSilver
    GradientStart = clGray
    Layout = 'NumPad'
  end
end
