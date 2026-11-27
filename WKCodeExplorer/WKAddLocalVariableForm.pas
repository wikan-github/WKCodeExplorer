unit WKAddLocalVariableForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs, Graphics, LazIDEIntf;

function WKTypeHistoryFileName: string;
procedure WKLoadTypeHistory(List: TStrings);
procedure WKSaveTypeHistory(List: TStrings);
procedure WKAddToTypeHistory(const AType: string);

type
  { TWKAddLocalVariableForm }
  TWKAddLocalVariableForm = class(TForm)
  published
    BtnCancel: TButton;
    BtnEditHistory: TButton;
    BtnOK: TButton;
    CbHistory: TComboBox;
    CbKind: TComboBox;
    EdName: TEdit;
    EdType: TComboBox;
    LblHistory: TLabel;
    LblKind: TLabel;
    LblName: TLabel;
    LblType: TLabel;
    procedure BtnCancelClick(Sender: TObject);
    procedure CbKindChange(Sender: TObject);
    procedure EditHistoryClick(Sender: TObject);
    procedure EdNameChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LblNameClick(Sender: TObject);
  private
    FFiltering: Boolean;
    FHistoryFull: TStringList;
    FTypeFull: TStringList;
    procedure CbHistoryChange(Sender: TObject);
    procedure CbHistorySelect(Sender: TObject);
    procedure EdTypeChange(Sender: TObject);
    procedure FilterCombo(ACombo: TComboBox; AFull: TStrings);
  public
    destructor Destroy; override;
    procedure InitializeDialog(UnitTypes, LocalTypes: TStrings;
      const AName, AType: string);
  end;

function WKShowAddLocalVariableDialog(UnitTypes, LocalTypes: TStrings;
  var AName, AType: string): Boolean;

implementation

{$R *.lfm}

const
  WKPrimitiveTypes: array[0..17] of string = (
    'Integer', 'Cardinal', 'Int64', 'Word', 'Byte', 'ShortInt', 'SmallInt',
    'LongInt', 'Single', 'Double', 'Extended', 'Currency', 'Boolean', 'Char',
    'String', 'AnsiString', 'Pointer', 'Variant'
  );
  WKTypeHistoryMax = 30;

function WKTypeHistoryFileName: string;
begin
  Result := IncludeTrailingPathDelimiter(GetUserDir) + '.wkcodeexplorer_types.txt';
end;

procedure WKLoadTypeHistory(List: TStrings);
var
  FN: string;
  F: TextFile;
  Line: string;
begin
  List.Clear;
  FN := WKTypeHistoryFileName;
  if not FileExists(FN) then Exit;
  AssignFile(F, FN);
  try
    Reset(F);
    try
      while not Eof(F) do
      begin
        ReadLn(F, Line);
        Line := Trim(Line);
        if Line <> '' then
          List.Add(Line);
      end;
    finally
      CloseFile(F);
    end;
  except
    // ignore read errors; history is optional
  end;
end;

procedure WKSaveTypeHistory(List: TStrings);
var
  FN: string;
  F: TextFile;
  I, Count: Integer;
begin
  FN := WKTypeHistoryFileName;
  AssignFile(F, FN);
  try
    Rewrite(F);
    try
      Count := List.Count;
      if Count > WKTypeHistoryMax then Count := WKTypeHistoryMax;
      for I := 0 to Count - 1 do
        WriteLn(F, List[I]);
    finally
      CloseFile(F);
    end;
  except
    // ignore write errors; history is optional
  end;
end;

procedure WKAddToTypeHistory(const AType: string);
var
  Hist: TStringList;
  T, S: string;
  I: Integer;
begin
  T := Trim(AType);
  if T = '' then Exit;
  Hist := TStringList.Create;
  try
    WKLoadTypeHistory(Hist);
    for I := Hist.Count - 1 downto 0 do
    begin
      S := Trim(Hist[I]);
      if SameText(S, T) then
        Hist.Delete(I);
    end;
    Hist.Insert(0, T);
    while Hist.Count > WKTypeHistoryMax do
      Hist.Delete(Hist.Count - 1);
    WKSaveTypeHistory(Hist);
  finally
    Hist.Free;
  end;
end;

procedure TWKAddLocalVariableForm.FormCreate(Sender: TObject);
begin
  FTypeFull := TStringList.Create;
  FHistoryFull := TStringList.Create;
  EdType.OnChange := @EdTypeChange;
  CbHistory.OnChange := @CbHistoryChange;
  CbHistory.OnSelect := @CbHistorySelect;
end;

procedure TWKAddLocalVariableForm.LblNameClick(Sender: TObject);
begin

end;

destructor TWKAddLocalVariableForm.Destroy;
begin
  FHistoryFull.Free;
  FTypeFull.Free;
  inherited Destroy;
end;

procedure TWKAddLocalVariableForm.FilterCombo(ACombo: TComboBox; AFull: TStrings);
var
  I: Integer;
  Filter, SavedText, S: string;
begin
  if FFiltering then Exit;
  if (ACombo = nil) or (AFull = nil) then Exit;
  FFiltering := True;
  SavedText := ACombo.Text;
  Filter := LowerCase(SavedText);
  ACombo.Items.BeginUpdate;
  try
    ACombo.Items.Clear;
    for I := 0 to AFull.Count - 1 do
    begin
      S := AFull[I];
      if (Filter = '') or (Pos(Filter, LowerCase(S)) > 0) then
        ACombo.Items.Add(S);
    end;
  finally
    ACombo.Items.EndUpdate;
    if ACombo.Text <> SavedText then
      ACombo.Text := SavedText;
    ACombo.SelStart := Length(ACombo.Text);
    FFiltering := False;
  end;
end;

procedure TWKAddLocalVariableForm.EdTypeChange(Sender: TObject);
begin
  FilterCombo(EdType, FTypeFull);
end;

procedure TWKAddLocalVariableForm.CbHistoryChange(Sender: TObject);
begin
  FilterCombo(CbHistory, FHistoryFull);
end;

procedure TWKAddLocalVariableForm.CbHistorySelect(Sender: TObject);
begin
  if CbHistory.ItemIndex >= 0 then
    EdType.Text := CbHistory.Items[CbHistory.ItemIndex];
end;

procedure TWKAddLocalVariableForm.EditHistoryClick(Sender: TObject);
var
  F: TextFile;
begin
  if not FileExists(WKTypeHistoryFileName) then
  begin
    AssignFile(F, WKTypeHistoryFileName);
    try
      Rewrite(F);
    finally
      CloseFile(F);
    end;
  end;
  LazarusIDE.DoOpenEditorFile(WKTypeHistoryFileName, -1, -1, [ofOnlyIfExists]);
end;

procedure TWKAddLocalVariableForm.CbKindChange(Sender: TObject);
begin

end;

procedure TWKAddLocalVariableForm.BtnCancelClick(Sender: TObject);
begin

end;

procedure TWKAddLocalVariableForm.EdNameChange(Sender: TObject);
begin

end;

procedure TWKAddLocalVariableForm.InitializeDialog(UnitTypes, LocalTypes: TStrings;
  const AName, AType: string);
var
  Hist: TStringList;
  I: Integer;
  S: string;
begin
  if FTypeFull = nil then
    FormCreate(nil);
  Hist := TStringList.Create;
  FFiltering := True;
  try
    FTypeFull.Clear;
    FHistoryFull.Clear;

    for I := Low(WKPrimitiveTypes) to High(WKPrimitiveTypes) do
      if FTypeFull.IndexOf(WKPrimitiveTypes[I]) < 0 then
        FTypeFull.Add(WKPrimitiveTypes[I]);

    if UnitTypes <> nil then
      for I := 0 to UnitTypes.Count - 1 do
      begin
        S := UnitTypes[I];
        if FTypeFull.IndexOf(S) < 0 then
          FTypeFull.Add(S);
      end;

    if LocalTypes <> nil then
      for I := 0 to LocalTypes.Count - 1 do
      begin
        S := LocalTypes[I];
        if FTypeFull.IndexOf(S) < 0 then
          FTypeFull.Add(S);
      end;

    WKLoadTypeHistory(Hist);
    for I := 0 to Hist.Count - 1 do
    begin
      S := Trim(Hist[I]);
      if (S <> '') and (FHistoryFull.IndexOf(S) < 0) then
        FHistoryFull.Add(S);
    end;

    EdType.Items.Assign(FTypeFull);
    CbHistory.Items.Assign(FHistoryFull);
    CbKind.ItemIndex := 0;
    CbKind.Enabled := False;
    EdName.Text := AName;
    EdType.Text := AType;
    EdType.SelStart := Length(EdType.Text);
  finally
    FFiltering := False;
    Hist.Free;
  end;
end;

function WKShowAddLocalVariableDialog(UnitTypes, LocalTypes: TStrings;
  var AName, AType: string): Boolean;
var
  Form: TWKAddLocalVariableForm;
  Chosen: string;
begin
  Result := False;
  Form := TWKAddLocalVariableForm.Create(nil);
  try
    if AType = '' then AType := 'Integer';
    Form.InitializeDialog(UnitTypes, LocalTypes, AName, AType);
    if Form.ShowModal = mrOK then
    begin
      AName := Trim(Form.EdName.Text);
      Chosen := Trim(Form.EdType.Text);
      if Chosen = '' then Chosen := 'Integer';
      AType := Chosen;
      WKAddToTypeHistory(Chosen);
      Result := True;
    end;
  finally
    Form.Free;
  end;
end;

initialization
  RegisterClass(TWKAddLocalVariableForm);

end.
