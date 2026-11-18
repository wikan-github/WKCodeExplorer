unit TestIfDef;

{$mode objfpc}{$H+}

interface

{$DEFINE USE_EXTRA}

type
  TGamma = class
  public
    procedure Always;
    {$IFDEF USE_EXTRA}
    procedure Extra;
    {$ENDIF}
  end;

implementation

procedure TGamma.Always;
begin
end;

{$IFDEF USE_EXTRA}
procedure TGamma.Extra;
begin
end;
{$ENDIF}

end.
