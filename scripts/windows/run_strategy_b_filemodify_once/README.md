# run_strategy_b_filemodify_once

This folder contains the one-time workflow for fresh folders where the Windows `FileModifyDate` is already trusted.

## What it does

1. Normalizes obvious extension mismatches.
2. Writes embedded date metadata from `FileModifyDate` exactly once.

## What it can change

- File extensions.
- Embedded image and video date tags.
- `FileModifyDate` is used as the source, not just a read-only reference.

## Important things to note

- This is the most sensitive strategy in the pack because it depends on the filesystem timestamp being correct.
- Do not rerun it on files that were already processed unless you intentionally want to rebuild the metadata from the current file timestamps.
- Keep a backup before you start.

## Prerequisites

- A fresh folder where `Date Modified` is known-good.
- ExifTool available at the default path or through `EXIFTOOL_PATH`.
- A backup if you need recovery.

## How to run

From the target media folder:

```bat
..\scripts\windows\run_strategy_b_filemodify_once\run_strategy_b_filemodify_once.bat
```

## ExifTool Commands Used

### Step 1: Extension Normalization

Same as `normalize_extensions`.

### Step 2: One-Time Metadata Write

```bat
"%ET%" -api QuickTimeUTC "-DateTimeOriginal<FileModifyDate" "-QuickTime:CreateDate<FileModifyDate" "-QuickTime:MediaCreateDate<FileModifyDate" "-QuickTime:CreationDate<FileModifyDate" "-CreateDate<FileModifyDate" -ext jpg -ext jpeg -ext mp4 -ext mov -ext heic -ext webp -ext png -overwrite_original_in_place .
```

**What it does:**
- `-DateTimeOriginal<FileModifyDate` — Write to the standard image capture date field
- `-QuickTime:CreateDate<FileModifyDate` — Write to video creation date
- `-QuickTime:MediaCreateDate<FileModifyDate` — Backup video creation date field
- `-QuickTime:CreationDate<FileModifyDate` — Another video timestamp field
- `-CreateDate<FileModifyDate` — Generic capture date field (images and videos)
- All these tags ensure the date is readable by Google Photos regardless of file type

**Expected output:**
```
   50 image files updated
   10 video files updated
```

**Critical warning:** This command uses the current `FileModifyDate` as the source. If the Windows timestamp is wrong or has changed, the metadata becomes permanently incorrect.

### What We Observed

- This strategy is sensitive: it depends entirely on the filesystem timestamp being correct at the moment of execution.
- Once run, the metadata is locked in; running it again will overwrite good data with current-date values if timestamps have drifted.
- Best used only on fresh imports where the file timestamps are known to be accurate.

## Output

- Step-by-step progress messages.
- A timestamped log under `logs\`.
- A warning that the strategy should not be rerun casually.