# Conversation Analysis and User Intent

## Purpose of the original conversation

The primary objective was to make large media batches upload-ready for Google Photos by ensuring image/video date tags are populated correctly and sorted logically.

The secondary objective was durability:
- avoid repeating previous metadata damage
- keep deterministic naming and ordering
- build repeatable commands for new folders

## What the user really wanted

1. Reliability over experimentation
   - A process that works repeatedly on many folders, including 20k+ files.

2. Correct Google Photos timeline
   - For images: DateTimeOriginal must exist and be meaningful.
   - For videos: QuickTime create dates must exist and be timezone-safe.

3. Protection from earlier failure mode
   - Previous damage happened when metadata was rewritten from changed FileModifyDate values (often "today").

4. Practical automation
   - One command or compact workflow, but with safety rails.

5. Recoverability
   - If metadata is lost later, filename should still preserve key time info.

## Major problems encountered in the chats

1. Wrong extension vs real file type
   - Examples: JPG files that are actually PNG, WEBP files that are actually JPEG.
   - Impact: ExifTool skips writes with format errors.

2. Unicode/surrogate filename handling on Windows
   - Symptom: "No support for unicode surrogates" and "Use -overwrite_original_in_place".
   - Impact: some files were skipped unless in-place overwrite was used.

3. Filename date parsing failures
   - Numeric IDs like 1879... were mistaken as date values, causing month out-of-range warnings.
   - Impact: some files stayed unchanged when filename-based parsing was applied too broadly.

4. Re-run risk with FileModifyDate as source
   - If files were already touched, file system timestamps could be "today".
   - Impact: rerunning bulk copy from FileModifyDate could destroy valid historical metadata.

5. Mixed-source folders
   - Some files had trustworthy dates in filename, others only in file system metadata.
   - Impact: required two-pass logic (fallback + selective override), not single blind command.

## Workflow evolution (high-level)

1. Start: single universal write from FileModifyDate.
2. Add extension normalization steps for fake JPG/PNG/HEIC/WEBP.
3. Add in-place overwrite for Unicode edge cases.
4. Introduce two-pass model:
   - pass A: baseline date from FileModifyDate
   - pass B: override only where filename starts with a real year pattern
5. Add focused verification for both image and video key tags.
6. Add sequence timeline synthesis for Media_XXXXXX folders where names contain no real date.

## Final stable strategy extracted from the conversation

Use source-priority logic per folder:

1. If filename contains real datetime -> prefer filename as source.
2. Else if FileModifyDate is trustworthy and folder is fresh -> use FileModifyDate once.
3. Else if filenames are sequence-only (Media_XXXXXX) -> synthesize timeline by formula.

Always validate before upload with spot checks for both an image and a video.

## Operationalization into this repository

The conversation has been transformed into script-first operations:

- strategy A runner: `../scripts/windows/run_strategy_a_filename_priority.bat`
- strategy B runner: `../scripts/windows/run_strategy_b_filemodify_once.bat`
- strategy C runner: `../scripts/windows/run_strategy_c_sequence_timeline.bat`
- verification: `../scripts/windows/verify_folder.bat` and `../scripts/windows/verify_file.bat`

All script runs generate timestamped logs under `../logs/` for repeatability and audit.
