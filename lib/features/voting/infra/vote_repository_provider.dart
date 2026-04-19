import 'package:brewtaste/core/appwrite/appwrite_client.dart';
import 'package:brewtaste/features/voting/domain/repositories/vote_repository.dart';
import 'package:brewtaste/features/voting/infra/appwrite_vote_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vote_repository_provider.g.dart';

@Riverpod(keepAlive: true)
VoteRepository voteRepository(Ref ref) => AppwriteVoteRepository(
      databases: ref.watch(appwriteDatabasesProvider),
      realtime: ref.watch(appwriteRealtimeProvider),
    );
