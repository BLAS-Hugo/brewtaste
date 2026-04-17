import 'package:brewtaste/core/appwrite/appwrite_constants.dart';
import 'package:brewtaste/core/appwrite/auth_notifier.dart';
import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/core/router/app_router.dart';
import 'package:brewtaste/core/router/deep_link_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppwriteConstants.assertEnvironment();

  await SentryFlutter.init(
    (options) {
      options
        ..dsn = _sentryDsn
        ..tracesSampleRate = 0.3;
    },
    appRunner: () {
      FlutterError.onError = (details) {
        ErrorReporter.report(details.exception, details.stack);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        ErrorReporter.report(error, stack);
        return true;
      };
      runApp(SentryWidget(child: const ProviderScope(child: App())));
    },
  );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return switch (auth) {
      AsyncData() => const _RouterApp(),
      AsyncError() => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Unable to initialize. Please restart the app.'),
          ),
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

class _RouterApp extends ConsumerWidget {
  const _RouterApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(deepLinkHandlerProvider);
    return MaterialApp.router(
      theme: _buildTheme(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }

  ThemeData _buildTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFF5A623),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFF5A623),
      onPrimary: const Color(0xFF1A1410),
      surface: const Color(0xFF1A1410),
      surfaceContainerLow: const Color(0xFF221B12),
      surfaceContainer: const Color(0xFF2C2318),
      surfaceContainerHigh: const Color(0xFF3A2E20),
      onSurface: const Color(0xFFF5ECD7),
      onSurfaceVariant: const Color(0xFFBDA882),
      secondary: const Color(0xFFC47A1E),
      onSecondary: const Color(0xFF1A1410),
    );
    final textTheme =
        GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      colorScheme: scheme,
      textTheme: textTheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
    );
  }
}
