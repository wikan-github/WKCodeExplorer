# WK Code Explorer — handoff

Test programs (`PasteFormatTest.pas`, `CopyFormatTest.pas`) and `TestVisibility.pas` live in `~/projects/WKCopyPasteTest/`, outside the repo. The repo has no `WKCodeExplorer/tests/` folder.

## Git state (as of 40f20c5)

```
$ git log --oneline -4
40f20c5 Place pasted class inside the interface type block; add {$M+} for published classes; copy implementation-node members
34f86e6 Update WKCodeExplorer handoff with verified member copy and paste
ce428a6 Paste MEMBER copy into selected class in WKCodeExplorer
475902b Remove debug logging and copy file output from WKCodeExplorer

$ git status --short -uall
 M tests/TestVisibility.pas
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
- Paste placement: a class is inserted inside the existing interface type block, before the
  first column-zero var/const/resourcestring/threadvar, after the last declaration in the block.
  A type line is added only when the unit has no interface type block. Verified in `umainForm.pas`
  (`TForm1` block), `TestVisibility.pas` (enum block, class after `TBeta`), and a new unit with no
  type section.
- `{$M+}` is added above the `interface` line when the copied class has a `published` section and
  the target lacks `{$M+}`. Verified: compile succeeds.
- Undo: one `Ctrl+Z` removes the whole paste, including `{$M+}` and the `type` line.
- Copy from an Implementation node (`THuman.Walk`, `THuman.Age`) produces the same text as the
  Interface node. Verified by Notepad comparison.
- Commit `40f20c5` contains the placement, `{$M+}`, comment rename and Implementation-copy
  changes.

## 2. FILES CHANGED

- `WKCodeExplorer/WKCodeExplorer.pas` — committed in `40f20c5` (`Place pasted class inside the interface type block; add {$M+} for published classes; copy implementation-node members`): Copy/Paste menu items and handlers (class lookup via `FindClassCTNode`, clipboard copy/paste), editor insertions with caret adjustment and placement inside the interface `type` block, automatic `{$M+}`, leading-comment rename, MEMBER copy (routines/properties with body) and MEMBER paste target handling.
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
- Copy is not available for enumerations or other non-class types (e.g. `TAppType`). Planned
  after standalone routines.
- Standalone routines, variables and types outside a class: Copy and Paste not implemented.
- `tests/TestVisibility.pas` has uncommitted local edits (enum types, a `const` section in
  `TBeta`, and no routine bodies in the implementation section). Not part of any commit.

## 4. NEXT STEPS

1. Standalone routines, variables and types plan (answer the five questions first).
2. Enum and other type copy/paste (`//MMWIN:TYPESCOPY`).
3. Delete feature for classes and members (correct the plan's question 6b first, and test undo
   grouping in the IDE).
4. Optional push of `mmx-explorer-m1` and `mmx-explorer-m2`.

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
