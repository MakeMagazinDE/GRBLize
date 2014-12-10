object Form3: TForm3
  Left = 0
  Top = 0
  Width = 794
  Height = 506
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeToolWin
  Caption = 'Camera View'
  Color = clBtnFace
  Constraints.MaxHeight = 508
  Constraints.MaxWidth = 794
  Constraints.MinHeight = 250
  Constraints.MinWidth = 400
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object VideoBox: TPaintBox
    Left = 146
    Top = 0
    Width = 640
    Height = 480
    Color = clCream
    ParentColor = False
  end
  object BtnCamIsAtZero: TSpeedButton
    Left = 8
    Top = 228
    Width = 129
    Height = 25
    Hint = 'Camera center is above workpiece zero; set offsets accordingly'
    Caption = 'Cam is at Part Zero'
    Font.Charset = ANSI_CHARSET
    Font.Color = 2925325
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    OnClick = BtnCamIsAtZeroClick
  end
  object Label1: TLabel
    Left = 280
    Top = 224
    Width = 5
    Height = 19
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object BtnCamAtHilite: TSpeedButton
    Left = 8
    Top = 260
    Width = 129
    Height = 25
    Hint = 'Camera center is above hilited point; set offsets accordingly'
    Caption = 'Cam is at Hilite Point'
    Font.Charset = ANSI_CHARSET
    Font.Color = clFuchsia
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    OnClick = BtnCamAtHiliteClick
  end
  object RadioGroupCam: TRadioGroup
    Left = 8
    Top = 8
    Width = 129
    Height = 73
    Hint = 'Spinde view camera control'
    Caption = 'Spindle Cam'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -12
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemIndex = 0
    Items.Strings = (
      'Off'
      'Crosshair')
    ParentFont = False
    TabOrder = 0
    OnClick = RadioGroupCamClick
  end
  object TrackBar1: TTrackBar
    Left = 8
    Top = 128
    Width = 129
    Height = 20
    Hint = 'Crosshair circle diameter'
    Max = 100
    Min = 1
    Position = 10
    TabOrder = 1
    TabStop = False
    TickStyle = tsNone
  end
  object StaticText1: TStaticText
    Left = 76
    Top = 98
    Width = 29
    Height = 17
    Caption = 'Color'
    TabOrder = 2
  end
  object StaticText6: TStaticText
    Left = 31
    Top = 160
    Width = 76
    Height = 17
    Caption = 'Circle Diameter'
    TabOrder = 3
  end
  object OverlayColor: TPanel
    Left = 32
    Top = 96
    Width = 33
    Height = 17
    Hint = 'Crosshair overlay color'
    BevelWidth = 2
    Color = clRed
    Ctl3D = True
    ParentBackground = False
    ParentCtl3D = False
    TabOrder = 4
    OnClick = OverlayColorClick
  end
  object ColorDialog1: TColorDialog
    Left = 16
    Top = 296
  end
end
