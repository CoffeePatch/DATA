# verify_folder

This folder contains the folder-level read-only verification script.

## What it does

Reports key date tags across the folder and scans for missing image or video timeline tags.

## What it can change

- Nothing. This script is read-only.

## Important things to note

- Run it after any write strategy.
- Use the output to confirm that your sample files actually hold the dates you expected.
- If the scan is empty, that is usually a good sign, but still spot-check representative files.

## Prerequisites

- ExifTool available at the default path or through `EXIFTOOL_PATH`.
- A target media folder with the updated files.

## How to run

From the target media folder:

```bat
..\scripts\windows\verify_folder\verify_folder.bat
```

## ExifTool Commands Used

### Folder-Level Tag Report

```bat
"%ET%" -filename -DateTimeOriginal -QuickTime:CreateDate -FileModifyDate -T -ext jpg -ext jpeg -ext png -ext heic -ext webp -ext mp4 -ext mov .
```

**What it does:**
- `-filename` — Print the filename
- `-DateTimeOriginal -QuickTime:CreateDate -FileModifyDate` — Print these three date tags for each file
- `-T` — Output in tab-separated format (easier to scan)
- Shows you at a glance whether files have the dates you expect

**Expected output:**
```
Media_042641.jpg    2023:12:07 09:30:00    -                           2023:12:07 09:30:00
Media_042642.jpg    2023:12:08 10:15:00    -                           2023:12:08 10:15:00
video_001.mp4       2024:01:15 14:22:00    2024:01:15 14:22:00         2024:01:15 14:22:00
```

(A dash means the tag is missing or not applicable.)

### Missing Image Tags Scan

```bat
"%ET%" -if "not $DateTimeOriginal" -filename -ext jpg -ext jpeg -ext png -ext heic -ext webp .
```

**What it does:**
- `-if "not $DateTimeOriginal"` — Only show files that lack a capture date
- Helps you identify which files still need metadata

**Expected output:**

Empty (meaning all images have dates) or:
```
unknown_photo.jpg
badly_named_img.png
```

### Missing Video Tags Scan

```bat
"%ET%" -if "not $QuickTime:CreateDate" -filename -ext mp4 -ext mov .
```

**What it does:**
- Similar to the image scan, but for video creation dates

### What We Observed

- A successful workflow ends with empty missing-tag scans.
- Spot-checking a few rows helps confirm the dates are reasonable (not year 2000, not future dates).
- If the output shows `2025:` and you know files are from 2023, something went wrong and you should restore from backup.

## Output

- Prints folder-level tag rows.
- Prints separate missing-tag scans for images and videos.
- Writes a timestamped log under `logs\`.