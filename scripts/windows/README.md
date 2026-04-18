# Windows Script Pack

Run these scripts from the **target media folder**.

## Prerequisite

Set this only when ExifTool is not in the script default path:

```bat
set EXIFTOOL_PATH=C:\path\to\exiftool.exe
```

## Script quick reference

| Script | Command | Use when | What it does | Typical response |
|---|---|---|---|---|
| `normalize_extensions.bat` | `..\scripts\windows\normalize_extensions.bat` | Extensions do not match real file type | Renames wrong extensions (`jpg`↔`png`, `jpg`↔`webp`, etc.) based on detected content | Prints rename actions and summary in log |
| `run_strategy_a_filename_priority.bat` | `..\scripts\windows\run_strategy_a_filename_priority.bat` | Mixed folders, some filenames include real date/time | 1) Normalize extensions, 2) write fallback from `FileModifyDate`, 3) override year-prefixed names from filename | Prints `Step 1/3`, `Step 2/3`, `Step 3/3`, then exit code |
| `run_strategy_b_filemodify_once.bat` | `..\scripts\windows\run_strategy_b_filemodify_once.bat` | Fresh folder; `Date Modified` is trusted | 1) Normalize extensions, 2) one-time metadata write from `FileModifyDate` | Prints `Step 1/2`, `Step 2/2`, plus rerun warning |
| `run_strategy_c_sequence_timeline.bat` | `..\scripts\windows\run_strategy_c_sequence_timeline.bat START_NUM "YYYY:MM:DD HH:MM:SS" STEP_SECONDS` | Sequence-only filenames (`Media_XXXXXX`) | Builds deterministic synthetic timeline from sequence number math | Echoes input parameters and completion status |
| `append_datetime_suffix.bat` | `..\scripts\windows\append_datetime_suffix.bat` | You want date suffix in filename while keeping sequence order | Appends datetime suffix from metadata to filename | Prints rename/write actions |
| `verify_folder.bat` | `..\scripts\windows\verify_folder.bat` | After any write strategy | Runs folder-level tag report and missing-tag scans | Prints verification section headers and results |
| `verify_file.bat` | `..\scripts\windows\verify_file.bat "filename.ext"` | Spot-check single file | Shows key date tags for one file | Prints selected tags or file-not-found error |

## Strategy C examples

```bat
..\scripts\windows\run_strategy_c_sequence_timeline.bat START_NUM "YYYY:MM:DD HH:MM:SS" STEP_SECONDS
..\scripts\windows\run_strategy_c_sequence_timeline.bat 49682 "2025:08:07 14:34:00" 300
```

Concrete example:

- Start number: `49682`
- Base datetime: `2025:08:07 14:34:00`
- Step seconds: `300` (5 minutes per sequence increment)

## Exit behavior

- `Exit code: 0` = script completed.
- `Exit code: 2` = ExifTool not found at configured path.
- Non-zero usage exit = missing required arguments.
- `verify_file.bat` returns non-zero if target file does not exist.

## Logs

Each run writes a log file:

`logs\YYYYMMDD_HHMMSS_<script-name>.log`

Use logs as execution history and audit evidence before upload.
