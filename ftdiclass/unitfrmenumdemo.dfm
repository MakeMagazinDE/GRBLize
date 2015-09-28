object frmenumdemo: Tfrmenumdemo
  Left = 717
  Top = 771
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'ftdiclass enumeration demo'
  ClientHeight = 203
  ClientWidth = 529
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 168
    Width = 254
    Height = 13
    Caption = 'Double click on a device for more information about it.'
  end
  object ListBox: TListBox
    Left = 8
    Top = 8
    Width = 513
    Height = 153
    ItemHeight = 13
    TabOrder = 0
    OnDblClick = ListBoxDblClick
  end
  object Timer1: TTimer
    Interval = 2500
    OnTimer = Timer1Timer
    Left = 304
    Top = 168
  end
end
