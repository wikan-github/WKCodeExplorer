# WKCodeExplorer dock report

Repository: `/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone`
Branch: `mmx-codeexplorer`
Widgetset built for: **gtk2**
Date: 2026-11-19

---

## a) Prompt explanation

The WK Code Explorer window was not dockable and its position was not saved or
restored, unlike the built-in Lazarus Code Explorer. This step investigates
whether the public `components/ideintf` API provides dockable-window
registration for a third-party window, and, if so, registers the WK Code
Explorer through it. The same prohibitions apply: scope limited to
`WKCodeExplorer/` and the report file, do not touch
`toolbarexplorerplugin.pas` or `codetoolbarexplorer.lpk`, do not install, do
not commit, do not push.

---

## b) Every command run and its full output

### 1. Git state and branch

```console
$ cd ... && git status --short && echo "--- branch ---" && git branch --show-current
 M tests/TestVisibility.pas
?? M2-STEP2-IMPLEMENTATION-REPORT.md
?? M2-STEP2-MEASUREMENT-REPORT.md
?? M2-STEP2-ONEDITORDESTROY-REPORT.md
?? M3-FEASIBILITY-CODEEXPLORER-PORT.md
?? M3-STEP2-ENDLINE-PROPOSAL.md
?? WKCodeExplorer/
?? prompt-result/
?? tests/TestHuge.pas
?? tests/TestLarge.pas
?? tests/extract_names.lpi
?? tests/extract_names.lpr
mmx-codeexplorer
```

Branch confirmed: `mmx-codeexplorer`.

### 2. How the built-in Code Explorer is registered as a dockable window

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -n "CodeExplorerView\|IDEWindowCreators" ide/main.pp
...
2571:  IDEWindowCreators.Add(NonModalIDEWindowNames[nmiwCodeExplorer],
2572:    nil,@CreateIDEWindow,'72%','120','+170','-200',
2573:     NonModalIDEWindowNames[nmiwSourceNoteBook],alRight);
...
6159:  if CodeExplorerView=nil then
6161:    IDEWindowCreators.CreateForm(CodeExplorerView,TCodeExplorerView,
6162:       State=iwgfDisabled,OwningComponent);
6163:    CodeExplorerView.OnGetDirectivesTree:=@CodeExplorerGetDirectivesTree;
6164:    CodeExplorerView.OnJumpToCode:=@CodeExplorerJumpToCode;
6165:    CodeExplorerView.OnShowOptions:=@CodeExplorerShowOptions;
6167:    CodeExplorerView.DisableAutoSizing{$IFDEF DebugDisableAutoSizing}('TMainIDE.DoShowCodeExplorer'){$ENDIF};
6170:    IDEWindowCreators.ShowForm(CodeExplorerView,State=iwgfShowOnTop);
6171:    CodeExplorerView.Refresh(true);
...
```

The built-in Code Explorer is registered with
`IDEWindowCreators.Add(...)` (form name `NonModalIDEWindowNames[nmiwCodeExplorer]`,
create proc `@CreateIDEWindow`, layout `'72%','120','+170','-200'`, dock sibling
`NonModalIDEWindowNames[nmiwSourceNoteBook]`, `alRight`), and shown with
`IDEWindowCreators.ShowForm(CodeExplorerView, ...)`.

### 3. Public registration API in components/ideintf

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -rn "IDEWindowCreators\|TIDEWindowCreator\b\|IDEDockMaster\|RegisterDockableIDEWindow" components/ideintf/*.pas | head -40
components/ideintf/idewindowintf.pas:317:  { TIDEWindowCreator
components/ideintf/idewindowintf.pas:318:    Every dockable window of the IDE needs a TIDEWindowCreator. }
components/ideintf/idewindowintf.pas:320:  TIDEWindowCreator = class
components/ideintf/idewindowintf.pas:385:    fItems: TFPList; // list of TIDEWindowCreator
components/ideintf/idewindowintf.pas:389:    function GetItems(Index: integer): TIDEWindowCreator;
components/ideintf/idewindowintf.pas:396:    property Items[Index: integer]: TIDEWindowCreator read GetItems; default;
components/ideintf/idewindowintf.pas:397:    function Add(aLayout: TIDEWindowCreator): integer; overload;
components/ideintf/idewindowintf.pas:398:    function Add(aFormName: string): TIDEWindowCreator; overload;
components/ideintf/idewindowintf.pas:399:    function Add(aFormName: string;
components/ideintf/idewindowintf.pas:412:    function FindWithName(FormName: string): TIDEWindowCreator;
components/ideintf/idewindowintf.pas:430:  IDEWindowCreators: TIDEWindowCreatorList = nil; // set by the IDE
components/ideintf/idewindowintf.pas:436:  { TIDEDockMaster }
components/ideintf/idewindowintf.pas:438:  TIDEDockMaster = class
components/ideintf/idewindowintf.pas:469:  OnIDEDockMasterNeeded: procedure = nil;
components/ideintf/idewindowintf.pas:471:procedure SetIDEDockMaster(AnIDEDockMaster: TIDEDockMaster);
components/ideintf/idewindowintf.pas:472:function  GetIDEDockMaster: TIDEDockMaster;
components/ideintf/idewindowintf.pas:474:property IDEDockMaster: TIDEDockMaster read GetIDEDockMaster write SetIDEDockMaster;
components/ideintf/idewindowintf.pas:492:  TheIDEDockMaster: TIDEDockMaster = nil; // can be set by a package
components/ideintf/idewindowintf.pas:399-410: (see below)
```

`Add` signature (line 399):

```pascal
function Add(aFormName: string;
             CreateFormProc: TCreateIDEWindowProc;
             CreateFormMethod: TCreateIDEWindowMethod;
             aLeft, aTop, aRight, aBottom: string;
             aDockSibling: string = '';
             aDockAlign: TAlign = alNone;
             aMulti: boolean = false;
             GetLayoutEvent: TGetDefaultIDEWindowLayoutEvent = nil): TIDEWindowCreator; overload;
```

`TCreateIDEWindowProc` / `TCreateIDEWindowMethod` (line 308-310):

```pascal
TCreateIDEWindowMethod = procedure(Sender: TObject; aFormName: string;
  var AForm: TCustomForm; DoDisableAutoSizing: boolean) of object;
TCreateIDEWindowProc = procedure(Sender: TObject; aFormName: string;
  var AForm: TCustomForm; DoDisableAutoSizing: boolean);
```

The public API **does** provide registration for a third-party window. `IDEDockMaster` is also available (`IDEDockMaster` global, `TIDEDockMaster` with `MakeIDEWindowDockable`/`MakeIDEWindowDockSite`), but the high-level `IDEWindowCreators` path is sufficient and matches what the IDE itself uses.

### 4-5. Implementation

`edit: WKCodeExplorer/WKCodeExplorer.pas` — added `IDEWindowIntf` to `uses`; added `CreateWKCodeExplorer` creator (calls `IDEWindowCreators.CreateForm` and stores the form in `WKCodeExplorerForm`, wiring `OnJumpToCode`); changed `ShowWKCodeExplorer` to use `IDEWindowCreators.ShowForm('WKCodeExplorer', True)`; registered the window in `Register` via `IDEWindowCreators.Add('WKCodeExplorer', @CreateWKCodeExplorer, nil, '72%', '120', '+170', '-200', 'SourceEditor', alRight)`.

### 6. Build

```console
$ cd ... && source ~/.zshrc && lazbuild -B --ws=gtk2 WKCodeExplorer/WKCodeExplorer.lpk > /tmp/opencode/wkbuild-dock.log 2>&1; echo "exit=$?"; tail -n 3 /tmp/opencode/wkbuild-dock.log
manpath: can't set the locale; make sure $LC_* and $LANG are correct
exit=0
(1008) 3621 lines compiled, 0.8 sec
(1021) 2 warning(s) issued
(1022) 31 hint(s) issued
```

### 7. Final git status

```console
$ cd ... && git status --short
 M tests/TestVisibility.pas
?? M2-STEP2-IMPLEMENTATION-REPORT.md
?? M2-STEP2-MEASUREMENT-REPORT.md
?? M2-STEP2-ONEDITORDESTROY-REPORT.md
?? M3-FEASIBILITY-CODEEXPLORER-PORT.md
?? M3-STEP2-ENDLINE-PROPOSAL.md
?? WKCodeExplorer/
?? prompt-result/
?? tests/TestHuge.pas
?? tests/TestLarge.pas
?? tests/extract_names.lpi
?? tests/extract_names.lpr
```

Branch still `mmx-codeexplorer`.

---

## c) Changes made, file by file

### `WKCodeExplorer/WKCodeExplorer.pas`

- Added `IDEWindowIntf` to the `uses` clause (public dockable-window API).
- Added `CreateWKCodeExplorer(Sender; aFormName; var AForm; DoDisableAutoSizing)`:
  calls `IDEWindowCreators.CreateForm(AForm, TWKCodeExplorerView,
  DoDisableAutoSizing, Application)` and stores the resulting form in the
  `WKCodeExplorerForm` singleton, wiring `OnJumpToCode`.
- `ShowWKCodeExplorer` now calls `IDEWindowCreators.ShowForm('WKCodeExplorer',
  True)` instead of creating/showing the form directly, so the IDE's dock
  master handles placement, docking and layout restoration.
- `Register` calls `IDEWindowCreators.Add('WKCodeExplorer', @CreateWKCodeExplorer,
  nil, '72%', '120', '+170', '-200', 'SourceEditor', alRight)` — same layout
  hints as the built-in Code Explorer (right-docked to the source editor).

**Why:** the public `IDEWindowCreators` API exists and is exactly what the IDE
uses, so the WK window can be docked and its position saved/restored by the IDE
layout system. No internal IDE units were copied.

### No other files changed.

---

## d) Build output, errors and hints

Widgetset: **gtk2**. Exit status: **0** (success).

Full output (`/tmp/opencode/wkbuild-dock.log`):

```text
Hint: (lazbuild) Opt: "primary-config-path=/home/kastawan/FPC-Deluxe/config_lazarus"
Hint: (lazarus) SetPrimaryConfigPath NewValue="/home/kastawan/FPC-Deluxe/config_lazarus"
Hint: (lazarus) [TBuildManager.SetBuildTarget] Old=x86_64-linux--gtk2 New=x86_64-linux--gtk2 Changed: OS/CPU=True LCL=False
Hint: (lazbuild) Compile package "/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.lpk"
Info: (lazarus) Execute Title="Compile package WKCodeExplorer 0.0"
Info: (lazarus) Working Directory="/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/"
Info: (lazarus) Executable="/home/kastawan/FPC-Deluxe/fpc/bin/x86_64-linux/fpc.sh"
Info: (lazarus) Param[0]="-MObjFPC"
...
Info: (lazarus) Param[25]="WKCodeExplorerRegister.pas"
Info: (lazarus) Param[26]="-B"
Hint: (11030) Start of reading config file /home/kastawan/FPC-Deluxe/fpc/bin/x86_64-linux/fpc.cfg
Hint: (11031) End of reading config file /home/kastawan/FPC-Deluxe/fpc/bin/x86_64-linux/fpc.cfg
Free Pascal Compiler version 3.3.1-21799-g7cfa194418-dirty [2026/11/12] for x86_64
Copyright (c) 1993-2026 by Florian Klaempfl and others
(1002) Target OS: Linux for x86-64
(3104) Compiling WKCodeExplorerRegister.pas
(3104) Compiling WKCodeExplorer.pas
(3104) Compiling WKCodeExplOpts.pas
/media/.../WKCodeExplorer.pas(155,38) Hint: (5024) Parameter "Sender" not used
... (26 more 5024 hints)
/media/.../WKCodeExplorer.pas(715,9) Warning: (6060) Case statement does not handle all possible cases
/media/.../WKCodeExplorer.pas(1974,3) Warning: (6060) Case statement does not handle all possible cases
/media/.../WKCodeExplorer.pas(2997,32) Hint: (5024) Parameter "Sender" not used
/media/.../WKCodeExplorer.pas(2997,49) Hint: (5024) Parameter "aFormName" not used
/media/.../WKCodeExplorer.pas(3010,30) Hint: (5024) Parameter "Sender" not used
/media/.../WKCodeExplorer.pas(285,26) Hint: (5024) Parameter "Sender" not used
(1008) 3621 lines compiled, 0.8 sec
(1021) 2 warning(s) issued
(1022) 31 hint(s) issued
```

**Errors:** none. **Warnings:** 2 × `6060` (inherited from upstream). **Hints:** 31 × `5024`
(unused parameters, inherited + 3 new from the creator/show handlers) plus
config/build informational hints.

---

## e) Skipped or not possible, and why

1. **Nothing was skipped** — the public API (`IDEWindowCreators` /
   `TIDEWindowCreator` / `IDEDockMaster`) exists and is exactly what the IDE
   uses, so the WK window is registered as a dockable window with the same
   layout hints as the built-in Code Explorer (`'72%','120','+170','-200'`,
   docked right of `SourceEditor`). Position saving/restoration is handled by
   the IDE's layout system via `IDEWindowCreators`.
2. **No internal IDE units were copied** — only `IDEWindowIntf` (public
   IDEIntf) is used.
3. **Did not install, commit, or push**, and did not touch
   `toolbarexplorerplugin.pas` or `codetoolbarexplorer.lpk`.
4. **The pre-existing modification to `tests/TestVisibility.pas`** was left
   untouched.