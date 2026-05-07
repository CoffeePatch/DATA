# run_strategy_c_sequence_timeline

This folder contains the deterministic sequence-based timeline strategy.

## What it does

1. Optionally normalizes obvious extension mismatches.
2. Builds a synthetic timeline from a starting sequence number, a base datetime, and a step size in seconds.
3. Applies the generated time to the embedded metadata and `FileModifyDate`.

## What it can change

- File extensions during the optional pre-pass.
- Embedded image and video timestamps.
- `FileModifyDate`.

## Important things to note

- This strategy expects sequence-only filenames such as `Media_049682`.
- You must provide all three arguments or the script shows usage and exits.
- Make sure the start number and step size match the naming pattern you actually have.
- Keep a backup before using it on large sets.

## Prerequisites

- ExifTool available at the default path or through `EXIFTOOL_PATH`.
- A sequence-only folder with a reliable numbering scheme.
- A chosen start number, base datetime, and step size.

## How to run

From the target media folder:

```bat
..\scripts\windows\run_strategy_c_sequence_timeline\run_strategy_c_sequence_timeline.bat START_NUM "YYYY:MM:DD HH:MM:SS" STEP_SECONDS
```

Example:

```bat
..\scripts\windows\run_strategy_c_sequence_timeline\run_strategy_c_sequence_timeline.bat 49682 "2025:08:07 14:34:00" 300
```

## ExifTool Commands Used

### Optional Pre-Pass: Extension Normalization

Same as `normalize_extensions`.

### Main: Synthetic Timeline from Sequence Number

```bat
"%ET%" -api QuickTimeUTC "-AllDates=%BASE_DT%" "-FileModifyDate=%BASE_DT%" "-AllDates+<${filename;$_=/(%d+)/ ? (($1-%START_NUM%)*%STEP_SEC%) : 0}" "-FileModifyDate+<${filename;$_=/(%d+)/ ? (($1-%START_NUM%)*%STEP_SEC%) : 0}" -ext jpg -ext jpeg -ext mp4 -ext mov -ext heic -ext webp -ext png -overwrite_original_in_place .
```

**What it does:**
- `-AllDates=%BASE_DT%` — Set all capture date tags to the base datetime you provided
- `-AllDates+<${filename;...}` — Then add an offset calculated from the filename
- `$_=/(%d+)/ ? (($1-%START_NUM%)*%STEP_SEC%) : 0` — Extract the sequence number from the filename, subtract the start number, multiply by step seconds to get an offset
- Result: File `Media_49682` gets base time, `Media_49683` gets base + 300 seconds, `Media_49684` gets base + 600 seconds, etc.

**Example:**

If you run:
```bat
run_strategy_c_sequence_timeline.bat 49682 "2025:08:07 14:34:00" 300
```

Then:
- `Media_49682.jpg` → 2025:08:07 14:34:00
- `Media_49683.jpg` → 2025:08:07 14:39:00 (5 minutes later)
- `Media_49684.jpg` → 2025:08:07 14:44:00 (10 minutes later)

**Expected output:**
```
   100 image files updated
   25 video files updated
```

### What We Observed

- This strategy works only when filenames are purely numeric or contain a sequence pattern.
- It sacrifices absolute accuracy for deterministic, reproducible ordering.
- Useful for archives where only the relative sequence matters, not the exact capture time.
- The math-based offset ensures no two files ever get the same timestamp.

## Output

- Prints the values it received.
- Shows the optional normalization pass.
- Writes a timestamped log under `logs\`.