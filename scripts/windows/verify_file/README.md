# verify_file

This folder contains the single-file read-only check.

## What it does

Shows the key date tags for one named file so you can spot-check the result of a write strategy.

## What it can change

- Nothing. This script is read-only.

## Important things to note

- Use it for quick spot checks, not as a replacement for folder-level verification.
- It returns a non-zero exit code if the file is missing.
- The filename must be passed exactly as it exists in the folder.

## Prerequisites

- ExifTool available at the default path or through `EXIFTOOL_PATH`.
- A specific file to inspect.

## How to run

From the target media folder:

```bat
..\scripts\windows\verify_file\verify_file.bat "filename.ext"
```

## ExifTool Commands Used

```bat
"%ET%" -filename -DateTimeOriginal -QuickTime:CreateDate -FileModifyDate "%TARGET%"
```

**What it does:**
- `-filename` — Print the filename
- `-DateTimeOriginal` — Image capture date (if present)
- `-QuickTime:CreateDate` — Video creation date (if present)
- `-FileModifyDate` — Windows filesystem timestamp
- `"%TARGET%"` — The specific file you named

**Expected output:**

For an image:
```
FileName                         : Media_042641.jpg
Date/Time Original               : 2023:12:07 09:30:00
QuickTime Create Date            : (tag not set)
File Modification Date/Time      : 2023:12:07 09:30:00
```

For a video:
```
FileName                         : video_001.mp4
Date/Time Original               : (tag not set)
QuickTime Create Date            : 2024:01:15 14:22:00
File Modification Date/Time      : 2024:01:15 14:22:00
```

### What We Observed

- If `DateTimeOriginal` is missing for images, something went wrong in the write strategy.
- Video files typically show dates only in `QuickTime:CreateDate`, not `DateTimeOriginal`.
- A mismatch between the three date columns usually means a strategy was run twice or the file was touched by Windows.
- Spot-checking at least 3 images and 3 videos after any write strategy is good practice.

## Output

- Prints selected date tags for the file.
- Writes a timestamped log under `logs\`.