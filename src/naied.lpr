program naied;

{$I naied.inc}

uses
  Dos, Memory, Globals, Screen, Editor, Keyboard, Files, Clipboard, Commands;

var
  I: Byte;

begin
  if ParamCount > 0 then
  begin
    for I := 1 to ParamCount do
    begin
      case ParamStr(I) of
        '-h':
          begin
            Writeln('Usage: naied.exe [options] <file name>');
            Writeln(' -h: This help screen');
            {$ifndef NO_INT10H}
            Writeln(' -m4025: Switch to text mode 40x25');
            Writeln(' -m8025: Switch to text mode 80x25');
            Writeln(' -m8050: Switch to text mode 80x50');
            {$endif}
            Halt;
          end;
        {$ifndef NO_INT10H}
        '-m8025':
          SetMode80x25;
        '-m8050':
          SetMode80x50;
        '-m4025':
          SetMode40x25;   
        {$endif}
      end;
    end;
    if Files.Exists(ParamStr(ParamCount)) or Files.IsValidName(ParamStr(ParamCount)) then
      Files.Open(ParamStr(ParamCount))
    else
      Files.Open('NONAME.TXT');
  end
  else
    Files.Open('NONAME.TXT');
  Editor.Run;
  {$ifndef NO_INT10H}
  SetMode80x25;
  {$endif}
end.

