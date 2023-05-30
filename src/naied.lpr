program naied;

{$I naied.inc}

uses
  Dos, Memory, Globals, Screen, Editor, Keyboard, Files, Clipboard, Commands;

var
  I: Integer;

begin
  if ParamCount = 0 then
  begin
    Writeln('Usage: naied.exe [options] <file name>');
    Writeln(' -l: Switch to text mode 80x50');
    Halt;
  end;
  SetMode80x25;
  for I := 1 to ParamCount do
  begin
    case ParamStr(I) of
      '-l':
        SetMode80x50;
    end;
  end;
  Files.Open(ParamStr(ParamCount));
  Screen.Render;
  Editor.Run;
  SetMode80x25;
end.

