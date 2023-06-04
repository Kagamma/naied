{ ref: https://www.phatcode.net/res/219/files/xms30.txt }

unit XMS;

{$I naied.inc}

interface

const
  PAGE_SIZE = 65536;
  BLOCK_SIZE = PAGE_SIZE * 8;
  BLOCK_SIZE_IN_KB = BLOCK_SIZE div 1024;
  PAGE_COUNT = BLOCK_SIZE div PAGE_SIZE;

type
  TXMSMemoryInfo = packed record
    case Byte of
      0: (
        FreeMem : Word;
        TotalMem: Word;
      );
      1: (
        Data: DWord;
      );
  end;

  TXMSMemoryBlock = packed record
    case Byte of
      0: (
        Allocated: Boolean;
        Error    : Byte;
        Handle   : Word;
      );
      1: (
        Data: DWord;
      )
  end;

  TXMSMemoryTransfer = packed record
    Size     : DWord;
    SrcHandle: Word;
    SrcOffset: Pointer;
    DstHandle: Word;
    DstOffset: Pointer;
  end;

  TXMSCopyDirection = (cpXMS2MEM, cpMEM2XMS);

var
  XMSAvail         : Boolean = False;
  XMSHandler       : Pointer;
  XMSMemoryTransfer: TXMSMemoryTransfer;

function CheckDriver: Boolean;
function QueryFreeExtendedMemory: DWord;
function Alloc: DWord;
procedure Free(const Handle: Word); assembler;
procedure Copy(const Handle: Word; const Buf: Pointer; const Page: Byte; const Direction: TXMSCopyDirection);
procedure PrintInfo;

implementation

function CheckDriver: Boolean; assembler; nostackframe;
asm
  mov ax,$4300
  int $2F
  cmp al,$80
  je  @Ok
  xor al, al
@Ok:
end;

procedure GetHandler; assembler; nostackframe;
asm
  mov ax,$4310
  int $2F
  mov word [XMSHandler    ],bx
  mov word [XMSHandler + 2],es
end;

function GetVersion: Word; assembler; nostackframe;
asm
  mov ah,$00
  call [XMSHandler]
end;

function QueryFreeExtendedMemory: DWord; assembler; nostackframe;
asm
  mov ah,$08
  call [XMSHandler]
end;

function Alloc: DWord; assembler; nostackframe;
asm
  mov ah,$09
  mov dx,BLOCK_SIZE_IN_KB
  call [XMSHandler]
  mov ah,bl
end;

procedure Free(const Handle: Word); assembler;
asm
  mov ah,$0A
  mov dx,Handle
  call [XMSHandler]
end;

procedure Copy(const Handle: Word; const Buf: Pointer; const Page: Byte; const Direction: TXMSCopyDirection);
begin
  FillChar(XMSMemoryTransfer, SizeOf(TXMSMemoryTransfer), 0);
  XMSMemoryTransfer.Size := PAGE_SIZE;
  case Direction of
    cpMEM2XMS:
      begin
        XMSMemoryTransfer.SrcOffset := Buf;
        XMSMemoryTransfer.DstHandle := Handle;
        XMSMemoryTransfer.DstOffset := Pointer(PAGE_SIZE * Page);
      end;
    cpXMS2MEM:
      begin
        XMSMemoryTransfer.SrcHandle := Handle;
        XMSMemoryTransfer.SrcOffset := Pointer(PAGE_SIZE * Page);
        XMSMemoryTransfer.DstOffset := Buf;
      end;
  end;
  asm
    mov ah,$0B
    mov si,offset XMSMemoryTransfer
    call [XMSHandler]
  end;
end;

procedure PrintInfo;
var
  XMSInfo: TXMSMemoryInfo;
begin
  XMSInfo.Data := QueryFreeExtendedMemory;
  Writeln('XMS Memory Info');
  Writeln('- Free: ', XMSInfo.FreeMem);
  Writeln('- Total: ', XMSInfo.TotalMem);
end;

initialization
  if CheckDriver then
  begin
    XMSAvail := True;
    GetHandler;
  end;

end.

