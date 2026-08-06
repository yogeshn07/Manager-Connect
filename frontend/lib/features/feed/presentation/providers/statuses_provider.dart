import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/feed/data/models/post_dto.dart';
import 'package:manager_connect/features/feed/data/repositories/feed_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'statuses_provider.g.dart';

@riverpod
class StatusesNotifier extends _$StatusesNotifier {
  @override
  Future<List<StatusDto>> build() async {
    final client = ref.watch(supabaseClientProvider);
    return FeedRepository(client).getStatuses();
  }

  Future<void> addStatus({String? imageStoragePath, String? caption, required String userId}) async {
    final client = ref.read(supabaseClientProvider);
    final repo = FeedRepository(client);
    try {
      final status = await repo.createStatus(
        userId: userId,
        imageStoragePath: imageStoragePath,
        caption: caption,
      );
      final current = switch (state) {
        AsyncData(:final value) => value,
        _ => <StatusDto>[],
      };
      state = AsyncData([status, ...current]);
    } catch (_) {}
  }

  Future<void> removeStatus(String statusId) async {
    final client = ref.read(supabaseClientProvider);
    try {
      await FeedRepository(client).deleteStatus(statusId);
      final current = switch (state) {
        AsyncData(:final value) => value,
        _ => <StatusDto>[],
      };
      state = AsyncData(current.where((s) => s.id != statusId).toList());
    } catch (_) {}
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => FeedRepository(ref.read(supabaseClientProvider)).getStatuses(),
    );
  }
}
