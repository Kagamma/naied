unit Editor;

{$I naied.inc}

interface

uses
  Memory, Screen, Keyboard, Globals;

type
  TEditorMode = (
    emCommand,
    emInsert,
    emReplace,
    emSelect
  );

  TEditorDirection = (
    dirLeft,
    dirUp,
    dirRight,
    dirDown,
    dirHome,
    dirEnd
  );

const
  EDITOR_MODE_SYMBOL: array[TEditorMode] of Char = ('C', 'I', 'R', 'S');

var
  EditorMode: TEditorMode = emInsert;
  WorkingFile: String = 'NONAME.TXT';
  EditorX: SmallInt = 1;
  EditorY: LongInt = 1;
  Modified: Boolean = False;
  SelStartIndex,
  SelEndIndex: Word;
  SelStart,
  SelEnd: PMemoryBlock;
  ActualSelStart,
  ActualSelEnd: PMemoryBlock;
  ActualSelStartIndex,
  ActualSelEndIndex: Word;
  IsDirDown: Boolean;
  Highlight: Byte = 3;
  IsRefreshStatusMode: Boolean;
  IsRefreshStatusCursor: Boolean;
  IsRefreshEdit: Boolean;
  IsRefreshEditScrollUp: Boolean;
  IsRefreshEditScrollDown: Boolean;
  IsRefreshEditSingleLine: Boolean;

procedure Run;
procedure GetActualSel;
procedure HandleInsert(const C: Char);
procedure HandleInsertString(const S: String);
procedure HandleDeleteRight;
procedure HandleEnter;       
procedure HandleHome;
procedure MoveTo(const X, Y: Integer);
function SearchForText(S: String; const IsCaseSensitive: Boolean): Boolean;

implementation

uses
  Files, Clipboard, Commands;

var
  KBInput: TKeyboardInput;
  KBFlags: Byte;

function SearchForText(S: String; const IsCaseSensitive: Boolean): Boolean;
var
  P: PMemoryBlock;
  Ind, Len: Integer;
  Loop: Integer = 0;
begin
  P := Current;
  if IsCaseSensitive then
    Ind := Pos(S, P^.Text)
  else
  begin
    S := UpCase(S);
    Ind := Pos(S, UpCase(P^.Text));
  end;
  if (P = Current) and (EditorX >= Ind) then
    Ind := 0;
  while (Ind < 1) and (P <> nil) do
  begin
    P := P^.Next;
    if P <> nil then
    begin
      if IsCaseSensitive then
        Ind := Pos(S, P^.Text)
      else
        Ind := Pos(S, UpCase(P^.Text));
      if (P = Current) and (EditorX = Ind) then
        Ind := 0;
      Inc(Loop);
    end;
  end;
  if P <> nil then
  begin
    Current := P;
    MoveTo(Ind, EditorY + Loop);
    Len := Length(S);
    if ScreenWidth - CursorX < Len then
    begin
      Len := Len - (ScreenWidth - CursorX);
      Offset := Offset + Len;
      CursorX := CursorX - Len;
    end;
    Result := True;
  end else
  begin
    Result := False
  end;
end;

procedure MoveTo(const X, Y: Integer);
var
  Loop,
  CornerLeft,
  CornerTop,
  CornerRight,
  CornerBottom: Integer;
  P, N: PMemoryBlock;
begin
  // quit because Y is larger than EditorY's max value
  if Y > Memory.Total then
    Exit;
  // Look for current 
  Loop := 0;
  N := Memory.First;
  P := N;
  while Loop <> Y do
  begin
    Inc(Loop);
    P := N;
    N := P^.Next;
  end;
  Current := P;
  // Find the actual corners
  CornerLeft := EditorX - CursorX;
  CornerTop := EditorY - CursorY + 1;
  CornerRight := CornerLeft + ScreenWidth;
  CornerBottom := CornerTop + ScreenHeight + 1;
  EditorX := X;
  EditorY := Y;
  CursorX := X - CornerLeft;
  CursorY := Y - CornerTop + 1;
  // Check to see if X and Y are within the current view, if yes, just move
  // the cursor and exit
  if (X < CornerLeft) or (X >= CornerRight) or (Y < CornerTop) or (Y >= CornerBottom) then
  begin
    // X and Y are not within view, so we need to scroll things
    if X < CornerLeft then
    begin
      CursorX := 0;
      Offset := Offset - (CornerLeft - X);
    end
    else
    if X >= CornerRight then
    begin
      CursorX := ScreenWidth - 1;
      Offset := X - ScreenWidth;
    end;
    if Y < CornerTop then
      CursorY := 0
    else
    if Y >= CornerBottom then
      CursorY := ScreenHeight - 1;

    IsRefreshEdit := True;
  end;
  // Look for view
  CornerTop := EditorY - CursorY + 1;
  while Loop <> CornerTop do
  begin
    P := P^.Prev;
    Dec(Loop);
  end;
  View := P;
  IsRefreshStatusCursor := True;
  Screen.SetCursorPosition(CursorX, CursorY);
end;

procedure GetActualSel;
begin
  if IsDirDown then
  begin
    ActualSelStart := SelStart;
    ActualSelEnd := SelEnd;
    ActualSelStartIndex := SelStartIndex;
    ActualSelEndIndex := SelEndIndex;
  end else
  begin
    ActualSelStart := SelEnd;
    ActualSelEnd := SelStart;
    ActualSelStartIndex := SelEndIndex;
    ActualSelEndIndex := SelStartIndex;
  end;
end;

procedure UpdateSelBlock(const Direction: TEditorDirection);
begin
  if EditorMode <> emSelect then
    Exit;
  case Direction of
    dirUp:
      begin
        SelEnd := SelEnd^.Prev;
        if SelEnd^.Next = SelStart then
          IsDirDown := False
        else
        if (SelStart = SelEnd) and (SelEndIndex < SelStartIndex) then
          IsDirDown := False
        else
        if (SelStart = SelEnd) and (SelEndIndex >= SelStartIndex) then
          IsDirDown := True;
      end;
    dirDown:
      begin
        SelEnd := SelEnd^.Next;
        if SelEnd^.Prev = SelStart then
          IsDirDown := True
        else
        if (SelStart = SelEnd) and (SelEndIndex < SelStartIndex) then
          IsDirDown := False
        else
        if (SelStart = SelEnd) and (SelEndIndex >= SelStartIndex) then
          IsDirDown := True;
      end;
    dirLeft:
      begin
        SelEndIndex := Max(0, SelEndIndex - 1);
        if (SelStart = SelEnd) and (SelEndIndex < SelStartIndex) then
          IsDirDown := False;
      end;
    dirRight:
      begin
        SelEndIndex := Min(MEMORY_TEXT_SIZE, SelEndIndex + 1);
        if (SelStart = SelEnd) and (SelEndIndex >= SelStartIndex) then
          IsDirDown := True;
      end;
    dirHome:
      begin
        SelEndIndex := 0;
        if (SelStart = SelEnd) and (SelEndIndex < SelStartIndex) then
          IsDirDown := False;
      end;
    dirEnd:
      begin
        SelEndIndex := Length(SelEnd^.Text);
        if (SelStart = SelEnd) and (SelEndIndex >= SelStartIndex) then
          IsDirDown := True;
      end;
  end;
  IsRefreshEdit := True;
end;

procedure HandleUp;
begin
  if Memory.Current^.Prev <> nil then
  begin
    Memory.Current := Current^.Prev;
    Dec(EditorY);
    CursorY := CursorY - 1;
    if CursorY < 1 then
    begin
      if not IsRefreshEditScrollUp then
        IsRefreshEditScrollUp := True
      else
        IsRefreshEdit := True;
      CursorY := 1;
    end;
    UpdateSelBlock(dirUp);
  end;
  if Memory.Current^.Next = Memory.View then
    Memory.View := Memory.Current;
  IsRefreshStatusCursor := True;
end;

procedure HandleDown;
var
  I: Byte = 0;
  M: PMemoryBlock;
begin
  if Memory.Current^.Next <> nil then
  begin
    Memory.Current := Current^.Next;
    Inc(EditorY);
    CursorY := CursorY + 1;
    if CursorY > ScreenHeight - 1 then
    begin
      if not IsRefreshEditScrollDown then
        IsRefreshEditScrollDown := True
      else
        IsRefreshEdit := True;
      CursorY := ScreenHeight - 1;
    end;
    UpdateSelBlock(dirDown);
  end;
  M := Memory.View;
  while (M <> Memory.Current) do
  begin
    M := M^.Next;
    Inc(I);
  end;
  if I > Screen.ScreenHeight - 2 then
    Memory.View := Memory.View^.Next;
  IsRefreshStatusCursor := True;
end;

procedure HandleLeft;
begin
  Dec(EditorX);
  if EditorX >= 1 then
  begin
    CursorX := CursorX - 1;
    if CursorX < 0 then
    begin
      IsRefreshEdit := True;
      Dec(Offset);
      CursorX := 0;
    end else
      UpdateSelBlock(dirLeft);
  end else
    EditorX := 1;
  IsRefreshStatusCursor := True;
end;

procedure HandleRight;
begin
  Inc(EditorX);
  if EditorX <= MEMORY_TEXT_SIZE then
  begin
    CursorX := CursorX + 1;
    if CursorX > ScreenWidth - 1 then
    begin
      IsRefreshEdit := True;
      Inc(Offset);
      CursorX := ScreenWidth - 1;
    end else
      UpdateSelBlock(dirRight);
  end else
    EditorX := MEMORY_TEXT_SIZE;
  IsRefreshStatusCursor := True;
end;

procedure HandleHome;
begin
  EditorX := 1;
  CursorX := 0;
  Offset := 0;
  UpdateSelBlock(dirHome);
  IsRefreshEdit := True;
end;

procedure HandleEnd;
var
  Size: Word;
begin
  Size := Length(Memory.Current^.Text);
  EditorX := Size + 1;
  CursorX := Min(ScreenWidth - 1, Size);
  Offset := Max(EditorX - ScreenWidth, 0);
  UpdateSelBlock(dirEnd);
  IsRefreshEdit := True;
end;

procedure HandleEnter;
begin
  Memory.Split(Memory.Current, EditorX);
  HandleHome;
  HandleDown;
  Modified := True;
  IsRefreshStatusMode := True;
  IsRefreshEdit := True;
end;

procedure HandleInsert(const C: Char);
var
  Size: Word;
begin
  Size := Length(Memory.Current^.Text);
  if Size < EditorX - 1 then
    AdjustTextSize(Current, EditorX - 1);
  System.Insert(C, Current^.Text, EditorX);
  HandleRight;
  Modified := True;
  IsRefreshStatusMode := True;
  IsRefreshEditSingleLine := True;
end;

procedure HandleInsertString(const S: String);
var
  Size, I: Word;
begin
  Size := Length(Memory.Current^.Text);
  if Size < EditorX - 1 then
    AdjustTextSize(Current, EditorX - 1);
  System.Insert(S, Current^.Text, EditorX);
  for I := 1 to Length(S) do
    HandleRight;
  Modified := True;
  IsRefreshStatusMode := True;
  IsRefreshEditSingleLine := True;
end;

procedure HandleDeleteLeft;
var
  M: PMemoryBlock;
begin
  M := Memory.Current;
  if (EditorX <= 1) and (EditorY > 1) then
  begin
    HandleUp;
    HandleEnd;
    Memory.Merge(M^.Prev, EditorX); 
    IsRefreshEdit := True;
  end else
  begin
    System.Delete(Current^.Text, EditorX - 1, 1);
    HandleLeft;
    IsRefreshStatusCursor := True; 
    IsRefreshEditSingleLine := True;
  end;
  Modified := True;
  IsRefreshStatusMode := True;
end;

procedure HandleDeleteRight;
var
  M: PMemoryBlock;
  Size: Word;
begin
  M := Memory.Current;
  Size := Length(M^.Text);
  if EditorX > Size then
  begin
    Memory.Merge(M, EditorX);
    IsRefreshStatusCursor := True; 
    IsRefreshEdit := True;
  end else
  begin
    System.Delete(Current^.Text, EditorX, 1);
    IsRefreshEditSingleLine := True;
  end;
  Modified := True;
  IsRefreshStatusMode := True;
end;

procedure HandleDeleteBlock;
var
  I, Size: DWord;
  P: PMemoryBlock;
begin
  GetActualSel;
  if IsDirDown then
  begin
    while Current <> ActualSelStart do
      HandleDeleteLeft;
    while EditorX <> ActualSelStartIndex + 1 do
      HandleDeleteLeft;
  end else
  begin
    if ActualSelStart <> ActualSelEnd then
    begin
      Size := Length(Current^.Text) - ActualSelStartIndex + 1;
      P := ActualSelStart^.Next;
      while P <> ActualSelEnd do
      begin
        Size := Size + Length(P^.Text) + 1;
        P := P^.Next;
      end;
      Size := Size + ActualSelEndIndex;
    end else
    begin
      Size := ActualSelEndIndex - ActualSelStartIndex;
    end;
    for I := 1 to Size do
      HandleDeleteRight;
  end;
  IsRefreshStatusCursor := True;
  IsRefreshStatusMode := True;
  IsRefreshEdit := True;
end;

procedure HandlePageDown;
var
  I: Byte;
begin
  for I := 0 to ScreenHeight - 3 do
  begin
    HandleDown;
  end;
end;

procedure HandlePageUp;
var
  I: Byte;
begin
  for I := 0 to ScreenHeight - 3 do
  begin
    HandleUp;
  end;
end;

procedure HandleCtrlS;
begin
  Files.Save;
  Modified := False;
  IsRefreshStatusCursor := True;
  IsRefreshStatusMode := True;
end;

function CheckForSelect: Boolean;
begin
  if IsShift(KBFlags) then
  begin
    EditorMode := emSelect;
    Screen.RenderStatusMode;
    SelStart := Current;
    SelEnd := Current;
    SelStartIndex := EditorX - 1;
    SelEndIndex := EditorX - 1;
    IsDirDown := True;
    IsRefreshEdit := True;
    Result := True;
  end else
    Result := False;
end;

function CheckForNotSelect: Boolean;
begin
  if not IsShift(KBFlags) then
  begin
    EditorMode := emInsert;
    Screen.RenderStatusMode;
    SelStart := nil;
    SelEnd := nil;
    IsRefreshEdit := True;
    Result := True;
  end else
    Result := False;
end;

function HandleKeyboardEdit: Boolean;
label
  Other;
begin
  Result := True;
  if IsCtrl(KBFlags) then
  begin
    case KBInput.ScanCode of
      SCAN_S:
        begin
          HandleCtrlS;
        end;
    end;
  end;
  case KBInput.ScanCode of
    SCAN_UP:
      begin
        Result := not CheckForSelect;
        if Result then
          HandleUp;
      end;
    SCAN_DOWN:
      begin
        Result := not CheckForSelect;
        if Result then
          HandleDown;
      end;
    SCAN_LEFT:
      begin
        Result := not CheckForSelect;
        if Result then
          HandleLeft;
      end;
    SCAN_RIGHT:
      begin
        Result := not CheckForSelect;
        if Result then
          HandleRight;
      end;
    SCAN_HOME:
      begin
        Result := not CheckForSelect;
        if Result then
          HandleHome;
      end;
    SCAN_END:
      begin
        Result := not CheckForSelect;
        if Result then
          HandleEnd;
      end;
    SCAN_ENTER:
      begin
        HandleEnter;
      end;
    SCAN_BS:
      begin
        HandleDeleteLeft;
      end;
    SCAN_DEL:
      begin
        HandleDeleteRight;
      end;
    SCAN_PGDN:
      begin
        Result := not CheckForSelect;
        if Result then
          HandlePageDown;
      end;
    SCAN_PGUP:
      begin
        Result := not CheckForSelect;
        if Result then
          HandlePageUp;
      end;
    SCAN_F3:
      begin
        if LastCommand = COMMAND_SEARCH_INS then
          CommandSearch(True, False)
        else
        if LastCommand = COMMAND_SEARCH_SEN then
          CommandSearch(True, True);
      end;  
    SCAN_F4:
      begin
        if LastCommand = COMMAND_REPLACE_INS then
          CommandReplace(True, False)
        else
        if LastCommand = COMMAND_REPLACE_SEN then
          CommandReplace(True, True);
      end;
    SCAN_F:
      begin
        if IsCtrl(KBFlags) then
        begin
          CommandSearch(False, IsShift(KBFlags));
        end else
          goto Other;
      end;
    SCAN_R:
      begin
        if IsCtrl(KBFlags) then
        begin
          CommandReplace(False, IsShift(KBFlags));
        end else
          goto Other;
      end;
    SCAN_H:
      begin
        if IsCtrl(KBFlags) and IsShift(KBFlags) then
        begin
          Highlight := Highlight + 1;
          if Highlight > 3 then
            Highlight := 0;
          IsRefreshEdit := True;
        end else
          goto Other;
      end;
    SCAN_V:
      begin
        if IsCtrl(KBFlags) then
        begin
          PasteBlock;
        end else
          goto Other;
      end
    else
      begin
      Other:
        case KBInput.CharCode of
          #9:
            begin
              HandleInsert(' ');
              HandleInsert(' ');
            end;
          #32..#126:
            HandleInsert(KBInput.CharCode);
        end;
      end;
  end;
end;

function HandleKeyboardSelect: Boolean;
begin
  Result := True;
  case KBInput.ScanCode of
    SCAN_UP:
      begin
        Result := not CheckForNotSelect;
        if Result then
          HandleUp;
      end;
    SCAN_DOWN:
      begin
        Result := not CheckForNotSelect;
        if Result then
          HandleDown;
      end;
    SCAN_LEFT:
      begin
        Result := not CheckForNotSelect;
        if Result then
          HandleLeft;
      end;
    SCAN_RIGHT:
      begin
        Result := not CheckForNotSelect;
        if Result then
          HandleRight;
      end;
    SCAN_C:
      begin
        if IsCtrl(KBFlags) then
        begin
          CopyBlock;
        end;
        KBInput.Data := 0;
        Result := not CheckForNotSelect;
      end;
    SCAN_X:
      begin
        if IsCtrl(KBFlags) then
        begin
          CopyBlock;
          HandleDeleteBlock;
        end;
        KBInput.Data := 0;
        Result := not CheckForNotSelect;
      end;
    SCAN_BS,
    SCAN_DEL:
      begin
        HandleDeleteBlock;
        KBInput.Data := 0;
        Result := not CheckForNotSelect;
      end;
    SCAN_HOME:
      begin
        Result := not CheckForNotSelect;
        if Result then
          HandleHome;
      end;
    SCAN_END:
      begin
        Result := not CheckForNotSelect;
        if Result then
          HandleEnd;
      end;
    SCAN_PGDN:
      begin
        Result := not CheckForNotSelect;
        if Result then
          HandlePageDown;
      end;
    SCAN_PGUP:
      begin
        Result := not CheckForNotSelect;
        if Result then
          HandlePageUp;
      end;
    else
      begin
        HandleDeleteBlock;
        Result := not CheckForNotSelect;
      end;
  end;
end;

procedure Run;
label
  Again;
begin
  KBInput.Data := 0;
  while True do
  begin
    IsRefreshStatusCursor := False;
    IsRefreshStatusMode := False;
    IsRefreshEdit := False;
    IsRefreshEditSingleLine := False;
    IsRefreshEditScrollUp := False;
    IsRefreshEditScrollDown := False;

    KBInput.Data := Keyboard.WaitForInput;
    KBFlags := Keyboard.GetFlags;
  Again:
    if KBInput.ScanCode = SCAN_ESC then
      CommandQuit
    else
    case EditorMode of
      emInsert,
      emReplace:
        begin
          if not HandleKeyboardEdit then
            goto Again;
        end;
      emSelect:
        begin
          if not HandleKeyboardSelect then
            goto Again;
        end;
    end;

    Screen.SetCursorPosition(CursorX, CursorY);
    if IsRefreshStatusCursor then
      Screen.RenderStatusCursor;

    if IsRefreshEdit then
      Screen.RenderEdit
    else
    if IsRefreshEditSingleLine then
      Screen.RenderEdit(True)
    else
    if IsRefreshEditScrollUp then
      Screen.RenderEditScrollUp
    else
    if IsRefreshEditScrollDown then
      Screen.RenderEditScrollDown;

    if IsRefreshStatusMode then
      Screen.RenderStatusMode;
  end;
end;

end.

