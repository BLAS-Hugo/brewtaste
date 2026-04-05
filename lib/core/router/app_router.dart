import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _PlaceholderScreen('Home'),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(name)),
    );
  }
}
