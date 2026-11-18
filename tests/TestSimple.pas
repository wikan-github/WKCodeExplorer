unit TestSimple;

{$mode objfpc}{$H+}

interface

type
  TAlpha = class
  public
    procedure Foo;
    function Bar: Integer;
  end;

procedure GlobalProc;

implementation

procedure GlobalProc;
begin
end;

procedure TAlpha.Foo;
begin
end;

function TAlpha.Bar: Integer;
begin
  Result := 0;
end;

end.
