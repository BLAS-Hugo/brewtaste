import 'package:brewtaste/features/session/presentation/screens/create_session_screen.dart';
import 'package:brewtaste/features/session/presentation/screens/home_screen.dart';
import 'package:brewtaste/features/session/presentation/screens/join_session_screen.dart';
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
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/session/create',
        builder: (context, state) => const CreateSessionScreen(),
      ),
      GoRoute(
        path: '/session/join',
        builder: (context, state) => const JoinSessionScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}
