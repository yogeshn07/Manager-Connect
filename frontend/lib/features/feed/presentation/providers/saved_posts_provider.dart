import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/feed/data/repositories/feed_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'saved_posts_provider.g.dart';

@riverpod
class SavedPostsNotifier extends _$SavedPostsNotifier {
  @override
  Future<Set<String>> build() async {
    final auth = ref.watch(authProvider);
    if (auth is! AppAuthStateAuthenticated) return {};
    final client = ref.watch(supabaseClientProvider);
    return FeedRepository(client).getSavedPostIds(auth.session.userId);
  }

  Future<void> toggle(String postId) async {
    final auth = ref.read(authProvider);
    if (auth is! AppAuthStateAuthenticated) return;
    final userId = auth.session.userId;
    final client = ref.read(supabaseClientProvider);
    final repo = FeedRepository(client);
    final saved = switch (state) {
      AsyncData(:final value) => value,
      _ => <String>{},
    };
    try {
      if (saved.contains(postId)) {
        await repo.unsavePost(userId: userId, postId: postId);
        state = AsyncData({...saved}..remove(postId));
      } else {
        await repo.savePost(userId: userId, postId: postId);
        state = AsyncData({...saved, postId});
      }
    } catch (_) {}
  }
}
