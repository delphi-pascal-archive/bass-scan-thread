unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, Bass, uScanThread, ExtCtrls, StdCtrls;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    btLoadSong1: TButton;
    Label2: TLabel;
    btLoadSong2: TButton;
    ColorDialog1: TColorDialog;
    panColBack: TPanel;
    panColPeak: TPanel;
    panColBorder: TPanel;
    panColLoopS: TPanel;
    panColLoopE: TPanel;
    panColPos: TPanel;
    panColText: TPanel;
    OpenDialog1: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure btLoadSong2Click(Sender: TObject);
    procedure btLoadSong1Click(Sender: TObject);
    procedure PanColorClick(Sender: TObject);
  private
    chan1,chan2,chan1Decode,chan2Decode : HSTREAM;
    ScanThreadChan1,ScanThreadChan2 : TScanThread;
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;
  PATH : String;
implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  PATH := ExtractFilePath(Application.ExeName);

  // on init bass avec le device par defaut
  if not BASS_Init(-1,44100,0,Handle,nil) then begin
    Application.MessageBox('Init BASS Failure','Error',MB_OK);
    halt;
  end;
  // on charge le son 2
  panColBack.Tag := 0;
  panColPeak.Tag := 1;
  panColBorder.Tag := 2;
  panColLoopS.Tag := 3;
  panColLoopE.Tag := 4;
  panColPos.Tag := 5;
  panColText.Tag := 6;
end;

procedure TForm1.btLoadSong2Click(Sender: TObject);
begin
  if OpenDialog1.Execute then begin
    // libère les ressources
    if chan2<>0 then begin
      BASS_StreamFree(chan2);
      BASS_StreamFree(chan2Decode);
      ScanThreadChan2.Free
    end;

    chan2 := BASS_StreamCreateFile(false,PChar(OpenDialog1.FileName),0,0,BASS_SAMPLE_LOOP);
    BASS_ChannelPlay(chan2,TRUE);

    chan2Decode := BASS_StreamCreateFile(false,PChar(OpenDialog1.FileName),0,0,BASS_STREAM_DECODE);
    ScanThreadChan2 := TScanThread.Create(chan2Decode,chan2,Form1,Form1,16,328,593,241);
  end;
end;

procedure TForm1.btLoadSong1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then begin
    // libère les ressources
    if chan1<>0 then begin
      BASS_StreamFree(chan1);
      BASS_StreamFree(chan1Decode);
      ScanThreadChan1.Free
    end;

    chan1 := BASS_StreamCreateFile(false,PChar(OpenDialog1.FileName),0,0,BASS_SAMPLE_LOOP);
    BASS_ChannelPlay(chan1,TRUE);
    // on créé une channel "décodé"
    chan1Decode := BASS_StreamCreateFile(false,PChar(OpenDialog1.FileName),0,0,BASS_STREAM_DECODE);
    ScanThreadChan1 := TScanThread.Create(chan1Decode,chan1,Form1,Form1,16,72,400,185);
  end;
end;

procedure TForm1.PanColorClick(Sender: TObject);
begin
  if ColorDialog1.Execute then begin
    TPanel(Sender).Color := ColorDialog1.Color;
  case TPanel(Sender).Tag of
    0: ScanThreadChan1.BackColor := TPanel(Sender).Color;
    1: ScanThreadChan1.PeakColor := TPanel(Sender).Color;
    2: ScanThreadChan1.BorderColor := TPanel(Sender).Color;
    3: ScanThreadChan1.LoopStartColor := TPanel(Sender).Color;
    4: ScanThreadChan1.LoopEndColor := TPanel(Sender).Color;
    5: ScanThreadChan1.PositionColor := TPanel(Sender).Color;
    6: ScanThreadChan1.TextColor := TPanel(Sender).Color;
  end;
end;
end;

end.
