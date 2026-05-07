# Mega Cloud Storage Sorting and Metadata Behavior

Mega is a general-purpose cloud storage service that sorts media primarily by **file system timestamp**, with optional metadata reading (but metadata is NOT the primary sort source).

## Sorting priority

1. **File system timestamp** (FileModifyDate) ← Primary sort
2. **Filename date pattern** (if filesystem timestamp unreliable)
3. **Embedded metadata** (read but not prioritized for timeline sorting)
4. **Upload date** (only if all above missing)

**Key difference from Google Photos:** Mega ignores embedded EXIF metadata for timeline sorting and uses filesystem timestamps instead.

---

## Image Files (.jpg, .jpeg, .png, .webp, .heic, .gif, .bmp)

### What Mega checks

| Priority | Source | What it looks for | If missing |
|---|---|---|---|
| 1 | `FileModifyDate` (Windows) | The file's modification timestamp | Uses upload date |
| 2 | Filename pattern | Dates in filename like `2024-01-15` or `IMG_20240115` | Uses upload date |
| 3 | Embedded EXIF | Reads `DateTimeOriginal`, `CreateDate` (NOT used for sorting; info only) | Ignored for sorting |
| 4 | Upload date | Date file was uploaded to Mega | Fallback |

### Expected metadata structure (Mega-friendly image)

```
Filename: IMG_20240115_091234.jpg
FileModifyDate: 2024:01:15 09:12:34 ← This is what Mega sorts by
DateTimeOriginal: 2024:01:15 09:12:34 (nice-to-have; not used for sorting)
CreateDate: 2024:01:15 09:12:34 (nice-to-have; not used for sorting)
```

### Common issues

- **Copied files** → FileModifyDate changes to copy time; files sort into wrong date
- **Downloaded files** → FileModifyDate becomes download time, not original capture time
- **Screenshot archives** → FileModifyDate = save time; may not reflect actual photo date
- **EXIF metadata** → Mega reads it but doesn't use it for timeline sorting

### Go/No-go check

✅ Correct: All images show correct modified dates; timeline matches folders/years  
❌ Wrong: All images show today's date because they were copied recently

---

## Video Files (.mp4, .mov, .mkv, .avi, .webm)

### What Mega checks

| Priority | Source | What it looks for |
|---|---|---|
| 1 | `FileModifyDate` | The file's modification timestamp |
| 2 | Filename pattern | Dates in filename |
| 3 | Embedded metadata | Reads but doesn't prioritize |
| 4 | Upload date | Last resort |

### Expected metadata structure

```
Filename: VID_20240115_091234.mp4
FileModifyDate: 2024:01:15 09:12:34 ← Mega sorts by this
QuickTime:CreateDate: 2024:01:15 09:12:34 (informational only)
```

### Common issues

- **Videos from cloud sync** → FileModifyDate set to sync time, not creation time
- **Re-encoded videos** → ffmpeg sets FileModifyDate to processing time
- **iPhone/Android videos** → FileModifyDate may differ from embedded timestamps
- **Backed up videos** → FileModifyDate changes to backup time

---

## Timezone Handling

### How Mega interprets FileModifyDate

- Uses local device timezone at time of file operation
- Converts to UTC for storage
- No special handling needed; filesystem timestamp is timezone-aware by default

### No timezone safety needed

- Unlike Google Photos, Mega doesn't require `-api QuickTimeUTC`
- Mega depends on Windows filesystem timestamps, which are already localized
- Multiple devices with different timezones will sort by their local timestamps (which is correct)

---

## Supported Media Types

| Category | Formats | Sorting |
|---|---|---|
| **Images** | JPG, PNG, GIF, WebP, HEIC, TIFF, BMP | By FileModifyDate |
| **Videos** | MP4, MOV, MKV, AVI, WebM, 3GP | By FileModifyDate |
| **Documents** | PDF, DOC, XLS, PPT (not relevant here) | By FileModifyDate |

**Note:** Mega supports almost all image and video formats; sorting is always by FileModifyDate regardless of format.

---

## File Ordering Behavior

### Timeline organization

Mega shows files in folders and galleries sorted by FileModifyDate, newest first.

### No automatic grouping

- Burst sequences are NOT automatically grouped
- Panoramas are NOT automatically detected
- Related images/videos must be manually organized

### Simple linear sort

Files appear in chronological order by FileModifyDate, period. No smart grouping.

---

## Failure Scenarios and Fixes

### Scenario 1: Copied files show wrong date

```
File: photo_from_2020.jpg
Original FileModifyDate: 2020:12:15 14:30
After copy: FileModifyDate: 2025:05:07 (today)
```

**Result:** Photo appears in "May 2025" folder instead of "December 2020"

**Fix:** Run ExifTool to restore FileModifyDate from embedded metadata or filename:
```bat
exiftool "-FileModifyDate<DateTimeOriginal" photo_from_2020.jpg
```

### Scenario 2: Downloaded files all show download date

```
Batch of photos downloaded from email/WhatsApp:
All files: FileModifyDate = 2025:05:07 (download time)
Actual photo dates: 2020–2024 (lost)
```

**Result:** Entire batch sorts as today's date

**Fix:** Use Strategy A (filename priority) or restore from DateTimeOriginal:
```bat
exiftool "-FileModifyDate<DateTimeOriginal" *.jpg
```

### Scenario 3: Multi-source archive mixes up dates

```
Original files from phone: FileModifyDate = capture time
Files from cloud sync: FileModifyDate = sync time
Files from backup: FileModifyDate = backup time
```

**Result:** Same photos appear in multiple date folders

**Fix:** Normalize all FileModifyDate values to a consistent source (use Strategy A or B from [../../runbook-windows.md](../../runbook-windows.md))

---

## Pre-Upload Verification Checklist

| Step | Check | Pass Criteria |
|---|---|---|
| 1 | Extension mismatch scan | No mismatched extensions (optional; Mega is lenient) |
| 2 | FileModifyDate reasonableness | All dates in expected range, not today unless intentional |
| 3 | Date consistency | Photos from same batch should cluster in same date folder |
| 4 | Spot check samples | Open Mega web gallery; dates match expectations |
| 5 | Local backup | Backup until verified in Mega |

---

## Recommended Workflow for Mega

1. **Identify the source of truth** → Is it filename dates or embedded metadata?
2. **Normalize FileModifyDate** → Use one of the scripts from [../../runbook-windows.md](../../runbook-windows.md) to set filesystem timestamps
3. **Optional: Verify embedded metadata** → Run `verify_folder.bat` from [../../scripts/windows/verify_folder/README.md](../../scripts/windows/verify_folder/README.md)
4. **Upload to Mega** → FileModifyDate will be the visible timeline
5. **Verify in Mega web gallery** → Check that photos appear in correct date folders

---

## Key Differences from Google Photos

| Feature | Google Photos | Mega |
|---|---|---|
| **Primary sort** | Embedded metadata (DateTimeOriginal) | FileModifyDate (filesystem) |
| **Timezone handling** | Strict; uses UTC with OffsetTime | Automatic; uses device local time |
| **Metadata checking** | Strict; validates multiple tags | Lenient; reads but doesn't validate for sorting |
| **Automatic grouping** | Bursts, panoramas, duplicates | No automatic grouping |
| **Supported formats** | Limited; strict validation | Broad; almost any format |
| **Sorting sensitivity** | Very sensitive to metadata | Sensitive to filesystem timestamps |

---

## When to use Mega for media storage

- You want simplicity; Mega doesn't require metadata preparation
- FileModifyDate is your source of truth (freshly downloaded or transferred files)
- You need broad device support (Windows, Mac, Linux, mobile)
- You want basic backup without timeline features
- You prefer to organize by folders rather than automatic date sorting

---

## When NOT to use Mega alone for photo library

- Your photos have mixed sources (phones, cameras, downloads, cloud syncs)
- FileModifyDate is unreliable or has changed
- You want automatic timeline and date-based organization
- You need to preserve captured metadata for future services (use Google Photos instead)

---

## Final Note

**Mega is best for general backup, not for primary photo library management.** If timeline and capture-date sorting matter, use Google Photos or Amazon Photos. If using Mega for photo organization, ensure FileModifyDate is correct before upload.
