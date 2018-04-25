object Form3: TForm3
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeToolWin
  Caption = 'Camera View'
  ClientHeight = 469
  ClientWidth = 778
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
  object BtnCamAtZero: TSpeedButton
    Left = 8
    Top = 212
    Width = 129
    Height = 25
    Hint = 'Camera center is above workpiece zero; set offsets accordingly'
    Caption = 'Part Zero'
    Font.Charset = ANSI_CHARSET
    Font.Color = 2925325
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    OnClick = BtnCamAtZeroClick
  end
  object Label1: TLabel
    Left = 320
    Top = 210
    Width = 5
    Height = 19
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object BtnCamAtPoint: TSpeedButton
    Left = 8
    Top = 243
    Width = 129
    Height = 25
    Hint = 
      'Camera center is above hilighted point in drawing; set offsets a' +
      'ccordingly'
    Caption = 'Hilite Point'
    Font.Charset = ANSI_CHARSET
    Font.Color = clFuchsia
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    OnClick = BtnCamAtPointClick
  end
  object VideoBox: TPaintBox
    Left = 143
    Top = -4
    Width = 640
    Height = 480
    Color = clCream
    ParentColor = False
  end
  object Label2: TLabel
    Left = 44
    Top = 193
    Width = 61
    Height = 13
    Caption = 'Cam is at...'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object BtnMoveCamZero: TSpeedButton
    Left = 8
    Top = 307
    Width = 129
    Height = 25
    Caption = 'Part Zero'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    OnClick = BtnMoveCamZeroClick
  end
  object Label3: TLabel
    Left = 33
    Top = 288
    Width = 83
    Height = 13
    Caption = 'Move Cam to...'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label4: TLabel
    Left = 34
    Top = 383
    Width = 82
    Height = 13
    Caption = 'Move Tool to...'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object BtnMoveToolZero: TSpeedButton
    Left = 8
    Top = 402
    Width = 129
    Height = 25
    Hint = 'Move tool to part zero'
    Caption = 'Part Zero'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clOlive
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    OnClick = BtnMoveToolZeroClick
  end
  object BtnMoveCamPoint: TSpeedButton
    Left = 8
    Top = 338
    Width = 129
    Height = 25
    Hint = 'Move camerato hilighted point in drawing;'
    Caption = 'Hilite Point'
    Font.Charset = ANSI_CHARSET
    Font.Color = clPurple
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    OnClick = BtnMoveCamPointClick
  end
  object BtnMoveToolPoint: TSpeedButton
    Left = 8
    Top = 433
    Width = 129
    Height = 25
    Hint = 'Move Tool to hilighted point in Drawing'
    Caption = 'Hilite Point'
    Font.Charset = ANSI_CHARSET
    Font.Color = clTeal
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    OnClick = BtnMoveToolPointClick
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
    Left = 200
    Top = 424
  end
  object Timer1: TTimer
    Interval = 250
    OnTimer = Timer1Timer
    Left = 264
    Top = 424
  end
end
