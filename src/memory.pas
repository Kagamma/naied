unit Memory;

{$I naied.inc}

interface

const
  MEMORY_TEXT_SIZE = 16384;

type
  PMemoryBlock = ^TMemoryBlock;
  TMemoryBlock = record
    Prev, Next: PMemoryBlock;
    Text      : String;
  end;

var
  TransferBlock: Pointer;
  XMSBlockCount: Word = 0;
  Total        : DWord = 0;
  View, Current,
  First, Last  : PMemoryBlock;

function CreateNode: PMemoryBlock;
procedure Insert(const L, M: PMemoryBlock);
procedure Append(const R: PMemoryBlock);
procedure Delete(const L: PMemoryBlock);
procedure Split(const M: PMemoryBlock; const StrIndex: Word);
procedure Merge(const M: PMemoryBlock; const StrIndex: Word);
procedure Init;
procedure Free;
procedure AdjustTextSize(const M: PMemoryBlock; NewSize: Word);

implementation

procedure Init;
begin
  if First <> nil then
    Free;
  First := CreateNode;
  Last := First;
  Current := First;
  View := First;
  Total := 1;
end;

procedure Free;
var
  P: PMemoryBlock;
begin
  P := First;
  while P <> nil do
  begin
    Dispose(P);
    P := P^.Next;
  end;
  First := nil;
  Last := nil;
end;

function CreateNode: PMemoryBlock;
begin
  New(Result);
  Result^.Prev := nil;
  Result^.Next := nil;
end;

procedure Insert(const L, M: PMemoryBlock);
var
  R: PMemoryBlock;
begin
  R := L^.Next;
  L^.Next := M;
  M^.Prev := L;
  M^.Next := R;
  if R <> nil then
    R^.Prev := M
  else
    Last := M;
  Inc(Total);
end;

procedure Append(const R: PMemoryBlock);
var
  L: PMemoryBlock;
begin
  L := Last;
  Last := R;
  L^.Next := Last;
  Last^.Prev := L;
  Inc(Total);
end;

procedure Delete(const L: PMemoryBlock);
var
  P, N: PMemoryBlock;
begin
  // Do not delete root
  if (L^.Prev = nil) and (L^.Next = nil) then
    Exit;
  P := L^.Prev;
  N := L^.Next;
  if P <> nil then
    P^.Next := N
  else
    First := P;
  if N <> nil then
    N^.Prev := P
  else
    Last := N;
  Dispose(L);
  Dec(Total);
end;

procedure Split(const M: PMemoryBlock; const StrIndex: Word);
var
  R: PMemoryBlock;
  Size: Word;
begin
  R := CreateNode;
  Size := Length(M^.Text);
  Insert(M, R);
  if StrIndex <= 1 then
  begin
    R^.Text := M^.Text;
    M^.Text := '';
  end else
  if StrIndex <= Size then
  begin
    SetLength(R^.Text, Size - StrIndex + 1);
    Move(M^.Text[StrIndex], R^.Text[1], Length(R^.Text));
    SetLength(M^.Text, StrIndex - 1);
  end;
end;

procedure Merge(const M: PMemoryBlock; const StrIndex: Word);
var
  R: PMemoryBlock;
begin
  R := M^.Next;
  if R <> nil then
  begin
    if StrIndex > Length(M^.Text) then
      AdjustTextSize(M, StrIndex - 1);
    M^.Text := M^.Text + R^.Text;
    Delete(R);
  end;
end;

procedure AdjustTextSize(const M: PMemoryBlock; NewSize: Word);
var
  Size, I: Word;
begin
  Size := Length(M^.Text);
  if NewSize > Size then
  begin
    SetLength(M^.Text, NewSize);
    for I := Size + 1 to NewSize do
      M^.Text[I] := ' ';
  end;
end;

initialization
  Init;

finalization
  Free;

end.

