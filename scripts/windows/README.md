# Windows Script Pack

Run these scripts from inside the target media folder.

## Prerequisite

Set this only if your ExifTool path is different from default:

```bat
set EXIFTOOL_PATH=C:\path\to\exiftool.exe
```

## Scripts

1. `normalize_extensions.bat`
   - Fixes mismatched extensions based on actual file type.

2. `run_strategy_a_filename_priority.bat`
   - For mixed folders where some filenames carry real dates.
   - Runs normalize + fallback from FileModifyDate + selective filename override.

3. `run_strategy_b_filemodify_once.bat`
   - For fresh folders where FileModifyDate is trusted.
   - One-time strategy only.

4. `run_strategy_c_sequence_timeline.bat`
   - For sequence-only names like Media_XXXXXX.
   - Builds synthetic timeline from sequence math.

5. `append_datetime_suffix.bat`
   - Appends datetime suffix to filenames while preserving sort prefix.

6. `verify_folder.bat`
   - Folder-wide tag report + missing-tag scans.

7. `verify_file.bat "filename.ext"`
   - Single-file verification for key image/video tags.

## Strategy C usage

```bat
run_strategy_c_sequence_timeline.bat START_NUM "YYYY:MM:DD HH:MM:SS" STEP_SECONDS
```

Example:

```bat
run_strategy_c_sequence_timeline.bat 49682 "2025:08:07 14:34:00" 300
```

## Logs

Each run creates a log file under:

- `logs\YYYYMMDD_HHMMSS_<script>.log`

Use logs as execution history and audit trail before upload.
