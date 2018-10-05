object FormGerber: TFormGerber
  Left = 227
  Top = 108
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeToolWin
  BorderWidth = 4
  Caption = 'Convert Gerber to GCode'
  ClientHeight = 519
  ClientWidth = 790
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
    790
    519)
  PixelsPerInch = 96
  TextHeight = 13
  object PaintBox1: TPaintBox
    Left = 0
    Top = 0
    Width = 789
    Height = 410
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = clSilver
    ParentColor = False
    ExplicitWidth = 730
  end
  object Memo2: TMemo
    Left = 260
    Top = 416
    Width = 409
    Height = 97
    Anchors = [akTop, akRight]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object OKBtn: TButton
    Left = 679
    Top = 471
    Width = 110
    Height = 40
    Hint = 'Accept plot and import to GRBLize files'
    Anchors = [akTop, akRight]
    Caption = 'OK'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ModalResult = 1
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    OnClick = OKBtnClick
  end
  object CancelBtn: TButton
    Left = 679
    Top = 416
    Width = 110
    Height = 40
    Anchors = [akTop, akRight]
    Cancel = True
    Caption = 'Abbrechen'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ModalResult = 2
    ParentFont = False
    TabOrder = 1
    OnClick = CancelBtnClick
  end
  object InflateGroup: TGroupBox
    Left = 0
    Top = 416
    Width = 150
    Height = 97
    Caption = 'Inflate (mm)'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    object InflateBar: TTrackBar
      Left = 2
      Top = 53
      Width = 146
      Height = 40
      DragKind = dkDock
      Max = 20
      Position = 2
      TabOrder = 0
      ThumbLength = 40
      TickStyle = tsNone
      OnChange = InflateBarChange
    end
    object EditInflate: TEdit
      Left = 47
      Top = 22
      Width = 63
      Height = 21
      Hint = 'Offset to track/pad outline'
      Alignment = taCenter
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      Text = '0,2'
      OnExit = InflateEditExit
      OnKeyPress = EditInflateKeyPress
    end
  end
  object PCBBox: TGroupBox
    Left = 154
    Top = 416
    Width = 100
    Height = 97
    Caption = 'PCB'
    TabOrder = 4
    object Label1: TLabel
      Left = 10
      Top = 44
      Width = 46
      Height = 13
      Caption = 'Thickness'
    end
    object CheckMirror: TCheckBox
      Left = 10
      Top = 20
      Width = 143
      Height = 23
      Caption = 'Mirror'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = CheckMirrorClick
    end
    object ComboThickness: TComboBox
      Left = 10
      Top = 59
      Width = 82
      Height = 31
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      Text = '1,6'
      TextHint = 'Thickness of PCB'
      Items.Strings = (
        '0,4'
        '0,6'
        '0,8'
        '1,2'
        '1,6'
        '2,0'
        '2,4')
    end
  end
  object OpenFileDialog: TOpenDialog
    Filter = 
      'Vector/Drill Files|*.plt;*.hpgl; *.hpg;*.pen;*.svg|G-Code Files|' +
      '*.tap; *.dat; *.nc?; *.gc?; *.ngc|GRBL Setup|*.grb|Gerber Files|' +
      '*.gbr;*.drl;*.drd|All Files|*.*'
    FilterIndex = 0
    Options = [ofFileMustExist, ofEnableSizing]
    Left = 664
    Top = 75
  end
  object TimerInflateBar: TTimer
    Enabled = False
    Interval = 10
    OnTimer = InflateBarTimer
    Left = 520
    Top = 88
  end
end
