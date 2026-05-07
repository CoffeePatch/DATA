# OneDrive Media Sorting and Metadata Behavior

OneDrive is Microsoft's cloud storage service that sorts media **exclusively by file system timestamp**; embedded metadata is ignored for sorting purposes.

## Sorting priority

1. **File system timestamp** (FileModifyDate) ← ONLY sort method
2. **Embedded metadata** (NOT read or used; ignored completely)
3. **Filename** (NOT used for sorting in OneDrive's photo gallery)
4. **Upload date** (only if FileModifyDate is invalid)

**Critical:** OneDrive does NOT read or respect EXIF metadata for timeline sorting. It uses FileModifyDate exclusively.

---

## Image Files (.jpg, .jpeg, .png, .heic, .gif, .bmp)

### What OneDrive checks

OneDrive's photo gallery reads **only** `FileModifyDate` for timeline sorting. All EXIF data is ignored for sorting (though it may appear in photo metadata viewers).

| Priority | Source | Purpose |
|---|---|---|
| 1 | `FileModifyDate` (Windows) | Timeline sort (only method) |
| 2 | Embedded EXIF | Informational only; not used for sorting |
| 3 | Filename | Informational only; not used for sorting |

### Expected structure

```
Filename: IMG_20240115_091234.jpg
FileModifyDate: 2024:01:15 09:12:34 ← OneDrive uses ONLY this for timeline
DateTimeOriginal: 2024:01:15 09:12:34 (ignored by OneDrive's gallery)
CreateDate: 2024:01:15 09:12:34 (ignored by OneDrive's gallery)
```

### Common issues

- **Copied files** → FileModifyDate becomes copy time; timeline is wrong
- **Downloaded files** → FileModifyDate = download time; original date lost
- **Edited files** → FileModifyDate changes to edit time; appears at wrong date in timeline
- **Synced files** → FileModifyDate = last sync time, not original capture time
- **Perfect EXIF metadata** → Completely irrelevant; OneDrive ignores it for sorting

### Go/No-go check

✅ Correct: FileModifyDate matches expected date; timeline aligns with folders  
❌ Wrong: All files show today's date or sync date (FileModifyDate was touched by copy/download/sync)

---

## Video Files (.mp4, .mov, .m4v, .avi, .webm, .mkv)

### What OneDrive checks

Same as images: **FileModifyDate only**.

| Priority | Source |
|---|---|
| 1 | `FileModifyDate` | Timeline sort (exclusive) |
| 2 | Embedded timestamps | Ignored for sorting |
| 3 | Filename | Ignored for sorting |

### Expected structure

```
Filename: VID_20240115_091234.mp4
FileModifyDate: 2024:01:15 09:12:34 ← OneDrive sorts by this ONLY
QuickTime:CreateDate: 2024:01:15 09:12:34 (ignored)
```

### Common issues

- **Videos from cloud sync** → FileModifyDate = sync time
- **Re-encoded videos** → FileModifyDate = encoding time
- **Downloaded videos** → FileModifyDate = download time
- **Backed up videos** → FileModifyDate = backup time

**Every** video sorting issue in OneDrive is caused by FileModifyDate being different from capture date.

---

## Timezone Handling

### How OneDrive interprets FileModifyDate

- Uses the Windows system timezone setting at time of file operation
- Converts to UTC for cloud storage
- NO special handling needed; filesystem timestamp is already timezone-aware

### Important for multi-device sync

When syncing files between devices in different timezones:
- Each device sees files in its local timezone
- FileModifyDate is converted to UTC on the server
- No special `-api QuickTimeUTC` needed; Windows handles this automatically

---

## Supported Media Types

| Category | Formats | Behavior |
|---|---|---|
| **Images** | JPG, JPEG, PNG, HEIC, GIF, BMP, TIFF, WEBP | Sorted by FileModifyDate |
| **Videos** | MP4, MOV, M4V, AVI, WMV, WebM, MKV | Sorted by FileModifyDate |
| **RAW photos** | CR2, NEF, ARW (Canon, Nikon, Sony) | Supported; sorted by FileModifyDate |

**Note:** OneDrive's auto-upload feature (OneDrive app on Windows/Mac) can read embedded metadata for searching/tagging, but **never** for timeline sorting.

---

## File Ordering Behavior

### Timeline view

- OneDrive displays photos in folders and timeline sorted **strictly by FileModifyDate**, newest first
- No automatic grouping of bursts or panoramas
- No deduplication

### Folder view

- Files appear in folder listings sorted by FileModifyDate
- Filename plays no role in sorting

### Search and tagging

- OneDrive's auto-upload can read some EXIF tags for search (camera model, GPS)
- But these do NOT affect timeline sort
- Sort is **always** FileModifyDate

---

## Failure Scenarios and Fixes

### Scenario 1: Recent file operations move everything to today

```
Batch action: Copied 500 photos from external drive to OneDrive
Result: All 500 files show today's date in timeline
Reason: Copy operation sets FileModifyDate to copy time
```

**Fix:** Restore FileModifyDate from embedded metadata (if available):
```batch
exiftool "-FileModifyDate<DateTimeOriginal" *.jpg
exiftool "-FileModifyDate<QuickTime:CreateDate" *.mp4
```

Or use [../../runbook-windows.md](../../runbook-windows.md) Strategy A or B to normalize.

### Scenario 2: Family photo archive shows wrong dates

```
Photos from 2015–2024
All show: 2025:05:07 (sync date)
Reason: Entire folder was synced from another device last week
```

**Result:** Entire archive appears as single-day upload in timeline

**Fix:** Restore from embedded metadata or filename before re-syncing.

### Scenario 3: Cross-device sync scatters files

```
Device A (EST timezone): Photo taken 2024:01:15 14:30 EST
Device B (PST timezone): Same photo appears 2024:01:15 14:30 PST (3 hours different)
Reason: FileModifyDate is localized; timezone conversion confusion
```

**Result:** Same file has two different dates depending on which device is viewing it

**Fix:** Ensure all devices use UTC or consistent timezone; manually fix FileModifyDate to UTC equivalent.

---

## Pre-Upload Verification Checklist

| Step | Check | Pass Criteria |
|---|---|---|
| 1 | FileModifyDate check | All dates in expected range; not today |
| 2 | Extension scan | No corrupted extensions (optional; OneDrive lenient) |
| 3 | Spot check samples | 3–5 photos; verify dates in OneDrive timeline after upload |
| 4 | Consistency | Photos from same batch show in same date folder |
| 5 | Local backup | Backup until verified in OneDrive |

---

## Recommended Workflow for OneDrive

1. **Ensure FileModifyDate is correct** → Most critical step for OneDrive
2. **Optional: Verify embedded metadata** → Run [../../scripts/windows/verify_folder/README.md](../../scripts/windows/verify_folder/README.md)
3. **Upload to OneDrive** → OneDrive reads FileModifyDate and sorts
4. **Verify in OneDrive web** → Check Photos timeline for correct dates
5. **Do NOT edit files** → Any edit will change FileModifyDate

---

## Key Differences from Google Photos and Mega

| Feature | Google Photos | Mega | OneDrive |
|---|---|---|---|
| **Sort method** | Embedded metadata | FileModifyDate | FileModifyDate |
| **Metadata validation** | Strict | Lenient | Ignored for sorting |
| **Timezone handling** | Strict; UTC required | Automatic local time | Automatic local time |
| **Automatic grouping** | Yes (bursts, etc.) | No | No |
| **Format support** | Limited | Broad | Broad |
| **Best for** | Photo timeline | General backup | Windows/Microsoft ecosystem |

---

## When to use OneDrive for media

- You're in Microsoft/Windows ecosystem
- FileModifyDate is reliable (freshly captured or downloaded files)
- You want cross-device sync with Office/OneDrive integration
- You don't need sophisticated timeline or search features
- You want simple folder-based organization

---

## When NOT to use OneDrive alone

- Timeline and date-based organization matter
- FileModifyDate is unreliable (copied, synced, or backed-up files)
- You want automatic burst/panorama grouping
- You need to preserve metadata for future services (use Google Photos instead)
- You want search by camera model, GPS, or other EXIF data

---

## Important OneDrive Characteristics

**OneDrive is fundamentally different from Google Photos and Amazon Photos:**
- Metadata is **never** used for sorting
- FileModifyDate is the **only** timeline sort method
- This makes OneDrive best for general sync, not photo curation

**If your photos were copied or synced from external sources, always restore FileModifyDate before relying on OneDrive timeline.**
