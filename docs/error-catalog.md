# Error Catalog and Recovery Guide

## First response order

1. Run `..\scripts\windows\normalize_extensions\normalize_extensions.bat`
2. Re-run the selected strategy script
3. Run `..\scripts\windows\verify_folder\verify_folder.bat`

## 1) Not a valid JPG (looks more like a PNG)

Meaning:
- Extension says .jpg but real content is PNG.

Fix:

```bat
"%EXIFTOOL_PATH%" -ext jpg -if "$FileType eq 'PNG'" "-FileName=%f.png" .
```

## 2) Not a valid WEBP (looks more like a JPEG)

Meaning:
- Extension says .webp but real content is JPEG.

Fix:

```bat
"%EXIFTOOL_PATH%" -ext webp -if "$FileType eq 'JPEG'" "-FileName=%f.jpg" .
```

## 3) Use -overwrite_original_in_place to write files with Unicode surrogate characters

Meaning:
- Standard overwrite mode could not safely rewrite some Windows filenames.

Fix:
- Use -overwrite_original_in_place for write commands.

## 4) Warning: No support for unicode surrogates

Meaning:
- Path scanning warning on Windows for special Unicode cases.

Action:
- Usually non-fatal if updates still succeed.
- Continue with -overwrite_original_in_place and verify sample files.

## 5) Invalid date/time or month out of range

Meaning:
- Filename parser tried to interpret non-date numeric strings as dates.

Fix:
- Restrict filename-based override to year-prefixed names only:

```bat
-if "$filename =~ /^(19|20)\d{2}/"
```

## 6) Files unchanged / failed condition

Meaning:
- Files did not match filter condition.

Action:
- This is expected for random-name files in Strategy A pass 2.
- Ensure pass 1 already assigned fallback dates.

## 7) Rerun risk: metadata overwritten with today

Meaning:
- A FileModifyDate-source command was rerun after file system timestamps changed.

Prevention:
- Run Date-from-FileModify strategy once only on fresh/trusted folders.
- For retries, isolate only failed files in separate folder.

## 8) Malformed UTF-8 / filename encoding warnings

Meaning:
- Some filenames carry encoding issues.

Action:
- Often warning-level only.
- Verify output counts and perform targeted sample checks.
- If writes fail, isolate those files and process in smaller batch.

## 9) Quick script mapping for incidents

- extension mismatch incident: `normalize_extensions/normalize_extensions.bat`
- mixed folder incident: `run_strategy_a_filename_priority/run_strategy_a_filename_priority.bat`
- fresh trusted-folder incident: `run_strategy_b_filemodify_once/run_strategy_b_filemodify_once.bat`
- sequence-only incident: `run_strategy_c_sequence_timeline/run_strategy_c_sequence_timeline.bat`
- validation incident: `verify_folder/verify_folder.bat` and `verify_file/verify_file.bat`
