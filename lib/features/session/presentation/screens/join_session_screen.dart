import 'dart:async';

import 'package:brewtaste/features/session/domain/errors/session_errors.dart';
import 'package:brewtaste/features/session/presentation/notifiers/join_session_notifier.dart';
import 'package:brewtaste/features/session/presentation/screens/qr_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class JoinSessionScreen extends ConsumerStatefulWidget {
  const JoinSessionScreen({this.initialCode, super.key});

  final String? initialCode;

  @override
  ConsumerState<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends ConsumerState<JoinSessionScreen> {
  late final TextEditingController _codeController;
  final _pseudoController = TextEditingController();
  bool _codeEmpty = false;
  bool _pseudoEmpty = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCode ?? 'BREW-';
    _codeController = TextEditingController(text: initial);
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

  Future<void> _scanQr() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(builder: (_) => const QrScanScreen()),
    );
    if (code != null) {
      _codeController.text = code;
      _codeController.selection = TextSelection.collapsed(
        offset: code.length,
      );
    }
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
              prefixIcon: const Icon(Icons.tag_outlined),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner_outlined),
                tooltip: 'Scanner le QR code',
                onPressed: isLoading ? null : _scanQr,
              ),
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
          const SizedBox(height: 20),
          TextField(
            controller: _pseudoController,
            decoration: InputDecoration(
              labelText: 'Votre pseudo',
              errorText: _pseudoEmpty ? 'Requis' : null,
              prefixIcon: const Icon(Icons.person_outline),
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
