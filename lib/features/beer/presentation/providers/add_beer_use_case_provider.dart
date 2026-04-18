import 'package:brewtaste/features/beer/domain/use_cases/add_beer_use_case.dart';
import 'package:brewtaste/features/beer/infra/beer_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_beer_use_case_provider.g.dart';

@riverpod
AddBeerUseCase addBeerUseCase(Ref ref) =>
    AddBeerUseCase(ref.watch(beerRepositoryProvider));
