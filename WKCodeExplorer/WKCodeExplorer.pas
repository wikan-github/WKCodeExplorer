{
 /***************************************************************************
                            codeexplorer.pas
                            ----------------

 ***************************************************************************/

 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 51 Franklin Street - Fifth Floor, Boston, MA 02110-1335, USA.   *
 *                                                                         *
 ***************************************************************************

  Abstract:
    Window showing the current source as tree structure.
    Normally it shows the codetools nodes of the current unit in the
    source editor. If an include file is open, the corresponding unit is shown.
}
unit WKCodeExplorer;

{$mode objfpc}{$H+}

interface

{$inline on}
{$warn 6058 off}

uses
  // RTL+FCL
  Classes, SysUtils, Types, AVL_Tree,
  // LazUtils
  LazUtilities, LazStringUtils, LazLoggerBase, LazTracer,
  // LCL
  LCLType, LMessages, Forms, Controls, Dialogs, Buttons, ComCtrls, Menus, ExtCtrls, EditBtn, Clipbrd,
  // SynEdit
  SynEdit,
  // CodeTools
  FileProcs, BasicCodeTools, CustomCodeTool, CodeToolManager, CodeAtom,
  CodeCache, CodeTree, KeywordFuncLists, FindDeclarationTool, DirectivesTree,
  PascalParserTool,
  // IDEIntf
  LazIDEIntf, IDECommands, MenuIntf, SrcEditorIntf, IDEDialogs, IDEImagesIntf,
  IDEWindowIntf,
  // Local plain settings class (no IDE-internal units)
  WKCodeExplOpts, WKCopyFormat, WKPasteFormat;

const
  { Local copies of the IDE-only string constants.  Values are taken from
    LazarusIDEStrConsts, IdeConfStrConsts and IdePackagerStrConsts. }
  lisCCOErrorCaption           = 'Error';
  lisCEFilter                  = '(filter)';
  lisCEModeShowCategories      = 'Show Categories';
  lisCEModeShowSourceNodes     = 'Show Source Nodes';
  lisCESurrounding             = 'Surrounding';
  lisCode                      = 'Code';
  lisCodeObserver              = 'Code Observer';
  lisDirectives                = 'Directives';
  lisMenuJumpTo                = 'Jump to';
  lisMenuJumpToImplementation  = 'Jump to Implementation';
  lisMenuViewCodeExplorer      = 'WKCodeExplorer';
  lisOptions                   = 'Options';
  lisRename                    = 'Rename';
  lisShowPositionOfSourceEditor = 'Show position of source editor';
  lisTreeNeedsRefresh          = 'Tree needs refresh';
  dlgUnitDepRefresh            = 'Refresh';
  lisCEIn                      = '%s in %s';

type
  TWKCodeExplorerView = class;

  TOnGetDirectivesTree =
     procedure(Sender: TObject; var ADirectivesTool: TDirectivesTool) of object;
  TOnJumpToCode = procedure(Sender: TObject; const Filename: string;
                            const Caret: TPoint; TopLine: integer) of object;

  TWKCodeExplorerViewFlag = (
    cevCodeRefreshNeeded,
    cevDirectivesRefreshNeeded,
    cevRefreshing,
    cevCheckOnIdle // check if a refresh is needed on next idle
    );
  TWKCodeExplorerViewFlags = set of TWKCodeExplorerViewFlag;
  
  TCodeObsStackItemType = (
    cositNone,
    cositBegin,
    cositRepeat,
    cositTry,
    cositFinally,
    cositExcept,
    cositCase,
    cositCaseElse,
    cositRoundBracketOpen,
    cositEdgedBracketOpen
    );
  TCodeObsStackItem = record
    StartPos: integer;
    Typ: TCodeObsStackItemType;
    StatementStartPos: integer;
  end;
  TCodeObsStack = ^TCodeObsStackItem;

  { TCodeObserverStatementState }

  TCodeObserverStatementState = class
  private
    function GetStatementStartPos: integer;
    procedure SetStatementStartPos(const AValue: integer);
  public
    Stack: TCodeObsStack;
    StackPtr: integer;
    StackCapacity: integer;
    IgnoreConstLevel: integer;
    TopLvlStatementStartPos: integer;
    destructor Destroy; override;
    procedure Clear;
    procedure Reset;
    procedure Push(Typ: TCodeObsStackItemType; StartPos: integer);
    function Pop: TCodeObsStackItemType;
    procedure PopAll;
    function TopType: TCodeObsStackItemType;
    property StatementStartPos: integer read GetStatementStartPos write SetStatementStartPos;
  end;

  { TWKCodeExplorerView }

  TWKCodeExplorerView = class(TForm)
    CodeFilterEdit: TEditButton;
    CodePage: TTabSheet;
    CodeTreeview: TTreeView;
    DirectivesFilterEdit: TEditButton;
    DirectivesPage: TTabSheet;
    DirectivesTreeView: TTreeView;
    IdleTimer1: TIdleTimer;
    Imagelist1: TImageList;
    MainNotebook: TPageControl;
    MenuItem1: TMenuItem;
    CodeTreeviewButtonPanel: TPanel;
    CodeOptionsSpeedButton: TSpeedButton;
    CodeRefreshSpeedButton: TSpeedButton;
    CodeModeSpeedButton: TSpeedButton;
    DirOptionsSpeedButton: TSpeedButton;
    DirRefreshSpeedButton: TSpeedButton;
    TreePopupmenu: TPopupMenu;
    WKCopyMenuItem: TMenuItem;
    WKPasteMenuItem: TMenuItem;
    procedure CodeExplorerViewCreate(Sender: TObject);
    procedure CodeExplorerViewDestroy(Sender: TObject);
    procedure CodeFilterEditChange(Sender: TObject);
    procedure CodeTreeviewMouseDown(Sender: TObject; Button: TMouseButton;
      {%H-}Shift: TShiftState; X, Y: Integer);
    procedure DirectivesFilterEditChange(Sender: TObject);
    procedure DirRefreshSpeedButtonClick(Sender: TObject);
    procedure FilterEditButtonClick(Sender: TObject);
    procedure FilterEditEnter(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure IdleTimer1Timer(Sender: TObject);
    procedure JumpToMenuItemClick(Sender: TObject);
    procedure JumpToImplementationMenuItemClick(Sender: TObject);
    procedure CloseIDEHandler(Sender: TObject);
    procedure ShowSrcEditPosMenuItemClick(Sender: TObject);
    procedure MainNotebookPageChanged(Sender: TObject);
    procedure CodeModeSpeedButtonClick(Sender: TObject);
    procedure CodeRefreshSpeedButtonClick(Sender: TObject);
    procedure OptionsSpeedButtonClick(Sender: TObject);
    procedure RefreshMenuItemClick(Sender: TObject);
    procedure RenameMenuItemClick(Sender: TObject);
    procedure WKCopyMenuItemClick(Sender: TObject);
    procedure WKPasteMenuItemClick(Sender: TObject);
    function FindClassCTNode(CurNode: TObject): TCodeTreeNode;
    procedure TreePopupmenuPopup(Sender: TObject);
    procedure TreeviewDblClick(Sender: TObject);
    procedure TreeviewDeletion(Sender: TObject; Node: TTreeNode);
    procedure TreeviewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure UserInputHandler(Sender: TObject; var {%H-}Msg: TLMessage);
  private
    fCategoryNodes: array[TCodeExplorerCategory] of TTreeNode;
    FCodeFilename: string;
    FCodeCmd1, FCodeCmd2, FCodeCmd3: TIDECommand;
    FDirectivesFilename: string;
    FFlags: TWKCodeExplorerViewFlags;
    FLastCodeChangeStep: integer;
    FLastCodeFilter: string;
    fLastCodeOptionsChangeStep: integer;
    FLastCodeValid: boolean;
    FLastCodeXY: TPoint;
    FLastCode: TCodeBuffer;
    FLastDirectivesChangeStep: integer;
    FLastDirectivesFilter: string;
    FLastMode: TCodeExplorerMode;
    FMode: TCodeExplorerMode;
    fObserverCatNodes: array[TCEObserverCategory] of TTreeNode;
    fObserverCatOverflow: array[TCEObserverCategory] of boolean;
    fObserverNode: TTreeNode;
    fSurroundingNode: TTreeNode;
    FOnGetDirectivesTree: TOnGetDirectivesTree;
    FOnJumpToCode: TOnJumpToCode;
    FOnShowOptions: TNotifyEvent;
    fSortCodeTool: TCodeTool;
    fLastCodeTool: TCodeTool;
    fCodeSortedForStartPos: TAvlTree;// tree of TTreeNode sorted for TViewNodeData(Node.Data).StartPos, secondary EndPos
    fNodesWithPath: TAvlTree; // tree of TViewNodeData sorted for Path and Params
    FUpdateCount: integer;
    ImgIDClass: Integer;
    ImgIDClassInterface: Integer;
    ImgIDRecord: Integer;
    ImgIDEnum: Integer;
    ImgIDHelper: Integer;
    ImgIDConst: Integer;
    ImgIDSection: Integer;
    ImgIDDefault: integer;
    ImgIDFinalization: Integer;
    ImgIDImplementation: Integer;
    ImgIDInitialization: Integer;
    ImgIDInterface: Integer;
    ImgIDProcedure: Integer;
    ImgIDFunction: Integer;
    ImgIDConstructor: Integer;
    ImgIDDestructor: Integer;
    ImgIDProgram: Integer;
    ImgIDProperty: Integer;
    ImgIDOperator: Integer;
    ImgIDPropertyReadOnly: Integer;
    ImgIDType: Integer;
    ImgIDUnit: Integer;
    ImgIDVariable: Integer;
    ImgIDHint: Integer;
    ImgIDLabel: Integer;
    procedure AssignAllImages;
    procedure ClearCodeTreeView;
    procedure ClearDirectivesTreeView;
    function GetCodeFilter: string;
    function GetCurrentPage: TCodeExplorerPage;
    function GetDirectivesFilter: string;
    function GetCodeNodeDescription(ACodeTool: TCodeTool;
                                   CodeNode: TCodeTreeNode): string;
    function GetDirectiveNodeDescription(ADirectivesTool: TDirectivesTool;
                                         Node: TCodeTreeNode): string;
    function GetCodeNodeImage(Tool: TFindDeclarationTool;
                              CodeNode: TCodeTreeNode): integer;
    function GetDirectiveNodeImage(CodeNode: TCodeTreeNode): integer;
    procedure CreateIdentifierNodes(ACodeTool: TCodeTool; CodeNode: TCodeTreeNode;
                          ParentViewNode: TTreeNode);
    function GetCTNodePath(ACodeTool: TCodeTool; CodeNode: TCodeTreeNode): string;
    procedure CreateNodePath(ACodeTool: TCodeTool; aNodeData: TObject);
    procedure AddImplementationNode(ACodeTool: TCodeTool; CodeNode: TCodeTreeNode);
    procedure CreateDirectiveNodes(ADirectivesTool: TDirectivesTool;
      CodeNode: TCodeTreeNode; ParentViewNode: TTreeNode);
    procedure CreateObservations(Tool: TCodeTool);
    function CreateObserverNode(Tool: TCodeTool; f: TCEObserverCategory): TTreeNode;
    procedure CreateObserverNodesForStatement(Tool: TCodeTool;
                            CodeNode: TCodeTreeNode; StartPos, EndPos: integer;
                            ObserverState: TCodeObserverStatementState);
    procedure FindObserverTodos(Tool: TCodeTool);
    procedure CreateSurrounding(Tool: TCodeTool);
    procedure DeleteTVNode(TVNode: TTreeNode);
    procedure SetCodeFilter(const AValue: string);
    procedure SetCurrentPage(const AValue: TCodeExplorerPage);
    procedure SetDirectivesFilter(const AValue: string);
    procedure SetMode(AMode: TCodeExplorerMode);
    procedure UpdateMode;
    procedure UpdateCaption;
    function OnExpandedStateGetNodeText(Node: TTreeNode): string;
    procedure ApplyCodeFilter;
    procedure ApplyDirectivesFilter;
    function CompareCodeNodes(Node1, Node2: TTreeNode): integer;
    function FilterNode(ANode: TTreeNode; const TheFilter: string;
      KeepTopLevel: Boolean): boolean;
  public
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure CheckOnIdle;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Refresh(OnlyVisible: boolean);
    procedure RefreshCode(OnlyVisible: boolean);
    procedure RefreshDirectives(OnlyVisible: boolean);
    procedure ClearCTNodes(ATreeView: TTreeView);// remove temporary references
    function JumpToSelection(ToImplementation: boolean = false): boolean; // jump in source editor
    procedure JumpToCode(Sender: TObject; const Filename: string;
      const Caret: TPoint; TopLine: integer);
    function SelectSourceEditorNode: boolean;
    function SelectCodePosition(CodeBuf: TCodeBuffer; X, Y: integer): boolean; // select deepest node
    function FindCodeTVNodeAtCleanPos(CleanPos: integer): TTreeNode;
    procedure BuildCodeSortedForStartPos;
    procedure CurrentCodeBufferChanged;
    procedure CodeFilterChanged;
    procedure DirectivesFilterChanged;
    function FilterFits(const NodeText, TheFilter: string): boolean; virtual;
    function GetCurrentTreeView: TCustomTreeView;
  public
    property OnGetDirectivesTree: TOnGetDirectivesTree read FOnGetDirectivesTree
                                                     write FOnGetDirectivesTree;
    property OnJumpToCode: TOnJumpToCode read FOnJumpToCode write FOnJumpToCode;
    property OnShowOptions: TNotifyEvent read FOnShowOptions write FOnShowOptions;
    property Mode: TCodeExplorerMode read FMode write SetMode;
    property CodeFilename: string read FCodeFilename;
    property CodeFilter: string read GetCodeFilter write SetCodeFilter;
    property DirectivesFilename: string read FDirectivesFilename;
    property DirectivesFilter: string read GetDirectivesFilter
                                      write SetDirectivesFilter;
    property CurrentPage: TCodeExplorerPage read GetCurrentPage
                                            write SetCurrentPage;
  end;

const
  WKCodeExplorerMenuRootName = 'WK Code Explorer';
  CodeObserverMaxNodes = 50;

var
  CodeExplorerView: TWKCodeExplorerView = nil;
  WKCodeExplorerForm: TWKCodeExplorerView = nil;
  WKCodeExplorerMenuRoot: TIDEMenuSection = nil;
  WKCEJumpToIDEMenuCommand: TIDEMenuCommand;
  WKCEJumpToImplementationIDEMenuCommand: TIDEMenuCommand;
  WKCEShowSrcEditPosIDEMenuCommand: TIDEMenuCommand;
  WKCERefreshIDEMenuCommand: TIDEMenuCommand;
  WKCERenameIDEMenuCommand: TIDEMenuCommand;

procedure RegisterStandardWKCodeExplorerMenuItems;
procedure Register;

function GetToDoComment(const Src: string;
                       CommentStartPos, CommentEndPos: integer;
                       out MagicStartPos, TextStartPos, TextEndPos: integer): boolean;

implementation

{$R *.lfm}

{ Helpers for standalone-routine copy/paste (//MMWIN:MODULECOPY). }

function WKIsIdentChar(C: Char): Boolean;
begin
  Result := C in ['A'..'Z', 'a'..'z', '0'..'9', '_'];
end;

function WKLineIndent(const S: string): Integer;
begin
  Result := 0;
  while (Result < Length(S)) and (S[Result + 1] = ' ') do
    Inc(Result);
end;

function WKRoutineKeywordLenAt(const S: string; P: Integer): Integer;
begin
  Result := 0;
  if SameText(Copy(S, P, 16), 'class procedure ') then Exit(16);
  if SameText(Copy(S, P, 15), 'class function ') then Exit(15);
  if SameText(Copy(S, P, 10), 'procedure ') then Exit(10);
  if SameText(Copy(S, P, 9), 'function ') then Exit(9);
  if SameText(Copy(S, P, 12), 'constructor ') then Exit(12);
  if SameText(Copy(S, P, 11), 'destructor ') then Exit(11);
  if SameText(Copy(S, P, 9), 'operator ') then Exit(9);
end;

function WKNameStartPos(const S: string): Integer;
var
  P, KL: Integer;
begin
  Result := 0;
  P := 1;
  while (P <= Length(S)) and (S[P] in [' ', #9]) do
    Inc(P);
  KL := WKRoutineKeywordLenAt(S, P);
  if KL = 0 then Exit;
  Result := P + KL;
end;

function WKHeaderName(const Header: string): string;
var
  P, E: Integer;
begin
  Result := '';
  P := WKNameStartPos(Header);
  if P = 0 then Exit;
  E := P;
  while (E <= Length(Header)) and (WKIsIdentChar(Header[E]) or (Header[E] = '.')) do
    Inc(E);
  Result := Copy(Header, P, E - P);
end;

// Lowercase the parameter/result part, drop whitespace and default values.
function WKNormalizeParams(const S: string): string;
var
  I, Depth: Integer;
  Ch: Char;
  InStr: Boolean;
begin
  Result := '';
  InStr := False;
  I := 1;
  while I <= Length(S) do
  begin
    Ch := S[I];
    if InStr then
    begin
      Result := Result + Ch;
      if Ch = '''' then
      begin
        if (I < Length(S)) and (S[I + 1] = '''') then
        begin
          Result := Result + '''';
          Inc(I, 2);
          Continue;
        end;
        InStr := False;
      end;
      Inc(I);
      Continue;
    end;
    case Ch of
      '''':
        begin
          InStr := True;
          Result := Result + Ch;
          Inc(I);
        end;
      ' ', #9, #10, #13, ';':
        Inc(I);
      '=':
        begin
          Inc(I);
          Depth := 0;
          while I <= Length(S) do
          begin
            Ch := S[I];
            if Ch = '''' then
            begin
              Inc(I);
              while I <= Length(S) do
              begin
                if S[I] = '''' then
                begin
                  if (I < Length(S)) and (S[I + 1] = '''') then
                    Inc(I, 2)
                  else
                  begin
                    Inc(I);
                    Break;
                  end;
                end
                else
                  Inc(I);
              end;
              Continue;
            end;
            if Ch = '(' then
              Inc(Depth)
            else if Ch = ')' then
            begin
              if Depth = 0 then Break;
              Dec(Depth);
            end
            else if (Ch = ',') and (Depth = 0) then
              Break
            else if Ch = ';' then
              Break;
            Inc(I);
          end;
        end;
      'A'..'Z':
        begin
          Result := Result + LowerCase(Ch);
          Inc(I);
        end;
      else
        begin
          Result := Result + Ch;
          Inc(I);
        end;
    end;
  end;
end;

// Keeps only the routine signature: everything up to the first top-level ';'.
// Trailing directives (overload, reintroduce, virtual, override, dynamic,
// abstract, inline, forward, cdecl, stdcall, register, external, message, ...)
// follow that ';' and must not take part in parameter-list comparisons.
function WKStripRoutineDirectives(const S: string): string;
var
  I, Depth: Integer;
  Ch: Char;
  InStr: Boolean;
begin
  Result := S;
  Depth := 0;
  InStr := False;
  I := 1;
  while I <= Length(S) do
  begin
    Ch := S[I];
    if InStr then
    begin
      if Ch = '''' then
      begin
        if (I < Length(S)) and (S[I + 1] = '''') then
          Inc(I)
        else
          InStr := False;
      end;
    end
    else
    begin
      case Ch of
        '''':
          InStr := True;
        '(':
          Inc(Depth);
        ')':
          if Depth > 0 then Dec(Depth);
        ';':
          if Depth = 0 then
          begin
            Result := Copy(S, 1, I);
            Exit;
          end;
      end;
    end;
    Inc(I);
  end;
end;

function WKNormHeaderTail(const Header: string): string;
var
  P: Integer;
begin
  Result := '';
  P := WKNameStartPos(Header);
  if P = 0 then Exit;
  while (P <= Length(Header)) and (WKIsIdentChar(Header[P]) or (Header[P] = '.')) do
    Inc(P);
  Result := WKNormalizeParams(WKStripRoutineDirectives(Copy(Header, P, Length(Header))));
end;

// Returns the 0-based index of the line holding the ';' that closes the header.
function WKHeaderEndLine(Lines: TStringList; StartIdx: Integer): Integer;
var
  I, J, Depth: Integer;
  S: string;
  InStr, InBrace, InParen, InLine: Boolean;
begin
  Result := StartIdx;
  if (Lines = nil) or (StartIdx < 0) or (StartIdx >= Lines.Count) then Exit;
  Depth := 0;
  InStr := False;
  InBrace := False;
  InParen := False;
  InLine := False;
  for I := StartIdx to Lines.Count - 1 do
  begin
    S := Lines[I];
    J := 1;
    while J <= Length(S) do
    begin
      if InLine then Break;
      if InStr then
      begin
        if S[J] = '''' then
        begin
          if (J < Length(S)) and (S[J + 1] = '''') then
            Inc(J)
          else
            InStr := False;
        end;
      end
      else if InBrace then
      begin
        if S[J] = '}' then InBrace := False;
      end
      else if InParen then
      begin
        if (S[J] = '*') and (J < Length(S)) and (S[J + 1] = ')') then
        begin
          InParen := False;
          Inc(J);
        end;
      end
      else
      begin
        case S[J] of
          '''': InStr := True;
          '{': InBrace := True;
          '(':
            begin
              if (J < Length(S)) and (S[J + 1] = '*') then
              begin
                InParen := True;
                Inc(J);
              end
              else
                Inc(Depth);
            end;
          ')':
            if Depth > 0 then Dec(Depth);
          ';':
            if Depth = 0 then
            begin
              Result := I;
              Exit;
            end;
          '/':
            if (J < Length(S)) and (S[J + 1] = '/') then InLine := True;
        end;
      end;
      Inc(J);
    end;
    InLine := False;
  end;
end;

function WKJoinLineRange(Lines: TStringList; StartIdx, EndIdx: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := StartIdx to EndIdx do
  begin
    if I = StartIdx then
      Result := Lines[I]
    else
      Result := Result + #13#10 + Lines[I];
  end;
end;

function WKFindRoutineHeader(Lines: TStringList; FromIdx, ToIdx: Integer;
  const AName, AParams: string; AColumnZero, AAllowDotted: Boolean): Integer;
var
  I, E, Indent: Integer;
  S, Header, N: string;
begin
  Result := -1;
  if (Lines = nil) or (AName = '') then Exit;
  if FromIdx < 0 then FromIdx := 0;
  if ToIdx >= Lines.Count then ToIdx := Lines.Count - 1;
  for I := FromIdx to ToIdx do
  begin
    S := Lines[I];
    Indent := WKLineIndent(S);
    if AColumnZero and (Indent <> 0) then Continue;
    if (not AColumnZero) and (Indent = 0) then Continue;
    if WKRoutineKeywordLenAt(S, Indent + 1) = 0 then Continue;
    E := WKHeaderEndLine(Lines, I);
    Header := WKJoinLineRange(Lines, I, E);
    N := WKHeaderName(Header);
    if N = '' then Continue;
    if (not AAllowDotted) and (Pos('.', N) > 0) then Continue;
    if SameText(N, AName) and (WKNormHeaderTail(Header) = AParams) then
      Exit(I);
  end;
end;

// Header line to the first 'end;' at the same indentation (nested routines are
// indented deeper and are therefore part of the body).
function WKFindRoutineEndLine(Lines: TStringList; HeaderIdx: Integer): Integer;
var
  Indent, I: Integer;
  T: string;
begin
  Result := -1;
  if (Lines = nil) or (HeaderIdx < 0) or (HeaderIdx >= Lines.Count) then Exit;
  Indent := WKLineIndent(Lines[HeaderIdx]);
  for I := HeaderIdx + 1 to Lines.Count - 1 do
  begin
    T := Trim(Lines[I]);
    if (T = 'end;') and (WKLineIndent(Lines[I]) = Indent) then
      Exit(I);
  end;
end;

function WKIndentText(const Text: string; Count: Integer): string;
var
  SL: TStringList;
  I: Integer;
  Pad: string;
begin
  Result := '';
  SL := TStringList.Create;
  try
    SL.Text := Text;
    Pad := StringOfChar(' ', Count);
    for I := 0 to SL.Count - 1 do
      if SL[I] <> '' then
        SL[I] := Pad + SL[I];
    Result := SL.Text;
    while (Result <> '') and (Result[Length(Result)] in [#10, #13]) do
      Delete(Result, Length(Result), 1);
  finally
    SL.Free;
  end;
end;

// Every paste ends with exactly one empty line after its block: append one
// CRLF more than the block already has, but do nothing when the text already
// ends with a blank line. Nothing is ever prepended.
function WKWithTrailingBlankLine(const Text: string): string;
var
  L: Integer;
begin
  Result := Text;
  L := Length(Result);
  if L = 0 then Exit;
  // Already followed by an empty line?
  if (L >= 4) and (Copy(Result, L - 3, 4) = #13#10#13#10) then
    Exit;
  if (L >= 2) and ((Copy(Result, L - 1, 2) = #10#10) or
     (Copy(Result, L - 1, 2) = #13#13)) then
    Exit;
  if (L >= 2) and (Copy(Result, L - 1, 2) = #13#10) then
    Result := Result + #13#10
  else if Result[L] = #10 then
    Result := Result + #10
  else if Result[L] = #13 then
    Result := Result + #13
  else
    Result := Result + #13#10 + #13#10;
end;

function WKDequalifyMemberBlock(const Block, Owner: string): string;
var
  P: Integer;
begin
  Result := Block;
  if Owner = '' then Exit;
  P := WKNameStartPos(Result);
  if P = 0 then Exit;
  if SameText(Copy(Result, P, Length(Owner) + 1), Owner + '.') then
    Delete(Result, P, Length(Owner) + 1);
end;

function WKQualifyRoutineHeader(const Block, Owner: string): string;
var
  P: Integer;
begin
  Result := Block;
  if Owner = '' then Exit;
  P := WKNameStartPos(Result);
  if P = 0 then Exit;
  if SameText(Copy(Result, P, Length(Owner) + 1), Owner + '.') then Exit;
  Insert(Owner + '.', Result, P);
end;

function WKIsModuleCopyText(const Text: string): Boolean;
var
  SL: TStringList;
  I: Integer;
begin
  Result := False;
  SL := TStringList.Create;
  try
    SL.Text := Text;
    for I := 0 to SL.Count - 1 do
    begin
      if Trim(SL[I]) = '' then Continue;
      Result := SameText(Trim(SL[I]), '//MMWIN:MODULECOPY');
      Exit;
    end;
  finally
    SL.Free;
  end;
end;

function WKParseModuleCopy(const Text: string;
  out Vis, ItemName, Decl, Body: string): Boolean;
var
  SL: TStringList;
  I, IfaceIdx, ImplIdx, EndIdx: Integer;
  S: string;

  function RangeText(AStart, AEnd: Integer): string;
  var
    K: Integer;
  begin
    while (AStart <= AEnd) and (Trim(SL[AStart]) = '') do Inc(AStart);
    while (AEnd >= AStart) and (Trim(SL[AEnd]) = '') do Dec(AEnd);
    Result := '';
    for K := AStart to AEnd do
      if K = AStart then
        Result := SL[K]
      else
        Result := Result + #13#10 + SL[K];
  end;

begin
  Result := False;
  Vis := 'PUBLIC';
  ItemName := '';
  Decl := '';
  Body := '';
  SL := TStringList.Create;
  try
    SL.Text := Text;
    IfaceIdx := -1;
    ImplIdx := -1;
    EndIdx := -1;
    for I := 0 to SL.Count - 1 do
    begin
      S := Trim(SL[I]);
      if SameText(Copy(S, 1, 6), '//VIS:') then
        Vis := UpperCase(Trim(Copy(S, 7, Length(S))));
      if SameText(Copy(S, 1, 7), '//NAME:') then
        ItemName := Trim(Copy(S, 8, Length(S)));
      if (IfaceIdx < 0) and SameText(S, 'interface') then
        IfaceIdx := I
      else if (ImplIdx < 0) and SameText(S, 'implementation') then
        ImplIdx := I
      else if (ImplIdx >= 0) and SameText(S, 'end.') then
      begin
        EndIdx := I;
        Break;
      end;
    end;
    if (IfaceIdx < 0) or (ImplIdx < 0) or (EndIdx < 0) then Exit;
    Decl := RangeText(IfaceIdx + 1, ImplIdx - 1);
    Body := RangeText(ImplIdx + 1, EndIdx - 1);
    Result := True;
  finally
    SL.Free;
  end;
end;

type

  { TViewNodeData }

  TViewNodeData = class
  public
    CTNode: TCodeTreeNode; // only valid during update, at other times it is nil
    Desc: TCodeTreeNodeDesc;
    SubDesc: TCodeTreeNodeSubDesc;
    StartPos, EndPos: integer;
    Path: string;
    Params: string;
    ImplementationNode: TViewNodeData;
    SortChildren: boolean; // sort for TVNode text (optional) and StartPos, EndPos
    constructor Create(CodeNode: TCodeTreeNode; SortTheChildren: boolean = true);
    destructor Destroy; override;
    procedure CreateParams(ACodeTool: TCodeTool);
  end;

function CompareViewNodeDataStartPos(Node1, Node2: TTreeNode): integer;
var
  NodeData1: TViewNodeData;
  NodeData2: TViewNodeData;
begin
  NodeData1:=TViewNodeData(Node1.Data);
  NodeData2:=TViewNodeData(Node2.Data);
  if NodeData1.StartPos>NodeData2.StartPos then
    Result:=1
  else if NodeData1.StartPos<NodeData2.StartPos then
    Result:=-1
  else if NodeData1.EndPos>NodeData2.EndPos then
    Result:=1
  else if NodeData1.EndPos<NodeData2.EndPos then
    Result:=-1
  else
    Result:=0;
end;

function CompareStartPosWithViewNodeData(Key: PInteger; Node: TTreeNode): integer;
var
  NodeData: TViewNodeData;
begin
  NodeData:=TViewNodeData(Node.Data);
  if Key^ > NodeData.StartPos then
    Result:=1
  else if Key^ < NodeData.StartPos then
    Result:=-1
  else
    Result:=0;
end;

function CompareViewNodePathsAndParams(NodeData1, NodeData2: Pointer): integer;
var
  Node1: TViewNodeData absolute NodeData1;
  Node2: TViewNodeData absolute NodeData2;
begin
  Result:=SysUtils.CompareText(Node1.Path,Node2.Path);
  if Result<>0 then exit;
  Result:=SysUtils.CompareText(Node1.Params,Node2.Params);
end;

function CompareViewNodePaths(NodeData1, NodeData2: Pointer): integer;
var
  Node1: TViewNodeData absolute NodeData1;
  Node2: TViewNodeData absolute NodeData2;
begin
  Result:=SysUtils.CompareText(Node1.Path,Node2.Path);
end;

procedure RegisterStandardWKCodeExplorerMenuItems;
var
  Path: String;
begin
  WKCodeExplorerMenuRoot:=RegisterIDEMenuRoot(WKCodeExplorerMenuRootName);
  Path:=WKCodeExplorerMenuRoot.Name;
  WKCEJumpToIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'WKJumpTo', lisMenuJumpTo);
  WKCEJumpToImplementationIDEMenuCommand:=RegisterIDEMenuCommand(Path,
    'WKJumpToImplementation', lisMenuJumpToImplementation);
  WKCEShowSrcEditPosIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'WKShowSrcEditPos',
    lisShowPositionOfSourceEditor);
  WKCERefreshIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'WKRefresh', dlgUnitDepRefresh);
  WKCERenameIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'WKRename', lisRename);
end;

function GetToDoComment(const Src: string; CommentStartPos,
  CommentEndPos: integer; out MagicStartPos, TextStartPos, TextEndPos: integer
  ): boolean;
var
  StartPos: Integer;
  EndPos: Integer;
  p: Integer;
begin
  if CommentStartPos<1 then exit(false);
  if CommentEndPos-CommentStartPos<5 then exit(false);
  if Src[CommentStartPos]='/' then begin
    StartPos:=CommentStartPos+2;
    EndPos:=CommentEndPos;
  end else if (Src[CommentStartPos]='{') then begin
    StartPos:=CommentStartPos+1;
    EndPos:=CommentEndPos-1;
  end else if (CommentStartPos<length(Src)) and (Src[CommentStartPos]='(')
  and (Src[CommentStartPos+1]='*') then begin
    StartPos:=CommentStartPos+2;
    EndPos:=CommentEndPos-2;
  end else
    exit(false);
  while (StartPos<EndPos) and (Src[StartPos]=' ') do inc(StartPos);
  MagicStartPos:=StartPos;
  if Src[StartPos]='#' then inc(StartPos);
  if CompareIdentifiers('todo',@Src[StartPos])<>0 then exit(false);
  // this is a ToDo
  p:=StartPos+length('todo');
  TextStartPos:=p;
  while (TextStartPos<EndPos) and (Src[TextStartPos]<>':') do inc(TextStartPos);
  if Src[TextStartPos]=':' then
    inc(TextStartPos) // a todo with colon syntax
  else
    TextStartPos:=p; // a todo without syntax
  while (TextStartPos<EndPos) and (Src[TextStartPos]=' ') do inc(TextStartPos);
  TextEndPos:=EndPos;
  while (TextEndPos>TextStartPos) and (Src[TextEndPos-1]=' ') do dec(TextEndPos);
  Result:=true;
end;

{ TViewNodeData }

constructor TViewNodeData.Create(CodeNode: TCodeTreeNode;
  SortTheChildren: boolean);
begin
  CTNode:=CodeNode;
  Desc:=CodeNode.Desc;
  SubDesc:=CodeNode.SubDesc;
  StartPos:=CodeNode.StartPos;
  EndPos:=CodeNode.EndPos;
  SortChildren:=SortTheChildren;
end;

destructor TViewNodeData.Destroy;
begin
  FreeAndNil(ImplementationNode);
  inherited Destroy;
end;

procedure TViewNodeData.CreateParams(ACodeTool: TCodeTool);
begin
  if Params<>'' then exit;
  if CTNode.Desc=ctnProcedure then begin
    try
      Params:=ACodeTool.ExtractProcHead(CTNode,
        [phpWithoutClassKeyword,phpWithoutClassName,phpWithoutName,phpWithoutSemicolon]);
    except
      on E: ECodeToolError do ; // ignore syntax errors
    end;
  end;
  if Params='' then
    Params:=' ';
end;

{ TWKCodeExplorerView }

procedure TWKCodeExplorerView.CodeExplorerViewCreate(Sender: TObject);
begin
  FMode := CodeExplorerOptions.Mode;
  UpdateMode;

  Name:='WKCodeExplorer';
  UpdateCaption;

  // Add Copy menu item to TreePopupmenu
  WKCopyMenuItem := TMenuItem.Create(Self);
  WKCopyMenuItem.Caption := 'Copy';
  WKCopyMenuItem.Enabled := false;
  WKCopyMenuItem.OnClick := @WKCopyMenuItemClick;
  TreePopupmenu.Items.Insert(0, WKCopyMenuItem);

  // Add Paste menu item to TreePopupmenu
  WKPasteMenuItem := TMenuItem.Create(Self);
  WKPasteMenuItem.Caption := 'Paste';
  WKPasteMenuItem.OnClick := @WKPasteMenuItemClick;
  TreePopupmenu.Items.Insert(1, WKPasteMenuItem);

  case CodeExplorerOptions.Page of
  cepDirectives: MainNotebook.ActivePage:=DirectivesPage;
  else MainNotebook.ActivePage:=CodePage;
  end;

  CodePage.Caption:=lisCode;
  CodeRefreshSpeedButton.Hint:=dlgUnitDepRefresh;
  CodeOptionsSpeedButton.Hint:=lisOptions;
  CodeFilterEdit.Text:='';
  DirectivesPage.Caption:=lisDirectives;
  DirectivesFilterEdit.Text:='';
  DirRefreshSpeedButton.Hint:=dlgUnitDepRefresh;
  DirOptionsSpeedButton.Hint:=lisOptions;
  CodeFilterEdit.TextHint:=lisCEFilter;
  DirectivesFilterEdit.TextHint:=lisCEFilter;
  CodeFilterEdit.Button.Enabled:=false;
  DirectivesFilterEdit.Button.Enabled:=false;

  AssignAllImages;
  // assign the root TMenuItem to the registered menu root.
  // This will automatically create all registered items
  WKCodeExplorerMenuRoot.MenuItem:=TreePopupMenu.Items;
  //WKCodeExplorerMenuRoot.Items.WriteDebugReport(' ');

  WKCEJumpToIDEMenuCommand.OnClick:=@JumpToMenuItemClick;
  WKCEJumpToImplementationIDEMenuCommand.OnClick:=@JumpToImplementationMenuItemClick;
  WKCEShowSrcEditPosIDEMenuCommand.OnClick:=@ShowSrcEditPosMenuItemClick;
  WKCERefreshIDEMenuCommand.OnClick:=@RefreshMenuItemClick;
  WKCERenameIDEMenuCommand.OnClick:=@RenameMenuItemClick;

  fNodesWithPath:=TAvlTree.Create(@CompareViewNodePathsAndParams);

  Application.AddOnUserInputHandler(@UserInputHandler);
  LazarusIDE.AddHandlerOnIDEClose(@CloseIDEHandler);
end;

procedure TWKCodeExplorerView.CodeExplorerViewDestroy(Sender: TObject);
begin
  //debugln('TWKCodeExplorerView.CodeExplorerViewDestroy');
  fLastCodeTool:=nil;
  FreeAndNil(fNodesWithPath);
  FreeAndNil(fCodeSortedForStartPos);
  if CodeExplorerView=Self then
    CodeExplorerView:=nil;
end;

procedure TWKCodeExplorerView.CodeFilterEditChange(Sender: TObject);
begin
  CodeFilterChanged;
end;

procedure TWKCodeExplorerView.CodeTreeviewMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Node: TTreeNode;
begin
  if Button=mbMiddle then begin
    Node:=CodeTreeview.GetNodeAt(X,Y);
    if Node <> nil then begin
      Node.Selected:=true;
      JumpToSelection(true);
    end;
  end;
end;

procedure TWKCodeExplorerView.DirectivesFilterEditChange(Sender: TObject);
begin
  DirectivesFilterChanged;
end;

procedure TWKCodeExplorerView.DirRefreshSpeedButtonClick(Sender: TObject);
begin
  FLastDirectivesChangeStep:=CTInvalidChangeStamp;
  RefreshDirectives(true);
end;

procedure TWKCodeExplorerView.FilterEditButtonClick(Sender: TObject);
begin
  (Sender as TEditButton).Text:='';
  IdleTimer1Timer(nil); // immediately reset filter
end;

procedure TWKCodeExplorerView.FilterEditEnter(Sender: TObject);
begin
  (Sender as TEditButton).SelectAll;
end;

procedure TWKCodeExplorerView.FormActivate(Sender: TObject);
begin
  //DebugLn(['TWKCodeExplorerView.FormActivate!']);
  FCodeCmd1:=IDECommandList.FindIDECommand(ecFindDeclaration);
  FCodeCmd2:=IDECommandList.FindIDECommand(ecFindProcedureDefinition);
  FCodeCmd3:=IDECommandList.FindIDECommand(ecFindProcedureMethod);
end;

procedure TWKCodeExplorerView.IdleTimer1Timer(Sender: TObject);
begin
  if not (cevCheckOnIdle in FFlags) then exit;
  if (Screen.ActiveCustomForm<>nil)
  and (fsModal in Screen.ActiveCustomForm.FormState) then
  begin
    // do not update while a modal form is shown, except for clear
    if SourceEditorManagerIntf=nil then exit;
    if SourceEditorManagerIntf.SourceEditorCount=0 then
    begin
      Exclude(FFlags,cevCheckOnIdle);
      FLastCodeValid:=false;
      ClearCodeTreeView;
      FDirectivesFilename:='';
      ClearDirectivesTreeView;
    end;
    exit;
  end;
  if not IsVisible then exit;
  Exclude(FFlags,cevCheckOnIdle);
  case CurrentPage of
  cepNone: ;
  cepCode: if (CurrentPage<>cepCode) or CodeTreeview.Focused then exit;
  cepDirectives: if (CurrentPage<>cepDirectives) or DirectivesTreeView.Focused then exit;
  end;
  Refresh(true);
end;

procedure TWKCodeExplorerView.JumpToMenuItemClick(Sender: TObject);
begin
  JumpToSelection(false);
end;

procedure TWKCodeExplorerView.JumpToImplementationMenuItemClick(Sender: TObject);
begin
  JumpToSelection(true);
end;

function TWKCodeExplorerView.FindClassCTNode(CurNode: TObject): TCodeTreeNode;
var
  NodeData: TViewNodeData;
  CodeBuffer: TCodeBuffer;
  ACodeTool: TCodeTool;
  p: LongInt;
  NewNode: TCodeTreeNode;
  DotPos: Integer;
  OwnerClassName: string;

  function FindTypeNode(ANode: TCodeTreeNode; const AName: string): TCodeTreeNode;
  begin
    Result := nil;
    while ANode <> nil do begin
      if (ANode.Desc = ctnTypeDefinition)
      and SameText(ACodeTool.ExtractDefinitionName(ANode), AName) then
        Exit(ANode);
      Result := FindTypeNode(ANode.FirstChild, AName);
      if Result <> nil then
        Exit;
      ANode := ANode.NextBrother;
    end;
  end;

begin
  Result := nil;
  if CurNode = nil then exit;
  NodeData := TViewNodeData(CurNode);
  if NodeData = nil then exit;
  if NodeData.StartPos < 1 then exit;
  CodeBuffer := CodeToolBoss.LoadFile(CodeFilename, false, false);
  if CodeBuffer = nil then exit;
  ACodeTool := nil;
  CodeToolBoss.Explore(CodeBuffer, ACodeTool, false);
  if ACodeTool = nil then exit;
  p := NodeData.StartPos;
  NewNode := ACodeTool.FindDeepestNodeAtPos(p, false);
  if NewNode <> nil then begin
    if (NewNode.Desc = ctnProcedure)
    and (NewNode.FirstChild <> nil)
    and (NewNode.FirstChild.Desc = ctnProcedureHead)
    and (NewNode.FirstChild.StartPos > p) then
      p := NewNode.FirstChild.StartPos;
  end;
  // Walk up with Parent until Desc = ctnTypeDefinition
  while NewNode <> nil do begin
    if NewNode.Desc = ctnTypeDefinition then begin
      Result := NewNode;
      exit;
    end;
    NewNode := NewNode.Parent;
  end;
  // Implementation method bodies are not nested under their class in the
  // code tree, so walking up from them never reaches ctnTypeDefinition.
  // Resolve the owning class from the node path (e.g. "THuman.Walk").
  if NodeData.Desc = ctnProcedure then
  begin
    DotPos := LastDelimiter('.', NodeData.Path);
    if DotPos > 1 then
    begin
      OwnerClassName := Copy(NodeData.Path, 1, DotPos - 1);
      Result := FindTypeNode(ACodeTool.Tree.Root, OwnerClassName);
    end;
  end;
end;

procedure TWKCodeExplorerView.WKCopyMenuItemClick(Sender: TObject);
const
  CRLF = #13#10;

  function PosToLineIndex(const S: string; P: Integer): Integer;
  var
    i: Integer;
  begin
    Result := 0;
    i := 1;
    while (i < P) and (i <= Length(S)) do
    begin
      if S[i] = #10 then
        Inc(Result)
      else if (S[i] = #13) and ((i = Length(S)) or (S[i + 1] <> #10)) then
        Inc(Result);
      Inc(i);
    end;
  end;

  function IsIdentChar2(C: Char): Boolean;
  begin
    Result := C in ['A'..'Z', 'a'..'z', '0'..'9', '_'];
  end;

  function StartsWithMemberPrefix(const AText, APrefix: string): Boolean;
  begin
    Result := (Pos(APrefix, AText) = 1) and
      ((Length(AText) = Length(APrefix)) or
       not IsIdentChar2(AText[Length(APrefix) + 1]));
  end;

var
  CurTreeView: TCustomTreeView;
  CurItem: TTreeNode;
  CurNode: TViewNodeData;
  CodeBuffer: TCodeBuffer;
  ACodeTool: TCodeTool;
  Source: string;
  AClassName: string;
  FoundNode, MemberCTNode: TCodeTreeNode;
  Impls: TStringList;
  Out: string;
  I, J, K: Integer;
  S: string;
  CommentTag: string;
  ClassStart, ClassEnd: Integer;
  InClass: Boolean;
  SL: TStringList;
  InImpl: Boolean;
  Trimmed: string;
  IsRoutine: Boolean;
  Indent: string;
  CurrIndent: string;
  Line: string;
  Rest: string;
  TrimmedLine: string;
  MemberLineIdx, VisLineIdx, P: Integer;
  DotPos: Integer;
  VisName, MemberDeclText, RoutineText, MemberName: string;

  // Standalone routine (not a class member): //MMWIN:MODULECOPY.
  // Interface declaration => declaration + body; implementation only => body.
  procedure CopyStandaloneRoutine;
  var
    Buf: TCodeBuffer;
    Tool: TCodeTool;
    Node: TCodeTreeNode;
    Src: string;
    TextLines: TStringList;
    ImplIdx, SelLine, HdrEnd, BodyStart, BodyEnd, DeclLine, LI: Integer;
    LVis, LDecl, LBody, LName, LParams, HText, OutText: string;
  begin
    Buf := CodeToolBoss.LoadFile(CodeFilename, false, false);
    if Buf = nil then Exit;
    Tool := nil;
    CodeToolBoss.Explore(Buf, Tool, false);
    if Tool = nil then Exit;
    Src := Buf.Source;
    TextLines := TStringList.Create;
    try
      TextLines.Text := Src;
      ImplIdx := -1;
      for LI := 0 to TextLines.Count - 1 do
        if SameText(Trim(TextLines[LI]), 'implementation') then
        begin
          ImplIdx := LI;
          Break;
        end;
      if ImplIdx < 0 then Exit;

      SelLine := PosToLineIndex(Src, CurNode.StartPos);
      Node := Tool.FindDeepestNodeAtPos(CurNode.StartPos, false);
      if (Node = nil) or (Node.Desc <> ctnProcedure) then Exit;
      LName := Tool.ExtractProcName(Node, []);
      if LName = '' then Exit;
      if Pos('.', LName) > 0 then
      begin
        MessageDlg('Cannot copy: ' + LName + ' is a nested routine',
          mtInformation, [mbOK], 0);
        Exit;
      end;

      LVis := 'PRIVATE';
      LDecl := '';
      if SelLine < ImplIdx then
      begin
        // Selected the interface declaration: copy declaration + body.
        HdrEnd := WKHeaderEndLine(TextLines, SelLine);
        LDecl := WKJoinLineRange(TextLines, SelLine, HdrEnd);
        LParams := WKNormHeaderTail(LDecl);
        BodyStart := WKFindRoutineHeader(TextLines, ImplIdx + 1,
          TextLines.Count - 1, LName, LParams, True, False);
        if BodyStart < 0 then
        begin
          MessageDlg('Cannot copy: implementation body not found for ' + LName,
            mtError, [mbOK], 0);
          Exit;
        end;
        BodyEnd := WKFindRoutineEndLine(TextLines, BodyStart);
        if BodyEnd < 0 then
        begin
          MessageDlg('Cannot copy: implementation body not found for ' + LName,
            mtError, [mbOK], 0);
          Exit;
        end;
        LBody := WKJoinLineRange(TextLines, BodyStart, BodyEnd);
        LVis := 'PUBLIC';
      end
      else
      begin
        // Selected an implementation body: body only, unless the same routine
        // is also declared in the interface (then keep both parts together).
        HdrEnd := WKHeaderEndLine(TextLines, SelLine);
        HText := WKJoinLineRange(TextLines, SelLine, HdrEnd);
        LParams := WKNormHeaderTail(HText);
        DeclLine := WKFindRoutineHeader(TextLines, 0, ImplIdx - 1,
          LName, LParams, True, False);
        BodyEnd := WKFindRoutineEndLine(TextLines, SelLine);
        if BodyEnd < 0 then
        begin
          MessageDlg('Cannot copy: implementation body not found for ' + LName,
            mtError, [mbOK], 0);
          Exit;
        end;
        LBody := WKJoinLineRange(TextLines, SelLine, BodyEnd);
        if DeclLine >= 0 then
        begin
          HdrEnd := WKHeaderEndLine(TextLines, DeclLine);
          LDecl := WKJoinLineRange(TextLines, DeclLine, HdrEnd);
          LVis := 'PUBLIC';
        end;
      end;

      OutText := '//MMWIN:MODULECOPY' + CRLF;
      OutText := OutText + '//VIS:' + LVis + CRLF;
      OutText := OutText + '//NAME:' + LName + CRLF;
      OutText := OutText + 'unit _MM_Copy_Buffer_;' + CRLF + CRLF;
      OutText := OutText + 'interface' + CRLF + CRLF;
      if LDecl <> '' then
        OutText := OutText + LDecl + CRLF + CRLF;
      OutText := OutText + 'implementation' + CRLF + CRLF;
      OutText := OutText + LBody + CRLF + CRLF;
      OutText := OutText + 'end.' + CRLF;
      Clipboard.AsText := OutText;
    finally
      TextLines.Free;
    end;
  end;

begin
  CurTreeView := GetCurrentTreeView;
  if CurTreeView = nil then exit;
  if tvoAllowMultiselect in CurTreeView.Options then
    CurItem := CurTreeView.GetFirstMultiSelected
  else
    CurItem := CurTreeView.Selected;
  if CurItem = nil then exit;
  CurNode := TViewNodeData(CurItem.Data);
  if CurNode = nil then exit;

  if CurNode.Desc = ctnTypeDefinition then begin
    FoundNode := FindClassCTNode(CurNode);
    if FoundNode = nil then exit;
    if not (FoundNode.FirstChild <> nil) then exit;
    if not (FoundNode.FirstChild.Desc in AllClasses) then exit;

    // Load source file
    CodeBuffer := CodeToolBoss.LoadFile(CodeFilename, false, false);
    if CodeBuffer = nil then exit;
    ACodeTool := nil;
    CodeToolBoss.Explore(CodeBuffer, ACodeTool, false);
    if ACodeTool = nil then exit;

    // Derive the class name from the CodeTools node; fall back to the tree label.
    // CurNode.Path is only assigned for ctnProcedure nodes (CreateNodePath),
    // so it is empty for a ctnTypeDefinition class node.
    AClassName := ACodeTool.ExtractDefinitionName(FoundNode);
    if AClassName = '' then
      AClassName := CurItem.Text;
    if AClassName = '' then exit;

    Source := CodeBuffer.Source;

    // Build implementation list
    Impls := TStringList.Create;
    try
      SL := TStringList.Create;
      try
        SL.Text := Source;
        InImpl := False;
        I := 0;
        while I < SL.Count do
        begin
          if not InImpl then
          begin
            if Pos('implementation', SL[I]) > 0 then
              InImpl := True;
            I := I + 1;
            Continue;
          end;

          S := SL[I];
          Trimmed := S;
          while (Length(Trimmed) > 0) and (Trimmed[1] = ' ') do
            Delete(Trimmed, 1, 1);

          IsRoutine := (Pos('procedure ' + AClassName + '.', Trimmed) = 1) or
                       (Pos('function ' + AClassName + '.', Trimmed) = 1) or
                       (Pos('constructor ' + AClassName + '.', Trimmed) = 1);

          if not IsRoutine then
          begin
            I := I + 1;
            Continue;
          end;

          Indent := '';
          for K := 1 to Length(S) do
          begin
            if S[K] = ' ' then
              Indent := Indent + ' '
            else
              Break;
          end;

          J := I;
          while J < SL.Count do
          begin
            Line := SL[J];

            CommentTag := '{ ' + AClassName + ' }';
            if Pos(CommentTag, Line) > 0 then
            begin
              Rest := Copy(Line, Length(CommentTag) + 1);
              while (Length(Rest) > 0) and (Rest[1] in [' ', #9]) do
                Delete(Rest, 1, 1);
              Line := Rest;
            end;

            Impls.Add(Line);

            CurrIndent := '';
            for K := 1 to Length(SL[J]) do
            begin
              if SL[J][K] = ' ' then
                CurrIndent := CurrIndent + ' '
              else
                Break;
            end;

            TrimmedLine := SL[J];
            while (Length(TrimmedLine) > 0) and (TrimmedLine[1] = ' ') do
              Delete(TrimmedLine, 1, 1);

            if (TrimmedLine = 'end;') and (CurrIndent = Indent) then
            begin
              J := J + 1;
              Break;
            end;

            J := J + 1;
          end;
          I := J;
        end;
      finally
        SL.Free;
      end;

      // Compute class range
      ClassStart := -1;
      ClassEnd := -1;
      InClass := False;
      SL := TStringList.Create;
      try
        SL.Text := Source;
        for I := 0 to SL.Count - 1 do
        begin
          if Pos(AClassName + ' = class', SL[I]) > 0 then
          begin
            InClass := True;
            ClassStart := I + 1;
          end;
          if InClass and (Pos('end;', SL[I]) > 0) then
          begin
            ClassEnd := I + 1;
            Break;
          end;
        end;
      finally
        SL.Free;
      end;

      if (ClassStart < 1) or (ClassEnd < 1) then exit;

      // Build CLASSCOPY text
      Out := BuildClassCopyText(Source, AClassName, ClassStart, ClassEnd, Impls);

      // Set clipboard
      Clipboard.AsText := Out;
    finally
      Impls.Free;
    end;
    exit;
  end;

  if (CurNode.Desc = ctnProcedure) or (CurNode.Desc = ctnProperty) then begin
    FoundNode := FindClassCTNode(CurNode);
    if (FoundNode = nil) or (FoundNode.FirstChild = nil)
    or (not (FoundNode.FirstChild.Desc in AllClasses)) then
    begin
      // Not a class member: a standalone routine. A property cannot be one.
      if CurNode.Desc = ctnProcedure then
        CopyStandaloneRoutine;
      exit;
    end;

    CodeBuffer := CodeToolBoss.LoadFile(CodeFilename, false, false);
    if CodeBuffer = nil then exit;
    ACodeTool := nil;
    CodeToolBoss.Explore(CodeBuffer, ACodeTool, false);
    if ACodeTool = nil then exit;

    AClassName := ACodeTool.ExtractDefinitionName(FoundNode);
    if AClassName = '' then
      AClassName := CurItem.Text;
    if AClassName = '' then exit;

    Source := CodeBuffer.Source;
    SL := TStringList.Create;
    try
      SL.Text := Source;

      // Compute class range
      ClassStart := -1;
      ClassEnd := -1;
      InClass := False;
      for I := 0 to SL.Count - 1 do
      begin
        if Pos(AClassName + ' = class', SL[I]) > 0 then
        begin
          InClass := True;
          ClassStart := I + 1;
        end;
        if InClass and (Trim(SL[I]) = 'end;') then
        begin
          ClassEnd := I + 1;
          Break;
        end;
      end;
      if (ClassStart < 1) or (ClassEnd < 1) then exit;

      // Implementation nodes label the routine as "THuman.Walk"; take the
      // part after the dot so the member name matches the Interface node.
      MemberName := '';
      S := CurItem.Text;
      DotPos := Pos('.', S);
      if DotPos > 0 then
        S := Copy(S, DotPos + 1, Length(S));
      for K := 1 to Length(S) do
        if S[K] in ['A'..'Z', 'a'..'z', '0'..'9', '_'] then
          MemberName := MemberName + S[K]
        else
          Break;

      // Find the Interface declaration inside the class body. The
      // implementation node's StartPos points at the body, so it cannot be
      // used as the declaration line.
      MemberLineIdx := -1;
      for I := ClassStart - 1 to ClassEnd - 1 do
      begin
        S := Trim(SL[I]);
        if StartsWithMemberPrefix(S, 'procedure ' + MemberName)
        or StartsWithMemberPrefix(S, 'function ' + MemberName)
        or StartsWithMemberPrefix(S, 'constructor ' + MemberName)
        or StartsWithMemberPrefix(S, 'destructor ' + MemberName)
        or StartsWithMemberPrefix(S, 'operator ' + MemberName)
        or StartsWithMemberPrefix(S, 'class procedure ' + MemberName)
        or StartsWithMemberPrefix(S, 'class function ' + MemberName) then
        begin
          MemberLineIdx := I;
          Break;
        end;
      end;
      if MemberLineIdx < 0 then
      begin
        MemberCTNode := ACodeTool.FindDeepestNodeAtPos(CurNode.StartPos, false);
        if MemberCTNode = nil then
          MemberLineIdx := PosToLineIndex(Source, CurNode.StartPos)
        else
          MemberLineIdx := PosToLineIndex(Source, MemberCTNode.StartPos);
      end;

      VisLineIdx := -1;
      VisName := 'public';
      for I := ClassStart - 1 to MemberLineIdx do
      begin
        S := Trim(SL[I]);
        if (S = 'private') or (S = 'protected') or (S = 'public') or (S = 'published') then
        begin
          VisLineIdx := I;
          VisName := S;
        end;
      end;

      if (MemberLineIdx < 0) or (MemberLineIdx >= SL.Count) then exit;
      MemberDeclText := SL[MemberLineIdx];

      RoutineText := '';
      InImpl := False;
      I := 0;
      while I < SL.Count do
      begin
        if not InImpl then
        begin
          if Pos('implementation', SL[I]) > 0 then
            InImpl := True;
          I := I + 1;
          Continue;
        end;

        S := SL[I];
        Trimmed := S;
        while (Length(Trimmed) > 0) and (Trimmed[1] = ' ') do
          Delete(Trimmed, 1, 1);

        CommentTag := 'procedure ' + AClassName + '.' + MemberName;
        IsRoutine := (Pos(CommentTag, Trimmed) = 1) and
          ((Length(Trimmed) = Length(CommentTag)) or not IsIdentChar2(Trimmed[Length(CommentTag) + 1]));
        if not IsRoutine then
        begin
          CommentTag := 'function ' + AClassName + '.' + MemberName;
          IsRoutine := (Pos(CommentTag, Trimmed) = 1) and
            ((Length(Trimmed) = Length(CommentTag)) or not IsIdentChar2(Trimmed[Length(CommentTag) + 1]));
        end;
        if not IsRoutine then
        begin
          CommentTag := 'constructor ' + AClassName + '.' + MemberName;
          IsRoutine := (Pos(CommentTag, Trimmed) = 1) and
            ((Length(Trimmed) = Length(CommentTag)) or not IsIdentChar2(Trimmed[Length(CommentTag) + 1]));
        end;

        if not IsRoutine then
        begin
          I := I + 1;
          Continue;
        end;

        Indent := '';
        for K := 1 to Length(S) do
        begin
          if S[K] = ' ' then
            Indent := Indent + ' '
          else
            Break;
        end;

        J := I;
        while J < SL.Count do
        begin
          Line := SL[J];

          CommentTag := '{ ' + AClassName + ' }';
          if Pos(CommentTag, Line) > 0 then
          begin
            Rest := Copy(Line, Length(CommentTag) + 1);
            while (Length(Rest) > 0) and (Rest[1] in [' ', #9]) do
              Delete(Rest, 1, 1);
            Line := Rest;
          end;

          RoutineText := RoutineText + Line + CRLF;

          CurrIndent := '';
          for K := 1 to Length(SL[J]) do
          begin
            if SL[J][K] = ' ' then
              CurrIndent := CurrIndent + ' '
            else
              Break;
          end;

          TrimmedLine := SL[J];
          while (Length(TrimmedLine) > 0) and (TrimmedLine[1] = ' ') do
            Delete(TrimmedLine, 1, 1);

          if (TrimmedLine = 'end;') and (CurrIndent = Indent) then
          begin
            J := J + 1;
            Break;
          end;

          J := J + 1;
        end;
        Break;
      end;

      Out := '//MMWIN:MEMBERSCOPY' + CRLF;
      Out := Out + 'unit _MM_Copy_Buffer_;' + CRLF;
      Out := Out + CRLF;
      Out := Out + 'interface' + CRLF;
      Out := Out + CRLF;
      Out := Out + 'type' + CRLF;
      Out := Out + '  ' + AClassName + ' = class' + CRLF;
      if VisLineIdx >= 0 then
        Out := Out + SL[VisLineIdx] + CRLF
      else
        Out := Out + '  ' + VisName + CRLF;
      Out := Out + MemberDeclText + CRLF;
      Out := Out + '  end;' + CRLF;
      Out := Out + CRLF;
      Out := Out + 'implementation' + CRLF;
      Out := Out + CRLF;
      if RoutineText <> '' then
      begin
        Out := Out + RoutineText + CRLF;
        Out := Out + CRLF;
      end;
      Out := Out + 'end.' + CRLF;

      Clipboard.AsText := Out;
    finally
      SL.Free;
    end;
  end;
end;

procedure TWKCodeExplorerView.WKPasteMenuItemClick(Sender: TObject);
const
  CRLF = #13#10;
var
  SrcEdit: TSourceEditorInterface;
  Syn: TSynEdit;
  ClipText, Kind, OldName, NewName, Msg: string;
  Decl, InsertText, FirstLine, S, Header, Visibility, MemberText: string;
  Impls, SL: TStringList;
  EditorText: string;
  Lines: TStringList;
  SavedCaret: TPoint;
  SavedTopLine: Integer;
  InsertedLinesAbove: Integer;
  I, J, ImplSectionLine, FinalEndLine: Integer;
  ClassIdx, ClassEndIdx, ClassLineIdx, EndClassIdx: Integer;
  MemberInsertLine, InterfaceIdx, InterfaceLineNo: Integer;
  TypeLineIdx, ClassInsertLine, TargetIndent, CurrentIndent: Integer;
  RoutineExists, HasClass, HasPublished: Boolean;
  CurPasteTV: TCustomTreeView;
  CurPasteItem: TTreeNode;
  CurPasteNodeData: TViewNodeData;
  PasteTargetNode: TCodeTreeNode;
  PasteCodeBuffer: TCodeBuffer;
  PasteCodeTool: TCodeTool;
  TargetClassName, CheckHeader, MemberName: string;

  function LineIndent(const AText: string): Integer;
  begin
    Result := 0;
    while (Result < Length(AText)) and (AText[Result + 1] = ' ') do
      Inc(Result);
  end;

  function ShiftIndent(const AText: string; ADelta: Integer): string;
  var
    Tmp: TStringList;
    K, N: Integer;
    L: string;
  begin
    Result := '';
    if ADelta = 0 then Exit(AText);
    Tmp := TStringList.Create;
    try
      Tmp.Text := AText;
      for K := 0 to Tmp.Count - 1 do
      begin
        L := Tmp[K];
        if L = '' then
          Continue;
        if ADelta > 0 then
          L := StringOfChar(' ', ADelta) + L
        else
        begin
          N := -ADelta;
          while (N > 0) and (L <> '') and (L[1] = ' ') do
          begin
            Delete(L, 1, 1);
            Dec(N);
          end;
        end;
        Tmp[K] := L;
      end;
      Result := Tmp.Text;
    finally
      Tmp.Free;
    end;
  end;

  function CountInsertedLines(const AText: string): Integer;
  var
    K: Integer;
  begin
    Result := 0;
    K := 1;
    while K < Length(AText) do
    begin
      if (AText[K] = #13) and (AText[K + 1] = #10) then
      begin
        Inc(Result);
        Inc(K, 2);
      end
      else
        Inc(K);
    end;
  end;

  procedure InsertAtLine(ALine: Integer; const AText: string);
  begin
    if (ALine < 1) or (AText = '') then Exit;
    Syn.CaretXY := Point(1, ALine);
    Syn.SelText := AText;
    if ALine <= SavedCaret.Y then
      Inc(InsertedLinesAbove, CountInsertedLines(AText));
  end;

  function IsSectionLine(const ALine: string): Boolean;
  var
    T: string;
    P: Integer;
  begin
    Result := (ALine <> '') and (ALine[1] <> ' ') and (ALine[1] <> #9);
    if not Result then Exit;
    T := Trim(ALine);
    P := Pos(' ', T);
    if P > 0 then
      T := Copy(T, 1, P - 1);
    Result := SameText(T, 'var') or SameText(T, 'const') or
      SameText(T, 'resourcestring') or SameText(T, 'threadvar');
  end;

  // //MMWIN:MODULECOPY: paste a standalone routine. A selected class node
  // makes it a public method; otherwise it becomes a unit-level routine
  // (interface declaration + implementation body, or the body alone when it
  // was private in the source).
  procedure PasteStandaloneRoutine;
  var
    Vis, RName, RDecl, RBody, Owner, T, Params: string;
    DeclSource, BodyHeader, TargetVis: string;
    SL2, HL: TStringList;
    ImplLine2, FinalLine2, CIdx, CEndIdx, K: Integer;
    SectIdx, NextSect, InsLine: Integer;
    Duplicate: Boolean;
  begin
    if not WKParseModuleCopy(ClipText, Vis, RName, RDecl, RBody) then Exit;
    if RName = '' then Exit;
    if Trim(RBody) = '' then
    begin
      MessageDlg('Cannot paste: clipboard has no routine body',
        mtError, [mbOK], 0);
      Exit;
    end;

    // The header of the implementation body (first statement up to its ';').
    HL := TStringList.Create;
    try
      HL.Text := RBody;
      BodyHeader := WKJoinLineRange(HL, 0, WKHeaderEndLine(HL, 0));
    finally
      HL.Free;
    end;
    HL := TStringList.Create;
    try
      HL.Text := BodyHeader;
      Params := WKNormHeaderTail(WKJoinLineRange(HL, 0, WKHeaderEndLine(HL, 0)));
    finally
      HL.Free;
    end;

    // Destination: a selected class node makes it a method of that class.
    Owner := '';
    CurPasteTV := GetCurrentTreeView;
    if CurPasteTV <> nil then
    begin
      if tvoAllowMultiselect in CurPasteTV.Options then
        CurPasteItem := CurPasteTV.GetFirstMultiSelected
      else
        CurPasteItem := CurPasteTV.Selected;
      if CurPasteItem <> nil then
      begin
        CurPasteNodeData := TViewNodeData(CurPasteItem.Data);
        if (CurPasteNodeData <> nil) and (CurPasteNodeData.Desc = ctnTypeDefinition) then
        begin
          PasteTargetNode := FindClassCTNode(CurPasteNodeData);
          if PasteTargetNode <> nil then
          begin
            PasteCodeBuffer := CodeToolBoss.LoadFile(CodeFilename, false, false);
            if PasteCodeBuffer <> nil then
            begin
              PasteCodeTool := nil;
              CodeToolBoss.Explore(PasteCodeBuffer, PasteCodeTool, false);
              if PasteCodeTool <> nil then
                Owner := PasteCodeTool.ExtractDefinitionName(PasteTargetNode);
            end;
          end;
          if Owner = '' then
            Owner := CurPasteItem.Text;
        end;
      end;
    end;

    SavedCaret := Syn.CaretXY;
    SavedTopLine := Syn.TopLine;
    InsertedLinesAbove := 0;
    EditorText := Syn.Text;

    SL2 := TStringList.Create;
    try
      SL2.Text := EditorText;
      ImplLine2 := -1;
      FinalLine2 := -1;
      for K := 0 to SL2.Count - 1 do
      begin
        T := Trim(SL2[K]);
        if (ImplLine2 < 0) and SameText(T, 'implementation') then
          ImplLine2 := K;
        if SameText(T, 'end.') then
          FinalLine2 := K;
      end;
      if (ImplLine2 < 0) or (FinalLine2 < 0) then Exit;
      ImplLine2 := ImplLine2 + 1;
      FinalLine2 := FinalLine2 + 1;

      CIdx := -1;
      CEndIdx := -1;
      if Owner <> '' then
      begin
        for K := 0 to SL2.Count - 1 do
        begin
          if (CIdx < 0) and (Pos(Owner + ' = class', SL2[K]) > 0) then
            CIdx := K
          else if (CIdx >= 0) and (Trim(SL2[K]) = 'end;') then
          begin
            CEndIdx := K;
            Break;
          end;
        end;
        if (CIdx < 0) or (CEndIdx <= CIdx) then
        begin
          MessageDlg('Cannot paste: class ' + Owner + ' not found',
            mtError, [mbOK], 0);
          Exit;
        end;
      end;

      // Duplicate = same owner + name + parameter list (defaults ignored).
      if Owner <> '' then
        Duplicate :=
          (WKFindRoutineHeader(SL2, CIdx + 1, CEndIdx - 1, RName, Params,
             False, False) >= 0) or
          (WKFindRoutineHeader(SL2, ImplLine2, SL2.Count - 1,
             Owner + '.' + RName, Params, True, True) >= 0)
      else
        Duplicate :=
          (WKFindRoutineHeader(SL2, 0, ImplLine2 - 2, RName, Params,
             True, False) >= 0) or
          (WKFindRoutineHeader(SL2, ImplLine2, SL2.Count - 1, RName, Params,
             True, False) >= 0);
      if Duplicate then
      begin
        MessageDlg('Routine already exists', mtInformation, [mbOK], 0);
        Exit;
      end;

      Syn.BeginUpdate;
      try
        if Owner <> '' then
        begin
          if RDecl <> '' then
            DeclSource := RDecl
          else
            DeclSource := BodyHeader;
          DeclSource := WKIndentText(WKDequalifyMemberBlock(DeclSource, Owner), 2);

          // //VIS:PRIVATE becomes a private method; everything else public.
          // A body-only copy (no declaration) is private as well.
          if SameText(Vis, 'PRIVATE') or (RDecl = '') then
            TargetVis := 'private'
          else
            TargetVis := 'public';

          // Insert at the end of the matching section, or create one.
          SectIdx := -1;
          NextSect := CEndIdx;
          for K := CIdx + 1 to CEndIdx - 1 do
          begin
            T := LowerCase(Trim(SL2[K]));
            if (T = 'private') or (T = 'protected') or (T = 'public')
            or (T = 'published') then
            begin
              if SectIdx >= 0 then
              begin
                NextSect := K;
                Break;
              end;
              if T = TargetVis then
                SectIdx := K;
            end;
          end;
          InsLine := NextSect + 1;
          if SectIdx < 0 then
            DeclSource := '  ' + TargetVis + CRLF + DeclSource;

          InsertAtLine(FinalLine2, WKWithTrailingBlankLine(WKQualifyRoutineHeader(RBody, Owner)));
          InsertAtLine(InsLine, WKWithTrailingBlankLine(DeclSource));
          Msg := 'Pasted routine ' + RName + ' into ' + Owner;
        end
        else if RDecl <> '' then
        begin
          InsertAtLine(FinalLine2, WKWithTrailingBlankLine(RBody));
          InsertAtLine(ImplLine2, WKWithTrailingBlankLine(RDecl));
          Msg := 'Pasted routine ' + RName;
        end
        else
        begin
          InsertAtLine(FinalLine2, WKWithTrailingBlankLine(RBody));
          Msg := 'Pasted routine ' + RName + ' (implementation only)';
        end;
      finally
        Syn.EndUpdate;
      end;
      Syn.CaretXY := Point(SavedCaret.X, SavedCaret.Y + InsertedLinesAbove);
      Syn.TopLine := SavedTopLine;
      MessageDlg(Msg, mtInformation, [mbOK], 0);
    finally
      SL2.Free;
    end;
  end;

begin
  ClipText := Clipboard.AsText;
  Kind := ParseClipboardKind(ClipText);
  if (Kind = '') and (not WKIsModuleCopyText(ClipText)) then
  begin
    MessageDlg('Clipboard has no WK Code Explorer data', mtInformation, [mbOK], 0);
    Exit;
  end;

  SrcEdit := SourceEditorManagerIntf.ActiveEditor;
  if SrcEdit = nil then Exit;
  if not (SrcEdit.EditorControl is TSynEdit) then
  begin
    MessageDlg('Paste needs a text editor', mtInformation, [mbOK], 0);
    Exit;
  end;
  Syn := TSynEdit(SrcEdit.EditorControl);
  if Syn = nil then Exit;

  if WKIsModuleCopyText(ClipText) then
  begin
    PasteStandaloneRoutine;
    Exit;
  end;

  OldName := ParseClassName(ClipText);
  if OldName = '' then
  begin
    MessageDlg('Clipboard has no WK Code Explorer data', mtInformation, [mbOK], 0);
    Exit;
  end;

  SavedCaret := Syn.CaretXY;
  SavedTopLine := Syn.TopLine;
  InsertedLinesAbove := 0;
  EditorText := Syn.Text;
  NewName := ChooseFreeClassName(EditorText, OldName);

  TargetClassName := OldName;
  if Kind = 'MEMBER' then
  begin
    // Determine target class: if a class node is selected in the WK tree, paste into it.
    CurPasteTV := GetCurrentTreeView;
    if CurPasteTV <> nil then
    begin
      if tvoAllowMultiselect in CurPasteTV.Options then
        CurPasteItem := CurPasteTV.GetFirstMultiSelected
      else
        CurPasteItem := CurPasteTV.Selected;
      if CurPasteItem <> nil then
      begin
        CurPasteNodeData := TViewNodeData(CurPasteItem.Data);
        if (CurPasteNodeData <> nil) and (CurPasteNodeData.Desc = ctnTypeDefinition) then
        begin
          PasteTargetNode := FindClassCTNode(CurPasteNodeData);
          if PasteTargetNode <> nil then
          begin
            PasteCodeBuffer := CodeToolBoss.LoadFile(CodeFilename, false, false);
            if PasteCodeBuffer <> nil then
            begin
              PasteCodeTool := nil;
              CodeToolBoss.Explore(PasteCodeBuffer, PasteCodeTool, false);
              if PasteCodeTool <> nil then
                TargetClassName := PasteCodeTool.ExtractDefinitionName(PasteTargetNode);
            end;
          end;
          if TargetClassName = '' then
            TargetClassName := CurPasteItem.Text;
        end;
      end;
    end;
    if TargetClassName = '' then
      TargetClassName := OldName;
    NewName := TargetClassName;
  end;

  Lines := TStringList.Create;
  Impls := nil;
  try
    Lines.Text := EditorText;
    ImplSectionLine := -1;
    FinalEndLine := -1;
    ClassIdx := -1;
    ClassEndIdx := -1;
    for I := 0 to Lines.Count - 1 do
    begin
      S := Trim(Lines[I]);
      if (ImplSectionLine < 0) and (S = 'implementation') then
        ImplSectionLine := I + 1;
      if S = 'end.' then
        FinalEndLine := I + 1;
      if Kind = 'MEMBER' then
      begin
        if (ClassIdx < 0) and (Pos(NewName + ' = class', Lines[I]) > 0) then
          ClassIdx := I;
      end
      else
      begin
        if (ClassIdx < 0) and (Pos(OldName + ' = class', Lines[I]) > 0) then
          ClassIdx := I;
      end;
      if (ClassIdx >= 0) and (ClassEndIdx < 0) and (S = 'end;') then
        ClassEndIdx := I;
    end;
    HasClass := (ClassIdx >= 0) and (ClassEndIdx > ClassIdx);
    if (ImplSectionLine < 1) or (FinalEndLine < 1) then Exit;

    Impls := ExtractRoutines(ClipText);

    // MEMBERSCOPY: stop when an identical routine header already exists.
    RoutineExists := False;
    if Kind = 'MEMBER' then
    begin
      if HasClass then
      begin
        // Existing class target: compare the renamed header as before.
        for I := 0 to Impls.Count - 1 do
        begin
          J := Pos(CRLF, Impls[I]);
          if J > 0 then
            Header := Trim(Copy(Impls[I], 1, J - 1))
          else
            Header := Trim(Impls[I]);
          CheckHeader := RenameWholeIdentifier(Header, OldName, NewName);
          if (CheckHeader <> '') and (Pos(CheckHeader, EditorText) > 0) then
          begin
            RoutineExists := True;
            Break;
          end;
        end;
      end
      else
      begin
        // No class selected: the members become private standalone routines.
        // Compare owner (= none) + name + parameter list, defaults ignored.
        for I := 0 to Impls.Count - 1 do
        begin
          SL := TStringList.Create;
          try
            SL.Text := WKDequalifyMemberBlock(Impls[I], OldName);
            Header := WKJoinLineRange(SL, 0, WKHeaderEndLine(SL, 0));
          finally
            SL.Free;
          end;
          MemberName := WKHeaderName(Header);
          if MemberName = '' then
            Continue;
          if (WKFindRoutineHeader(Lines, 0, ImplSectionLine - 2, MemberName,
               WKNormHeaderTail(Header), True, False) >= 0)
          or (WKFindRoutineHeader(Lines, ImplSectionLine, Lines.Count - 1,
               MemberName, WKNormHeaderTail(Header), True, False) >= 0) then
          begin
            RoutineExists := True;
            Break;
          end;
        end;
      end;
      if RoutineExists then
      begin
        MessageDlg('Routine already exists', mtInformation, [mbOK], 0);
        Exit;
      end;
    end;

    Syn.BeginUpdate;
    try
      // Insert implementations first (highest line number) so earlier
      // insertion positions remain valid.
      InsertText := '';
      for I := 0 to Impls.Count - 1 do
      begin
        // Exactly one blank line between pasted routines, none before the
        // first and none after the last (each block already ends with CRLF).
        if I > 0 then
          InsertText := InsertText + CRLF;
        if (Kind = 'MEMBER') and (not HasClass) then
          // No class: strip "TOld." so the body is a unit-level routine.
          InsertText := InsertText +
            WKDequalifyMemberBlock(Impls[I], OldName)
        else
          InsertText := InsertText +
            RenameWholeIdentifier(Impls[I], OldName, NewName);
      end;
      InsertAtLine(FinalEndLine, WKWithTrailingBlankLine(InsertText));

      if Kind = 'CLASS' then
      begin
        Decl := RenameWholeIdentifier(ExtractClassDeclaration(ClipText),
          OldName, NewName);
        // Rename only the copied leading "{ OldName }" comment to "{ NewName }".
        J := Pos(CRLF, Decl);
        if J > 0 then
        begin
          S := Copy(Decl, 1, J - 1);
          if Trim(S) = '{ ' + OldName + ' }' then
            Decl := '{ ' + NewName + ' }' + Copy(Decl, J, Length(Decl));
        end;
        // Locate the interface type block. Only a column-zero "type" line
        // counts, so a class-level "type" inside a class body is never matched.
        TypeLineIdx := -1;
        InterfaceIdx := -1;
        for I := 0 to ImplSectionLine - 2 do
        begin
          S := Lines[I];
          if (InterfaceIdx < 0) and SameText(Trim(S), 'interface') then
            InterfaceIdx := I
          else if (InterfaceIdx >= 0) and (S <> '')
          and (S[1] <> ' ') and (S[1] <> #9)
          and SameText(Trim(S), 'type') then
          begin
            TypeLineIdx := I;
            Break;
          end;
        end;

        // Insert before the first column-zero var/const/resourcestring/threadvar
        // after the type line, otherwise before implementation.
        ClassInsertLine := ImplSectionLine;
        if TypeLineIdx >= 0 then
        begin
          for I := TypeLineIdx + 1 to ImplSectionLine - 2 do
            if IsSectionLine(Lines[I]) then
            begin
              ClassInsertLine := I + 1;
              Break;
            end;
        end
        else if InterfaceIdx >= 0 then
        begin
          for I := InterfaceIdx + 1 to ImplSectionLine - 2 do
            if IsSectionLine(Lines[I]) then
            begin
              ClassInsertLine := I + 1;
              Break;
            end;
        end;

        // Match the indentation of the first declaration in the type block.
        // With no type block (or no declaration) use two spaces.
        TargetIndent := 2;
        if TypeLineIdx >= 0 then
          for I := TypeLineIdx + 1 to ClassInsertLine - 2 do
          begin
            S := Trim(Lines[I]);
            if (S <> '') and (Lines[I][1] = ' ') and
               (S[1] <> '{') and (Pos('//', S) <> 1) then
            begin
              TargetIndent := LineIndent(Lines[I]);
              Break;
            end;
          end;

        CurrentIndent := 0;
        SL := TStringList.Create;
        try
          SL.Text := Decl;
          for I := 0 to SL.Count - 1 do
            if Pos('= class', SL[I]) > 0 then
            begin
              CurrentIndent := LineIndent(SL[I]);
              Break;
            end;
        finally
          SL.Free;
        end;
        Decl := ShiftIndent(Decl, TargetIndent - CurrentIndent);

        // Do not duplicate a { Name } comment already above the insertion point.
        if ClassInsertLine > 1 then
        begin
          S := Trim(Lines[ClassInsertLine - 2]);
          if Pos('{ ' + NewName + ' }', S) > 0 then
          begin
            J := Pos(CRLF, Decl);
            if J > 0 then
            begin
              FirstLine := Copy(Decl, 1, J - 1);
              if (Pos('{', FirstLine) > 0) and (Pos('}', FirstLine) > 0) then
                Delete(Decl, 1, J + Length(CRLF) - 1);
            end;
          end;
        end;
        // Only the case with no interface "type" line adds a "type" line.
        if TypeLineIdx < 0 then
          Decl := 'type' + CRLF + CRLF + Decl;
        InsertAtLine(ClassInsertLine, WKWithTrailingBlankLine(Decl));
        // Add {$M+} when the copied class has a published section and the
        // target unit does not already enable published fields.
        HasPublished := False;
        SL := TStringList.Create;
        try
          SL.Text := ClipText;
          for I := 0 to SL.Count - 1 do
            if SameText(Trim(SL[I]), 'published') then
            begin
              HasPublished := True;
              Break;
            end;
        finally
          SL.Free;
        end;
        if HasPublished and (Pos('{$M+}', UpperCase(EditorText)) = 0) then
        begin
          InterfaceLineNo := -1;
          for I := 0 to Lines.Count - 1 do
            if SameText(Trim(Lines[I]), 'interface') then
            begin
              InterfaceLineNo := I + 1;
              Break;
            end;
          if InterfaceLineNo > 0 then
            InsertAtLine(InterfaceLineNo, WKWithTrailingBlankLine('{$M+}'));
        end;
        Msg := 'Pasted class as ' + NewName;
      end
      else
      begin
        if HasClass then
        begin
          // Member declaration lines come from the clipboard class body.
          SL := TStringList.Create;
          try
            SL.Text := ExtractClassDeclaration(ClipText);
            ClassLineIdx := -1;
            EndClassIdx := -1;
            Visibility := '';
            for I := 0 to SL.Count - 1 do
              if (ClassLineIdx < 0) and (Pos('= class', SL[I]) > 0) then
                ClassLineIdx := I;
            if ClassLineIdx >= 0 then
              for I := ClassLineIdx + 1 to SL.Count - 1 do
              begin
                S := Trim(SL[I]);
                if S = 'end;' then
                begin
                  EndClassIdx := I;
                  Break;
                end;
                if (Visibility = '') and
                   ((S = 'private') or (S = 'protected') or
                    (S = 'public') or (S = 'published')) then
                  Visibility := S;
              end;
            MemberText := '';
            if (ClassLineIdx >= 0) and (EndClassIdx > ClassLineIdx) then
              for I := ClassLineIdx + 1 to EndClassIdx - 1 do
              begin
                S := Trim(SL[I]);
                if (Visibility <> '') and (S = Visibility) then
                  Continue;
                MemberText := MemberText + SL[I] + CRLF;
              end;
            MemberText := WKWithTrailingBlankLine(MemberText);
          finally
            SL.Free;
          end;

          // Visibility comes from clipboard class text (section label above member).
          // Insert into the matching section in the target class; if that section
          // is missing, add it before the target's "end;".
          MemberInsertLine := -1;
          if Visibility <> '' then
            for I := ClassIdx + 1 to ClassEndIdx - 1 do
              if Trim(Lines[I]) = Visibility then
              begin
                MemberInsertLine := I + 2;
                Break;
              end;
          if MemberInsertLine < 1 then
          begin
            MemberInsertLine := ClassEndIdx + 1;
            if Visibility <> '' then
              MemberText := '  ' + Visibility + CRLF + MemberText;
          end;
          InsertAtLine(MemberInsertLine, MemberText);
          Msg := 'Pasted member into ' + NewName;
        end
        else
        begin
          // No class selected: the implementation bodies were already added
          // above as private unit-level routines. No class is created.
          Msg := 'Pasted member as private routine';
        end;
      end;
    finally
      Syn.EndUpdate;
    end;
    Syn.CaretXY := Point(SavedCaret.X, SavedCaret.Y + InsertedLinesAbove);
    Syn.TopLine := SavedTopLine;
    MessageDlg(Msg, mtInformation, [mbOK], 0);
  finally
    Impls.Free;
    Lines.Free;
  end;
end;

procedure TWKCodeExplorerView.CloseIDEHandler(Sender: TObject);
begin
  CodeExplorerOptions.Save;
end;

procedure TWKCodeExplorerView.ShowSrcEditPosMenuItemClick(Sender: TObject);
begin
  SelectSourceEditorNode;
end;

procedure TWKCodeExplorerView.MainNotebookPageChanged(Sender: TObject);
begin
  if MainNotebook.ActivePage=DirectivesPage then
    CodeExplorerOptions.Page:=cepDirectives
  else
    CodeExplorerOptions.Page:=cepCode;
  Refresh(true);
end;

procedure TWKCodeExplorerView.CodeModeSpeedButtonClick(Sender: TObject);
begin
  // Let's Invert Mode of Exibition
  if Mode = cemCategory then
    SetMode(cemSource)
  else
    SetMode(cemCategory);
end;

procedure TWKCodeExplorerView.CodeRefreshSpeedButtonClick(Sender: TObject);
begin
  FLastCodeChangeStep:=CTInvalidChangeStamp;
  RefreshCode(true);
end;

procedure TWKCodeExplorerView.OptionsSpeedButtonClick(Sender: TObject);
begin
  if Assigned(FOnShowOptions) then
  begin
    OnShowOptions(Self);
    Refresh(True);
  end;
end;

procedure TWKCodeExplorerView.RefreshMenuItemClick(Sender: TObject);
begin
  FLastCodeChangeStep:=CTInvalidChangeStamp;
  FLastDirectivesChangeStep:=CTInvalidChangeStamp;
  Refresh(true);
end;

procedure TWKCodeExplorerView.RenameMenuItemClick(Sender: TObject);
begin
  if not JumpToSelection then begin
    IDEMessageDialog(lisCCOErrorCaption, lisTreeNeedsRefresh, mtError, [mbOk]);
    Refresh(true);
    exit;
  end;
  ExecuteIDECommand(SourceEditorManagerIntf.ActiveSourceWindow, ecRenameIdentifier);
end;

procedure TWKCodeExplorerView.TreePopupmenuPopup(Sender: TObject);
var
  CurTreeView: TCustomTreeView;
  CurItem: TTreeNode;
  CanRename: boolean;
  CurNode: TViewNodeData;
  HasImplementation: Boolean;
  FoundNode: TCodeTreeNode;
begin
  CanRename:=false;
  HasImplementation:=false;
  CurTreeView:=GetCurrentTreeView;
  if CurTreeView<>nil then begin
    if tvoAllowMultiselect in CurTreeView.Options then
      CurItem:=CurTreeView.GetFirstMultiSelected
    else
      CurItem:=CurTreeView.Selected;
    if CurItem<>nil then begin
      CurNode:=TViewNodeData(CurItem.Data);
      if CurNode.StartPos>0 then begin
        case CurrentPage of
        cepCode:
          if (CurNode.Desc in AllIdentifierDefinitions+[ctnProcedure,ctnProperty])
          and (CurItem.GetNextMultiSelected=nil) then
            CanRename:=true;
        cepDirectives:
          ;
        end;
      end;
      if (CurNode.ImplementationNode<>nil)
      and (CurNode.ImplementationNode.StartPos>0) then
        HasImplementation:=true;
    end;
  end;
  WKCERenameIDEMenuCommand.Visible:=CanRename;
  WKCEJumpToImplementationIDEMenuCommand.Visible:=HasImplementation;
  // Enable Copy for class nodes and for member nodes (procedure/property)
  WKCopyMenuItem.Enabled := false;
  if CurItem <> nil then begin
    CurNode := TViewNodeData(CurItem.Data);
    if CurNode <> nil then begin
      if CurNode.Desc = ctnTypeDefinition then begin
        FoundNode := FindClassCTNode(CurNode);
        if (FoundNode <> nil) and (FoundNode.FirstChild <> nil) and
           (FoundNode.FirstChild.Desc in AllClasses) then
          WKCopyMenuItem.Enabled := true;
      end
      else if CurNode.Desc in [ctnProcedure, ctnProperty] then
      begin
        FoundNode := FindClassCTNode(CurNode);
        if (FoundNode <> nil) and (FoundNode.FirstChild <> nil) and
           (FoundNode.FirstChild.Desc in AllClasses) then
          WKCopyMenuItem.Enabled := true
        else if CurNode.Desc = ctnProcedure then
          // Standalone routine (//MMWIN:MODULECOPY).
          WKCopyMenuItem.Enabled := true;
      end;
    end;
  end;
  //DebugLn(['TWKCodeExplorerView.TreePopupmenuPopup ',WKCERenameIDEMenuCommand.Visible]);
end;

procedure TWKCodeExplorerView.TreeviewDblClick(Sender: TObject);
begin
  JumpToSelection;
end;

procedure TWKCodeExplorerView.TreeviewDeletion(Sender: TObject; Node: TTreeNode);
begin
  if Node.Data<>nil then
    TObject(Node.Data).Free;
end;

procedure TWKCodeExplorerView.TreeviewKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_RETURN) and (Shift=[])
  or ((Key=FCodeCmd1.ShortcutA.Key1) and (Shift=FCodeCmd1.ShortcutA.Shift1))
  or ((Key=FCodeCmd1.ShortcutB.Key1) and (Shift=FCodeCmd1.ShortcutB.Shift1))
  or ((Key=FCodeCmd2.ShortcutA.Key1) and (Shift=FCodeCmd2.ShortcutA.Shift1))
  or ((Key=FCodeCmd2.ShortcutB.Key1) and (Shift=FCodeCmd2.ShortcutB.Shift1))
  or ((Key=FCodeCmd3.ShortcutA.Key1) and (Shift=FCodeCmd3.ShortcutA.Shift1))
  or ((Key=FCodeCmd3.ShortcutB.Key1) and (Shift=FCodeCmd3.ShortcutB.Shift1))
  then begin
    JumpToSelection;
    Key:=0;
  end;
end;

procedure TWKCodeExplorerView.UserInputHandler(Sender: TObject; var Msg: TLMessage);
begin
  if CodeExplorerOptions.Refresh=cerOnIdle then
    CheckOnIdle;
end;

type
  TSpeedButtonFriend = class(TSpeedButton);

procedure TWKCodeExplorerView.AssignAllImages;
begin
  IDEImages.AssignImage(CodeRefreshSpeedButton, 'laz_refresh');
  IDEImages.AssignImage(CodeOptionsSpeedButton, 'menu_environment_options');
  IDEImages.AssignImage(DirRefreshSpeedButton, 'laz_refresh');
  IDEImages.AssignImage(DirOptionsSpeedButton, 'menu_environment_options');

  CodeTreeview.Images := IDEImages.Images_16;
  ImgIDDefault := IDEImages.GetImageIndex('ce_default');
  ImgIDProgram := IDEImages.GetImageIndex('ce_program');
  ImgIDUnit := IDEImages.GetImageIndex('cc_unit');
  ImgIDInterface := IDEImages.GetImageIndex('ce_interface');
  ImgIDImplementation := IDEImages.GetImageIndex('ce_implementation');
  ImgIDInitialization := IDEImages.GetImageIndex('ce_initialization');
  ImgIDFinalization := IDEImages.GetImageIndex('ce_finalization');
  ImgIDType := IDEImages.GetImageIndex('cc_type');
  ImgIDVariable := IDEImages.GetImageIndex('cc_variable');
  ImgIDConst := IDEImages.GetImageIndex('cc_constant');
  ImgIDClass := IDEImages.GetImageIndex('cc_class');
  ImgIDClassInterface := IDEImages.GetImageIndex('ce_classinterface');
  ImgIDHelper := IDEImages.GetImageIndex('ce_helper');
  ImgIDRecord := IDEImages.GetImageIndex('cc_record');
  ImgIDEnum := IDEImages.GetImageIndex('cc_enum');
  ImgIDProcedure := IDEImages.GetImageIndex('cc_procedure');
  ImgIDFunction := IDEImages.GetImageIndex('cc_function');
  ImgIDConstructor := IDEImages.GetImageIndex('cc_constructor');
  ImgIDDestructor := IDEImages.GetImageIndex('cc_destructor');
  ImgIDLabel := IDEImages.GetImageIndex('cc_label');
  ImgIDOperator := IDEImages.GetImageIndex('cc_operator');
  ImgIDProperty := IDEImages.GetImageIndex('cc_property');
  ImgIDPropertyReadOnly := IDEImages.GetImageIndex('cc_property_ro');
  // sections
  ImgIDSection := IDEImages.GetImageIndex('ce_section');
  ImgIDHint := IDEImages.GetImageIndex('state_hint');

  TSpeedButtonFriend(CodeFilterEdit.Button).ButtonGlyph.LCLGlyphName := ResBtnListFilter;
  TSpeedButtonFriend(DirectivesFilterEdit.Button).ButtonGlyph.LCLGlyphName := ResBtnListFilter;
end;

function TWKCodeExplorerView.GetCodeNodeDescription(ACodeTool: TCodeTool;
  CodeNode: TCodeTreeNode): string;
var
  ClassIdentNode, HelperForNode, InhNode: TCodeTreeNode;
begin
  Result:='?';
  try
    case CodeNode.Desc of
    ctnUnit, ctnProgram, ctnLibrary, ctnPackage:
      Result:=CodeNode.DescAsString+' '+ACodeTool.ExtractSourceName;
    ctnTypeSection:
      Result:='Type';
    ctnVarSection:
      Result:='Var';
    ctnConstSection:
      Result:='Const';
    ctnLabelSection:
      Result:='Label';
    ctnResStrSection:
      Result:='Resourcestring';
    ctnVarDefinition, ctnConstDefinition, ctnEnumIdentifier, ctnLabel:
      Result:=ACodeTool.ExtractIdentifier(CodeNode.StartPos);
    ctnUseUnit:
      Result:=ACodeTool.ExtractDottedIdentifier(CodeNode.StartPos);
    ctnTypeDefinition:
      begin
        Result:=ACodeTool.ExtractIdentifier(CodeNode.StartPos);
        ClassIdentNode := CodeNode.FirstChild;
        if Assigned(ClassIdentNode) then
        begin
          if ClassIdentNode.Desc in [ctnClassHelper, ctnRecordHelper, ctnTypeHelper] then
            HelperForNode := ACodeTool.FindHelperForNode(ClassIdentNode)
          else
            HelperForNode := nil;
          InhNode:=ACodeTool.FindInheritanceNode(ClassIdentNode);
          if InhNode<>nil then
            Result:=Result+ACodeTool.ExtractNode(InhNode,[]);
          if HelperForNode<>nil then
            Result:=Result+' '+ACodeTool.ExtractNode(HelperForNode,[]);
        end;
      end;
    ctnGenericType:
      Result:=ACodeTool.ExtractDefinitionName(CodeNode);
    ctnClass,ctnObject,ctnObjCClass,ctnObjCCategory,ctnObjCProtocol,
    ctnClassInterface,ctnCPPClass:
      Result:='('+ACodeTool.ExtractClassInheritance(CodeNode,[])+')';
    ctnProcedure:
      Result:=ACodeTool.ExtractProcHead(CodeNode,
                    [// phpWithStart is no needed because there are icons
                     phpWithVarModifiers,
                     phpWithParameterNames,phpWithDefaultValues,phpWithResultType,
                     phpWithOfObject]);
    ctnProcedureHead:
      Result:='Procedure Header';
    ctnProperty:
      Result:=ACodeTool.ExtractPropName(CodeNode,false); // property keyword is not needed because there are icons
    ctnInterface:
      Result:='Interface';
    ctnBeginBlock:
      Result:='Begin block';
    ctnAsmBlock:
      Result:='Asm block';
    else
      Result:=CodeNode.DescAsString;
    end;
  except
    on E: ECodeToolError do
      Result:=''; // ignore syntax errors
  end;
end;

function TWKCodeExplorerView.GetDirectiveNodeDescription(
  ADirectivesTool: TDirectivesTool; Node: TCodeTreeNode): string;
begin
  Result:=ADirectivesTool.GetDirective(Node);
end;

function TWKCodeExplorerView.GetCodeFilter: string;
begin
  Result:=CodeFilterEdit.Text;
end;

procedure TWKCodeExplorerView.ClearCodeTreeView;
var
  f: TCEObserverCategory;
  c: TCodeExplorerCategory;
begin
  for c:=low(TCodeExplorerCategory) to high(TCodeExplorerCategory) do
    fCategoryNodes[c]:=nil;
  fObserverNode:=nil;
  for f:=low(TCEObserverCategory) to high(TCEObserverCategory) do
    fObserverCatNodes[f]:=nil;
  fSurroundingNode:=nil;
  CodeTreeview.Items.Clear;
end;

procedure TWKCodeExplorerView.ClearDirectivesTreeView;
begin
  DirectivesTreeView.Items.Clear;
end;

function TWKCodeExplorerView.GetCurrentPage: TCodeExplorerPage;
begin
  if MainNotebook.ActivePage=CodePage then
    Result:=cepCode
  else if MainNotebook.ActivePage=DirectivesPage then
    Result:=cepDirectives
  else
    Result:=cepNone;
end;

function TWKCodeExplorerView.GetDirectivesFilter: string;
begin
  Result:=DirectivesFilterEdit.Text;
end;

function TWKCodeExplorerView.GetCodeNodeImage(Tool: TFindDeclarationTool;
  CodeNode: TCodeTreeNode): integer;
begin
  case CodeNode.Desc of
    ctnProgram,ctnLibrary,ctnPackage: Result:=ImgIDProgram;
    ctnUnit:                          Result:=ImgIDUnit;
    ctnInterface:                     Result:=ImgIDInterface;
    ctnImplementation:                Result:=ImgIDImplementation;
    ctnInitialization:                Result:=ImgIDInitialization;
    ctnFinalization:                  Result:=ImgIDFinalization;
    ctnTypeSection:                   Result:=ImgIDSection;
    ctnTypeDefinition:
      begin
        if (CodeNode.FirstChild <> nil) then
          case CodeNode.FirstChild.Desc of
            ctnClassInterface,ctnDispinterface,ctnObjCProtocol:
              Result := ImgIDClassInterface;
            ctnClass,ctnObjCClass,ctnObjCCategory,ctnCPPClass:
              Result := ImgIDClass;
            ctnObject,ctnRecordType:
              Result := ImgIDRecord;
            ctnEnumerationType,ctnEnumIdentifier:
              Result:=ImgIDEnum;
            ctnClassHelper,ctnRecordHelper,ctnTypeHelper:
              Result := ImgIDHelper;
          else
            Result := ImgIDType;
          end
        else
          Result := ImgIDType;
      end;
    ctnVarSection:                    Result:=ImgIDSection;
    ctnVarDefinition:                 Result:=ImgIDVariable;
    ctnConstSection,ctnResStrSection: Result:=ImgIDSection;
    ctnConstDefinition:               Result:=ImgIDConst;
    ctnClassInterface,ctnDispinterface,ctnObjCProtocol:
      Result := ImgIDClassInterface;
    ctnClass,ctnObject,
    ctnObjCClass,ctnObjCCategory,ctnCPPClass:
                                      Result:=ImgIDClass;
    ctnRecordType:                    Result:=ImgIDRecord;
    ctnEnumerationType,ctnEnumIdentifier:
                                      Result:=ImgIDEnum;
    ctnClassHelper,ctnRecordHelper,ctnTypeHelper:
                                      Result:=ImgIDHelper;
    ctnProcedure:
                                      if Tool.NodeIsConstructor(CodeNode) then
                                        Result:=ImgIDConstructor
                                      else
                                      if Tool.NodeIsDestructor(CodeNode) then
                                        Result:=ImgIDDestructor
                                      else
                                      if Tool.NodeIsFunction(CodeNode) then
                                        Result:=ImgIDFunction
                                      else
                                      if Tool.NodeIsOperator(CodeNode) then
                                        Result:=ImgIDOperator
                                      else
                                        Result:=ImgIDProcedure;
    ctnProperty:                      Result:=ImgIDProperty;
    ctnUsesSection:                   Result:=ImgIDSection;
    ctnUseUnit:                       Result:=ImgIDUnit;
    ctnLabelSection:                  Result:=ImgIDSection;
    ctnLabel:                         Result:=ImgIDLabel;
  else
    Result:=ImgIDDefault;
  end;
end;

function TWKCodeExplorerView.GetDirectiveNodeImage(CodeNode: TCodeTreeNode): integer;
begin
  case CodeNode.SubDesc of
  cdnsInclude:  Result:=ImgIDSection;
  else
    case CodeNode.Desc of
    cdnIf:     Result:=ImgIDSection;
    cdnElseIf: Result:=ImgIDSection;
    cdnElse:   Result:=ImgIDSection;
    cdnEnd:    Result:=ImgIDSection;
    cdnDefine: Result:=ImgIDConst;
    else
      Result:=ImgIDDefault;
    end;
  end;
end;

procedure TWKCodeExplorerView.CreateIdentifierNodes(ACodeTool: TCodeTool;
  CodeNode: TCodeTreeNode; ParentViewNode: TTreeNode);
var
  NodeData: TViewNodeData;
  NodeText: String;
  ViewNode, CurParentViewNode, InFrontViewNode: TTreeNode;
  NodeImageIndex: Integer;
  ShowNode: Boolean;
  ShowChilds: Boolean;
  Category: TCodeExplorerCategory;
begin
  InFrontViewNode:=nil;
  while CodeNode<>nil do begin
    ShowNode:=true;
    ShowChilds:=true;
    CurParentViewNode:=ParentViewNode;

    // don't show statements
    if (CodeNode.Desc in AllPascalStatements+[ctnParameterList]-
        [ctnInitialization,ctnFinalization]) then begin
      ShowNode:=false;
      ShowChilds:=false;
    end;
    // don't show parameter lists
    if (CodeNode.Desc in [ctnProcedureHead]) then begin
      ShowNode:=false;
      ShowChilds:=false;
    end;
    // don't show forward class definitions
    if (CodeNode.Desc=ctnTypeDefinition)
    and (CodeNode.FirstChild<>nil)
    and (CodeNode.FirstChild.Desc in AllClasses)
    and ((CodeNode.FirstChild.SubDesc and ctnsForwardDeclaration)>0) then begin
      ShowNode:=false;
      ShowChilds:=false;
    end;
    // don't show class node (the type node is already shown)
    if (CodeNode.Desc in AllClasses) then begin
      ShowNode:=false;
    end;

    //don't show child nodes of ctnUseUnit
    if (CodeNode.Desc=ctnUseUnit)
    then begin
      ShowChilds:=false;
    end;

    // don't show subs
    if CodeNode.Desc in [ctnConstant,ctnIdentifier,ctnRangedArrayType,
      ctnOpenArrayType,ctnOfConstType,ctnRangeType,ctnTypeType,ctnFileType,
      ctnVariantType,ctnSetType,ctnProcedureType]
    then begin
      ShowNode:=false;
      ShowChilds:=false;
    end;

    // show enums, but not the brackets
    if CodeNode.Desc=ctnEnumerationType then
      ShowNode:=false;

    // don't show end node and class modification nodes
    if CodeNode.Desc in [ctnEndPoint,ctnClassInheritance,ctnHelperFor,
                         ctnClassAbstract,ctnClassExternal,ctnClassSealed]
    then
      ShowNode:=false;
      
    // don't show class visibility section nodes
    if (CodeNode.Desc in AllClassSections) then
      ShowNode:=false;

    // don't show record composition nodes, only the named field
    if CodeNode.Desc=ctnRecordComposition then
      ShowNode:=false;

    if Mode=cemCategory then begin
      // don't show method bodies
      if (CodeNode.Desc=ctnProcedure)
      and (ACodeTool.NodeIsMethodBody(CodeNode)) then begin
        ShowNode:=false;
        ShowChilds:=false;
      end;

      // don't show single hint modifiers
      if (CodeNode.Desc = ctnHintModifier) and (CurParentViewNode = nil) then
      begin
        ShowNode:=false;
        ShowChilds:=false;
      end;

      // category mode: put nodes in categories
      Category:=cecNone;
      if ShowNode
      and ((CodeNode.Parent=nil)
        or (CodeNode.Parent.Desc in AllCodeSections)
        or (CodeNode.Parent.Parent=nil)
        or (CodeNode.Parent.Parent.Desc in AllCodeSections)) then
      begin
        // top level definition
        case CodeNode.Desc of
        ctnUseUnit:         Category:=cecUses;
        ctnTypeDefinition,ctnGenericType:  Category:=cecTypes;
        ctnVarDefinition:   Category:=cecVariables;
        ctnConstDefinition,ctnEnumIdentifier: Category:=cecConstants;
        ctnProcedure:       Category:=cecProcedures;
        ctnProperty:        Category:=cecProperties;
        end;
        if Category<>cecNone then begin
          ShowNode:=Category in CodeExplorerOptions.Categories;
          if ShowNode then begin
            if fCategoryNodes[Category]=nil then begin
              // create treenode for new category
              NodeData:=TViewNodeData.Create(CodeNode.Parent);
              NodeText:=CodeExplorerLocalizedString(Category);
              NodeImageIndex:=GetCodeNodeImage(ACodeTool,CodeNode.Parent);
              fCategoryNodes[Category]:=CodeTreeview.Items.AddChildObject(nil,
                                                             NodeText,NodeData);
              fCategoryNodes[Category].ImageIndex:=NodeImageIndex;
              fCategoryNodes[Category].SelectedIndex:=NodeImageIndex;
            end;
            if (CurParentViewNode=nil) then
              CurParentViewNode:=fCategoryNodes[Category];
            InFrontViewNode:=nil;
          end;
        end else begin
          ShowNode:=false;
        end;
      end else begin
        // not a top level node
      end;
      //DebugLn(['TWKCodeExplorerView.CreateIdentifierNodes ',CodeNode.DescAsString,' ShowNode=',ShowNode,' ShowChilds=',ShowChilds]);
    end;
    
    if ShowNode then begin
      // add a node to the TTreeView
      NodeData:=TViewNodeData.Create(CodeNode);
      CreateNodePath(ACodeTool,NodeData);
      NodeText:=GetCodeNodeDescription(ACodeTool,CodeNode);
      NodeImageIndex:=GetCodeNodeImage(ACodeTool,CodeNode);
      //if NodeText='TWKCodeExplorerView' then
      //  debugln(['TWKCodeExplorerView.CreateIdentifierNodes CodeNode=',CodeNode.DescAsString,' NodeText="',NodeText,'" Category=',dbgs(Category),' InFrontViewNode=',InFrontViewNode<>nil,' CurParentViewNode=',CurParentViewNode<>nil]);
      if InFrontViewNode<>nil then
        ViewNode:=CodeTreeview.Items.InsertObjectBehind(InFrontViewNode,NodeText,NodeData)
      else if CurParentViewNode<>nil then
        ViewNode:=CodeTreeview.Items.AddChildObject(CurParentViewNode,NodeText,NodeData)
      else
        ViewNode:=CodeTreeview.Items.AddObject(nil,NodeText,NodeData);
      ViewNode.ImageIndex:=NodeImageIndex;
      ViewNode.SelectedIndex:=NodeImageIndex;
      InFrontViewNode:=ViewNode;
    end else begin
      // do not add a node to the TTreeView
      ViewNode:=CurParentViewNode;
      AddImplementationNode(ACodeTool,CodeNode);
    end;
    if ShowChilds then
      CreateIdentifierNodes(ACodeTool,CodeNode.FirstChild,ViewNode);
    CodeNode:=CodeNode.NextBrother;
  end;
end;

procedure TWKCodeExplorerView.CreateDirectiveNodes(ADirectivesTool: TDirectivesTool;
  CodeNode: TCodeTreeNode; ParentViewNode: TTreeNode);
var
  NodeData: TViewNodeData;
  NodeText: String;
  ViewNode, InFrontViewNode: TTreeNode;
  NodeImageIndex: Integer;
  ShowNode: Boolean;
  ShowChilds: Boolean;
begin
  InFrontViewNode:=nil;
  while CodeNode<>nil do begin
    ShowNode:=true;
    ShowChilds:=true;
    
    // do not show root node
    if CodeNode.Desc=cdnRoot then begin
      ShowNode:=false;
    end;

    ViewNode:=ParentViewNode;
    if ShowNode then begin
      NodeData:=TViewNodeData.Create(CodeNode,false);
      NodeText:=GetDirectiveNodeDescription(ADirectivesTool,CodeNode);
      NodeImageIndex:=GetDirectiveNodeImage(CodeNode);
      if InFrontViewNode<>nil then
        ViewNode:=DirectivesTreeView.Items.InsertObjectBehind(
                                              InFrontViewNode,NodeText,NodeData)
      else if ParentViewNode<>nil then
        ViewNode:=DirectivesTreeView.Items.AddChildObject(
                                               ParentViewNode,NodeText,NodeData)
      else
        ViewNode:=DirectivesTreeView.Items.AddObject(nil,NodeText,NodeData);
      ViewNode.ImageIndex:=NodeImageIndex;
      ViewNode.SelectedIndex:=NodeImageIndex;
      InFrontViewNode:=ViewNode;
    end;
    if ShowChilds then
      CreateDirectiveNodes(ADirectivesTool,CodeNode.FirstChild,ViewNode);
    CodeNode:=CodeNode.NextBrother;
  end;
end;

procedure TWKCodeExplorerView.CreateObservations(Tool: TCodeTool);

  function AddCodeNode(f: TCEObserverCategory; CodeNode: TCodeTreeNode): TTreeNode;
  var
    Data: TViewNodeData;
    ObsTVNode: TTreeNode;
    NodeText: String;
    NodeImageIndCex: LongInt;
  begin
    ObsTVNode:=CreateObserverNode(Tool,f);
    if ObsTVNode.Count>=CodeObserverMaxNodes then
    begin
      fObserverCatOverflow[f]:=true;
      exit(nil);
    end;
    Data:=TViewNodeData.Create(CodeNode);
    NodeText:=GetCodeNodeDescription(Tool,CodeNode);
    NodeImageIndCex:=GetCodeNodeImage(Tool,CodeNode);
    Result:=CodeTreeview.Items.AddChild(ObsTVNode,NodeText);
    Result.Data:=Data;
    Result.Text:=NodeText;
    Result.ImageIndex:=NodeImageIndCex;
    Result.SelectedIndex:=NodeImageIndCex;
  end;

  function IsHiddenClassSection(SectionNode: TCodeTreeNode): boolean;
  // the first visibility section of a class/object/record has no keyword
  begin
    Result:=(SectionNode<>nil)
        and (SectionNode.Desc in AllClassBaseSections)
        and ((SectionNode.PriorBrother=nil)
          or (not (SectionNode.PriorBrother.Desc in AllClassBaseSections)));
  end;

  procedure CheckUnsortedClassMembers(ParentCodeNode: TCodeTreeNode);
  var
    LastNode: TCodeTreeNode;
    LastIdentifier: string;

    function NodeSorted(CodeNode: TCodeTreeNode): boolean;
    var
      p: PChar;
      Identifier: String;
    begin
      Result:=true;
      if (LastNode<>nil)
      //and (not CodeToolBoss.SourceChangeCache.BeautifyCodeOptions.MixMethodsAndProperties)
      and (CodeNode.Desc<>LastNode.Desc) then begin
        // sort variables then methods and properties
        if (LastNode.Desc in [ctnProperty,ctnProcedure])
        and not (CodeNode.Desc in [ctnProperty,ctnProcedure])
        then begin
          Result:=false;
        end;
        if (LastNode.Desc in [ctnProperty])
        and (CodeNode.Desc in [ctnProcedure])
        and (not CodeToolBoss.SourceChangeCache.BeautifyCodeOptions.MixMethodsAndProperties)
        then
          Result:=false;
      end;
      p:=Tool.GetNodeIdentifier(CodeNode);
      if p<>nil then
        Identifier:=GetIdentifier(p)
      else
        Identifier:='';
      if Result and (LastIdentifier<>'') and (Identifier<>'')
      and (CodeNode.Desc=LastNode.Desc) then begin
        // compare identifiers
        if CompareIdentifiers(PChar(Identifier),PChar(LastIdentifier))>0 then
        begin
          Result:=false;
        end;
      end;
      if not Result then begin
        AddCodeNode(cefcUnsortedClassMembers,CodeNode);
      end;
      LastNode:=CodeNode;
      LastIdentifier:=Identifier;
    end;

  var
    CodeNode: TCodeTreeNode;
  begin
    CodeNode:=ParentCodeNode.FirstChild;
    LastNode:=nil;
    while CodeNode<>nil do begin
      if CodeNode.Desc in AllIdentifierDefinitions then begin
        if not NodeSorted(CodeNode) then exit;
        // skip all variables in a group (e.g. Next,Prev:TNode)
        while CodeNode.FirstChild=nil do begin
          CodeNode:=CodeNode.NextBrother;
          if CodeNode=nil then exit;
        end;
      end else if CodeNode.Desc in [ctnProperty,ctnProcedure] then
      begin
        if not NodeSorted(CodeNode) then exit;
      end;
      CodeNode:=CodeNode.NextBrother;
    end;
  end;

var
  CodeNode: TCodeTreeNode;
  LineCnt: LongInt;
  i: integer;
  f: TCEObserverCategory;
  ObserverCats: TCEObserverCategories;
  ProcNode: TCodeTreeNode;
  ObsState: TCodeObserverStatementState;
  TVNode: TTreeNode;
begin
  CodeNode:=Tool.Tree.Root;
  ObserverCats:=CodeExplorerOptions.ObserverCategories;
  ObsState:=TCodeObserverStatementState.Create;
  try
    while CodeNode<>nil do begin
      case CodeNode.Desc of

      ctnBeginBlock:
        begin
          if (cefcLongProcs in ObserverCats)
          and (CodeNode.Parent.Desc=ctnProcedure) then begin
            LineCnt:=LineEndCount(Tool.Src,CodeNode.StartPos,CodeNode.EndPos,i);
            if LineCnt>=CodeExplorerOptions.LongProcLineCount then
            begin
              ProcNode:=CodeNode.Parent;
              TVNode:=AddCodeNode(cefcLongProcs,ProcNode);
              if Assigned(TVNode) then
                TVNode.Text:=TVNode.Text+' ['+IntToStr(LineCnt)+']';
            end;
          end;
          if (cefcEmptyProcs in ObserverCats)
          and (CodeNode.Parent.Desc=ctnProcedure) then
          begin
            Tool.MoveCursorToCleanPos(CodeNode.StartPos);
            Tool.ReadNextAtom;// read begin
            Tool.ReadNextAtom;
            if Tool.CurPos.Flag=cafEnd then begin
              // no code, maybe comments and directives (hidden code)
              ProcNode:=CodeNode.Parent;
              AddCodeNode(cefcEmptyProcs,ProcNode);
            end;
          end;
          if not CodeNode.HasParentOfType(ctnBeginBlock) then
          begin
            CreateObserverNodesForStatement(Tool,CodeNode,
                                    CodeNode.StartPos,CodeNode.EndPos,ObsState);
          end;
          if (cefcEmptyBlocks in ObserverCats)
          and CodeIsOnlySpace(Tool.Src,CodeNode.StartPos+length('begin'),
               CodeNode.EndPos-length('end')-1)
          then begin
            AddCodeNode(cefcEmptyBlocks,CodeNode);
          end;
        end;

      ctnAsmBlock:
        begin
          if (cefcEmptyBlocks in ObserverCats)
          and CodeIsOnlySpace(Tool.Src,CodeNode.StartPos+length('asm'),
               CodeNode.EndPos-length('end')-1)
          then begin
            AddCodeNode(cefcEmptyBlocks,CodeNode);
          end;
        end;

      ctnProcedure:
        begin
          if (cefcNestedProcs in ObserverCats) then
          begin
            i:=0;
            ProcNode:=CodeNode.FirstChild;
            while ProcNode<>nil do begin
              if ProcNode.Desc=ctnProcedure then
                inc(i);
              ProcNode:=ProcNode.NextBrother;
            end;
            if i>=CodeExplorerOptions.NestedProcCount then begin
              AddCodeNode(cefcNestedProcs,CodeNode);
            end;
          end;
        end;

      ctnParameterList:
        begin
          if (cefcLongParamLists in ObserverCats)
          and (CodeNode.HasParentOfType(ctnInterface))
          and (CodeNode.ChildCount>CodeExplorerOptions.LongParamListCount) then
          begin
            if (CodeNode.Parent.Desc=ctnProcedureHead)
            and (CodeNode.Parent.Parent.Desc=ctnProcedure) then
            begin
              ProcNode:=CodeNode.Parent.Parent;
              AddCodeNode(cefcLongParamLists,ProcNode);
            end;
          end;
        end;

      ctnProperty:
        begin
          if (cefcPublishedPropWithoutDefault in ObserverCats)
          and (CodeNode.Parent.Desc=ctnClassPublished) then
          begin
            if (not Tool.PropertyHasSpecifier(CodeNode,'DEFAULT',false))
            and (Tool.PropertyHasSpecifier(CodeNode,'READ',false))
            and (Tool.PropertyHasSpecifier(CodeNode,'WRITE',false))
            then
              AddCodeNode(cefcPublishedPropWithoutDefault,CodeNode);
          end;
        end;

      ctnClassClassVar..ctnClassPublished:
        begin
          if (cefcUnsortedClassVisibility in ObserverCats)
          and (CodeNode.PriorBrother<>nil)
          and (CodeNode.PriorBrother.Desc in AllClassBaseSections)
          and (CodeNode.PriorBrother.Desc>CodeNode.Desc)
          then begin
            if IsHiddenClassSection(CodeNode.PriorBrother)
            and ((CodeNode.PriorBrother.Desc=ctnClassPublished)
              or (CodeNode.PriorBrother.FirstChild=nil))
            then begin
              // the hidden first section is either published or empty
            end else begin
              // the prior section was more visible
              AddCodeNode(cefcUnsortedClassVisibility,CodeNode);
            end;
          end;
          if (cefcUnsortedClassMembers in ObserverCats)
          then
            CheckUnsortedClassMembers(CodeNode);
          if (cefcEmptyClassSections in ObserverCats)
          and (CodeNode.FirstChild=nil) then
          begin
            if IsHiddenClassSection(CodeNode) then begin
              // the hidden first section can be empty
            end else begin
              // empty class section
              AddCodeNode(cefcEmptyClassSections,CodeNode);
            end;
          end;
        end;

      end;
      CodeNode:=CodeNode.Next;
    end;

    if cefcToDos in ObserverCats then
      FindObserverTodos(Tool);
  finally
    ObsState.Free;
  end;

  // add numbers
  for f:=low(TCEObserverCategory) to high(TCEObserverCategory) do
  begin
    if fObserverCatNodes[f]=nil then continue;
    if fObserverCatOverflow[f] then
      fObserverCatNodes[f].Text:=
        fObserverCatNodes[f].Text+' ('+IntToStr(fObserverCatNodes[f].Count)+'+)'
    else
      fObserverCatNodes[f].Text:=
        fObserverCatNodes[f].Text+' ('+IntToStr(fObserverCatNodes[f].Count)+')';
  end;
end;

function TWKCodeExplorerView.CreateObserverNode(Tool: TCodeTool;
  f: TCEObserverCategory): TTreeNode;
var
  Data: TViewNodeData;
begin
  if fObserverCatNodes[f] = nil then
  begin
    if fObserverNode = nil then
    begin
      fObserverNode:=CodeTreeview.Items.Add(nil, lisCodeObserver);
      Data:=TViewNodeData.Create(Tool.Tree.Root);
      Data.Desc:=ctnNone;
      Data.StartPos:=Tool.SrcLen;
      fObserverNode.Data:=Data;
      fObserverNode.ImageIndex:=ImgIDSection;
      fObserverNode.SelectedIndex:=ImgIDSection;
    end;
    fObserverCatNodes[f]:=CodeTreeview.Items.AddChild(fObserverNode,
                            CodeExplorerLocalizedString(f));
    Data:=TViewNodeData.Create(Tool.Tree.Root);
    Data.Desc:=ctnNone;
    Data.StartPos:=Tool.SrcLen;
    fObserverCatNodes[f].Data:=Data;
    fObserverCatNodes[f].ImageIndex:=ImgIDHint;
    fObserverCatNodes[f].SelectedIndex:=ImgIDHint;
  end;
  Result:=fObserverCatNodes[f];
end;

procedure TWKCodeExplorerView.CreateObserverNodesForStatement(Tool: TCodeTool;
  CodeNode: TCodeTreeNode;
  StartPos, EndPos: integer; ObserverState: TCodeObserverStatementState);
var
  Data: TViewNodeData;
  ObsTVNode: TTreeNode;
  NodeText: String;
  NodeImageIndex: LongInt;
  TVNode: TTreeNode;
  ProcNode: TCodeTreeNode;
  OldPos: LongInt;
  CurAtom, Last1Atom, Last2Atom: TCommonAtomFlag;
  FuncName: string;
  Atom: TAtomPosition;
  c1: Char;
  Typ: TCodeObsStackItemType;
  CheckWrongIndentation: boolean;
  FindUnnamedConstants: boolean;

  procedure CheckSubStatement(CanBeEqual: boolean);
  var
    StatementStartPos: Integer;
    LastIndent: LongInt;
    Indent: LongInt;
    NeedUndo: Boolean;
    LastPos: LongInt;
  begin
    //DebugLn(['CheckSubStatement START=',Tool.GetAtom,' ',CheckWrongIndentation,' ',ObserverState.StatementStartPos,' ',dbgstr(copy(Tool.Src,ObserverState.StatementStartPos,15))]);
    if not CheckWrongIndentation then exit;
    StatementStartPos:=ObserverState.StatementStartPos;
    if StatementStartPos<1 then exit;
    LastPos:=Tool.CurPos.StartPos;
    Tool.ReadNextAtom;
    if PositionsInSameLine(Tool.Src,LastPos,Tool.CurPos.StartPos) then exit;
    NeedUndo:=true;
    //DebugLn(['CheckSubStatement NEXT=',Tool.GetAtom,' NotSameLine=',not PositionsInSameLine(Tool.Src,StatementStartPos,Tool.CurPos.StartPos),' ',dbgstr(copy(Tool.Src,Tool.CurPos.StartPos,15))]);
    if (Tool.CurPos.Flag<>cafNone)
    and (not PositionsInSameLine(Tool.Src,StatementStartPos,Tool.CurPos.StartPos))
    then begin
      LastIndent:=GetLineIndent(Tool.Src,StatementStartPos);
      Indent:=GetLineIndent(Tool.Src,Tool.CurPos.StartPos);
      //DebugLn(['CheckSubStatement OTHER LINE ',Tool.GetAtom,' ',LastIndent,' ',Indent]);
      if (Indent<LastIndent)
      or ((Indent=LastIndent) and (not CanBeEqual) and (not Tool.UpAtomIs('BEGIN')))
      then begin
        //DebugLn(['CheckSubStatement START=',CheckWrongIndentation,' ',ObserverState.StatementStartPos,' ',dbgstr(copy(Tool.Src,ObserverState.StatementStartPos,15))]);
        //DebugLn(['CheckSubStatement NEXT=',Tool.GetAtom,' NotSameLine=',not PositionsInSameLine(Tool.Src,StatementStartPos,Tool.CurPos.StartPos),' ',dbgstr(copy(Tool.Src,Tool.CurPos.StartPos,15))]);
        //DebugLn(['CheckSubStatement OTHER LINE LastIndent=',LastIndent,' Indent=',Indent]);
        // add wrong indentation
        ObsTVNode:=CreateObserverNode(Tool,cefcWrongIndentation);
        if ObsTVNode.Count>=CodeObserverMaxNodes then
        begin
          fObserverCatOverflow[cefcWrongIndentation]:=true;
        end else begin
          Data:=TViewNodeData.Create(CodeNode);
          Data.Desc:=ctnConstant;
          Data.SubDesc:=ctnsNone;
          Data.StartPos:=Tool.CurPos.StartPos;
          Data.EndPos:=Tool.CurPos.EndPos;
          NodeText:=Tool.GetAtom;
          // add some context information
          Tool.UndoReadNextAtom;
          NeedUndo:=false;
          ProcNode:=CodeNode;
          while (ProcNode<>nil) and (ProcNode.Desc<>ctnProcedure) do
            ProcNode:=ProcNode.Parent;
          if ProcNode<>nil then begin
            OldPos:=Tool.CurPos.EndPos;
            NodeText:=Format(lisCEIn, [NodeText, Tool.ExtractProcName(ProcNode, [
              phpWithoutClassName])]);
            Tool.MoveCursorToCleanPos(OldPos);
          end;
          NodeImageIndex:=ImgIDConst;
          TVNode:=CodeTreeview.Items.AddChild(ObsTVNode,NodeText);
          TVNode.Data:=Data;
          TVNode.Text:=NodeText;
          TVNode.ImageIndex:=NodeImageIndex;
          TVNode.SelectedIndex:=NodeImageIndex;
        end;
      end;
    end;
    if NeedUndo then
      Tool.UndoReadNextAtom;
  end;

begin
  if EndPos>Tool.SrcLen then EndPos:=Tool.SrcLen+1;
  if (StartPos<1) or (StartPos>=EndPos) then exit;
  CheckWrongIndentation:=cefcWrongIndentation in CodeExplorerOptions.ObserverCategories;
  FindUnnamedConstants:=cefcUnnamedConsts in CodeExplorerOptions.ObserverCategories;
  if (not FindUnnamedConstants) and (not CheckWrongIndentation) then exit;
  Tool.MoveCursorToCleanPos(StartPos);
  Last1Atom:=cafNone;
  Last2Atom:=cafNone;
  ObserverState.Reset;
  while Tool.CurPos.StartPos<EndPos do begin
    CurAtom:=cafNone;
    if ObserverState.StatementStartPos<1 then
    begin
      // start of statement
      ObserverState.StatementStartPos:=Tool.CurPos.StartPos;
    end;

    c1:=Tool.Src[Tool.CurPos.StartPos];
    case c1 of
    ';':
      begin
        // end of statement
        ObserverState.StatementStartPos:=0;
      end;

    '''','#','0'..'9','$','%':
      begin
        // a constant
        if not FindUnnamedConstants then begin
          // ignore
        end else if (ObserverState.IgnoreConstLevel>=0)
        and (ObserverState.IgnoreConstLevel>=ObserverState.StackPtr)
        then begin
          // ignore range
        end else if Tool.AtomIsEmptyStringConstant then begin
          // ignore empty string constant ''
        end else if Tool.AtomIsCharConstant
        and (not CodeExplorerOptions.ObserveCharConst) then
        begin
          // ignore char constants
        end else if CodeExplorerOptions.COIgnoreConstant(@Tool.Src[Tool.CurPos.StartPos])
        then begin
          // ignore user defined constants
        end else begin
          // add constant
          ObsTVNode:=CreateObserverNode(Tool,cefcUnnamedConsts);
          if ObsTVNode.Count>=CodeObserverMaxNodes then
          begin
            fObserverCatOverflow[cefcUnnamedConsts]:=true;
            break;
          end else begin
            Data:=TViewNodeData.Create(CodeNode);
            Data.Desc:=ctnConstant;
            Data.SubDesc:=ctnsNone;
            Data.StartPos:=Tool.CurPos.StartPos;
            Data.EndPos:=Tool.CurPos.EndPos;
            NodeText:=Tool.GetAtom;
            // add some context information
            ProcNode:=CodeNode;
            while (ProcNode<>nil) and (ProcNode.Desc<>ctnProcedure) do
              ProcNode:=ProcNode.Parent;
            if ProcNode<>nil then begin
              OldPos:=Tool.CurPos.EndPos;
              NodeText:=Format(lisCEIn, [NodeText, Tool.ExtractProcName(ProcNode, [
                phpWithoutClassName])]);
              Tool.MoveCursorToCleanPos(OldPos);
            end;
            NodeImageIndex:=ImgIDConst;
            TVNode:=CodeTreeview.Items.AddChild(ObsTVNode,NodeText);
            TVNode.Data:=Data;
            TVNode.Text:=NodeText;
            TVNode.ImageIndex:=NodeImageIndex;
            TVNode.SelectedIndex:=NodeImageIndex;
          end;
        end;
      end;

    '.':
      CurAtom:=cafPoint;

    '(','[':
      begin
        if c1='(' then
          ObserverState.Push(cositRoundBracketOpen,Tool.CurPos.StartPos)
        else
          ObserverState.Push(cositEdgedBracketOpen,Tool.CurPos.StartPos);
        if (Last1Atom=cafWord)
        and (ObserverState.IgnoreConstLevel<0) then
        begin
          Atom:=Tool.LastAtoms.GetPriorAtom;
          FuncName:=copy(Tool.Src,Atom.StartPos,Atom.EndPos-Atom.StartPos);
          if Last2Atom=cafPoint then
            FuncName:='.'+FuncName;
          if CodeExplorerOptions.COIgnoreConstInFunc(FuncName) then
          begin
            // skip this function call
            ObserverState.IgnoreConstLevel:=ObserverState.StackPtr;
          end;
        end;
      end;

    ')',']':
      begin
        while ObserverState.StackPtr>0 do
        begin
          Typ:=ObserverState.TopType;
          if Typ in [cositRoundBracketOpen,cositEdgedBracketOpen]
          then begin
            ObserverState.Pop;
            // normally brackets must match () []
            // but during editing often the brackets don't match
            // for example [( ]
            // skip silently
            if (Typ=cositRoundBracketOpen)=(c1='(') then break;
          end else begin
            // missing bracket close
            break;
          end;
        end;
      end;

    ':':
      ObserverState.StatementStartPos:=-1;

    '_','a'..'z','A'..'Z':
      begin
        CurAtom:=cafWord;
        if Tool.UpAtomIs('END') then
        begin
          while ObserverState.StackPtr>0 do
          begin
            Typ:=ObserverState.Pop;
            if Typ in [cositBegin,cositFinally,cositExcept,cositCase,cositCaseElse]
            then
              break;
          end;
          ObserverState.StatementStartPos:=-1;
        end
        else if Tool.UpAtomIs('BEGIN') then
          ObserverState.Push(cositBegin,Tool.CurPos.StartPos)
        else if Tool.UpAtomIs('REPEAT') then
          ObserverState.Push(cositRepeat,Tool.CurPos.StartPos)
        else if Tool.UpAtomIs('TRY') then
          ObserverState.Push(cositTry,Tool.CurPos.StartPos)
        else if Tool.UpAtomIs('FINALLY') or Tool.UpAtomIs('EXCEPT') then
        begin
          while ObserverState.StackPtr>0 do
          begin
            Typ:=ObserverState.Pop;
            if Typ=cositTry then
              break;
          end;
          ObserverState.StatementStartPos:=-1;
          if Tool.UpAtomIs('FINALLY') then
            ObserverState.Push(cositFinally,Tool.CurPos.StartPos)
          else
            ObserverState.Push(cositExcept,Tool.CurPos.StartPos);
        end
        else if Tool.UpAtomIs('CASE') then
        begin
          ObserverState.Push(cositCase,Tool.CurPos.StartPos);
          ObserverState.StatementStartPos:=Tool.CurPos.StartPos;
        end
        else if Tool.UpAtomIs('ELSE') then
        begin
          if ObserverState.TopType=cositCase then
          begin
            ObserverState.Pop;
            ObserverState.Push(cositCaseElse,Tool.CurPos.StartPos);
          end;
          ObserverState.StatementStartPos:=-1;
          CheckSubStatement(false);
        end
        else if Tool.UpAtomIs('DO') or Tool.UpAtomIs('THEN') then
          CheckSubStatement(false)
        else if Tool.UpAtomIs('OF') then
          CheckSubStatement(true);
      end;
    end;
    // read next atom
    Last2Atom:=Last1Atom;
    Last1Atom:=CurAtom;
    Tool.ReadNextAtom;
  end;
end;

procedure TWKCodeExplorerView.FindObserverTodos(Tool: TCodeTool);
var
  Src: String;
  p: Integer;
  CommentEndPos: LongInt;
  MagicStartPos: integer;
  TextStartPos: integer;
  TextEndPos: integer;
  l: Integer;
  SrcLen: Integer;
  Data: TViewNodeData;
  ObsTVNode: TTreeNode;
  NodeText: String;
  NodeImageIndCex: LongInt;
  TVNode: TTreeNode;
begin
  Src:=Tool.Src;
  SrcLen:=length(Src);
  p:=1;
  repeat
    p:=FindNextComment(Src,p);
    if p>SrcLen then break;
    CommentEndPos:=FindCommentEnd(Src,p,Tool.Scanner.NestedComments);
    if GetToDoComment(Src,p,CommentEndPos,MagicStartPos,TextStartPos,TextEndPos)
    then begin
      // add todo
      ObsTVNode:=CreateObserverNode(Tool,cefcToDos);
      if fObserverNode.Count>=CodeObserverMaxNodes then begin
        fObserverCatOverflow[cefcToDos]:=true;
        break;
      end else begin
        Data:=TViewNodeData.Create(Tool.Tree.Root,false);
        Data.Desc:=ctnConstant;
        Data.SubDesc:=ctnsNone;
        Data.StartPos:=p;
        Data.EndPos:=MagicStartPos;
        l:=TextEndPos-TextStartPos;
        if l>20 then l:=20;
        NodeText:=TrimCodeSpace(copy(Src,TextStartPos,l));
        NodeImageIndCex:=ImgIDConst;
        TVNode:=CodeTreeview.Items.AddChild(ObsTVNode,NodeText);
        TVNode.Data:=Data;
        TVNode.Text:=NodeText;
        TVNode.ImageIndex:=NodeImageIndCex;
        TVNode.SelectedIndex:=NodeImageIndCex;
      end;
    end;
    p:=CommentEndPos;
  until p>SrcLen;
end;

procedure TWKCodeExplorerView.CreateSurrounding(Tool: TCodeTool);

  function CTNodeIsEnclosing(CTNode: TCodeTreeNode; p: integer): boolean;
  var
    NextCTNode: TCodeTreeNode;
  begin
    Result:=false;
    if (p<CTNode.StartPos) or (p>CTNode.EndPos) then exit;
    if (p=CTNode.EndPos) then begin
      NextCTNode:=CTNode.NextSkipChilds;
      if (NextCTNode<>nil) and (NextCTNode.StartPos<=p) then exit;
    end;
    Result:=true;
  end;

  procedure CreateSubNodes(ParentTVNode: TTreeNode; CTNode: TCodeTreeNode;
    p: integer);
  var
    ChildCTNode: TCodeTreeNode;
    ChildData: TViewNodeData;
    ChildTVNode: TTreeNode;
    AddChilds: Boolean;
    Add: Boolean;
    CurParentTVNode: TTreeNode;
  begin
    ChildCTNode:=CTNode.FirstChild;
    while ChildCTNode<>nil do
    begin
      AddChilds:=false;
      Add:=false;
      if CTNodeIsEnclosing(ChildCTNode,p) then begin
        AddChilds:=true;
        Add:=true;
        if ChildCTNode.Desc in AllClasses then
          Add:=false;
      end else if (CTNode.Desc=ctnProcedure)
      and (ChildCTNode.Desc<>ctnProcedureHead) then begin
        Add:=true
      end;

      CurParentTVNode:=ParentTVNode;
      if Add then
      begin
        ChildData:=TViewNodeData.Create(ChildCTNode,false);
        ChildTVNode:=CodeTreeview.Items.AddChildObject(
                     ParentTVNode,GetCodeNodeDescription(Tool,ChildCTNode),ChildData);
        ChildTVNode.ImageIndex:=GetCodeNodeImage(Tool,ChildCTNode);
        ChildTVNode.SelectedIndex:=ChildTVNode.ImageIndex;
        CurParentTVNode:=ChildTVNode;
      end else
        ChildTVNode:=nil;
      if AddChilds then
      begin
        CreateSubNodes(CurParentTVNode,ChildCTNode,p);
        if ChildTVNode<>nil then
          ChildTVNode.Expanded:=true;
      end;
      ChildCTNode:=ChildCTNode.NextBrother;
    end;
  end;

var
  CodeNode: TCodeTreeNode;
  Data: TViewNodeData;
  TVNode: TTreeNode;
  CurPos: TCodeXYPosition;
  p: integer;
begin
  if fSurroundingNode = nil then
  begin
    fSurroundingNode:=CodeTreeview.Items.Add(nil, lisCESurrounding);
    Data:=TViewNodeData.Create(Tool.Tree.Root,false);
    Data.Desc:=ctnNone;
    Data.StartPos:=Tool.SrcLen;
    fSurroundingNode.Data:=Data;
    fSurroundingNode.ImageIndex:=ImgIDSection;
    fSurroundingNode.SelectedIndex:=ImgIDSection;
  end;

  CurPos.Code:=FLastCode;
  CurPos.X:=FLastCodeXY.X;
  CurPos.Y:=FLastCodeXY.Y;
  fLastCodeTool.CaretToCleanPos(CurPos,p);

  // add all top lvl sections
  CodeNode:=Tool.Tree.Root;
  while CodeNode<>nil do begin
    Data:=TViewNodeData.Create(CodeNode,false);
    TVNode:=CodeTreeview.Items.AddChildObject(
                       fSurroundingNode,GetCodeNodeDescription(Tool,CodeNode),Data);
    TVNode.ImageIndex:=GetCodeNodeImage(Tool,CodeNode);
    TVNode.SelectedIndex:=TVNode.ImageIndex;
    if CTNodeIsEnclosing(CodeNode,p) then
      CreateSubNodes(TVNode,CodeNode,p);
    TVNode.Expanded:=true;

    CodeNode:=CodeNode.NextBrother;
  end;
  fSurroundingNode.Expanded:=true;
end;

procedure TWKCodeExplorerView.DeleteTVNode(TVNode: TTreeNode);
var
  c: TCodeExplorerCategory;
  oc: TCEObserverCategory;
begin
  if TVNode=nil then exit;
  if TVNode.Data<>nil then begin
    if (TObject(TVNode.Data) is TViewNodeData) and (fCodeSortedForStartPos<>nil)
    then
      fCodeSortedForStartPos.Remove(TVNode);
    TObject(TVNode.Data).Free;
    TVNode.Data:=nil;
  end;
  if TVNode.Parent=nil then begin
    if TVNode=fObserverNode then
      fObserverNode:=nil
    else if TVNode=fSurroundingNode then
      fSurroundingNode:=nil
    else begin
      for c:=low(fCategoryNodes) to high(fCategoryNodes) do
        if fCategoryNodes[c]=TVNode then
          fCategoryNodes[c]:=nil;
    end;
  end else if TVNode=fObserverNode then begin
    for oc:=low(fObserverCatNodes) to high(fObserverCatNodes) do
      if fObserverCatNodes[oc]=TVNode then
        fObserverCatNodes[oc]:=nil;
  end;
  TVNode.Delete;
end;

procedure TWKCodeExplorerView.SetCodeFilter(const AValue: string);
begin
  if CodeFilter=AValue then exit;
  CodeFilterEdit.Text:=AValue;
  CodeFilterChanged;
end;

procedure TWKCodeExplorerView.SetCurrentPage(const AValue: TCodeExplorerPage);
begin
  case AValue of
  cepCode:       MainNotebook.ActivePage:=CodePage;
  cepDirectives: MainNotebook.ActivePage:=DirectivesPage;
  end;
end;

procedure TWKCodeExplorerView.SetDirectivesFilter(const AValue: string);
begin
  if DirectivesFilter=AValue then exit;
  DirectivesFilterEdit.Text:=AValue;
  DirectivesFilterChanged;
end;

procedure TWKCodeExplorerView.SetMode(AMode: TCodeExplorerMode);
begin
  if FMode=AMode then exit;
  FMode:=AMode;
  UpdateMode;
end;

procedure TWKCodeExplorerView.UpdateMode;
begin
  if FMode=cemCategory
  then begin
    IDEImages.AssignImage(CodeModeSpeedButton, 'show_category');
    CodeModeSpeedButton.Hint:=lisCEModeShowSourceNodes;
  end
  else begin
    IDEImages.AssignImage(CodeModeSpeedButton, 'show_source');
    CodeModeSpeedButton.Hint:=lisCEModeShowCategories;
  end;
  Refresh(true);
end;

procedure TWKCodeExplorerView.UpdateCaption;
var
  s: String;
begin
  s:=lisMenuViewCodeExplorer;
  if (CodeExplorerOptions.Refresh=cerManual) and (FCodeFilename<>'') then
    s+=' - ' + ExtractFileName(FCodeFilename);
  Caption:=s;
end;

function TWKCodeExplorerView.OnExpandedStateGetNodeText(Node: TTreeNode): string;
var
  p: Integer;
begin
  Result:=Node.Text;
  if Result='' then exit;
  p:=length(Result);
  if Result[p]=')' then begin
    dec(p);
    while (p>1) and (Result[p] in ['+','0'..'9']) do dec(p);
    if (p>1) and (Result[p]='(') then begin
      repeat
        dec(p);
      until (p=0) or (Result[p]<>' ');
      SetLength(Result,p);
    end;
  end;
end;

procedure TWKCodeExplorerView.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  ExecuteIDEShortCut(Self,Key,Shift,nil);
end;

procedure TWKCodeExplorerView.ApplyCodeFilter;
var
  ANode, NextNode: TTreeNode;
  TheFilter: String;
begin
  TheFilter:=GetCodeFilter;
  //DebugLn(['TWKCodeExplorerView.ApplyCodeFilter ====================="',TheFilter,'"']);
  FLastCodeFilter:=TheFilter;
  CodeTreeview.BeginUpdate;
  ANode:=CodeTreeview.Items.GetFirstNode;
  while ANode<>nil do begin
    NextNode:=ANode.GetNextSibling;
    FilterNode(ANode,TheFilter,True);
    ANode:=NextNode;
  end;
  CodeTreeview.EndUpdate;
end;

procedure TWKCodeExplorerView.ApplyDirectivesFilter;
var
  ANode, NextNode: TTreeNode;
  TheFilter: String;
begin
  TheFilter:=GetDirectivesFilter;
  //DebugLn(['TWKCodeExplorerView.ApplyDirectivesFilter ====================="',TheFilter,'"']);
  FLastDirectivesFilter:=TheFilter;
  DirectivesTreeView.BeginUpdate;
  //DirectivesTreeView.Options:=DirectivesTreeView.Options+[tvoAllowMultiselect];
  ANode:=DirectivesTreeView.Items.GetFirstNode;
  while ANode<>nil do begin
    NextNode:=ANode.GetNextSibling;
    FilterNode(ANode,TheFilter,False);
    ANode:=NextNode;
  end;
  DirectivesTreeView.EndUpdate;
end;

procedure TWKCodeExplorerView.BeginUpdate;
begin
  inc(FUpdateCount);
end;

procedure TWKCodeExplorerView.EndUpdate;
var
  CurPage: TCodeExplorerPage;
begin
  if FUpdateCount<=0 then
    LazTracer.RaiseGDBException('TWKCodeExplorerView.EndUpdate');
  dec(FUpdateCount);
  if FUpdateCount=0 then begin
    CurPage:=CurrentPage;
    if (CurPage=cepCode) and (cevCodeRefreshNeeded in FFlags) then
      RefreshCode(true);
    if (CurPage=cepDirectives) and (cevDirectivesRefreshNeeded in FFlags) then
      RefreshDirectives(true);
  end;
end;

procedure TWKCodeExplorerView.CheckOnIdle;
begin
  Include(FFlags,cevCheckOnIdle);
end;

procedure TWKCodeExplorerView.Refresh(OnlyVisible: boolean);
begin
  Exclude(FFlags,cevCheckOnIdle);
  //debugln(['TWKCodeExplorerView.Refresh ']);
  RefreshCode(OnlyVisible);
  RefreshDirectives(OnlyVisible);
end;

procedure TWKCodeExplorerView.RefreshCode(OnlyVisible: boolean);

  procedure AutoExpandNodes;
  var
    TVNode: TTreeNode;
    Data: TViewNodeData;
    ShowInterfaceImplementation: Boolean;
  begin
    ShowInterfaceImplementation:=(Mode <> cemCategory)
      or (not (cecSurrounding in CodeExplorerOptions.Categories));
    if not ShowInterfaceImplementation then exit;
    TVNode:=CodeTreeview.Items.GetFirstNode;
    while TVNode<>nil do begin
      Data:=TViewNodeData(TVNode.Data);
      if Data.Desc in [ctnInterface,ctnImplementation] then begin
        // auto expand interface and implementation nodes
        TVNode.Expanded:=true;
      end;
      TVNode:=TVNode.GetNext;
    end;
  end;

  procedure DeleteDuplicates(ACodeTool: TCodeTool);

    function IsForward(Data: TViewNodeData): boolean;
    begin
      if Data.Desc=ctnProcedure then
      begin
        if (Data.CTNode.Parent<>nil) and (Data.CTNode.Parent.Desc=ctnInterface)
        then
          exit(true);
        if ACodeTool.NodeIsForwardProc(Data.CTNode) then
          exit(true);
      end;
      Result:=false;
    end;

  var
    TVNode: TTreeNode;
    NextTVNode: TTreeNode;
    Data: TViewNodeData;
    NextData: TViewNodeData;
    DeleteNode: Boolean;
    DeleteNextNode: Boolean;
  begin
    TVNode:=CodeTreeview.Items.GetFirstNode;
    while TVNode<>nil do begin
      NextTVNode:=TVNode.GetNext;
      if NextTVNode=nil then break;
      if (TVNode.Parent<>nil) and (NextTVNode.Parent=TVNode.Parent) then
      begin
        DeleteNode:=false;
        DeleteNextNode:=false;
        if (CompareTextIgnoringSpace(TVNode.Text,NextTVNode.Text,false)=0) then
        begin
          Data:=TViewNodeData(TVNode.Data);
          NextData:=TViewNodeData(NextTVNode.Data);
          if IsForward(Data) then
            DeleteNode:=true;
          if IsForward(NextData) then
            DeleteNextNode:=true;
        end;
        if DeleteNextNode then begin
          DeleteTVNode(NextTVNode);
          NextTVNode:=TVNode;
        end else if DeleteNode then begin
          NextTVNode:=TVNode.GetNextSkipChildren;
          DeleteTVNode(TVNode);
        end;
      end;
      TVNode:=NextTVNode;
    end;
  end;

var
  OldExpanded: TTreeNodeExpandedState;
  ACodeTool: TCodeTool;
  SrcEdit: TSourceEditorInterface;
  Filename: String;
  Code: TCodeBuffer;
  NewXY: TPoint;
  OnlyXYChanged: Boolean;
  CurFollowNode: Boolean;
  TVNode: TTreeNode;
  TheFilter: String;
begin
  if (FUpdateCount>0)
  or (OnlyVisible and ((CurrentPage<>cepCode) or (not IsVisible))) then begin
    Include(FFlags,cevCodeRefreshNeeded);
    exit;
  end;
  Exclude(FFlags,cevCodeRefreshNeeded);
  fLastCodeTool:=nil;
  OldExpanded:=nil;
  try
    Include(FFlags,cevRefreshing);
    
    // get the current editor
    if not LazarusIDE.BeginCodeTools then exit;
    SrcEdit:=SourceEditorManagerIntf.ActiveEditor;
    if SrcEdit=nil then exit;
    // get the codetool for the current editor
    Filename:=SrcEdit.FileName;
    Code:=CodeToolBoss.FindFile(Filename);
    if Code=nil then exit;
    ACodeTool:=nil;
    // ToDo: check if something changed (file stamp, codebuffer stamp, defines stamp)
    CodeToolBoss.Explore(Code,ACodeTool,false);
    if ACodeTool=nil then exit;

    fLastCodeTool:=ACodeTool;
    FLastCode:=Code;

    // check for changes in the codetool
    TheFilter:=GetCodeFilter;
    OnlyXYChanged:=false;
    if (ACodeTool=nil) then begin
      if (FCodeFilename='') then begin
        // still no tool
        exit;
      end;
      //debugln(['TWKCodeExplorerView.RefreshCode no tool']);
    end else begin
      if CompareText(FLastCodeFilter,TheFilter)<>0 then begin
        // debugln(['TWKCodeExplorerView.RefreshCode filter changed']);
      end else if not FLastCodeValid then begin
        //debugln(['TWKCodeExplorerView.RefreshCode last code not valid'])
      end else if ACodeTool.MainFilename<>FCodeFilename then begin
        //debugln(['TWKCodeExplorerView.RefreshCode File changed ',ACodeTool.MainFilename,' ',FCodeFilename])
      end else if (ACodeTool.Scanner=nil) then begin
        //debugln(['TWKCodeExplorerView.RefreshCode Scanner=nil'])
      end else if (ACodeTool.Scanner.ChangeStep<>FLastCodeChangeStep) then begin
        //debugln(['TWKCodeExplorerView.RefreshCode Scanner changed ',ACodeTool.Scanner.ChangeStep,' ',FLastCodeChangeStep])
      end else if (Mode<>FLastMode) then begin
        //debugln(['TWKCodeExplorerView.RefreshCode Mode changed ',ord(Mode),' ',ord(FLastMode)])
      end else if (fLastCodeOptionsChangeStep<>CodeExplorerOptions.ChangeStep) then begin
        //debugln(['TWKCodeExplorerView.RefreshCode Options changed ',fLastCodeOptionsChangeStep,' ',CodeExplorerOptions.ChangeStep])
      end else begin
        // still the same source and options
        OnlyXYChanged:=true;
        if not CodeExplorerOptions.FollowCursor then
          exit;
        NewXY:=SrcEdit.CursorTextXY;
        //debugln(['TWKCodeExplorerView.RefreshCode ',dbgs(NewXY),' ',dbgs(FLastCodeXY)]);
        if ComparePoints(NewXY,FLastCodeXY)=0 then begin
          // still the same cursor position
          exit;
        end;
        FLastCodeXY:=NewXY;
      end;
    end;

    if OnlyXYChanged then begin
      SelectCodePosition(Code,FLastCodeXY.X,FLastCodeXY.Y);
    end else begin

      FLastCodeValid:=true;
      FLastMode:=Mode;
      fLastCodeOptionsChangeStep:=CodeExplorerOptions.ChangeStep;
      FLastCodeXY:=SrcEdit.CursorTextXY;
      FLastCodeFilter:=TheFilter;
      // remember the codetools ChangeStep
      if ACodeTool<>nil then begin
        FCodeFilename:=ACodeTool.MainFilename;
        if ACodeTool.Scanner<>nil then
          FLastCodeChangeStep:=ACodeTool.Scanner.ChangeStep;
      end else
        FCodeFilename:='';

      if fCodeSortedForStartPos<>nil then
        fCodeSortedForStartPos.Clear;
      fNodesWithPath.Clear;

      //DebugLn(['TWKCodeExplorerView.RefreshCode ',FCodeFilename]);

      CurFollowNode:=CodeExplorerOptions.FollowCursor and (not Active);

      // start updating the CodeTreeView
      CodeTreeview.BeginUpdate;
      if not CurFollowNode then
        OldExpanded:=TTreeNodeExpandedState.Create(CodeTreeView,@OnExpandedStateGetNodeText);

      ClearCodeTreeView;

      if (ACodeTool<>nil) and (ACodeTool.Tree<>nil) and (ACodeTool.Tree.Root<>nil)
      then begin
        CreateIdentifierNodes(ACodeTool,ACodeTool.Tree.Root,nil);
        if (Mode = cemCategory) then
        begin
          if (cecCodeObserver in CodeExplorerOptions.Categories) then
            CreateObservations(ACodeTool);
          if (cecSurrounding in CodeExplorerOptions.Categories) then
            CreateSurrounding(ACodeTool);
        end;
      end;

      // sort nodes
      fSortCodeTool:=ACodeTool;
      TVNode:=CodeTreeview.Items.GetFirstNode;
      while TVNode<>nil do begin
        if (TVNode.GetFirstChild<>nil)
        and (TObject(TVNode.Data) is TViewNodeData)
        and TViewNodeData(TVNode.Data).SortChildren then begin
          TVNode.CustomSort(@CompareCodeNodes);
        end;
        TVNode:=TVNode.GetNext;
      end;

      DeleteDuplicates(ACodeTool);

      // restore old expanded state
      if not CurFollowNode then
        AutoExpandNodes;

      BuildCodeSortedForStartPos;
      // clear references to the TCodeTreeNode to avoid dangling pointers
      ClearCTNodes(CodeTreeview);

      ApplyCodeFilter;

      if OldExpanded<>nil then
        OldExpanded.Apply(CodeTreeView,false);

      if CurFollowNode then
        SelectCodePosition(Code,FLastCodeXY.X,FLastCodeXY.Y);

      CodeTreeview.EndUpdate;
    end;
    UpdateCaption;
    if HostDockSite <> nil then
      HostDockSite.UpdateDockCaption();
  finally
    Exclude(FFlags,cevRefreshing);
    OldExpanded.Free;
  end;
end;

procedure TWKCodeExplorerView.RefreshDirectives(OnlyVisible: boolean);
var
  ADirectivesTool: TDirectivesTool;
  OldExpanded: TTreeNodeExpandedState;
begin
  if (FUpdateCount>0)
  or (OnlyVisible and ((CurrentPage<>cepDirectives) or (not IsVisible))) then
  begin
    Include(FFlags,cevDirectivesRefreshNeeded);
    exit;
  end;
  Exclude(FFlags,cevDirectivesRefreshNeeded);

  try
    Include(FFlags,cevRefreshing);

    // get the directivestool with the updated tree
    ADirectivesTool:=nil;
    if Assigned(OnGetDirectivesTree) then
      OnGetDirectivesTree(Self,ADirectivesTool);

    // check for changes in the codetools
    if (ADirectivesTool=nil) then begin
      if (FDirectivesFilename='') then begin
        // still no tool
        exit;
      end;
    end else begin
      if (ADirectivesTool.Code.Filename=FDirectivesFilename)
      and (ADirectivesTool.ChangeStep=FLastDirectivesChangeStep) then begin
        // still the same source
        exit;
      end;
    end;

    // remember the codetools ChangeStep
    if ADirectivesTool<>nil then begin
      FDirectivesFilename:=ADirectivesTool.Code.Filename;
      FLastDirectivesChangeStep:=ADirectivesTool.ChangeStep;
    end else
      FDirectivesFilename:='';
      
    //DebugLn(['TWKCodeExplorerView.RefreshDirectives ',FDirectivesFilename]);

    // start updating the DirectivesTreeView
    DirectivesTreeView.BeginUpdate;
    OldExpanded:=TTreeNodeExpandedState.Create(DirectivesTreeView);

    ClearDirectivesTreeView;
    if (ADirectivesTool<>nil) and (ADirectivesTool.Tree<>nil)
    and (ADirectivesTool.Tree.Root<>nil) then
    begin
      CreateDirectiveNodes(ADirectivesTool,ADirectivesTool.Tree.Root,nil);
    end;

    // restore old expanded state
    OldExpanded.Apply(DirectivesTreeView);
    OldExpanded.Free;
    ClearCTNodes(DirectivesTreeView);

    ApplyDirectivesFilter;

    DirectivesTreeView.EndUpdate;

  finally
    Exclude(FFlags,cevRefreshing);
  end;
end;

procedure TWKCodeExplorerView.ClearCTNodes(ATreeView: TTreeView);
var
  TVNode: TTreeNode;
  NodeData: TViewNodeData;
begin
  TVNode:=ATreeView.Items.GetFirstNode;
  while TVNode<>nil do begin
    NodeData:=TViewNodeData(TVNode.Data);
    NodeData.CTNode:=nil;
    TVNode:=TVNode.GetNext;
  end;
end;

function TWKCodeExplorerView.JumpToSelection(ToImplementation: boolean): boolean;
var
  CurItem: TTreeNode;
  CurNode: TViewNodeData;
  Caret: TCodeXYPosition;
  NewTopLine: integer;
  CodeBuffer: TCodeBuffer;
  ACodeTool: TCodeTool;
  CurTreeView: TCustomTreeView;
  SrcEdit: TSourceEditorInterface;
  NewNode: TCodeTreeNode;
  p: LongInt;
begin
  Result:=false;
  CurTreeView:=GetCurrentTreeView;
  if CurTreeView=nil then exit;
  if tvoAllowMultiselect in CurTreeView.Options then
    CurItem:=CurTreeView.GetFirstMultiSelected
  else
    CurItem:=CurTreeView.Selected;
  if CurItem=nil then exit;
  CurNode:=TViewNodeData(CurItem.Data);
  if ToImplementation then begin
    CurNode:=CurNode.ImplementationNode;
    if CurNode=nil then exit;
  end;
  if CurNode.StartPos<1 then exit;
  CodeBuffer:=nil;
  case CurrentPage of
  cepCode:
    begin
      CodeBuffer:=CodeToolBoss.LoadFile(CodeFilename,false,false);
      if CodeBuffer=nil then exit;
      ACodeTool:=nil;
      CodeToolBoss.Explore(CodeBuffer,ACodeTool,false);
      if ACodeTool=nil then exit;
      p:=CurNode.StartPos;
      NewNode:=ACodeTool.FindDeepestNodeAtPos(p,false);
      if NewNode<>nil then begin
        if (NewNode.Desc=ctnProcedure)
        and (NewNode.FirstChild<>nil)
        and (NewNode.FirstChild.Desc=ctnProcedureHead)
        and (NewNode.FirstChild.StartPos>p) then
          p:=NewNode.FirstChild.StartPos;
        if NewNode.Desc=ctnProperty then begin
          if ACodeTool.MoveCursorToPropName(NewNode) then
            p:=ACodeTool.CurPos.StartPos;
        end;
      end;
      if not ACodeTool.CleanPosToCaretAndTopLine(p,Caret,NewTopLine)
      then exit;
    end;
  cepDirectives:
    begin
      CodeBuffer:=CodeToolBoss.LoadFile(DirectivesFilename,false,false);
      if CodeBuffer=nil then exit;
      CodeBuffer.AbsoluteToLineCol(CurNode.StartPos,Caret.Y,Caret.X);
      if Caret.Y<1 then exit;
      Caret.Code:=CodeBuffer;
      NewTopLine:=Caret.Y-(CodeToolBoss.VisibleEditorLines div 2);
      if NewTopLine<1 then NewTopLine:=1;
    end;
  else
    exit;
  end;
  if Assigned(OnJumpToCode) then
    OnJumpToCode(Self,Caret.Code.Filename,Point(Caret.X,Caret.Y),NewTopLine);
  SrcEdit:=SourceEditorManagerIntf.ActiveEditor;
  //DebugLn(['TWKCodeExplorerView.JumpToSelection  ',SrcEdit.FileName,' ',dbgs(SrcEdit.CursorTextXY),' X=',Caret.X,' Y=',Caret.Y]);
  // check if jump was successful
  if (SrcEdit.CodeToolsBuffer<>CodeBuffer)
  or (SrcEdit.CursorTextXY.X<>Caret.X) or (SrcEdit.CursorTextXY.Y<>Caret.Y) then
    exit;
  Result:=true;
end;

function TWKCodeExplorerView.SelectSourceEditorNode: boolean;
var
  SrcEdit: TSourceEditorInterface;
  xy: TPoint;
begin
  Result:=false;
  SrcEdit:=SourceEditorManagerIntf.ActiveEditor;
  if SrcEdit=nil then exit;
  xy:=SrcEdit.CursorTextXY;
  Result:=SelectCodePosition(TCodeBuffer(SrcEdit.CodeToolsBuffer),xy.x,xy.y);
end;

function TWKCodeExplorerView.SelectCodePosition(CodeBuf: TCodeBuffer; X,
  Y: integer): boolean;
var
  CodePos: TCodeXYPosition;
  CleanPos: integer;
  TVNode: TTreeNode;
begin
  Result:=false;
  if CurrentPage=cepCode then begin
    if FLastCodeValid and (fLastCodeTool<>nil) then begin
      CodePos:=CodeXYPosition(X,Y,CodeBuf);
      CodeBuf.LineColToPosition(Y,X,CleanPos);
      //debugln(['TWKCodeExplorerView.SelectCodePosition Code ',ExtractFileName(CodeBuf.Filename),' y=',y,' x=',x,' CleanPos=',CleanPos,' ',dbgstr(copy(CodeBuf.Source,CleanPos-20,20)),'|',dbgstr(copy(CodeBuf.Source,CleanPos,20))]);
      if fLastCodeTool.CaretToCleanPos(CodePos,CleanPos)<>0 then exit;
      //debugln(['TWKCodeExplorerView.SelectCodePosition CleanSrc ',ExtractFileName(CodeBuf.Filename),' y=',y,' x=',x,' Tool=',ExtractFileName(fLastCodeTool.MainFilename),' ',dbgstr(copy(fLastCodeTool.Src,CleanPos-20,20)),'|',dbgstr(copy(fLastCodeTool.Src,CleanPos,20))]);
      TVNode:=FindCodeTVNodeAtCleanPos(CleanPos);
      if TVNode=nil then exit;
      //debugln(['TWKCodeExplorerView.SelectCodePosition ',TVNode.Text]);
      CodeTreeview.BeginUpdate;
      CodeTreeview.Options:=CodeTreeview.Options-[tvoAllowMultiselect];
      if not TVNode.IsVisible then begin
        // collapse all other and expand only this
        CodeTreeview.FullCollapse;
        CodeTreeview.Selected:=TVNode;
        //debugln(['TWKCodeExplorerView.SelectCodePosition ',TVNode.Text]);
      end else begin
        CodeTreeview.Selected:=TVNode;
        //debugln(['TWKCodeExplorerView.SelectCodePosition ',TVNode.Text]);
      end;
      //debugln(['TWKCodeExplorerView.SelectCodePosition TVNode=',TVNode.Text,' Selected=',CodeTreeview.Selected=TVNode]);
      CodeTreeview.EndUpdate;
      Result:=true;
    end;
  end;
end;

function TWKCodeExplorerView.FindCodeTVNodeAtCleanPos(CleanPos: integer): TTreeNode;
// find TTreeNode in CodeTreeView containing the codetools clean position
// if there are several nodes, the one with the shortest range (EndPos-StartPos)
// is returned.
var
  Best: TTreeNode;
  BestStartPos, BestEndPos: integer;

  procedure Check(TVNode: TTreeNode; NodeData: TViewNodeData);
  begin
    if NodeData=nil then exit;
    if (NodeData.StartPos>CleanPos) or (NodeData.EndPos<CleanPos) then exit;
    //debugln(['FindCodeTVNodeAtCleanPos.Check TVNode="',TVNode.Text,'" NodeData="',dbgstr(copy(fLastCodeTool.Src,NodeData.StartPos,40)),'"']);
    if (Best<>nil) then begin
      if (BestEndPos=CleanPos) and (NodeData.EndPos>CleanPos) then begin
        // for example  a,|b  then b is better
      end else if BestEndPos-BestStartPos > NodeData.EndPos-NodeData.StartPos then begin
        // smaller range is better
      end else
        exit;
    end;
    Best:=TVNode;
    BestStartPos:=NodeData.StartPos;
    BestEndPos:=NodeData.EndPos;
  end;

var
  AVLNode: TAvlTreeNode;
  Node: TTreeNode;
  NodeData: TViewNodeData;
begin
  Result:=nil;
  if (fLastCodeTool=nil) or (not FLastCodeValid) or (CodeTreeview=nil)
  or (fCodeSortedForStartPos=nil) then exit;

  // find nearest node in tree
  Best:=nil;
  BestStartPos:=0;
  BestEndPos:=0;
  AVLNode:=fCodeSortedForStartPos.FindLowest;
  while AVLNode<>nil do begin
    Node:=TTreeNode(AVLNode.Data);
    NodeData:=TViewNodeData(Node.Data);
    //debugln(['TWKCodeExplorerView.FindCodeTVNodeAtCleanPos Node ',NodeData.StartPos,'-',NodeData.EndPos,' ',Node.Text,' ',CleanPos]);
    Check(Node,NodeData);
    Check(Node,NodeData.ImplementationNode);
    AVLNode:=fCodeSortedForStartPos.FindSuccessor(AVLNode);
  end;
  Result:=Best;
end;

procedure TWKCodeExplorerView.BuildCodeSortedForStartPos;
var
  TVNode: TTreeNode;
  NodeData: TViewNodeData;
begin
  if fCodeSortedForStartPos<>nil then
    fCodeSortedForStartPos.Clear;
  if (CodeTreeview=nil) then exit;
  TVNode:=CodeTreeview.Items.GetFirstNode;
  while TVNode<>nil do begin
    if TVNode.Parent=nil then begin
      if (TVNode=fObserverNode) or (TVNode=fSurroundingNode) then break;
    end;
    NodeData:=TViewNodeData(TVNode.Data);
    if (NodeData<>nil) and (NodeData.StartPos>0)
    and (NodeData.EndPos>=NodeData.StartPos) then begin
      if fCodeSortedForStartPos=nil then
        fCodeSortedForStartPos:=TAvlTree.Create(TListSortCompare(@CompareViewNodeDataStartPos));
      fCodeSortedForStartPos.Add(TVNode);
    end;
    TVNode:=TVNode.GetNext;
  end;
end;

procedure TWKCodeExplorerView.CurrentCodeBufferChanged;
begin
  if CodeExplorerOptions.Refresh=cerSwitchEditorPage then
    CheckOnIdle;
end;

procedure TWKCodeExplorerView.CodeFilterChanged;
var
  TheFilter: String;
begin
  TheFilter:=GetCodeFilter;
  CodeFilterEdit.Button.Enabled:=TheFilter<>'';
  if FLastCodeFilter=TheFilter then exit;
  if (FUpdateCount>0) or (CurrentPage<>cepCode) then begin
    Include(FFlags,cevCodeRefreshNeeded);
    exit;
  end;
  if (FLastCodeFilter='') or (PosI(FLastCodeFilter,TheFilter)>0)
  then begin
    // longer filter => just delete nodes
    ApplyCodeFilter;
  end else begin
    CheckOnIdle;
  end;
end;

procedure TWKCodeExplorerView.DirectivesFilterChanged;
var
  TheFilter: String;
begin
  TheFilter:=DirectivesFilterEdit.Text;
  DirectivesFilterEdit.Button.Enabled:=TheFilter<>'';
  if FLastDirectivesFilter=TheFilter then exit;
  if (FUpdateCount>0) or (CurrentPage<>cepDirectives) then begin
    Include(FFlags,cevDirectivesRefreshNeeded);
    exit;
  end;
  FLastDirectivesChangeStep:=CTInvalidChangeStamp;
  RefreshDirectives(False);
end;

function TWKCodeExplorerView.FilterNode(ANode: TTreeNode;
  const TheFilter: string; KeepTopLevel: Boolean): boolean;
// Return True if ANode passes the filter. Delete nodes which do not pass.
// Filter recursively all subnodes.
var
  ChildNode, NextNode: TTreeNode;
  ChildPass, ChildrenPassed: Boolean;
begin
  if ANode=nil then exit(false);
  ChildNode:=ANode.GetFirstChild;
  ChildrenPassed:=false;
  while ChildNode<>nil do begin
    NextNode:=ChildNode.GetNextSibling;
    ChildPass:=FilterNode(ChildNode,TheFilter,KeepTopLevel);
    ChildrenPassed:=ChildrenPassed or ChildPass;
    ChildNode:=NextNode;
  end;
  Result:=((ANode.Parent=nil) and KeepTopLevel)
      or ChildrenPassed or FilterFits(ANode.Text,TheFilter);
  //DebugLn(['TWKCodeExplorerView.FilterNode "',ANode.Text,'" Parent=',ANode.Parent,
  //  ' Child=',ANode.GetFirstChild,' Filter=',FilterFits(ANode.Text,TheFilter),' Result=',Result]);
  if Result then begin
    if ChildrenPassed and (TheFilter<>'') then
      ANode.Expanded:=True;
  end
  else
    DeleteTVNode(ANode);
end;

function TWKCodeExplorerView.FilterFits(const NodeText, TheFilter: string): boolean;
var
  Src: PChar;
  PFilter: PChar;
  c: Char;
  i: Integer;
begin
  Result:=false;
  if TheFilter='' then
    Result:=true
  else if NodeText<>'' then begin
    Src:=PChar(NodeText);
    PFilter:=PChar(TheFilter);
    repeat
      c:=Src^;
      if c<>#0 then begin
        if UpChars[Src^]=UpChars[PFilter^] then begin
          i:=1;
          while (UpChars[Src[i]]=UpChars[PFilter[i]]) and (PFilter[i]<>#0) do
            inc(i);
          if PFilter[i]=#0 then begin
            //DebugLn(['TWKCodeExplorerView.FilterFits Fits "',NodeText,'" "',TheFilter,'"']);
            exit(true);
          end;
        end;
      end else
        exit(false);
      inc(Src);
    until false;
  end;
end;

function TWKCodeExplorerView.GetCurrentTreeView: TCustomTreeView;
begin
  case CurrentPage of
  cepCode: Result:=CodeTreeview;
  cepDirectives: Result:=DirectivesTreeView;
  else  Result:=nil;
  end;
end;

function TWKCodeExplorerView.GetCTNodePath(ACodeTool: TCodeTool;
  CodeNode: TCodeTreeNode): string;
var
  CurName: String;
begin
  Result:='';
  try
    while CodeNode<>nil do begin
      CurName:='';
      case CodeNode.Desc of

      ctnTypeDefinition,
      ctnVarDefinition,
      ctnConstDefinition,
      ctnEnumIdentifier:
        CurName:=ACodeTool.ExtractIdentifier(CodeNode.StartPos);

      ctnUseUnit:
        CurName:=ACodeTool.ExtractDottedIdentifier(CodeNode.StartPos);

      ctnGenericType:
        CurName:=ACodeTool.ExtractDefinitionName(CodeNode);

      ctnProcedure:
        CurName:=ACodeTool.ExtractProcName(CodeNode,[]);

      ctnProperty:
        CurName:=ACodeTool.ExtractPropName(CodeNode,false); // property keyword is not needed because there are icons

      end;
      if CurName<>'' then begin
        if Result<>'' then Result:='.'+Result;
        Result:=CurName+Result;
      end;
      CodeNode:=CodeNode.Parent;
    end;
  except
    on E: ECodeToolError do
      Result:=''; // ignore syntax errors
  end;
end;

procedure TWKCodeExplorerView.CreateNodePath(ACodeTool: TCodeTool;
  aNodeData: TObject);
var
  NodeData: TViewNodeData absolute aNodeData;
  AVLNode: TAvlTreeNode;
begin
  if NodeData.CTNode.Desc=ctnProcedure then
    NodeData.Path:=GetCTNodePath(ACodeTool,NodeData.CTNode);
  if NodeData.Path='' then exit;
  AVLNode:=fNodesWithPath.FindKey(NodeData,@CompareViewNodePaths);
  if AVLNode=nil then begin
    // unique path
    fNodesWithPath.Add(NodeData);
    exit;
  end;
  // there is already a node with this path
  // => add params to distinguish overloads
  NodeData.CreateParams(ACodeTool);
  TViewNodeData(AVLNode.Data).CreateParams(ACodeTool);
  fNodesWithPath.Add(NodeData);
end;

procedure TWKCodeExplorerView.AddImplementationNode(ACodeTool: TCodeTool;
  CodeNode: TCodeTreeNode);
var
  NodeData: TViewNodeData;
  AVLNode: TAvlTreeNode;
  DeclData: TViewNodeData;
begin
  if (CodeNode.Desc=ctnProcedure)
  and ((ctnsForwardDeclaration and CodeNode.SubDesc)=0) then begin
    NodeData:=TViewNodeData.Create(CodeNode);
    try
      NodeData.Path:=GetCTNodePath(ACodeTool,NodeData.CTNode);
      if NodeData.Path='' then exit;
      //debugln(['TWKCodeExplorerView.AddImplementationNode Proc=',NodeData.Path]);
      AVLNode:=fNodesWithPath.FindKey(NodeData,@CompareViewNodePaths);
      if (AVLNode=nil) or (TViewNodeData(AVLNode.Data).ImplementationNode<>nil)
      then begin
        // there is no declaration, or there is already an implementation
        // => ignore
        exit;
      end;
      DeclData:=TViewNodeData(AVLNode.Data);
      if (DeclData.Params<>'') then begin
        // there are several nodes with this Path
        NodeData.CreateParams(ACodeTool);
        AVLNode:=fNodesWithPath.Find(NodeData);
        if (AVLNode=nil) or (TViewNodeData(AVLNode.Data).ImplementationNode<>nil)
        then begin
          // there is no declaration, or there is already an implementation
          // => ignore
          exit;
        end;
        DeclData:=TViewNodeData(AVLNode.Data);
      end;
      // implementation found
      //debugln(['TWKCodeExplorerView.AddImplementationNode implementation found: ',NodeData.Path,'(',NodeData.Params,')']);
      NodeData.Desc:=CodeNode.Desc;
      NodeData.SubDesc:=CodeNode.SubDesc;
      NodeData.StartPos:=CodeNode.StartPos;
      NodeData.EndPos:=CodeNode.EndPos;
      DeclData.ImplementationNode:=NodeData;
      NodeData:=nil;
    finally
      NodeData.Free;
    end;
  end;
end;

function TWKCodeExplorerView.CompareCodeNodes(Node1, Node2: TTreeNode): integer;
const
  SortDesc = AllIdentifierDefinitions+[ctnProcedure,ctnProperty];
  
  function DescToLvl(Desc: TCodeTreeNodeDesc): integer;
  begin
    case Desc of
    ctnTypeSection,
    ctnTypeDefinition,ctnGenericType:
      Result:=1;
    ctnConstSection,ctnConstDefinition:
      Result:=2;
    ctnVarSection,ctnClassClassVar,ctnResStrSection,ctnLabelSection,
    ctnVarDefinition:
      Result:=3;
    ctnInterface,ctnImplementation,ctnProgram,ctnPackage,ctnLibrary,
    ctnProcedure:
      Result:=4;
    ctnProperty:
      Result:=5;
    ctnUsesSection:
      Result:=6;

    // class sections
    ctnClassGUID,
    ctnClassPrivate,
    ctnClassProtected,
    ctnClassPublic,
    ctnClassPublished   : Result:=Desc-ctnClassGUID;
    
    else Result:=10000;
    end;
  end;
  
var
  Data1: TViewNodeData;
  Data2: TViewNodeData;
begin
  Data1:=TViewNodeData(Node1.Data);
  Data2:=TViewNodeData(Node2.Data);
  if (Mode=cemCategory) then begin
    if Data1.Desc<>Data2.Desc then begin
      Result:=DescToLvl(Data1.Desc)-DescToLvl(Data2.Desc);
      if Result<>0 then exit;
    end;
    if (Data1.Desc in SortDesc)
    and (Data2.Desc in SortDesc) then begin
      Result:=SysUtils.CompareText(Node1.Text,Node2.Text);
      if Result<>0 then exit;
    end;
    if (Data1.Desc=ctnConstant) and (Data2.Desc=ctnConstant)
    and (fSortCodeTool<>nil) then begin
      //if GetAtomLength(@fSortCodeTool.Src[Data1.StartPos])>50 then
      //  DebugLn(['TWKCodeExplorerView.CompareCodeNodes ',GetAtomString(@fSortCodeTool.Src[Data1.StartPos],fSortCodeTool.Scanner.NestedComments),' ',round(Now*8640000) mod 10000]);
      //Result:=-CompareAtom(@fSortCodeTool.Src[Data1.StartPos],
      //                     @fSortCodeTool.Src[Data2.StartPos]);
      //if Result<>0 then exit;
    end;
  end;
  if Data1.StartPos<Data2.StartPos then
    Result:=-1
  else if Data1.StartPos>Data2.StartPos then
    Result:=1
  else
    Result:=0;
end;

{ TCodeObserverStatementState }

function TCodeObserverStatementState.GetStatementStartPos: integer;
begin
  if StackPtr=0 then
    Result:=TopLvlStatementStartPos
  else
    Result:=Stack[StackPtr-1].StatementStartPos;
end;

procedure TCodeObserverStatementState.SetStatementStartPos(const AValue: integer);
begin
  if StackPtr=0 then
    TopLvlStatementStartPos:=AValue
  else
    Stack[StackPtr-1].StatementStartPos:=AValue;
end;

destructor TCodeObserverStatementState.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TCodeObserverStatementState.Clear;
begin
  ReAllocMem(Stack,0);
  StackCapacity:=0;
  StackPtr:=0;
end;

procedure TCodeObserverStatementState.Reset;
begin
  PopAll;
  TopLvlStatementStartPos:=0;
  IgnoreConstLevel:=-1;
end;

procedure TCodeObserverStatementState.Push(Typ: TCodeObsStackItemType;
  StartPos: integer);
begin
  if StackPtr=StackCapacity then
  begin
    StackCapacity:=StackCapacity*2+10;
    ReAllocMem(Stack,SizeOf(TCodeObsStackItem)*StackCapacity);
  end;
  Stack[StackPtr].Typ:=Typ;
  Stack[StackPtr].StartPos:=StartPos;
  Stack[StackPtr].StatementStartPos:=0;
  inc(StackPtr);
end;

function TCodeObserverStatementState.Pop: TCodeObsStackItemType;
begin
  if StackPtr=0 then
    LazTracer.RaiseGDBException('inconsistency');
  dec(StackPtr);
  Result:=Stack[StackPtr].Typ;
  if IgnoreConstLevel>StackPtr then
    IgnoreConstLevel:=-1;
end;

procedure TCodeObserverStatementState.PopAll;
begin
  StackPtr:=0;
end;

function TCodeObserverStatementState.TopType: TCodeObsStackItemType;
begin
  if StackPtr>0 then
    Result:=Stack[StackPtr-1].Typ
  else
    Result:=cositNone;
end;

procedure CreateWKCodeExplorer(Sender: TObject; aFormName: string;
  var AForm: TCustomForm; DoDisableAutoSizing: boolean);
begin
  if IDEWindowCreators <> nil then
    IDEWindowCreators.CreateForm(AForm, TWKCodeExplorerView,
      DoDisableAutoSizing, Application);
  if (AForm <> nil) and (AForm is TWKCodeExplorerView) then
  begin
    WKCodeExplorerForm := TWKCodeExplorerView(AForm);
    WKCodeExplorerForm.OnJumpToCode := @WKCodeExplorerForm.JumpToCode;
  end;
end;

procedure ShowWKCodeExplorer(Sender: TObject);
begin
  if IDEWindowCreators = nil then
    exit;
  if WKCodeExplorerForm = nil then
    IDEWindowCreators.CreateForm(WKCodeExplorerForm, TWKCodeExplorerView,
      True, Application);
  if WKCodeExplorerForm <> nil then
  begin
    WKCodeExplorerForm.OnJumpToCode := @WKCodeExplorerForm.JumpToCode;
    IDEWindowCreators.ShowForm(WKCodeExplorerForm, True);
  end;
end;

procedure TWKCodeExplorerView.JumpToCode(Sender: TObject; const Filename: string;
  const Caret: TPoint; TopLine: integer);
begin
  if LazarusIDE <> nil then
    LazarusIDE.DoOpenFileAndJumpToPos(Filename, Caret, TopLine, -1, -1,
      [ofOnlyIfExists, ofRegularFile]);
end;

procedure Register;
begin
  RegisterStandardWKCodeExplorerMenuItems;
  if IDEWindowCreators <> nil then
    IDEWindowCreators.Add('WKCodeExplorer', @CreateWKCodeExplorer, nil,
      '72%', '120', '+170', '-200',
      'SourceNotebook', alRight);
  if itmViewMainWindows <> nil then
    RegisterIDEMenuCommand(itmViewMainWindows, 'WKViewCodeExplorer',
      'WK Code Explorer', nil, @ShowWKCodeExplorer);
end;

initialization
  if CodeExplorerOptions = nil then
    CodeExplorerOptions := TCodeExplorerOptions.Create;

finalization
  FreeAndNil(WKCodeExplorerForm);
  FreeAndNil(CodeExplorerOptions);

end.
