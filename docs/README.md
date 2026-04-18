# Media Metadata Documentation Hub

This folder is the central documentation for fixing and validating media metadata at scale.

## Quick start (recommended)

1. Open Command Prompt in the target media folder.
2. Run one script from `scripts\windows` based on folder type:
   - `run_strategy_a_filename_priority.bat`
   - `run_strategy_b_filemodify_once.bat`
   - `run_strategy_c_sequence_timeline.bat START_NUM "YYYY:MM:DD HH:MM:SS" STEP_SECONDS`
3. Run `verify_folder.bat`.
4. Spot-check with `verify_file.bat "filename.ext"`.
5. Review generated logs under `logs\`.

## What to read first

1. `runbook-windows.md`
   - Main Standard Operating Procedure (SOP) for Windows + ExifTool.
   - Includes safe workflows for mixed folders, date-from-filename folders, and sequence-only folders.

2. `../scripts/windows/README.md`
   - Script catalog, usage examples, and logging behavior.

3. `conversation-analysis.md`
   - Analysis of the 31-chat history: user intent, decision points, and workflow evolution.

4. `error-catalog.md`
   - Known errors/warnings and exact fixes.

5. `verification-and-signoff.md`
   - Verification commands and upload go/no-go checklist for Google Photos.

## Core rule in one line

Never run a FileModifyDate-to-metadata command twice on already-processed files unless you intentionally want to replace metadata with current file system timestamps.
