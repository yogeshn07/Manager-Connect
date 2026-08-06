import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/core/network/api_error_handler.dart';
import 'package:manager_connect/features/insights/data/models/insight_dto.dart';
import 'package:manager_connect/features/insights/data/models/insight_raw_dto.dart';
import 'package:manager_connect/features/insights/data/models/insight_review_dto.dart';
import 'package:manager_connect/features/insights/data/models/insight_source_dto.dart';
import 'package:manager_connect/features/insights/data/models/pipeline_health_dto.dart';

class InsightRepository {
  InsightRepository(this._client);

  final SupabaseClient _client;

  static const _pageSize = 20;

  // All columns visible to members via RLS (status='active' enforced server-side).
  static const _select =
      'id, raw_id, source_id, url_fingerprint, '
      'ai_headline, ai_summary, ai_why_matters, ai_key_takeaway, '
      'ai_tags, ai_confidence, source_name, source_url, article_date, '
      'reading_time_minutes, hero_image_url, category, is_ai_generated, '
      'status, scheduled_for, published_at, is_evergreen, '
      'reviewed_by, reviewed_at, created_at, updated_at';

  Future<List<InsightDto>> getFeed({
    String? category,
    int page = 0,
  }) async {
    try {
      var query = _client
          .from(Table.catalystInsights)
          .select(_select)
          .eq('status', 'active');

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query
          .order('published_at', ascending: false)
          .range(page * _pageSize, (page + 1) * _pageSize - 1);

      return (response as List).map((row) => InsightDto.fromJson(row as Map<String, dynamic>)).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<InsightDto> getInsight(String id) async {
    try {
      final response = await _client
          .from(Table.catalystInsights)
          .select(_select)
          .eq('id', id)
          .single();
      return InsightDto.fromJson(response);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // Returns all active sources from the allow-list, ordered by tier then name.
  Future<List<InsightSourceDto>> getAvailableSources() async {
    try {
      final response = await _client
          .from(Table.insightsSources)
          .select('id, name, approved_domain, tier')
          .eq('is_active', true)
          .order('tier')
          .order('name');
      return (response as List)
          .map((row) => InsightSourceDto.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // Submits a URL to the collect-insight pipeline. Admin only — RLS on
  // insights_sources permits INSERT only for authenticated admins.
  Future<Map<String, dynamic>> collectInsight({
    required String url,
    required String sourceId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'collect-insight',
        body: {'url': url, 'source_id': sourceId},
      );
      _checkEfResponse(response, 'collect insight');
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // ── Admin review workflow (review-insight Edge Function) ──────────────────

  // Returns all catalyst_insights in 'review' status, ordered by ai_confidence
  // descending so highest-confidence insights appear first.
  Future<List<InsightReviewDto>> getReviewQueue() async {
    try {
      final response = await _client.functions.invoke(
        'review-insight',
        body: {'action': 'list'},
      );
      _checkEfResponse(response, 'list review queue');
      final data = response.data as Map<String, dynamic>;
      final insights = data['insights'] as List<dynamic>;
      return insights
          .map((e) => InsightReviewDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // Transitions a catalyst_insight from 'review' → 'active' (published).
  // Sets published_at = now(), reviewed_by = caller's user ID.
  Future<void> approveInsight(String insightId) async {
    try {
      final response = await _client.functions.invoke(
        'review-insight',
        body: {'action': 'approve', 'insight_id': insightId},
      );
      _checkEfResponse(response, 'approve insight');
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // Transitions a catalyst_insight from 'review' → 'archived' (rejected).
  // Optional rejection_reason is persisted in the audit log for ops visibility.
  Future<void> rejectInsight(
    String insightId, {
    String? rejectionReason,
  }) async {
    try {
      final body = <String, dynamic>{
        'action': 'reject',
        'insight_id': insightId,
      };
      if (rejectionReason != null && rejectionReason.isNotEmpty) {
        body['rejection_reason'] = rejectionReason;
      }
      final response = await _client.functions.invoke(
        'review-insight',
        body: body,
      );
      _checkEfResponse(response, 'reject insight');
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // Returns raw pipeline records submitted by the given user, newest first.
  Future<List<InsightRawDto>> getSubmissionHistory(String userId) async {
    try {
      final response = await _client
          .from(Table.insightsRaw)
          .select(
            'id, source_id, raw_url, url_fingerprint, title_fingerprint, '
            'status, og_title, og_description, og_image_url, '
            'submitted_by, created_at, updated_at',
          )
          .eq('submitted_by', userId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => InsightRawDto.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // Returns the catalyst_insights id for a raw row that has been published,
  // or null if no active insight exists for that raw_id yet.
  Future<String?> getPublishedInsightId(String rawId) async {
    try {
      final response = await _client
          .from(Table.catalystInsights)
          .select('id')
          .eq('raw_id', rawId)
          .eq('status', 'active')
          .maybeSingle();
      return response?['id'] as String?;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // ── Pipeline health monitoring (admin, read-only via RLS SELECT) ─────────
  //
  // pipeline-health and pipeline-operations Edge Functions require service_role
  // auth and are not callable from the Flutter client. These methods replicate
  // the same metrics by querying insights_raw and catalyst_insights directly.
  // Admin RLS grants SELECT on both tables; UPDATE is blocked for all
  // authenticated users (insights_raw_update_blocked policy), so no retry
  // actions are possible from the Flutter client.

  Future<PipelineHealthDto> getPipelineHealth() async {
    try {
      final checkedAt = DateTime.now().toUtc();
      final staleThreshold =
          checkedAt.subtract(const Duration(minutes: 15));
      final since24h = checkedAt.subtract(const Duration(hours: 24));

      final rawResponse = await _client
          .from(Table.insightsRaw)
          .select('status, created_at, updated_at');
      final rawRows =
          (rawResponse as List).cast<Map<String, dynamic>>();

      final rawQueueByStatus = <String, int>{};
      var ingestedLast24h = 0;
      var failedCount = 0;
      var stalledCount = 0;

      for (final row in rawRows) {
        final status = row['status'] as String;
        rawQueueByStatus[status] =
            (rawQueueByStatus[status] ?? 0) + 1;
        final createdAt =
            DateTime.parse(row['created_at'] as String).toUtc();
        if (createdAt.isAfter(since24h)) ingestedLast24h++;
        if (status == 'ai_error') {
          failedCount++;
        } else if (status == 'validated') {
          final updatedAt =
              DateTime.parse(row['updated_at'] as String).toUtc();
          if (updatedAt.isBefore(staleThreshold)) stalledCount++;
        }
      }

      final ciResponse = await _client
          .from(Table.catalystInsights)
          .select('status, created_at, published_at');
      final ciRows =
          (ciResponse as List).cast<Map<String, dynamic>>();

      final catalystByStatus = <String, int>{};
      final latencySamples = <double>[];

      for (final row in ciRows) {
        final status = row['status'] as String;
        catalystByStatus[status] =
            (catalystByStatus[status] ?? 0) + 1;
        if (status == 'active' && latencySamples.length < 50) {
          final publishedAtStr = row['published_at'] as String?;
          if (publishedAtStr != null) {
            final createdAt =
                DateTime.parse(row['created_at'] as String);
            final publishedAt = DateTime.parse(publishedAtStr);
            latencySamples.add(
              publishedAt
                  .difference(createdAt)
                  .inMilliseconds
                  .toDouble(),
            );
          }
        }
      }

      final avgLatency = latencySamples.isEmpty
          ? null
          : latencySamples.reduce((a, b) => a + b) /
              latencySamples.length;

      return PipelineHealthDto(
        rawQueueByStatus: rawQueueByStatus,
        rawTotal: rawRows.length,
        catalystByStatus: catalystByStatus,
        catalystTotal: ciRows.length,
        failedEnrichmentCount: failedCount,
        stalledValidationCount: stalledCount,
        scheduledCount: catalystByStatus['scheduled'] ?? 0,
        archivedCount: catalystByStatus['archived'] ?? 0,
        ingestedLast24h: ingestedLast24h,
        avgTimeToPublishMs: avgLatency,
        latencySampleSize: latencySamples.length,
        checkedAt: checkedAt,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<PipelineJobDto>> listFailedJobs({int limit = 50}) async {
    try {
      final response = await _client
          .from(Table.insightsRaw)
          .select('id, raw_url, status, source_id, created_at, updated_at')
          .eq('status', 'ai_error')
          .order('updated_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((row) =>
              PipelineJobDto.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<PipelineJobDto>> listStalledJobs({int limit = 50}) async {
    try {
      final staleThreshold = DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 15))
          .toIso8601String();
      final response = await _client
          .from(Table.insightsRaw)
          .select('id, raw_url, status, source_id, created_at, updated_at')
          .eq('status', 'validated')
          .lt('updated_at', staleThreshold)
          .order('updated_at', ascending: true)
          .limit(limit);
      return (response as List)
          .map((row) =>
              PipelineJobDto.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  void _checkEfResponse(FunctionResponse response, String operation) {
    if (response.status >= 400) {
      final data = response.data;
      if (data is Map<String, dynamic> && data['error'] != null) {
        final error = data['error'] as Map<String, dynamic>;
        throw AppException(
          error['message'] as String? ?? 'Failed to $operation',
          response.status,
        );
      }
      throw AppException('Failed to $operation', response.status);
    }
  }
}
