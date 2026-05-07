# Google Photos Media Sorting and Metadata Behavior

Google Photos sorts media into a timeline based on **capture date**, not upload date or filename.

## Sorting priority

1. **Embedded capture metadata** (DateTimeOriginal for images, QuickTime:CreateDate for videos) ← Primary
2. **Filename date pattern** (if metadata missing; some services only)
3. **File system timestamp** (FileModifyDate; weakest fallback)
4. **Upload date** (only if all above missing or invalid)

**Critical rule:** If your embedded metadata is wrong or missing, files sort incorrectly regardless of filename or upload time.

---

## Image Files (.jpg, .jpeg, .png, .webp, .heic, .gif, .bmp)

### What Google Photos checks

| Priority | Tag Name | What it looks for | If missing |
|---|---|---|---|
| 1 | `DateTimeOriginal` (EXIF) | The moment the photo was taken | Falls back to next |
| 2 | `CreateDate` (EXIF alternate) | Backup capture timestamp | Falls back to next |
| 3 | Filename pattern | Dates in filename like `2024-01-15` or `IMG_20240115` | Uses file system date |
| 4 | `FileModifyDate` (Windows) | The file's modification timestamp | Uses current date (wrong) |

### Expected metadata structure (correct image)

```
Filename: IMG_20240115_091234.jpg
DateTimeOriginal: 2024:01:15 09:12:34
CreateDate: 2024:01:15 09:12:34
FileModifyDate: 2024:01:15 09:12:34 (may differ slightly)
```

### Common issues

- **HEIC files with .jpg extension** → Google Photos may refuse to display or sort them
- **PNG files from screenshots** → Often have missing or placeholder dates
- **WebP images from WhatsApp/Telegram** → Timestamps truncated or missing; upload date used instead
- **EXIF stripping on resize** → DateTimeOriginal deleted by some editors

### Go/No-go check

✅ Correct: All images show dates in expected range (e.g., 2020–2024)  
❌ Wrong: Images show dates like 2000, 2099, or today's date when they shouldn't

---

## Video Files (.mp4, .mov, .mkv, .avi, .webm)

### What Google Photos checks

| Priority | Tag Name | What it looks for | Media type |
|---|---|---|---|
| 1 | `QuickTime:CreateDate` | Video creation timestamp | MP4, MOV, M4V |
| 2 | `QuickTime:MediaCreateDate` | Backup video timestamp | MP4, MOV |
| 3 | `Matroska:DateTimeOriginal` | Metadata in MKV files | MKV |
| 4 | Filename pattern | Dates in filename | All video types |
| 5 | `FileModifyDate` | File system timestamp | All video types |

### Expected metadata structure (correct video)

```
Filename: VID_20240115_091234.mp4
QuickTime:CreateDate: 2024:01:15 09:12:34
QuickTime:MediaCreateDate: 2024:01:15 09:12:34
FileModifyDate: 2024:01:15 09:12:34
```

### Common issues

- **MP4 files from Android** → Timestamps often in local timezone; UTC conversion needed
- **Screen recordings (OBS, Camtasia)** → Create date defaults to "now"
- **Repacked videos (ffmpeg re-encode)** → Timestamps reset to 1970 or current date
- **Videos from Mega/OneDrive sync** → FileModifyDate changes; embedded timestamps become primary
- **iPhone videos (.mov)** → Usually correct; can show 2000 if edited with third-party tools

### Go/No-go check

✅ Correct: All videos show dates in expected range  
❌ Wrong: Videos show epoch (1970) or today's date when they shouldn't

---

## Timezone Handling

### How Google Photos interprets dates

- If metadata includes timezone info (`OffsetTimeOriginal`), Google Photos uses UTC
- If no timezone present, Google Photos assumes **local device timezone at upload time**
- **Problem:** Files from multiple timezones can sort incorrectly if timezone metadata missing

### What we use in this repo

The `-api QuickTimeUTC` flag in ExifTool ensures timestamps are stored in UTC-safe format, preventing timezone drift between devices.

### Example issue

| File | Metadata | Device timezone | Google Photos sees |
|---|---|---|---|
| photo1.jpg | 2024:01:15 14:30 (no TZ) | EST (UTC-5) | 2024:01:15 14:30 EST → sorts as 19:30 UTC |
| photo2.jpg | 2024:01:15 14:30 (no TZ) | PST (UTC-8) | 2024:01:15 14:30 PST → sorts as 22:30 UTC |

**Result:** Same-time photos sort 3 hours apart.

---

## Media Types Accepted

### Supported formats

| Category | Formats | Limit | Notes |
|---|---|---|---|
| **Images** | JPG, PNG, GIF, WebP, HEIC, AVIF, RAW | 10 MB per file (free storage) | RAW preserved only in Takeout |
| **Videos** | MP4, MOV, MKV, AVI, WebM | 5 GB per file | 1080p and 4K supported |
| **Burst photos** | JPG/PNG sequence | N/A | Grouped if timestamps within 1 second |
| **Panoramas** | JPG/PNG | N/A | Detected by aspect ratio + timestamps |
| **Screenshots** | PNG/JPG | N/A | Sorted by FileModifyDate if metadata missing |

### NOT supported (uploaded but not sorted correctly)

- TIFF files (old format; limited timeline support)
- BMP files (outdated; not optimized)
- WebP from certain older sources (metadata loss)
- Repacked formats without preserved metadata

---

## File Grouping Behavior

### Burst sequences

- If 3+ images have timestamps within 1 second, treated as burst
- Displayed as single thumbnail; expand to see all
- Requires valid, sequential `DateTimeOriginal`

### Panoramas

- Detected by aspect ratio (width > 2× height) AND consecutive timestamps
- Grouped automatically; no special metadata needed

### Videos with stills

- If JPG and MP4 have same timestamp (within 1 second), Google Photos links them
- Shown together in timeline

### Duplicates

- Exact-byte duplicates detected and shown once
- Does NOT detect near-duplicates or resized copies; both appear

---

## Failure Scenarios and Fixes

### Scenario 1: Missing DateTimeOriginal (images)

```
File: IMG_12345.jpg
DateTimeOriginal: (missing)
Filename: IMG_12345.jpg (no date pattern)
FileModifyDate: 2025:05:07 (today, because it was copied)
```

**Result:** Photo sorts into today's date, even though it's from 2020

**Fix:** Use Strategy A (filename priority) or add DateTimeOriginal from filename/FileModifyDate

### Scenario 2: Timezone mismatch (videos)

```
File: VID_001.mp4
QuickTime:CreateDate: 2024:01:15 14:30 (local time, no TZ tag)
Device at upload: EST (UTC-5)
```

**Result:** Video sorts as if taken at 19:30 UTC instead of 14:30 local

**Fix:** Add `OffsetTimeOriginal` or use `-api QuickTimeUTC` when writing dates

### Scenario 3: Rerun on already-processed files (Strategy B)

```
Initial:
Video file, metadata correct, FileModifyDate = 2024:01:15

After copy:
FileModifyDate changes to 2025:05:07

Rerun Strategy B:
All metadata overwritten with 2025:05:07 (WRONG)
```

**Result:** Entire library now shows today's date

**Fix:** Never rerun Strategy B. Use Strategy A instead.

---

## Pre-Upload Verification Checklist

| Step | Check | Pass Criteria |
|---|---|---|
| 1 | Extension mismatch scan | No `.heic` as JPEG; no `.jpg` as PNG |
| 2 | Missing capture date scan | Images: `DateTimeOriginal` present; Videos: `QuickTime:CreateDate` present |
| 3 | Date range check | No year 2000, 2099, or today unless intentional |
| 4 | Timezone consistency | All files from same device/timeframe show same hour |
| 5 | Spot check samples | Check 3 images + 3 videos in Google Photos; dates match |
| 6 | Local backup | Original folder backed up until upload verified |

---

## Multi-Cloud Upload Strategy

1. **Prepare metadata** → Run Strategy A or B from [../../runbook-windows.md](../../runbook-windows.md)
2. **Add filename safety** → Run `append_datetime_suffix` to preserve date in name
3. **Upload to Google Photos** → Timeline matches local timeline
4. **Sync to other services** (optional) → Mega/OneDrive use filesystem timestamps; filename suffix helps recovery
5. **Archive backup** → Keep until verified; 30 days recommended before deletion

---

## Observed Patterns

### Pattern 1: WhatsApp/Telegram imports (common failure)

- All photos show FileModifyDate = download date
- DateTimeOriginal often missing
- **Solution:** Use filename date if available, or ask for source import date

### Pattern 2: Screenshot archives

- PNGs from Windows screenshots have no EXIF data
- DateTimeOriginal shows FileModifyDate (save time, not take time)
- **Solution:** Use Filename-Based Strategy if folder has named screenshots

### Pattern 3: Multi-device family archives

- iPhone videos (MOV format, metadata correct)
- Android videos (MP4, timezone offset not encoded)
- Mixed timezones scatter files across timeline
- **Solution:** Use `-api QuickTimeUTC` to normalize all devices to UTC

### Pattern 4: Repacked videos (ffmpeg)

- Original metadata lost; ffmpeg sets creation date to write time
- All timestamps show batch-processing date
- **Solution:** Use Sequence-Based Strategy if original order known but dates lost

---

## Final Safety Rule

**Before uploading to Google Photos:**

1. ✅ Verify 10+ sample files using verification scripts
2. ✅ Confirm dates in expected range
3. ✅ Retain backup until Google Photos thumbnail preview matches
4. ✅ Check timeline AFTER upload; fix issues BEFORE sharing link

**Never assume metadata is correct just because the script ran without errors.**
