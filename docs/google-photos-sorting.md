# Google Photos Media Sorting and Cloud Storage Behavior

This guide explains how Google Photos (and similar cloud services like Mega, OneDrive, and Amazon Photos) sort, categorize, and display media files based on metadata.

## 1) Core Sorting Principle

Google Photos organizes your media into a timeline based on **capture date**, not upload date or filename.

The sorting hierarchy (in order of priority):

1. **Embedded capture metadata** (DateTimeOriginal for images, QuickTime:CreateDate for videos)
2. **Filename date pattern** (if metadata is missing; some services only)
3. **File system timestamp** (FileModifyDate; weakest fallback)
4. **Upload date** (only used if all above are missing or invalid)

**Why this matters:** If your embedded metadata is wrong or missing, files sort incorrectly regardless of filename or upload time.

---

## 2) Image Files (.jpg, .jpeg, .png, .webp, .heic, .gif, .bmp)

### What Google Photos checks:

| Priority | Tag Name | What it looks for | If missing |
|---|---|---|---|
| 1 | `DateTimeOriginal` (EXIF) | The moment the photo was taken | Falls back to next priority |
| 2 | `CreateDate` (EXIF alternate) | Backup capture timestamp | Falls back to next priority |
| 3 | Filename pattern | Dates in filename like `2024-01-15` or `IMG_20240115` | Uses file system date |
| 4 | `FileModifyDate` (Windows) | The file's modification timestamp | Uses current date (wrong) |

### Expected metadata structure (correct image):

```
Filename: IMG_20240115_091234.jpg
DateTimeOriginal: 2024:01:15 09:12:34
CreateDate: 2024:01:15 09:12:34
FileModifyDate: 2024:01:15 09:12:34 (may differ slightly)
```

### Common issues observed:

- **HEIC files with .jpg extension** → Google Photos may refuse to display or sort them correctly.
- **PNG files from screenshots** → Often have missing or placeholder dates; Chrome screenshots show "today's" date.
- **WebP images from WhatsApp/Telegram** → Timestamps often truncated or missing; upload date used instead.
- **EXIF stripping on resize** → If edited in basic editors, DateTimeOriginal may be deleted.

### Go/No-go check:

✅ Correct: All images show dates in the range you expect (e.g., 2020–2024).  
❌ Wrong: Images show dates like 2000, 2099, or today's date when they shouldn't.

---

## 3) Video Files (.mp4, .mov, .mkv, .avi, .webm)

### What Google Photos checks:

| Priority | Tag Name | What it looks for | Media type |
|---|---|---|---|
| 1 | `QuickTime:CreateDate` | Video creation timestamp | MP4, MOV, M4V |
| 2 | `QuickTime:MediaCreateDate` | Backup video timestamp | MP4, MOV |
| 3 | `Matroska:DateTimeOriginal` | Metadata in MKV files | MKV |
| 4 | Filename pattern | Dates in filename | All video types |
| 5 | `FileModifyDate` | File system timestamp | All video types |

### Expected metadata structure (correct video):

```
Filename: VID_20240115_091234.mp4
QuickTime:CreateDate: 2024:01:15 09:12:34
QuickTime:MediaCreateDate: 2024:01:15 09:12:34
FileModifyDate: 2024:01:15 09:12:34
```

### Common issues observed:

- **MP4 files from Android devices** → Often encode timestamps in local timezone; UTC conversion needed.
- **Screen recordings (OBS, Camtasia)** → Create date defaults to "now"; must override manually.
- **Repacked videos (ffmpeg re-encode)** → Timestamps often reset to 1970 or current date.
- **Videos from Mega/OneDrive sync** → FileModifyDate changes; embedded timestamps become primary source.
- **iPhone videos (.mov format)** → Usually correct, but can show 2000 if edited with third-party tools.

### Go/No-go check:

✅ Correct: All videos show dates in the range you expect.  
❌ Wrong: Videos show epoch (1970) or today's date when they shouldn't.

---

## 4) Timezone Handling

### How Google Photos interprets dates:

- If a metadata tag includes timezone info (`OffsetTimeOriginal`), Google Photos uses UTC.
- If no timezone is present, Google Photos assumes **local device timezone at upload time**.
- **Problem:** Files from multiple timezones can sort incorrectly if timezone metadata is missing.

### What we use in this repo:

The `-api QuickTimeUTC` flag in ExifTool ensures timestamps are stored in UTC-safe format, preventing timezone drift between devices.

### Example issue:

| File | Metadata | Device timezone | Google Photos sees |
|---|---|---|---|
| photo1.jpg | 2024:01:15 14:30 (no TZ) | EST (UTC-5) | 2024:01:15 14:30 EST → sorts as 19:30 UTC |
| photo2.jpg | 2024:01:15 14:30 (no TZ) | PST (UTC-8) | 2024:01:15 14:30 PST → sorts as 22:30 UTC |

Result: Same-time photos sort 3 hours apart.

---

## 5) Media Types Accepted by Google Photos

### Supported formats:

| Category | Formats | Limit | Notes |
|---|---|---|---|
| **Images** | JPG, PNG, GIF, WebP, HEIC, AVIF, RAW | 10 MB per file (free storage) | RAW files preserved only in Takeout |
| **Videos** | MP4, MOV, MKV, AVI, WebM | 5 GB per file | 1080p and 4K both supported |
| **Burst photos** | JPG/PNG sequence | N/A | Detected by rapid timestamps; grouped |
| **Panoramas** | JPG/PNG | N/A | Detected by width/height ratio |
| **Screenshots** | PNG/JPG | N/A | Sorted by FileModifyDate if metadata missing |

### **NOT supported (will upload but not sort correctly):**

- TIFF files (treated as images but no timeline support in some regions)
- BMP files (old format; uploaded but not optimized)
- WEBP from certain older sources (metadata loss)
- Repacked formats without preserved metadata

---

## 6) File Ordering Behavior by Type

### How Google Photos groups related files:

**Burst sequences:**
- If 3+ images have timestamps within 1 second, Google Photos treats them as a burst.
- Displayed as a single thumbnail; you can expand to see all.
- Requires each file to have valid, sequential `DateTimeOriginal`.

**Panoramas:**
- Detected by image aspect ratio (width > 2× height) AND consecutive timestamps.
- Grouped automatically; no special metadata needed.

**Videos with stills:**
- If a JPG and MP4 have the same timestamp (within 1 second), Google Photos links them.
- Shown together in the timeline.

**Duplicates:**
- Google Photos detects exact-byte duplicates and shows only one.
- **Does not** detect near-duplicates or resized copies; both appear in timeline.

---

## 7) What Happens When Metadata Is Wrong

### Scenario 1: Missing DateTimeOriginal (images)

```
File: IMG_12345.jpg
DateTimeOriginal: (missing)
Filename: IMG_12345.jpg (no date pattern)
FileModifyDate: 2025:05:07 (today, because it was copied)
```

**Result:** Photo sorts into today's date in Google Photos timeline, even though it's from 2020.

**Fix:** Use Strategy A (filename priority) or add DateTimeOriginal from filename or FileModifyDate.

### Scenario 2: Timezone mismatch (videos)

```
File: VID_001.mp4
QuickTime:CreateDate: 2024:01:15 14:30 (local time, no TZ tag)
Device at upload: EST (UTC-5)
```

**Result:** Video sorts as if it was taken at 19:30 UTC instead of 14:30 local time.

**Fix:** Add `OffsetTimeOriginal` or use `-api QuickTimeUTC` when writing dates.

### Scenario 3: Rerun on already-processed files (Strategy B)

```
Initial state:
Video file, metadata correct, FileModifyDate = 2024:01:15

User runs Strategy B, then later copies the file:
Copy operation changes FileModifyDate to 2025:05:07

User runs Strategy B again (thinking it's safe):
All metadata overwritten with 2025:05:07 (wrong)
```

**Result:** Entire library of "fixed" videos now shows today's date.

**Fix:** Never rerun Strategy B on already-processed files. Use Strategy A instead.

---

## 8) Verification Checklist Before Upload

| Step | Check | Pass Criteria |
|---|---|---|
| 1 | Extension mismatch scan | No `.heic` files that are really JPEG; no `.jpg` files that are PNG |
| 2 | Missing capture date scan | Images: no missing `DateTimeOriginal`; Videos: no missing `QuickTime:CreateDate` |
| 3 | Date range reasonableness | No files show year 2000, 2099, or "today" unless intentional |
| 4 | Timezone consistency | All files from same device/timeframe show same hour (not scattered by timezone) |
| 5 | Spot check 3 images + 3 videos | Open metadata in Google Photos; dates match expectations |
| 6 | Backup retained | Original folder backed up until upload verified in Google Photos |

---

## 9) Common Cloud Services and Their Sorting Behavior

| Service | Primary sort field | Timezone handling | Supports all formats | Notes |
|---|---|---|---|---|
| **Google Photos** | DateTimeOriginal (images), QuickTime:CreateDate (videos) | UTC with OffsetTime tag | JPG, PNG, GIF, WebP, HEIC, MP4, MOV | Industry standard; strict metadata checks |
| **Mega** | FileModifyDate (fallback to filename) | Uses device local time | Most formats | Sorts by filesystem timestamp if metadata missing |
| **OneDrive** | FileModifyDate (primary) | Local device timezone | JPEG, PNG, HEIC, MP4, MOV | Metadata ignored; timestamp-only sort |
| **Amazon Photos** | DateTimeOriginal, then FileModifyDate | UTC preferred | JPG, PNG, HEIC, MP4, MOV | Similar to Google Photos |
| **iCloud Photos** | DateTimeOriginal (images), MediaCreateDate (videos) | UTC required | HEIC, JPEG, MP4, MOV | Very strict; missing OffsetTime causes issues |

---

## 10) Recommended Workflow for Multi-Cloud Upload

1. **Prepare metadata** (this repo):
   - Normalize extensions
   - Run Strategy A or B
   - Verify with scripts

2. **Add filename safety suffix:**
   - Run `append_datetime_suffix`
   - Result: `Media_042641_20231207_093000.jpg`
   - Filename now preserves date if metadata stripped

3. **Upload to Google Photos:**
   - Timeline will match your local timeline
   - Photos sort by capture date

4. **Sync to Mega/OneDrive (optional):**
   - These services use filesystem timestamps
   - Because you already added filename suffix, manual recovery is possible if needed

5. **Archive original folder:**
   - Keep raw backup until you verify Google Photos upload is complete
   - At least 30 days recommended before deletion

---

## 11) What We Observed in Practice

### Pattern 1: WhatsApp/Telegram imports (common failure)
- All photos show FileModifyDate = download date
- DateTimeOriginal often missing or stripped
- **Solution:** Use filename date if available, or ask user for source import date

### Pattern 2: Screenshot archives
- PNGs from Windows screenshots have no EXIF data
- DateTimeOriginal shows FileModifyDate (save time, not take time)
- **Solution:** Use Filename-Based Strategy if folder has named screenshots; otherwise warn user metadata is approximate

### Pattern 3: Multi-device family archives
- iPhone videos in MOV format (metadata correct)
- Android videos in MP4 (timezone offset not encoded)
- Mixed timezones scatter files across timeline
- **Solution:** Use `-api QuickTimeUTC` to normalize; all devices sync to UTC

### Pattern 4: Repacked archives from ffmpeg
- Original metadata lost; ffmpeg sets creation date to file write time
- All timestamps show batch-processing date (e.g., all show May 7, 2024)
- **Solution:** Use Sequence-Based Strategy if original order is known but dates are lost

---

## 12) Final Safety Rule

**Before uploading to Google Photos or any cloud service:**

1. ✅ Verify at least 10 sample files using the verification scripts
2. ✅ Confirm dates are in the expected range
3. ✅ Retain the local backup until Google Photos thumbnail preview matches your expectations
4. ✅ Check Google Photos timeline _after_ upload; correct any remaining issues _before_ sharing the link

**Never assume metadata is correct just because the script ran without errors.**
