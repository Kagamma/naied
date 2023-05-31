unit Commands;

{$I naied.inc}

interface 

type
  TCommandFunc = function(const IsSilent: Boolean): Char;

var
  LastCommand: String = 'search';

function CommandQuit: Char;
function CommandSearch(const IsSilent: Boolean): Char;

implementation

uses
  Editor, Memory, Screen, Files, Keyboard;

var
  InputBuffer: String;
  IsCursorBackup: Boolean = False;
  OldCursorX,
  OldCursorY: ShortInt;

procedure WriteCommand(const S: String);
begin                        
  Screen.RenderStatusBarBlank;
  Screen.SetCursorPosition(0, 0);
  Write(S);
end;

procedure BackupCursor;
begin
  if IsCursorBackup then
    Exit;
  OldCursorX := CursorX;
  OldCursorY := CursorY;
  Screen.SetCursorPosition(0, 0);
  IsCursorBackup := True;
end;

procedure RestoreCursor;
begin 
  if not IsCursorBackup then
    Exit;
  CursorX := OldCursorX;
  CursorY := OldCursorY;
  Screen.SetCursorPosition(CursorX, CursorY);
  IsCursorBackup := False;
end;

function CommandQuit: Char;
begin
  if Editor.Modified then
  begin  
    Result := ' ';
    BackupCursor;
    WriteCommand('Save before quit? (Y/N/C)');
    repeat
      Result := TKeyboardInput(Keyboard.WaitForInput).CharCode;
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

function CommandSearch(const IsSilent: Boolean): Char;
begin
  BackupCursor;
  if not IsSilent then
  begin
    WriteCommand('Search: ');
    Readln(InputBuffer);
  end;
  RestoreCursor;
  if InputBuffer <> '' then
  begin
    LastCommand := 'search';
    InputBuffer := UpCase(InputBuffer);
    if not Editor.SearchForText(InputBuffer) then
    begin
      BackupCursor;
      WriteCommand('Text not found!');
      Keyboard.WaitForInput;
      RestoreCursor;
    end;
  end;
  Screen.RenderStatusBar;
end;

end.

