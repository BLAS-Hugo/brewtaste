import 'dart:async';

import 'package:brewtaste/features/results/domain/entities/beer_result.dart';
import 'package:brewtaste/features/results/domain/entities/participant_vote.dart';
import 'package:brewtaste/features/results/domain/services/results_calculation_service.dart';
import 'package:brewtaste/features/results/presentation/notifiers/results_notifier.dart';
import 'package:brewtaste/shared/domain/entities/beer.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(resultsProvider(sessionId));

    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Résultats')),
        body: Center(child: Text('$error')),
      ),
      data: (results) => _ResultsView(results: results),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.results});

  final ResultsState results;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Résultats')),
      body: results.rankedBeers.isEmpty
          ? const Center(child: Text('Aucune bière dégustée.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: results.rankedBeers.length,
              itemBuilder: (context, index) {
                final beerResult = results.rankedBeers[index];
                return _BeerResultTile(
                  beerResult: beerResult,
                  onTap: () => _showDetailModal(context, beerResult, results),
                );
              },
            ),
    );
  }

  void _showDetailModal(
    BuildContext context,
    BeerResult beerResult,
    ResultsState results,
  ) {
    final participantVotes = ResultsCalculationService().votesForBeer(
      beer: beerResult.beer,
      votes: results.votes,
      participants: results.participants,
    );

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _BeerDetailModal(
          beerResult: beerResult,
          session: results.session,
          participantVotes: participantVotes,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Beer result tile
// ---------------------------------------------------------------------------

class _BeerResultTile extends StatelessWidget {
  const _BeerResultTile({
    required this.beerResult,
    required this.onTap,
  });

  final BeerResult beerResult;
  final VoidCallback onTap;

  String get _rankLabel => switch (beerResult.rank) {
        1 => '🥇',
        2 => '🥈',
        3 => '🥉',
        _ => '#${beerResult.rank}',
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final beer = beerResult.beer;
    final average = beerResult.averageScore;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    _rankLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        beer.name ?? '—',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (beer.brewery != null)
                        Text(
                          beer.brewery!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      Text(
                        '${beerResult.validVoteCount}/${beerResult.totalVoteCount} ont goûté',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (average == null)
                  Text(
                    "Personne\nn'a goûté",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        average.toStringAsFixed(1),
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '/ 10',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Beer detail modal
// ---------------------------------------------------------------------------

class _BeerDetailModal extends StatelessWidget {
  const _BeerDetailModal({
    required this.beerResult,
    required this.session,
    required this.participantVotes,
  });

  final BeerResult beerResult;
  final Session session;
  final List<ParticipantVote> participantVotes;

  String _guessFieldLabel(GuessField field) => switch (field) {
        GuessField.style => 'Style',
        GuessField.brewery => 'Brasserie',
        GuessField.hops => 'Houblon',
        GuessField.aromas => 'Arômes',
      };

  String? _beerFieldValue(Beer beer, GuessField field) => switch (field) {
        GuessField.style => beer.style,
        GuessField.brewery => beer.brewery,
        GuessField.hops => beer.hops,
        GuessField.aromas => beer.aromas,
      };

  @override
  Widget build(BuildContext context) {
    final beer = beerResult.beer;
    final colorScheme = Theme.of(context).colorScheme;
    final calculator = ResultsCalculationService();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            beer.name ?? '—',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (beer.brewery != null) ...[
            const SizedBox(height: 2),
            Text(
              beer.brewery!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          if (beer.style != null || beer.hops != null || beer.aromas != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (beer.style != null)
                    _InfoChip(label: 'Style', value: beer.style!),
                  if (beer.hops != null)
                    _InfoChip(label: 'Houblon', value: beer.hops!),
                  if (beer.aromas != null)
                    _InfoChip(label: 'Arômes', value: beer.aromas!),
                ],
              ),
            ),
          if (beerResult.averageScore != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  beerResult.averageScore!.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ 10',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          if (participantVotes.isEmpty)
            Text(
              "Personne n'a goûté cette bière.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            )
          else ...[
            Text(
              'Votes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            for (final participantVote in participantVotes) ...[
              _ParticipantVoteTile(
                participantVote: participantVote,
                session: session,
                beer: beer,
                guessFieldLabel: _guessFieldLabel,
                beerFieldValue: _beerFieldValue,
                guessIsCorrect: calculator.guessIsCorrect,
              ),
              const Divider(height: 1),
            ],
          ],
        ],
      ),
    );
  }
}

class _ParticipantVoteTile extends StatelessWidget {
  const _ParticipantVoteTile({
    required this.participantVote,
    required this.session,
    required this.beer,
    required this.guessFieldLabel,
    required this.beerFieldValue,
    required this.guessIsCorrect,
  });

  final ParticipantVote participantVote;
  final Session session;
  final Beer beer;
  final String Function(GuessField) guessFieldLabel;
  final String? Function(Beer, GuessField) beerFieldValue;
  final bool Function(String, String) guessIsCorrect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  participantVote.pseudo,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                participantVote.hasSkipped
                    ? '—'
                    : '${participantVote.score}/10',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: participantVote.hasSkipped
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          for (final field in session.guessFields)
            if (beerFieldValue(beer, field) != null)
              _GuessRow(
                label: guessFieldLabel(field),
                guess: participantVote.guesses[field.name],
                truth: beerFieldValue(beer, field)!,
                guessIsCorrect: guessIsCorrect,
              ),
        ],
      ),
    );
  }
}

class _GuessRow extends StatelessWidget {
  const _GuessRow({
    required this.label,
    required this.guess,
    required this.truth,
    required this.guessIsCorrect,
  });

  final String label;
  final String? guess;
  final String truth;
  final bool Function(String, String) guessIsCorrect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasGuess = guess != null && guess!.isNotEmpty;
    final isCorrect = hasGuess && guessIsCorrect(guess!, truth);

    return Row(
      spacing: 8,
      children: [
        Text(
          '$label :',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        if (hasGuess) ...[
          Text(
            guess!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Icon(
            isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 16,
            color: isCorrect ? colorScheme.tertiary : colorScheme.error,
          ),
        ] else
          Text(
            '—',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
