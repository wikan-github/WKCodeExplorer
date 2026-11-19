unit TestVisibility;

{$mode objfpc}{$H+}

interface

type

  { THuman }

  THuman = class
  private
    FEye : Integer;
    procedure Listen;
  protected
    function Age: integer;
  public
    constructor Create;
    procedure Walk;
  published
    procedure Body;
  end;

  TBeta = class
  private
    procedure Priv;
  protected
    function Prot: integer;
  public
    constructor Create;
    procedure Pub;
  published
    procedure Pubd;
  end;

implementation

{ THuman }

procedure THuman.Listen;
begin

end;

function THuman.Age: integer;
begin

end;

constructor THuman.Create;
begin

end;

procedure THuman.Walk;
begin

end;

procedure THuman.Body;
begin

end;

procedure TBeta.Priv;
begin
end;

function TBeta.Prot: integer;
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
