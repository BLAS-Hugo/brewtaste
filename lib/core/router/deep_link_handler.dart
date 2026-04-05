import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:brewtaste/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_link_handler.g.dart';

@Riverpod(keepAlive: true)
DeepLinkHandler deepLinkHandler(Ref ref) {
  final router = ref.watch(appRouterProvider);
  final handler = DeepLinkHandler(router: router)
    ..init();
  ref.onDispose(handler.dispose);
  return handler;
}

class DeepLinkHandler {
  DeepLinkHandler({required this.router});

  final GoRouter router;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  void init() {
    _subscription = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri uri) {
    if (uri.scheme == 'brewtaste') {
      router.go('/${uri.host}${uri.path}');
    }
  }

  void dispose() => _subscription?.cancel();
}
