{ ref: https://stanislavs.org/helppc/int_16.html }

unit Keyboard;

{$I naied.inc}

interface

const
  SCAN_ESC           = $01;

  SCAN_UP            = $48;
  SCAN_DOWN          = $50;
  SCAN_LEFT          = $4B;
  SCAN_RIGHT         = $4D;

  SCAN_CTRL_LEFT     = $73;
  SCAN_CTRL_RIGHT    = $74;
  SCAN_CTRL_UP       = $8D;
  SCAN_CTRL_DOWN     = $91;

  SCAN_INS           = $52;
  SCAN_HOME          = $47;
  SCAN_PGUP          = $49;
  SCAN_DEL           = $53;
  SCAN_END           = $4F;
  SCAN_PGDN          = $51;

  SCAN_CTRL_HOME     = $77;
  SCAN_CTRL_PGUP     = $84;
  SCAN_CTRL_END      = $75;
  SCAN_CTRL_PGDN     = $76;

  SCAN_F1            = $3B;
  SCAN_F2            = $3C;
  SCAN_F3            = $3D;
  SCAN_F4            = $3E;
  SCAN_F5            = $3F;
  SCAN_F6            = $40;
  SCAN_F7            = $41;
  SCAN_F8            = $42;
  SCAN_F9            = $43;
  SCAN_F10           = $44;
  SCAN_F11           = $85;
  SCAN_F12           = $86;

  SCAN_ALT_F1        = $68;
  SCAN_ALT_F2        = $69;
  SCAN_ALT_F3        = $6A;
  SCAN_ALT_F4        = $6B;
  SCAN_ALT_F5        = $6C;
  SCAN_ALT_F6        = $6D;
  SCAN_ALT_F7        = $6E;
  SCAN_ALT_F8        = $6F;
  SCAN_ALT_F9        = $70;
  SCAN_ALT_F10       = $71;
  SCAN_ALT_F11       = $8B;
  SCAN_ALT_F12       = $8C;

  SCAN_SHIFT_F1      = $54;
  SCAN_SHIFT_F2      = $55;
  SCAN_SHIFT_F3      = $56;
  SCAN_SHIFT_F4      = $57;
  SCAN_SHIFT_F5      = $58;
  SCAN_SHIFT_F6      = $59;
  SCAN_SHIFT_F7      = $5A;
  SCAN_SHIFT_F8      = $5B;
  SCAN_SHIFT_F9      = $5C;
  SCAN_SHIFT_F10     = $5D;
  SCAN_SHIFT_F11     = $87;
  SCAN_SHIFT_F12     = $88;

  SCAN_CTRL_F1       = $5E;
  SCAN_CTRL_F2       = $5F;
  SCAN_CTRL_F3       = $60;
  SCAN_CTRL_F4       = $61;
  SCAN_CTRL_F5       = $62;
  SCAN_CTRL_F6       = $63;
  SCAN_CTRL_F7       = $64;
  SCAN_CTRL_F8       = $65;
  SCAN_CTRL_F9       = $66;
  SCAN_CTRL_F10      = $67;
  SCAN_CTRL_F11      = $89;
  SCAN_CTRL_F12      = $8A;

  SCAN_TILDA         = $29;
  SCAN_1             = $02;
  SCAN_2             = $03;
  SCAN_3             = $04;
  SCAN_4             = $05;
  SCAN_5             = $06;
  SCAN_6             = $07;
  SCAN_7             = $08;
  SCAN_8             = $09;
  SCAN_9             = $0A;
  SCAN_0             = $0B;
  SCAN_MINUS         = $0C;
  SCAN_EQ            = $0D;
  SCAN_BS            = $0E;

  SCAN_TAB           = $0F;
  SCAN_Q             = $10;
  SCAN_W             = $11;
  SCAN_E             = $12;
  SCAN_R             = $13;
  SCAN_T             = $14;
  SCAN_Y             = $15;
  SCAN_U             = $16;
  SCAN_I             = $17;
  SCAN_O             = $18;
  SCAN_P             = $19;
  SCAN_LBRAKET       = $1A;
  SCAN_RBRAKET       = $1B;
  SCAN_BACK_SLASH    = $2B;

  SCAN_A             = $1E;
  SCAN_S             = $1F;
  SCAN_D             = $20;
  SCAN_F             = $21;
  SCAN_G             = $22;
  SCAN_H             = $23;
  SCAN_J             = $24;
  SCAN_K             = $25;
  SCAN_L             = $26;
  SCAN_DOTCOMA       = $27;
  SCAN_QUOTE         = $28;
  SCAN_ENTER         = $1c;

  SCAN_Z             = $2C;
  SCAN_X             = $2D;
  SCAN_C             = $2E;
  SCAN_V             = $2F;
  SCAN_B             = $30;
  SCAN_N             = $31;
  SCAN_M             = $32;
  SCAN_COMA          = $33;
  SCAN_DOT           = $34;
  SCAN_SLASH         = $35;

  SCAN_SPACE         = $39;

  SCAN_GREY_MINUS    = $4A;
  SCAN_GREY_PLUS     = $4E;

type
  TKeyboardInput = packed record
    case Byte of
      0: (
        CharCode: Char;
        ScanCode: Byte;
      );
      1: (
        Data: Word;
      );
  end;

function WaitForInput: Word;
function HasKey: Word;
function GetFlags: Byte;
function IsCtrl(const Flags: Byte): ByteBool;
function IsAlt(const Flags: Byte): ByteBool;
function IsShift(const Flags: Byte): ByteBool;

implementation

uses
  Dos;

var
  OldCtrlBreakHandle: Pointer;

function WaitForInput: Word; assembler; nostackframe;
asm
  mov ax,$1000
  int $16
end;

function HasKey: Word; assembler; nostackframe;
asm
  mov ax,$1100
  int $16
end;

function GetFlags: Byte; assembler; nostackframe;
asm
  mov ax,$1200
  int $16
end;

procedure SetFastTypematicRate; assembler; nostackframe;
asm
  mov ax,$0305
  xor bx,bx
  int $16
end;

procedure SetDefaultTypematicRate; assembler; nostackframe;
asm
  mov ax,$0300
  int $16
end;

function IsCtrl(const Flags: Byte): ByteBool; assembler;
asm
  mov al,Flags
  and al,$4
end;

function IsAlt(const Flags: Byte): ByteBool; assembler;
asm
  mov al,Flags
  and al,$8
end;

function IsShift(const Flags: Byte): ByteBool; assembler;
asm
  mov al,Flags
  and al,$3
end;

procedure BlankHandle; assembler; nostackframe; far;
asm
  iret
end;

initialization
  GetIntVec($23, OldCtrlBreakHandle);
  SetIntVec($23, @BlankHandle);
  SetFastTypematicRate;

finalization
  SetIntVec($23, OldCtrlBreakHandle);
  SetDefaultTypematicRate;

end.

