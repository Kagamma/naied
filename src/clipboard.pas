unit Clipboard;

{$I naied.inc}

interface

uses
  Memory;

const
  CLIPBOARD_SIZE = 1024 * 32;

var
  ClipboardPtr: PChar;
  ClipboardSize: Word = 0;

procedure CopyBlock;
procedure PasteBlock;

implementation

uses
  Globals,
  Editor;

function CheckWinClipboard: Boolean; assembler; nostackframe;
asm
  mov ax,$1700
  int $2F
  xor bx,bx
  cmp ax,$1700
  je  @Nope
  inc bx
@Nope:
  mov ax,bx
end;

procedure OpenWinClipboard; assembler; nostackframe;
asm
  mov ax,$1701
  int $2F
end;

procedure CloseWinClipboard; assembler; nostackframe;
asm
  mov ax,$1708
  int $2F
end;

procedure ClearWinClipboard; assembler; nostackframe;
asm
  mov ax,$1708
  int $2F
end;

function GetWinClipboardSize: DWord; assembler; nostackframe;
asm
  mov ax,$1704
  mov dx,1
  int $2F
end;

procedure GetWinClipboardData(const P: Pointer); assembler;
asm
  push es
  les bx,P
  mov dx,1
  mov ax,$1705
  int $2F
  pop es
end;

procedure SetWinClipboardData(const P: Pointer; const Size: Word); assembler;
asm
  push es
  push si
  les bx,P
  mov cx,Size
  mov dx,1
  xor si,si
  mov ax,$1703
  int $2F
  pop si
  pop es
end;

procedure CopyBlock;
var
  I: Word;
  P: PMemoryBlock;
begin
  if SelStart = nil then
    Exit;
  ClipboardSize := 0;
  if ActualSelStart = ActualSelEnd then
  begin
    for I := ActualSelStartIndex + 1 to Min(Length(ActualSelEnd^.Text), ActualSelEndIndex) do
    begin
      ClipboardPtr[ClipboardSize] := ActualSelStart^.Text[I];
      Inc(ClipboardSize);
      if ClipboardSize > CLIPBOARD_SIZE then
        Exit;
    end;
  end else
  begin
    for I := ActualSelStartIndex + 1 to Length(ActualSelStart^.Text) do
    begin
      ClipboardPtr[ClipboardSize] := ActualSelStart^.Text[I];
      Inc(ClipboardSize);
      if ClipboardSize > CLIPBOARD_SIZE then
        Exit;
    end;
    P := ActualSelStart^.Next;
    while P <> ActualSelEnd do
    begin
      ClipboardPtr[ClipboardSize] := #10;
      if ClipboardSize + 1 + Length(P^.Text) > CLIPBOARD_SIZE then
        Exit;
      Inc(ClipboardSize);
      Move(P^.Text[1], ClipboardPtr[ClipboardSize], Length(P^.Text));
      Inc(ClipboardSize, Length(P^.Text));
      P := P^.Next;
    end;
    ClipboardPtr[ClipboardSize] := #10;
    Inc(ClipboardSize);
    if ClipboardSize > CLIPBOARD_SIZE then
      Exit;
    for I := 1 to Min(Length(ActualSelEnd^.Text), ActualSelEndIndex) do
    begin
      ClipboardPtr[ClipboardSize] := ActualSelEnd^.Text[I];
      Inc(ClipboardSize);
      if ClipboardSize > CLIPBOARD_SIZE then
        Exit;
    end;
  end;
  if CheckWinClipboard then
  begin
    OpenWinClipboard;
    ClearWinClipboard;
    SetWinClipboardData(ClipboardPtr, ClipboardSize + 1);
    CloseWinClipboard;
  end;
end;

procedure PasteBlock;
var
  I: Integer;
  C: Char;
  WCBSize: DWord;
begin
  if ClipboardSize = 0 then
    Exit;
  if CheckWinClipboard then
  begin
    OpenWinClipboard;
    WCBSize := GetWinClipboardSize;
    if WCBSize > CLIPBOARD_SIZE then
    begin
      CloseWinClipboard;
    end else
    begin
      ClipboardSize := WCBSize - 1;
      GetWinClipboardData(ClipboardPtr);
      CloseWinClipboard;
    end;
  end;
  for I := 0 to ClipboardSize - 1 do
  begin
    C := ClipboardPtr[I];
    if C = #10 then
      Editor.HandleEnter
    else
      Editor.HandleInsert(C);
  end;
end;

initialization
  ClipboardPtr := GetMem(CLIPBOARD_SIZE);

end.

