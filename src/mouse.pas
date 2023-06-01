{ ref: https://stanislavs.org/helppc/int_33.html }

unit Mouse;

{$I naied.inc}

interface

type
  PMouseInput = ^TMouseInput;
  TMouseInput = packed record
    Status, X, Y: Word;
  end;

var
  MouseAvail: Boolean = False;

function CheckMouse: Boolean;
function CheckDriver: Boolean;
procedure GetStatus(const Status: PMouseInput);
procedure Show;
procedure Hide;

implementation

function CheckMouse: Boolean; assembler; nostackframe;
asm
  xor ax,ax
  int $33
end;

function CheckDriver: Boolean; assembler; nostackframe;
asm
  mov ax,$21
  int $33
  cmp al,$FF
  je @Installed
  xor ax,ax
@Installed:
end;

procedure Show; assembler; nostackframe;
asm
  mov ax,1
  int $33
end;

procedure Hide; assembler; nostackframe;
asm
  mov ax,2
  int $33
end;

procedure GetStatus(const Status: PMouseInput); assembler;
asm
  push ds
  mov ax,3
  int $33
  lds di,Status
  mov word [di    ],bx
  mov word [di + 2],cx
  mov word [di + 4],dx
  pop ds
end;

initialization
  if CheckMouse then
    MouseAvail := True;

finalization
  if MouseAvail then
    Hide;

end.

