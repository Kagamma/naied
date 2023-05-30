unit Commands;

{$I naied.inc}

interface

function CommandQuit: Char;

implementation

uses
  Editor, Memory, Screen, Files, Keyboard;

var
  OldCursorX,
  OldCursorY: ShortInt;

procedure BackupCursor;
begin
  OldCursorX := CursorX;
  OldCursorY := CursorY;
  Screen.SetCursorPosition(0, 0);
end;

procedure RestoreCursor;
begin
  CursorX := OldCursorX;
  CursorY := OldCursorY;
  Screen.SetCursorPosition(CursorX, CursorY);
end;

function CommandQuit: Char;
begin
  if Editor.Modified then
  begin  
    Result := ' ';
    Screen.RenderStatusBarBlank;
    BackupCursor;
    Write('Save before quit? (Y/N/C)');
    repeat
      if Keyboard.IsPressed then
        Result := TKeyboardInput(Keyboard.GetKey).CharCode;
    until Result in ['y', 'n', 'c'];
    RestoreCursor;
    Screen.RenderStatusBar;
  end else
    Result := 'n';
  case Result of
    'y':
      begin
        Files.Save;
        SetMode80x25;
        Halt;
      end; 
    'n':
      begin
        SetMode80x25;
        Halt;
      end;
  end;
end;

end.

