import 'package:brewtaste/features/session/domain/errors/session_errors.dart';
import 'package:brewtaste/features/session/presentation/notifiers/join_session_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class JoinSessionScreen extends ConsumerStatefulWidget {
  const JoinSessionScreen({super.key});

  @override
  ConsumerState<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends ConsumerState<JoinSessionScreen> {
  final _codeController = TextEditingController(text: 'BREW-');
  final _pseudoController = TextEditingController();
  bool _codeEmpty = false;
  bool _pseudoEmpty = false;

  @override
  void initState() {
    super.initState();
    _codeController.selection = TextSelection.collapsed(
      offset: _codeController.text.length,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pseudoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    final pseudo = _pseudoController.text.trim();
    if (code.isEmpty || pseudo.isEmpty) {
      setState(() {
        _codeEmpty = code.isEmpty;
        _pseudoEmpty = pseudo.isEmpty;
      });
      return;
    }
    setState(() {
      _codeEmpty = false;
      _pseudoEmpty = false;
    });
    await ref.read(joinSessionProvider.notifier).submit(
          code: code,
          pseudo: pseudo,
        );
  }

  String _errorMessage(Object error) {
    if (error is SessionNotFoundException) return 'Code introuvable.';
    if (error is SessionRevealedException) {
      return 'Cette session est déjà terminée.';
    }
    if (error is SessionExpiredException) return 'Cette session a expiré.';
    return 'Une erreur inattendue est survenue.';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(joinSessionProvider, (_, next) {
      next.whenData((participant) {
        if (participant != null) {
          context.go('/session/${participant.sessionId}/lobby');
        }
      });
    });

    final state = ref.watch(joinSessionProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Rejoindre une session')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Code de session',
              hintText: 'BREW-XXXX',
              errorText: _codeEmpty ? 'Requis' : null,
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: (v) {
              if (_codeEmpty) setState(() => _codeEmpty = false);
              final upper = v.toUpperCase();
              if (v != upper) {
                _codeController.value = _codeController.value.copyWith(
                  text: upper,
                  selection: TextSelection.collapsed(offset: upper.length),
                );
              }
            },
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 32),
          FilledButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Rejoindre'),
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
