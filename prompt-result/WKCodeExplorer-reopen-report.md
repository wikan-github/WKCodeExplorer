# WKCodeExplorer reopen report

Repository: `/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone`
Branch: `mmx-codeexplorer`
Widgetset built for: **gtk2**
Date: 2026-11-19

---

## a) Prompt explanation

After closing the docked WK Code Explorer and reopening it from
View → WK Code Explorer, it appeared as a floating window (restart restored the
docked position). The prompt asked me to compare the ShowForm overload used by
the port with the one used by the built-in Code Explorer and, if they differ,
switch the port to the built-in's overload: create the form through
`IDEWindowCreators.CreateForm` if it is nil, then
`IDEWindowCreators.ShowForm(WKCodeExplorerForm, True)`. Same prohibitions:
scope limited to `WKCodeExplorer/` and the report file, do not touch
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

### 2. ShowForm / CreateForm declarations in TIDEWindowCreatorList

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -n "procedure ShowForm\|procedure CreateForm\|function ShowForm" components/ideintf/idewindowintf.pas
components/ideintf/idewindowintf.pas:415:    procedure ShowForm(AForm: TCustomForm; BringToFront: boolean;
components/ideintf/idewindowintf.pas:417:    function ShowForm(AFormName: string; BringToFront: boolean): TCustomForm; overload;
components/ideintf/idewindowintf.pas:418:    procedure CreateForm(var AForm; AFormClass: TCustomFormClass;
```

```console
$ sed -n '413,420p' components/ideintf/idewindowintf.pas
    function GetForm(aFormName: string; AutoCreate: boolean;
                               DisableAutoSizing: boolean = false): TCustomForm;
    procedure ShowForm(AForm: TCustomForm; BringToFront: boolean;
                       AMoveToVisibleMode: TLayoutMoveToVisibleMode = vmOnlyMoveOffScreenToVisible); overload;
    function ShowForm(AFormName: string; BringToFront: boolean): TCustomForm; overload;
    procedure CreateForm(var AForm; AFormClass: TCustomFormClass;
                         DoDisableAutoSizing: boolean; TheOwner: TComponent); // utility function to create a form with delayed autosizing
```

Two overloads of `ShowForm`: by form object and by form name.

### 3. Built-in DoShowCodeExplorer

```console
$ sed -n '6159,6172p' /home/kastawan/FPC-Deluxe/lazarus/ide/main.pp
  if CodeExplorerView=nil then
  begin
    IDEWindowCreators.CreateForm(CodeExplorerView,TCodeExplorerView,
       State=iwgfDisabled,OwningComponent);
    CodeExplorerView.OnGetDirectivesTree:=@CodeExplorerGetDirectivesTree;
    CodeExplorerView.OnJumpToCode:=@CodeExplorerJumpToCode;
    CodeExplorerView.OnShowOptions:=@CodeExplorerShowOptions;
  end else if State=iwgfDisabled then
    CodeExplorerView.DisableAutoSizing{$IFDEF DebugDisableAutoSizing}('TMainIDE.DoShowCodeExplorer'){$ENDIF};

  if State>=iwgfShow then begin
    IDEWindowCreators.ShowForm(CodeExplorerView,State=iwgfShowOnTop);
    CodeExplorerView.Refresh(true);
  end;
```

The built-in uses the **form-object** overload:
`IDEWindowCreators.ShowForm(CodeExplorerView, State=iwgfShowOnTop)`.

### 4. Port's ShowWKCodeExplorer and Register (before change)

```console
$ grep -n "ShowWKCodeExplorer\|procedure Register" WKCodeExplorer/WKCodeExplorer.pas
...
$ sed -n '/procedure ShowWKCodeExplorer/,/^end;$/p' WKCodeExplorer/WKCodeExplorer.pas
procedure ShowWKCodeExplorer(Sender: TObject);
begin
  if IDEWindowCreators <> nil then
    IDEWindowCreators.ShowForm('WKCodeExplorer', True);
end;
```

```console
$ sed -n '/^procedure Register;/,/^end;$/p' WKCodeExplorer/WKCodeExplorer.pas
procedure Register;
begin
  RegisterStandardWKCodeExplorerMenuItems;
  if IDEWindowCreators <> nil then
    IDEWindowCreators.Add('WKCodeExplorer', @CreateWKCodeExplorer, nil,
      '72%', '120', '+170', '-200',
      'SourceEditor', alRight);
  if itmViewMainWindows <> nil then
    RegisterIDEMenuCommand(itmViewMainWindows, 'WKViewCodeExplorer',
      'WK Code Explorer', nil, @ShowWKCodeExplorer);
end;
```

**State before change:** the port used the **form-name** overload
`ShowForm('WKCodeExplorer', True)`, while the IDE uses the **form-object**
overload `ShowForm(CodeExplorerView, ...)`. Mismatch confirmed.

### 5. Change

`edit: WKCodeExplorer/WKCodeExplorer.pas` — `ShowWKCodeExplorer` now creates
the form via `IDEWindowCreators.CreateForm` if it is nil, then calls
`IDEWindowCreators.ShowForm(WKCodeExplorerForm, True)`, matching the built-in.

### 6. Build

```console
$ cd ... && source ~/.zshrc && lazbuild -B --ws=gtk2 WKCodeExplorer/WKCodeExplorer.lpk > /tmp/opencode/wkbuild-reopen.log 2>&1; echo "exit=$?"; tail -n 3 /tmp/opencode/wkbuild-reopen.log
manpath: can't set the locale; make sure $LC_* and $LANG are correct
exit=0
(1008) 3629 lines compiled, 0.8 sec
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

`ShowWKCodeExplorer` changed from:

```pascal
if IDEWindowCreators <> nil then
  IDEWindowCreators.ShowForm('WKCodeExplorer', True);
```

to:

```pascal
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
```

**Why:** the built-in uses the form-object overload `ShowForm(CodeExplorerView,
...)`, which restores the docked layout for an already-created form. The
form-name overload `ShowForm('WKCodeExplorer', ...)` re-resolves via the
creator and produced a floating window after a close. Matching the built-in
overload fixes reopen-after-close docking.

### No other files changed.

---

## d) Build output, errors and hints

Widgetset: **gtk2**. Exit status: **0** (success).

Full output (`/tmp/opencode/wkbuild-reopen.log`):

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
(1008) 3629 lines compiled, 0.8 sec
(1021) 2 warning(s) issued
(1022) 31 hint(s) issued
```

**Errors:** none. **Warnings:** 2 × `6060` (inherited). **Hints:** 31 × `5024` plus
config/build informational hints.

---

## e) Skipped or not possible, and why

1. **Step 6 branch was not taken** — the overloads *did* differ (port used the
   form-name overload, IDE uses the form-object overload), so step 5's change
   was applied. No investigation of `caHide`/dock state was needed.
2. **The `CreateWKCodeExplorer` creator is still registered** via
   `IDEWindowCreators.Add` in `Register`, so the IDE layout system can still
   recreate the form on restore; `ShowWKCodeExplorer` now also creates it
   directly if it is nil and shows it via the form-object overload.
3. **Did not install, commit, or push**, and did not touch
   `toolbarexplorerplugin.pas` or `codetoolbarexplorer.lpk`.
4. **The pre-existing modification to `tests/TestVisibility.pas`** was left
   untouched.