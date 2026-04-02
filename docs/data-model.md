# Data Model — Appwrite Collections

## `sessions`

| Field | Type | Required | Notes |
|---|---|---|---|
| `hostId` | string | ✓ | Appwrite userId |
| `status` | enum | ✓ | `waiting` / `tasting` / `revealed` |
| `code` | string | ✓ | `BREW-XXXX`, unique, indexed |
| `isBlind` | boolean | ✓ | Hides `name` and `brewery` during voting |
| `guessFields` | string[] | ✓ | Subset of: `style`, `brewery`, `hops`, `aromas` |
| `createdAt` | datetime | ✓ | Used for 24h expiry check |

## `participants`

| Field | Type | Required | Notes |
|---|---|---|---|
| `sessionId` | string | ✓ | Relation to `sessions` |
| `userId` | string | ✓ | Appwrite anonymous userId |
| `pseudo` | string | ✓ | Chosen on join |
| `isHost` | boolean | ✓ | |
| `joinedAt` | datetime | ✓ | |

## `beers`

| Field | Type | Required | Notes |
|---|---|---|---|
| `sessionId` | string | ✓ | Relation to `sessions` |
| `name` | string | ✓ | Masked in app if `isBlind` until `status == revealed` |
| `brewery` | string | ✓ | Masked in app if `isBlind` until `status == revealed` |
| `style` | string? | — | Nullable |
| `hops` | string? | — | Nullable |
| `aromas` | string? | — | Nullable |
| `status` | enum | ✓ | `pending` / `voting` / `revealed` |
| `addedAt` | datetime | ✓ | Also determines beer order in results |

## `votes`

| Field | Type | Required | Notes |
|---|---|---|---|
| `sessionId` | string | ✓ | |
| `beerId` | string | ✓ | Relation to `beers` |
| `userId` | string | ✓ | |
| `score` | integer | — | 1–10; null if `hasSkipped` |
| `guesses` | string | — | JSON: `{ style?, brewery?, hops?, aromas? }` |
| `hasSkipped` | boolean | ✓ | |

---

## Permissions

| Collection | Create | Read | Update | Delete |
|---|---|---|---|---|
| `sessions` | any auth user | any auth user | hostId only | hostId only |
| `participants` | any auth user | any auth user | self or hostId | hostId only |
| `beers` | hostId only | any auth user | hostId only | hostId only |
| `votes` | self only | hostId + self | **never** | **never** |

> The vote lock is enforced entirely by the absence of `update` permission on `votes`. Do not add it.

---

## State Machines

**Session:**
```
waiting → tasting → revealed
```

**Beer:**
```
pending → voting → revealed
```
