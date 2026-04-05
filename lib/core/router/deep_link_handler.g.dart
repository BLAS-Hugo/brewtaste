// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deep_link_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deepLinkHandler)
final deepLinkHandlerProvider = DeepLinkHandlerProvider._();

final class DeepLinkHandlerProvider
    extends
        $FunctionalProvider<DeepLinkHandler, DeepLinkHandler, DeepLinkHandler>
    with $Provider<DeepLinkHandler> {
  DeepLinkHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deepLinkHandlerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deepLinkHandlerHash();

  @$internal
  @override
  $ProviderElement<DeepLinkHandler> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeepLinkHandler create(Ref ref) {
    return deepLinkHandler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeepLinkHandler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeepLinkHandler>(value),
    );
  }
}

String _$deepLinkHandlerHash() => r'e377d19d27f414a5c0e4adfd57e12a98491eb7e4';
