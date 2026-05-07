# Amazon Photos Media Sorting and Metadata Behavior

Amazon Photos (Amazon Drive's photo gallery feature) sorts media by **capture date**, similar to Google Photos, but with some AWS-specific behaviors.

## Sorting priority

1. **Embedded capture metadata** (DateTimeOriginal for images, QuickTime:CreateDate for videos) ← Primary
2. **Filename date pattern** (if metadata missing)
3. **File system timestamp** (FileModifyDate; fallback)
4. **Upload date** (only if all above missing)

**Similar to Google Photos:** Amazon Photos respects embedded metadata for timeline sorting. Metadata preparation is important.

---

## Image Files (.jpg, .jpeg, .png, .webp, .heic, .gif, .tiff)

### What Amazon Photos checks

| Priority | Tag Name | What it looks for | If missing |
|---|---|---|---|
| 1 | `DateTimeOriginal` (EXIF) | The moment the photo was taken | Falls back to next |
| 2 | `CreateDate` (EXIF alternate) | Backup capture timestamp | Falls back to next |
| 3 | Filename pattern | Dates in filename | Uses file system date |
| 4 | `FileModifyDate` (Windows) | The file's modification timestamp | Uses current date |

### Expected metadata structure

```
Filename: IMG_20240115_091234.jpg
DateTimeOriginal: 2024:01:15 09:12:34
CreateDate: 2024:01:15 09:12:34
FileModifyDate: 2024:01:15 09:12:34
```

### Common issues

- **HEIC files** → Supported but require proper tagging (similar to Google Photos)
- **PNG screenshots** → Often missing DateTimeOriginal; shows today's date
- **WhatsApp/Telegram imports** → Metadata often stripped; FileModifyDate used instead
- **Cloud-synced photos** → FileModifyDate may be sync time; embedded metadata is primary fallback

### Go/No-go check

✅ Correct: All images show dates in expected range  
❌ Wrong: Images show 2000, 2099, or today when they shouldn't

---

## Video Files (.mp4, .mov, .mkv, .avi, .webm)

### What Amazon Photos checks

| Priority | Tag Name | What it looks for | Media type |
|---|---|---|---|
| 1 | `QuickTime:CreateDate` | Video creation timestamp | MP4, MOV, M4V |
| 2 | `QuickTime:MediaCreateDate` | Backup video timestamp | MP4, MOV |
| 3 | Filename pattern | Dates in filename | All types |
| 4 | `FileModifyDate` | File system timestamp | All types |

### Expected metadata structure

```
Filename: VID_20240115_091234.mp4
QuickTime:CreateDate: 2024:01:15 09:12:34
QuickTime:MediaCreateDate: 2024:01:15 09:12:34
FileModifyDate: 2024:01:15 09:12:34
```

### Common issues

- **Android videos** → Timezone offset not encoded; may sort differently than expected
- **Screen recordings** → Create date defaults to "now"; must override
- **Repacked videos** → ffmpeg resets timestamps to processing time
- **Cloud sync** → Embedded timestamps are used; sync time is ignored (unlike Mega/OneDrive)

### Go/No-go check

✅ Correct: Videos show dates in expected range  
❌ Wrong: Videos show epoch (1970) or today

---

## Timezone Handling

### How Amazon Photos interprets dates

- If metadata includes timezone info (`OffsetTimeOriginal`), Amazon Photos uses UTC
- If no timezone present, Amazon Photos assumes **device local timezone at upload time**
- Multiple timezones can cause sorting scatter

### What we use in this repo

The `-api QuickTimeUTC` flag in ExifTool ensures timestamps are stored in UTC-safe format.

### Example issue (same as Google Photos)

| File | Metadata | Device timezone | Amazon Photos sees |
|---|---|---|---|
| photo1.jpg | 2024:01:15 14:30 (no TZ) | EST (UTC-5) | Sorts as 19:30 UTC |
| photo2.jpg | 2024:01:15 14:30 (no TZ) | PST (UTC-8) | Sorts as 22:30 UTC |

**Result:** Same-time photos sort 3 hours apart

---

## Supported Media Types

| Category | Formats | Unlimited | Notes |
|---|---|---|---|
| **Images** | JPG, PNG, GIF, WebP, HEIC, TIFF | Yes (Amazon Prime members) | TIFF also supported; rare format |
| **Videos** | MP4, MOV, MKV, AVI, WebM, 3GP | Limited (depends on plan) | Up to 2160p (4K) supported |
| **RAW** | CR2, NEF, ARW, DNG | Yes (Prime members) | Professional photo support |

**Unlimited storage:** Amazon Prime members get unlimited photo storage at original quality (no compression) for JPG and PNG.

---

## File Ordering and Organization

### Timeline view

- Sorted by capture date (similar to Google Photos)
- Most recent first

### Automatic collections

- Amazon Photos creates automatic albums by date (day, month, year)
- No smart grouping like Google Photos; albums are simple date-based collections

### Sharing

- Easy sharing via link
- Albums can be organized manually or by date

---

## Failure Scenarios and Fixes

### Scenario 1: Missing DateTimeOriginal (same as Google Photos)

```
File: IMG_12345.jpg
DateTimeOriginal: (missing)
FileModifyDate: 2025:05:07
```

**Result:** Photo sorts into today's date

**Fix:** Use Strategy A (filename priority) or restore from FileModifyDate via [../../runbook-windows.md](../../runbook-windows.md)

### Scenario 2: Timezone mismatch (same as Google Photos)

```
File: VID_001.mp4
QuickTime:CreateDate: 2024:01:15 14:30 (no TZ)
Device: EST (UTC-5)
```

**Result:** Video sorts 5 hours later than actual capture time

**Fix:** Add timezone metadata or use `-api QuickTimeUTC`

### Scenario 3: Bulk import shows wrong dates

```
Import 1000 photos from Facebook/Instagram
All show: 2025:05:07 (import date)
Original dates: 2015–2023 (lost)
```

**Result:** Timeline is completely wrong

**Fix:** Restore from embedded metadata (if available) or use filename pattern if dates are in filename.

---

## Pre-Upload Verification Checklist

| Step | Check | Pass Criteria |
|---|---|---|
| 1 | Extension mismatch scan | No HEIC as JPG; no PNG as JPG |
| 2 | Missing capture date scan | Images: `DateTimeOriginal` present; Videos: `QuickTime:CreateDate` present |
| 3 | Date range check | No 2000, 2099, or today unless intentional |
| 4 | Timezone consistency | All files from same batch show same hour |
| 5 | Spot check | 3 images + 3 videos in Amazon Photos; dates match |
| 6 | Local backup | Backup until verified |

---

## Recommended Workflow for Amazon Photos

1. **Prepare metadata** → Run Strategy A or B from [../../runbook-windows.md](../../runbook-windows.md)
2. **Verify** → Run [../../scripts/windows/verify_folder/README.md](../../scripts/windows/verify_folder/README.md)
3. **Upload to Amazon Photos** → Upload will respect embedded metadata
4. **Verify timeline** → Check that dates match expectations in Amazon Photos web gallery
5. **Consider unlimited storage** → If Amazon Prime member, unlimited original-quality photo storage

---

## Key Differences from Google Photos

| Feature | Google Photos | Amazon Photos |
|---|---|---|
| **Sort method** | Embedded metadata | Embedded metadata |
| **Timezone handling** | Strict; UTC with OffsetTime | Similar; UTC preferred |
| **Automatic grouping** | Bursts, panoramas, duplicates | Date-only collections |
| **Search** | AI-powered (objects, text, faces) | Basic search; less sophisticated |
| **Sharing** | Link sharing built-in | Link sharing available |
| **Storage** | Limited free; paid tiers | Unlimited for Prime members (photos only) |
| **Metadata validation** | Very strict | Strict but slightly more forgiving |

---

## When to use Amazon Photos

- You're an Amazon Prime member with unlimited photo storage needs
- You want embedded-metadata-based timeline sorting (similar to Google Photos)
- You want integration with AWS ecosystem
- You prefer less aggressive AI/ML features than Google Photos
- You want simple date-based collections rather than smart albums

---

## When NOT to use Amazon Photos alone

- You're not an Amazon Prime member (storage limits apply)
- You want sophisticated search and organization features (Google Photos better)
- You want automatic burst/panorama detection (Google Photos better)
- You want face recognition and memories (Google Photos much better)

---

## Important Notes

**Amazon Photos is a good alternative to Google Photos if:**
- You have reliable embedded metadata
- You don't need advanced search or AI features
- You're an Amazon Prime member and want unlimited storage
- You prefer AWS ecosystem integration

**Metadata preparation is just as important for Amazon Photos as for Google Photos.** Use the same Strategy A or B from [../../runbook-windows.md](../../runbook-windows.md) to prepare files.
