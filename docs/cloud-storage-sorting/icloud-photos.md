# iCloud Photos Media Sorting and Metadata Behavior

iCloud Photos is Apple's cloud service for photos and videos, tightly integrated with Apple devices. It sorts media by **capture date** and has the **strictest metadata validation** of all services.

## Sorting priority

1. **Embedded capture metadata** (DateTimeOriginal for images, QuickTime:CreateDate for videos) ← Very strict validation
2. **Filename date pattern** (if metadata missing; limited support)
3. **File system timestamp** (FileModifyDate; weak fallback)
4. **Upload date** (least preferred)

**Critical:** iCloud Photos validates metadata very strictly. Invalid or malformed tags can cause upload failures or timeline errors.

---

## Image Files (.jpg, .jpeg, .heic, .png, .gif)

### What iCloud Photos checks

| Priority | Tag Name | What it looks for | Validation |
|---|---|---|---|
| 1 | `DateTimeOriginal` (EXIF) | The moment the photo was taken | Must be valid YYYY:MM:DD format |
| 2 | `CreateDate` (EXIF alternate) | Backup capture timestamp | Must match DateTimeOriginal format |
| 3 | Filename pattern | Dates in filename | Limited; prefers embedded |
| 4 | `FileModifyDate` (Windows) | File system timestamp | Weak fallback |

### Expected metadata structure (iCloud-safe)

```
Filename: IMG_20240115_091234.jpg
DateTimeOriginal: 2024:01:15 09:12:34 (with timezone info preferred)
CreateDate: 2024:01:15 09:12:34 (with timezone info preferred)
OffsetTimeOriginal: +05:30 (optional; helps multi-timezone support)
FileModifyDate: 2024:01:15 09:12:34
```

### Common issues

- **HEIC files** → Supported on all Apple devices; must have valid metadata
- **Non-Apple HEIC** → May fail validation if not properly tagged (rare)
- **PNG files** → Supported but less common; must have EXIF data
- **WebP files** → NOT supported; iCloud rejects WebP uploads
- **Missing timezone info** → Causes multi-device sorting issues
- **Malformed EXIF** → iCloud is very strict; corrupted tags cause failures
- **Photos from non-Apple devices** → Must have proper EXIF tagging to work

### Go/No-go check

✅ Correct: All images have valid `DateTimeOriginal`; timeline matches expected dates  
❌ Wrong: Images show 2000, 2099, garbled dates, or upload fails

---

## Video Files (.mp4, .mov, .m4v)

### What iCloud Photos checks

| Priority | Tag Name | What it looks for | Media type |
|---|---|---|---|
| 1 | `QuickTime:CreateDate` | Video creation timestamp (STRICT) | MOV, MP4, M4V |
| 2 | `QuickTime:MediaCreateDate` | Backup video timestamp | MOV, MP4 |
| 3 | Filename pattern | Dates in filename | All types |
| 4 | `FileModifyDate` | File system timestamp | All types |

### Expected metadata structure

```
Filename: VID_20240115_091234.mov
QuickTime:CreateDate: 2024:01:15 09:12:34 (MUST be present and valid)
QuickTime:MediaCreateDate: 2024:01:15 09:12:34 (redundant but safe)
FileModifyDate: 2024:01:15 09:12:34
```

### Critical requirement for videos

**`QuickTime:CreateDate` is MANDATORY for all videos on iCloud Photos.** Videos without this tag may fail to upload or display incorrectly.

### Common issues

- **MP4 files from Android** → `QuickTime:CreateDate` may be missing; requires writing it explicitly
- **Screen recordings** → Often have invalid or missing timestamps
- **Repacked videos (ffmpeg)** → Timestamps may be corrupted; need fixing
- **iPhone videos** → Usually correct; must remain valid
- **Third-party app videos** → May have non-standard tagging; iCloud may reject
- **Video with mismatched timestamps** → If image and video have vastly different times, iCloud may not link them

### Go/No-go check

✅ Correct: All videos have valid `QuickTime:CreateDate`; timeline matches expectations  
❌ Wrong: Videos missing timestamps; upload fails; dates show as garbled

---

## Timezone Handling

### How iCloud Photos interprets dates

- **Timezone info is REQUIRED for multi-device sync**
- If `OffsetTimeOriginal` is present, iCloud uses UTC
- If no timezone info, iCloud assumes device local timezone (can cause issues)
- Multiple devices with different timezones MUST have timezone metadata

### What we use in this repo

The `-api QuickTimeUTC` flag in ExifTool is **essential for iCloud Photos**. It ensures:
- Timestamps are stored in UTC-safe format
- Timezone offsets are preserved
- Multi-device sync works correctly

### Example: The importance of timezone info

| Scenario | With OffsetTime | Without OffsetTime |
|---|---|---|
| Photo taken 2024:01:15 14:30 IST (+05:30) | iCloud stores as 09:00 UTC; correct on all devices | iCloud assumes 14:30 local to upload device; wrong if uploaded from US |
| Same photo on iPhone (IST) | Shows 2024:01:15 14:30 IST | Shows wrong time if uploaded from different timezone |
| Same photo on iPad (PST) | Shows 2024:01:15 09:00 UTC converted to PST = 01:00 PST (correct) | Shows garbled or device-specific time |

**Result:** Timezone info is essential for correct multi-device iCloud Photos libraries.

---

## Supported Media Types

| Category | Formats | Support | Notes |
|---|---|---|---|
| **Images** | JPG, JPEG, HEIC, PNG, GIF | Full support | WebP NOT supported; iCloud rejects |
| **Videos** | MP4, MOV, M4V | Full support | AVI, MKV, WebM NOT supported |
| **RAW** | CR2, NEF, ARW, DNG | Supported (newer devices) | Professional photo support on modern devices |
| **Burst photos** | JPG/HEIC sequences | Auto-grouped | Detected by timestamp and burst flag |
| **Edited photos** | JPG/HEIC with editing data | Full support | Original + edits synced |

**Unsupported formats are rejected at upload** (unlike Google Photos, which converts some formats).

---

## File Ordering and Organization

### Timeline view

- Sorted strictly by capture date (DateTimeOriginal or QuickTime:CreateDate)
- Most recent first
- Multi-device sync shows unified timeline across all Apple devices

### Automatic grouping

- Burst sequences detected and grouped
- Panoramas detected and grouped
- Live Photos (HEIC+video pair) linked automatically
- Duplicates detected and deduplicated

### Shared Photo Library

- iCloud Shared Photo Library can include multiple family members
- All participants see unified timeline
- Metadata must be consistent across all devices

### Years view and Months view

- Automatic organization by capture date
- Memories feature uses ML on capture date + content analysis

---

## Failure Scenarios and Fixes

### Scenario 1: MP4 video without QuickTime:CreateDate

```
File: video_from_android.mp4
QuickTime:CreateDate: (missing)
FileModifyDate: 2024:01:15 14:30
```

**Result:** Upload fails or video doesn't appear in timeline

**Fix:** Write `QuickTime:CreateDate` from FileModifyDate or filename:
```batch
exiftool "-QuickTime:CreateDate<FileModifyDate" video_from_android.mp4
```

Or use Strategy B from [../../runbook-windows.md](../../runbook-windows.md).

### Scenario 2: Multi-timezone family library shows scattered dates

```
Grandma's photo: 2024:01:15 10:00 IST (no OffsetTime)
Grandchild uploads from US: timestamp interpreted as 10:00 EST
iCloud sees: 2024:01:15 10:00 EST (wrong)
Expected: 2024:01:15 10:00 IST = 00:30 EST (5.5 hours different)
```

**Result:** Family timeline is completely scrambled

**Fix:** Add timezone info to all images and videos:
```batch
exiftool "-OffsetTimeOriginal=+05:30" *.jpg
exiftool "-OffsetTimeOriginal=+05:30" *.heic
```

Or use `-api QuickTimeUTC` when writing dates (handles this automatically).

### Scenario 3: Edited photos lose metadata

```
Original: photo.heic (DateTimeOriginal = 2024:01:15 10:00)
Edited in iCloud: Apple preserves original metadata
But: If edited externally with non-Apple app, DateTimeOriginal lost
```

**Result:** Edited photo shows current date

**Fix:** Do not edit photos with non-Apple apps before iCloud upload. Or restore metadata from backup.

### Scenario 4: WebP images rejected

```
File: image.webp
Attempt to upload to iCloud Photos
```

**Result:** Upload fails; iCloud does not support WebP

**Fix:** Convert WebP to JPEG or PNG before upload:
```batch
exiftool "-FileName=%%f.jpg" image.webp
```

---

## Pre-Upload Verification Checklist

| Step | Check | Pass Criteria | Critical? |
|---|---|---|---|
| 1 | Format check | No WebP; no TIFF; no BMP | YES |
| 2 | Image metadata | All images have valid `DateTimeOriginal` | YES |
| 3 | Video metadata | All videos have valid `QuickTime:CreateDate` | YES |
| 4 | Timezone info | `OffsetTimeOriginal` present (if multi-timezone) | YES |
| 5 | Date range | No 2000, 2099, or garbled dates | YES |
| 6 | Spot check | 3 images + 3 videos on Apple device; dates correct | YES |
| 7 | Local backup | Backup retained | YES |

---

## Recommended Workflow for iCloud Photos

1. **Prepare metadata with timezone info** → Use Strategy A or B from [../../runbook-windows.md](../../runbook-windows.md) with `-api QuickTimeUTC`
2. **Add timezone info if multi-device** → Ensure `OffsetTimeOriginal` is set for images and videos
3. **Verify all required tags** → Run [../../scripts/windows/verify_folder/README.md](../../scripts/windows/verify_folder/README.md)
4. **Convert non-supported formats** → WebP → JPEG, etc.
5. **Upload to iCloud** → Use iCloud app or iCloud.com
6. **Verify on Apple device** → Check Photos app timeline; ensure dates match

---

## Key Differences from Google Photos, Mega, OneDrive

| Feature | iCloud Photos | Google Photos | Mega | OneDrive |
|---|---|---|---|---|
| **Sort method** | Metadata (strict) | Metadata (strict) | FileModifyDate | FileModifyDate |
| **Timezone handling** | Strict; OffsetTime required | Preferred but not required | Local time | Local time |
| **Supported formats** | Limited (JPG, HEIC, PNG, MOV, MP4) | Broader | Very broad | Broad |
| **Metadata validation** | Very strict | Strict | Lenient | Ignored |
| **Automatic grouping** | Yes (bursts, duplicates, memories) | Yes | No | No |
| **Multi-device sync** | Native family sync | Google account-based | Manual sync | OneDrive app |
| **Best for** | Apple ecosystem | General users | General backup | Windows ecosystem |

---

## When to use iCloud Photos

- You have an Apple device ecosystem (iPhone, iPad, Mac)
- You want seamless multi-device sync
- You want iCloud Shared Photo Library with family
- You want automatic memories and ML-powered organization
- You're comfortable with Apple's privacy model

---

## When NOT to use iCloud Photos

- You're not primarily on Apple devices
- You need cross-platform support (Windows, Android primary)
- You want unlimited storage without cost (iCloud has limits)
- You have Windows-only media archives (use Google Photos or Mega)

---

## Final Notes on iCloud Photos

**iCloud Photos is the strictest service in metadata validation:**
- Invalid metadata causes upload failures, not silent errors
- Multi-device sync requires proper timezone handling
- WebP and unsupported formats are rejected outright
- Shared libraries require all participants' devices to sync metadata

**If preparing a family archive for iCloud Photos, use Strategy B from [../../runbook-windows.md](../../runbook-windows.md) with `-api QuickTimeUTC` flag** to ensure timezone-safe metadata across all devices.
