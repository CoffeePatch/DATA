# run_strategy_a_filename_priority

This folder contains the mixed-folder strategy that prefers trustworthy date information in filenames, while still providing a fallback from file system timestamps.

## What it does

1. Normalizes obvious extension mismatches.
2. Writes baseline metadata from `FileModifyDate`.
3. Overrides year-prefixed filenames with the date found in the filename.

## What it can change

- File extensions.
- Embedded media date tags.
- `FileModifyDate`.
- It may also rename files when the extension normalization step finds a mismatch.

## Important things to note

- This strategy touches metadata and can change file timestamps.
- Use it only when the folder is mixed and some filenames contain a real date prefix.
- Do not treat it as a harmless repeatable cleanup if the folder has already been processed and the filesystem times have changed.
- Keep a backup before running it.

## Prerequisites

- A mixed folder with some date-bearing filenames.
- ExifTool available at the default path or through `EXIFTOOL_PATH`.
- A backup of the source folder if you need rollback protection.

## How to run

From the target media folder:

```bat
..\scripts\windows\run_strategy_a_filename_priority\run_strategy_a_filename_priority.bat
```

## ExifTool Commands Used

### Step 1: Extension Normalization

Same as `normalize_extensions` — fixes obvious extension/content mismatches.

### Step 2: Baseline Metadata from FileModifyDate

```bat
"%ET%" -api QuickTimeUTC "-AllDates<FileModifyDate" "-FileModifyDate<FileModifyDate" -ext jpg -ext jpeg -ext mp4 -ext mov -ext heic -ext webp -ext png -overwrite_original_in_place .
```

**What it does:**
- `-api QuickTimeUTC` — Ensures video timestamps are stored in UTC-safe format
- `-AllDates<FileModifyDate` — Copy the file's modification date into all standard capture date tags (for images)
- `-FileModifyDate<FileModifyDate` — Ensure the file timestamp itself matches (redundant but safe)
- `-ext jpg -ext jpeg ...` — Apply to all common media types
- `-overwrite_original_in_place` — Write directly to the file without creating backups

**Expected output:**
```
   10 image files updated
   5 video files updated
```

### Step 3: Override from Filename (Year-Prefixed Only)

```bat
"%ET%" -api QuickTimeUTC -if "$filename =~ /^(19|20)\d{2}/" "-AllDates<Filename" "-FileModifyDate<Filename" -ext jpg -ext jpeg -ext mp4 -ext mov -ext heic -ext webp -ext png -overwrite_original_in_place .
```

**What it does:**
- `-if "$filename =~ /^(19|20)\d{2}/"` — Only process files starting with 19xx or 20xx (year pattern)
- `-AllDates<Filename` — Extract the date from the filename and overwrite capture tags
- This protects random-name files from accidental date parsing errors

**Expected output:**
```
   3 image files updated
```
(Only files with year prefixes)

### What We Observed

- Step 2 guarantees all files have some valid date, even if incorrect.
- Step 3 upgrades only files with trustworthy date-bearing names, minimizing parsing errors.
- This two-pass approach recovers mixed folders without losing data.

## Output

- Step-by-step progress messages.
- A timestamped log under `logs\`.
- Exit code `0` on success, `2` if ExifTool is missing.