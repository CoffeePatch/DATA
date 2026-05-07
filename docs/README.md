# Media Metadata Documentation Hub

Use this folder to understand **what to run**, **why to run it**, and **how to verify output**.

## Curated reference

Start with [reorganized-reference.md](reorganized-reference.md) if you want the cleaned-up reading order and the capture template for future notes.

## Recommended reading for beginners

1. [exiftool-foundations.md](exiftool-foundations.md) - first-principles explanation (what ExifTool is, why timeline metadata matters, when parameter changes are truly required).
2. [cloud-storage-sorting/README.md](cloud-storage-sorting/README.md) - cloud storage sorting behavior (how each service prioritizes metadata; what tags each media type requires; timezone handling; common failure patterns).
   - [cloud-storage-sorting/google-photos.md](cloud-storage-sorting/google-photos.md) - Choose this if uploading to Google Photos
   - [cloud-storage-sorting/mega.md](cloud-storage-sorting/mega.md) - Choose this if uploading to Mega
   - [cloud-storage-sorting/onedrive.md](cloud-storage-sorting/onedrive.md) - Choose this if uploading to OneDrive
   - [cloud-storage-sorting/amazon-photos.md](cloud-storage-sorting/amazon-photos.md) - Choose this if uploading to Amazon Photos
   - [cloud-storage-sorting/icloud-photos.md](cloud-storage-sorting/icloud-photos.md) - Choose this if uploading to iCloud Photos
3. [runbook-windows.md](runbook-windows.md) - complete script and manual command SOP.
4. [../scripts/windows/README.md](../scripts/windows/README.md) - folder-based script index and command reference.
5. [verification-and-signoff.md](verification-and-signoff.md) - validation checklist before upload.
6. [error-catalog.md](error-catalog.md) - failure patterns and exact recovery actions.

## Recommended execution order

1. Read [runbook-windows.md](runbook-windows.md) for the complete SOP.
2. Choose one strategy script from [../scripts/windows/README.md](../scripts/windows/README.md).
3. Run verification steps from [verification-and-signoff.md](verification-and-signoff.md).
4. If errors appear, use [error-catalog.md](error-catalog.md) for exact recovery actions.

## Step-by-step command flow

### Step 1: Open Command Prompt in target media folder

All scripts should be run from the folder that contains your media files.

### Step 2: Choose exactly one metadata strategy

| Situation | Command |
|---|---|
| Mixed folder, some filenames include real date/time | `..\scripts\windows\run_strategy_a_filename_priority\run_strategy_a_filename_priority.bat` |
| Fresh folder, Date Modified is trusted, one-time write | `..\scripts\windows\run_strategy_b_filemodify_once\run_strategy_b_filemodify_once.bat` |
| Sequence-only filenames (for example `Media_049682`) | `..\scripts\windows\run_strategy_c_sequence_timeline\run_strategy_c_sequence_timeline.bat START_NUM "YYYY:MM:DD HH:MM:SS" STEP_SECONDS` |

### Step 3: Run verification

```bat
..\scripts\windows\verify_folder\verify_folder.bat
..\scripts\windows\verify_file\verify_file.bat "filename.ext"
```

### Step 4: Review logs

Every script creates a timestamped log file under:

`logs\YYYYMMDD_HHMMSS_<script-name>.log`

### Step 5: Decide go/no-go

Use `verification-and-signoff.md` checklist before upload.

## How scripts respond

- **Normal success**: script prints `Exit code: 0` and log file path.
- **ExifTool missing**: script prints `ERROR: ExifTool not found ...` and exits with code `2`.
- **Missing required argument** (parameterized scripts): usage text is printed and script exits non-zero.
- **Verify file not found** (`verify_file.bat`): script prints file-not-found error and exits non-zero.

## Folder notes

Each script now has its own folder under `../scripts/windows/` with a local README that explains behavior, change scope, prerequisites, and run instructions.

## What to read first

1. [exiftool-foundations.md](exiftool-foundations.md) - beginner-first background and decision logic.
2. [cloud-storage-sorting/README.md](cloud-storage-sorting/README.md) - cloud storage sorting: pick your target service and read the corresponding guide.
   - [cloud-storage-sorting/google-photos.md](cloud-storage-sorting/google-photos.md) - Google Photos
   - [cloud-storage-sorting/mega.md](cloud-storage-sorting/mega.md) - Mega
   - [cloud-storage-sorting/onedrive.md](cloud-storage-sorting/onedrive.md) - OneDrive
   - [cloud-storage-sorting/amazon-photos.md](cloud-storage-sorting/amazon-photos.md) - Amazon Photos
   - [cloud-storage-sorting/icloud-photos.md](cloud-storage-sorting/icloud-photos.md) - iCloud Photos
3. [runbook-windows.md](runbook-windows.md) - full script + manual command SOP.
4. [../scripts/windows/README.md](../scripts/windows/README.md) - each script purpose, command, and output.
5. [verification-and-signoff.md](verification-and-signoff.md) - validation and sign-off criteria.
6. [error-catalog.md](error-catalog.md) - warning/error meanings and fixes.
7. [conversation-analysis.md](conversation-analysis.md) - workflow reasoning and history context.

## Core rule

Never rerun a FileModifyDate-to-metadata write strategy on already-processed files unless replacement is intentional.
