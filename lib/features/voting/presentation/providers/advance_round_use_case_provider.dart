import 'package:brewtaste/features/beer/infra/beer_repository_provider.dart';
import 'package:brewtaste/features/session/infra/session_repository_provider.dart';
import 'package:brewtaste/features/voting/domain/use_cases/advance_round_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'advance_round_use_case_provider.g.dart';

@riverpod
AdvanceRoundUseCase advanceRoundUseCase(Ref ref) => AdvanceRoundUseCase(
      ref.watch(beerRepositoryProvider),
      ref.watch(sessionRepositoryProvider),
    );
