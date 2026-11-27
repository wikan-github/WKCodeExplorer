# WK Code Explorer — handoff

Test programs (`PasteFormatTest.pas`, `CopyFormatTest.pas`) live in `~/projects/WKCopyPasteTest/`, outside the repo. `tests/TestVisibility.pas` is tracked in this repo but has pre-existing local edits.

## Git state

The WKCodeExplorer feature work and this handoff are committed on `mmx-codeexplorer`. The branch is ahead of `origin/mmx-codeexplorer`; nothing has been pushed.

Local files left out of commits:

```
$ git status --short -uall
 M tests/TestVisibility.pas
?? codetoolbarexplorer.lps
?? files.zip
```

Latest feature commit: `0f3bf6d Add designer dialog for Ctrl+L local variables and clean type suggestions`.

## 1. STATUS

Only features verified in the IDE are listed below.

### CLASS copy/paste — verified in the IDE
- Copy a class node: `CLASSCOPY` text (marker, unit wrapper, type block, implementation, end).
- Paste into a unit: class placed inside the existing interface type block (before the first var/const after it), type line added only when the unit has none, `{$M+}` added when the class has a published section and the target lacks it, leading comment renamed to `THuman_1` / `THuman_2` when the name exists.
- Caret restored by the inserted line count; one Ctrl+Z removes the whole paste.

### MEMBER copy/paste — verified in the IDE
- Copy a method or property from the Interface node (for example `Walk`, `Age`) and from the Implementation node (`THuman.Walk`); both produce the same `MEMBERSCOPY` text.
- Paste into a class: public or private, following the visibility of the copied member; a nested routine pasted into a class becomes a private method.
- Paste with no class selected (Module): private standalone routine, body only, `TOld.` removed from the header.
- Repeated paste shows "Routine already exists".

### MODULECOPY (standalone routines) — verified in the IDE
- Public routine (declaration in interface): declaration plus body. Overloads each keep their own declaration.
- Private routine (body only): body only.
- Paste into a class: a standalone routine becomes a method; visibility follows the copied item.
- Nested routine copied on its own: copies just that routine.

### Paste blank line — not implemented (enhancement)
- Blank-line spacing after each paste is NOT done (moved to enhancements).

### Delete (classes and members) — verified in the IDE
- Class (interface or implementation section): declaration and method bodies removed, `{ Name }` comment and empty visibility labels kept; Ctrl+Z restores in one step.
- Method from Interface node: declaration and body removed. From Implementation node: body and declaration.
- Overloads: only the selected overload removed.
- `XTHuman` and `THuman`: deleting `THuman` leaves `XTHuman`.

### Delete (standalone) — verified in the IDE
- Public routine: declaration and body removed. Private routine: body only. Variables and constants: their line.
- Non-class types: Delete stays disabled. Nested routine and local variable: disabled.
- Cancel leaves source unchanged; Ctrl+Z restores in one step.

### Refresh and view — verified in the IDE
- Source order is the default view; category view available by the toggle.
- Tree refreshes after Delete and Paste (forced refresh that bypasses the tree-focus check).
- Expanded branches after refresh are NOT restored automatically (enhancement).

### Ctrl+L Add local variable — verified in the IDE
- The dialog opens with Ctrl+L (after removing the Lazarus alternate binding).
- `THuman.Walk` with no var creates `var` above `begin` with the declaration under it.
- `Show` and `Clamp` insert as the first line under `var`, indented two spaces.
- The outer body of `LogMessage` inserts into its var section.
- A duplicate name shows "Variable already exists".
- An invalid name (`123myVar`) shows the confirmation.
- A name typed in a nested routine's own var section (`Fill`, `yy`) creates `var yy: Integer;` inside `Fill`; verified in the IDE.
- The dialog is a designer form (`WKAddLocalVariableForm`) with Type name, History and `Edit...`.
- Type name defaults to `Integer`; the Type name combo lists primitive types, unit-level types and current-routine local types, filters as you type, and strips a leading `type` keyword. All confirmed in the IDE.
- The separate History combo stores up to 30 chosen types; selecting an entry copies it into Type name, `Edit...` opens the history file, OK saves the chosen type, and Cancel does not. All confirmed in the IDE.

## 2. FILES CHANGED

- `WKCodeExplorer/WKCodeExplorer.pas` — committed in `0f3bf6d`: Delete for classes/members/standalone routines/module vars-consts, implementation-section class delete fix, default source-order view, forced refresh after Delete/Paste, Ctrl+L Add local variable command (`WKAddLocalVariableExecute`, `WKFindRoutineBodyBounds`, `WKIsAlreadyDeclared`, prompt/validation helpers), nested routine var insertion, and type-name collection that strips a leading `type` keyword.
- `WKCodeExplorer/WKAddLocalVariableForm.pas` / `.lfm` — new designer form for Ctrl+L (Type name, History, `Edit...`). Committed in `0f3bf6d`; the `.lfm` uses numeric `ModalResult` values (`1` / `2`). User reported that a package reinstall was required before the rebuilt form resource was loaded.
- `WKCodeExplorer/WKCopyFormat.pas` — helper for building `CLASSCOPY` clipboard text (committed earlier).
- `WKCodeExplorer/WKPasteFormat.pas` — clipboard parsing, whole-identifier renaming, and class-declaration/routine extraction helpers for paste (committed earlier).
- `WKCodeExplorer/WKCodeExplorer.lpk` — package file list includes copy/paste units and the new Ctrl+L form files (committed in `0f3bf6d`).
- `WKCodeExplorer/WKCodeExplorerRegister.pas` — registration/unit wiring updates for the package, including `WKAddLocalVariableForm` (committed in `0f3bf6d`).
- `docs/HANDOFF-WK-CODEEXPLORER.md` — updated to reflect verified nested-routine Ctrl+L and all Type name / History checks.
- `tests/TestVisibility.pas` — pre-existing local worktree edits; not part of any commit.

## 3. KNOWN ISSUES / LIMITS

- `CurNode.CTNode` is nil after refresh; use `FindClassCTNode`.
- `CurNode.Path` is empty for class nodes; use `ExtractDefinitionName`.
- Copied comment still reads `{ THuman }` after pasting as `THuman_1` (cosmetic).
- Clipboard is replaced by anything copied, so copy nothing between Copy and Paste.
- 2 inherited `6060` build warnings.
- Pasted units with a `published` section need `{$M+}` (auto-added on paste when missing).
- Paste fallback uses the tree label when `FindClassCTNode` fails, which can include an inheritance suffix such as `TForm1(TForm)`.
- `CurPasteTV` is not checked for `nil` before use.
- MEMBER paste IDE test was run only in `umainForm.pas`.
- Copy is not available for enumerations or other non-class types (e.g. `TAppType`).
- Expanded branches after refresh are not restored automatically.
- Ctrl+L conflicts with Lazarus default `ecFindNext` binding; user must remove the Lazarus alternate binding.
- `WKIsAlreadyDeclared` is a best-effort heuristic.
- Undo: each paste or delete is one undo step; Ctrl+Z does not step back through earlier operations (same as the Delphi editor).
- The build reports a note for `WKAddLocalVariableCmd` (assigned but never used).
- `tests/TestVisibility.pas` has uncommitted local edits; not part of any commit.

## 4. NEXT STEPS

1. Multi-select copy and paste (`MODULECOPY` from the bottom member list, in source order).
2. Variables, constants and non-class types: copy and paste into interface.
3. Enums and other non-class types (`//MMWIN:TYPESCOPY`).
4. Delete Recovery (JSON log in `.wkdeleted/`, created automatically, refuse if it cannot be written).
5. Enhancements: expanded branches after refresh; duplicate paste renames (`_1`, `_2`); blank-line spacing after each paste; warn-first scan for undeclared identifiers; optional push of `mmx-explorer-m1` and `mmx-explorer-m2`.

## 5. TEST PROCEDURE

### CLASS copy/paste (verified)

1. In WK Code Explorer, copy a class node (e.g. `THuman`).
2. Paste three times.
3. Expected: classes pasted as `THuman`, `THuman_1`, `THuman_2`; compile succeeds after each paste.
4. Expected caret: line/column unchanged relative to original position accounting for inserted lines.
5. Undo: one `Ctrl+Z` removes the whole paste.

### MEMBER copy/paste (verified)

1. Copy a routine/member without a return type (e.g. `Walk`) and one with a return type (e.g. `Age`).
2. Paste into a new class / selected class.
3. Expected: member inserted under original visibility; routine renamed for target class; compile succeeds.
4. Paste the same member again: `"Routine already exists"`.

### MODULECOPY standalone routines (verified)

1. Copy a public standalone routine: clipboard contains declaration + body.
2. Copy a private standalone routine: body only.
3. Paste into a class: becomes a method; visibility follows copied item.
4. Nested routine copied on its own: copies just that routine.

### Delete (verified)

1. Delete class from interface or implementation: declaration/bodies removed, `{ Name }` comment and empty visibility labels kept; one Ctrl+Z restores.
2. Delete method from Interface/Implementation node; overload deletes only selected overload.
3. Delete standalone public routine: declaration + body removed. Private: body only. Var/const: line removed.
4. Non-class types, nested routine, local variable: Delete disabled. Cancel leaves source unchanged.

### Refresh and view (verified)

1. Source order is default view; category toggle works.
2. After Delete/Paste, tree refreshes (forced refresh bypasses tree-focus check).
3. Expanded branches after refresh: NOT restored automatically (known enhancement).

### Ctrl+L Add local variable (verified)

1. Remove Lazarus Ctrl+L alternate binding (`ecFindNext`) so WKCodeExplorer receives Ctrl+L. **Verified**.
2. `THuman.Walk`, no var, name `xyz`: `var` above `begin`, `xyz: Integer;` under it, indented two spaces. **Verified**.
3. `Show` and `Clamp`, existing var section: inserted as the first line under `var`, indented two spaces. **Verified**.
4. Outer body of `LogMessage`: inserts into its var section. **Verified**.
5. Duplicate name: "Variable already exists". **Verified**.
6. Invalid name (`123myVar`): confirmation shown. **Verified**.
7. Name typed in a nested routine's own var section (`Fill`, `yy`): creates `var yy: Integer;` inside `Fill`. **Verified**.
8. Type name defaults to `Integer`; dropdown contains all 18 primitive types. **Verified**.
9. Unit-level type declarations appear in Type name; class/record members do not. **Verified**.
10. Current-routine local types appear in Type name. **Verified**.
11. Inline `type T = ...` suggests `T`, not `type T`. **Verified**.
12. Typing filters the Type name list case-insensitively. **Verified**.
13. Chosen type is saved to History and is at the top on the next Ctrl+L; selecting it fills Type name. **Verified**.
14. `Edit...` opens `/home/kastawan/.wkcodeexplorer_types.txt`. **Verified**.
15. Cancel does not add a type to History. **Verified**.
16. A chosen non-default type is inserted as `Name: Type;` in the var section. **Verified**.

## 6. RULES

- Read this file first.
- Do not trust older reports in `prompt-result/`.
- Check `git status` before any edit.
- One stage per prompt.
- Quote command output.
