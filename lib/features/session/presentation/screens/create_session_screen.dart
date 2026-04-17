import 'package:brewtaste/features/session/domain/errors/session_errors.dart';
import 'package:brewtaste/features/session/presentation/notifiers/create_session_notifier.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateSessionScreen extends ConsumerStatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  ConsumerState<CreateSessionScreen> createState() =>
      _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  final _pseudoController = TextEditingController();
  bool _isBlind = false;
  final _guessFields = <GuessField>{};
  bool _pseudoEmpty = false;

  @override
  void dispose() {
    _pseudoController.dispose();
    super.dispose();
  }

  void _toggleGuessField(GuessField field) {
    setState(() {
      if (_guessFields.contains(field)) {
        _guessFields.remove(field);
      } else {
        _guessFields.add(field);
      }
    });
  }

  void _onBlindChanged(bool value) {
    setState(() {
      _isBlind = value;
      if (!value) _guessFields.remove(GuessField.brewery);
    });
  }

  Future<void> _submit() async {
    final pseudo = _pseudoController.text.trim();
    if (pseudo.isEmpty) {
      setState(() => _pseudoEmpty = true);
      return;
    }
    setState(() => _pseudoEmpty = false);
    await ref.read(createSessionProvider.notifier).submit(
          pseudo: pseudo,
          isBlind: _isBlind,
          guessFields: _guessFields.toList(),
        );
  }

  String _errorMessage(Object error) {
    if (error is SessionCodeCollisionException) {
      return 'Impossible de générer un code unique, réessayez.';
    }
    return 'Une erreur inattendue est survenue.';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createSessionProvider, (_, next) {
      next.whenData((session) {
        if (session != null) context.go('/session/${session.id}/lobby');
      });
    });

    final state = ref.watch(createSessionProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle session')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _pseudoController,
            decoration: InputDecoration(
              labelText: 'Votre pseudo',
              errorText: _pseudoEmpty ? 'Requis' : null,
            ),
            textCapitalization: TextCapitalization.words,
            enabled: !isLoading,
            onChanged: (_) {
              if (_pseudoEmpty) setState(() => _pseudoEmpty = false);
            },
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Mode aveugle'),
            subtitle: const Text('Masque le nom et la brasserie'),
            value: _isBlind,
            onChanged: isLoading ? null : _onBlindChanged,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          const Text('Champs à deviner'),
          _GuessFieldTile(
            label: 'Style',
            checked: _guessFields.contains(GuessField.style),
            onTap: isLoading ? null : () => _toggleGuessField(GuessField.style),
          ),
          _GuessFieldTile(
            label: 'Brasserie',
            checked: _guessFields.contains(GuessField.brewery),
            enabled: _isBlind,
            onTap: isLoading
                ? null
                : () => _toggleGuessField(GuessField.brewery),
          ),
          _GuessFieldTile(
            label: 'Houblon',
            checked: _guessFields.contains(GuessField.hops),
            onTap: isLoading ? null : () => _toggleGuessField(GuessField.hops),
          ),
          _GuessFieldTile(
            label: 'Arômes',
            checked: _guessFields.contains(GuessField.aromas),
            onTap: isLoading
                ? null
                : () => _toggleGuessField(GuessField.aromas),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Créer'),
          ),
          if (state.hasError) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage(state.error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _GuessFieldTile extends StatelessWidget {
  const _GuessFieldTile({
    required this.label,
    required this.checked,
    this.enabled = true,
    this.onTap,
  });

  final String label;
  final bool checked;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(label),
      value: checked,
      onChanged: (enabled && onTap != null) ? (_) => onTap!() : null,
      contentPadding: EdgeInsets.zero,
    );
  }
}
