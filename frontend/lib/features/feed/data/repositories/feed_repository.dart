import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/app_constants.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/core/network/api_error_handler.dart';
import 'package:manager_connect/features/feed/data/models/post_dto.dart';

class FeedRepository {
  FeedRepository(this._client);

  final SupabaseClient _client;

  static const _postSelect =
      'id, author_id, content, is_deleted, created_at, '
      'profiles!posts_author_id_fkey(full_name, avatar_url, is_system_account)';

  static const _commentSelect =
      'id, post_id, author_id, content, created_at, '
      'profiles!comments_author_id_fkey(full_name, avatar_url, is_system_account)';

  // --- Feed ---

  Future<List<PostDto>> getFeed({
    DateTime? cursor,
    int limit = AppConstants.paginationPageSize,
  }) async {
    try {
      var query = _client
          .from(Table.posts)
          .select(_postSelect)
          .eq('is_deleted', false);

      if (cursor != null) {
        query = query.lt('created_at', cursor.toIso8601String());
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);
      return response.map(PostDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<PostDto?> getPinnedPost() async {
    try {
      final response = await _client
          .from(Table.pinnedAnnouncements)
          .select('post_id, posts($_postSelect)')
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      final postData = response['posts'] as Map<String, dynamic>?;
      if (postData == null) return null;
      return PostDto.fromJson(postData, isPinned: true);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- Post Detail ---

  Future<PostDto> getPost(String postId) async {
    try {
      final response = await _client
          .from(Table.posts)
          .select(_postSelect)
          .eq('id', postId)
          .single();

      return PostDto.fromJson(response);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- Create Post (Edge Function) ---

  Future<Map<String, dynamic>> createPost({
    required String content,
    List<String>? imageStoragePaths,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'create-post',
        body: {
          'content': content,
          if (imageStoragePaths != null && imageStoragePaths.isNotEmpty)
            'image_storage_paths': imageStoragePaths,
        },
      );
      if (response.status >= 400) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['error'] != null) {
          final error = data['error'] as Map<String, dynamic>;
          throw AppException(
            error['message'] as String? ?? 'Failed to create post',
            response.status,
          );
        }
        throw AppException('Failed to create post', response.status);
      }
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- Delete Post ---

  Future<void> deletePost(String postId) async {
    try {
      await _client.from(Table.posts).update({
        'is_deleted': true,
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', postId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- Comments ---

  Future<List<CommentDto>> getComments(String postId) async {
    try {
      final response = await _client
          .from(Table.comments)
          .select(_commentSelect)
          .eq('post_id', postId)
          .eq('is_deleted', false)
          .order('created_at');

      return response.map(CommentDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<CommentDto> createComment({
    required String postId,
    required String authorId,
    required String content,
  }) async {
    try {
      final response = await _client
          .from(Table.comments)
          .insert({
            'post_id': postId,
            'author_id': authorId,
            'content': content,
          })
          .select(_commentSelect)
          .single();

      return CommentDto.fromJson(response);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _client.from(Table.comments).update({
        'is_deleted': true,
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', commentId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- Reactions ---

  Future<List<ReactionDto>> getReactions(String postId) async {
    try {
      final response = await _client
          .from(Table.postReactions)
          .select('id, post_id, user_id, emoji')
          .eq('post_id', postId);

      return response.map(ReactionDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> upsertReaction({
    required String postId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await _client.from(Table.postReactions).upsert(
        {
          'post_id': postId,
          'user_id': userId,
          'emoji': emoji,
        },
        onConflict: 'post_id,user_id',
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> removeReaction({
    required String postId,
    required String userId,
  }) async {
    try {
      await _client
          .from(Table.postReactions)
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- Flag ---

  Future<void> flagContent({
    required String reporterId,
    required String contentType,
    required String contentId,
    String? reason,
  }) async {
    try {
      await _client.from(Table.flaggedContent).insert({
        'reporter_id': reporterId,
        'content_type': contentType,
        'content_id': contentId,
        if (reason != null) 'reason': reason,
      });
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
