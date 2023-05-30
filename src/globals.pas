unit Globals;

{$I naied.inc}

interface

function Min(const X, Y: ShortInt): ShortInt; overload;
function Max(const X, Y: ShortInt): ShortInt; overload;
function Min(const X, Y: SmallInt): SmallInt; overload;
function Max(const X, Y: SmallInt): SmallInt; overload;
function Min(const X, Y: LongInt): LongInt; overload;
function Max(const X, Y: LongInt): LongInt; overload;

implementation

function Min(const X, Y: ShortInt): ShortInt; overload;
begin
  if X < Y then
    Result := X
  else
    Result := Y;
end;

function Max(const X, Y: ShortInt): ShortInt; overload;
begin
  if X > Y then
    Result := X
  else
    Result := Y;
end;

function Min(const X, Y: SmallInt): SmallInt; overload;
begin
  if X < Y then
    Result := X
  else
    Result := Y;
end;

function Max(const X, Y: SmallInt): SmallInt; overload;
begin
  if X > Y then
    Result := X
  else
    Result := Y;
end;

function Min(const X, Y: LongInt): LongInt; overload;
begin
  if X < Y then
    Result := X
  else
    Result := Y;
end;

function Max(const X, Y: LongInt): LongInt; overload;
begin
  if X > Y then
    Result := X
  else
    Result := Y;
end;

end.

