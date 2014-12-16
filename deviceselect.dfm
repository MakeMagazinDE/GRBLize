object deviceselectbox: Tdeviceselectbox
  Left = 243
  Top = 108
  BorderStyle = bsDialog
  Caption = 'USB Device'
  ClientHeight = 217
  ClientWidth = 505
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 505
    Height = 217
    Caption = 'Panel1'
    TabOrder = 0
    object Label1: TLabel
      Left = 24
      Top = 16
      Width = 217
      Height = 16
      Caption = 'Select FTDI Cable or  FT232R device:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
    object OKButton: TButton
      Left = 407
      Top = 182
      Width = 65
      Height = 23
      Caption = 'OK'
      Default = True
      TabOrder = 0
      OnClick = OKButtonClick
      IsControl = True
    end
    object ListView1: TListView
      Left = 18
      Top = 40
      Width = 463
      Height = 129
      Columns = <
        item
          Caption = 'USB Device'
          Width = 100
        end
        item
          Caption = 'FTDI Serial'
          Width = 100
        end
        item
          Caption = 'Description'
          Width = 250
        end>
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ReadOnly = True
      RowSelect = True
      ParentFont = False
      ShowWorkAreas = True
      TabOrder = 1
      ViewStyle = vsReport
      OnDblClick = ListView1DblClick
    end
    object CancelButton: TButton
      Left = 327
      Top = 180
      Width = 65
      Height = 25
      Caption = 'Cancel'
      TabOrder = 2
      OnClick = CancelButtonClick
      IsControl = True
    end
  end
end
