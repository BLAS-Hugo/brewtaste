# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BrewTaste is a Flutter mobile app (Android & iOS) for group beer tasting sessions. A host creates a session, participants join via a short code (`BREW-XXXX`) or QR code, rate each beer anonymously, and results are revealed simultaneously. No account required — Appwrite anonymous auth is used automatically.

Two roles: **Host** (creates session, adds beers, controls flow) and **Participant** (joins, rates, guesses).

## Commands

```bash
flutter pub get                            # Install dependencies
flutter run                                # Run on connected device/emulator
flutter analyze                            # Static analysis / lint
flutter test                               # Run all tests
flutter test test/path/to/test.dart        # Run a single test file
flutter build apk                          # Build Android APK
flutter build ios                          # Build iOS (requires macOS + Xcode)
```

## Architecture

**Feature-first with clean architecture per feature.**

```
lib/
├── core/
│   ├── appwrite/      # Appwrite client, constants, config
│   ├── router/        # GoRouter — all route definitions
│   └── errors/        # Sentry setup, global error handling
├── features/
│   ├── session/       # Session creation, lobby, lifecycle
│   ├── voting/        # Per-beer voting flow (host + participant views)
│   ├── results/       # Results reveal and ranking
│   └── beer/          # Beer addition (barcode scan + manual), beer state
└── shared/
    ├── widgets/        # Reusable UI components
    ├── domain/         # Entities shared across features
    └── infra/          # Shared infra utilities
```

Each feature has four layers: `presentation/` (screens, widgets, Riverpod providers), `domain/` (entities, repository interfaces, use cases), `data/` (models, DTOs, datasources), `infra/` (Appwrite repository implementations).

## Navigation (GoRouter)

```
/                          → HomeScreen
/session/create            → CreateSessionScreen
/session/:id/lobby         → LobbyScreen
/session/:id/voting        → VotingScreen
/session/:id/waiting       → WaitingScreen (between rounds)
/session/:id/results       → ResultsScreen
/join/:code                → deep link → lookups session → redirect to LobbyScreen
```

Deep link scheme: `brewtaste://join/:code` via `app_links` package. Android: intent filter in `AndroidManifest.xml`. iOS: scheme in `Info.plist`.

## Appwrite Data Model

Four collections. See `docs/data-model.md` for full schema and permissions.

- **`sessions`** — `hostId`, `status` (waiting/tasting/revealed), `code` (BREW-XXXX), `isBlind`, `guessFields[]`, `createdAt`
- **`participants`** — `sessionId`, `userId`, `pseudo`, `isHost`, `joinedAt`
- **`beers`** — `sessionId`, `name`, `brewery`, `style?`, `hops?`, `aromas?`, `status` (pending/voting/revealed), `addedAt`
- **`votes`** — `sessionId`, `beerId`, `userId`, `score` (1–10, null if skip), `guesses` (JSON string), `hasSkipped`

## Key Business Rules

- **Vote lock** — enforced by Appwrite: `votes` collection has no `update` permission. Never add one.
- **Blind mode** — filter `name` and `brewery` from beer data in the app while `beer.status != revealed`.
- **Skip** — `hasSkipped: true` votes are excluded from score averages.
- **Session code** — generated client-side (`BREW-XXXX`, random 4-digit). Check uniqueness against active sessions before creating; retry up to 5 times on collision, then surface to Sentry.
- **Session validity** — a code is only joinable if the session is `waiting` or `tasting` and was created less than 24h ago.
- **Kick cascade** — when the host kicks a participant, delete all their votes in the session first, then delete the participant document (client-side for MVP).
- **Results calculation** — done entirely client-side at reveal: fetch all session votes, compute average per beer (skips excluded), sort descending by average then by vote count on tie. Guess comparison: case-insensitive trimmed string equality.

## Sentry

Only unexpected errors go to Sentry (Appwrite exceptions, parse errors). Business errors (session not found, code invalid, session expired) are handled in UI and not sent to Sentry.

```dart
// main.dart entry point
await SentryFlutter.init((options) {
  options.dsn = Env.sentryDsn;
  options.tracesSampleRate = 0.3;
}, appRunner: () => runApp(ProviderScope(child: App())));
```

## Realtime Subscriptions (Appwrite)

| Subscription | Consumer | Purpose |
|---|---|---|
| `sessions.[id]` | Everyone | Detect session `status` changes |
| `participants` | Host | Live arrivals / kicks |
| `votes` | Host | Vote count per round |

## Open Food Facts (barcode enrichment)

`GET https://world.openfoodfacts.org/api/v2/product/{barcode}` — no API key needed. Fields used: `product_name`, `brands`. Coverage for craft beers is limited; always fall back silently to manual entry if not found.

## Docs

**Always read the relevant docs before implementing any feature.** These are the source of truth for architecture decisions, patterns, and business rules.

- `docs/data-model.md` — full Appwrite schema, permissions, state machines
- `docs/session-flow.md` — session lifecycle, join flow, round flow, results calculation, realtime events
- `docs/feature-architecture.md` — layer responsibilities, what each feature owns
- `docs/flutter-guidelines.md` — Riverpod patterns, GoRouter usage, clean architecture layer rules, widget conventions, error handling, naming, blind mode filtering
- `docs/git-guidelines.md` — branch naming, commit convention (Conventional Commits), PR rules, release flow
- `plan/MASTER_PLAN.md` — phased implementation roadmap, current progress
- `plan/features/` — per-feature implementation plans (created just-in-time)

## Development Workflow

For every feature/task, follow this process strictly:

1. **Create the feature branch** — from `develop`, following `docs/git-guidelines.md` naming conventions
2. **Write `plan/features/<name>.md`** — implementation plan with approach, file structure, and key decisions. Done just-in-time, not upfront.
3. **Implement** — run `flutter analyze` + `flutter test` locally before committing
4. **Open a PR targeting `develop`** — never merge feature/fix/chore PRs to `main`
5. **Merge** — Codemagic `pr-check` must pass first
6. **Mark task complete** in `plan/MASTER_PLAN.md`

`main` is the release branch only. All development goes through `develop`.

## Environment

Credentials (Appwrite endpoint/project ID, Sentry DSN) are loaded from `.env`, which is gitignored. `google-services.json` and `GoogleService-Info.plist` are also gitignored.
