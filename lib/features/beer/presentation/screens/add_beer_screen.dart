import 'package:brewtaste/features/beer/presentation/notifiers/add_beer_notifier.dart';
import 'package:brewtaste/features/beer/presentation/screens/barcode_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddBeerScreen extends ConsumerStatefulWidget {
  const AddBeerScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<AddBeerScreen> createState() => _AddBeerScreenState();
}

class _AddBeerScreenState extends ConsumerState<AddBeerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breweryController = TextEditingController();
  final _styleController = TextEditingController();
  final _hopsController = TextEditingController();
  final _aromasController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _breweryController.dispose();
    _styleController.dispose();
    _hopsController.dispose();
    _aromasController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.of(context).push<ScannedBeer>(
      MaterialPageRoute<ScannedBeer>(
        builder: (_) => const BarcodeScanScreen(),
      ),
    );

    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit introuvable, remplissez manuellement'),
          ),
        );
      }
      return;
    }

    _nameController.text = result.name;
    _breweryController.text = result.brewery;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(addBeerProvider.notifier).submit(
          sessionId: widget.sessionId,
          name: _nameController.text,
          brewery: _breweryController.text,
          style: _styleController.text.trim().isEmpty
              ? null
              : _styleController.text,
          hops: _hopsController.text.trim().isEmpty
              ? null
              : _hopsController.text,
          aromas: _aromasController.text.trim().isEmpty
              ? null
              : _aromasController.text,
        );

    final notifierState = ref.read(addBeerProvider);
    if (notifierState.hasValue && !notifierState.hasError && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifierState = ref.watch(addBeerProvider);
    final isLoading = notifierState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une bière'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            tooltip: 'Scanner un code-barres',
            onPressed: isLoading ? null : _scanBarcode,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom *'),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _breweryController,
              decoration: const InputDecoration(labelText: 'Brasserie *'),
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 24),
            Text(
              'Informations optionnelles',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _styleController,
              decoration: const InputDecoration(labelText: 'Style'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hopsController,
              decoration: const InputDecoration(labelText: 'Houblon'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aromasController,
              decoration: const InputDecoration(labelText: 'Arômes'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),
            if (notifierState.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Une erreur est survenue. Réessayez.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
