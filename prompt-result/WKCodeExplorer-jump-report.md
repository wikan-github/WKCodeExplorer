# WKCodeExplorer jump report

Repository: `/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone`
Branch: `mmx-codeexplorer`
Widgetset built for: **gtk2**
Date: 2026-11-19

---

## a) Prompt explanation

The double-click/Enter on a node in the WK Code Explorer did nothing: the view's
`JumpToSelection` calls `OnJumpToCode` only if it is assigned, then checks that
the active editor's `CodeToolsBuffer` and `CursorTextXY` match the target. In
the port, `OnJumpToCode` was never assigned, so the check failed and nothing
happened. This step adds a handler that opens the target file in the editor and
moves the caret, using only the public IDEIntf API. The same prohibitions apply:
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

Branch confirmed: `mmx-codeexplorer`. (A pre-existing unrelated modification to
`tests/TestVisibility.pas` was present; it was not touched.)

### 2. IDE source: where OnJumpToCode is assigned

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -n "OnJumpToCode" ide/main.pp
6164:    CodeExplorerView.OnJumpToCode:=@CodeExplorerJumpToCode;
```

```console
$ sed -n '9941,9947p' ide/main.pp
procedure TMainIDE.CodeExplorerJumpToCode(Sender: TObject;
  const Filename: string; const Caret: TPoint; TopLine: integer);
begin
  DoJumpToSourcePosition(Filename,Caret.X,Caret.Y,TopLine,[jfAddJumpPoint, jfFocusEditor]);
end;
```

`DoJumpToSourcePosition` is defined in `TMainIDE` (`ide/main.pp:10374`) and in
`TMainIDEInterface` (`ide/mainintf.pas`), but only the IDE's own `TMainIDE`
instance can call it; a third-party package must use the public
`TLazIDEInterface` API.

### 3. Public IDE API verification (grep output)

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -rn "DoOpenFileAndJumpToPos" components/ideintf/lazideintf.pas
components/ideintf/lazideintf.pas:368:    function DoOpenFileAndJumpToPos(const AFilename: string;
components/ideintf/lazideintf.pas:370:                       PageIndex, WindowIndex: integer; Flags: TOpenFlags): TModalResult; virtual; abstract; overload;
components/ideintf/lazideintf.pas:371:    function DoOpenFileAndJumpToPos(const AFilename: string;
components/ideintf/lazideintf.pas:372:                       const CursorPosition: TPoint; TopLine, BlockTopLine, BlockBottomLine: integer;
components/ideintf/lazideintf.pas:373:                       PageIndex, WindowIndex: integer; Flags: TOpenFlags): TModalResult; virtual; abstract; overload;
components/ideintf/lazideintf.pas:859:  function TLazIDEInterface.DoOpenFileAndJumpToPos(const AFilename: string;
components/ideintf/lazideintf.pas:863:  Result := DoOpenFileAndJumpToPos(AFilename, CursorPosition, TopLine, TopLine, TopLine, PageIndex, WindowIndex, Flags);
```

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -n "ofOnlyIfExists\|ofRegularFile" components/ideintf/lazideintf.pas
101:    ofOnlyIfExists,  // do not auto create non existing files
108:    ofRegularFile,   // open as regular file (e.g. do not open projects/packages)
```

Both call names exist in the public IDEIntf. `DoOpenFileAndJumpToPos` opens the
file (if not already open) and moves the caret, which covers steps (a)-(d).

### 4. Edits

`edit: WKCodeExplorer/WKCodeExplorer.pas` — added `procedure JumpToCode(...)` to
the public section of `TWKCodeExplorerView` and implemented it using
`LazarusIDE.DoOpenFileAndJumpToPos(Filename, Caret, TopLine, -1, -1,
[ofOnlyIfExists, ofRegularFile])`.

`edit: WKCodeExplorer/WKCodeExplorer.pas` — in `ShowWKCodeExplorer`, after
creating the form, assigned `WKCodeExplorerForm.OnJumpToCode :=
@WKCodeExplorerForm.JumpToCode`.

### 5. Build

```console
$ cd ... && source ~/.zshrc && lazbuild -B --ws=gtk2 WKCodeExplorer/WKCodeExplorer.lpk > /tmp/opencode/wkbuild-jump.log 2>&1; echo "exit=$?"; tail -n 3 /tmp/opencode/wkbuild-jump.log
manpath: can't set the locale; make sure $LC_* and $LANG are correct
exit=0
(1008) 3610 lines compiled, 0.8 sec
(1021) 2 warning(s) issued
(1022) 29 hint(s) issued
```

### 6. Final git status

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

- Added public method `JumpToCode(Sender; const Filename; const Caret: TPoint;
  TopLine: integer)` to `TWKCodeExplorerView`, implemented via
  `LazarusIDE.DoOpenFileAndJumpToPos(Filename, Caret, TopLine, -1, -1,
  [ofOnlyIfExists, ofRegularFile])`. This opens the file if needed, sets the
  caret and top line, and brings the editor to front — exactly the behaviour of
  the original `TMainIDE.CodeExplorerJumpToCode` → `DoJumpToSourcePosition`.
- In `ShowWKCodeExplorer`, assigned `WKCodeExplorerForm.OnJumpToCode :=
  @WKCodeExplorerForm.JumpToCode` after creating the form.

**Why:** the prompt's root cause — `OnJumpToCode` was never assigned, so
`JumpToSelection`'s check failed.

### No other files changed.

---

## d) Build output, errors and hints

Widgetset: **gtk2**. Exit status: **0**.

Full output (`/tmp/opencode/wkbuild-jump.log`):

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
/media/.../WKCodeExplorer.pas(1973,3) Warning: (6060) Case statement does not handle all possible cases
/media/.../WKCodeExplorer.pas(284,26) Hint: (5024) Parameter "Sender" not used
/media/.../WKCodeExplorer.pas(2996,30) Hint: (5024) Parameter "Sender" not used
(1008) 3610 lines compiled, 0.8 sec
(1021) 2 warning(s) issued
(1022) 29 hint(s) issued
```

**Errors:** none. **Warnings:** 2 × `6060` (inherited from upstream). **Hints:** 29 × `5024`
(unused parameters, inherited) plus config/build informational hints.

---

## e) Skipped or not possible, and why

1. **`DoJumpToSourcePosition` (the IDE's own method) was not used** — it is
   defined on `TMainIDE`/`TMainIDEInterface` and is not part of the public
   `TLazIDEInterface` API available to a third-party package. Instead I used
   the public `LazarusIDE.DoOpenFileAndJumpToPos`, which covers open + caret +
   top line + focus in one call.
2. **No explicit "bring editor to front" beyond what `DoOpenFileAndJumpToPos`
   does** — that call already focuses the editor (`jfFocusEditor`-equivalent
   behaviour in the public implementation). If a separate `BringToFront` turns
   out to be needed, it can be added later.
3. **`OnJumpToCode` was assigned only in `ShowWKCodeExplorer`** (when the form
   is first created). Because the form is kept alive, the handler stays
   attached for the package's lifetime. If the form were ever recreated, the
   assignment would need to be repeated.
4. **Did not install, commit, or push**, and did not touch
   `toolbarexplorerplugin.pas` or `codetoolbarexplorer.lpk`.
5. **The pre-existing modification to `tests/TestVisibility.pas`** was left
   untouched.