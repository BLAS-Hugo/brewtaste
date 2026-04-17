import 'package:brewtaste/features/session/presentation/notifiers/lobby_notifier.dart';
import 'package:brewtaste/shared/domain/entities/participant.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(lobbyProvider(sessionId), (prev, next) {
      next.whenData((state) {
        // Host started session → everyone moves to voting
        if (state.session.status == SessionStatus.tasting) {
          context.go('/session/$sessionId/voting');
          return;
        }
        // Participant was kicked → back to home
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
    final cs = Theme.of(context).colorScheme;
    final canStart = lobby.participants.length >= 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon'),
        actions: [
          _CodeChip(code: lobby.session.code),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: QrImageView(
              data: 'brewtaste://join/${lobby.session.code}',
              size: 160,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: cs.onSurface,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: cs.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${lobby.participants.length} participant'
                  '${lobby.participants.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: lobby.participants.length,
              itemBuilder: (context, i) {
                final p = lobby.participants[i];
                return _ParticipantTile(
                  participant: p,
                  trailing: p.isHost
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.person_remove_outlined),
                          color: cs.error,
                          tooltip: 'Exclure',
                          onPressed: () => ref
                              .read(lobbyProvider(sessionId).notifier)
                              .kick(
                                participantId: p.id,
                                kickedUserId: p.userId,
                              ),
                        ),
                );
              },
            ),
          ),
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('En attente...'),
        actions: [
          _CodeChip(code: lobby.session.code),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          CircularProgressIndicator(color: cs.primary),
          const SizedBox(height: 16),
          Text(
            "En attente du lancement par l'hôte",
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${lobby.participants.length} participant'
                  '${lobby.participants.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: lobby.participants.length,
              itemBuilder: (context, i) =>
                  _ParticipantTile(participant: lobby.participants[i]),
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
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: cs.surfaceContainerHigh,
        child: Text(
          participant.pseudo[0].toUpperCase(),
          style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(participant.pseudo),
      subtitle: participant.isHost
          ? Text('Hôte',
              style: TextStyle(color: cs.primary, fontSize: 12))
          : null,
      trailing: trailing,
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: code));
        // Android 13+ (API 33) shows its own clipboard toast — skip ours.
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.copy_outlined, size: 13, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
