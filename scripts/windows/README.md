# Windows Script Pack

Run these scripts from the target media folder.

## Prerequisite

Set this only when ExifTool is not in the script default path:

```bat
set EXIFTOOL_PATH=C:\path\to\exiftool.exe
```

## Folder map

Each strategy now lives in its own folder with a matching README:

| Folder | Command | What it covers |
|---|---|---|
| [normalize_extensions](normalize_extensions/README.md) | `..\scripts\windows\normalize_extensions\normalize_extensions.bat` | Extension/content mismatches |
| [run_strategy_a_filename_priority](run_strategy_a_filename_priority/README.md) | `..\scripts\windows\run_strategy_a_filename_priority\run_strategy_a_filename_priority.bat` | Mixed folders with some date-bearing filenames |
| [run_strategy_b_filemodify_once](run_strategy_b_filemodify_once/README.md) | `..\scripts\windows\run_strategy_b_filemodify_once\run_strategy_b_filemodify_once.bat` | Fresh folders with trusted `FileModifyDate` |
| [run_strategy_c_sequence_timeline](run_strategy_c_sequence_timeline/README.md) | `..\scripts\windows\run_strategy_c_sequence_timeline\run_strategy_c_sequence_timeline.bat START_NUM "YYYY:MM:DD HH:MM:SS" STEP_SECONDS` | Sequence-only folders |
| [append_datetime_suffix](append_datetime_suffix/README.md) | `..\scripts\windows\append_datetime_suffix\append_datetime_suffix.bat` | Add a datetime suffix to filenames |
| [verify_folder](verify_folder/README.md) | `..\scripts\windows\verify_folder\verify_folder.bat` | Folder-level verification |
| [verify_file](verify_file/README.md) | `..\scripts\windows\verify_file\verify_file.bat "filename.ext"` | Single-file spot checks |

## Notes

- Each script writes logs to `logs\YYYYMMDD_HHMMSS_<script-name>.log` in the repository root.
- The relocated scripts preserve the original behavior; only the folder layout changed.
- Use the folder-specific README for prerequisites, warnings, and examples before running anything.
