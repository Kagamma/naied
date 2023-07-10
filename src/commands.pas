unit Commands;

{$I naied.inc}

interface

const
  COMMAND_SEARCH_INS = 1;
  COMMAND_SEARCH_SEN = 2;
  COMMAND_REPLACE_INS = 3;
  COMMAND_REPLACE_SEN = 4;
  COMMAND_GOTO = 5;
  COMMAND_OPEN = 6;
  COMMAND_SAVEAS = 7;

var
  LastCommand: Byte = 0;

function CommandSaveBefore(const Msg: String): Char;
procedure CommandSearch(const IsSilent, IsCaseSensitive: Boolean);
procedure CommandReplace(const IsSilent, IsCaseSensitive: Boolean);
procedure CommandGoto;   
procedure CommandOpen;  
procedure CommandSave;
procedure CommandSaveAs;

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

procedure WriteCommand(const S: String);
begin
  Screen.RenderStatusBarBlank;
  Screen.SetCursorPosition(0, 0);
  Write(S);
  CursorX := Length(S);
end;

function ReadCommand(var S: String): Boolean;
var
  Input: TKeyboardInput;
  I: Byte = 0;
begin
  S := '';
  while True do
  begin
    Input.Data := Keyboard.WaitForInput;
    if Input.ScanCode = SCAN_ESC then
      Exit(False)
    else
    if Input.ScanCode = SCAN_ENTER then
      Exit(True)
    else
    if (Input.ScanCode = SCAN_BS) and (I > 0) then
    begin
      SetLength(S, I - 1);
      Dec(I);
      Dec(CursorX);
      ScreenPointer[CursorX] := AttrStatus;
    end
    else
    if (I < 50) and (Input.CharCode in [#32..#126]) then
    begin
      S := S + Input.CharCode;
      ScreenPointer[CursorX] := AttrStatus + Byte(Input.CharCode);
      Inc(I);
      Inc(CursorX);
    end;
    Screen.SetCursorPosition(CursorX, 0);
  end;
end;

procedure FinishCommand;
begin
  RestoreCursor;
  Screen.RenderStatusBar;
  Screen.RenderEdit(False, False, False);
end;

function CommandSaveBefore(const Msg: String): Char;
begin
  if Editor.Modified then
  begin  
    Result := ' ';
    BackupCursor;
    WriteCommand(Msg);
    repeat
      Result := TKeyboardInput(Keyboard.WaitForInput).CharCode;
    until Result in ['y', 'n', 'c'];
    RestoreCursor;
    Screen.RenderStatusBar;
  end else
    Result := 'n';
end;

procedure CommandSearch(const IsSilent, IsCaseSensitive: Boolean);
begin
  BackupCursor;
  if not IsSilent then
  begin
    WriteCommand('Search: ');
    if not ReadCommand(InputBuffer1) then
    begin
      FinishCommand;
      Exit;
    end;
  end;
  if InputBuffer1 <> '' then
  begin
    if IsCaseSensitive then
      LastCommand := COMMAND_SEARCH_SEN
    else
      LastCommand := COMMAND_SEARCH_INS;
    WriteCommand('Searching...');
    RestoreCursor;
    if not Editor.SearchForText(InputBuffer1, IsCaseSensitive) then
    begin
      BackupCursor;
      WriteCommand('Text not found!');
      Keyboard.WaitForInput;
    end;
  end;
  FinishCommand;
end;

procedure CommandReplace(const IsSilent, IsCaseSensitive: Boolean);
var
  I: Word;
begin
  BackupCursor;
  if not IsSilent then
  begin
    WriteCommand('Replace: ');
    if not ReadCommand(InputBuffer1) then
    begin
      FinishCommand;
      Exit;
    end;
  end;
  if InputBuffer1 <> '' then
  begin
    if not IsSilent then
    begin
      WriteCommand('With: ');
      if not ReadCommand(InputBuffer2) then
      begin
        FinishCommand;
        Exit;
      end;
    end;
    if IsCaseSensitive then
      LastCommand := COMMAND_REPLACE_SEN
    else
      LastCommand := COMMAND_REPLACE_INS;
    WriteCommand('Replacing...');
    RestoreCursor;
    if not Editor.SearchForText(InputBuffer1, IsCaseSensitive) then
    begin
      BackupCursor;
      WriteCommand('Text not found!');
      Keyboard.WaitForInput;
    end else
    begin
      BackupCursor;
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
  FinishCommand;
end;

procedure CommandGoto;
var
  Code: Integer;
  Y: DWord;
begin
  LastCommand := COMMAND_REPLACE_SEN;
  BackupCursor;
  WriteCommand('Line number: ');
  if not ReadCommand(InputBuffer1) then
  begin
    FinishCommand;
    Exit;
  end;
  if InputBuffer1 <> '' then
    Val(InputBuffer1, Y, Code)
  else
    Code := 1;
  if Code <> 0 then
  begin
    WriteCommand('Not a number!');
    Keyboard.WaitForInput;
  end else
  begin
    RestoreCursor;
    Editor.MoveTo(1, Y);
  end;
  FinishCommand;
end;

procedure CommandOpen;
begin
  case CommandSaveBefore('Save current file? (Y/N/C)') of
    'y':
      begin
        Files.Save;
      end;
    'c':
      begin
        Exit;
      end;
  end;
  BackupCursor;
  LastCommand := COMMAND_OPEN;
  WriteCommand('File name: ');
  if not ReadCommand(InputBuffer1) then
  begin
    FinishCommand;
    Exit;
  end;
  if InputBuffer1 <> '' then
    Files.Open(InputBuffer1);
end;

procedure CommandSave;
begin
  Files.Save;
  Modified := False;
  IsRefreshStatusCursor := True;
  IsRefreshStatusMode := True;
end;

procedure CommandSaveAs;
begin
  LastCommand := COMMAND_SAVEAS;
  BackupCursor;
  WriteCommand('File name: ');
  if not ReadCommand(InputBuffer1) then
  begin
    FinishCommand;
    Exit;
  end;
  if InputBuffer1 <> '' then
  begin
    WorkingFile := InputBuffer1;
    CommandSave;
  end;
  FinishCommand;
end;

end.

