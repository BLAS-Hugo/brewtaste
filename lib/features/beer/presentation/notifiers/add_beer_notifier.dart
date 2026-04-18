import 'package:brewtaste/features/beer/presentation/providers/add_beer_use_case_provider.dart';
import 'package:brewtaste/shared/domain/entities/beer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_beer_notifier.g.dart';

@riverpod
class AddBeerNotifier extends _$AddBeerNotifier {
  @override
  Future<Beer?> build() async => null;

  Future<void> submit({
    required String sessionId,
    required String name,
    required String brewery,
    String? style,
    String? hops,
    String? aromas,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(addBeerUseCaseProvider).call(
            sessionId: sessionId,
            name: name,
            brewery: brewery,
            style: style,
            hops: hops,
            aromas: aromas,
          ),
    );
  }
}
