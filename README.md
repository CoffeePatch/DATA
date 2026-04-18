# DATA

Central documentation and script pack for repeatable media metadata fixes on Windows with ExifTool.

## What this repository gives you

- A **script-first workflow** for writing and verifying media date metadata.
- A **manual command runbook** for users who want to run steps individually.
- A **verification and recovery guide** for common errors and rerun risks.

## Quick start

1. Open **Command Prompt** in your target media folder.
2. Pick exactly one strategy script:
   - Mixed folder with some date-bearing names:
     `..\scripts\windows\run_strategy_a_filename_priority.bat`
   - Fresh folder where Date Modified is trusted:
     `..\scripts\windows\run_strategy_b_filemodify_once.bat`
   - Sequence-only names (for example `Media_XXXXXX`):
     `..\scripts\windows\run_strategy_c_sequence_timeline.bat START_NUM "YYYY:MM:DD HH:MM:SS" STEP_SECONDS`
3. Verify results:
   - `..\scripts\windows\verify_folder.bat`
   - `..\scripts\windows\verify_file.bat "filename.ext"`
4. Review logs in `logs\`.

## Documentation map

- `docs/README.md` - step-by-step reading and execution order.
- `docs/runbook-windows.md` - full SOP with script and manual command paths.
- `docs/verification-and-signoff.md` - go/no-go checks before upload.
- `docs/error-catalog.md` - known errors, meaning, and fixes.
- `docs/conversation-analysis.md` - workflow evolution and decision context.

## Script catalog

- `scripts/windows/README.md` - what each script does, when to use it, expected output.
- `scripts/windows/run_strategy_a_filename_priority.bat`
- `scripts/windows/run_strategy_b_filemodify_once.bat`
- `scripts/windows/run_strategy_c_sequence_timeline.bat`
- `scripts/windows/verify_folder.bat`
- `scripts/windows/verify_file.bat`

## Important safety rule

Do not rerun FileModifyDate-based write workflows on already-processed files unless you intentionally want to replace metadata with current filesystem timestamps.
