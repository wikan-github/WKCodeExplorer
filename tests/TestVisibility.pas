unit TestVisibility;

{$mode objfpc}{$H+}

interface

type
  TBeta = class
  private
    procedure Priv;
  protected
    function Prot: Integer;
  public
    constructor Create;
    procedure Pub;
  published
    procedure Pubd;
  end;

implementation

procedure TBeta.Priv;
begin
end;

function TBeta.Prot: Integer;
begin
  Result := 0;
end;

constructor TBeta.Create;
begin
end;

procedure TBeta.Pub;
begin
end;

procedure TBeta.Pubd;
begin
end;

end.
