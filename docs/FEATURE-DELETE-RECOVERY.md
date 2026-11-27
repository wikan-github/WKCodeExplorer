## 1. Status

- Phase 1 (recording): NOT IMPLEMENTED. `WKWriteRecoveryRecord`, `WKJsonEscape` and the `"source"` field are absent from `WKCodeExplorer/WKCodeExplorer.pas` at commit `d83dd1d`. Two attempts stopped at the prerequisite check (reports: `delete-recovery-viewer-report.md` and `recovery-source-path-report.md`, both in `prompt-result/`).
- Phase 2 (viewer and restore): NOT STARTED. Depends on Phase 1.
- Delete itself is verified in the IDE and must not change.

## 2. Decisions (agreed with the user, do not revisit without asking)

- Recording: before any source line is removed, and only after the user chooses Yes in the confirmation, write one JSON file per Delete action.
- Folder: `.wkdeleted`, next to the source file. Created if missing. Not cleaned up automatically.
- File name: local date and time, `yyyy-mm-dd_hh-mm-ss.json`. If it exists, append `_1`, `_2`, and so on.
- Fields, in this order: `time` (ISO `yyyy-mm-ddThh:nn:ss`), `action`, `owner`, `name`, `params`, `source`, `clip`.
- `action` values: `delete-class`, `delete-method`, `delete-standalone-public`, `delete-standalone-private`, `delete-variable`, `delete-constant`.
- `owner`: class name for a method, empty for a class or standalone item.
- `params`: normalised parameter list, used to tell overloads apart; empty for a class.
- `source`: FULL path of the source file, not just the name. Escaped like the other string fields.
- `clip`: the copy text for the item (the same text Copy would produce), built before the removal.
- JSON: written with plain text output; escaping handled by one helper `WKJsonEscape` covering backslash, double quote, CR, LF and tab. No JSON library.
- If the folder cannot be created or the file cannot be written: show `Delete refused: cannot write recovery record in <folder>` and remove nothing.
- One record per Delete action, not per line.
- Viewer (Phase 2): popup item `Recovery...`, always enabled when the source file has a `.wkdeleted` folder; otherwise `No recovery records`. Separate designer form (`WKRecoveryForm.pas` and `.lfm`), list newest first with time, action and `owner.name`, memo with the selected record's fields, buttons Restore and Close.
- Restore: puts the clip on the clipboard, calls the existing `WKPasteMenuItemClick`, then restores the previous clipboard text. Destination rules are the existing paste rules, unchanged. Restore is one undo step. The form stays open after a restore. Records are not deleted in this phase.
- Form rules: published controls, every event bound in the `.lfm`, `ModalResult` values written as `mrOk` and `mrCancel`.

## 3. Phase 1 steps (recording)

- Locate the confirmation and the removal in `WKDeleteMenuItemClick`, and where the copy text for the item is built.
- Add `WKJsonEscape` and `WKWriteRecoveryRecord`. Call the writer after Yes and before any removal.
- Build with `lazbuild`; expected 0 errors, 2 warnings (6060).
- IDE checks listed in section 5.

## 4. Phase 2 steps (viewer and restore)

- Create `WKRecoveryForm.pas` and `.lfm`, add to `WKCodeExplorer.lpk`.
- Add the `Recovery...` popup item and its handler.
- Add the restore helper that uses the clipboard and `WKPasteMenuItemClick`.
- Build; expected 0 errors, 2 warnings (6060).

## 5. IDE test checklist

Phase 1:

- [ ] a) Delete a class: a file appears in `.wkdeleted` next to the source, named with the current date and time.
- [ ] b) The file is valid JSON with action `delete-class`, the class name, and a `clip` string.
- [ ] c) `"source"` holds the full path, for example `/home/kastawan/Desktop/tmp/WKCodeExplorerTest/umainform.pas`.
- [ ] d) Two deletes in the same second: two files, the second named with `_1`.
- [ ] e) Folder unwritable: Delete shows the refusal and removes nothing.
- [ ] f) Cancel on the confirmation: no file is written.
- [ ] g) Ctrl+Z after a delete still restores the source.

Phase 2:

- [ ] h) `Recovery...` on a source file with no `.wkdeleted` folder: `No recovery records` appears.
- [ ] i) After a delete: `Recovery...` lists the record, newest first.
- [ ] j) Select a record: its fields appear in the memo.
- [ ] k) Restore a deleted class into a class destination: pasted as the paste does.
- [ ] l) Restore a deleted standalone public routine into the Module: declaration and body are pasted.
- [ ] m) Ctrl+Z after a Restore removes the restored text in one step.
- [ ] n) The form's layout is editable in the designer.

## 6. Open questions

- Whether `.wkdeleted` should be added to `.gitignore` (not decided).
- Retention: keep all records, or cap the count (not decided).

## 7. Test unit

- `tests/TestVisibility.pas` (the complex unit) is the source for the tests.
- Its uncommitted state must be restored from the stash before testing.

## 8. Record of the two stopped attempts

- On 27 November 2026, `delete-recovery-viewer-report.md` stopped at the prerequisite check. The required grep found only `WKPasteMenuItemClick`; `WKWriteRecoveryRecord` and `WKJsonEscape` were absent from `WKCodeExplorer/WKCodeExplorer.pas`, so no form, popup item, restore helper or `.lpk` change was made.
- On 27 November 2026, `recovery-source-path-report.md` stopped for the same reason. Neither `WKWriteRecoveryRecord`, `WKJsonEscape` nor the `"source"` field existed, so the full-path change could not be applied and no build was run.
