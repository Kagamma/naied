unit Commands;

{$I naied.inc}

interface

var
  LastCommand: String = 'search';

function CommandQuit: Char;
procedure CommandSearch(const IsSilent, IsCaseSensitive: Boolean);
procedure CommandReplace(const IsSilent, IsCaseSensitive: Boolean);

implementation

uses
  Editor, Memory, Screen, Files, Keyboard;

var
  InputBuffer1,
  InputBuffer2,
  InputBuffer3: String;
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

procedure CommandSearch(const IsSilent, IsCaseSensitive: Boolean);
begin
  BackupCursor;
  if not IsSilent then
  begin
    WriteCommand('Search: ');
    Readln(InputBuffer1);
  end;
  RestoreCursor;
  if InputBuffer1 <> '' then
  begin
    LastCommand := 'search';
    InputBuffer1 := InputBuffer1;
    if not Editor.SearchForText(InputBuffer1, IsCaseSensitive) then
    begin
      BackupCursor;
      WriteCommand('Text not found!');
      Keyboard.WaitForInput;
      RestoreCursor;
    end;
  end;
  Screen.RenderStatusBar;
  Screen.RenderEdit;
end;

procedure CommandReplace(const IsSilent, IsCaseSensitive: Boolean);
var
  I: Word;
begin
  BackupCursor;
  if not IsSilent then
  begin
    WriteCommand('Replace: ');
    Readln(InputBuffer1);
  end;
  RestoreCursor;
  if InputBuffer1 <> '' then
  begin
    if not IsSilent then
    begin
      WriteCommand('With: ');
      Readln(InputBuffer2);
    end;
    LastCommand := 'replace';
    InputBuffer1 := InputBuffer1;
    if not Editor.SearchForText(InputBuffer1, IsCaseSensitive) then
    begin
      BackupCursor;
      WriteCommand('Text not found!');
      Keyboard.WaitForInput;
      RestoreCursor;
    end else
    begin
      for I := 1 to Length(InputBuffer1) do
      begin
        Editor.HandleDeleteRight;
      end;      
      for I := 1 to Length(InputBuffer2) do
      begin
        Editor.HandleInsert(InputBuffer2[I]);
      end;
    end;
  end;
  Screen.RenderStatusBar;
  Screen.RenderEdit;
end;

end.

