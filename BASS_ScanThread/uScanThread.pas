unit uScanThread;

interface

uses
  Windows, Dialogs, Forms, Controls, StdCtrls, Classes, ExtCtrls,SysUtils,Graphics,bass;

 type TSpectrumColor = record
   ColorLoopStart,ColorLoopEnd,ColorPosition : TColor;
   ColorBack,ColorBorder,ColorPeak : TColor;
   ColorText : TColor;
 end;

type TScanThread = class(TThread)
  private
    fPaintBox : TPaintBox;
    fdecoder : DWORD; // la channel "decode" -> GetLevel
    fChannel : DWORD; // la channel en cours -> Position ...
    fKillscan : boolean; // quand arreter le scan , utile si il faut re-scanner
    fBPP : DWORD; // relation Temps sur TailleX
    wavebufL : array of smallint; // tableaux de levels gauche
    wavebufR : array of smallint; //droit
    fWidth,fHeight:integer; // taille en X et Y
    fBufferBitmap : TBitmap; // le bitmap ou on va dessiner desus
    fNbLoopSync : DWORD; // indice pr la procedure LoopSyncProc
    fSpectrumColor : TSpectrumColor;
    fLoopStart,fLoopEnd,fPosition : DWORD; // position de fin , début et en cours
    fNeedRedraw : boolean;// utile pr savoir si il faut redessiner

    procedure SetBackColor (AColor : TColor);
    procedure SetBorderColor (AColor : TColor);
    procedure SetPeakColor (AColor : TColor);
    procedure SetLoopStartColor (AColor : TColor);
    procedure SetLoopEndColor (AColor : TColor);
    procedure SetPositionColor (AColor : TColor);
    procedure SetTextColor (AColor : TColor);

    procedure ScanPeaks; // on recupère les Levels
    procedure draw_Spectrum; // on dessiner dans le Bitmap
    procedure ThreadProcedure; // fonction principal

  protected
    // Les <> méthodes relatives au TPaintBox : Paint , onMouseDown , onMouseMove
    procedure PaintBoxPaint(Sender: TObject);

    procedure PaintBoxMouseDown(Sender: TObject;Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer);

    procedure PaintBoxMouseMove(Sender: TObject;
    Shift: TShiftState; X, Y: Integer);

    procedure Execute; override;
  public
    property BPP:DWORD read fBPP;
    property LoopStart : DWORD read fLoopStart write fLoopStart;
    property LoopEnd : DWORD read fLoopEnd write fLoopEnd;
    property Position : DWORD read fPosition write fPosition;

    property BackColor : TColor write SetBackColor;
    property BorderColor : TColor write SetBorderColor;
    property PeakColor : TColor write SetPeakColor;
    property LoopStartColor : TColor write SetLoopStartColor;
    property LoopEndColor : TColor write SetLoopEndColor;
    property PositionColor : TColor write SetPositionColor;
    property TextColor : TColor write SetTextColor;

    procedure ReDraw;
    procedure ReScan;

    property SpectrumColor : TSpectrumColor read fSpectrumColor write fSpectrumColor;
    constructor Create(ADecoder:DWORD;AChannel:DWORD;AOwner : TComponent;AParent : TWinControl;ALeft,ATop,AWidth,AHeight : DWORD);
    destructor Destroy;override;
end;

procedure LoopSyncProc(handle: HSYNC; channel, data: DWORD; user: Pointer); stdcall;

var
  NbLoopSync : DWORD =0 ;
  GlobalLoopStart : array[0..1000]of DWORD;
  fLoopSync : array[0..1000]of HSYNC;

implementation

procedure LoopSyncProc(handle: HSYNC; channel, data: DWORD; user: Pointer); stdcall;
var
  i : integer;
begin
  for i:=0 to NbLoopSync do begin
    if handle = fLoopSync[i] then begin
      if not BASS_ChannelSetPosition(channel,GlobalLoopStart[i],BASS_POS_BYTE) then BASS_ChannelSetPosition(channel,0,BASS_POS_BYTE);
    end;
  end;
end;
//------------------------------------------------------------------------------

{ TScanThread }

constructor TScanThread.Create(ADecoder:DWORD;AChannel:DWORD;AOwner : TComponent;AParent : TWinControl;ALeft,ATop,AWidth,AHeight : DWORD);
begin
  inherited create(false);
  if NbLoopSync>=1000 then NbLoopSync:=0;
  fNeedRedraw:=True;
  fNbLoopSync:=NbLoopSync;
  fBufferBitmap := TBitmap.Create;
  fLoopEnd:=0;
  fLoopStart:=0;
  GlobalLoopStart[fNbLoopSync]:=fLoopStart;

  with fSpectrumColor do begin
    ColorLoopStart := ClBlue;
    ColorLoopEnd := ClRed;
    ColorPosition := ClWhite;
    ColorBack  := ClBlack;
    ColorBorder  := ClGray;
    ColorPeak  := ClLime;
    ColorText := ClWhite;
  end;

  fKillscan := false;

  fPaintBox := TPaintBox.Create(AOwner);
  fPaintBox.Parent := AParent;
  fPaintBox.Parent.DoubleBuffered:=True;
  fPaintBox.Width := AWidth;
  fPaintBox.Height := AHeight;
  fPaintBox.Left:=ALeft;
  fPaintBox.Top := ATop;


  fWidth:=fPaintBox.Canvas.ClipRect.Right;
  fHeight:=fPaintBox.Canvas.ClipRect.Bottom;

  fBufferBitmap.Width:=fWidth;
  fBufferBitmap.Height:=fHeight;

  fDecoder := ADecoder;

  fBPP :=BASS_ChannelGetLength(ADecoder,BASS_POS_BYTE) div fWidth;
  if (fbpp < BASS_ChannelSeconds2Bytes(ADecoder,0.02)) then // minimum 20ms per pixel (BASS_ChannelGetLevel scans 20ms)
      fbpp := BASS_ChannelSeconds2Bytes(ADecoder,0.02);

  SetLength(wavebufL,fWidth);
  SetLength(wavebufR,fWidth);

  Priority := tpNormal;
  FreeOnTerminate := false;

  fChannel := AChannel;
  fLoopSync[fNbLoopSync]:= BASS_ChannelSetSync(fChannel,BASS_SYNC_POS or BASS_SYNC_MIXTIME,fLoopEnd,LoopSyncProc,nil);
  NbLoopSync:=NbLoopSync+1;
end;

procedure TScanThread.ReDraw;
begin
  fNeedRedraw := true;
end;

procedure TScanThread.ReScan;
begin
  fkillscan:=false;
end;

procedure TScanThread.SetBackColor (AColor : TColor);
begin
  fSpectrumColor.ColorBack := AColor;
  ReDraw;
end;
procedure TScanThread.SetBorderColor (AColor : TColor);
begin
  fSpectrumColor.ColorBorder := AColor;
  ReDraw;
end;
procedure TScanThread.SetPeakColor (AColor : TColor);
begin
  fSpectrumColor.ColorPeak := AColor;
  ReDraw;
end;
procedure TScanThread.SetLoopStartColor (AColor : TColor);
begin
  fSpectrumColor.ColorLoopStart := AColor;
  ReDraw;
end;
procedure TScanThread.SetLoopEndColor (AColor : TColor);
begin
  fSpectrumColor.ColorLoopEnd := AColor;
  ReDraw;
end;
procedure TScanThread.SetPositionColor (AColor : TColor);
begin
  fSpectrumColor.ColorPosition := AColor;
  ReDraw;
end;
procedure TScanThread.SetTextColor (AColor : TColor);
begin
  fSpectrumColor.ColorText := AColor;
  ReDraw;
end;

destructor TScanThread.Destroy;
begin
  //NbLoopSync:=NbLoopSync-1;
  fKillScan:=true;
  fBufferBitmap.Free;
  fPaintBox.Free;
  inherited Destroy;
end;

procedure TScanThread.PaintBoxPaint(Sender: TObject);
begin
  fPaintBox.Canvas.Draw(0,0,fBufferBitmap);

  fPaintBox.Canvas.Pen.Color:=fSpectrumColor.ColorLoopStart;
  fPaintBox.Canvas.MoveTo(fLoopStart div fBPP,0);
  fPaintBox.Canvas.LineTo(fLoopStart div fBPP,fHeight);

  fPaintBox.Canvas.Pen.Color:=fSpectrumColor.ColorLoopEnd;
  fPaintBox.Canvas.MoveTo(fLoopEnd div fBPP,0);
  fPaintBox.Canvas.LineTo(fLoopEnd div fBPP,fHeight);

  fPaintBox.Canvas.Pen.Color:=fSpectrumColor.ColorPosition;
  fPaintBox.Canvas.MoveTo(fPosition div fBPP,0);
  fPaintBox.Canvas.LineTo(fPosition div fBPP,fHeight);

  fPaintBox.Canvas.Font.Color := fSpectrumColor.ColorText;
  fPaintBox.Canvas.Brush.Color:=fSpectrumColor.ColorBack;
  fPaintBox.Canvas.TextOut((fLoopStart div fBPP)+7,12,IntToStr(Round(BASS_ChannelBytes2Seconds(fDecoder,fLoopStart))));
  fPaintBox.Canvas.TextOut((fLoopEnd div fBPP)+7,12,IntToStr(Round(BASS_ChannelBytes2Seconds(fDecoder,fLoopEnd))));
  fPaintBox.Canvas.TextOut((fPosition div fBPP)+7,12,IntToStr(Round(BASS_ChannelBytes2Seconds(fDecoder,fPosition))));
end;

procedure TScanThread.PaintBoxMouseDown(Sender: TObject;Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer);
begin
  if ssLeft in shift then begin
    fLoopStart :=DWORD(X)*fBPP;
    GlobalLoopStart[fNbLoopSync]:=fLoopStart;
  end else if ssRight in shift then begin
    fLoopEnd :=DWORD(X)*fBPP;
    BASS_ChannelRemoveSync(fChannel,fLoopSync[fNbLoopSync]); // remove old sync
    fLoopSync[fNbLoopSync]:= BASS_ChannelSetSync(fChannel,BASS_SYNC_POS or BASS_SYNC_MIXTIME,fLoopEnd,LoopSyncProc,nil);
   // set new sync
  end else if ssMiddle in shift then
    BASS_ChannelSetPosition(fChannel,DWORD(X)*fBPP,BASS_POS_BYTE);
end;

procedure TScanThread.PaintBoxMouseMove(Sender: TObject;
    Shift: TShiftState; X, Y: Integer);
begin
  if ssLeft in shift then begin
    fLoopStart :=DWORD(X)*fBPP;
    GlobalLoopStart[fNbLoopSync]:=fLoopStart;
  end else if ssRight in shift then begin
    fLoopEnd :=DWORD(X)*fBPP;
    BASS_ChannelRemoveSync(fChannel,fLoopSync[fNbLoopSync]); // remove old sync
    fLoopSync[fNbLoopSync]:= BASS_ChannelSetSync(fChannel,BASS_SYNC_POS or BASS_SYNC_MIXTIME,fLoopEnd,LoopSyncProc,nil);
   // set new sync
  end else if ssMiddle in shift then
    BASS_ChannelSetPosition(fChannel,DWORD(X)*fBPP,BASS_POS_BYTE);
end;

procedure TScanThread.Execute;
begin
  ScanPeaks;
  fPaintBox.OnPaint := PaintBoxPaint;
  fPaintBox.OnMouseDown:=PaintBoxMouseDown;
  fPaintBox.OnMouseMove:= PaintBoxMouseMove;
  repeat
    synchronize(ThreadProcedure);
    sleep(20);
  until Terminated;
end;

procedure TScanThread.ThreadProcedure;
begin
  //ScanPeaks ; //-> normalement inutile , car déjà scanné
  if fNeedRedraw then Draw_Spectrum;
  fPosition:=BASS_ChannelGetPosition(fChannel,BASS_POS_BYTE);
  fPaintBox.Invalidate;
end;

procedure TScanThread.Draw_Spectrum;
var
  i,ht : integer;
begin
  //clear background
  fBufferBitmap.Canvas.Brush.Color := fSpectrumColor.ColorBack;
  fBufferBitmap.Canvas.FillRect(Rect(0,0,fBufferBitmap.Width,fBufferBitmap.Height));

  fBufferBitmap.Canvas.Pen.Color := fSpectrumColor.ColorBorder;
  fBufferBitmap.Canvas.Rectangle(1,0,fBufferBitmap.Width,fBufferBitmap.Canvas.ClipRect.Bottom);

  //draw peaks
  ht := fHeight div 2;
  for i:=0 to length(wavebufL)-1 do
  begin
    fBufferBitmap.Canvas.MoveTo(i,ht);
	  fBufferBitmap.Canvas.Pen.Color := fSpectrumColor.ColorPeak;
    fBufferBitmap.Canvas.LineTo(i,ht-trunc((wavebufL[i]/32768)*ht));

    fBufferBitmap.Canvas.Pen.Color := fSpectrumColor.ColorPeak;
    fBufferBitmap.Canvas.MoveTo(i,ht+2);
	  fBufferBitmap.Canvas.LineTo(i,ht+2+trunc((wavebufR[i]/32768)*ht));
  end;
  fNeedRedraw:=false;
end;

procedure TScanThread.ScanPeaks;
var
  cpos,level : DWord;
  peak : array[0..1] of DWORD;
  position : DWORD;
  counter : integer;
begin
  cpos := 0;
  peak[0] := 0;
  peak[1] := 0;
  counter := 0;

  while not fKillscan do
  begin
    level := BASS_ChannelGetLevel(fDecoder); // scan peaks

    if (peak[0]<LOWORD(level)) then
      peak[0]:=LOWORD(level); // set left peak

		if (peak[1]<HIWORD(level)) then
      peak[1]:=HIWORD(level); // set right peak

    if BASS_ChannelIsActive(fDecoder) <> BASS_ACTIVE_PLAYING then
    begin
      position := cardinal(-1); // reached the end
		end else
      position := BASS_ChannelGetPosition(fDecoder,BASS_POS_BYTE) div fBPP;

    if position > cpos then
    begin
      inc(counter);
      if counter <= length(wavebufL)-1 then
      begin
        wavebufL[counter] := peak[0];
        wavebufR[counter] := peak[1];
      end;

      if (position >= DWORD(fWidth)) then
        fKillscan:=true;

        cpos := position;
     end;
    peak[0] := 0;
    peak[1] := 0;
  end;
end;

end.
