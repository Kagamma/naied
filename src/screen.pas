unit Screen;

{$I naied.inc}

interface

uses
  Memory, Globals;

type
  TScreenMode = (sm80x25, sm80x50, sm40x25);

var
  ScreenMode   : TScreenMode = sm80x25;
  ScreenWidth  : Byte = 80;
  ScreenHeight : Byte = 25;
  ScreenPointer: PWord;
  Offset       : Word = 0;
  CursorX      : ShortInt = 0;
  CursorY      : ShortInt = 1;
  AttrStatus   : Word = $1700;
  AttrNormal   : Word = $0700;
  AttrHighlight: Word = $0E00;
  AttrTrailing : Word = $4700;
  AttrSelect   : Word = $7000;

{$ifndef NO_INT10H}
procedure SetMode80x50;
procedure SetMode80x25;
procedure SetMode40x25;
{$endif}
procedure SetCursorPosition(const X, Y: Byte);
function RenderTextAtLeft(const X, Y: Byte; const S: String): Byte;
function RenderTextAtRight(const X, Y: Byte; const S: String): Byte;
procedure RenderStatusBarBlank;
procedure RenderStatusBar;
procedure RenderStatusMode;
procedure RenderStatusCursor;
procedure RenderStatusFile;
procedure RenderEdit(const IsSingle, IsSingleLeft, IsSingleRight: Boolean);
procedure RenderEditScrollUp;
procedure RenderEditScrollDown;
procedure RenderEditScrollLeft(const IsSingleLine: Boolean);
procedure RenderEditScrollRight(const IsSingleLine: Boolean);
procedure WriteText(const X, Y, Attr: Byte; const S: String);

implementation

uses
  Editor;

var
  OldStatusCursorPosition: Byte = 0;

{$ifdef NO_INT10H}
procedure SetCursorPosition(const X, Y: Byte);
var
  P: Word;
begin
  P := Y * 80 + X;
  Port[$3D4] := $E;
  Port[$3D5] := Byte((P shr 8) and $FF);
  Port[$3D4] := $F;
  Port[$3D5] := Byte(P and $FF);
end;
{$else}
procedure SetMode80x50;
begin
  if ScreenMode = sm80x50 then
    Exit;
  asm
    mov ax,$1112
    xor bl,bl
    int $10
  end;
  ScreenMode := sm80x50;
  ScreenWidth := 80;
  ScreenHeight := 50;
end;

procedure SetMode80x25;
begin
  if ScreenMode = sm80x25 then
    Exit;
  asm
    mov ax,$0003
    xor bl,bl
    int $10
  end;
  ScreenMode := sm80x25;
  ScreenWidth := 80;
  ScreenHeight := 25;
end;

procedure SetMode40x25;
begin
  if ScreenMode = sm40x25 then
    Exit;
  asm
    xor ax,ax
    xor bl,bl
    int $10
  end;
  ScreenMode := sm40x25;
  ScreenWidth := 40;
  ScreenHeight := 25;
end;

procedure SetCursorPosition(const X, Y: Byte); assembler;
asm
  mov ah,2
  mov dh,Y
  mov dl,X
  xor bh,bh
  int $10
end;
{$endif}

function RenderTextAtLeft(const X, Y: Byte; const S: String): Byte;
var
  I, J: Byte;
begin
  J := 1;
  Result := Min(ScreenWidth - 1, X + Length(S) - 1);
  for I := X to Result do
  begin
    ScreenPointer[Y * ScreenWidth + I] := AttrStatus + Byte(S[J]);
    Inc(J);
  end;
end;

function RenderTextAtRight(const X, Y: Byte; const S: String): Byte;
var
  I, J: Byte;
begin
  J := 1;
  Result := Max(0, X - Length(S) + 1);
  for I := Result to X do
  begin
    ScreenPointer[Y * ScreenWidth + I] := AttrStatus + Byte(S[J]);
    Inc(J);
  end;
end;

procedure RenderStatusCursor;
var
  I, P: Byte;
  S: String;
begin
  P := ScreenWidth - 4;
  for I := OldStatusCursorPosition to P do
  begin
    ScreenPointer[I] := AttrStatus;
  end;
  Str(EditorY, S);
  P := RenderTextAtRight(P, 0, S) - 1;
  Str(EditorX, S);
  P := RenderTextAtRight(P, 0, S + ':') - 1;
  Str(Total, S);
  P := RenderTextAtRight(P, 0, S + ' ') - 1;
  Str(MemAvail div 1024, S);
  OldStatusCursorPosition := RenderTextAtRight(P, 0, S + 'K ') - 1;
end;

procedure RenderStatusMode;
var
  P: Byte;
  C: Char;
begin
  P := ScreenWidth - 2;
  if Modified then
    C := '*'
  else
    C := ' ';
  RenderTextAtLeft(P, 0, C + EDITOR_MODE_SYMBOL[EditorMode]);
end;

procedure RenderStatusFile;
begin
  RenderTextAtLeft(0, 0, WorkingFile);
end;

procedure RenderStatusBarBlank;
var
  I: Byte;
begin
  for I := 0 to ScreenWidth - 1 do
  begin
    ScreenPointer[I] := AttrStatus;
  end;
end;

procedure RenderStatusBar;
begin
  RenderStatusBarBlank;
  RenderStatusCursor;
  RenderStatusMode;
  RenderStatusFile;
end;
 
procedure RenderEditScrollUp;
var
  Src, Dst: PWord;
  Size: Word;
begin
  Src := ScreenPointer + ScreenWidth;
  Dst := ScreenPointer + ScreenWidth * 2;
  Size := ScreenWidth * 2;
  Move(Src[0], Dst[0], Size * (ScreenHeight - 2));
  RenderEdit(True, False, False);
end;

procedure RenderEditScrollDown;
var
  Src, Dst: PWord;
  Size, I: Word;
begin
  Src := ScreenPointer + ScreenWidth * 2;
  Dst := ScreenPointer + ScreenWidth;
  Size := ScreenWidth * 2;
  for I := 0 to ScreenHeight - 3 do
  begin
    Move(Src[I * ScreenWidth], Dst[I * ScreenWidth], Size);
  end;
  RenderEdit(True, False, False);
end;

procedure RenderEditScrollLeft(const IsSingleLine: Boolean);
var
  Src: PWord;
  Size, I: Word;
begin
  Src := ScreenPointer + ScreenWidth;
  Size := ScreenWidth * 2 - 2;
  for I := 0 to ScreenHeight - 3 do
  begin
    Move(Src[I * ScreenWidth], Src[I * ScreenWidth + 1], Size);
  end;
  RenderEdit(False, True, False); 
  if IsSingleLine then
    RenderEdit(True, False, False);
end;

procedure RenderEditScrollRight(const IsSingleLine: Boolean);
var
  Src: PWord;
  Size, I: Word;
begin
  Src := ScreenPointer + ScreenWidth;
  Size := ScreenWidth * 2 - 2;
  for I := 0 to ScreenHeight - 3 do
  begin
    Move(Src[I * ScreenWidth + 1], Src[I * ScreenWidth], Size);
  end;
  RenderEdit(False, False, True);
  if IsSingleLine then
    RenderEdit(True, False, False);
end;

procedure RenderEdit(const IsSingle, IsSingleLeft, IsSingleRight: Boolean);
var
  I, J, K, L: Word;
  P: PMemoryBlock;
  TrailingSpacePos: Word;
  Attr: Word;
  C: Char;
  Start, Finish,
  Left, Right,
  SelStartRow,
  SelEndRow: Byte;
begin
  if IsSingle then
  begin
    Start := CursorY;
    Finish := CursorY;
  end else
  begin
    Start := 1;
    Finish := ScreenHeight - 1;
  end;
  Left := 0; 
  Right := ScreenWidth - 1;
  if IsSingleLeft then
  begin
    Right := 0;
  end;
  if IsSingleRight then
  begin
    Left := Right;
  end;
  // Check for selection
  if IsSingle then
    P := Memory.Current
  else
    P := Memory.View;
  if SelStart <> nil then
  begin
    GetActualSel;
    SelStartRow := 0;
    SelEndRow := ScreenHeight;
    for I := Start to Finish do
    begin
      if P = ActualSelStart then
        SelStartRow := I;
      if P = ActualSelEnd then
        SelEndRow := I;
      P := P^.Next;
    end;
  end;
  //
  if IsSingle then
    P := Memory.Current
  else
    P := Memory.View;
  for J := Start to Finish do
  begin
    if P = nil then
    begin
      FillWord(ScreenPointer[J * ScreenWidth], ScreenWidth, AttrNormal);
      Continue;
    end;
    L := Length(P^.Text);
    if Highlight and 2 <> 0 then
    begin
      TrailingSpacePos := L + 1;
      I := L;
      while P^.Text[I] = ' ' do
      begin
        TrailingSpacePos := I;
        Dec(I);
        if I = 0 then
          Break;
      end;
    end;
    for I := Left to Right do
    begin
      K := Offset + I + 1;
      if K > L then
        ScreenPointer[J * ScreenWidth + I] := AttrNormal
      else
      begin
        C := P^.Text[K];
        if (Highlight and 2 <> 0) and (K >= TrailingSpacePos) then
          Attr := AttrTrailing
        else
        if (Highlight and 1 <> 0) and not (C in [' ', 'A'..'Z', 'a'..'z', '0'..'9']) then
          Attr := AttrHighlight
        else
          Attr := AttrNormal;
        if SelStart <> nil then
        begin
          if ((J > SelStartRow) and (J < SelEndRow)) or
             ((J = SelStartRow) and (J <> SelEndRow) and (K > ActualSelStartIndex)) or
             ((J <> SelStartRow) and (J = SelEndRow) and (K <= ActualSelEndIndex)) or
             ((J = SelStartRow) and (J = SelEndRow) and (K > ActualSelStartIndex) and (K <= ActualSelEndIndex)) then
            Attr := AttrSelect;
        end;
        ScreenPointer[J * ScreenWidth + I] := Attr + Byte(C);
      end;
    end;
    P := P^.Next;
  end;
end;

procedure WriteText(const X, Y, Attr: Byte; const S: String);
var
  I: Word;
  P: PWord;
  W: Word;
  MaxLen: Word;
begin
  MaxLen := Length(S);
  P := ScreenPointer + (80 * Y + X);
  W := Attr shl 8;
  for I := 1 to MaxLen do
  begin
    if I <= Length(S) then
      P^ := W + Byte(S[I])
    else
      P^ := W;
    Inc(P);
  end;
end;

initialization
  ScreenPointer := Ptr($B800, $0000);

finalization
  FillWord(ScreenPointer[0], ScreenWidth * ScreenHeight, $0700);
  SetCursorPosition(0, 0);

end.

