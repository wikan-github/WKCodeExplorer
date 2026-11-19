# WKCodeExplorer float report

Repository: `/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone`
Branch: `mmx-codeexplorer`
Widgetset built for: **gtk2**
Date: 2026-11-19

---

## a) Prompt explanation

After closing the docked WK Code Explorer and reopening it from View, it floated
instead of re-docking (restart restored the docked position). The prompt
suspected the dock-sibling argument in the port's `IDEWindowCreators.Add` call:
the port used the literal `'SourceEditor'`, which may not match the IDE's window
name. I was asked to find the IDE's actual sibling name, compare the two Add
calls argument by argument, fix the sibling if it differed, verify the form Name
matches, build, and report. Same prohibitions: scope limited to
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

### 2. nmiwSourceNoteBook / NonModalIDEWindowNames

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -rn "nmiwSourceNoteBook\|NonModalIDEWindowNames" ide/*.pas components/ideintf/*.pas | head
ide/packages/ideconfig/ideoptiondefs.pas:80:    nmiwSourceNoteBook,
ide/packages/ideconfig/ideoptiondefs.pas:105:    nmiwSourceNoteBook,
ide/packages/ideconfig/ideoptiondefs.pas:113:  NonModalIDEWindowNames: array[TNonModalIDEWindow] of string = (
```

```console
$ sed -n '78,132p' ide/packages/ideconfig/ideoptiondefs.pas
  TNonModalIDEWindow = (
    nmiwNone, // empty/none/undefined
    nmiwMainIDE,
    nmiwSourceNoteBook,
    nmiwMessagesView,
    nmiwUnitDependencies,
    nmiwCodeExplorer,
    nmiwFPDocEditor,
    ...
  );

  // form names for non modal IDE windows:
  NonModalIDEWindowNames: array[TNonModalIDEWindow] of string = (
    '?',
    'MainIDE',
    'SourceNotebook',
    'MessagesView',
    'UnitDependencies',
    'CodeExplorerView',
    ...
   );
```

So `NonModalIDEWindowNames[nmiwSourceNoteBook]` = **`'SourceNotebook'`** (file:
`ide/packages/ideconfig/ideoptiondefs.pas`, lines 80 and 113/118). The port
could not reference this array (it is IDE-internal, in `ideconfig`), so the
literal string `'SourceNotebook'` is used, citing that definition.

### 3. Built-in vs port Add call comparison

Built-in (`ide/main.pp:2571-2573`):

```pascal
IDEWindowCreators.Add(NonModalIDEWindowNames[nmiwCodeExplorer],   // 'CodeExplorerView'
  nil, @CreateIDEWindow, '72%', '120', '+170', '-200',
  NonModalIDEWindowNames[nmiwSourceNoteBook], alRight);            // 'SourceNotebook', alRight
```

Port (before fix) `Register`:

```pascal
IDEWindowCreators.Add('WKCodeExplorer', @CreateWKCodeExplorer, nil,
  '72%', '120', '+170', '-200',
  'SourceEditor', alRight);
```

Argument-by-argument:

| # | Built-in | Port (before) | Match? |
|---|---|---|---|
| 1 form name | `'CodeExplorerView'` | `'WKCodeExplorer'` | different (expected, unique name) |
| 2 CreateFormProc | `nil` | `@CreateWKCodeExplorer` | different (port needs its own creator) |
| 3 CreateFormMethod | `@CreateIDEWindow` | `nil` | different (port uses proc) |
| 4 aLeft | `'72%'` | `'72%'` | yes |
| 5 aTop | `'120'` | `'120'` | yes |
| 6 aRight | `'+170'` | `'+170'` | yes |
| 7 aBottom | `'-200'` | `'-200'` | yes |
| 8 aDockSibling | `'SourceNotebook'` | `'SourceEditor'` | **NO — bug** |
| 9 aDockAlign | `alRight` | `alRight` | yes |

The only incorrect argument is the dock sibling: `'SourceEditor'` is not a
registered IDE window name, so the dock master could not find the sibling and
the window floated. Fixed to `'SourceNotebook'`.

### 4. Form Name check

```console
$ grep -n "^  Name\|^Name" WKCodeExplorer/WKCodeExplorer.lfm
(no output)
```

The `.lfm` has no explicit `Name` property; the form's Name is set at runtime
in `CodeExplorerViewCreate`:

```pascal
Name := 'WKCodeExplorer';   // WKCodeExplorer.pas line 501
```

This matches the name passed to `IDEWindowCreators.Add('WKCodeExplorer', ...)`
and `ShowForm('WKCodeExplorer', ...)` / `ShowForm(WKCodeExplorerForm, ...)`.
No correction needed.

### 5. Fix applied

`edit: WKCodeExplorer/WKCodeExplorer.pas` — dock sibling `'SourceEditor'` →
`'SourceNotebook'`.

### 6. Build

```console
$ cd ... && source ~/.zshrc && lazbuild -B --ws=gtk2 WKCodeExplorer/WKCodeExplorer.lpk > /tmp/opencode/wkbuild-float.log 2>&1; echo "exit=$?"; tail -n 4 /tmp/opencode/wkbuild-float.log
manpath: can't set the locale; make sure $LC_* and $LANG are correct
exit=0
/media/.../WKCodeExplorer.pas(285,26) Hint: (5024) Parameter "Sender" not used
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

- In `Register`, `IDEWindowCreators.Add(...)` dock-sibling argument changed from
  `'SourceEditor'` to `'SourceNotebook'`.

**Why:** `'SourceEditor'` is not a registered IDE window name, so the dock
master could not resolve the sibling and the window floated. `'SourceNotebook'`
is the exact value of `NonModalIDEWindowNames[nmiwSourceNoteBook]` defined in
`ide/packages/ideconfig/ideoptiondefs.pas`, which is what the built-in Code
Explorer uses.

### No other files changed.

---

## d) Build output, errors and hints

Widgetset: **gtk2**. Exit status: **0** (success).

Full output (`/tmp/opencode/wkbuild-float.log`):

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

1. **The form Name was not corrected** — it is already `'WKCodeExplorer'` (set at
   runtime in `CodeExplorerViewCreate`, line 501), which matches the name
   passed to `IDEWindowCreators.Add` and `ShowForm`. No change needed.
2. **`NonModalIDEWindowNames` could not be referenced directly** — it lives in
   the IDE-internal `ideconfig` package (`ideoptiondefs.pas`), so the literal
   string `'SourceNotebook'` is used instead, citing its definition.
3. **Did not install, commit, or push**, and did not touch
   `toolbarexplorerplugin.pas` or `codetoolbarexplorer.lpk`.
4. **The pre-existing modification to `tests/TestVisibility.pas`** was left
   untouched.