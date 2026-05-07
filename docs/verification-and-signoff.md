# Verification and Sign-off

## Script-first verification

Run from target folder:

```bat
..\scripts\windows\verify_folder\verify_folder.bat
..\scripts\windows\verify_file\verify_file.bat "Media_049685.jpg"
..\scripts\windows\verify_file\verify_file.bat "Media_049686.mp4"
```

Each run generates a timestamped log in `logs\`.

## Manual fallback

If needed, define this first:

```bat
set EXIFTOOL_PATH=C:\path\to\exiftool.exe
```

## A) Folder-level cross-check (read-only)

```bat
"%EXIFTOOL_PATH%" -filename -DateTimeOriginal -QuickTime:CreateDate -FileModifyDate -T -ext jpg -ext jpeg -ext png -ext heic -ext webp -ext mp4 -ext mov .
```

Interpretation:
- images should have DateTimeOriginal
- videos should have QuickTime:CreateDate
- FileModifyDate may differ for videos (UTC handling), this can still be correct

## B) Single-file check (image)

```bat
"%EXIFTOOL_PATH%" -filename -DateTimeOriginal -FileModifyDate "Media_049685.jpg"
```

Pass criteria:
- DateTimeOriginal exists and is valid

## C) Single-file check (video)

```bat
"%EXIFTOOL_PATH%" -filename -DateTimeOriginal -QuickTime:CreateDate -FileModifyDate "Media_049686.mp4"
```

Pass criteria:
- QuickTime:CreateDate exists
- local and UTC offsets are logically consistent when QuickTimeUTC was used

## D) Quick missing-tag scan

Images missing DateTimeOriginal:

```bat
"%EXIFTOOL_PATH%" -if "not $DateTimeOriginal" -filename -ext jpg -ext jpeg -ext png -ext heic -ext webp .
```

Videos missing QuickTime create date:

```bat
"%EXIFTOOL_PATH%" -if "not $QuickTime:CreateDate" -filename -ext mp4 -ext mov .
```

## E) Go/No-Go checklist before upload

Go when all are true:
1. Extension normalization pass completed without unresolved format errors.
2. Selected source strategy completed (A, B, or C).
3. Spot checks passed for at least:
   - 3 image files across folder range
   - 3 video files across folder range
4. Missing-tag scans are empty or intentionally accepted.
5. Backup is retained until upload verification is complete.

No-Go when any is true:
- widespread invalid date parsing warnings during filename override
- key tags missing on sampled files
- unresolved write failures due to format or filename issues
