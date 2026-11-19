{$mode objfpc}{$H+}
unit WKCopyFormat;

interface

uses Classes;

{ Builds the exact MMX CLASSCOPY format text from class source text and implementations. }
function BuildClassCopyText(const Source, ClassName: string;
  TypeStart, TypeEnd: integer; const Implementations: TStringList): string;

implementation

function BuildClassCopyText(const Source, ClassName: string;
  TypeStart, TypeEnd: integer; const Implementations: TStringList): string;
var
  I: Integer;
  P, Q, R: string;
  CStart, CEnd: Integer;
  InClass: Boolean;
  Extracted: string;
  ExtractedLine: string;
  CommentPrefix: string;
  RestLine: string;
  C1, C2: Integer;
  Lines: TStringList;
begin
  P := '';
  { marker }
  P := P + '//MMWIN:CLASSCOPY' + chr(13) + chr(10);
  { unit line }
  P := P + 'unit _MM_Copy_Buffer_;' + chr(13) + chr(10);
  { blank }
  P := P + chr(13) + chr(10);
  { interface }
  P := P + 'interface' + chr(13) + chr(10);
  { blank }
  P := P + chr(13) + chr(10);
  { type }
  P := P + 'type' + chr(13) + chr(10);
  { Split Source into lines }
  Lines := TStringList.Create;
  try
    Lines.Text := Source;
    { Find THuman = class line }
    InClass := False;
    CStart := -1;
    CEnd := -1;
    for I := 0 to Lines.Count - 1 do
    begin
      if Pos(ClassName + ' = class', Lines[I]) > 0 then
      begin
        InClass := True;
        CStart := I + 1;  { 1-based line number }
      end;
      if InClass and (Pos('end;', Lines[I]) > 0) then
      begin
        CEnd := I + 1;  { 1-based line number }
        Break;
      end;
    end;
    { Extract class declaration }
    Extracted := '';
    if (CStart > 0) and (CEnd > 0) then
    begin
      for I := CStart to CEnd do
      begin
        ExtractedLine := Lines[I - 1];
        CommentPrefix := '{ ' + ClassName + ' }';
        C1 := Pos(CommentPrefix, ExtractedLine);
        if C1 > 0 then
        begin
          C2 := C1 + Length(CommentPrefix) - 1;
          RestLine := Copy(ExtractedLine, C2 + 1);
          while (Length(RestLine) > 0) and (RestLine[1] = ' ') do
            Delete(RestLine, 1, 1);
          if Length(RestLine) > 0 then
            Extracted := Extracted + RestLine + chr(13) + chr(10);
        end
        else
          Extracted := Extracted + ExtractedLine + chr(13) + chr(10);
      end;
    end;
  finally
    Lines.Free;
  end;
  { Add class declaration section, comment once above the class }
  Q := '  { ' + ClassName + ' }' + chr(13) + chr(10);
  Q := Q + Extracted;
  P := P + Q + chr(13) + chr(10);
  { implementation }
  P := P + 'implementation' + chr(13) + chr(10);
  { blank }
  P := P + chr(13) + chr(10);
  { comment once above the implementations }
  Q := '  { ' + ClassName + ' }' + chr(13) + chr(10);
  P := P + Q + chr(13) + chr(10);
  { routines, each one without comment prefix }
  for I := 0 to Implementations.Count - 1 do
  begin
    R := Implementations.Strings[I];
    P := P + R + chr(13) + chr(10);
    if (R = 'end;') then
      P := P + chr(13) + chr(10);
  end;
  { blank before end }
  P := P + chr(13) + chr(10);
  { end }
  P := P + 'end.' + chr(13) + chr(10);
  Result := P;
end;

end.