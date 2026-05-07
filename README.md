# DATA

Central documentation and script pack for repeatable media metadata fixes on Windows with ExifTool.

## Start here (new users)

- [Organized reference index](docs/reorganized-reference.md)
- [What is ExifTool and why this repo exists](docs/exiftool-foundations.md)
- [Cloud storage sorting behavior (Google Photos, Mega, OneDrive, Amazon, iCloud)](docs/cloud-storage-sorting/README.md)
- [Windows runbook (full SOP)](docs/runbook-windows.md)
- [Windows scripts quick reference](scripts/windows/README.md)
- [Verification and sign-off checklist](docs/verification-and-signoff.md)

## What this repository gives you

- A **script-first workflow** for writing and verifying media date metadata.
- A **manual command runbook** for users who want to run steps individually.
- A **verification and recovery guide** for common errors and rerun risks.

## Quick start

1. Open **Command Prompt** in your target media folder.
2. Pick exactly one strategy script:
   - Mixed folder with some date-bearing names:
     `..\scripts\windows\run_strategy_a_filename_priority\run_strategy_a_filename_priority.bat`
   - Fresh folder where Date Modified is trusted:
     `..\scripts\windows\run_strategy_b_filemodify_once\run_strategy_b_filemodify_once.bat`
   - Sequence-only names (for example `Media_XXXXXX`):
     `..\scripts\windows\run_strategy_c_sequence_timeline\run_strategy_c_sequence_timeline.bat START_NUM "YYYY:MM:DD HH:MM:SS" STEP_SECONDS`
3. Verify results:
   - `..\scripts\windows\verify_folder\verify_folder.bat`
   - `..\scripts\windows\verify_file\verify_file.bat "filename.ext"`
4. Review logs in `logs\`.

## Documentation map

- [docs/reorganized-reference.md](docs/reorganized-reference.md) - curated reading order and future-reference capture.
- [docs/README.md](docs/README.md) - step-by-step reading and execution order.
- [docs/exiftool-foundations.md](docs/exiftool-foundations.md) - beginner explanation of metadata, cloud timeline behavior, and parameter choices.
- [docs/cloud-storage-sorting/README.md](docs/cloud-storage-sorting/README.md) - cloud storage comparison and per-service guides (Google Photos, Mega, OneDrive, Amazon Photos, iCloud Photos).
  - [docs/cloud-storage-sorting/google-photos.md](docs/cloud-storage-sorting/google-photos.md) - Google Photos sorting, metadata priority, timezone handling.
  - [docs/cloud-storage-sorting/mega.md](docs/cloud-storage-sorting/mega.md) - Mega sorting by FileModifyDate; lenient metadata handling.
  - [docs/cloud-storage-sorting/onedrive.md](docs/cloud-storage-sorting/onedrive.md) - OneDrive FileModifyDate-only sorting; metadata ignored.
  - [docs/cloud-storage-sorting/amazon-photos.md](docs/cloud-storage-sorting/amazon-photos.md) - Amazon Photos metadata-based sorting; similar to Google Photos.
  - [docs/cloud-storage-sorting/icloud-photos.md](docs/cloud-storage-sorting/icloud-photos.md) - iCloud Photos strict metadata validation; timezone required for multi-device.
- [docs/runbook-windows.md](docs/runbook-windows.md) - full SOP with script and manual command paths.
- [docs/verification-and-signoff.md](docs/verification-and-signoff.md) - go/no-go checks before upload.
- [docs/error-catalog.md](docs/error-catalog.md) - known errors, meaning, and fixes.
- [docs/conversation-analysis.md](docs/conversation-analysis.md) - workflow evolution and decision context.

## Script catalog

- [scripts/windows/README.md](scripts/windows/README.md) - index for the per-script folders.
- [scripts/windows/normalize_extensions/README.md](scripts/windows/normalize_extensions/README.md)
- [scripts/windows/run_strategy_a_filename_priority/README.md](scripts/windows/run_strategy_a_filename_priority/README.md)
- [scripts/windows/run_strategy_b_filemodify_once/README.md](scripts/windows/run_strategy_b_filemodify_once/README.md)
- [scripts/windows/run_strategy_c_sequence_timeline/README.md](scripts/windows/run_strategy_c_sequence_timeline/README.md)
- [scripts/windows/append_datetime_suffix/README.md](scripts/windows/append_datetime_suffix/README.md)
- [scripts/windows/verify_folder/README.md](scripts/windows/verify_folder/README.md)
- [scripts/windows/verify_file/README.md](scripts/windows/verify_file/README.md)

## Important safety rule

Do not rerun FileModifyDate-based write workflows on already-processed files unless you intentionally want to replace metadata with current filesystem timestamps.
