import 'package:brewtaste/core/appwrite/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return MaterialApp(
      home: switch (auth) {
        AsyncData() => const Scaffold(
          body: Center(child: Text('BrewTaste')),
        ),
        AsyncError(:final error) => Scaffold(
          body: Center(child: Text('Auth error: $error')),
        ),
        _ => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      },
    );
  }
}
