# Deep Links + QR — Implementation Plan

## What was already in place

- `brewtaste://` scheme registered on Android and iOS
- `DeepLinkHandler` fully wired (cold + warm start via `app_links`)
- All packages present: `app_links`, `mobile_scanner`, `qr_flutter`
- QR code on host lobby already encoded `brewtaste://join/BREW-XXXX`

## Changes

### Android `AndroidManifest.xml`
Added `android:host="join"` to the intent filter `<data>` tag for specificity.

### `lib/core/router/app_router.dart`
Added `/join/:code` route → `JoinSessionScreen(initialCode: code)`.
`DeepLinkHandler` was already converting `brewtaste://join/BREW-1234` → `/join/BREW-1234`.

### `lib/features/session/presentation/screens/qr_scan_screen.dart` (new)
Full-screen QR scanner following the `BarcodeScanScreen` pattern. Parses:
- `brewtaste://join/BREW-XXXX` URI → extracts code
- Raw `BREW-XXXX` string → uses directly
- Anything else → ignored (user retries)
Returns `String?` code via `Navigator.pop`.

### `lib/features/session/presentation/screens/join_session_screen.dart`
- Added `String? initialCode` constructor param — used to pre-fill the code field on deep link / QR scan entry
- Added QR camera icon button as `suffixIcon` on the code field
