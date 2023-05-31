unit Files;

{$I naied.inc}

interface

uses
  Memory;

procedure Open(const Path: String);
procedure Save;

implementation

uses
  Globals,
  Screen,
  Editor;

procedure Open(const Path: String);
var
  F: TextFile;
  M: PMemoryBlock;
  Size: Word;
  S: String;
begin
  AssignFile(F, Path);
  {$I-}
  Reset(F);
  {$I+}
  Screen.RenderStatusBarBlank;
  if IOResult = 0 then
  begin
    Memory.Init;
    M := Memory.First;
    while not EOF(F) do
    begin
      if Total mod 100 = 0 then
      begin
        Str(Total, S);
        WorkingFile := 'LOADING: ' + S;
        Screen.RenderStatusFile;
      end;
      Readln(F, M^.Text);
      Size := Min(Length(M^.Text), MEMORY_TEXT_SIZE);
      SetLength(M^.Text, Size);
      if not EOF(F) then
      begin
        M := Memory.CreateNode;
        Memory.Append(M);
      end;
    end;
    CloseFile(F);
  end;
  Screen.RenderStatusBar;
  WorkingFile := Path;
  Editor.MoveTo(1, 100);
end;

procedure Save;
var
  F: TextFile;
  M: PMemoryBlock;
  S, B: String;
  I: DWord = 0;
begin
  AssignFile(F, WorkingFile);
  Rewrite(F);
  M := Memory.First;
  B := WorkingFile;
  Screen.RenderStatusBarBlank;
  while M <> nil do
  begin
    if I mod 100 = 0 then
    begin
      Str(I, S);
      WorkingFile := 'SAVING: ' + S;
      Screen.RenderStatusFile;
    end;
    Writeln(F, M^.Text);
    M := M^.Next;
    Inc(I);
  end;
  CloseFile(F);
  WorkingFile := B;
  Screen.RenderStatusBar;
end;

end.

