# Windows Runbook (ExifTool)

This runbook is designed for large, mixed media folders and repeated operations.

## 0) Preconditions and setup

1. Backup first
   - Make a full copy of the folder before writing metadata.

2. Open Command Prompt inside target folder.

3. Recommended: use scripts from this repository
   - `..\scripts\windows\README.md`

4. Optional: define ExifTool path if your install path is non-default:

```bat
set EXIFTOOL_PATH=C:\path\to\exiftool.exe
```

## 1) Script-first execution

Run exactly one strategy script depending on folder type.

### Strategy A script (mixed folder, some names include real dates)

```bat
..\scripts\windows\run_strategy_a_filename_priority.bat
```

### Strategy B script (fresh folder with trusted Date Modified)

```bat
..\scripts\windows\run_strategy_b_filemodify_once.bat
```

### Strategy C script (sequence-only names like Media_XXXXXX)

```bat
..\scripts\windows\run_strategy_c_sequence_timeline.bat START_NUM "YYYY:MM:DD HH:MM:SS" STEP_SECONDS
```

Example:

```bat
..\scripts\windows\run_strategy_c_sequence_timeline.bat 49682 "2025:08:07 14:34:00" 300
```

Then verify:

```bat
..\scripts\windows\verify_folder.bat
..\scripts\windows\verify_file.bat "Media_049685.jpg"
..\scripts\windows\verify_file.bat "Media_049686.mp4"
```

## 2) Manual fallback commands (if scripts are not used)

### 2.1 Normalize wrong extensions (safe pre-pass)

Run all five checks. They only rename when file content type mismatches extension.

```bat
"%EXIFTOOL_PATH%" -ext jpg  -if "$FileType eq 'PNG'"  "-FileName=%f.png" .
"%EXIFTOOL_PATH%" -ext png  -if "$FileType eq 'JPEG'" "-FileName=%f.jpg" .
"%EXIFTOOL_PATH%" -ext heic -if "$FileType eq 'JPEG'" "-FileName=%f.jpg" .
"%EXIFTOOL_PATH%" -ext webp -if "$FileType eq 'JPEG'" "-FileName=%f.jpg" .
"%EXIFTOOL_PATH%" -ext jpg  -if "$FileType eq 'WEBP'" "-FileName=%f.webp" .
```

### 2.2 Choose exactly one source strategy

Do not mix strategies unless explicitly required.

### Strategy A: Filename contains real date/time

Use this when names include valid date tokens (examples: 2024-11-07_223757.png, IMG_20240707...).

1) Baseline fallback from file system date (one pass):

```bat
"%EXIFTOOL_PATH%" -api QuickTimeUTC "-AllDates<FileModifyDate" "-FileModifyDate<FileModifyDate" -ext jpg -ext jpeg -ext mp4 -ext mov -ext heic -ext webp -ext png -overwrite_original_in_place .
```

2) Override only files that begin with year pattern 19xx/20xx:

```bat
"%EXIFTOOL_PATH%" -api QuickTimeUTC -if "$filename =~ /^(19|20)\d{2}/" "-AllDates<Filename" "-FileModifyDate<Filename" -ext jpg -ext jpeg -ext mp4 -ext mov -ext heic -ext webp -ext png -overwrite_original_in_place .
```

Why two passes:
- pass 1 guarantees all files have some valid date
- pass 2 upgrades only files with parseable date-bearing names

### Strategy B: FileModifyDate is trusted and filename has no date

Use only on fresh folders where Date Modified is known-good.
Run once.

```bat
"%EXIFTOOL_PATH%" -api QuickTimeUTC "-DateTimeOriginal<FileModifyDate" "-QuickTime:CreateDate<FileModifyDate" "-QuickTime:MediaCreateDate<FileModifyDate" "-QuickTime:CreationDate<FileModifyDate" "-CreateDate<FileModifyDate" -ext jpg -ext jpeg -ext mp4 -ext mov -ext heic -ext webp -ext png -overwrite_original_in_place .
```

Critical warning:
- Do not rerun this blindly on already-processed files.
- If Date Modified has become "today", rerun will copy bad values into metadata.

### Strategy C: Sequence-only names (Media_XXXXXX) need synthetic timeline

Use when filenames do not include dates and you want deterministic ordering in Google Photos.

Example:
- first file number: 49682
- base datetime: 2025:08:07 14:34:00
- increment per sequence step: 300 seconds

```bat
"%EXIFTOOL_PATH%" -api QuickTimeUTC "-AllDates=2025:08:07 14:34:00" "-FileModifyDate=2025:08:07 14:34:00" "-AllDates+<${filename;$_=/(\d+)/ ? (($1-49682)*300) : 0}" "-FileModifyDate+<${filename;$_=/(\d+)/ ? (($1-49682)*300) : 0}" -ext jpg -ext jpeg -ext mp4 -ext mov -ext heic -ext webp -ext png -overwrite_original_in_place .
```

Notes:
- This forces timeline by sequence, not by capture truth.
- Keep separate from real-date folders.

## 3) Optional filename safety suffix (preserve sequence-first sort)

Recommended script:

```bat
..\scripts\windows\append_datetime_suffix.bat
```

Manual equivalent:

Appends datetime to name while keeping prefix order stable.

```bat
"%EXIFTOOL_PATH%" -api QuickTimeUTC -d "%%f_%Y%m%d_%H%M%S.%%e" "-FileName<DateTimeOriginal" "-FileName<QuickTime:CreateDate" -ext jpg -ext jpeg -ext mp4 -ext mov -ext heic -ext webp -ext png -overwrite_original_in_place .
```

Result shape:
- Media_060157.jpg -> Media_060157_20250807_143420.jpg

## 4) Logs and audit trail

All scripts create timestamped log files in:

- `logs\YYYYMMDD_HHMMSS_<script-name>.log`

Review logs before upload and retain them until upload verification is complete.

## 5) Stop conditions

Stop immediately and isolate files when:
- format errors continue after extension normalization
- rerun risk exists due to Date Modified changing to now
- warnings indicate widespread filename parse failures

In those cases, move only problematic files into a temporary folder, fix them there, then merge back.
