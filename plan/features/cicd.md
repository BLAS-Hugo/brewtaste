# CI/CD — Codemagic

**Status:** To implement  
**Phase:** 0.2

---

## Goal

- Validate every PR (analyze + test)
- Build distributable artifacts on `develop` and `main`
- Keep secrets out of the repo (Appwrite credentials, Sentry DSN, signing certs)

---

## Workflows

### 1. `pr-check` (triggers on every PR)

Steps:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`

Fails fast. Blocks merge if failing.

### 2. `build-android` (triggers on push to `develop` / `main`)

Steps:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --release`
5. Upload artifact to Codemagic dashboard

### 3. `build-ios` (triggers on push to `develop` / `main`)

Steps:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `flutter build ios --release --no-codesign` (CI) or with signing for TestFlight
5. Upload IPA artifact

---

## Environment Variables (Codemagic encrypted)

| Variable | Used in |
|---|---|
| `APPWRITE_ENDPOINT` | `core/appwrite/appwrite_config.dart` |
| `APPWRITE_PROJECT_ID` | `core/appwrite/appwrite_config.dart` |
| `APPWRITE_DATABASE_ID` | `core/appwrite/appwrite_config.dart` |
| `SENTRY_DSN` | `core/errors/sentry_config.dart` |

These are injected at build time. Two approaches:

**Option A — `envied` (compile-time, recommended)**
- Values baked into the binary via code gen
- `codemagic.yaml` exports vars as shell env, `envied` reads them during `build_runner`

**Option B — `flutter_dotenv`**
- `.env` file bundled as an asset
- Simpler but `.env` must be present at build time (injected via Codemagic file injection)

Decision: use **`envied`** — harder to extract from binary, no asset bundling.

---

## `codemagic.yaml` skeleton

```yaml
workflows:
  pr-check:
    name: PR Check
    triggering:
      events:
        - pull_request
    scripts:
      - name: Get dependencies
        script: flutter pub get
      - name: Analyze
        script: flutter analyze
      - name: Test
        script: flutter test

  build-android:
    name: Build Android
    triggering:
      events:
        - push
      branch_patterns:
        - pattern: develop
        - pattern: main
    environment:
      vars:
        APPWRITE_ENDPOINT: Encrypted(...)
        APPWRITE_PROJECT_ID: Encrypted(...)
        APPWRITE_DATABASE_ID: Encrypted(...)
        SENTRY_DSN: Encrypted(...)
    scripts:
      - name: Get dependencies
        script: flutter pub get
      - name: Generate code
        script: dart run build_runner build --delete-conflicting-outputs
      - name: Analyze
        script: flutter analyze
      - name: Test
        script: flutter test
      - name: Build APK
        script: flutter build apk --release
    artifacts:
      - build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    name: Build iOS
    triggering:
      events:
        - push
      branch_patterns:
        - pattern: develop
        - pattern: main
    environment:
      vars:
        APPWRITE_ENDPOINT: Encrypted(...)
        APPWRITE_PROJECT_ID: Encrypted(...)
        APPWRITE_DATABASE_ID: Encrypted(...)
        SENTRY_DSN: Encrypted(...)
    scripts:
      - name: Get dependencies
        script: flutter pub get
      - name: Generate code
        script: dart run build_runner build --delete-conflicting-outputs
      - name: Analyze
        script: flutter analyze
      - name: Test
        script: flutter test
      - name: Build iOS
        script: flutter build ios --release --no-codesign
    artifacts:
      - build/ios/iphoneos/Runner.app
```

---

## Signing (iOS)

For TestFlight distribution:
- Store `.p12` certificate + provisioning profile as Codemagic code signing assets
- Use Codemagic's automatic signing or manual profile injection
- Out of scope for initial setup — `--no-codesign` for now

---

## Branch Strategy Alignment

Per `docs/git-guidelines.md`:
- `develop` — integration branch, build artifacts on every push
- `main` — release branch, can trigger store distribution later
- Feature branches → PR → `develop` (PR check must pass)

---

## Implementation Notes

- `codemagic.yaml` goes at the project root
- `build_runner` step is needed because `envied` + `freezed` + `riverpod_generator` all generate code
- Keep build cache enabled in Codemagic to speed up subsequent runs
