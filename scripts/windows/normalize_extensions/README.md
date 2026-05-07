# normalize_extensions

This folder holds the original extension-fix script and its usage notes.

## What it does

Renames files when the extension does not match the real file content. It uses ExifTool's file-type detection to correct common mismatches such as JPEG content saved with a `.png` extension or PNG content saved with a `.jpg` extension.

## What it can change

- Filename extension only.
- It does not write capture metadata.
- It does not intentionally change embedded timestamps.

## Important things to note

- Run it from the target media folder, not from inside the script folder.
- If a file is already correctly named, it should stay unchanged.
- This is a safe first pass before any metadata-writing strategy.

## Prerequisites

- ExifTool must be available at the default path or through `EXIFTOOL_PATH`.
- The media folder should be backed up if you want a rollback option.

## How to run

From the target media folder:

```bat
..\scripts\windows\normalize_extensions\normalize_extensions.bat
```

## ExifTool Commands Used

This script runs five extension-correction checks, each targeting a different type of mismatch:

```bat
"%ET%" -ext jpg  -if "$FileType eq 'PNG'"  "-FileName=%%f.png" .
"%ET%" -ext png  -if "$FileType eq 'JPEG'" "-FileName=%%f.jpg" .
"%ET%" -ext heic -if "$FileType eq 'JPEG'" "-FileName=%%f.jpg" .
"%ET%" -ext webp -if "$FileType eq 'JPEG'" "-FileName=%%f.jpg" .
"%ET%" -ext jpg  -if "$FileType eq 'WEBP'" "-FileName=%%f.webp" .
```

### Command Breakdown

- `-ext jpg` — Look at files with .jpg extension
- `-if "$FileType eq 'PNG'"` — But only if the real file type (detected by ExifTool) is PNG
- `"-FileName=%%f.png"` — Rename the file, keeping the original name but changing extension to .png
- `.` — Apply to the current folder and all files in it

### Expected Output

For each matching file:
```
1 file was successfully rewritten
```

If no files match a condition, no output is generated for that check.

### What We Observed

- Mismatches are common when files are copied between Android, Windows, and cloud services.
- Running this before any metadata write prevents ExifTool from silently skipping files with wrong extensions.
- The script is idempotent: running it again on already-normalized files does nothing.

## Output

- Prints the ExifTool path it is using.
- Writes a timestamped log to `logs\` in the repository root.
- Ends with a script exit code so you can tell whether it succeeded.