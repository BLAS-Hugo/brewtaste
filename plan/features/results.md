# Results Feature — Implementation Plan

## Approach

Client-side calculation from existing data. No new Appwrite collection or repository.

Three existing repos provide all the data:
- `VoteRepository.getVotesForSession` (new public method, delegates to existing private `_getVotesForSession`)
- `BeerRepository.getBeers`
- `SessionRepository.getParticipants` + `getSessionById`

No realtime — session is `revealed`, data is immutable.

## Files Modified

- `lib/features/voting/domain/repositories/vote_repository.dart` — added `getVotesForSession`
- `lib/features/voting/infra/appwrite_vote_repository.dart` — implemented via existing private method

## Files Created

- `lib/features/results/domain/entities/beer_result.dart` — ranked beer with avg score + vote counts
- `lib/features/results/domain/entities/participant_vote.dart` — per-participant vote data for detail modal
- `lib/features/results/domain/services/results_calculation_service.dart` — pure calculation (rank, avg, guess comparison)
- `lib/features/results/presentation/notifiers/results_notifier.dart` — AsyncNotifier, parallel fetch, no realtime
- `lib/features/results/presentation/screens/results_screen.dart` — ranked list + detail modal

## Key Decisions

- `ResultsCalculationService` is a plain Dart class (no Riverpod), instantiated inline where needed
- Beers with 0 non-skipped votes get `averageScore = null` → displayed as "Personne n'a goûté"
- Sort: descending avg, tie-break by valid vote count; null-avg beers always last
- Detail modal: `DraggableScrollableSheet` with per-participant scores and ✓/✗ for each guess field
- Guess comparison: case-insensitive trimmed string equality
