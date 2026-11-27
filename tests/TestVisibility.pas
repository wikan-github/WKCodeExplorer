unit TestVisibility;

{$mode objfpc}{$H+}

{$M+}
interface

uses
  Classes, SysUtils;

const
  MaxItems = 10;
  AppName = 'WKCodeExplorer';
  Primes: array[0..4] of integer = (2, 3, 5, 7, 11);

type
  TEffort = (teasy, tmoderate, tadvance);
  TAppType = (TAppDekstop, TAppConsole, TAppWeb);
  TCount = integer;
  TNameList = array of string;
  TMatrix = array[0..2, 0..2] of integer;

  TPoint2D = record
    X, Y: integer;
  end;

type
  { TBase }
  TBase = class
  public
    procedure Walk(ASteps: integer); virtual;
    class procedure Describe; virtual;
  end;

  { THuman }
  THuman = class(TBase)
  private
    FEye: integer;
    FNames: TNameList;
    FLog: TStringList;
    FTag: integer;
    procedure Listen;
  class var FCount: integer;
  protected
    function Age: integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Walk; reintroduce; overload;
    function Sum(const AValues: array of integer): integer; overload;
    function Sum(AValue: double): double; overload;
    class procedure Describe; override;
    class function Count: integer;
  published
    procedure Body;
    property Tag: integer read FTag write FTag;
  end;

  { TBeta }
  TBeta = class
  const
    AppType = TAppDekstop;

  private
    FValue: integer;
    FMatrix: TMatrix;
    procedure Priv;
  class var FInstances: integer;
  protected
    function Prot: integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Pub;
    class procedure Reset;
    class function Version: string;
    property Value: integer read FValue write FValue;
  published
    procedure Pubd;
  end;

type
  TAppState = (asIdle, asBusy);

  TPointRec = record
    X, Y: integer;
  end;

  tlocalBeing_1 = class
  end;

var
  GlobalCounter: integer;
  GlobalName: string;
  GlobalPoints: array[0..1] of TPoint2D;

function Clamp(AValue, AMin, AMax: integer): integer;
procedure LogMessage(const AText: string);
procedure Show(AValue: integer); overload;
procedure Show(const AValue: string); overload;
procedure Show(AValue: double); overload;
procedure Walk(ASteps: integer);
function Total(const AItems: array of integer): integer;
procedure TestTypes;

implementation

var
  LastMessage: string;

function InternalHelper(AValue: integer): integer;
begin
  Result := AValue * 2;
end;

function Clamp(AValue, AMin, AMax: integer): integer;
begin
  if AValue < AMin then
    Result := AMin
  else if AValue > AMax then
    Result := AMax
  else
    Result := AValue;
end;

procedure LogMessage(const AText: string);
var
  Stamp: string;

  procedure AppendStamp;
  begin
    Stamp := '[' + AppName + '] ';
  end;

  function Decorate(const S: string): string;
  begin
    Result := Stamp + S;
  end;

begin
  AppendStamp;
  LastMessage := Decorate(AText);
end;

procedure Show(AValue: integer);
var
  Digits: array[0..9] of char;
  Index: integer;

  procedure Fill(V: integer);
  var
    yy: integer;
  begin
    Index := 0;
    repeat
      Digits[Index] := Chr(Ord('0') + (V mod 10));
      V := V div 10;
      Inc(Index);
    until (V = 0) or (Index > High(Digits));
    yy := 1;
  end;

begin
  Fill(Abs(AValue));
  LogMessage(IntToStr(AValue));
end;

procedure Show(const AValue: string);
begin
  LogMessage(AValue);
end;

procedure Show(AValue: double);
begin
  LogMessage(FloatToStr(AValue));
end;

procedure Walk(ASteps: integer);
begin
  GlobalCounter := GlobalCounter + ASteps;
end;

function Total(const AItems: array of integer): integer;
var
  I: integer;
begin
  Result := 0;
  for I := Low(AItems) to High(AItems) do
    Result := Result + AItems[I];
end;

procedure TestTypes;
type
  TLocalFlag = (lfOn, lfOff);
var
  yy: Integer;
  NewLocalType: TLocalFlag;
  NewClass: tlocalBeing_1;
  NewUnitType: TAppState;
  Existing: Integer;
begin
  NewLocalType := lfOn;

end;

{ TBase }

procedure TBase.Walk(ASteps: integer);
begin
end;

class procedure TBase.Describe;
begin
end;

{ THuman }

procedure THuman.Listen;
begin
  FLog.Add('listen');
end;

function THuman.Age: integer;
begin
  Result := InternalHelper(FEye);
end;

constructor THuman.Create;
begin
  inherited Create;
  FEye := 0;
  FLog := TStringList.Create;
  SetLength(FNames, 0);
  Inc(FCount);
end;

destructor THuman.Destroy;
begin
  Dec(FCount);
  FLog.Free;
  inherited Destroy;
end;

procedure THuman.Walk;
begin
  FEye := FEye + 1;
  FLog.Add('walk');
end;

function THuman.Sum(const AValues: array of integer): integer;
begin
  Result := Total(AValues);
end;

function THuman.Sum(AValue: double): double;
begin
  Result := AValue * 2;
end;

class procedure THuman.Describe;
begin
  LogMessage('THuman');
end;

class function THuman.Count: integer;
begin
  Result := FCount;
end;

procedure THuman.Body;
begin
end;

{ TBeta }

procedure TBeta.Priv;
begin
end;

function TBeta.Prot: integer;
begin
  Result := FValue;
end;

constructor TBeta.Create;
begin
  FValue := 0;
  FillChar(FMatrix, SizeOf(FMatrix), 0);
  Inc(FInstances);
end;

destructor TBeta.Destroy;
begin
  Dec(FInstances);
  inherited Destroy;
end;

procedure TBeta.Pub;
begin
  Show(FValue);
end;

class procedure TBeta.Reset;
begin
  FInstances := 0;
end;

class function TBeta.Version: string;
begin
  Result := '1.0';
end;

procedure TBeta.Pubd;
begin
end;

end.
