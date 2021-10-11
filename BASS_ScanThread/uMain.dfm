object Form1: TForm1
  Left = 224
  Top = 124
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 
    'BASS ScanThread (left click = start; right click = finish; middl' +
    'e = position)'
  ClientHeight = 578
  ClientWidth = 625
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 120
  TextHeight = 16
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 45
    Height = 16
    Caption = 'Song 1:'
  end
  object Label2: TLabel
    Left = 8
    Top = 264
    Width = 45
    Height = 16
    Caption = 'Song 2:'
  end
  object btLoadSong1: TButton
    Left = 8
    Top = 32
    Width = 105
    Height = 25
    Caption = 'Load'
    TabOrder = 0
    OnClick = btLoadSong1Click
  end
  object btLoadSong2: TButton
    Left = 8
    Top = 288
    Width = 105
    Height = 25
    Caption = 'Load'
    TabOrder = 1
    OnClick = btLoadSong2Click
  end
  object panColBack: TPanel
    Left = 424
    Top = 8
    Width = 193
    Height = 25
    Caption = 'Background Color'
    TabOrder = 2
    OnClick = PanColorClick
  end
  object panColPeak: TPanel
    Left = 424
    Top = 40
    Width = 193
    Height = 25
    Caption = 'Peak Color'
    TabOrder = 3
    OnClick = PanColorClick
  end
  object panColBorder: TPanel
    Left = 424
    Top = 72
    Width = 193
    Height = 25
    Caption = 'Border Color'
    TabOrder = 4
    OnClick = PanColorClick
  end
  object panColLoopS: TPanel
    Left = 424
    Top = 104
    Width = 193
    Height = 25
    Caption = 'Loop Start Color'
    TabOrder = 5
    OnClick = PanColorClick
  end
  object panColLoopE: TPanel
    Left = 424
    Top = 136
    Width = 193
    Height = 25
    Caption = 'Loop End Color'
    TabOrder = 6
    OnClick = PanColorClick
  end
  object panColPos: TPanel
    Left = 424
    Top = 168
    Width = 193
    Height = 25
    Caption = 'Position Color'
    TabOrder = 7
    OnClick = PanColorClick
  end
  object panColText: TPanel
    Left = 424
    Top = 200
    Width = 193
    Height = 25
    Caption = 'Text Color'
    TabOrder = 8
    OnClick = PanColorClick
  end
  object ColorDialog1: TColorDialog
    Left = 152
    Top = 8
  end
  object OpenDialog1: TOpenDialog
    Left = 120
    Top = 8
  end
end
