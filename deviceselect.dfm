object deviceselectbox: Tdeviceselectbox
  Left = 243
  Top = 108
  BorderStyle = bsDialog
  Caption = 'Select Device'
  ClientHeight = 249
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
  TextHeight = 16
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 505
    Height = 249
    Caption = 'Panel1'
    TabOrder = 0
    object Label3: TLabel
      Left = 10
      Top = 218
      Width = 72
      Height = 19
      Caption = 'baud rate'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object OKButton: TButton
      Left = 415
      Top = 214
      Width = 80
      Height = 28
      Caption = 'OK'
      Default = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = OKButtonClick
      IsControl = True
    end
    object ListView1: TListView
      Left = 10
      Top = 8
      Width = 485
      Height = 196
      Columns = <
        item
          Caption = 'Device'
          Width = 100
        end
        item
          Caption = 'FTDI Serial'
          Width = 120
        end
        item
          Caption = 'Description'
          Width = 260
        end>
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
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
      Left = 326
      Top = 214
      Width = 80
      Height = 28
      Caption = 'Cancel'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = CancelButtonClick
      IsControl = True
    end
    object EditBaudrate: TComboBox
      Left = 108
      Top = 214
      Width = 145
      Height = 28
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      Text = 'EditBaudrate'
      Items.Strings = (
        '9600'
        '19200'
        '38400'
        '57600'
        '115200')
    end
  end
end
