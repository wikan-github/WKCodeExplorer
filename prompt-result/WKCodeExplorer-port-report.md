# WKCodeExplorer port report

Repository: `/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone`
Branch: `mmx-codeexplorer`
Date: 2026-11-19

---

## a) Prompt explanation

The prompt asked me to port Lazarus's own Code Explorer (`codeexplorer.pas`,
`codeexplopts.pas`, `codeexplorer.lfm`) out of the IDE source tree and into a
standalone, third-party Lazarus package named **WKCodeExplorer**, confined to a
new folder `WKCodeExplorer/` plus this report file. The motivation is recorded
in `M3-FEASIBILITY-CODEEXPLORER-PORT.md`: the real Code Explorer is tightly
wired to IDE-internal units (`LazarusIDEStrConsts`, `IdeConfStrConsts`,
`IdePackagerStrConsts`, `IDEOptionDefs`, `CodeExplOpts`), so a port must replace
those with local definitions before an external package can compile.

Specifically the prompt required:

1. confirm git branch and clean-ish state;
2. gate the work on the repository `LICENSE` being GPL-2.0-or-later compatible;
3. verify the three authoritative source files exist, show `ls -l`, and diff
   the two `.pas` files against "the uploads" (report differences, but never
   use the uploads as the source);
4. create `WKCodeExplorer.lpk` depending only on CodeTools, LazUtils, LCL,
   IDEIntf, SynEdit and FCL;
5. copy and rename the three files, rename the form class to
   `TWKCodeExplorerView` (including inside the `.lfm`);
6. apply feasibility-report section 6: drop internal uses and `{$I ide.inc}`,
   add local `lis*` constants, replace `NonModalIDEWindowNames`;
7. rewrite `codeexplopts.pas` as a plain settings class with only the members
   the view reads, plus `Load`/`Save`, and no IDE options page;
8. use WK-prefixed menu command names to avoid clashing with IDE command IDs;
9. build with `lazbuild` and record the output;
10. show final `git status --short` and write this report.

Explicit prohibitions: do not touch `toolbarexplorerplugin.pas` or
`codetoolbarexplorer.lpk`, do not install the package, do not commit, do not
push.

**License gate result:** the top of `LICENSE` is the **MIT License**
("Copyright (c) 2025 Anderson Fiori"). MIT is a permissive non-copyleft free
software license and is GPL-compatible (the GNU project lists the MIT/X11
license as compatible with the GNU GPL), so it **is** compatible with
GPL-2.0-or-later. I therefore continued. (Note: the Lazarus sources being
ported carry a GPL-2.0-or-later header; the repository license itself is MIT.)

---

## b) Every command run and its full output

All commands were run from the repository root unless stated otherwise.
`read` tool calls used to inspect files are listed as `read:` entries with the
line ranges requested; their content is also reflected in section (c).

### 1. Git state and branch

```console
$ cd /media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone && pwd && git status --short && git branch --show-current
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone
?? M2-STEP2-IMPLEMENTATION-REPORT.md
?? M2-STEP2-MEASUREMENT-REPORT.md
?? M2-STEP2-ONEDITORDESTROY-REPORT.md
?? M3-FEASIBILITY-CODEEXPLORER-PORT.md
?? M3-STEP2-ENDLINE-PROPOSAL.md
?? WKCodeExplorer/
?? tests/TestHuge.pas
?? tests/TestLarge.pas
?? tests/extract_names.lpi
?? tests/extract_names.lpr
mmx-codeexplorer
```

Branch confirmed: **`mmx-codeexplorer`**. A pre-existing untracked
`WKCodeExplorer/` folder was already present (work from an earlier session);
I investigated it before overwriting anything (see below).

### 2. LICENSE gate

```console
$ cd /media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone && echo "=== LICENSE top (first 40 lines) ===" && head -n 40 LICENSE
=== LICENSE top (first 40 lines) ===
MIT License

Copyright (c) 2025 Anderson Fiori

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### 3. Authoritative source files exist

```console
$ ls -l /home/kastawan/FPC-Deluxe/lazarus/ide/codeexplorer.pas /home/kastawan/FPC-Deluxe/lazarus/ide/codeexplopts.pas /home/kastawan/FPC-Deluxe/lazarus/ide/codeexplorer.lfm
-rw-rw-r-- 1 kastawan kastawan  30465 Nov 13 10:44 /home/kastawan/FPC-Deluxe/lazarus/ide/codeexplopts.pas
-rw-rw-r-- 1 kastawan kastawan   7079 Nov 13 10:44 /home/kastawan/FPC-Deluxe/lazarus/ide/codeexplorer.lfm
-rw-rw-r-- 1 kastawan kastawan  99210 Nov 13 10:44 /home/kastawan/FPC-Deluxe/lazarus/ide/codeexplorer.pas
```

### 4. Searching for the uploads and inspecting the pre-existing folder

```console
$ cd ... && echo "=== Find uploads ===" && find . -iname '*codeexplor*' -o -iname '*upload*' | head -50 && echo "=== Existing WKCodeExplorer folder ===" && ls -la WKCodeExplorer/
=== Find uploads ===
./.git/logs/refs/heads/mmx-codeexplorer
./.git/refs/heads/mmx-codeexplorer
./M3-FEASIBILITY-CODEEXPLORER-PORT.md
./img/CodeExplorerPlugin.png
./WKCodeExplorer
./WKCodeExplorer/WKCodeExplorer.lpk
./WKCodeExplorer/WKCodeExplorer.lfm
./WKCodeExplorer/lib/x86_64-linux/WKCodeExplorer.ppu
./WKCodeExplorer/lib/x86_64-linux/WKCodeExplorer.o
./WKCodeExplorer/lib/x86_64-linux/wkcodeexplorer.compiled
./WKCodeExplorer/WKCodeExplorer.pas
./LazarusCodeExplorerPlugin
=== Existing WKCodeExplorer folder ===
total 48
drwxrwxr-x 3 kastawan kastawan  4096 Nov 19 07:46 .
drwx------ 9 kastawan kastawan  4096 Nov 19 07:50 ..
-rw-rw-r-- 1 kastawan kastawan 17048 Nov 19 07:45 WKCodeExplOpts.pas
-rw-rw-r-- 1 kastawan kastawan  7089 Nov 19 07:44 WKCodeExplorer.lfm
-rw-rw-r-- 1 kastawan kastawan  1465 Nov 19 07:46 WKCodeExplorer.lpk
-rw-rw-r-- 1 kastawan kastawan   432 Nov 19 07:46 WKCodeExplorer.pas
drwxrwxr-x 3 kastawan kastawan  4096 Nov 19 07:46 lib
```

```console
$ cd ... && echo "=== All files near root ===" && ls -la && echo "=== Search whole tree for codeexplopts/codeexplorer copies ===" && find /media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output -iname 'codeexplorer.pas' -o -iname 'codeexplopts.pas' -o -iname 'codeexplorer.lfm' 2>/dev/null | head -50
=== All files near root ===
total 5124
drwx------  9 kastawan kastawan     4096 Nov 19 07:50 .
drwxrwxr-x 55 kastawan kastawan     4096 Nov 14 00:23 ..
drwxrwxr-x  8 kastawan kastawan     4096 Nov 19 07:52 .git
-rw-rw-r--  1 kastawan kastawan     2313 Nov 19 00:18 .gitignore
-rw-rw-r--  1 kastawan kastawan    10065 Nov 18 23:07 HANDOFF-REPORT-for-Claude.md
-rwx------  1 kastawan kastawan     1387 Nov 13 08:46 HANDOFF.md
-rw-rw-r--  1 kastawan kastawan     1071 Nov 18 20:19 LICENSE
-rw-rw-r--  1 kastawan kastawan     4417 Nov 18 20:05 Lazarus-MMX-Style-Code-Explorer-Milestone-Plan.md
-rw-rw-r--  2 kastawan kastawan    17048 Nov 19 07:45 ?? (see below)
...
```
(The `ls -la` output was truncated by the tool after 127 lines; it showed the
same files as the earlier `find`, i.e. no upload folder. Full output was saved
by the harness at
`/home/kastawan/.local/share/opencode/shell/7ec95c4c3fd1c1a81b1af4e81e0de54c8353dc55/sh_1f1160ad8001K6CBpin4sC4wQ7.out`.)
The second part of the command produced no matches.

```console
$ cd ... && echo "=== prompt-result ===" && ls -la prompt-result/ && echo "=== LazarusCodeExplorerPlugin ===" && ls -la LazarusCodeExplorerPlugin/ && echo "=== find candidate uploads (pas files with codeexpl in name anywhere in home) ===" && find /home/kastawan -iname '*codeexplor*' 2>/dev/null | head -80
=== prompt-result ===
total 8
drwxrwxr-x 2 kastawan kastawan 4096 Nov 19 07:44 .
drwx------ 9 kastawan kastawan 4096 Nov 19 07:50 ..
=== LazarusCodeExplorerPlugin ===
total 8
drwxrwxr-x 2 kastawan kastawan 4096 Nov 19 07:44 .
drwx------ 9 kastawan kastawan 4096 Nov 19 07:50 ..
=== find candidate uploads (pas files with codeexpl in name anywhere in home) ===
/home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone/.git/logs/refs/heads/mmx-codeexplorer
/home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone/.git/refs/heads/mmx-codeexplorer
/home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone/M3-FEASIBILITY-CODEEXPLORER-PORT.md
/home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone/img/CodeExplorerPlugin.png
/home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer
/home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.lpk
/home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.lfm
/home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/lib/x86_64-linux/WKCodeExplorer.ppu
/home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/lib/x86_64-linux/WKCodeExplorer.o
/home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/lib/x86_64-linux/wkcodeexplorer.compiled
/home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas
/home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone/LazarusCodeExplorerPlugin
/home/kastawan/.lazarus/codeexploreroptions.xml
/home/kastawan/FPC-Deluxe/lazarus/images/codeexplorer
/home/kastawan/FPC-Deluxe/lazarus/ide/frames/codeexplorer_categories_options.pas
/home/kastawan/FPC-Deluxe/lazarus/ide/frames/codeexplorer_update_options.lfm
/home/kastawan/FPC-Deluxe/lazarus/ide/frames/codeexplorer_update_options.pas
/home/kastawan/FPC-Deluxe/lazarus/ide/frames/codeexplorer_categories_options.lfm
/home/kastawan/FPC-Deluxe/lazarus/ide/codeexplorer.pas
/home/kastawan/FPC-Deluxe/lazarus/ide/codeexplorer.lfm
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk2/codeexplorer_categories_options.ppu
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk2/codeexplorer.ppu
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk2/codeexplorer_update_options.lfm
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk2/codeexplorer_categories_options.lfm
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk2/codeexplorer.o
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk2/codeexplorer_update_options.o
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk2/codeexplorer.lfm
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk3/codeexplorer_categories_options.ppu
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk3/codeexplorer.ppu
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk3/codeexplorer_update_options.lfm
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk3/codeexplorer_categories_options.lfm
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk3/codeexplorer.o
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk3/codeexplorer_update_options.o
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk3/codeexplorer.lfm
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk3/codeexplorer_update_options.ppu
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk3/codeexplorer_categories_options.ppu
/home/kastawan/FPC-Deluxe/lazarus/config_lazarus/codeexploreroptions.xml
```

`read: M3-FEASIBILITY-CODEEXPLORER-PORT.md` lines 1–213 — the section 6
replacement list used as the basis for the edits.

```console
$ echo "=== readlink both paths ===" && readlink -f /media/kastawan/.../MMX-Clone && readlink -f /home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone && echo "=== look for upload dirs ===" && find /home/kastawan /tmp /media/kastawan -maxdepth 4 -type d \( -iname '*upload*' -o -iname '*attach*' -o -iname '*incoming*' \) 2>/dev/null | head -40 && echo "=== grep HANDOFF for upload ===" && grep -rin "upload" /media/kastawan/.../MMX-Clone/*.md | head -40
=== readlink both paths ===
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone
/home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone
=== look for upload dirs ===
/home/kastawan/MEGAsync/GloboNotes/.globonote/attachments
/home/kastawan/.config/discord/Crashpad/attachments
/home/kastawan/.config/ai.opencode.desktop/Crashpad/attachments
/home/kastawan/.config/google-chrome/Crash Reports/attachments
/home/kastawan/.config/pygpt-net/upload
/home/kastawan/.config/Codex/Crashpad/attachments
/home/kastawan/.config/opera/Crashpad/attachments
/home/kastawan/.config/Joplin/Crashpad/attachments
/home/kastawan/.config/marktext/Crashpad/attachments
/home/kastawan/.config/terabox/tmp/uploadcfgs
/home/kastawan/.config/Claude/Crashpad/attachments
/home/kastawan/.config/TeraBox/Crashpad/attachments
/home/kastawan/.config/google-chrome/Crash Reports/attachments
=== grep HANDOFF for upload ===
./Lazarus-MMX-Style-Code-Explorer-Milestone-Plan.md:6:- MMX user manual (PDF, uploaded): mmxmanual.pdf
```

```console
$ echo "=== broader search for files containing 'unit CodeExplorer' ===" && grep -rl "unit CodeExplorer" /media/kastawan /home/kastawan /tmp/opencode 2>/dev/null | head -40 && echo "=== stat inodes both paths ===" && stat -c '%i %n' ... 
Command exceeded timeout of 120000 ms. Retry with a larger timeout if the command is expected to take longer.
Timed out before completion
```

```console
$ echo "=== parent Output dir ===" && ls -la /media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/ && echo "=== /tmp/opencode ===" && ls -la /tmp/opencode 2>/dev/null | head -40 && echo "=== stat inodes both feasibility copies ===" && stat -c '%i %n' /media/.../M3-FEASIBILITY-CODEEXPLORER-PORT.md /home/kastawan/MEGAsync/.../M3-FEASIBILITY-CODEEXPLORER-PORT.md
=== /tmp/opencode ===
total 492
drwxrwxr-x  2 kastawan kastawan    180 Nov 18 18:49 .
drwxrwxrwt 64 root     root      10860 Nov 19 07:54 ..
-rwxrwxr-x  1 kastawan kastawan 232240 Nov 18 18:41 fpc_hello_test
-rw-rw-r--  1 kastawan kastawan   4000 Nov 18 18:41 fpc_hello_test.o
-rw-rw-r--  1 kastawan kastawan     56 Nov 18 18:41 fpc_hello_test.pas
-rwxrwxr-x  1 kastawan kastawan 236368 Nov 18 18:42 fpc_hello_test2
-rw-rw-r--  1 kastawan kastawan   4160 Nov 18 18:42 fpc_hello_test2.o
-rw-rw-r--  1 kastawan kastawan     58 Nov 18 18:42 fpc_hello_test2.pas
-rw-rw-r--  1 kastawan kastawan  10368 Nov 18 19:03 lazarus_monitoroff.log
=== stat inodes both feasibility copies ===
1074 /media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/M3-FEASIBILITY-CODEEXPLORER-PORT.md
1074 /home/kastawan/MEGAsync/@OpenCode/Output/MMX-Clone/M3-FEASIBILITY-CODEEXPLORER-PORT.md
```
(The parent-directory listing was truncated by the tool; full output was saved
at
`/home/kastawan/.local/share/opencode/shell/7ec95c4c3fd1c1a81b1af4e81e0de54c8353dc55/sh_1f1160ad8001K6CBpin4sC4wQ7.out`.)

```console
$ cd ... && echo "=== grep md files for upload paths ===" && grep -rinE 'upload|Downloads|/tmp/|\.pas.*copied|uploaded' --include='*.md' . | head -60 && echo "=== git log --all --stat ===" && git log --all --oneline -12
=== grep md files for upload paths ===
./M3-FEASIBILITY-CODEEXPLORER-PORT.md:210:| `codeexplopts.pas` (925) | **rewrite** (or copy with ~90 replacements) | **~200–250 new lines** (≈90 if copied) |
./Lazarus-MMX-Style-Code-Explorer-Milestone-Plan.md:6:- MMX user manual (PDF, uploaded): mmxmanual.pdf
=== git log --all --stat ===
01f3102 Refresh method list after edits and clean up on editor destroy
b205082 Store line numbers per combobox item for jumps
be687d0 Show owning class in method list and fix filter jump
8fb316d Merge pull request #1 from wp-xyz/main
c9838db Use auxiliary panel to center the "Methods" label vertically. Move panel with label and combobox to the left to avoid jumping there when a new tool button is added.
b1d358e Removed DebugLog and replaced by standard DebugLn (unit LazLoggerBase; use cmdline argument "--debug-log=filename" to create log file). Prepended each debug message by "[TCodeAnalyzerPlugin]" to identify the source of the message.
465da3d Update .gitignore
b9373a6 Change Author values
aef7c12 Update README.md
39d9784 Change package name
4c79a34 Update combo.dropdowcount
dc4ac4d Update README.md
```

```console
$ echo "=== name-only search for codeexplorer*pas / codeexplopts*pas across likely roots ===" && find /media/kastawan/Kingston250-SSD/MEGAsync /home/kastawan -type f \( -iname 'codeexplorer.pas' -o -iname 'codeexplorer.lfm' -o -iname 'codeexplopts.pas' \) 2>/dev/null | sort && echo "=== git status showing untracked codeexplorer files ===" && cd ... && git status --short --untracked-files=all | grep -i codeexpl
=== name-only search for codeexplorer*pas / codeexplopts*pas across likely roots ===
/home/kastawan/FPC-Deluxe/lazarus/ide/codeexplopts.pas
/home/kastawan/FPC-Deluxe/lazarus/ide/codeexplorer.lfm
/home/kastawan/FPC-Deluxe/lazarus/ide/codeexplorer.pas
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk2/codeexplorer.lfm
/home/kastawan/FPC-Deluxe/lazarus/units/x86_64-linux/gtk3/codeexplorer.lfm
=== git status showing untracked codeexplorer files ===
?? M3-FEASIBILITY-CODEEXPLORER-PORT.md
?? WKCodeExplorer/WKCodeExplOpts.pas
?? WKCodeExplorer/WKCodeExplorer.lfm
?? WKCodeExplorer/WKCodeExplorer.lpk
?? WKCodeExplorer/WKCodeExplorer.pas
```

```console
$ echo "=== search opencode storage for uploaded codeexplorer files ===" && find /home/kastawan/.local/share/opencode /home/kastawan/.config/opencode /home/kastawan/.config/ai.opencode.desktop -type f \( -iname '*codeexplor*' -o -iname '*codeexplopt*' \) 2>/dev/null | head -40 && echo "=== search for any file named codeexplorer*.pas in FPC-Deluxe parent ===" && find /home/kastawan/FPC-Deluxe -maxdepth 2 -type f -iname 'codeexplor*' 2>/dev/null | head -40
=== search opencode storage for uploaded codeexplorer files ===
=== search for any file named codeexplorer*.pas in FPC-Deluxe parent ===
/home/kastawan/FPC-Deluxe/config_lazarus/codeexploreroptions.xml
```

**Conclusion of the upload search:** no uploaded copies of `codeexplorer.pas`
or `codeexplopts.pas` exist anywhere on disk. The `diff` against "the uploads"
could therefore not be performed; see section (e).

### 5. Source analysis commands

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus/ide && echo "=== TCodeExplorerView occurrences count ===" && grep -c "TCodeExplorerView" codeexplorer.pas && echo "=== lis/dlg identifiers used ===" && grep -oE '\b(lis[A-Za-z0-9_]+|dlg[A-Za-z0-9_]+)\b' codeexplorer.pas | sort | uniq -c | sort -rn && echo "=== NonModalIDEWindowNames ===" && grep -n "NonModalIDEWindowNames" codeexplorer.pas && echo "=== command IDs / RegisterIDEMenuCommand / IDECommand ===" && grep -nE 'Command|RegisterIDE|IDEMenuCommand|cec[a-zA-Z]+Command|CreateIDECommand' codeexplorer.pas | head -120
=== TCodeExplorerView occurrences count ===
117
=== lis/dlg identifiers used ===
      3 dlgUnitDepRefresh
      2 lisOptions
      2 lisCEIn
      2 lisCEFilter
      1 lists
      1 lisTreeNeedsRefresh
      1 lisShowPositionOfSourceEditor
      1 lisRename
      1 lisMenuViewCodeExplorer
      1 lisMenuJumpToImplementation
      1 lisMenuJumpTo
      1 lisDirectives
      1 lisCodeObserver
      1 lisCode
      1 lisCESurrounding
      1 lisCEModeShowSourceNodes
      1 lisCEModeShowCategories
      1 lisCCOErrorCaption
=== NonModalIDEWindowNames ===
477:  Name:=NonModalIDEWindowNames[nmiwCodeExplorer];
=== command IDs / RegisterIDEMenuCommand / IDECommand ===
52:  LazIDEIntf, IDECommands, MenuIntf, SrcEditorIntf, IDEDialogs, IDEImagesIntf,
166:    FCodeCmd1, FCodeCmd2, FCodeCmd3: TIDECommand;
296:  CEJumpToIDEMenuCommand: TIDEMenuCommand;
297:  CEJumpToImplementationIDEMenuCommand: TIDEMenuCommand;
298:  CEShowSrcEditPosIDEMenuCommand: TIDEMenuCommand;
299:  CERefreshIDEMenuCommand: TIDEMenuCommand;
300:  CERenameIDEMenuCommand: TIDEMenuCommand;
385:  CodeExplorerMenuRoot:=RegisterIDEMenuRoot(CodeExplorerMenuRootName);
387:  CEJumpToIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'Jump to', lisMenuJumpTo);
388:  CEJumpToImplementationIDEMenuCommand:=RegisterIDEMenuCommand(Path,
390:  CEShowSrcEditPosIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'Show position of source editor',
392:  CERefreshIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'Refresh', dlgUnitDepRefresh);
393:  CERenameIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'Rename', lisRename);
504:  CEJumpToIDEMenuCommand.OnClick:=@JumpToMenuItemClick;
505:  CEJumpToImplementationIDEMenuCommand.OnClick:=@JumpToImplementationMenuItemClick;
506:  CEShowSrcEditPosIDEMenuCommand.OnClick:=@ShowSrcEditPosMenuItemClick;
507:  CERefreshIDEMenuCommand.OnClick:=@RefreshMenuItemClick;
508:  CERenameIDEMenuCommand.OnClick:=@RenameMenuItemClick;
570:  FCodeCmd1:=IDECommandList.FindIDECommand(ecFindDeclaration);
571:  FCodeCmd2:=IDECommandList.FindIDECommand(ecFindProcedureDefinition);
572:  FCodeCmd3:=IDECommandList.FindIDECommand(ecFindProcedureMethod);
670:  ExecuteIDECommand(SourceEditorManagerIntf.ActiveSourceWindow, ecRenameIdentifier);
706:  CERenameIDEMenuCommand.Visible:=CanRename;
707:  CEJumpToImplementationIDEMenuCommand.Visible:=HasImplementation;
708:  //DebugLn(['TCodeExplorerView.TreePopupmenuPopup ',CERenameIDEMenuCommand.Visible]);
```

`read: codeexplorer.pas` lines 1–140, 280–529, 1960–1999 — used clause,
class declaration, menu registration, constructor, `SetMode`/`UpdateCaption`.

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus/ide && echo "=== CodeExplorerOptions reads ===" && grep -n "CodeExplorerOptions" codeexplorer.pas && echo "=== TCodeExplorer* type uses ===" && grep -nE '\b(TCodeExplorerOptions|...|cefc[A-Z])' codeexplorer.pas | head -160
=== CodeExplorerOptions reads ===
737:  CodeExplorerOptions.Page:=cepCode;
740:  if CodeExplorerOptions.Refresh=cerOnIdle then
1095:          ShowNode:=Category in CodeExplorerOptions.Categories;
1303:  ObserverCats:=CodeExplorerOptions.ObserverCategories;
1314:            if LineCnt>=CodeExplorerOptions.LongProcLineCount then
1368:            if i>=CodeExplorerOptions.NestedProcCount then begin
1378:          and (CodeNode.ChildCount>CodeExplorerOptions.LongParamListCount) then
1574:  CheckWrongIndentation:=cefcWrongIndentation in CodeExplorerOptions.ObserverCategories;
1575:  FindUnnamedConstants:=cefcUnnamedConsts in CodeExplorerOptions.ObserverCategories;
1609:        and (not CodeExplorerOptions.ObserveCharConst) then
1612:        end else if CodeExplorerOptions.COIgnoreConstant(@Tool.Src[Tool.CurPos.StartPos])
1665:          if CodeExplorerOptions.COIgnoreConstInFunc(FuncName) then
1989:  if (CodeExplorerOptions.Refresh=cerManual) and (FCodeFilename<>'') then
2099:      or (not (cecSurrounding in CodeExplorerOptions.Categories));
2225:      end else if (fLastCodeOptionsChangeStep<>CodeExplorerOptions.ChangeStep) then begin
2226:        //debugln(['TCodeExplorerView.RefreshCode Options changed ',fLastCodeOptionsChangeStep,' ',CodeExplorerOptions.ChangeStep])
2230:        if not CodeExplorerOptions.FollowCursor then
2248:      fLastCodeOptionsChangeStep:=CodeExplorerOptions.ChangeStep;
2265:      CurFollowNode:=CodeExplorerOptions.FollowCursor and (not Active);
2279:          if (cecCodeObserver in CodeExplorerOptions.Categories) then
2281:          if (cecSurrounding in CodeExplorerOptions.Categories) then
2610:  if CodeExplorerOptions.Refresh=cerSwitchEditorPage then
=== TCodeExplorer* type uses ===
164:    fCategoryNodes: array[TCodeExplorerCategory] of TTreeNode;
177:    FLastMode: TCodeExplorerMode;
178:    FMode: TCodeExplorerMode;
179:    fObserverCatNodes: array[TCEObserverCategory] of TTreeNode;
180:    fObserverCatOverflow: array[TCEObserverCategory] of boolean;
220:    function GetCurrentPage: TCodeExplorerPage;
237:    function CreateObserverNode(Tool: TCodeTool; f: TCEObserverCategory): TTreeNode;
245:    procedure SetCurrentPage(const AValue: TCodeExplorerPage);
247:    procedure SetMode(AMode: TCodeExplorerMode);
280:    property Mode: TCodeExplorerMode read FMode write SetMode;
286:    property CurrentPage: TCodeExplorerPage read GetCurrentPage
... (tool truncated the remaining lines; full output saved to
/home/kastawan/.local/share/opencode/shell/7ec95c4c3fd1c1a81b1af4e81e0de54c8353dc55/sh_1f1174aaa001dOgNq4SAU1dqsT.out)
```

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus/ide && echo "=== possible opts identifiers in codeexplorer.pas ===" && grep -nE '\b(cefcAll|FirstCodeExplorerCategory|DefaultCodeExplorerCategories|...|IncreaseChangeStep)\b' codeexplorer.pas
=== possible opts identifiers in codeexplorer.pas ===
(no output; grep exit status 1)
```

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus/ide && echo "=== all-caps identifiers starting with ec/nmiw/Group ===" && grep -oE '\b(ec[A-Z][A-Za-z0-9_]*|nmiw[A-Za-z0-9_]*|Group[A-Z][A-Za-z0-9_]*)\b' codeexplorer.pas | sort | uniq -c && echo "=== IDE command creation refs ===" && grep -nE 'IDECommandList|CreateIDECommand|TIDECommand|ecFind|ecRename|ExecuteIDECommand|FindIDECommand' codeexplorer.pas
=== all-caps identifiers starting with ec/nmiw/Group ===
      1 ecFindDeclaration
      1 ecFindProcedureDefinition
      1 ecFindProcedureMethod
      1 ecRenameIdentifier
      1 nmiwCodeExplorer
=== IDE command creation refs ===
166:    FCodeCmd1, FCodeCmd2, FCodeCmd3: TIDECommand;
570:  FCodeCmd1:=IDECommandList.FindIDECommand(ecFindDeclaration);
571:  FCodeCmd2:=IDECommandList.FindIDECommand(ecFindProcedureDefinition);
572:  FCodeCmd3:=IDECommandList.FindIDECommand(ecFindProcedureMethod);
670:  ExecuteIDECommand(SourceEditorManagerIntf.ActiveSourceWindow, ecRenameIdentifier);
```

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && echo "=== lis* definitions ===" && grep -rnE "lisCCOErrorCaption|lisCEFilter|...|lisCEIn\b" ide/lazarusidestrconsts.pas ide/packages/ideconfig/ideconfstrconsts.pas ide/packages/idepackager/idepackagerstrconsts.pas 2>/dev/null | head -80
=== lis* definitions ===
ide/lazarusidestrconsts.pas:50:  lisRename = 'Rename';
ide/lazarusidestrconsts.pas:98:  lisOptions = 'Options';
ide/lazarusidestrconsts.pas:341:  lisMenuViewCodeExplorer = 'Code Explorer';
ide/lazarusidestrconsts.pas:345:  lisMenuJumpTo = 'Jump to';
ide/lazarusidestrconsts.pas:348:  lisMenuJumpToImplementation = 'Jump to Implementation';
ide/lazarusidestrconsts.pas:349:  lisMenuJumpToImplementationUses = 'Jump to Implementation uses';
ide/lazarusidestrconsts.pas:2583:  lisTreeNeedsRefresh = 'Tree needs refresh';
ide/lazarusidestrconsts.pas:2848:  lisCEFilter = '(filter)';
ide/lazarusidestrconsts.pas:2931:  lisCode = 'Code';
ide/lazarusidestrconsts.pas:3546:  dlgUnitDepRefresh      = 'Refresh';
ide/lazarusidestrconsts.pas:5075:  lisCEModeShowCategories = 'Show Categories';
ide/lazarusidestrconsts.pas:5076:  lisCEModeShowSourceNodes = 'Show Source Nodes';
ide/lazarusidestrconsts.pas:5077:  lisCESurrounding = 'Surrounding';
ide/lazarusidestrconsts.pas:5094:  lisCodeObserver = 'Code Observer';
ide/lazarusidestrconsts.pas:5687:  lisDirectivesForNewUnit = 'Directives for new unit';
ide/lazarusidestrconsts.pas:5779:  lisShowPositionOfSourceEditor = 'Show position of source editor';
ide/lazarusidestrconsts.pas:5863:  lisDirectives = 'Directives';
ide/packages/ideconfig/ideconfstrconsts.pas:238:  lisCCOErrorCaption = 'Error';
ide/packages/idepackager/idepackagerstrconsts.pas:48:  lisCEIn = '%s in %s';
```

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -nE "lisCEUses|lisCETypes|...|lisCEToDos" ide/lazarusidestrconsts.pas | head -40
5087:  lisCEUses = 'Uses';
5089:  lisCETypes = 'Types';
5090:  lisCEVariables = 'Variables';
5091:  lisCEConstants = 'Constants';
5092:  lisCEProcedures = 'Procedures';
5093:  lisCEProperties = 'Properties';
5424:  lisCELongProcedures = 'Long procedures';
5425:  lisCEManyParameters = 'Many parameters';
5426:  lisCEUnnamedConstants = 'Unnamed constants';
5427:  lisCEEmptyProcedures = 'Empty procedures';
5428:  lisCEManyNestedProcedures = 'Many nested procedures';
5429:  lisCEPublishedPropertyWithoutDefault = 'Published properties without default';
5430:  lisCEUnsortedVisibility = 'Unsorted visibility';
5431:  lisCEUnsortedMembers = 'Unsorted members';
5432:  lisCEToDos = 'ToDos';
5433:  lisCEEmptyClassSections = 'Empty class sections';
5441:  lisCEEmptyBlocks = 'Empty blocks';
5446:  lisCEWrongIndentation = 'Wrong indentation';
```

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus/ide && grep -n "function CodeExplorerLocalizedString\|function dbgs\|lisCE\|dlgGroupCodeExplorer" codeexplopts.pas
285:function CodeExplorerLocalizedString(const c: TCodeExplorerCategory): string;
287:function CodeExplorerLocalizedString(const c: TCEObserverCategory): string;
288:function dbgs(c: TCodeExplorerCategory): string; overload;
320:function CodeExplorerLocalizedString(const c: TCodeExplorerCategory): string;
323:  cecUses: Result:=lisCEUses;
324:  cecTypes: Result:=lisCETypes;
325:  cecVariables: Result:=lisCEVariables;
326:  cecConstants: Result:=lisCEConstants;
327:  cecProcedures: Result:=lisCEProcedures;
328:  cecProperties: Result:=lisCEProperties;
330:  cecSurrounding: Result:=lisCESurrounding;
342:function CodeExplorerLocalizedString(const c: TCEObserverCategory): string;
345:  cefcLongProcs: Result:=lisCELongProcedures;
346:  cefcLongParamLists: Result:=lisCEManyParameters;
347:  cefcEmptyProcs: Result:=lisCEEmptyProcedures;
348:  cefcNestedProcs: Result:=lisCEManyNestedProcedures;
349:  cefcUnnamedConsts: Result:=lisCEUnnamedConstants;
350:  cefcEmptyBlocks: Result:=lisCEEmptyBlocks;
351:  cefcWrongIndentation: Result:=lisCEWrongIndentation;
352:  cefcPublishedPropWithoutDefault: Result:=lisCEPublishedPropertyWithoutDefault;
353:  cefcUnsortedClassVisibility: Result:=lisCEUnsortedVisibility;
354:  cefcEmptyClassSections: Result:=lisCEEmptyClassSections;
355:  cefcUnsortedClassMembers: Result:=lisCEUnsortedMembers;
356:  cefcToDos: Result:=lisCEToDos;
361:function dbgs(c: TCodeExplorerCategory): string;
473:  Result := dlgGroupCodeExplorer;
```

`read: codeexplopts.pas` lines 1–180, 180–319, 440–609, 610–749, 750–925, 318–377 — full interface and implementation.

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -rn "function CompareAtom" components/codetools/basiccodetools.pas | head -10
187:function CompareAtom(p1, p2: PChar; NestedComments: boolean): integer;
4656:function CompareAtom(p1, p2: PChar; NestedComments: boolean): integer;
```

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -nE "constructor Create|procedure Flush|procedure SetDeleteValue|function GetValue" components/lazutils/laz2_xmlcfg.pas | head -30
99:    constructor Create(AOwner: TComponent); override; overload;
100:    constructor Create(const AFilename: String); overload; // create and load
101:    constructor CreateClean(const AFilename: String); // create new
102:    constructor CreateWithSource(const AFilename, Source: String); // create new and load from Source
105:    procedure Flush;    // Writes the XML file
119:    procedure SetDeleteValue(const APath, AValue, DefValue: String);
121:    procedure SetDeleteValue(const APath: String; AValue, DefValue: Int64);
123:    procedure SetDeleteValue(const APath: String; AValue, DefValue: Boolean);
126:    procedure SetDeleteValue(const APath: String; const AValue, DefValue: TRect);
133:    procedure SetDeleteValue(const APath: String; const AValue, DefValue; const APTypeInfo: PTypeInfo);
134:    procedure SetDeleteValue(const APath: String; const AValue; DefValue: Int64; const APTypeInfo: PTypeInfo);
135:    procedure SetDeleteValue(const APath: String; const {%H-}AValue; const APTypeInfo: PTypeInfo);
```

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -rn "ecFindDeclaration\s*=\|ecRenameIdentifier\s*=\|ecFindProcedureDefinition\s*=" components/ideintf ide --include='*.pas' | head -20
components/ideintf/idecommands.pas:64:  ecFindProcedureDefinition = ecFirstLazarus + 6;
components/ideintf/idecommands.pas:81:  ecFindDeclaration         = ecFirstLazarus + 30;
components/ideintf/idecommands.pas:154:  ecRenameIdentifier        = ecFirstLazarus + 116;
ide/lazarusidestrconsts.pas:3303:  srkmecFindProcedureDefinition   = 'Find Procedure Definiton';
ide/lazarusidestrconsts.pas:3357:  srkmecRenameIdentifier          = 'Rename Identifier';
ide/lazarusidestrconsts.pas:3363:  srkmecFindDeclaration           = 'Find Declaration';
```

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus/ide && echo "=== lis/dlg usage lines ===" && grep -nE '\b(lis[A-Za-z0-9_]+|dlg[A-Za-z0-9_]+)\b' codeexplorer.pas | grep -v 'lists'
387:  CEJumpToIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'Jump to', lisMenuJumpTo);
389:    'Jump to implementation', lisMenuJumpToImplementation);
391:    lisShowPositionOfSourceEditor);
392:  CERefreshIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'Refresh', dlgUnitDepRefresh);
393:  CERenameIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'Rename', lisRename);
485:  CodePage.Caption:=lisCode;
486:  CodeRefreshSpeedButton.Hint:=dlgUnitDepRefresh;
487:  CodeOptionsSpeedButton.Hint:=lisOptions;
489:  DirectivesPage.Caption:=lisDirectives;
491:  DirRefreshSpeedButton.Hint:=dlgUnitDepRefresh;
492:  DirOptionsSpeedButton.Hint:=lisOptions;
493:  CodeFilterEdit.TextHint:=lisCEFilter;
494:  DirectivesFilterEdit.TextHint:=lisCEFilter;
666:    IDEMessageDialog(lisCCOErrorCaption, lisTreeNeedsRefresh, mtError, [mbOk]);
1466:      fObserverNode:=CodeTreeview.Items.Add(nil, lisCodeObserver);
1554:            NodeText:=Format(lisCEIn, [NodeText, Tool.ExtractProcName(ProcNode, [
1635:              NodeText:=Format(lisCEIn, [NodeText, Tool.ExtractProcName(ProcNode, [
1879:    fSurroundingNode:=CodeTreeview.Items.Add(nil, lisCESurrounding);
1975:    CodeModeSpeedButton.Hint:=lisCEModeShowSourceNodes;
1979:    CodeModeSpeedButton.Hint:=lisCEModeShowCategories;
1988:  s:=lisMenuViewCodeExplorer;
```

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus/ide && echo "=== tail of codeexplorer.pas ===" && tail -n 30 codeexplorer.pas && echo "=== Register / initialization ===" && grep -nE '\bRegister\b|initialization|finalization|RegisterStandardCodeExplorerMenuItems|RegisterPackage' codeexplorer.pas
=== tail of codeexplorer.pas ===
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

end.
=== Register / initialization ===
302:procedure RegisterStandardCodeExplorerMenuItems;
381:procedure RegisterStandardCodeExplorerMenuItems;
```

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -rn "RegisterStandardCodeExplorerMenuItems" --include='*.pas' --include='*.pp' --include='*.inc' . | head -20
./ide/codeexplorer.pas:302:procedure RegisterStandardCodeExplorerMenuItems;
./ide/codeexplorer.pas:381:procedure RegisterStandardCodeExplorerMenuItems;
./ide/main.pp:2730:  RegisterStandardCodeExplorerMenuItems;
```

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -rn "CodeExplorerMenuRoot" --include='*.pas' --include='*.inc' --include='*.reg' . | head -30
./ide/codeexplorer.pas:291:  CodeExplorerMenuRootName = 'Code Explorer';
./ide/codeexplorer.pas:385:  CodeExplorerMenuRoot:=RegisterIDEMenuRoot(CodeExplorerMenuRootName);
./ide/codeexplorer.pas:386:  Path:=CodeExplorerMenuRoot.Name;
./ide/codeexplorer.pas:501:  CodeExplorerMenuRoot.MenuItem:=TreePopupMenu.Items;
./ide/codeexplorer.pas:502:  //CodeExplorerMenuRoot.Items.WriteDebugReport(' ');
./components/ideintf/menuintf.pas:386:  CodeExplorerMenuRoot: TIDEMenuSection = nil;
```

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -nE "function RegisterIDEMenuRoot|function RegisterIDEMenuCommand|CodeExplorerMenuRoot" components/ideintf/menuintf.pas | head -30
386:  CodeExplorerMenuRoot: TIDEMenuSection = nil;
434:function RegisterIDEMenuRoot(const Name: string; MenuItem: TMenuItem = nil
450:function RegisterIDEMenuCommand(Parent: TIDEMenuSection;
458:function RegisterIDEMenuCommand(const Path, Name, Caption: string;
468:function RegisterIDEMenuRoot(const Name: string; MenuItem: TMenuItem
520:function RegisterIDEMenuCommand(Parent: TIDEMenuSection;
543:function RegisterIDEMenuCommand(const Path, Name, Caption: string;
```
`read: menuintf.pas` lines 430–469 — confirmed `RegisterIDEMenuCommand(const Path, Name, Caption, ...)`: the 2nd argument is the internal command name.

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus/ide && echo "TCodeExplorerView in lfm:" && grep -n "TCodeExplorerView" codeexplorer.lfm && echo "TCodeExplorerView in pas (first 20):" && grep -n "TCodeExplorerView" codeexplorer.pas | head -20 && echo "total in pas:" && grep -c "TCodeExplorerView" codeexplorer.pas
TCodeExplorerView in lfm:
1:object CodeExplorerView: TCodeExplorerView
TCodeExplorerView in pas (first 20):
61:  TCodeExplorerView = class;
68:  TCodeExplorerViewFlag = (
74:  TCodeExplorerViewFlags = set of TCodeExplorerViewFlag;
117:  { TCodeExplorerView }
119:  TCodeExplorerView = class(TForm)
168:    FFlags: TCodeExplorerViewFlags;
295:  CodeExplorerView: TCodeExplorerView = nil;
470:{ TCodeExplorerView }
472:procedure TCodeExplorerView.CodeExplorerViewCreate(Sender: TObject);
516:procedure TCodeExplorerView.CodeExplorerViewDestroy(Sender: TObject);
518:  //debugln('TCodeExplorerView.CodeExplorerViewDestroy');
526:procedure TCodeExplorerView.CodeFilterEditChange(Sender: TObject);
531:procedure TCodeExplorerView.CodeTreeviewMouseDown(Sender: TObject;
545:procedure TCodeExplorerView.DirectivesFilterEditChange(Sender: TObject);
550:procedure TCodeExplorerView.DirRefreshSpeedButtonClick(Sender: TObject);
556:procedure TCodeExplorerView.FilterEditButtonClick(Sender: TObject);
562:procedure TCodeExplorerView.FilterEditEnter(Sender: TObject);
567:procedure TCodeExplorerView.FormActivate(Sender: TObject);
569:  //DebugLn(['TCodeExplorerView.FormActivate!']);
575:procedure TCodeExplorerView.IdleTimer1Timer(Sender: TObject);
total in pas:
117
```

```console
$ echo "=== ~/Downloads and common upload spots ===" && ls -la /home/kastawan/Downloads 2>/dev/null | head -30 && find /home/kastawan/Downloads /home/kastawan/Desktop /tmp -maxdepth 3 -type f \( -iname '*codeexplor*' -o -iname '*CodeExpl*' \) 2>/dev/null | head -30
=== ~/Downloads and common upload spots ===
total 4676512
-rw-rw-r--   1 kastawan kastawan         0 Sep  4 20:58 <non-UTF8 filename>
drwxr-xr-x  41 kastawan kastawan     49152 Nov 18 20:10 .
drwxr-x---+ 69 kastawan kastawan      4096 Nov 19 07:51 ..
-rw-------  1 kastawan kastawan    224949 Mar  6  2026 .org.chromium.Chromium.5UxGV7
-rw-------  1 kastawan kastawan    22700 Jun 29  2026 .org.chromium.Chromium.AuyQ6m
-rw-------  1 kastawan kastawan    248338 Mar 31  2026 .org.chromium.Chromium.EHTzQ
... (listing truncated by head -30; no codeexplorer files)
```

```console
$ echo "=== hidden dirs in repo ===" && find /media/kastawan/.../MMX-Clone -maxdepth 2 -type d -name '.*' | head -20 && echo "=== any file named *upload* under repo/home opencode ===" && find /media/kastawan/.../MMX-Clone /home/kastawan/.local/share/opencode -iname '*upload*' 2>/dev/null | head -20
=== hidden dirs in repo ===
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/.git
=== any file named *upload* under repo/home opencode ===
(no output)
```

### 6. Applying the port

`write: /tmp/opencode/do_wk_port.py` — transformation script (unit rename,
`{$I ide.inc}` replacement, uses cleanup, local constants, WK menu names,
window name, local menu-root variable, `Register` + lifecycle, class rename;
plus the `.lfm` class rename). Script text is reproduced in section (c).

```console
$ python3 /tmp/opencode/do_wk_port.py
Wrote WKCodeExplorer.pas (100687 bytes), WKCodeExplorer.lfm (7081 bytes)
```

`write: WKCodeExplorer/WKCodeExplOpts.pas` — new plain settings unit.
Three targeted `edit:` calls followed: remove a leftover placeholder block,
add `i: integer` to `Load`, and load default ignore lists when the XML has no
entries.

`write: WKCodeExplorer/WKCodeExplorer.lpk` — package definition.

```console
$ cd .../WKCodeExplorer && echo "=== residual internal units/identifiers ===" && grep -nE 'IdeConfStrConsts|IdePackagerStrConsts|LazarusIDEStrConsts|IDEOptionDefs|ide\.inc|NonModalIDEWindowNames|nmiwCodeExplorer|CodeExplOpts;|TCodeExplorerView' WKCodeExplorer.pas WKCodeExplorer.lfm || echo "(none)" && echo "=== new class name count ===" && grep -c 'TWKCodeExplorerView' WKCodeExplorer.pas && grep -n 'TWKCodeExplorerView' WKCodeExplorer.lfm && echo "=== WK command names ===" && grep -nE "RegisterIDEMenuCommand|MenuRootName|MenuRoot:" WKCodeExplorer.pas | head -20
=== residual internal units/identifiers ===
WKCodeExplorer.pas:55:  WKCodeExplOpts;
WKCodeExplorer.pas:59:    LazarusIDEStrConsts, IdeConfStrConsts and IdePackagerStrConsts. }
=== new class name count ===
117
1:object CodeExplorerView: TWKCodeExplorerView
=== WK command names ===
309:  WKWKCodeExplorerMenuRootName = 'Code Explorer';
314:  WKCodeExplorerMenuRoot: TIDEMenuSection = nil;
404:  WKCodeExplorerMenuRoot:=RegisterIDEMenuRoot(WKWKCodeExplorerMenuRootName);
406:  WKCEJumpToIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'WKJumpTo', lisMenuJumpTo);
407:  WKCEJumpToImplementationIDEMenuCommand:=RegisterIDEMenuCommand(Path,
409:  WKCEShowSrcEditPosIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'WKShowSrcEditPos',
411:  WKCERefreshIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'WKRefresh', dlgUnitDepRefresh);
412:  WKCERenameIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'WKRename', lisRename);
```
This exposed a bug in my rename script (a double `WKWK` prefix and the root
name still being the IDE's `'Code Explorer'`). Fixed as follows:

```console
$ cd .../WKCodeExplorer && sed -i "s/WKWKCodeExplorerMenuRootName/WKCodeExplorerMenuRootName/g; s/WKCodeExplorerMenuRootName = 'Code Explorer'/WKCodeExplorerMenuRootName = 'WK Code Explorer'/" WKCodeExplorer.pas && grep -nE 'MenuRootName|MenuRoot:|RegisterIDEMenuRoot' WKCodeExplorer.pas | head -10
309:  WKCodeExplorerMenuRootName = 'WK Code Explorer';
314:  WKCodeExplorerMenuRoot: TIDEMenuSection = nil;
404:  WKCodeExplorerMenuRoot:=RegisterIDEMenuRoot(WKCodeExplorerMenuRootName);
```

`read: WKCodeExplorer.pas` lines 30–79 and tail — verified header, constants
and lifecycle block.

### 7. Build attempts

```console
$ cd ... && which lazbuild && lazbuild WKCodeExplorer/WKCodeExplorer.lpk 2>&1
lazbuild not found
```
Exit status 1. `lazbuild` is not on PATH.

```console
$ echo "=== find lazbuild ===" && find /home/kastawan /usr/local /opt -maxdepth 5 -type f -name 'lazbuild' 2>/dev/null | head -20 && echo "=== PATH ===" && echo "$PATH"
=== find lazbuild ===
/home/kastawan/FPC-Deluxe/lazarus/lazbuild
=== PATH ===
/home/kastawan/.local/share/pnpm/bin:/home/kastawan/.bun/bin:/media/kastawan/Kingston250-SSD/Android/Sdk/platform-tools/:/home/kastawan/.nvm/versions/node/v24.21.0/bin:/home/kastawan/bin:/home/kastawan/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
```

```console
$ cd ... && /home/kastawan/FPC-Deluxe/lazarus/lazbuild WKCodeExplorer/WKCodeExplorer.lpk 2>&1
Hint: (lazbuild) Opt: "primary-config-path=/home/kastawan/FPC-Deluxe/config_lazarus"
Hint: (lazarus) SetPrimaryConfigPath NewValue="/home/kastawan/FPC-Deluxe/config_lazarus"
Hint: (lazbuild) Primary config path: "/home/kastawan/FPC-Deluxe/config_lazarus"
Hint: (lazarus) [TBuildManager.SetBuildTarget] Old=x86_64-linux--gtk3 New=x86_64-linux--gtk3 Changed: OS/CPU=True LCL=False
Hint: (lazbuild) Compile package ".../WKCodeExplorer/WKCodeExplorer.lpk"
Hint: (lazarus) source disk file modified of WKCodeExplorer 0.0: .../WKCodeExplorer/WKCodeExplorer.pas
Info: (lazarus) Execute Title="Compile package WKCodeExplorer 0.0"
Info: (lazarus) Working Directory=".../WKCodeExplorer/"
Info: (lazarus) Executable="/home/kastawan/FPC-Deluxe/fpc/bin/x86_64-linux/fpc.sh"
Info: (lazarus) Param[0]="-MObjFPC"
... (25 compiler params)
Hint: (11030) Start of reading config file .../fpc.cfg
Hint: (11031) End of reading config file .../fpc.cfg
Free Pascal Compiler version 3.3.1-21799-g7cfa194418-dirty [2026/11/12] for x86_64
Copyright (c) 1993-2026 by Florian Klaempfl and others
(1002) Target OS: Linux for x86-64
(3104) Compiling WKCodeExplorer.pas
(3104) Compiling WKCodeExplOpts.pas
.../WKCodeExplOpts.pas(284,18) Warning: (6018) Unreachable code
(1008) 579 lines compiled, 0.1 sec
(1021) 1 warning(s) issued
(1022) 2 hint(s) issued
```
This "success" was misleading: Lazarus had **regenerated** the package main
source, overwriting the ported `WKCodeExplorer.pas` with a 22-line stub (only
579 lines compiled). Investigated with:

```console
$ cd .../WKCodeExplorer && wc -l WKCodeExplorer.pas WKCodeExplOpts.pas WKCodeExplorer.lfm WKCodeExplorer.lpk && ls -l lib/x86_64-linux/
   22 WKCodeExplorer.pas
  555 WKCodeExplOpts.pas
  234 WKCodeExplorer.lfm
   58 WKCodeExplorer.lpk
  869 total
total 352
-rw-rw-r-- 1 kastawan kastawan 293368 Nov 19 08:01 WKCodeExplOpts.o
-rw-rw-r-- 1 kastawan kastawan  47097 Nov 19 08:01 WKCodeExplOpts.ppu
-rw-rw-r-- 1 kastawan kastawan   4640 Nov 19 08:01 WKCodeExplorer.o
-rw-rw-r-- 1 kastawan kastawan    945 Nov 19 08:01 WKCodeExplorer.ppu
-rw-rw-r-- 1 kastawan kastawan   1283 Nov 19 08:01 wkcodeexplorer.compiled
```

`read: WKCodeExplorer.pas` — confirmed it was the auto-generated stub.

```console
$ cd /home/kastawan/FPC-Deluxe/lazarus && grep -rn "This file was automatically created by Lazarus" --include='*.pas' --include='*.inc' . | head -20
./packager/registration/fcllaz.pas:1:{ This file was automatically created by Lazarus. Do not edit!
... (list truncated to 20 entries)
./ide/packages/idepackager/packagesystem.pas:6124:  HeaderSrc:= '{ This file was automatically created by Lazarus. Do not edit!'+e
...
```

`read: packagesystem.pas` lines 6090–6159, 4660–4694, 6001–6045;
`read: packagedefs.pas` lines 3895–3924, 3823–3829, 1440–1464;
`grep: PkgFileTypeIdents` → `components/buildintf/packageintf.pas:46` with
values `('Unit', 'Virtual Unit', 'Main Unit', 'LFM', ...)`.
Conclusion: `SavePackageMainSource` is called on every package compile and
rewrites `APackage.GetSrcFilename` (the unit with `<Type Value="Main Unit"/>`,
or the package-named `.pas` by default). Fix: add a separate
`WKCodeExplorerRegister.pas` marked "Main Unit" so the real ported unit is
left alone.

```console
$ /home/kastawan/FPC-Deluxe/lazarus/lazbuild --help 2>&1 | head -80
lazbuild [options] <project/package filename or package name>

Parameters:
-?, -h, --help                This help message.
-B, --build-all               Build all files of project/package/IDE.
--build-twice                 Compile package twice and check if any unit was compiled again.
-r, --recursive               Apply build flags (-B) to dependencies too.
-d, --skip-dependencies       Do not compile dependencies.
... (rest of help; no option to skip main-source regeneration)
```

```console
$ cd ... && python3 /tmp/opencode/do_wk_port.py && sed -i "s/WKWKCodeExplorerMenuRootName/WKCodeExplorerMenuRootName/g; s/WKCodeExplorerMenuRootName = 'Code Explorer'/WKCodeExplorerMenuRootName = 'WK Code Explorer'/" WKCodeExplorer/WKCodeExplorer.pas && wc -l WKCodeExplorer/WKCodeExplorer.pas && grep -n 'MenuRootName' WKCodeExplorer/WKCodeExplorer.pas | head -3
Wrote WKCodeExplorer.pas (100687 bytes), WKCodeExplorer.lfm (7081 bytes)
3004 WKCodeExplorer/WKCodeExplorer.pas
309:  WKCodeExplorerMenuRootName = 'WK Code Explorer';
404:  WKCodeExplorerMenuRoot:=RegisterIDEMenuRoot(WKCodeExplorerMenuRootName);
```

`edit: /tmp/opencode/do_wk_port.py` — fold the double-prefix fix into the script.
`write: WKCodeExplorer/WKCodeExplorerRegister.pas` — package main unit stub.
`edit: WKCodeExplorer/WKCodeExplorer.lpk` — add `<Type Value="Main Unit"/>`
entry for the register unit; mark the other two units as `Unit`.

```console
$ cd ... && /home/kastawan/FPC-Deluxe/lazarus/lazbuild WKCodeExplorer/WKCodeExplorer.lpk 2>&1
... (beginning truncated by tool)
(3104) Compiling WKCodeExplorerRegister.pas
(3104) Compiling WKCodeExplorer.pas
(3104) Compiling WKCodeExplOpts.pas
.../WKCodeExplorer.pas(155,38) Hint: (5024) Parameter "Sender" not used
... (26 more 5024 hints)
.../WKCodeExplorer.pas(711,9) Warning: (6060) Case statement does not handle all possible cases
.../WKCodeExplorer.pas(1969,3) Warning: (6060) Case statement does not handle all possible cases
.../WKCodeExplorerRegister.pas(17,50) Error: (5000) Identifier not found "Register"
.../WKCodeExplorerRegister.pas(23) Fatal: (10026) There were 1 errors compiling module, stopping
Fatal: (1018) Compilation aborted
Error: .../ppcx64 returned an error exitcode
Error: (lazarus) Compile package WKCodeExplorer 0.0: stopped with exit code 1
Error: (lazbuild) "WKCodeExplorer 0.0": compilation failed
```
Exit status 2. Cause: `Register` was only in the implementation section of
`WKCodeExplorer.pas`, so `@WKCodeExplorer.Register` was not visible.
Full output was saved at
`/home/kastawan/.local/share/opencode/shell/7ec95c4c3fd1c1a81b1af4e81e0de54c8353dc55/sh_1f11e89130011LjOiLdNL67yu8.out`.

`edit: WKCodeExplorer/WKCodeExplorer.pas` — add `procedure Register;` to the
interface. `edit: /tmp/opencode/do_wk_port.py` — same fix in the script.

```console
$ cd ... && /home/kastawan/FPC-Deluxe/lazarus/lazbuild WKCodeExplorer/WKCodeExplorer.lpk 2>&1 | tail -n 20
.../WKCodeExplorer.pas(175,35) Hint: (5024) Parameter "Sender" not used
... (hints)
.../WKCodeExplorer.pas(712,9) Warning: (6060) Case statement does not handle all possible cases
.../WKCodeExplorer.pas(1970,3) Warning: (6060) Case statement does not handle all possible cases
(1008) 3027 lines compiled, 0.8 sec
(1021) 2 warning(s) issued
(1022) 27 hint(s) issued
```
Build succeeded; full log in section (d).

```console
$ cd .../WKCodeExplorer && wc -l *.pas *.lfm *.lpk && echo "=== main unit after build ===" && cat WKCodeExplorerRegister.pas && echo "=== ported unit key lines ===" && grep -nE '^unit |^procedure Register;|TWKCodeExplorerView = class|Name:=.WKCodeExplorer|WKJumpTo|WKRefresh' WKCodeExplorer.pas | head -12
   555 WKCodeExplOpts.pas
  3005 WKCodeExplorer.pas
    22 WKCodeExplorerRegister.pas
   234 WKCodeExplorer.lfm
    65 WKCodeExplorer.lpk
  3881 total
=== main unit after build ===
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
=== ported unit key lines ===
32:unit WKCodeExplorer;
79:  TWKCodeExplorerView = class;
137:  TWKCodeExplorerView = class(TForm)
322:procedure Register;
407:  WKCEJumpToIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'WKJumpTo', lisMenuJumpTo);
409:    'WKJumpToImplementation', lisMenuJumpToImplementation);
412:  WKCERefreshIDEMenuCommand:=RegisterIDEMenuCommand(Path, 'WKRefresh', dlgUnitDepRefresh);
497:  Name:='WKCodeExplorer';
2993:procedure Register;
```
The ported unit survived the build (3005 lines). Lazarus rewrote only the
small register unit, as intended.

### 8. Verification and final git status

```console
$ cd ... && echo "=== diff stat: upstream codeexplorer.pas -> ported ===" && diff -u /home/kastawan/FPC-Deluxe/lazarus/ide/codeexplorer.pas WKCodeExplorer/WKCodeExplorer.pas | grep -c '^[-+]' && echo "=== first 60 diff lines ===" && diff -u ... | head -60
337
=== first 60 diff lines ===
--- /home/kastawan/FPC-Deluxe/lazarus/ide/codeexplorer.pas	2026-11-13 10:44:47.346548892 +0800
+++ WKCodeExplorer/WKCodeExplorer.pas	2026-11-19 08:04:42.057479914 +0800
@@ -29,13 +29,14 @@
     Normally it shows the codetools nodes of the current unit in the
     source editor. If an include file is open, the corresponding unit is shown.
 }
-unit CodeExplorer;
+unit WKCodeExplorer;
 
 {$mode objfpc}{$H+}
 
 interface
 
-{$I ide.inc}
+{$inline on}
+{$warn 6058 off}
 
 uses
   // RTL+FCL
@@ -50,28 +51,45 @@
   PascalParserTool,
   // IDEIntf
   LazIDEIntf, IDECommands, MenuIntf, SrcEditorIntf, IDEDialogs, IDEImagesIntf,
-  // IdeConfig
-  IdeConfStrConsts,
-  // IdePackager
-  IdePackagerStrConsts,
-  // IDE
-  LazarusIDEStrConsts, IDEOptionDefs, CodeExplOpts;
+  // Local plain settings class (no IDE-internal units)
+  WKCodeExplOpts;
+
+const
+  { Local copies of the IDE-only string constants.  Values are taken from
+    LazarusIDEStrConsts, IdeConfStrConsts and IdePackagerStrConsts. }
+  lisCCOErrorCaption           = 'Error';
+  lisCEFilter                  = '(filter)';
+  lisCEModeShowCategories      = 'Show Categories';
+  lisCEModeShowSourceNodes     = 'Show Source Nodes';
+  lisCESurrounding             = 'Surrounding';
+  lisCode                      = 'Code';
+  lisCodeObserver              = 'Code Observer';
+  lisDirectives                = 'Directives';
+  lisMenuJumpTo                = 'Jump to';
+  lisMenuJumpToImplementation  = 'Jump to Implementation';
+  lisMenuViewCodeExplorer      = 'Code Explorer';
+  lisOptions                   = 'Options';
+  lisRename                    = 'Rename';
+  lisShowPositionOfSourceEditor = 'Show position of source editor';
+  lisTreeNeedsRefresh          = 'Tree needs refresh';
+  dlgUnitDepRefresh            = 'Refresh';
+  lisCEIn                      = '%s in %s';
 
 type
-  TCodeExplorerView = class;
+  TWKCodeExplorerView = class;
 
   TOnGetDirectivesTree =
      procedure(Sender: TObject; var ADirectivesTool: TDirectivesTool) of object;
   TOnJumpToCode = procedure(Sender: TObject; const Filename: string;
```

```console
$ cd ... && git status --short && echo "--- untracked in WKCodeExplorer ---" && git status --short --untracked-files=all WKCodeExplorer/
?? M2-STEP2-IMPLEMENTATION-REPORT.md
?? M2-STEP2-MEASUREMENT-REPORT.md
?? M2-STEP2-ONEDITORDESTROY-REPORT.md
?? M3-FEASIBILITY-CODEEXPLORER-PORT.md
?? M3-STEP2-ENDLINE-PROPOSAL.md
?? WKCodeExplorer/
?? tests/TestHuge.pas
?? tests/TestLarge.pas
?? tests/extract_names.lpi
?? tests/extract_names.lpr
--- untracked in WKCodeExplorer ---
?? WKCodeExplorer/WKCodeExplOpts.pas
?? WKCodeExplorer/WKCodeExplorer.lfm
?? WKCodeExplorer/WKCodeExplorer.lpk
?? WKCodeExplorer/WKCodeExplorer.pas
?? WKCodeExplorer/WKCodeExplorerRegister.pas
?? WKCodeExplorer/lib/x86_64-linux/WKCodeExplorer.lfm
```

```console
$ cd ... && /home/kastawan/FPC-Deluxe/lazarus/lazbuild -B WKCodeExplorer/WKCodeExplorer.lpk > /tmp/opencode/wkbuild-final.log 2>&1; echo "exit=$?"; tail -n 12 /tmp/opencode/wkbuild-final.log
exit=0
.../WKCodeExplorer.pas(175,35) Hint: (5024) Parameter "Sender" not used
... (hints)
.../WKCodeExplorer.pas(712,9) Warning: (6060) Case statement does not handle all possible cases
.../WKCodeExplorer.pas(1970,3) Warning: (6060) Case statement does not handle all possible cases
(1008) 3582 lines compiled, 0.8 sec
(1021) 2 warning(s) issued
(1022) 27 hint(s) issued
```

`read: /tmp/opencode/wkbuild-final.log` — full final build log, reproduced in
section (d).

---

## c) Change made for each file, and why

All changes are inside `WKCodeExplorer/` (plus this report). No file outside
that folder was edited.

### `WKCodeExplorer/WKCodeExplorer.lpk` (created, 65 lines)

Declares a package named `WKCodeExplorer`, `RunAndDesignTime`, with exactly
the six required dependencies: `CodeTools`, `LazUtils`, `LCL`, `IDEIntf`,
`SynEdit`, `FCL`. Lists the three ported files plus a package registration unit.
Unit output directory is `lib/$(TargetCPU)-$(TargetOS)`.

**Why:** step 4. `WKCodeExplorerRegister.pas` is declared `<Type Value="Main
Unit"/>` because Lazarus rewrites the package main source on every compile;
making a throwaway stub the main unit protects the 3005-line ported unit from
being overwritten (this was observed empirically — see section b).

### `WKCodeExplorer/WKCodeExplorer.pas` (created from `codeexplorer.pas`, 3005 lines)

Derived from `/home/kastawan/FPC-Deluxe/lazarus/ide/codeexplorer.pas` (99210
bytes, 2974 lines). Changes, all from feasibility-report section 6 plus the
prompt's extra requirements:

| Change | Reason |
|---|---|
| `unit CodeExplorer;` → `unit WKCodeExplorer;` | package/unit naming |
| `{$I ide.inc}` → `{$inline on}` + `{$warn 6058 off}` | `ide.inc` contains only directives; avoids IDE-internal include (section 4/6) |
| Removed `IdeConfStrConsts`, `IdePackagerStrConsts`, `LazarusIDEStrConsts`, `IDEOptionDefs` from `uses`; `CodeExplOpts` → `WKCodeExplOpts` | these are IDE-internal / IDE-only units not linkable from a third-party package (section 6) |
| Added a `const` block with 17 `lis*`/`dlg*` strings (`lisCCOErrorCaption`, `lisCEFilter`, `lisCEModeShowCategories`, `lisCEModeShowSourceNodes`, `lisCESurrounding`, `lisCode`, `lisCodeObserver`, `lisDirectives`, `lisMenuJumpTo`, `lisMenuJumpToImplementation`, `lisMenuViewCodeExplorer`, `lisOptions`, `lisRename`, `lisShowPositionOfSourceEditor`, `lisTreeNeedsRefresh`, `dlgUnitDepRefresh`, `lisCEIn`) | replacements for the removed IDE string units; values copied verbatim from the Lazarus sources |
| `TCodeExplorerView` → `TWKCodeExplorerView` (all 117 occurrences, including flag types `TWKCodeExplorerViewFlag(s)`) | step 5: rename class and every reference |
| `Name:=NonModalIDEWindowNames[nmiwCodeExplorer]` → `Name:='WKCodeExplorer'` | removes dependency on `IDEOptionDefs` internal array (section 6) |
| `CodeExplorerMenuRootName = 'Code Explorer'` → `WKCodeExplorerMenuRootName = 'WK Code Explorer'`; local `WKCodeExplorerMenuRoot: TIDEMenuSection` instead of IDEIntf's global `CodeExplorerMenuRoot` | avoid clashing with the IDE's own Code Explorer menu root |
| Menu item internal names `'Jump to'`, `'Jump to implementation'`, `'Show position of source editor'`, `'Refresh'`, `'Rename'` → `'WKJumpTo'`, `'WKJumpToImplementation'`, `'WKShowSrcEditPos'`, `'WKRefresh'`, `'WKRename'` | step 8: WK-prefixed command names |
| Menu command variables and registration function also WK-prefixed (`WKCEJumpToIDEMenuCommand`, …, `RegisterStandardWKCodeExplorerMenuItems`) | consistent naming, no shared globals with IDE |
| Added `procedure Register;` to the interface and implementation; `initialization` creates `CodeExplorerOptions`, `finalization` frees it | the IDE used to call `RegisterStandardCodeExplorerMenuItems` from `main.pp`; a standalone package must register itself and own its options object |

Transformation script used (`/tmp/opencode/do_wk_port.py`, final version):
see the description above; it performs the edits in order with `assert` checks,
then writes both the `.pas` and `.lfm`.

### `WKCodeExplorer/WKCodeExplorer.lfm` (created from `codeexplorer.lfm`, 234 lines)

Verbatim copy except line 1: `object CodeExplorerView: TCodeExplorerView` →
`object CodeExplorerView: TWKCodeExplorerView`.

**Why:** step 5; the form resource class name must match the Pascal class for
`{$R *.lfm}` to initialise the form. Event handler names (e.g.
`CodeExplorerViewCreate`) were deliberately left unchanged because they are
method names, not class references.

### `WKCodeExplorer/WKCodeExplOpts.pas` (rewritten, 555 lines)

A plain `TCodeExplorerOptions = class(TObject)`, with **only** the members
`WKCodeExplorer.pas` reads: `Mode`, `Page`, `Refresh`, `Categories`,
`FollowCursor`, `ObserverCategories`, `ObserveCharConst`, `LongProcLineCount`,
`LongParamListCount`, `NestedProcCount`, `ChangeStep`, `COIgnoreConstant`,
`COIgnoreConstInFunc` — plus `Clear`, `IncreaseChangeStep`, `Load`, `Save`.
Also provides the enums/constants/name arrays and the two
`CodeExplorerLocalizedString` overloads plus `dbgs` that the view uses.
`Load`/`Save` use `TXMLConfig` with a `WKCodeExplorer/` key prefix and
`GetAppConfigDir(False) + 'wkcodeexploreroptions.xml'`, with local string
constants for all category captions. No `TAbstractIDEEnvironmentOptions`
base, no `RegisterIDEOptionsGroup`, no `TAbstractIDEOptions`, no BuildIntf or
IDEOptEditorIntf dependency.

**Why:** step 7 and feasibility-report section 6 ("rewrite path",
≈200–250 lines). The original 925-line unit's IDE-options-page machinery is
irrelevant to a toolbar-plugin port.

### `WKCodeExplorer/WKCodeExplorerRegister.pas` (new, 22 lines)

Lazarus-generated-style package main unit: `unit WKCodeExplorerRegister;`,
`uses WKCodeExplorer, WKCodeExplOpts, LazarusPackageIntf;`, `Register` calls
`RegisterUnit('WKCodeExplorer', @WKCodeExplorer.Register);`, initialization
calls `RegisterPackage('WKCodeExplorer', @Register)`.

**Why:** required so `lazbuild`'s `SavePackageMainSource` rewrites this file
instead of the ported unit. Lazarus itself rewrote the file on the first build
(removing my extra comment and adding `WKCodeExplOpts` to `uses`), which is
harmless.

### `WKCodeExplorer/lib/x86_64-linux/*` (build artifacts)

`.ppu`, `.o`, `.lfm` and `wkcodeexplorer.compiled` produced by `lazbuild`.
Not source changes.

### `prompt-result/WKCodeExplorer-port-report.md`

This report. **Why:** explicitly requested deliverable.

---

## d) Build output, errors and hints

`lazbuild` is not on `PATH`; the real executable is
`/home/kastawan/FPC-Deluxe/lazarus/lazbuild`. The successful final command was:

```console
$ cd /media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone && /home/kastawan/FPC-Deluxe/lazarus/lazbuild -B WKCodeExplorer/WKCodeExplorer.lpk > /tmp/opencode/wkbuild-final.log 2>&1; echo "exit=$?"
exit=0
```

Full final build output (`/tmp/opencode/wkbuild-final.log`, verbatim):

```text
Hint: (lazbuild) Opt: "primary-config-path=/home/kastawan/FPC-Deluxe/config_lazarus"
Hint: (lazarus) SetPrimaryConfigPath NewValue="/home/kastawan/FPC-Deluxe/config_lazarus"
Hint: (lazbuild) Primary config path: "/home/kastawan/FPC-Deluxe/config_lazarus"
Hint: (lazarus) [TBuildManager.SetBuildTarget] Old=x86_64-linux--gtk3 New=x86_64-linux--gtk3 Changed: OS/CPU=True LCL=False
Hint: (lazbuild) Compile package "/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.lpk"
Hint: (lazarus) Fallback output directory of WKCodeExplorer: /home/kastawan/FPC-Deluxe/config_lazarus/lib/WKCodeExplorer/lib/x86_64-linux
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
Info: (lazarus) Param[18]="-Fu/home/kastawan/FPC-Deluxe/lazarus/lcl/units/x86_64-linux/gtk3"
Info: (lazarus) Param[19]="-Fu/home/kastawan/FPC-Deluxe/lazarus/components/lazcontrols/lib/x86_64-linux/gtk3"
Info: (lazarus) Param[20]="-Fu/home/kastawan/FPC-Deluxe/lazarus/components/synedit/units/x86_64-linux/gtk3"
Info: (lazarus) Param[21]="-Fu/home/kastawan/FPC-Deluxe/lazarus/components/ideintf/units/x86_64-linux/gtk3"
Info: (lazarus) Param[22]="-FU/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/lib/x86_64-linux/"
Info: (lazarus) Param[23]="-dLCL"
Info: (lazarus) Param[24]="-dLCLgtk3"
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
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(156,39) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(157,36) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(158,37) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(159,12) Hint: (5024) Parameter "Shift" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(160,42) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(161,42) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(164,28) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(165,31) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(166,35) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(167,49) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(168,31) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(169,43) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(170,39) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(171,40) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(172,43) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(173,39) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(174,36) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(175,35) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(176,34) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(712,9) Warning: (6060) Case statement does not handle all possible cases
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(177,32) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(178,32) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(179,31) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(180,32) Hint: (5024) Parameter "Sender" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(180,58) Hint: (5024) Parameter "Msg" not used
/media/kastawan/Kingston250-SSD/MEGAsync/@OpenCode/Output/MMX-Clone/WKCodeExplorer/WKCodeExplorer.pas(1970,3) Warning: (6060) Case statement does not handle all possible cases
(1008) 3582 lines compiled, 0.8 sec
(1021) 2 warning(s) issued
(1022) 27 hint(s) issued
```

**Errors encountered and resolved during the work:**

1. `lazbuild: not found` — resolved by using the full path
   `/home/kastawan/FPC-Deluxe/lazarus/lazbuild`.
2. First build silently overwrote `WKCodeExplorer.pas` with a 22-line stub —
   resolved by introducing `WKCodeExplorerRegister.pas` as the package "Main
   Unit".
3. `Identifier not found "Register"` in `WKCodeExplorerRegister.pas` —
   resolved by exposing `procedure Register;` in the interface of
   `WKCodeExplorer.pas`.
4. `Warning: (6018) Unreachable code` at `WKCodeExplOpts.pas(284,18)` —
   resolved by removing the unreachable `else` arm of the exhaustive
   `case TCEObserverCategory`.

**Remaining diagnostics (not errors, build exits 0):**

- 2 × `Warning: (6060) Case statement does not handle all possible cases` at
  `WKCodeExplorer.pas(712,9)` and `(1970,3)`. Both are inherited verbatim from
  Lazarus's `codeexplorer.pas` (deliberately not "fixed" to keep the port
  faithful).
- 26 × `Hint: (5024) Parameter "Sender"/"Shift"/"Msg" not used` in the ported
  view plus 1 config-file hint. Again inherited from the upstream source.
- 6 lazbuild/lazarus informational hints about config paths and build target.

No fatal errors remain. The package was **not** installed.

---

## e) Skipped or not possible, and why

1. **Diff against "the uploads" could not be performed.** No uploaded copies
   of `codeexplorer.pas` / `codeexplopts.pas` exist anywhere I searched: the
   repository (including untracked files and git history), both paths to the
   MEGAsync output folder, `~/Downloads`, `~/Desktop`, `/tmp`, `/tmp/opencode`,
   and the OpenCode config/storage directories. The only `.pas` files named
   `codeexplorer.pas` / `codeexplopts.pas` on the machine are the authoritative
   ones under `/home/kastawan/FPC-Deluxe/lazarus/ide/`. Consequently there are
   no upload differences to report, and I used only the authoritative
   FPC-Deluxe sources as required.
2. **No stop on the LICENSE gate** — MIT is GPL-compatible, so the work
   continued. If it had not been compatible, I would have stopped and written
   this report only.
3. **No IDE options page** — deliberately omitted per step 7; the rewritten
   options unit has no `RegisterIDEOptionsGroup` and does not depend on
   BuildIntf/IDEOptEditorIntf.
4. **No "View > Code Explorer" show-command was added.** The upstream unit is
   created by IDE code in `main.pp`; the port exposes `TWKCodeExplorerView` and
   a `Register` hook, but adding a host command to instantiate/show the form
   was outside the stated scope.
5. **Did not install the package**, did not commit, did not push — explicitly
   forbidden.
6. **Did not edit** `toolbarexplorerplugin.pas` or `codetoolbarexplorer.lpk` —
   explicitly forbidden. Both are untouched.
7. **Runtime behaviour was not exercised inside the IDE** — only compilation
   with `lazbuild` was requested; loading the package into a running Lazarus
   IDE would constitute installation/testing beyond the scope.
8. **Two upstream compiler warnings and the unused-parameter hints were left
   as-is** to preserve the port's fidelity to the original source.
9. **The pre-existing contents of `WKCodeExplorer/` were replaced.** The folder
   contained an earlier partial attempt (a 432-byte generated stub, an
   already-rewritten options unit, and a package file). I inspected them first,
   then overwrote them with the complete port; no other existing file was
   modified.

---

## Post-report verification (after writing this file)

```console
$ cd ... && git status --short && echo "--- report ---" && ls -l prompt-result/WKCodeExplorer-port-report.md && echo "--- package files ---" && ls -l WKCodeExplorer/*.pas WKCodeExplorer/*.lfm WKCodeExplorer/*.lpk
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
--- report ---
-rw-rw-r-- 1 kastawan kastawan 73270 Nov 19 08:07 prompt-result/WKCodeExplorer-port-report.md
--- package files ---
-rw-rw-r-- 1 kastawan kastawan  19270 Nov 19 08:01 WKCodeExplorer/WKCodeExplOpts.pas
-rw-rw-r-- 1 kastawan kastawan   7081 Nov 19 08:04 WKCodeExplorer/WKCodeExplorer.lfm
-rw-rw-r-- 1 kastawan kastawan   1762 Nov 19 08:04 WKCodeExplorer/WKCodeExplorer.lpk
-rw-rw-r-- 1 kastawan kastawan 100706 Nov 19 08:04 WKCodeExplorer/WKCodeExplorer.pas
-rw-rw-r-- 1 kastawan kastawan    456 Nov 19 08:04 WKCodeExplorer/WKCodeExplorerRegister.pas
```

Nothing was committed or pushed; the package was not installed.
