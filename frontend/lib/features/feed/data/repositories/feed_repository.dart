import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' hide Bucket;
import 'package:manager_connect/core/constants/app_constants.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/core/network/api_error_handler.dart';
import 'package:manager_connect/features/feed/data/models/post_dto.dart';

class FeedRepository {
  FeedRepository(this._client);

  final SupabaseClient _client;

  static const _postSelect =
      'id, author_id, content, is_deleted, created_at, post_type, '
      'profiles!posts_author_id_fkey(full_name, avatar_url, is_system_account), '
      'post_reactions(count), '
      'comments(count), '
      'post_images(storage_path, display_order), '
      'polls!posts_poll_id_fkey(id, question, closes_at, is_closed, activity_id, '
      'poll_options(id, option_text, display_order, '
      'poll_votes(poll_option_id, user_id, '
      'profiles!poll_votes_user_id_fkey(full_name))))';

  List<PostDto> _parsePosts(List<dynamic> response, {bool isPinned = false}) {
    return response.map((raw) {
      final json = Map<String, dynamic>.from(raw as Map<String, dynamic>);
      final images = (json['post_images'] as List? ?? [])
        ..sort(
          (a, b) => ((a as Map)['display_order'] as int).compareTo(
            (b as Map)['display_order'] as int,
          ),
        );
      json['image_urls'] = images
          .map(
            (img) => _client.storage
                .from(Bucket.postImages)
                .getPublicUrl((img as Map)['storage_path'] as String),
          )
          .toList();
      return PostDto.fromJson(json, isPinned: isPinned);
    }).toList();
  }

  PostDto _parsePost(Map<String, dynamic> raw, {bool isPinned = false}) =>
      _parsePosts([raw], isPinned: isPinned).first;

  static const _commentSelect =
      'id, post_id, author_id, parent_comment_id, content, created_at, '
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

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return _parsePosts(response);
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
      return _parsePost(postData, isPinned: true);
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

      return _parsePost(response);
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
      await _client
          .from(Table.posts)
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', postId);
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
    String? parentCommentId,
  }) async {
    try {
      final response = await _client
          .from(Table.comments)
          .insert({
            'post_id': postId,
            'author_id': authorId,
            'content': content,
            if (parentCommentId != null) 'parent_comment_id': parentCommentId,
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
      await _client
          .from(Table.comments)
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', commentId);
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
      await _client.from(Table.postReactions).upsert({
        'post_id': postId,
        'user_id': userId,
        'emoji': emoji,
      }, onConflict: 'post_id,user_id');
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

  // --- Search ---

  Future<List<PostDto>> searchPosts(String query) async {
    try {
      final response = await _client
          .from(Table.posts)
          .select(_postSelect)
          .ilike('content', '%$query%')
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(20);
      return _parsePosts(response);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<Map<String, dynamic>>> searchProfiles(String query) async {
    try {
      final response = await _client
          .from(Table.profiles)
          .select('id, full_name, title, avatar_url')
          .ilike('full_name', '%$query%')
          .eq('is_active', true)
          .eq('is_system_account', false)
          .limit(10);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- Saved posts ---

  Future<Set<String>> getSavedPostIds(String userId) async {
    try {
      final response = await _client
          .from(Table.savedPosts)
          .select('post_id')
          .eq('user_id', userId);
      return {for (final r in (response as List)) r['post_id'] as String};
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<PostDto>> getSavedPosts(String userId) async {
    try {
      final response = await _client
          .from(Table.savedPosts)
          .select('saved_at, posts($_postSelect)')
          .eq('user_id', userId)
          .order('saved_at', ascending: false)
          .limit(40);
      return _parsePosts(
        (response as List)
            .where((r) => r['posts'] != null)
            .map((r) => r['posts'] as Map<String, dynamic>)
            .toList(),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> savePost({
    required String userId,
    required String postId,
  }) async {
    try {
      await _client.from(Table.savedPosts).upsert({
        'user_id': userId,
        'post_id': postId,
      }, onConflict: 'user_id,post_id');
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> unsavePost({
    required String userId,
    required String postId,
  }) async {
    try {
      await _client
          .from(Table.savedPosts)
          .delete()
          .eq('user_id', userId)
          .eq('post_id', postId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- Statuses ---

  static const _statusSelect =
      'id, user_id, image_url, caption, created_at, expires_at, '
      'profiles!statuses_user_id_fkey(full_name, avatar_url)';

  Future<List<StatusDto>> getStatuses() async {
    try {
      final response = await _client
          .from(Table.statuses)
          .select(_statusSelect)
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false);
      return response.map(StatusDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<StatusDto> createStatus({
    required String userId,
    String? imageStoragePath,
    String? caption,
  }) async {
    try {
      String? imageUrl;
      if (imageStoragePath != null) {
        imageUrl = _client.storage
            .from(Bucket.statuses)
            .getPublicUrl(imageStoragePath);
      }
      final response = await _client
          .from(Table.statuses)
          .insert({
            'user_id': userId,
            if (imageUrl != null) 'image_url': imageUrl,
            if (caption != null && caption.isNotEmpty) 'caption': caption,
          })
          .select(_statusSelect)
          .single();
      return StatusDto.fromJson(response);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  static String _mimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  Future<String> uploadPostImage({
    required String userId,
    required String filePath,
    required List<int> bytes,
  }) async {
    try {
      final ext = filePath.split('.').last.toLowerCase();
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage
          .from(Bucket.postImages)
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(
              contentType: _mimeType(filePath),
              upsert: false,
            ),
          );
      return path;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<String> uploadStatusImage({
    required String userId,
    required String filePath,
    required List<int> bytes,
  }) async {
    try {
      final ext = filePath.split('.').last.toLowerCase();
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage
          .from(Bucket.statuses)
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(
              contentType: _mimeType(filePath),
              upsert: false,
            ),
          );
      return path;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> deleteStatus(String statusId) async {
    try {
      await _client.from(Table.statuses).delete().eq('id', statusId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- Polls ---

  Future<void> createPollPost({
    required String userId,
    required String question,
    required List<String> options,
    required int closesInDays,
    String? activityId,
  }) async {
    try {
      // 1. Create poll record
      final pollRow = await _client
          .from(Table.polls)
          .insert({
            'created_by': userId,
            'question': question,
            'closes_at': DateTime.now()
                .add(Duration(days: closesInDays))
                .toUtc()
                .toIso8601String(),
            if (activityId != null) 'activity_id': activityId,
          })
          .select('id')
          .single();
      final pollId = pollRow['id'] as String;

      // 2. Create poll options
      await _client
          .from(Table.pollOptions)
          .insert(
            options
                .asMap()
                .entries
                .map(
                  (e) => {
                    'poll_id': pollId,
                    'option_text': e.value,
                    'display_order': e.key,
                  },
                )
                .toList(),
          );

      // 3. Create the linked post
      await _client.from(Table.posts).insert({
        'author_id': userId,
        'content': question,
        'post_type': 'poll',
        'poll_id': pollId,
      });
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> castVote({
    required String pollId,
    required String optionId,
    required String userId,
  }) async {
    try {
      await _client.from(Table.pollVotes).upsert({
        'poll_id': pollId,
        'poll_option_id': optionId,
        'user_id': userId,
      }, onConflict: 'poll_id,user_id');
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> deleteVote({
    required String pollId,
    required String userId,
  }) async {
    try {
      await _client
          .from(Table.pollVotes)
          .delete()
          .eq('poll_id', pollId)
          .eq('user_id', userId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  static const _pollSelect =
      'id, question, closes_at, is_closed, activity_id, '
      'poll_options(id, option_text, display_order, '
      'poll_votes(poll_option_id, user_id, '
      'profiles!poll_votes_user_id_fkey(full_name)))';

  Future<PollDto?> getActivityPoll(String activityId) async {
    try {
      final rows = await _client
          .from(Table.polls)
          .select(_pollSelect)
          .eq('activity_id', activityId)
          .order('created_at', ascending: false)
          .limit(1);
      if ((rows as List).isEmpty) return null;
      return PollDto.fromJson(rows.first);
    } catch (_) {
      return null;
    }
  }

  // --- Achievements (recognitions received by user) ---

  Future<List<Map<String, dynamic>>> getUserRecognitions(String userId) async {
    try {
      // Step 1: recognition ids where user is recipient
      final recipientRows = await _client
          .from(Table.recognitionRecipients)
          .select('recognition_id')
          .eq('recipient_id', userId);

      final ids = (recipientRows as List)
          .map((r) => r['recognition_id'] as String)
          .toList();

      if (ids.isEmpty) return [];

      // Step 2: fetch those recognitions with giver name
      final rows = await _client
          .from(Table.recognitions)
          .select(
            'id, category_tag, message, created_at, '
            'profiles!recognitions_giver_id_fkey(full_name)',
          )
          .inFilter('id', ids)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      return (rows as List).map((r) {
        final giver = r['profiles'];
        return {
          ...Map<String, dynamic>.from(r as Map),
          'giver_name': giver is Map ? giver['full_name'] as String? : null,
        };
      }).toList();
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
