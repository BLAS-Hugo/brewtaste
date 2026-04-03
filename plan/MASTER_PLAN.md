# BrewTaste — Master Implementation Plan

**Status:** Planning  
**Target:** MVP (Android + iOS)

---

## Phases Overview

| # | Phase | Description | Priority |
|---|---|---|---|
| 0 | CI/CD + Scaffolding | Codemagic, project structure, env setup | Critical |
| 1 | Core Infrastructure | Appwrite client, auth, router, Sentry | Critical |
| 2 | Session Feature | Create, join, lobby | High |
| 3 | Beer Feature | Add beer (manual + barcode), state | High |
| 4 | Voting Feature | Vote flow, waiting screen | High |
| 5 | Results Feature | Calculation, ranking screen, detail modal | High |
| 6 | Deep Links + QR | `brewtaste://` scheme, QR code display/scan | Medium |
| 7 | Polish & Audit | Blind mode audit, business rules, UX | Medium |

---

## Phase 0 — CI/CD & Project Scaffolding

> **Goal:** Build pipeline working before any feature code lands.

### Tasks

- [ ] **0.1** Create `plan/` folder structure (feature plan stubs)
- [ ] **0.2** Set up Codemagic workflow
  - Flutter analyze + test on every PR
  - Build APK (Android) + IPA (iOS) on `main`/`develop`
  - Environment variables via Codemagic encrypted vars (Appwrite, Sentry)
  - See `plan/features/cicd.md` for details
- [ ] **0.3** Configure `.env` + `flutter_dotenv` (or `envied`) for local dev
- [ ] **0.4** Create full `lib/` folder structure (empty files/barrel exports)
  - `core/appwrite/`, `core/router/`, `core/errors/`
  - `features/session/`, `features/voting/`, `features/results/`, `features/beer/`
  - `shared/widgets/`, `shared/domain/`, `shared/infra/`
- [ ] **0.5** Add all required packages to `pubspec.yaml`

### Key packages to add

| Package | Purpose |
|---|---|
| `appwrite` | Backend SDK |
| `riverpod` + `flutter_riverpod` + `riverpod_annotation` | State management |
| `go_router` | Navigation |
| `sentry_flutter` | Error monitoring |
| `app_links` | Deep link handling |
| `qr_flutter` | QR code generation |
| `mobile_scanner` | Barcode / QR scan |
| `envied` | Compile-time env vars (or `flutter_dotenv`) |
| `freezed` + `json_serializable` | Immutable models + JSON |
| `riverpod_generator` | Code gen for providers |
| `build_runner` | Code generation runner |
| `very_good_analysis` | Already present |

---

## Phase 1 — Core Infrastructure

> **Goal:** App boots, authenticates anonymously, routes work, errors go to Sentry.

See `plan/features/core_infrastructure.md`

### Tasks

- [ ] **1.1** Appwrite client singleton + constants (`projectId`, `endpoint`, collection IDs)
- [ ] **1.2** Anonymous auth service — auto-login on app start, expose `userId`
- [ ] **1.3** GoRouter setup — all routes defined (shells, redirects, error page)
- [ ] **1.4** Deep link handler wired into router (`/join/:code`)
- [ ] **1.5** Sentry init in `main.dart`, global error boundary
- [ ] **1.6** Shared domain entities: `Session`, `Participant`, `Beer`, `Vote`
- [ ] **1.7** `HomeScreen` stub (entry point — join / create CTAs)

---

## Phase 2 — Session Feature

> **Goal:** Host can create a session; participant can join it; both see live lobby.

See `plan/features/session.md`

### Tasks

- [ ] **2.1** `CreateSessionScreen` — form (isBlind toggle, guess fields checkboxes)
- [ ] **2.2** `CreateSessionUseCase` — code generation (`BREW-XXXX`), uniqueness check (up to 5 retries), Appwrite write
- [ ] **2.3** `JoinSessionScreen` — code input form
- [ ] **2.4** `JoinSessionUseCase` — validate code (status, 24h expiry), create participant doc
- [ ] **2.5** `LobbyScreen` (Host view) — participant list, kick button, start session button
- [ ] **2.6** `LobbyScreen` (Participant view) — participant list, waiting state
- [ ] **2.7** Realtime subscription: `participants` collection → live arrivals / kicks
- [ ] **2.8** Kick logic — delete participant votes first, then participant document
- [ ] **2.9** QR code display on host lobby (from session code)

---

## Phase 3 — Beer Feature

> **Goal:** Host can add a beer (manual or barcode), beer stored in Appwrite.

See `plan/features/beer.md`

### Tasks

- [ ] **3.1** `AddBeerScreen` — manual form (name*, brewery*, style?, hops?, aromas?)
- [ ] **3.2** Barcode scanner integration (`mobile_scanner`)
- [ ] **3.3** Open Food Facts API call on scan result → pre-fill form fields
- [ ] **3.4** `AddBeerUseCase` — write beer to Appwrite with `status: pending`
- [ ] **3.5** `EditBeerUseCase` — update beer fields (only allowed between rounds)
- [ ] **3.6** `StartVotingUseCase` — set `beer.status = voting`

---

## Phase 4 — Voting Feature

> **Goal:** Participants vote per beer; host sees live vote count; rounds advance.

See `plan/features/voting.md`

### Tasks

- [ ] **4.1** `VotingScreen` (Participant) — slider 1–10, guess fields (conditional on session config), skip button, submit
- [ ] **4.2** `SubmitVoteUseCase` — write vote to Appwrite (one-shot, no update)
- [ ] **4.3** Blind mode filter — strip `name`/`brewery` from beer data while `status != revealed`
- [ ] **4.4** `VotingScreen` (Host) — vote counter (X/Y), advance round button
- [ ] **4.5** Realtime subscription: `votes` collection → host vote counter update
- [ ] **4.6** `WaitingScreen` (Participant) — shown between rounds; listens to `session.status` + beer status changes
- [ ] **4.7** `AdvanceRoundUseCase` — set current beer `status = revealed`, create next beer or prompt host
- [ ] **4.8** Realtime subscription: `sessions/{id}` → all clients react to status changes

---

## Phase 5 — Results Feature

> **Goal:** Host closes session; all clients see ranked results simultaneously.

See `plan/features/results.md`

### Tasks

- [ ] **5.1** `CloseSessionUseCase` — set `session.status = revealed`
- [ ] **5.2** `ResultsCalculationService` — client-side: fetch all votes, compute averages (skips excluded), sort (avg desc, vote count on tie)
- [ ] **5.3** `ResultsScreen` — ranked beer list, `X/Y ont goûté` per beer
- [ ] **5.4** `BeerDetailModal` — full beer info revealed, per-participant notes + guesses (✓/✗), skips as `—`
- [ ] **5.5** Guess comparison logic: `toLowerCase().trim()` equality

---

## Phase 6 — Deep Links & QR

> **Goal:** `brewtaste://join/BREW-XXXX` opens the app directly into the join flow.

See `plan/features/deep_links.md`

### Tasks

- [ ] **6.1** Android intent filter in `AndroidManifest.xml`
- [ ] **6.2** iOS scheme in `Info.plist`
- [ ] **6.3** `app_links` integration → feed into GoRouter `/join/:code`
- [ ] **6.4** QR code scan flow (from home screen / join screen)
- [ ] **6.5** End-to-end deep link test (manual + automated)

---

## Phase 7 — Polish & Audit

> **Goal:** All business rules enforced; app is shippable.

### Checklist

- [ ] **7.1** Blind mode audit — verify no `name`/`brewery` leaks while `beer.status != revealed`
- [ ] **7.2** Vote lock audit — confirm no update path exists in app
- [ ] **7.3** Kick cascade test — votes deleted before participant doc
- [ ] **7.4** Session validity — 24h expiry enforced on join
- [ ] **7.5** Code collision retry (up to 5, then Sentry)
- [ ] **7.6** 0-vote beer displayed as "Personne n'a goûté" (no average shown)
- [ ] **7.7** UI polish: loading states, error toasts, empty states
- [ ] **7.8** Sentry: only unexpected errors sent (not business errors)

---

## Implementation Order Rationale

```
Phase 0 (CI/CD + scaffold) → Phase 1 (core infra + auth + router)
  → Phase 2 (session: create + join + lobby)
    → Phase 3 (beer: add beer)
      → Phase 4 (voting: vote flow)
        → Phase 5 (results)
          → Phase 6 (deep links + QR)
            → Phase 7 (polish)
```

Phases 0–1 are pure infrastructure and unblock all feature work. CI/CD is first so every subsequent PR is validated. Features are ordered by data dependency: you need a session before beers, beers before votes, votes before results.

---

## Development Workflow

For every phase/task above, follow this process:

1. **Write the implementation plan** — create `plan/features/<name>.md` with the detailed approach, file structure, key decisions, and edge cases. This is done at the start of the task, not upfront, so it reflects actual context.
2. **Create a feature branch** — following `docs/git-guidelines.md` naming conventions.
3. **Implement** — write the code, run `flutter analyze` + `flutter test` locally.
4. **Open a PR → `develop`** — Codemagic PR check must pass (analyze + test).
5. **Merge** — squash or merge commit per git guidelines.
6. **Mark task complete** in this file.

Feature plan files in `plan/features/` are created **just-in-time**, not upfront — context accumulated during earlier phases makes them more accurate.
