import 'package:brewtaste/features/beer/presentation/screens/add_beer_screen.dart';
import 'package:brewtaste/features/results/presentation/screens/results_screen.dart';
import 'package:brewtaste/features/session/presentation/screens/create_session_screen.dart';
import 'package:brewtaste/features/session/presentation/screens/home_screen.dart';
import 'package:brewtaste/features/session/presentation/screens/join_session_screen.dart';
import 'package:brewtaste/features/session/presentation/screens/lobby_screen.dart';
import 'package:brewtaste/features/voting/presentation/screens/tasting_screen.dart';
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
      GoRoute(
        path: '/session/:id/lobby',
        builder: (context, state) => LobbyScreen(
          sessionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/session/:id/add-beer',
        builder: (context, state) => AddBeerScreen(
          sessionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/session/:id/voting',
        builder: (context, state) => TastingScreen(
          sessionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/session/:id/results',
        builder: (context, state) => ResultsScreen(
          sessionId: state.pathParameters['id']!,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}
