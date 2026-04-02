# Feature Architecture

Each feature under `lib/features/` follows clean architecture with four layers.

## Layer Responsibilities

### `presentation/`
- Screens and feature-specific widgets
- Riverpod providers (notifiers, `FutureProvider`, `StreamProvider`)
- Depends on domain interfaces — never imports infra directly

### `domain/`
- Entities (pure Dart — no `fromJson`, no Appwrite types, no Flutter imports)
- Repository interfaces (`abstract class ISessionRepository { ... }`)
- Use cases (single-responsibility classes, e.g. `CalculateResultsUseCase`)

### `data/`
- DTOs and model classes: serialization/deserialization only
- DTOs map to/from domain entities; they are never passed to the UI

### `infra/`
- Concrete Appwrite repository implementations — the **only** layer that imports `dart_appwrite`
- Maps `appwrite.Document` → domain entity via the feature's DTO
- Applies blind mode filtering here before returning entities (see flutter-guidelines.md)

## Dependency Direction

```
presentation ──▶ domain ◀── infra
```

`presentation` and `infra` both depend on `domain`. They never depend on each other. Providers in `presentation/` wire infra implementations to domain interfaces at the Riverpod layer.

---

## Features

### `session`
Handles session creation, the lobby, and session lifecycle transitions (`waiting → tasting → revealed`). Contains the host's session control panel. Manages the realtime subscription to `sessions.[id]` for all users.

### `voting`
The per-beer voting flow. Two parallel views: host view (add beer, launch vote, see vote count, advance round) and participant view (score slider, guess fields, skip). Manages realtime subscription to `votes` (host only).

### `beer`
Beer creation — barcode scanner calling Open Food Facts API, manual entry form. Shared beer entity and status management (`pending → voting → revealed`).

### `results`
Fetches all votes at reveal, runs client-side calculation, renders ranked list and per-beer detail modal with individual scores and guess comparisons.

---

## `core/`

### `core/appwrite/`
Singleton Appwrite client, collection/database IDs as constants, and any shared query helpers.

### `core/router/`
GoRouter configuration: all route definitions, redirect guards (e.g. redirect to `/` if session not found or expired), and deep link handler for `brewtaste://join/:code`.

### `core/errors/`
Sentry initialization. Distinction between unexpected errors (sent to Sentry) and business errors (handled in UI, not sent). A top-level error boundary that catches unhandled exceptions.

---

## `shared/`

### `shared/domain/`
Entities used across multiple features (e.g. `Session`, `Beer`, `Participant`, `Vote`).

### `shared/widgets/`
Reusable UI components not tied to a specific feature.

### `shared/infra/`
Cross-feature infrastructure utilities (e.g. env loading, common Appwrite query builders).
