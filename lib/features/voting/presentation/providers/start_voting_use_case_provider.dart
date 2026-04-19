import 'package:brewtaste/features/beer/domain/use_cases/start_voting_use_case.dart';
import 'package:brewtaste/features/beer/infra/beer_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'start_voting_use_case_provider.g.dart';

@riverpod
StartVotingUseCase startVotingUseCase(Ref ref) =>
    StartVotingUseCase(ref.watch(beerRepositoryProvider));
