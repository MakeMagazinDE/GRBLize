object deviceselectbox: Tdeviceselectbox
  Left = 243
  Top = 108
  BorderStyle = bsDialog
  Caption = 'Select USB Device'
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
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 505
    Height = 249
    Caption = 'Panel1'
    TabOrder = 0
    object Label1: TLabel
      Left = 18
      Top = 18
      Width = 231
      Height = 16
      Caption = 'Select FTDI Cable or FT232R device:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 18
      Top = 183
      Width = 107
      Height = 16
      Caption = 'or use serial port'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 18
      Top = 215
      Width = 128
      Height = 16
      Caption = 'FTDI/COM baud rate'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object OKButton: TButton
      Left = 416
      Top = 198
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
      Left = 345
      Top = 197
      Width = 65
      Height = 25
      Caption = 'Cancel'
      TabOrder = 2
      OnClick = CancelButtonClick
      IsControl = True
    end
    object ComboBoxComPort: TComboBox
      Left = 139
      Top = 182
      Width = 139
      Height = 21
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ItemIndex = 0
      ParentFont = False
      TabOrder = 3
      Text = 'none (FTDI direct)'
      Items.Strings = (
        'none (FTDI direct)')
    end
    object EditBaudrate: TEdit
      Left = 152
      Top = 214
      Width = 57
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
      Text = '115200'
    end
    object CheckBoxNewGRBL: TCheckBox
      Left = 225
      Top = 216
      Width = 105
      Height = 17
      Hint = 'Check if using GRBL version 0.9 and up'
      ParentCustomHint = False
      TabStop = False
      Caption = 'GRBL 0.9 and up'
      Color = clNone
      DoubleBuffered = False
      ParentColor = False
      ParentDoubleBuffered = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
      StyleElements = [seFont]
    end
  end
end
