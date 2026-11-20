# WK Code Explorer — handoff

Test programs (`PasteFormatTest.pas`, `CopyFormatTest.pas`) and `TestVisibility.pas` live in `~/projects/WKCopyPasteTest/`, outside the repo. The repo has no `WKCodeExplorer/tests/` folder.

## Git state (as of ce428a6)

```
$ git branch --show-current
mmx-codeexplorer

$ git log --oneline -4
ce428a6 Paste MEMBER copy into selected class in WKCodeExplorer
475902b Remove debug logging and copy file output from WKCodeExplorer
335f260 Add WKCodeExplorer copy and paste for class members
6537cce Fix TBeta.Pubd name in TestVisibility test unit

$ git status --short -uall
 M docs/HANDOFF-WK-CODEEXPLORER.md
```

## 1. STATUS

- CLASS copy: **verified in the IDE**.
- CLASS paste: **verified in the IDE** (`THuman`, `THuman_1`, `THuman_2` on three pastes; compile Success after each).
- Caret: **verified by line numbers** (37:7 before paste, 51:7 after, column unchanged).
- Undo: **one Ctrl+Z removed the whole paste** (confirmed by screenshot).
- MEMBER copy: **verified in the IDE** for routines without a return type (`Walk`) and with one (`Age`).
- MEMBER paste into a new class: **verified**.
- MEMBER paste with a class selected in the WK tree: **verified** (member inserted into `TForm1` under its original visibility, routine renamed to `TForm1`).
- Repeated paste shows `"Routine already exists"`.

## 2. FILES CHANGED

- `WKCodeExplorer/WKCodeExplorer.pas` — committed in `ce428a6` (`Paste MEMBER copy into selected class in WKCodeExplorer`): Copy/Paste menu items and handlers (class lookup via `FindClassCTNode`, clipboard copy/paste), editor insertions with caret adjustment and `type`-section handling, MEMBER copy (routines/properties with body) and MEMBER paste target handling.
- `WKCodeExplorer/WKCopyFormat.pas` — new (committed earlier, `335f260`): helper for building `CLASSCOPY` clipboard text.
- `WKCodeExplorer/WKPasteFormat.pas` — new (committed earlier, `335f260`): clipboard parsing, whole-identifier renaming, and class-declaration/routine extraction helpers for paste.
- `WKCodeExplorer/WKCodeExplorer.lpk` — modified (committed earlier): package file list updated to include copy/paste units.
- `WKCodeExplorer/WKCodeExplorerRegister.pas` — modified (committed earlier): registration/unit wiring updates for the package.
- Note: `tests/TestVisibility.pas` does not need `{$M+}` (team decision).

## 3. KNOWN ISSUES

- `CurNode.CTNode` is nil after refresh; use `FindClassCTNode`.
- `CurNode.Path` is empty for class nodes; use `ExtractDefinitionName`.
- Copied comment still reads `{ THuman }` after pasting as `THuman_1` (cosmetic).
- Clipboard is replaced by anything copied, so copy nothing between Copy and Paste.
- 2 inherited `6060` build warnings.
- Pasted units with a `published` section need `{$M+}`.
- Paste fallback uses the tree label when `FindClassCTNode` fails, which can include an inheritance suffix such as `TForm1(TForm)`.
- `CurPasteTV` is not checked for `nil` before use.
- MEMBER paste test was run only in `umainForm.pas`.
- Copy is disabled on the Implementation node (e.g. `THuman.Walk`). Member copy works only from the Interface node (e.g. `Walk`).

## 4. NEXT STEPS

- Optional: push `mmx-explorer-m1` and `mmx-explorer-m2` if not yet on GitHub. (Debug logging removal was completed in `475902b`; test-file `{$M+}` change not needed per team decision.)

## 5. TEST PROCEDURE

### CLASS copy/paste (verified)

1. In WK Code Explorer, copy a class node (e.g. `THuman`).
2. Paste three times.
3. Expected: classes pasted as `THuman`, `THuman_1`, `THuman_2`; compile succeeds after each paste.
4. Expected caret: line/column unchanged relative to original position accounting for inserted lines (verified example: 37:7 before paste, 51:7 after, column unchanged).
5. Undo: one `Ctrl+Z` removes the whole paste.

### MEMBER copy/paste (verified)

1. Copy a routine/member without a return type (e.g. `Walk`) and one with a return type (e.g. `Age`) — MEMBER copy verified for both.
2. Paste into a new class.
3. Expected: member declaration inserted in the appropriate visibility section and implementation routine inserted/renamed for the target class; compile succeeds.

### MEMBER paste with selected class in WK tree (TForm1, verified)

1. Copy a member (`//MMWIN:MEMBERSCOPY` clipboard).
2. Select a class node in the WK tree (e.g. `TForm1`).
3. Paste.
4. Expected: member inserted into `TForm1` under its original visibility; routine renamed to `TForm1`.
5. Paste the same member again.
6. Expected: dialog/message `"Routine already exists"`.
7. Note: this MEMBER paste test was run only in `umainForm.pas`.

## 6. RULES

- Read this file first.
- Do not trust older reports in `prompt-result/`.
- Check `git status` before any edit.
- One stage per prompt.
- Quote command output.
