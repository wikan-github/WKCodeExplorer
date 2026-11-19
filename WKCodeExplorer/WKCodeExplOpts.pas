{
 /***************************************************************************
                             WKCodeExplOpts.pas
                             ------------------

  Standalone settings for the WK Code Explorer package.

  This is a clean rewrite of Lazarus ide/codeexplopts.pas.  It keeps only the
  types, constants and TCodeExplorerOptions members that WKCodeExplorer.pas
  actually uses, plus Load and Save.  There is no IDE options page and no
  dependency on any IDE-internal unit (BuildIntf / IDEOptEditorIntf / LazConf /
  IdeXmlConfigProcs / LazarusIDEStrConsts).

  Derived from Lazarus ide/codeexplopts.pas (GPL-2.0-or-later).
  ***************************************************************************/
}
unit WKCodeExplOpts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BasicCodeTools, Laz2_XMLCfg, LazLoggerBase;

type
  TCodeExplorerPage = (
    cepNone,
    cepCode,
    cepDirectives
    );

  TCodeExplorerRefresh = (
    cerManual,
    cerSwitchEditorPage,
    cerOnIdle
    );

  TCodeExplorerMode = (
    cemCategory,
    cemSource
    );

  TCodeExplorerCategory = (
    cecNone,
    cecUses,
    cecTypes,
    cecVariables,
    cecConstants,
    cecProperties,
    cecProcedures,
    cecCodeObserver,
    cecSurrounding
    );
  TCodeExplorerCategories = set of TCodeExplorerCategory;

  TCEObserverCategory = (
    cefcLongProcs,
    cefcLongParamLists,
    cefcEmptyProcs,
    cefcNestedProcs,
    cefcUnnamedConsts,
    cefcEmptyBlocks,
    cefcWrongIndentation,
    cefcPublishedPropWithoutDefault,
    cefcUnsortedClassVisibility,
    cefcEmptyClassSections,
    cefcUnsortedClassMembers,
    cefcToDos
    );
  TCEObserverCategories = set of TCEObserverCategory;

const
  FirstCodeExplorerCategory = cecUses;
  DefaultCodeExplorerCategories = [cecUses,
                cecTypes, cecVariables, cecConstants, cecProcedures];
  cefcAll = [low(TCEObserverCategory)..high(TCEObserverCategory)];
  DefaultCodeExplorerPage = cepCode;
  DefaultCodeObserverCategories = [
    cefcLongProcs,
    cefcEmptyProcs,
    cefcUnnamedConsts,
    cefcEmptyBlocks,
    cefcWrongIndentation,
    cefcPublishedPropWithoutDefault,
    cefcToDos
    ];
  DefaultCOLongProcLineCount = 50;
  DefaultCOLongParamListCount = 6;
  DefaultCONestedProcCount = 3;
  DefaultCOureCharConst = false;

  DefaultCOIgnoreConstants: array[1..2] of ansistring = ('0', '1');
  DefaultCOIgnoreConstInFuncs: array[1..15] of ansistring = (
    'Assert', 'Debug', 'DebugLn', 'DbgOut', 'write', 'writeln',
    'Format', 'FormatBuf', 'StrFmt', 'StrLFmt', 'FmtStr',
    'FloatToStrF', 'FloatToStr', 'CurrToStrF', 'FormatDateTime'
    );

  CodeExplorerVersion = 1;
  cerDefault = cerSwitchEditorPage;

  CodeExplorerPageNames: array[TCodeExplorerPage] of string = (
    '?', 'Code', 'Directives'
    );
  CodeExplorerRefreshNames: array[TCodeExplorerRefresh] of string = (
    'Manual', 'SwitchEditorPage', 'OnIdle'
    );
  CodeExplorerModeNames: array[TCodeExplorerMode] of string = (
    'Category', 'Source'
    );
  CodeExplorerCategoryNames: array[TCodeExplorerCategory] of string = (
    '?', 'Uses', 'Types', 'Variables', 'Constants', 'Properties',
    'Procedures', 'CodeObserver', 'Surrounding'
    );
  CodeObserverCategoryNames: array[TCEObserverCategory] of string = (
    'LongProcs', 'LongParamLists', 'EmptyProcs', 'NestedProcs',
    'UnnamedConsts', 'EmptyBlocks', 'WrongIndentation',
    'PublishedPropWithoutDefault', 'UnsortedClassVisibility',
    'EmptyClassSections', 'UnsortedClassMembers', 'ToDos'
    );

  { Local copies of the localized strings used by CodeExplorerLocalizedString. }
  lisCEUses = 'Uses';
  lisCETypes = 'Types';
  lisCEVariables = 'Variables';
  lisCEConstants = 'Constants';
  lisCEProcedures = 'Procedures';
  lisCEProperties = 'Properties';
  lisCodeObserver = 'Code Observer';
  lisCESurrounding = 'Surrounding';
  lisCELongProcedures = 'Long procedures';
  lisCEManyParameters = 'Many parameters';
  lisCEEmptyProcedures = 'Empty procedures';
  lisCEManyNestedProcedures = 'Many nested procedures';
  lisCEUnnamedConstants = 'Unnamed constants';
  lisCEEmptyBlocks = 'Empty blocks';
  lisCEWrongIndentation = 'Wrong indentation';
  lisCEPublishedPropertyWithoutDefault = 'Published properties without default';
  lisCEUnsortedVisibility = 'Unsorted visibility';
  lisCEEmptyClassSections = 'Empty class sections';
  lisCEUnsortedMembers = 'Unsorted members';
  lisCEToDos = 'ToDos';

type
  { TCodeExplorerOptions - plain TObject, no IDE options framework }
  TCodeExplorerOptions = class(TObject)
  private
    FMode: TCodeExplorerMode;
    FRefresh: TCodeExplorerRefresh;
    FPage: TCodeExplorerPage;
    FCategories: TCodeExplorerCategories;
    FFollowCursor: boolean;
    FObserverCategories: TCEObserverCategories;
    FObserveCharConst: boolean;
    FLongProcLineCount: integer;
    FLongParamListCount: integer;
    FNestedProcCount: integer;
    FChangeStep: integer;
    FIgnoreConstants: TStringList;
    FIgnoreConstInFuncs: TStringList;
    FOptionsFilename: string;
    procedure SetMode(const AValue: TCodeExplorerMode);
    procedure SetRefresh(const AValue: TCodeExplorerRefresh);
    procedure SetPage(const AValue: TCodeExplorerPage);
    procedure SetCategories(const AValue: TCodeExplorerCategories);
    procedure SetFollowCursor(const AValue: boolean);
    procedure SetObserverCategories(const AValue: TCEObserverCategories);
    procedure SetObserveCharConst(const AValue: boolean);
    procedure SetLongProcLineCount(const AValue: integer);
    procedure SetLongParamListCount(const AValue: integer);
    procedure SetNestedProcCount(const AValue: integer);
    function GetOptionsFilename: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Load;
    procedure Save;
    procedure IncreaseChangeStep;
    function COIgnoreConstant(p: PChar): boolean;
    function COIgnoreConstInFunc(const Func: string): boolean;
  public
    property Mode: TCodeExplorerMode read FMode write SetMode;
    property Page: TCodeExplorerPage read FPage write SetPage;
    property Refresh: TCodeExplorerRefresh read FRefresh write SetRefresh;
    property Categories: TCodeExplorerCategories read FCategories write SetCategories;
    property FollowCursor: boolean read FFollowCursor write SetFollowCursor;
    property ChangeStep: integer read FChangeStep;
    property ObserverCategories: TCEObserverCategories read FObserverCategories
                                                     write SetObserverCategories;
    property ObserveCharConst: boolean read FObserveCharConst
                                            write SetObserveCharConst;
    property LongProcLineCount: integer read FLongProcLineCount
                                             write SetLongProcLineCount;
    property LongParamListCount: integer read FLongParamListCount
                                              write SetLongParamListCount;
    property NestedProcCount: integer read FNestedProcCount
                                           write SetNestedProcCount;
    property OptionsFilename: string read GetOptionsFilename write FOptionsFilename;
  end;

var
  CodeExplorerOptions: TCodeExplorerOptions = nil;

function CodeExplorerPageNameToEnum(const s: string): TCodeExplorerPage;
function CodeExplorerRefreshNameToEnum(const s: string): TCodeExplorerRefresh;
function CodeExplorerModeNameToEnum(const s: string): TCodeExplorerMode;
function CodeExplorerCategoryNameToEnum(const s: string): TCodeExplorerCategory;
function CodeObserverCatNameToEnum(const s: string): TCEObserverCategory;
function CodeExplorerLocalizedString(const c: TCodeExplorerCategory): string;
function CodeExplorerLocalizedString(const c: TCEObserverCategory): string;
function dbgs(c: TCodeExplorerCategory): string; overload;

implementation

function CodeExplorerPageNameToEnum(const s: string): TCodeExplorerPage;
begin
  for Result := Low(TCodeExplorerPage) to High(TCodeExplorerPage) do
    if SysUtils.CompareText(CodeExplorerPageNames[Result], s) = 0 then exit;
  Result := DefaultCodeExplorerPage;
end;

function CodeExplorerRefreshNameToEnum(const s: string): TCodeExplorerRefresh;
begin
  for Result := Low(TCodeExplorerRefresh) to High(TCodeExplorerRefresh) do
    if SysUtils.CompareText(CodeExplorerRefreshNames[Result], s) = 0 then exit;
  Result := cerDefault;
end;

function CodeExplorerModeNameToEnum(const s: string): TCodeExplorerMode;
begin
  for Result := Low(TCodeExplorerMode) to High(TCodeExplorerMode) do
    if SysUtils.CompareText(CodeExplorerModeNames[Result], s) = 0 then exit;
  Result := cemCategory;
end;

function CodeExplorerCategoryNameToEnum(const s: string): TCodeExplorerCategory;
begin
  for Result := FirstCodeExplorerCategory to High(TCodeExplorerCategory) do
    if SysUtils.CompareText(CodeExplorerCategoryNames[Result], s) = 0 then exit;
  Result := cecTypes;
end;

function CodeObserverCatNameToEnum(const s: string): TCEObserverCategory;
begin
  for Result := Low(TCEObserverCategory) to High(TCEObserverCategory) do
    if SysUtils.CompareText(CodeObserverCategoryNames[Result], s) = 0 then exit;
  Result := cefcLongProcs;
end;

function CodeExplorerLocalizedString(const c: TCodeExplorerCategory): string;
begin
  case c of
    cecUses: Result := lisCEUses;
    cecTypes: Result := lisCETypes;
    cecVariables: Result := lisCEVariables;
    cecConstants: Result := lisCEConstants;
    cecProcedures: Result := lisCEProcedures;
    cecProperties: Result := lisCEProperties;
    cecCodeObserver: Result := lisCodeObserver;
    cecSurrounding: Result := lisCESurrounding;
  else
    Result := '?';
  end;
end;

function CodeExplorerLocalizedString(const c: TCEObserverCategory): string;
begin
  case c of
    cefcLongProcs: Result := lisCELongProcedures;
    cefcLongParamLists: Result := lisCEManyParameters;
    cefcEmptyProcs: Result := lisCEEmptyProcedures;
    cefcNestedProcs: Result := lisCEManyNestedProcedures;
    cefcUnnamedConsts: Result := lisCEUnnamedConstants;
    cefcEmptyBlocks: Result := lisCEEmptyBlocks;
    cefcWrongIndentation: Result := lisCEWrongIndentation;
    cefcPublishedPropWithoutDefault: Result := lisCEPublishedPropertyWithoutDefault;
    cefcUnsortedClassVisibility: Result := lisCEUnsortedVisibility;
    cefcEmptyClassSections: Result := lisCEEmptyClassSections;
    cefcUnsortedClassMembers: Result := lisCEUnsortedMembers;
    cefcToDos: Result := lisCEToDos;
  end;
end;

function dbgs(c: TCodeExplorerCategory): string;
begin
  Result := CodeExplorerCategoryNames[c];
end;

{ TCodeExplorerOptions }

constructor TCodeExplorerOptions.Create;
begin
  inherited Create;
  FIgnoreConstants := TStringList.Create;
  FIgnoreConstants.CaseSensitive := False;
  FIgnoreConstants.Sorted := True;
  FIgnoreConstants.Duplicates := dupIgnore;
  FIgnoreConstInFuncs := TStringList.Create;
  FIgnoreConstInFuncs.CaseSensitive := False;
  FIgnoreConstInFuncs.Sorted := True;
  FIgnoreConstInFuncs.Duplicates := dupIgnore;
  Clear;
end;

destructor TCodeExplorerOptions.Destroy;
begin
  FreeAndNil(FIgnoreConstants);
  FreeAndNil(FIgnoreConstInFuncs);
  inherited Destroy;
end;

procedure TCodeExplorerOptions.IncreaseChangeStep;
begin
  if FChangeStep = high(integer) then
    FChangeStep := low(integer)
  else
    Inc(FChangeStep);
end;

procedure TCodeExplorerOptions.Clear;
var
  i: integer;
begin
  IncreaseChangeStep;
  FMode := cemCategory;
  FRefresh := cerDefault;
  FFollowCursor := true;
  FPage := DefaultCodeExplorerPage;
  FCategories := DefaultCodeExplorerCategories;
  FObserverCategories := DefaultCodeObserverCategories;
  FLongProcLineCount := DefaultCOLongProcLineCount;
  FLongParamListCount := DefaultCOLongParamListCount;
  FNestedProcCount := DefaultCONestedProcCount;
  FObserveCharConst := DefaultCOureCharConst;
  FIgnoreConstants.Clear;
  FIgnoreConstInFuncs.Clear;
  for i := Low(DefaultCOIgnoreConstants) to High(DefaultCOIgnoreConstants) do
    FIgnoreConstants.Add(DefaultCOIgnoreConstants[i]);
  for i := Low(DefaultCOIgnoreConstInFuncs) to High(DefaultCOIgnoreConstInFuncs) do
    FIgnoreConstInFuncs.Add(DefaultCOIgnoreConstInFuncs[i]);
end;

procedure TCodeExplorerOptions.SetMode(const AValue: TCodeExplorerMode);
begin
  if FMode = AValue then exit;
  FMode := AValue;
  IncreaseChangeStep;
end;

procedure TCodeExplorerOptions.SetPage(const AValue: TCodeExplorerPage);
begin
  if FPage = AValue then exit;
  FPage := AValue;
  IncreaseChangeStep;
end;

procedure TCodeExplorerOptions.SetRefresh(const AValue: TCodeExplorerRefresh);
begin
  if FRefresh = AValue then exit;
  FRefresh := AValue;
  IncreaseChangeStep;
end;

procedure TCodeExplorerOptions.SetCategories(const AValue: TCodeExplorerCategories);
begin
  if FCategories = AValue then exit;
  FCategories := AValue;
  IncreaseChangeStep;
end;

procedure TCodeExplorerOptions.SetFollowCursor(const AValue: boolean);
begin
  if FFollowCursor = AValue then exit;
  FFollowCursor := AValue;
  IncreaseChangeStep;
end;

procedure TCodeExplorerOptions.SetObserverCategories(
  const AValue: TCEObserverCategories);
begin
  if FObserverCategories = AValue then exit;
  FObserverCategories := AValue;
  IncreaseChangeStep;
end;

procedure TCodeExplorerOptions.SetObserveCharConst(const AValue: boolean);
begin
  if FObserveCharConst = AValue then exit;
  FObserveCharConst := AValue;
  IncreaseChangeStep;
end;

procedure TCodeExplorerOptions.SetLongProcLineCount(const AValue: integer);
begin
  if FLongProcLineCount = AValue then exit;
  FLongProcLineCount := AValue;
  IncreaseChangeStep;
end;

procedure TCodeExplorerOptions.SetLongParamListCount(const AValue: integer);
begin
  if FLongParamListCount = AValue then exit;
  FLongParamListCount := AValue;
  IncreaseChangeStep;
end;

procedure TCodeExplorerOptions.SetNestedProcCount(const AValue: integer);
begin
  if FNestedProcCount = AValue then exit;
  FNestedProcCount := AValue;
  IncreaseChangeStep;
end;

function TCodeExplorerOptions.GetOptionsFilename: string;
begin
  if FOptionsFilename = '' then
    FOptionsFilename := IncludeTrailingPathDelimiter(GetAppConfigDir(False))
      + 'wkcodeexploreroptions.xml';
  Result := FOptionsFilename;
end;

function TCodeExplorerOptions.COIgnoreConstant(p: PChar): boolean;
var
  i: integer;
begin
  for i := 0 to FIgnoreConstants.Count - 1 do
    if CompareAtom(p, PChar(FIgnoreConstants[i]), False) = 0 then
      exit(True);
  Result := False;
end;

function TCodeExplorerOptions.COIgnoreConstInFunc(const Func: string): boolean;
begin
  Result := FIgnoreConstInFuncs.IndexOf(Func) >= 0;
end;

procedure TCodeExplorerOptions.Load;
var
  Cfg: TXMLConfig;
  c: TCodeExplorerCategory;
  f: TCEObserverCategory;
  i: integer;
  Base: string;
begin
  Base := 'WKCodeExplorer/';
  if not FileExists(GetOptionsFilename) then
  begin
    Clear;
    Exit;
  end;
  try
    Cfg := TXMLConfig.Create(GetOptionsFilename);
    try
      FMode := CodeExplorerModeNameToEnum(
        Cfg.GetValue(Base + 'Mode/Value', CodeExplorerModeNames[FMode]));
      FRefresh := CodeExplorerRefreshNameToEnum(
        Cfg.GetValue(Base + 'Refresh/Value', CodeExplorerRefreshNames[FRefresh]));
      FPage := CodeExplorerPageNameToEnum(
        Cfg.GetValue(Base + 'Page/Value', CodeExplorerPageNames[FPage]));
      FFollowCursor := Cfg.GetValue(Base + 'FollowCursor', FFollowCursor);

      FCategories := [];
      for c := FirstCodeExplorerCategory to High(TCodeExplorerCategory) do
        if Cfg.GetValue(Base + 'Categories/' + CodeExplorerCategoryNames[c],
                        c in FCategories) then
          Include(FCategories, c);

      FObserverCategories := [];
      for f := Low(TCEObserverCategory) to High(TCEObserverCategory) do
        if Cfg.GetValue(Base + 'Observer/' + CodeObserverCategoryNames[f],
                        f in FObserverCategories) then
          Include(FObserverCategories, f);

      FObserveCharConst := Cfg.GetValue(Base + 'Observer/CharConsts',
        FObserveCharConst);
      FLongProcLineCount := Cfg.GetValue(Base + 'Observer/LongProcLineCount',
        FLongProcLineCount);
      FLongParamListCount := Cfg.GetValue(Base + 'Observer/LongParamListCount',
        FLongParamListCount);
      FNestedProcCount := Cfg.GetValue(Base + 'Observer/NestedProcCount',
        FNestedProcCount);

      FIgnoreConstants.Clear;
      FIgnoreConstants.CommaText := Cfg.GetValue(Base + 'Observer/IgnoreConstants', '');
      if FIgnoreConstants.Count = 0 then
        for i := Low(DefaultCOIgnoreConstants) to High(DefaultCOIgnoreConstants) do
          FIgnoreConstants.Add(DefaultCOIgnoreConstants[i]);
      FIgnoreConstInFuncs.Clear;
      FIgnoreConstInFuncs.CommaText := Cfg.GetValue(Base + 'Observer/IgnoreInFuncs', '');
      if FIgnoreConstInFuncs.Count = 0 then
        for i := Low(DefaultCOIgnoreConstInFuncs) to High(DefaultCOIgnoreConstInFuncs) do
          FIgnoreConstInFuncs.Add(DefaultCOIgnoreConstInFuncs[i]);
    finally
      Cfg.Free;
    end;
  except
    on E: Exception do
      DebugLn('[WKCodeExplOpts.Load] error reading "', GetOptionsFilename,
              '" ', E.Message);
  end;
  IncreaseChangeStep;
end;

procedure TCodeExplorerOptions.Save;
var
  Cfg: TXMLConfig;
  c: TCodeExplorerCategory;
  f: TCEObserverCategory;
  Base: string;
begin
  Base := 'WKCodeExplorer/';
  try
    ForceDirectories(ExtractFileDir(GetOptionsFilename));
    Cfg := TXMLConfig.CreateClean(GetOptionsFilename);
    try
      Cfg.SetDeleteValue(Base + 'Version/Value', CodeExplorerVersion, 0);
      Cfg.SetDeleteValue(Base + 'Mode/Value',
        CodeExplorerModeNames[FMode], CodeExplorerModeNames[cemCategory]);
      Cfg.SetDeleteValue(Base + 'Refresh/Value',
        CodeExplorerRefreshNames[FRefresh], CodeExplorerRefreshNames[cerDefault]);
      Cfg.SetDeleteValue(Base + 'Page/Value',
        CodeExplorerPageNames[FPage], CodeExplorerPageNames[DefaultCodeExplorerPage]);
      Cfg.SetDeleteValue(Base + 'FollowCursor', FFollowCursor, true);
      for c := FirstCodeExplorerCategory to High(TCodeExplorerCategory) do
        Cfg.SetDeleteValue(Base + 'Categories/' + CodeExplorerCategoryNames[c],
          c in FCategories, c in DefaultCodeExplorerCategories);
      for f := Low(TCEObserverCategory) to High(TCEObserverCategory) do
        Cfg.SetDeleteValue(Base + 'Observer/' + CodeObserverCategoryNames[f],
          f in FObserverCategories, f in DefaultCodeObserverCategories);
      Cfg.SetDeleteValue(Base + 'Observer/CharConsts', FObserveCharConst,
        DefaultCOureCharConst);
      Cfg.SetDeleteValue(Base + 'Observer/LongProcLineCount', FLongProcLineCount,
        DefaultCOLongProcLineCount);
      Cfg.SetDeleteValue(Base + 'Observer/LongParamListCount', FLongParamListCount,
        DefaultCOLongParamListCount);
      Cfg.SetDeleteValue(Base + 'Observer/NestedProcCount', FNestedProcCount,
        DefaultCONestedProcCount);
      Cfg.SetDeleteValue(Base + 'Observer/IgnoreConstants',
        FIgnoreConstants.CommaText, '');
      Cfg.SetDeleteValue(Base + 'Observer/IgnoreInFuncs',
        FIgnoreConstInFuncs.CommaText, '');
      Cfg.Flush;
    finally
      Cfg.Free;
    end;
  except
    on E: Exception do
      DebugLn('[WKCodeExplOpts.Save] error writing "', GetOptionsFilename,
              '" ', E.Message);
  end;
end;

end.
