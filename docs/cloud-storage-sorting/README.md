# Cloud Storage Sorting and Media Organization Guide

This folder documents how different cloud storage services sort, categorize, and display media files based on metadata.

## Quick reference

| Service | Primary sort | Supports metadata | Timezone safe | Best for |
|---|---|---|---|---|
| **Google Photos** | Capture date (strict) | Yes, DateTimeOriginal/QuickTime:CreateDate | UTC with OffsetTime | Photos + Videos, timeline priority |
| **Mega** | FileModifyDate fallback | Reads EXIF but uses filesystem | Local device time | General backup, less strict |
| **OneDrive** | FileModifyDate only | Ignored; timestamp-only | Local device time | Office integration, cross-device sync |
| **Amazon Photos** | Capture date (like Google) | Yes, similar to Google Photos | UTC preferred | AWS ecosystem, Photos app integration |
| **iCloud Photos** | Capture date (strict) | Yes, very strict validation | UTC required | Apple ecosystem, device sync |

## Cloud service guides

1. **[Google Photos](google-photos.md)** — How Google Photos prioritizes metadata tags, timezone handling, supported formats, and pre-upload validation
2. **[Mega](mega.md)** — FileModifyDate-primary sorting, loose metadata handling, suitable for general backups
3. **[OneDrive](onedrive.md)** — Filesystem timestamp sorting, metadata ignored, best for cross-device sync within Windows ecosystem
4. **[Amazon Photos](amazon-photos.md)** — Similar to Google Photos, UTC-safe handling, tightly integrated with AWS
5. **[iCloud Photos](icloud-photos.md)** — Strict metadata validation, UTC required, best for Apple device families

## Core principles across all services

### Sorting priority hierarchy (general pattern)

1. **Embedded capture metadata** (DateTimeOriginal for images, QuickTime:CreateDate for videos) ← Most reliable
2. **Filename date pattern** (if metadata missing; varies by service)
3. **File system timestamp** (FileModifyDate; fallback or primary depending on service)
4. **Upload date** (least preferred; used only if all above are missing or invalid)

### Why metadata matters

- If embedded capture metadata is wrong or missing, files sort incorrectly regardless of filename or upload time.
- Each cloud service has different strictness about which tags it reads.
- Some services ignore metadata entirely and sort by filesystem timestamp alone.

## Why this repository writes multiple metadata tags

We write the same date to multiple tag locations because:

1. **Cross-platform compatibility** — iPhones read `QuickTime:CreateDate`, Android phones read `DateTimeOriginal`, Windows apps read either
2. **Service compatibility** — Google Photos checks multiple tags; if one is missing, it falls back to the next
3. **Safety against editing** — If someone edits a file and loses one tag, others remain as backup
4. **Future-proofing** — Different cloud services may prioritize different tags

## Pre-upload verification strategy

**Before uploading to any cloud service:**

1. ✅ Verify extension matches content (no HEIC as .jpg, PNG as .jpg, etc.)
2. ✅ Verify all images have `DateTimeOriginal` (or service's primary date tag)
3. ✅ Verify all videos have `QuickTime:CreateDate` (or service's primary date tag)
4. ✅ Verify dates are in expected range (not year 2000, not future)
5. ✅ Verify timezone consistency (all files from same device/timeframe same hour)
6. ✅ Retain local backup until cloud upload verified

## When to use each service

### Use Google Photos if:
- Timeline/capture-date sorting is critical
- You want automatic search and AI-powered features
- You're comfortable with Google's privacy model

### Use Mega if:
- You want simplicity and broad device support
- Filesystem timestamps are reliable
- You don't need sophisticated AI search

### Use OneDrive if:
- You're in Microsoft/Windows ecosystem
- You want cross-device sync with Office apps
- Local file timestamps are your source of truth

### Use Amazon Photos if:
- You're in AWS ecosystem
- You want unlimited photo storage (Amazon Prime member)
- You need similar features to Google Photos but within AWS

### Use iCloud Photos if:
- You're in Apple ecosystem
- You have multiple Apple devices (iPhone, iPad, Mac)
- You want iCloud Shared Photo Library features

## Common failure patterns across services

1. **WhatsApp/Telegram imports** — Download date becomes filesystem timestamp; original capture metadata lost
2. **Screenshot archives** — PNG files show creation time as save time, not actual screenshot time
3. **Batch-repacked videos** — ffmpeg re-encode resets all timestamps to processing time
4. **Multi-device archives** — iPhone dates in MOV format, Android dates in MP4; timezone offsets scatter files
5. **Copy operations** — FileModifyDate changes during copy; downstream services see copy date instead of capture date

## Next steps

1. Choose your target cloud service(s)
2. Read the corresponding guide in this folder
3. Prepare metadata using the [../runbook-windows.md](../runbook-windows.md) scripts
4. Verify using [../verification-and-signoff.md](../verification-and-signoff.md)
5. Upload and validate in the cloud service
