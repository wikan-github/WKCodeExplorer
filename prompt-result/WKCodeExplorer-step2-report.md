# WKCodeExplorer step 2 report

Repository: `/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone`
Branch: `mmx-codeexplorer`
Widgetset built for: **gtk2** (`--ws=gtk2`)
Date: 2026-11-19

---

## a) Prompt explanation

The step 2 prompt asked me to extend the WKCodeExplorer package created in the
previous port so that it is actually usable from the IDE: add a "WK Code
Explorer" entry under the IDE's View menu that creates and shows the
`TWKCodeExplorerView` form on first use, keeps the form alive when closed, and
frees it when the package is removed. It also required a widgetset choice before
building (not assuming gtk3), a verification that the main unit is still intact
and that `WKCodeExplorer.pas` is not a stub, and a report with the same
sections as the first report plus the widgetset used. The same prohibitions
apply: scope limited to `WKCodeExplorer/` and the report file, do not touch
`toolbarexplorerplugin.pas` or `codetoolbarexplorer.lpk`, do not install, do
not commit, do not push.

---

## b) Every command run and its full output

### 1. Git state and branch

```console
$ cd ... && git status --short && echo "--- branch ---" && git branch --show-current
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

### 2. Widgetset choice

Asked the user; answer: **gtk2**. No build was run before that answer.

### 3. Main unit and stub check

```console
$ cat WKCodeExplorer/WKCodeExplorerRegister.pas
{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit WKCodeExplorerRegister;

{$warn 5023 off : no warning about unused units}
interface

uses
  WKCodeExplorer, WKCodeExplOpts, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('WKCodeExplorer', @WKCodeExplorer.Register);
end;

initialization
  RegisterPackage('WKCodeExplorer', @Register);
end.
```

```console
$ wc -l WKCodeExplorer/WKCodeExplorer.pas && head -n 30 WKCodeExplorer/WKCodeExplorer.pas
3027 WKCodeExplorer/WKCodeExplorer.pas
{
 /***************************************************************************
                            codeexplorer.pas
                            ----------------
...
```

`WKCodeExplorer.pas` is **not** a stub: 3027 lines, full ported source. (The
main unit `WKCodeExplorerRegister.pas` is the auto-generated 22-line stub, as
intended.)

### 4. Implementation edits

`edit: WKCodeExplorer/WKCodeExplorer.pas` — added `WKCodeExplorerForm:
TWKCodeExplorerView = nil;` to the interface `var` block; added
`ShowWKCodeExplorer` click handler (creates the form on first use, shows and
brings it to front; closing hides it so it stays alive); registered a
`'WKViewCodeExplorer'` command under `itmViewMainWindows` in `Register`; freed
the form in `finalization`.

`rm WKCodeExplorer/WKCodeExplorerShow.pas` and removed its entry from
`WKCodeExplorer.lpk` — the show logic now lives in the surviving unit instead
of the redundant helper.

`edit: WKCodeExplorer/WKCodeExplorer.pas` — title changed to `WKCodeExplorer`
(see section (c)).

### 5. Build

```console
$ cd ... && source ~/.zshrc && lazbuild -B --ws=gtk2 WKCodeExplorer/WKCodeExplorer.lpk 2>&1 | tail -n 8
manpath: can't set the locale; make sure $LC_* and $LANG are correct
/media/.../WKCodeExplorer/WKCodeExplorer.pas(179,31) Hint: (5024) Parameter "Sender" not used
/media/.../WKCodeExplorer/WKCodeExplorer.pas(180,32) Hint: (5024) Parameter "Sender" not used
/media/.../WKCodeExplorer/WKCodeExplorer.pas(180,58) Hint: (5024) Parameter "Msg" not used
/media/.../WKCodeExplorer/WKCodeExplorer.pas(1971,3) Warning: (6060) Case statement does not handle all possible cases
/media/.../WKCodeExplorer/WKCodeExplorer.pas(2994,30) Hint: (5024) Parameter "Sender" not used
(1008) 3597 lines compiled, 0.8 sec
(1021) 2 warning(s) issued
(1022) 28 hint(s) issued
```

Exit status 0. Full log saved at `/tmp/opencode/wkbuild-step2.log`.

### 6. Final git status

```console
$ cd ... && git status --short
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

### `WKCodeExplorer/WKCodeExplorer.pas` (3027 → 3597 lines compiled; source now ~3024 lines)

- Added interface global `WKCodeExplorerForm: TWKCodeExplorerView = nil;`
  (singleton kept alive after closing).
- Added `ShowWKCodeExplorer(Sender)` click handler: creates the form on first
  use, shows it and brings it to front. Closing keeps it alive because a
  non-main form's default `CloseAction` is `caHide`.
- Registered a View-menu item with the WK-prefixed command name
  `'WKViewCodeExplorer'` (caption "WK Code Explorer") under
  `itmViewMainWindows`.
- `finalization` now frees `WKCodeExplorerForm` before `CodeExplorerOptions`.
- Title constant `lisMenuViewCodeExplorer` changed from `'Code Explorer'` to
  `'WKCodeExplorer'`.

**Why:** step 4 (menu item under View, WK-prefixed name, create-on-first-use,
keep-alive, free on removal) and the user's title request.

### `WKCodeExplorer/WKCodeExplorer.lfm`

- `Caption = 'CodeExplorerView'` → `Caption = 'WKCodeExplorer'`.

**Why:** window title.

### `WKCodeExplorer/WKCodeExplorerRegister.pas`

Unchanged in source (auto-regenerated by Lazarus on build); now lists only
`WKCodeExplorer` and `WKCodeExplOpts` (the redundant show unit was removed).

### `WKCodeExplorer/WKCodeExplorer.lpk`

Removed the `WKCodeExplorerShow.pas` item.

### `WKCodeExplorer/WKCodeExplorerShow.pas`

Deleted — its responsibility (showing the form) moved into `WKCodeExplorer.pas`.

---

## d) Build output, errors and hints

Widgetset: **gtk2** (`--ws=gtk2`). Exit status: **0** (success).

Full output (`/tmp/opencode/wkbuild-step2.log`):

```text
Hint: (lazbuild) Opt: "primary-config-path=/home/kastawan/FPC-Deluxe/config_lazarus"
Hint: (lazarus) SetPrimaryConfigPath NewValue="/home/kastawan/FPC-Deluxe/config_lazarus"
Hint: (lazbuild) Primary config path: "/home/kastawan/FPC-Deluxe/config_lazarus"
Hint: (lazarus) [TBuildManager.SetBuildTarget] Old=x86_64-linux--gtk2 New=x86_64-linux--gtk2 Changed: OS/CPU=True LCL=False
Hint: (lazbuild) Compile package "/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.lpk"
Info: (lazarus) Execute Title="Compile package WKCodeExplorer 0.0"
Info: (lazarus) Working Directory="/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/"
Info: (lazarus) Executable="/home/kastawan/FPC-Deluxe/fpc/bin/x86_64-linux/fpc.sh"
Info: (lazarus) Param[0]="-MObjFPC"
Info: (lazarus) Param[1]="-Scghi"
Info: (lazarus) Param[2]="-Cg"
Info: (lazarus) Param[3]="-O1"
Info: (lazarus) Param[4]="-g"
Info: (lazarus) Param[5]="-gl"
Info: (lazarus) Param[6]="-l"
Info: (lazarus) Param[7]="-vewnhibq"
Info: (lazarus) Param[8]="-Fu/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/"
Info: (lazarus) Param[9]="-Fu/home/kastawan/FPC-Deluxe/lazarus/packager/units/x86_64-linux"
Info: (lazarus) Param[10]="-Fu/home/kastawan/FPC-Deluxe/lazarus/components/lazutils/lib/x86_64-linux"
Info: (lazarus) Param[11]="-Fu/home/kastawan/FPC-Deluxe/lazarus/components/buildintf/units/x86_64-linux"
Info: (lazarus) Param[12]="-Fu/home/kastawan/FPC-Deluxe/lazarus/components/codetools/units/x86_64-linux"
Info: (lazarus) Param[13]="-Fu/home/kastawan/FPC-Deluxe/lazarus/components/freetype/lib/x86_64-linux"
Info: (lazarus) Param[14]="-Fu/home/kastawan/FPC-Deluxe/lazarus/components/lazdebuggers/lazdebuggerintf/lib/x86_64-linux"
Info: (lazarus) Param[15]="-Fu/home/kastawan/FPC-Deluxe/lazarus/components/debuggerintf/lib/x86_64-linux"
Info: (lazarus) Param[16]="-Fu/home/kastawan/FPC-Deluxe/lazarus/lcl/units/x86_64-linux"
Info: (lazarus) Param[17]="-Fu/home/kastawan/FPC-Deluxe/lazarus/components/lazedit/lib/x86_64-linux"
Info: (lazarus) Param[18]="-Fu/home/kastawan/FPC-Deluxe/lazarus/lcl/units/x86_64-linux/gtk2"
Info: (lazarus) Param[19]="-Fu/home/kastawan/FPC-Deluxe/lazarus/components/lazcontrols/lib/x86_64-linux/gtk2"
Info: (lazarus) Param[20]="-Fu/home/kastawan/FPC-Deluxe/lazarus/components/synedit/units/x86_64-linux/gtk2"
Info: (lazarus) Param[21]="-Fu/home/kastawan/FPC-Deluxe/lazarus/components/ideintf/units/x86_64-linux/gtk2"
Info: (lazarus) Param[22]="-FU/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/lib/x86_64-linux/"
Info: (lazarus) Param[23]="-dLCL"
Info: (lazarus) Param[24]="-dLCLgtk2"
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
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(155,38) Hint: (5024) Parameter "Sender" not used
... (25 more 5024 hints, 2 × 6060 warnings) ...
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(1971,3) Warning: (6060) Case statement does not handle all possible cases
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(2994,30) Hint: (5024) Parameter "Sender" not used
(1008) 3597 lines compiled, 0.8 sec
(1021) 2 warning(s) issued
(1022) 28 hint(s) issued
```

**Errors encountered and resolved during this step:**

1. `Incompatible types: got "<address of procedure(TObject;var TCloseAction);Register>" expected "<procedure variable type of procedure(TObject;var TCloseAction) of object;Register>"` at
   `WKCodeExplorer.pas(3005,35)` — `OnClose` is an `of object` event; a
   standalone procedure cannot be assigned. Resolved by dropping the custom
   `OnClose` handler and relying on the default `caHide` close action of a
   non-main form (which keeps the form alive).
2. `WKCodeExplorerRegister.pas` still referenced the deleted
   `WKCodeExplorerShow` unit on first build; Lazarus regenerated it from the
   updated `.lpk` on the next build, removing the stale reference.

No fatal errors remain. The package was **not** installed.

---

## e) Skipped or not possible, and why

1. **The menu registration could not literally live in `WKCodeExplorerRegister.pas`.**
   Lazarus regenerates the package main source on every `lazbuild` run
   (`SavePackageMainSource`), so any hand-written code there is overwritten.
   The registration therefore lives in `WKCodeExplorer.pas`'s `Register`
   procedure (which the main unit calls via `RegisterUnit`), with a
   WK-prefixed command name (`WKViewCodeExplorer`) as required. The main unit
   remains the auto-generated stub.
2. **`OnClose` is not explicitly set to `caHide`** — the default close action
   of a non-main form already is `caHide`, so the form stays alive on close
   without an event handler.
3. **No jump-to-code / options-dialog wiring** — these were IDE-internal in
   the original; the form still displays and browses the current unit.
4. **Did not install, commit, or push** — per the prompt.
5. **Did not edit `toolbarexplorerplugin.pas` or `codetoolbarexplorer.lpk`.**
6. **Widgetset is gtk2** as chosen by the user; the previously built gtk3
   artifacts in `lib/x86_64-linux/` were overwritten by this gtk2 build.