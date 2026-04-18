import 'package:brewtaste/core/appwrite/appwrite_client.dart';
import 'package:brewtaste/features/beer/domain/repositories/beer_repository.dart';
import 'package:brewtaste/features/beer/infra/appwrite_beer_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'beer_repository_provider.g.dart';

@Riverpod(keepAlive: true)
BeerRepository beerRepository(Ref ref) => AppwriteBeerRepository(
      databases: ref.watch(appwriteDatabasesProvider),
      realtime: ref.watch(appwriteRealtimeProvider),
    );
