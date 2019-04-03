object Form2: TForm2
  Left = 0
  Top = 0
  Cursor = crCross
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeToolWin
  Caption = 'Drawing'
  ClientHeight = 587
  ClientWidth = 856
  Color = clBtnFace
  Constraints.MaxHeight = 800
  Constraints.MaxWidth = 1200
  Constraints.MinHeight = 240
  Constraints.MinWidth = 320
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  OnMouseWheel = FormMouseWheel
  OnPaint = FormPaint
  OnResize = FormResize
  DesignSize = (
    856
    587)
  PixelsPerInch = 96
  TextHeight = 13
  object DrawingBox: TPaintBox
    Left = -1
    Top = 2
    Width = 857
    Height = 547
    Hint = 'Milling View - Drag with left-click or modify with right-click'
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = clCream
    DragCursor = crSizeAll
    ParentColor = False
    ParentShowHint = False
    ShowHint = True
    Touch.InteractiveGestures = [igZoom, igPressAndTap]
    OnMouseDown = DrawingBoxMouseDown
    OnMouseMove = DrawingBoxMouseMove
    OnMouseUp = DrawingBoxMouseUp
  end
  object Panel1: TPanel
    Left = -1
    Top = 549
    Width = 857
    Height = 38
    Align = alCustom
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 0
    DesignSize = (
      857
      38)
    object BtnZoomReset: TButton
      Left = 771
      Top = 4
      Width = 80
      Height = 30
      HelpType = htKeyword
      HelpKeyword = 'Reset zoom and pan'
      Anchors = [akRight, akBottom]
      Caption = 'Reset'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      TabStop = False
      OnClick = BtnZoomResetClick
    end
    object CheckBoxDimensions: TCheckBox
      Left = 8
      Top = 8
      Width = 177
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Show Dimensions'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = CheckBoxDimensionsClick
    end
    object CheckBoxDirections: TCheckBox
      Left = 190
      Top = 8
      Width = 162
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Show Directions'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = CheckBoxDirectionsClick
    end
    object CheckBoxToolpath: TCheckBox
      Left = 358
      Top = 8
      Width = 155
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Show Tool Path'
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      State = cbChecked
      TabOrder = 3
      OnClick = CheckBoxDirectionsClick
    end
    object BtnDecZoom: TButton
      Left = 649
      Top = 4
      Width = 30
      Height = 30
      HelpType = htKeyword
      HelpKeyword = 'Reset zoom and pan'
      Anchors = [akRight, akBottom]
      Caption = '-'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
      TabStop = False
      OnClick = BrtZoomDecClick
    end
    object BtnIncZoom: TButton
      Left = 730
      Top = 4
      Width = 30
      Height = 30
      HelpType = htKeyword
      HelpKeyword = 'Reset zoom and pan'
      Anchors = [akRight, akBottom]
      Caption = '+'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
      TabStop = False
      OnClick = BtnZoomIncClich
    end
    object ViewZoom: TStaticText
      Left = 685
      Top = 4
      Width = 26
      Height = 29
      Anchors = [akRight, akBottom]
      Caption = '50'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
    end
    object StaticText4: TStaticText
      Left = 577
      Top = 4
      Width = 63
      Height = 29
      Anchors = [akRight, akBottom]
      Caption = 'Zoom:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
    end
  end
  object PopupMenuPoint: TPopupMenu
    AutoPopup = False
    Left = 84
    Top = 80
    object pu_PointEnabled: TMenuItem
      Caption = 'Path Enabled'
      Checked = True
      OnClick = pu_PathEnabledClick
    end
    object MenuItem2: TMenuItem
      Caption = '-'
    end
    object MenuItem3: TMenuItem
      AutoCheck = True
      Caption = 'Contour'
      GroupIndex = 1
      OnClick = pu_RadioClick
    end
    object MenuItem4: TMenuItem
      Tag = 1
      AutoCheck = True
      Caption = 'Inside'
      GroupIndex = 1
      OnClick = pu_RadioClick
    end
    object MenuItem5: TMenuItem
      Tag = 2
      AutoCheck = True
      Caption = 'Outside'
      GroupIndex = 1
      OnClick = pu_RadioClick
    end
    object MenuItem6: TMenuItem
      Tag = 3
      AutoCheck = True
      Caption = 'Pocket'
      GroupIndex = 1
      OnClick = pu_RadioClick
    end
    object MenuItem7: TMenuItem
      Caption = 'Drill'
      GroupIndex = 2
      OnClick = pu_RadioClick
    end
  end
  object PopupMenuObject: TPopupMenu
    Left = 84
    Top = 24
    object pu_ObjectEnabled: TMenuItem
      Caption = 'Object Enabled'
      Checked = True
      OnClick = pu_ObjectEnabledClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object pu_online: TMenuItem
      AutoCheck = True
      Caption = 'Contour'
      GroupIndex = 1
      OnClick = pu_RadioClick
    end
    object pu_inside: TMenuItem
      Tag = 1
      AutoCheck = True
      Caption = 'Inside'
      GroupIndex = 1
      OnClick = pu_RadioClick
    end
    object pu_outside: TMenuItem
      Tag = 2
      AutoCheck = True
      Caption = 'Outside'
      GroupIndex = 1
      OnClick = pu_RadioClick
    end
    object pu_pocket: TMenuItem
      Tag = 3
      AutoCheck = True
      Caption = 'Pocket'
      GroupIndex = 1
      OnClick = pu_RadioClick
    end
    object Drill1: TMenuItem
      Caption = 'Drill'
      GroupIndex = 2
      OnClick = pu_RadioClick
    end
  end
end
