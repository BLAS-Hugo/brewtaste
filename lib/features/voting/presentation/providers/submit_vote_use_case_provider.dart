import 'package:brewtaste/features/voting/domain/use_cases/submit_vote_use_case.dart';
import 'package:brewtaste/features/voting/infra/vote_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'submit_vote_use_case_provider.g.dart';

@riverpod
SubmitVoteUseCase submitVoteUseCase(Ref ref) =>
    SubmitVoteUseCase(ref.watch(voteRepositoryProvider));
