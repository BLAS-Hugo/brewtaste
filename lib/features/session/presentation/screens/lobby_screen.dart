import 'package:brewtaste/features/session/presentation/notifiers/lobby_notifier.dart';
import 'package:brewtaste/shared/domain/entities/beer.dart';
import 'package:brewtaste/shared/domain/entities/participant.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Warm palette for participant avatars — derived by hashing the pseudo.
const _avatarColors = [
  Color(0xFFF5A623), // amber
  Color(0xFFC47A1E), // ochre
  Color(0xFFC0623A), // terra cotta
  Color(0xFF8B5E3C), // warm brown
  Color(0xFFD4A017), // golden
  Color(0xFFCC5500), // burnt orange
];

Color _avatarColor(String pseudo) =>
    _avatarColors[pseudo.codeUnits.fold(0, (sum, c) => sum + c) %
        _avatarColors.length];

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(lobbyProvider(sessionId), (prev, next) {
      next.whenData((state) {
        if (state.session.status == SessionStatus.tasting) {
          context.go('/session/$sessionId/voting');
          return;
        }
        if (!state.isHost) {
          final prevParticipants = switch (prev) {
            AsyncData(:final value) => value.participants,
            _ => null,
          };
          final wasHere = prevParticipants
                  ?.any((p) => p.userId == state.currentUserId) ??
              true;
          final stillHere =
              state.participants.any((p) => p.userId == state.currentUserId);
          if (wasHere && !stillHere) context.go('/');
        }
      });
    });

    final state = ref.watch(lobbyProvider(sessionId));

    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$e')),
      ),
      data: (lobby) => lobby.isHost
          ? _HostLobby(lobby: lobby, sessionId: sessionId)
          : _ParticipantLobby(lobby: lobby),
    );
  }
}

// ---------------------------------------------------------------------------
// Host view
// ---------------------------------------------------------------------------

class _HostLobby extends ConsumerWidget {
  const _HostLobby({required this.lobby, required this.sessionId});

  final LobbyState lobby;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final canStart = lobby.participants.length >= 2;

    final participantCount = lobby.participants.length;
    final beerCount = lobby.beers.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon'),
        actions: [
          _CodeChip(code: lobby.session.code),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/session/$sessionId/add-beer'),
        tooltip: 'Ajouter une bière',
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.onSurfaceVariant),
                  ),
                  padding: const EdgeInsets.all(1),
                  child: QrImageView(
                    data: 'brewtaste://join/${lobby.session.code}',
                    size: 160,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: colorScheme.onSurface,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                '$participantCount participant'
                '${participantCount > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: participantCount,
            itemBuilder: (context, index) {
              final participant = lobby.participants[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _ParticipantTile(
                  participant: participant,
                  trailing: participant.isHost
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.person_remove_outlined),
                          color: colorScheme.error,
                          tooltip: 'Exclure',
                          onPressed: () => ref
                              .read(lobbyProvider(sessionId).notifier)
                              .kick(
                                participantId: participant.id,
                                kickedUserId: participant.userId,
                              ),
                        ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                '$beerCount bière${beerCount > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          if (beerCount == 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  "Aucune bière ajoutée pour l'instant.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: beerCount,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _BeerTile(beer: lobby.beers[index]),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: canStart
                ? () =>
                    ref.read(lobbyProvider(sessionId).notifier).startSession()
                : null,
            child: const Text('Démarrer la dégustation'),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Participant view
// ---------------------------------------------------------------------------

class _ParticipantLobby extends StatelessWidget {
  const _ParticipantLobby({required this.lobby});

  final LobbyState lobby;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('En attente...'),
        actions: [
          _CodeChip(code: lobby.session.code),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Row(
                spacing: 16,
                children: [
                  SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          "En attente de l'hôte",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'La dégustation démarrera bientôt.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              '${lobby.participants.length} participant'
              '${lobby.participants.length > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: lobby.participants.length,
              itemBuilder: (context, index) =>
                  _ParticipantTile(participant: lobby.participants[index]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant, this.trailing});

  final Participant participant;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarColor = _avatarColor(participant.pseudo);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: CircleAvatar(
        backgroundColor: avatarColor.withValues(alpha: 0.2),
        child: Text(
          participant.pseudo[0].toUpperCase(),
          style: TextStyle(
            color: avatarColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(participant.pseudo),
      subtitle: participant.isHost
          ? Text(
              'Hôte',
              style: TextStyle(color: colorScheme.primary, fontSize: 12),
            )
          : null,
      trailing: trailing,
    );
  }
}

class _BeerTile extends StatelessWidget {
  const _BeerTile({required this.beer});

  final Beer beer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, labelColor) = switch (beer.status) {
      BeerStatus.pending => ('En attente', colorScheme.onSurfaceVariant),
      BeerStatus.voting => ('Vote en cours', colorScheme.primary),
      BeerStatus.revealed => ('Révélée', colorScheme.tertiary),
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: const CircleAvatar(child: Icon(Icons.sports_bar_outlined)),
      title: Text(beer.name ?? '—'),
      subtitle: beer.brewery != null
          ? Text(
              beer.brewery!,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          : null,
      trailing: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: labelColor),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: code));
        var showSnackBar = true;
        if (defaultTargetPlatform == TargetPlatform.android) {
          final info = await DeviceInfoPlugin().androidInfo;
          if (info.version.sdkInt >= 33) showSnackBar = false;
        }
        if (showSnackBar && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Code copié !')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Text(
              code,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Icon(
              Icons.copy_outlined,
              size: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
