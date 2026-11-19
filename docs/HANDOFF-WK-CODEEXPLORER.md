# WK Code Explorer — handoff

Test programs (`PasteFormatTest.pas`, `CopyFormatTest.pas`) and `TestVisibility.pas` live in `~/projects/WKCopyPasteTest/`, outside the repo. The repo has no `WKCodeExplorer/tests/` folder.

## Git state (captured)

```
$ git branch --show-current
mmx-codeexplorer

$ git log --oneline -3
6537cce Fix TBeta.Pubd name in TestVisibility test unit
f3ddd3e Ignore working notes and scratch test files
be4d134 Extend TestVisibility with THuman class for multi-class explorer checks

$ git status --short -uall
 M .gitignore
 M WKCodeExplorer/WKCodeExplorer.lpk
 M WKCodeExplorer/WKCodeExplorer.pas
 M WKCodeExplorer/WKCodeExplorerRegister.pas
?? WKCodeExplorer/WKCopyFormat.pas
?? WKCodeExplorer/WKPasteFormat.pas
```

## 1. STATUS

- CLASS copy: **verified in the IDE**.
- CLASS paste: **verified in the IDE** (`THuman`, `THuman_1`, `THuman_2` on three pastes; compile Success after each).
- Caret: **verified by line numbers** (37:7 before paste, 51:7 after, column unchanged).
- Undo: **one Ctrl+Z removed the whole paste** (confirmed by screenshot).
- MEMBER paste (`//MMWIN:MEMBERSCOPY`): **NOT RUN**.

## 2. FILES CHANGED

- `WKCodeExplorer/WKCodeExplorer.pas` — modified: Copy/Paste menu items and handlers (class lookup via `FindClassCTNode`, clipboard copy/paste), editor insertions with caret adjustment and `type`-section handling, debug logging.
- `WKCodeExplorer/WKCopyFormat.pas` — new: helper for building `CLASSCOPY` clipboard text.
- `WKCodeExplorer/WKPasteFormat.pas` — new: clipboard parsing, whole-identifier renaming, and class-declaration/routine extraction helpers for paste.
- `WKCodeExplorer/WKCodeExplorer.lpk` — modified: package file list updated to include copy/paste units.
- `WKCodeExplorer/WKCodeExplorerRegister.pas` — modified: registration/unit wiring updates for the package.
- Note: `tests/TestVisibility.pas` needs `{$M+}` after `{$mode ObjFPC}{$H+}`, not yet added.

## 3. KNOWN ISSUES

- Debug logging to `/tmp` files (remove before final commit).
- `CurNode.CTNode` is nil after refresh; use `FindClassCTNode`.
- `CurNode.Path` is empty for class nodes; use `ExtractDefinitionName`.
- Copied comment still reads `{ THuman }` after pasting as `THuman_1` (cosmetic).
- Clipboard is replaced by anything copied, so copy nothing between Copy and Paste.
- 2 inherited `6060` build warnings.
- Pasted units with a `published` section need `{$M+}`.

## 4. NEXT STEPS

- Remove debug logging, rebuild (expect 2 warnings).
- Run the MEMBER paste test with a `//MMWIN:MEMBERSCOPY` clipboard.
- Commit in three steps: (1) paste feature with debug logging, plus docs/ handoff and .gitignore; (2) add {$M+} to tests/TestVisibility.pas; (3) remove debug logging after the MEMBER paste test.

## 5. RULES

- Read this file first.
- Do not trust older reports in `prompt-result/`.
- Check `git status` before any edit.
- One stage per prompt.
- Quote command output.
