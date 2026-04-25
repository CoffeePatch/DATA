# ExifTool Foundations: What, Why, and How

This guide explains the workflow from zero knowledge: what ExifTool is, why media metadata matters for timeline sorting, and when you should (or should not) change metadata parameters.

## 1) What is ExifTool?

ExifTool is a command-line metadata editor for photos, videos, and many other file formats.

In this repository, ExifTool is used to:

- read date/time metadata from files
- write missing or incorrect date/time metadata
- align metadata so cloud galleries can sort media in the correct timeline order
- verify output after bulk operations

## 2) What problem are we solving?

Large media folders often contain mixed conditions:

- some files already have correct capture-time metadata
- some files have missing metadata
- some files have wrong extensions (`.jpg` file that is actually PNG content)
- some files use sequence-only names (`Media_049682`) with no date in filename

If these are uploaded without preparation, cloud timelines can appear out of order or with wrong dates.

## 3) How Google Photos and other cloud services use metadata

Most cloud media services (including Google Photos) use embedded media metadata as primary timeline signals.

Typical priority behavior is:

1. Embedded capture tags (image EXIF or video QuickTime date fields)
2. Filename date patterns (in some cases)
3. File system timestamps as weaker fallback

Because different services and file formats interpret fallback differently, the safest approach is to populate key embedded tags consistently before upload.

### 3.1 Timeline-critical metadata tags (practical priority)

| Media type | High-impact tags | Why they matter |
|---|---|---|
| Images (JPG/JPEG/HEIC) | `DateTimeOriginal`, `CreateDate`, `ModifyDate` | These are the core EXIF capture-time signals used by gallery timelines. |
| Videos (MP4/MOV) | `QuickTime:CreateDate`, `QuickTime:MediaCreateDate`, `QuickTime:CreationDate` | QuickTime date fields are primary timeline anchors for many video uploads. |
| Fallback only | `FileModifyDate` | Useful only as a fallback source when true capture tags are missing. |

Timezone support tags like `OffsetTimeOriginal` improve timeline consistency when platforms interpret local vs UTC differently.

### 3.2 What is "correct" metadata vs "not correct"

- **Correct metadata**:
  - capture-time tags exist
  - image/video date fields agree with each other
  - timezone context is present or date values are consistently interpreted
- **Not correct metadata**:
  - missing capture-time tags
  - conflicting values across date fields
  - dates copied from untrusted filesystem timestamps after copy/sync
  - filename-only date assumptions with no embedded tag support

### 3.3 Android vs Windows behavior (what usually happens)

- **Android (typical camera/media pipeline)**:
  - usually writes capture dates into EXIF (images) or QuickTime tags (videos)
  - may vary by app/version; some files can have incomplete timezone fields
- **Windows (filesystem + media properties)**:
  - exposes both embedded metadata and filesystem timestamps
  - copy/move/export can change `FileModifyDate`, which can become unsafe as a future metadata source

Operational rule: prefer embedded capture tags over filesystem times for timeline truth.

## 4) Why direct upload can fail

Direct upload can produce timeline issues when:

- key tags are missing (`DateTimeOriginal` for images, `QuickTime:CreateDate` for videos)
- file system timestamps were already modified during copy/sync
- filename date parsing is inconsistent
- content/extension mismatch causes metadata writes to skip silently

That is why this repository starts with extension normalization, then applies one explicit date-source strategy, then verifies.

## 5) Is changing parameters truly required?

Not always. Only change parameters when source quality or folder type demands it.

Use this decision model:

- **Strategy A (filename-priority override after fallback)**  
  Use when some filenames contain trustworthy real date/time.
- **Strategy B (FileModifyDate once)**  
  Use only on fresh folders where Date Modified is known-good.
- **Strategy C (synthetic sequence timeline)**  
  Use when names are sequence-only and no real timestamp source exists.

If a folder already has correct embedded tags, avoid rewriting metadata.

## 6) Essential ExifTool parameter intent used in this repo

- `-api QuickTimeUTC`  
  Enforces UTC-safe handling for QuickTime date fields (important for video consistency).
- `"-AllDates<SourceTag"`  
  Copies source date into core EXIF date group for images.
- `"-QuickTime:CreateDate<SourceTag"` and related QuickTime assignments  
  Populates video timeline fields.
- `-overwrite_original_in_place`  
  Required for safer rewrites on Windows paths and Unicode edge cases.
- `-if "condition"`  
  Restricts updates to files matching explicit rules (prevents broad bad writes).

## 7) Single-file vs multi-file commands

### Single media file (manual check/update pattern)

Read one file:

```bat
"%EXIFTOOL_PATH%" -filename -DateTimeOriginal -QuickTime:CreateDate -FileModifyDate "Media_049686.mp4"
```

Write one file from trusted file system date:

```bat
"%EXIFTOOL_PATH%" -api QuickTimeUTC "-DateTimeOriginal<FileModifyDate" "-QuickTime:CreateDate<FileModifyDate" -overwrite_original_in_place "Media_049686.mp4"
```

### Multiple files (batch)

Repository scripts are the preferred batch method:

- `..\scripts\windows\run_strategy_a_filename_priority.bat`
- `..\scripts\windows\run_strategy_b_filemodify_once.bat`
- `..\scripts\windows\run_strategy_c_sequence_timeline.bat START_NUM "YYYY:MM:DD HH:MM:SS" STEP_SECONDS`

Manual batch mode (runbook equivalent) is documented in [runbook-windows.md](runbook-windows.md).

## 8) Professional workflow order (recommended)

1. Backup folder.
2. Run extension normalization.
3. Run exactly one strategy (A, B, or C).
4. Verify folder-level and sample file-level tags.
5. Review logs under `logs\`.
6. Upload only after sign-off checklist passes.

Use [verification-and-signoff.md](verification-and-signoff.md) as the final gate.
