{$mode objfpc}{$H+}
unit WKPasteFormat;

// Pure logic for WK Code Explorer paste. No form, IDE or Lazarus dependency.

interface

uses Classes;

function ParseClipboardKind(const Text: string): string;
function RenameWholeIdentifier(const Source, OldName, NewName: string): string;
function ParseClassName(const Text: string): string;
function ChooseFreeClassName(const EditorText, Name: string): string;
function ExtractClassDeclaration(const Text: string): string;
function ExtractRoutines(const Text: string): TStringList;

implementation

uses SysUtils;

const
  CRLF = #13#10;
  MarkerClass = '//MMWIN:CLASSCOPY';
  MarkerMember = '//MMWIN:MEMBERSCOPY';

function IsIdentChar(C: Char): Boolean; inline;
begin
  Result := ((C >= 'A') and (C <= 'Z')) or ((C >= 'a') and (C <= 'z')) or
            ((C >= '0') and (C <= '9')) or (C = '_');
end;

function IsIdentStartChar(C: Char): Boolean; inline;
begin
  Result := ((C >= 'A') and (C <= 'Z')) or ((C >= 'a') and (C <= 'z')) or
            (C = '_');
end;

function PosIC(const Sub, S: string): Integer;
var
  I, L: Integer;
begin
  Result := 0;
  L := Length(Sub);
  if (L = 0) or (Length(S) < L) then Exit;
  for I := 1 to Length(S) - L + 1 do
    if SameText(Copy(S, I, L), Sub) then
    begin
      Result := I;
      Exit;
    end;
end;

function TrimLR(const S: string): string;
var
  A, B: Integer;
begin
  A := 1;
  B := Length(S);
  while (A <= B) and (S[A] in [' ', #9, #13, #10]) do Inc(A);
  while (B >= A) and (S[B] in [' ', #9, #13, #10]) do Dec(B);
  if A > B then
    Result := ''
  else
    Result := Copy(S, A, B - A + 1);
end;

function GetIndent(const S: string): Integer;
var
  I: Integer;
begin
  I := 1;
  while (I <= Length(S)) and (S[I] in [' ', #9]) do Inc(I);
  Result := I - 1;
end;

function HasMarkerAtLineStart(const Text, Marker: string): Boolean;
var
  Lines: TStringList;
  I: Integer;
  T: string;
begin
  Result := False;
  Lines := TStringList.Create;
  try
    Lines.Text := Text;
    for I := 0 to Lines.Count - 1 do
    begin
      T := TrimLR(Lines[I]);
      if T = Marker then
      begin
        Result := True;
        Exit;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function ParseClipboardKind(const Text: string): string;
begin
  if HasMarkerAtLineStart(Text, MarkerClass) then
    Result := 'CLASS'
  else if HasMarkerAtLineStart(Text, MarkerMember) then
    Result := 'MEMBER'
  else
    Result := '';
end;

function RenameWholeIdentifier(const Source, OldName, NewName: string): string;
type
  TScanState = (ssNormal, ssBraceComment, ssParenComment, ssLineComment, ssString);
var
  I, L, IdentStart, IdentEnd: Integer;
  State: TScanState;
begin
  Result := '';
  if (Source = '') or (OldName = '') then
  begin
    Result := Source;
    Exit;
  end;
  L := Length(Source);
  I := 1;
  State := ssNormal;
  while I <= L do
  begin
    case State of
      ssBraceComment:
        begin
          Result := Result + Source[I];
          if Source[I] = '}' then State := ssNormal;
          Inc(I);
        end;
      ssParenComment:
        begin
          if (Source[I] = '*') and (I < L) and (Source[I + 1] = ')') then
          begin
            Result := Result + '*)';
            Inc(I, 2);
            State := ssNormal;
          end
          else
          begin
            Result := Result + Source[I];
            Inc(I);
          end;
        end;
      ssLineComment:
        begin
          Result := Result + Source[I];
          if (Source[I] = #10) or (Source[I] = #13) then State := ssNormal;
          Inc(I);
        end;
      ssString:
        begin
          if Source[I] = '''' then
          begin
            if (I < L) and (Source[I + 1] = '''') then
            begin
              Result := Result + '''''';
              Inc(I, 2);
            end
            else
            begin
              Result := Result + '''';
              Inc(I);
              State := ssNormal;
            end;
          end
          else
          begin
            Result := Result + Source[I];
            Inc(I);
          end;
        end;
      ssNormal:
        begin
          if Source[I] = '''' then
          begin
            State := ssString;
            Result := Result + '''';
            Inc(I);
          end
          else if (Source[I] = '/') and (I < L) and (Source[I + 1] = '/') then
          begin
            State := ssLineComment;
            Result := Result + '//';
            Inc(I, 2);
          end
          else if Source[I] = '{' then
          begin
            State := ssBraceComment;
            Result := Result + '{';
            Inc(I);
          end
          else if (Source[I] = '(') and (I < L) and (Source[I + 1] = '*') then
          begin
            State := ssParenComment;
            Result := Result + '(*';
            Inc(I, 2);
          end
          else if IsIdentStartChar(Source[I]) then
          begin
            IdentStart := I;
            while (I <= L) and IsIdentChar(Source[I]) do Inc(I);
            IdentEnd := I - 1;
            if (Copy(Source, IdentStart, IdentEnd - IdentStart + 1) = OldName) and
               ((IdentStart = 1) or (not IsIdentChar(Source[IdentStart - 1]))) and
               ((IdentEnd = L) or (not IsIdentChar(Source[IdentEnd + 1]))) then
              Result := Result + NewName
            else
              Result := Result + Copy(Source, IdentStart, IdentEnd - IdentStart + 1);
          end
          else
          begin
            Result := Result + Source[I];
            Inc(I);
          end;
        end;
    end;
  end;
end;

// Extract the leading identifier immediately before the first "= class" occurrence.
function ClassNameBeforeClassKeyword(const Line: string): string;
var
  P, E, S: Integer;
begin
  Result := '';
  P := PosIC('= class', Line);
  if P <= 1 then Exit;
  E := P - 1;
  while (E > 0) and (Line[E] in [' ', #9]) do Dec(E);
  S := E;
  while (S > 0) and IsIdentChar(Line[S]) do Dec(S);
  Result := Copy(Line, S + 1, E - S);
end;

function ParseClassName(const Text: string): string;
var
  Lines: TStringList;
  I: Integer;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    Lines.Text := Text;
    for I := 0 to Lines.Count - 1 do
    begin
      Result := ClassNameBeforeClassKeyword(Lines[I]);
      if Result <> '' then Exit;
    end;
  finally
    Lines.Free;
  end;
end;

procedure CollectClassNames(const Text: string; Names: TStringList);
var
  Lines: TStringList;
  I: Integer;
  Nm: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := Text;
    for I := 0 to Lines.Count - 1 do
    begin
      Nm := ClassNameBeforeClassKeyword(Lines[I]);
      if (Nm <> '') and (Names.IndexOf(Nm) < 0) then
        Names.Add(Nm);
    end;
  finally
    Lines.Free;
  end;
end;

function ChooseFreeClassName(const EditorText, Name: string): string;
var
  Names: TStringList;
  N: Integer;
  Candidate: string;
begin
  Result := Name;
  if Name = '' then Exit;
  Names := TStringList.Create;
  try
    Names.CaseSensitive := False;
    CollectClassNames(EditorText, Names);
    if Names.IndexOf(Name) < 0 then Exit;
    N := 1;
    while True do
    begin
      Candidate := Name + '_' + IntToStr(N);
      if Names.IndexOf(Candidate) < 0 then
      begin
        Result := Candidate;
        Exit;
      end;
      Inc(N);
    end;
  finally
    Names.Free;
  end;
end;

function ExtractClassDeclaration(const Text: string): string;
var
  Lines: TStringList;
  I, StartIdx, EndIdx, BaseIndent: Integer;
  T: string;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    Lines.Text := Text;
    StartIdx := -1;
    for I := 0 to Lines.Count - 1 do
      if ClassNameBeforeClassKeyword(Lines[I]) <> '' then
      begin
        StartIdx := I;
        Break;
      end;
    if StartIdx < 0 then Exit;
    BaseIndent := GetIndent(Lines[StartIdx]);
    EndIdx := -1;
    for I := StartIdx + 1 to Lines.Count - 1 do
    begin
      T := TrimLR(Lines[I]);
      if (T = 'end;') and (GetIndent(Lines[I]) <= BaseIndent) then
      begin
        EndIdx := I;
        Break;
      end;
    end;
    if EndIdx < 0 then Exit;
    // Include the { ClassName } line directly above the declaration, if present.
    if StartIdx > 0 then
    begin
      T := TrimLR(Lines[StartIdx - 1]);
      if (Length(T) > 2) and (T[1] = '{') and (T[Length(T)] = '}') then
        Dec(StartIdx);
    end;
    Result := '';
    for I := StartIdx to EndIdx do
      Result := Result + Lines[I] + CRLF;
  finally
    Lines.Free;
  end;
end;

function IsRoutineHeaderFor(const Line, ClassName: string): Boolean;
const
  Kw: array[0..7] of string = (
    'class constructor ', 'class procedure ', 'class function ',
    'procedure ', 'function ', 'constructor ', 'destructor ', 'operator '
  );
var
  I, L, DotPos: Integer;
begin
  Result := False;
  for I := 0 to High(Kw) do
  begin
    L := Length(Kw[I]);
    if (Length(Line) > L) and SameText(Copy(Line, 1, L), Kw[I]) then
    begin
      DotPos := L + Length(ClassName) + 1;
      if (Length(Line) >= DotPos) and (Line[DotPos] = '.') and
         SameText(Copy(Line, L + 1, Length(ClassName)), ClassName) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

function ExtractRoutines(const Text: string): TStringList;
var
  Lines: TStringList;
  ClassName, T: string;
  I, J, ImplIdx, HeaderIndent, EndIdx: Integer;
  Block: string;
begin
  Result := TStringList.Create;
  ClassName := ParseClassName(Text);
  if ClassName = '' then Exit;
  Lines := TStringList.Create;
  try
    Lines.Text := Text;
    ImplIdx := -1;
    for I := 0 to Lines.Count - 1 do
      if TrimLR(Lines[I]) = 'implementation' then
      begin
        ImplIdx := I;
        Break;
      end;
    if ImplIdx < 0 then Exit;
    I := ImplIdx + 1;
    while I < Lines.Count do
    begin
      T := TrimLR(Lines[I]);
      if (T = '') or ((Length(T) > 2) and (T[1] = '{') and (T[Length(T)] = '}')) then
      begin
        Inc(I);
        Continue;
      end;
      if not IsRoutineHeaderFor(T, ClassName) then
      begin
        Inc(I);
        Continue;
      end;
      HeaderIndent := GetIndent(Lines[I]);
      Block := '';
      EndIdx := -1;
      J := I;
      while J < Lines.Count do
      begin
        Block := Block + Lines[J] + CRLF;
        T := TrimLR(Lines[J]);
        if (T = 'end;') and (GetIndent(Lines[J]) <= HeaderIndent) then
        begin
          EndIdx := J;
          Break;
        end;
        Inc(J);
      end;
      if EndIdx < 0 then Break;
      Result.Add(Block);
      I := EndIdx + 1;
    end;
  finally
    Lines.Free;
  end;
end;

end.
