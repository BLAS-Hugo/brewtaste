# Shared Domain Entities — Implementation Plan

**Branch:** `feat/core-entities`  
**Phase:** 1.6 + 1.7

## Goal

Pure Dart domain entities shared across all features. No Appwrite types, no JSON serialization — that belongs in feature `data/` layers. Freezed for immutability, value equality, and copyWith.

## Location

`lib/shared/domain/entities/`

## Entities

| File | Entity | Enums |
|---|---|---|
| `session.dart` | `Session` | `SessionStatus`, `GuessField` |
| `participant.dart` | `Participant` | — |
| `beer.dart` | `Beer` | `BeerStatus` |
| `vote.dart` | `Vote` | — |

## Key decisions

- `Beer.name` and `Beer.brewery` are **nullable** — infra layer nulls them when `isBlind && beer.status != revealed`
- `Vote.score` is **nullable** — null when `hasSkipped: true`
- `Vote.guesses` is `Map<String, String>` — keyed by `GuessField.name`
- `Session.guessFields` uses `List<GuessField>` enum instead of raw strings — cleaner domain model
- Enums co-located with their owning entity file

## HomeScreen stub

`lib/features/session/presentation/screens/home_screen.dart` — two CTAs, no navigation yet. Wired to `/` in router.
