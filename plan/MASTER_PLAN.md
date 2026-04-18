# BrewTaste — Master Implementation Plan

**Status:** In progress — Phase 3 complete, Phase 4 next  
**Target:** MVP (Android + iOS)

---

## Phases Overview

| # | Phase | Description | Status |
|---|---|---|---|
| 0 | CI/CD + Scaffolding | Codemagic, project structure, env setup | ✅ Done |
| 1 | Core Infrastructure | Appwrite client, auth, router, Sentry | ✅ Done |
| 2 | Session Feature | Create, join, lobby | ✅ Done |
| 3 | Beer Feature | Add beer (manual + barcode), lobby beer list | ✅ Done |
| 4 | Voting Feature | Vote flow, waiting screen | 🔜 Next |
| 5 | Results Feature | Calculation, ranking screen, detail modal | — |
| 6 | Deep Links + QR | `brewtaste://` scheme, QR code display/scan | — |
| 7 | Polish & Audit | Blind mode audit, business rules, UX | — |

---

## Phase 0 — CI/CD & Project Scaffolding ✅

> **Goal:** Build pipeline working before any feature code lands.

- [x] **0.1** Create `plan/` folder structure
- [x] **0.2** Set up Codemagic workflow (analyze + test on PR, APK/IPA build on `develop`/`main`, Sentry + Appwrite env vars, Flutter SDK + pub-cache caching)
- [x] **0.3** Configure `.env` for local dev (Appwrite endpoint/project ID, Sentry DSN)
- [x] **0.4** Create full `lib/` folder structure (`core/`, `features/`, `shared/`)
- [x] **0.5** Add all required packages to `pubspec.yaml` (`appwrite`, `flutter_riverpod`, `riverpod_annotation`, `go_router`, `sentry_flutter`, `app_links`, `qr_flutter`, `mobile_scanner`, `dio`, `flutter_svg`, `freezed`, `riverpod_generator`, `build_runner`, `very_good_analysis`)

---

## Phase 1 — Core Infrastructure ✅

> **Goal:** App boots, authenticates anonymously, routes work, errors go to Sentry.

- [x] **1.1** Appwrite client singleton + constants (`projectId`, `endpoint`, collection IDs)
- [x] **1.2** Anonymous auth — auto-login on app start, `authProvider` exposes `userId`
- [x] **1.3** GoRouter setup — all routes defined, error page
- [x] **1.4** Deep link handler wired into router (`brewtaste://join/:code` → `/join/:code`)
- [x] **1.5** Sentry init in `main.dart`, `ErrorReporter.report()` helper
- [x] **1.6** Shared domain entities: `Session`, `Participant`, `Beer`, `Vote`
- [x] **1.7** `HomeScreen` — illustrated entry point with "Créer" / "Rejoindre" CTAs

---

## Phase 2 — Session Feature ✅

> **Goal:** Host can create a session; participant can join it; both see live lobby.

- [x] **2.1** `CreateSessionScreen` — pseudo field, blind mode toggle, guess fields checkboxes, config section visually grouped
- [x] **2.2** `CreateSessionUseCase` — `BREW-XXXX` code generation, uniqueness check (up to 5 retries, Sentry on exhaustion)
- [x] **2.3** `JoinSessionScreen` — code + pseudo fields with prefix icons
- [x] **2.4** `JoinSessionUseCase` — validate code (status check, 24h expiry), create participant doc
- [x] **2.5** `LobbyScreen` (Host view) — QR code, participant list, kick button, beer list, Add beer FAB, start session button (enabled at ≥2 participants)
- [x] **2.6** `LobbyScreen` (Participant view) — waiting card, participant list
- [x] **2.7** Realtime subscription: `participants` collection → live arrivals / kicks
- [x] **2.8** Kick logic — delete participant votes first, then participant document
- [x] **2.9** QR code display on host lobby (border + surface background)

---

## Phase 3 — Beer Feature ✅

> **Goal:** Host can add beers on the fly during a tasting session (manual or barcode scan).

- [x] **3.1** `AddBeerScreen` — name* / brewery* required, style / hops / aromas optional, inline "Requis" validation, error message on failure
- [x] **3.2** Barcode scanner (`BarcodeScanScreen`) — `MobileScanner` widget, returns `ScannedBeer` via `Navigator.pop()`
- [x] **3.3** Open Food Facts API (`GET /api/v2/product/{barcode}` via Dio) — pre-fills name + brewery; snackbar "Produit introuvable" on miss
- [x] **3.4** `AddBeerUseCase` — trim + clean fields, write to Appwrite with `status: pending`
- [x] **3.5** `EditBeerUseCase` — update beer fields (between rounds)
- [x] **3.6** `StartVotingUseCase` — set `beer.status = voting`
- [x] **3.7** `BeerRepository` + `AppwriteBeerRepository` — `addBeer`, `editBeer`, `startVoting`, `getBeers`, `watchBeers` (StreamController + reconnect pattern)
- [x] **3.8** `LobbyNotifier` / `LobbyState` extended with `beers` field + `watchBeers` subscription
- [x] **3.9** Host lobby beer list — name + status badge (`En attente` / `Vote en cours` / `Révélée`), empty state hint

---

## Phase 4 — Voting Feature 🔜

> **Goal:** Host adds a beer and starts a vote; participants vote; host closes the round and moves on.

**Session flow during tasting:**
```
Host adds beer (AddBeerScreen, accessible from tasting screen)
  ↓
Host taps "Démarrer le vote" → StartVotingUseCase → beer.status = voting
  ↓
Participants see VotingScreen (score 1–10 + guess fields + skip)
  ↓
Host sees live vote count (X/Y)
  ↓
Host taps "Révéler" → AdvanceRoundUseCase → beer.status = revealed
  ↓
All clients see revealed beer info; host can add next beer
```

- [ ] **4.1** `VotingScreen` (Participant) — score slider 1–10, guess fields (conditional on `session.guessFields`), skip button, submit; blind mode hides name/brewery
- [ ] **4.2** `SubmitVoteUseCase` — write vote to Appwrite (one-shot, no update permission)
- [ ] **4.3** Blind mode filter in `AppwriteBeerRepository` — strip `name`/`brewery` when `status != revealed` and `session.isBlind`
- [ ] **4.4** `TastingScreen` (Host) — beer list with status badges, "Ajouter une bière" FAB, per-beer vote counter (X/Y participants), "Démarrer le vote" / "Révéler" actions, "Terminer la session" button
- [ ] **4.5** `AdvanceRoundUseCase` — set `beer.status = revealed`
- [ ] **4.6** Realtime subscription: `votes` collection → host vote counter updates live
- [ ] **4.7** `WaitingScreen` (Participant) — shown when no active vote (`beer.status != voting`); listens for next `voting` beer or session `revealed`
- [ ] **4.8** Realtime: `sessions/{id}` + `beers` → all clients navigate on status change

---

## Phase 5 — Results Feature

> **Goal:** Host closes session; all clients see ranked results simultaneously.

- [ ] **5.1** `CloseSessionUseCase` — set `session.status = revealed`
- [ ] **5.2** `ResultsCalculationService` — fetch all session votes, compute per-beer average (skips excluded), sort descending by avg then vote count on tie
- [ ] **5.3** `ResultsScreen` — ranked beer list, `X/Y ont goûté` per beer, reveal animation
- [ ] **5.4** `BeerDetailModal` — full beer info, per-participant score + guesses (✓/✗), skips as `—`
- [ ] **5.5** Beers with zero non-skipped votes shown as "Personne n'a goûté"

---

## Phase 6 — Deep Links & QR

> **Goal:** `brewtaste://join/BREW-XXXX` opens the app directly into the join flow.

- [ ] **6.1** Android intent filter in `AndroidManifest.xml`
- [ ] **6.2** iOS scheme in `Info.plist`
- [ ] **6.3** `app_links` integration → feed into GoRouter `/join/:code`
- [ ] **6.4** QR code scan from join screen (scan host's QR → auto-fill code field)
- [ ] **6.5** End-to-end deep link test (manual)

---

## Phase 7 — Polish & Audit

> **Goal:** All business rules enforced; app is shippable.

- [ ] **7.1** Blind mode audit — no `name`/`brewery` leaks while `beer.status != revealed`
- [ ] **7.2** Vote lock audit — confirm no update path exists in app
- [ ] **7.3** Kick cascade test — votes deleted before participant doc
- [ ] **7.4** Session validity — 24h expiry enforced on join
- [ ] **7.5** Code collision retry (up to 5, then Sentry)
- [ ] **7.6** 0-vote beer displayed as "Personne n'a goûté" (no average shown)
- [ ] **7.7** UI polish: loading states, error toasts, empty states
- [ ] **7.8** Sentry: only unexpected errors reported (not business errors)

---

## Implementation Order

```
Phase 0 (CI/CD + scaffold) → Phase 1 (core infra + auth + router)
  → Phase 2 (session: create + join + lobby)
    → Phase 3 (beer: add beer + lobby list)
      → Phase 4 (voting: tasting screen + vote flow)
        → Phase 5 (results)
          → Phase 6 (deep links + QR)
            → Phase 7 (polish)
```

---

## Development Workflow

1. **Create a feature branch** — from `develop`, following `docs/git-guidelines.md` naming conventions.
2. **Implement** — run `flutter analyze` + `flutter test` locally before committing.
3. **Open a PR → `develop`** — Codemagic PR check must pass.
4. **Merge** — squash or merge commit per git guidelines.
5. **Update this file** — mark completed tasks, update Status header.
