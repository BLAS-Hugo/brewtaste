# Session Flow

## Lifecycle Overview

```
Host creates session
       ↓
    [waiting]  ← participants join via code / QR / deep link
       ↓         host sees arrivals in real-time, can kick
  Host launches (≥2 participants required)
       ↓
   [tasting]  ← host adds beers on the fly, one round per beer
       │
       │  ┌─────────────────────────────────────────┐
       │  │ Host adds beer (manual or barcode scan) │
       │  │         ↓                               │
       │  │ Host starts vote → beer.status=voting   │
       │  │         ↓                               │
       │  │ Participants vote / skip                │
       │  │         ↓                               │
       │  │ Host closes round → beer.status=revealed│
       │  │         ↓                               │
       │  │    Next beer? ──────────────────────────┘
       │
       ↓
  Host closes session
       ↓
  [revealed]  ← all participants see results simultaneously
```

Beers are added **during** the tasting phase, not upfront. The host can add as many beers as needed, in any order, throughout the session.

---

## Joining

- Methods: manual code entry (`BREW-XXXX`), QR scan, deep link `brewtaste://join/BREW-XXXX`
- `/join/:code` → lookup session by code → redirect to `/session/:id/lobby`
- If session not found, expired (>24h), or `revealed` → redirect to `/` with error message
- On join: participant picks a pseudo; anonymous Appwrite auth is created automatically if none exists

---

## Tasting Round (per beer)

```
Host adds beer (barcode scan or manual)
        ↓
Host launches vote → beer.status = voting
        ↓
Participants vote (score 1–10 + guesses) OR skip
        ↓
Host sees vote count in real-time
        ↓
Host moves to next beer (at any time, no need to wait for all votes)
```

- In **blind mode** (`isBlind: true`): `name` and `brewery` are filtered client-side while `beer.status != revealed`
- **Guess fields** available: `style`, `brewery` *(blind only)*, `hops`, `aromas` — only those activated by the host at session creation
- Votes are **locked on submit** (no update permission in Appwrite)
- Host can edit beer info between rounds

---

## Results Calculation (client-side)

1. Fetch all votes for the session in one query
2. Per beer: average score of non-skipped votes only
3. Sort beers: descending average, tie-broken by number of valid votes
4. Guess comparison: `guess.toLowerCase().trim() == truth.toLowerCase().trim()`
5. Beers with zero non-skipped votes: displayed as "Personne n'a goûté" (no average shown)

---

## Realtime Updates

| Event | Who listens | Action |
|---|---|---|
| `session.status` changes | Everyone | Navigate to next screen |
| New participant document | Host | Update lobby list |
| Participant deleted | Participant (self) | Redirect to home if kicked |
| New vote document | Host | Increment vote counter |
