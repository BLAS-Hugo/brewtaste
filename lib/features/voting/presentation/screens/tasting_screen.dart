import 'package:brewtaste/features/voting/presentation/notifiers/tasting_notifier.dart';
import 'package:brewtaste/shared/domain/entities/beer.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TastingScreen extends ConsumerWidget {
  const TastingScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(tastingProvider(sessionId), (previous, next) {
      next.whenData((tasting) {
        if (tasting.session.status == SessionStatus.revealed) {
          context.go('/session/$sessionId/results');
        }
      });
    });

    final state = ref.watch(tastingProvider(sessionId));

    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$error')),
      ),
      data: (tasting) => tasting.isHost
          ? _HostTasting(tasting: tasting, sessionId: sessionId)
          : _ParticipantTasting(tasting: tasting, sessionId: sessionId),
    );
  }
}

// ---------------------------------------------------------------------------
// Host view
// ---------------------------------------------------------------------------

class _HostTasting extends ConsumerWidget {
  const _HostTasting({required this.tasting, required this.sessionId});

  final TastingState tasting;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(tastingProvider(sessionId).notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Dégustation')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/session/$sessionId/add-beer'),
        tooltip: 'Ajouter une bière',
        child: const Icon(Icons.add),
      ),
      body: tasting.visibleBeers.isEmpty
          ? const Center(child: Text('Aucune bière. Ajoutez-en une via +.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tasting.visibleBeers.length,
              itemBuilder: (context, index) {
                final beer = tasting.visibleBeers[index];
                return _HostBeerTile(
                  beer: beer,
                  voteCount: tasting.voteCountFor(beer.id),
                  participantCount: tasting.participantCount,
                  onStartVoting: () => notifier.startVoting(beer.id),
                  onReveal: () => notifier.revealBeer(beer.id),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton(
            onPressed: notifier.endSession,
            child: const Text('Terminer la session'),
          ),
        ),
      ),
    );
  }
}

class _HostBeerTile extends StatelessWidget {
  const _HostBeerTile({
    required this.beer,
    required this.voteCount,
    required this.participantCount,
    required this.onStartVoting,
    required this.onReveal,
  });

  final Beer beer;
  final int voteCount;
  final int participantCount;
  final VoidCallback onStartVoting;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (statusLabel, statusColor) = switch (beer.status) {
      BeerStatus.pending => ('En attente', colorScheme.onSurfaceVariant),
      BeerStatus.voting => ('Vote en cours', colorScheme.primary),
      BeerStatus.revealed => ('Révélée', colorScheme.tertiary),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                children: [
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
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                        ),
                  ),
                ],
              ),
              if (beer.status == BeerStatus.pending)
                FilledButton.tonal(
                  onPressed: onStartVoting,
                  child: const Text('Démarrer le vote'),
                ),
              if (beer.status == BeerStatus.voting)
                Row(
                  spacing: 12,
                  children: [
                    Text(
                      '$voteCount/$participantCount votes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    FilledButton(
                      onPressed: onReveal,
                      child: const Text('Révéler'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Participant view
// ---------------------------------------------------------------------------

class _ParticipantTasting extends StatelessWidget {
  const _ParticipantTasting({
    required this.tasting,
    required this.sessionId,
  });

  final TastingState tasting;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final activeBeer = tasting.activeBeer;

    if (activeBeer == null) {
      return const Scaffold(body: _WaitingView());
    }

    if (tasting.hasVotedFor(activeBeer.id)) {
      return Scaffold(
        body: _VoteConfirmedView(
          beer: activeBeer,
          isBlind: tasting.session.isBlind,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Voter')),
      body: _VotingForm(
        session: tasting.session,
        beer: activeBeer,
        sessionId: sessionId,
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          const CircularProgressIndicator(),
          Text(
            'En attente du prochain tour...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _VoteConfirmedView extends StatelessWidget {
  const _VoteConfirmedView({required this.beer, required this.isBlind});

  final Beer beer;
  final bool isBlind;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showName =
        !isBlind || beer.status == BeerStatus.revealed;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: colorScheme.primary,
          ),
          Text(
            'Vote enregistré ✓',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (showName && beer.name != null)
            Text(
              beer.name!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );
  }
}

class _VotingForm extends ConsumerStatefulWidget {
  const _VotingForm({
    required this.session,
    required this.beer,
    required this.sessionId,
  });

  final Session session;
  final Beer beer;
  final String sessionId;

  @override
  ConsumerState<_VotingForm> createState() => _VotingFormState();
}

class _VotingFormState extends ConsumerState<_VotingForm> {
  int? _score;
  late final Map<String, TextEditingController> _guessControllers;

  @override
  void initState() {
    super.initState();
    _guessControllers = {
      for (final field in _visibleGuessFields)
        field.name: TextEditingController(),
    };
  }

  List<GuessField> get _visibleGuessFields => widget.session.guessFields
      .where(
        (field) =>
            field != GuessField.brewery || widget.session.isBlind,
      )
      .toList();

  @override
  void dispose() {
    for (final controller in _guessControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _collectedGuesses => {
        for (final entry in _guessControllers.entries)
          if (entry.value.text.trim().isNotEmpty)
            entry.key: entry.value.text.trim(),
      };

  String _labelFor(GuessField field) => switch (field) {
        GuessField.style => 'Style',
        GuessField.brewery => 'Brasserie',
        GuessField.hops => 'Houblon',
        GuessField.aromas => 'Arômes',
      };

  Future<void> _skip() async {
    await ref.read(tastingProvider(widget.sessionId).notifier).submitVote(
          beerId: widget.beer.id,
          guesses: {},
          hasSkipped: true,
        );
  }

  Future<void> _submit() async {
    if (_score == null) return;
    await ref.read(tastingProvider(widget.sessionId).notifier).submitVote(
          beerId: widget.beer.id,
          guesses: _collectedGuesses,
          hasSkipped: false,
          score: _score,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(tastingProvider(widget.sessionId)).isLoading;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (widget.beer.name != null) ...[
          Text(
            widget.beer.name!,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
        ],
        Text(
          'Votre note',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          spacing: 8,
          children: [
            Text(
              '1',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Expanded(
              child: Slider(
                value: (_score ?? 5).toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: _score?.toString() ?? '—',
                onChanged: (value) =>
                    setState(() => _score = value.round()),
              ),
            ),
            Text(
              '10',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        if (_score != null)
          Center(
            child: Text(
              '$_score / 10',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        if (_visibleGuessFields.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Vos suppositions',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          for (final field in _visibleGuessFields) ...[
            TextFormField(
              controller: _guessControllers[field.name],
              decoration: InputDecoration(labelText: _labelFor(field)),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
          ],
        ],
        const SizedBox(height: 32),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : _skip,
                child: const Text('Passer'),
              ),
            ),
            Expanded(
              child: FilledButton(
                onPressed: (isLoading || _score == null) ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Voter'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
