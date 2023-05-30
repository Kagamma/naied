unit Screen;

{$I naied.inc}

interface

uses
  Memory, Globals;

var
  ScreenWidth  : Byte = 80;
  ScreenHeight : Byte = 50;
  ScreenPointer: PWord;
  Offset       : Word = 0;
  CursorX      : ShortInt = 0;
  CursorY      : ShortInt = 1;
  AttrStatus   : Word = $1700;
  AttrNormal   : Word = $0700;
  AttrHighlight: Word = $0E00;
  AttrTrailing : Word = $4700;
  AttrSelect   : Word = $7000;

procedure SetMode80x50;
procedure SetMode80x25;
procedure SetCursorPosition(const X, Y: Byte);
function RenderTextAtLeft(const X, Y: Byte; const S: String): Byte;
function RenderTextAtRight(const X, Y: Byte; const S: String): Byte;
procedure RenderStatusBarBlank;
procedure RenderStatusBar;
procedure RenderStatusMode;
procedure RenderStatusCursor;
procedure RenderStatusFile;
procedure RenderEdit;
procedure Render;

implementation

uses
  Editor;

var
  OldStatusCursorPosition: Byte = 0;

procedure SetMode80x50;
begin
  asm
    mov ax,$1112
    xor bl,bl
    int $10
  end;
  ScreenWidth := 80;
  ScreenHeight := 50;
end;

procedure SetMode80x25;
begin
  asm
    mov ax,$0003
    xor bl,bl
    int $10
  end;
  ScreenWidth := 80;
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
  I: Integer;
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

procedure RenderEdit;
var
  I, J, K, L: Word;
  P: PMemoryBlock;
  TrailingSpacePos: Word;
  Attr: Word;
  C: Char;
  SelStartRow,
  SelEndRow: Byte;
begin
  // Check for selection
  if SelStart <> nil then
  begin
    GetActualSel;
    P := Memory.View;
    SelStartRow := 0;
    SelEndRow := ScreenHeight;
    for I := 1 to ScreenHeight - 1 do
    begin
      if P = ActualSelStart then
        SelStartRow := I;
      if P = ActualSelEnd then
        SelEndRow := I;
      P := P^.Next;
    end;
  end;
  //
  P := Memory.View;
  for J := 1 to ScreenHeight - 1 do
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
    for I := 0 to ScreenWidth - 1 do
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

procedure Render;
begin
  FillWord(ScreenPointer[0], ScreenWidth * ScreenHeight, AttrNormal);
  SetCursorPosition(CursorX, CursorY);
  RenderStatusBar;
  RenderEdit;
end;

initialization
  ScreenPointer := Ptr($B800, $0000);

end.

