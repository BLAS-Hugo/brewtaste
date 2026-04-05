import 'package:brewtaste/core/appwrite/auth_notifier.dart';
import 'package:brewtaste/core/router/app_router.dart';
import 'package:brewtaste/core/router/deep_link_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SentryFlutter.init(
    (options) {
      options
        ..dsn = _sentryDsn
        ..tracesSampleRate = 0.3;
    },
    appRunner: () => runApp(
      SentryWidget(child: const ProviderScope(child: App())),
    ),
  );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return switch (auth) {
      AsyncData() => _RouterApp(ref: ref),
      AsyncError(:final error) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Auth error: $error')),
        ),
      ),
      _ => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
    };
  }
}

class _RouterApp extends StatelessWidget {
  const _RouterApp({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    ref.watch(deepLinkHandlerProvider);
    return MaterialApp.router(
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
