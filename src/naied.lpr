program naied;

{$I naied.inc}

uses
  Dos, Memory, Globals, Screen, Editor, Keyboard, Files, Clipboard, Commands;

var
  I: Byte;

begin
  SetMode80x25;
  if ParamCount > 0 then
  begin
    for I := 1 to ParamCount do
    begin
      case ParamStr(I) of
        '-h':
          begin
            Writeln('Usage: naied.exe [options] <file name>');
            Writeln(' -h: This help screen');
            Writeln(' -m4025: Switch to text mode 40x25');
            Writeln(' -m8050: Switch to text mode 80x50');
            Halt;
          end;
        '-m8050':
          SetMode80x50; 
        '-m4025':
          SetMode40x25;
      end;
    end;
    if Files.Exists(ParamStr(ParamCount)) then
      Files.Open(ParamStr(ParamCount))
    else
      Files.Open('NONAME.TXT');
  end
  else
    Files.Open('NONAME.TXT');
  Editor.Run;
  SetMode80x25;
end.

