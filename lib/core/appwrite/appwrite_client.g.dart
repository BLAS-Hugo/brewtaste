// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appwrite_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appwriteClient)
final appwriteClientProvider = AppwriteClientProvider._();

final class AppwriteClientProvider
    extends $FunctionalProvider<Client, Client, Client>
    with $Provider<Client> {
  AppwriteClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appwriteClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appwriteClientHash();

  @$internal
  @override
  $ProviderElement<Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Client create(Ref ref) {
    return appwriteClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Client>(value),
    );
  }
}

String _$appwriteClientHash() => r'0e03ca6454f99bb54a97713551c76a1a3bad56ef';

@ProviderFor(appwriteAccount)
final appwriteAccountProvider = AppwriteAccountProvider._();

final class AppwriteAccountProvider
    extends $FunctionalProvider<Account, Account, Account>
    with $Provider<Account> {
  AppwriteAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appwriteAccountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appwriteAccountHash();

  @$internal
  @override
  $ProviderElement<Account> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Account create(Ref ref) {
    return appwriteAccount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Account value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Account>(value),
    );
  }
}

String _$appwriteAccountHash() => r'862e00b55fb49394db1e410a8a96328d3e5261b6';

@ProviderFor(appwriteDatabases)
final appwriteDatabasesProvider = AppwriteDatabasesProvider._();

final class AppwriteDatabasesProvider
    extends $FunctionalProvider<Databases, Databases, Databases>
    with $Provider<Databases> {
  AppwriteDatabasesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appwriteDatabasesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appwriteDatabasesHash();

  @$internal
  @override
  $ProviderElement<Databases> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Databases create(Ref ref) {
    return appwriteDatabases(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Databases value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Databases>(value),
    );
  }
}

String _$appwriteDatabasesHash() => r'fd04a756b8481565eaad3266d71956a4cfe87416';

@ProviderFor(appwriteRealtime)
final appwriteRealtimeProvider = AppwriteRealtimeProvider._();

final class AppwriteRealtimeProvider
    extends $FunctionalProvider<Realtime, Realtime, Realtime>
    with $Provider<Realtime> {
  AppwriteRealtimeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appwriteRealtimeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appwriteRealtimeHash();

  @$internal
  @override
  $ProviderElement<Realtime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Realtime create(Ref ref) {
    return appwriteRealtime(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Realtime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Realtime>(value),
    );
  }
}

String _$appwriteRealtimeHash() => r'8d8b4c5c744b7b28934819f95e24dfd971ef1da8';
