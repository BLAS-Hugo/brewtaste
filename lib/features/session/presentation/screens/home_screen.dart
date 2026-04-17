import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/session/create'),
              child: const Text('Créer une session'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push('/session/join'),
              child: const Text('Rejoindre une session'),
            ),
          ],
        ),
      ),
    );
  }
}
