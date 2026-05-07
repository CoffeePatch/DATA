# append_datetime_suffix

This folder contains the filename-safety-net rename script.

## What it does

Adds a datetime suffix to the filename while keeping the original prefix intact. The goal is to preserve ordering information in the name while exposing a readable date suffix for future reference.

## What it can change

- Filename only.
- It does not directly rewrite embedded capture metadata.
- It can rename files based on `DateTimeOriginal` or `QuickTime:CreateDate`.

## Important things to note

- Use this only after the metadata is already correct.
- If the date tags are wrong or missing, the suffix will not be useful.
- This is a backup-oriented naming step, not a replacement for verification.

## Prerequisites

- The files should already have valid capture metadata.
- ExifTool available at the default path or through `EXIFTOOL_PATH`.

## How to run

From the target media folder:

```bat
..\scripts\windows\append_datetime_suffix\append_datetime_suffix.bat
```

## ExifTool Commands Used

```bat
"%ET%" -api QuickTimeUTC -d "%%f_%%Y%%m%%d_%%H%%M%%S.%%e" "-FileName<DateTimeOriginal" "-FileName<QuickTime:CreateDate" -ext jpg -ext jpeg -ext mp4 -ext mov -ext heic -ext webp -ext png -overwrite_original_in_place .
```

**What it does:**
- `-d "%%f_%%Y%%m%%d_%%H%%M%%S.%%e"` — Format string: keep original filename (`%%f`), add underscore, add date (`%%Y%%m%%d` = YYYYMMDD), add time (`%%H%%M%%S` = HHMMSS), add extension (`%%e`)
- `-FileName<DateTimeOriginal` — Use the image's capture date if present
- `-FileName<QuickTime:CreateDate` — Fall back to video creation date if no image capture date
- Result: `Media_042641.jpg` becomes `Media_042641_20231207_093000.jpg`

**Expected output:**
```
   50 image files renamed
   10 video files renamed
```

### What We Observed

- This is a naming safety net, not a metadata fix.
- It only works if the capture metadata is already correct; if tags are missing or wrong, the rename reflects that error.
- The suffix makes the date visible in the filename, so even if metadata is stripped later, the date remains in the name.
- Useful as a final step for archival or cloud uploads.

## Output

- Prints a short rename status.
- Writes a timestamped log under `logs\`.