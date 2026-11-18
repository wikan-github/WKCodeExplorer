unit TestOverload;
{$mode objfpc}{$H+}
interface
procedure Show(X: Integer);
procedure Show(S: string);
implementation
procedure Show(X: Integer);
begin
end;
procedure Show(S: string);
begin
end;
end.
