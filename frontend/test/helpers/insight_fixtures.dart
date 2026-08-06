import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/features/insights/data/models/insight_dto.dart';
import 'package:manager_connect/features/insights/data/models/insight_raw_dto.dart';
import 'package:manager_connect/features/insights/data/models/insight_review_dto.dart';
import 'package:manager_connect/features/insights/data/models/insight_source_dto.dart';
import 'package:manager_connect/features/insights/data/models/pipeline_health_dto.dart';

// ── InsightDto fixtures ───────────────────────────────────────────────────────

const kBaseInsightJson = <String, dynamic>{
  'id': 'ci-001',
  'raw_id': 'raw-001',
  'source_id': 'src-001',
  'url_fingerprint': 'abc123',
  'ai_headline': 'Grid modernisation accelerates in Southeast Asia',
  'ai_summary': 'Summary text',
  'ai_why_matters': 'Why it matters',
  'ai_key_takeaway': 'Key takeaway',
  'ai_tags': ['grid', 'southeast-asia'],
  'ai_confidence': 0.92,
  'source_name': 'Energy Monitor',
  'source_url': 'https://energymonitor.ai/article/1',
  'article_date': '2026-07-01',
  'reading_time_minutes': 5,
  'hero_image_url': 'https://example.com/img.jpg',
  'category': 'grid_technology',
  'is_ai_generated': true,
  'status': 'active',
  'scheduled_for': null,
  'published_at': '2026-07-02T10:00:00.000Z',
  'is_evergreen': false,
  'reviewed_by': 'user-admin-1',
  'reviewed_at': '2026-07-02T09:55:00.000Z',
  'created_at': '2026-06-30T08:00:00.000Z',
  'updated_at': '2026-07-02T10:00:00.000Z',
};

InsightDto makeInsightDto({
  String id = 'ci-001',
  String rawId = 'raw-001',
  String status = 'active',
  InsightCategory category = InsightCategory.gridTechnology,
  bool isEvergreen = false,
  String? aiHeadline = 'Grid modernisation accelerates in Southeast Asia',
}) =>
    InsightDto(
      id: id,
      rawId: rawId,
      sourceId: 'src-001',
      urlFingerprint: 'abc123',
      aiHeadline: aiHeadline,
      aiSummary: 'Summary text',
      aiWhyMatters: 'Why it matters',
      aiKeyTakeaway: 'Key takeaway',
      aiTags: const ['grid', 'southeast-asia'],
      aiConfidence: 0.92,
      sourceName: 'Energy Monitor',
      sourceUrl: 'https://energymonitor.ai/article/1',
      articleDate: '2026-07-01',
      readingTimeMinutes: 5,
      heroImageUrl: null,
      category: category,
      isAiGenerated: true,
      status: status,
      publishedAt: DateTime.parse('2026-07-02T10:00:00.000Z'),
      isEvergreen: isEvergreen,
      createdAt: DateTime.parse('2026-06-30T08:00:00.000Z'),
      updatedAt: DateTime.parse('2026-07-02T10:00:00.000Z'),
    );

InsightRawDto makeInsightRawDto({
  String id = 'raw-001',
  String status = 'pending',
  String rawUrl = 'https://energymonitor.ai/article/1',
}) =>
    InsightRawDto(
      id: id,
      sourceId: 'src-001',
      rawUrl: rawUrl,
      urlFingerprint: 'abc123',
      status: status,
      createdAt: DateTime.parse('2026-06-30T08:00:00.000Z'),
      updatedAt: DateTime.parse('2026-06-30T08:10:00.000Z'),
    );

const kBaseRawJson = <String, dynamic>{
  'id': 'raw-001',
  'source_id': 'src-001',
  'raw_url': 'https://energymonitor.ai/article/1',
  'url_fingerprint': 'abc123',
  'title_fingerprint': null,
  'status': 'pending',
  'og_title': null,
  'og_description': null,
  'og_image_url': null,
  'submitted_by': 'user-1',
  'created_at': '2026-06-30T08:00:00.000Z',
  'updated_at': '2026-06-30T08:10:00.000Z',
};

const kBaseSourceJson = <String, dynamic>{
  'id': 'src-001',
  'name': 'Energy Monitor',
  'approved_domain': 'energymonitor.ai',
  'tier': 1,
};

InsightSourceDto makeSourceDto({
  String id = 'src-001',
  String name = 'Energy Monitor',
  int tier = 1,
}) =>
    InsightSourceDto(
      id: id,
      name: name,
      approvedDomain: 'energymonitor.ai',
      tier: tier,
    );

const kBaseReviewJson = <String, dynamic>{
  'id': 'ci-001',
  'ai_headline': 'Grid modernisation accelerates',
  'ai_summary': 'Summary',
  'ai_why_matters': 'Why it matters',
  'ai_key_takeaway': 'Key takeaway',
  'ai_tags': ['grid'],
  'ai_confidence': 0.87,
  'category': 'energy_transition',
  'source_name': 'Energy Monitor',
  'source_url': 'https://energymonitor.ai/article/1',
  'article_date': '2026-07-01',
  'reading_time_minutes': 4,
  'hero_image_url': null,
  'is_evergreen': false,
  'created_at': '2026-06-30T08:00:00.000Z',
};

InsightReviewDto makeReviewDto({
  String id = 'ci-001',
  String category = 'grid_technology',
  bool isEvergreen = false,
  double? aiConfidence = 0.87,
}) =>
    InsightReviewDto(
      id: id,
      aiHeadline: 'Grid modernisation accelerates',
      aiSummary: 'Summary',
      category: category,
      isEvergreen: isEvergreen,
      aiConfidence: aiConfidence,
      createdAt: DateTime.parse('2026-06-30T08:00:00.000Z'),
    );

PipelineHealthDto makePipelineHealthDto({
  int failedEnrichmentCount = 0,
  int stalledValidationCount = 0,
  int ingestedLast24h = 10,
  double? avgTimeToPublishMs = 300000.0,
}) =>
    PipelineHealthDto(
      rawQueueByStatus: {'pending': 5, 'validated': 2, 'ai_error': failedEnrichmentCount},
      rawTotal: 7,
      catalystByStatus: const {'review': 3, 'active': 12},
      catalystTotal: 15,
      failedEnrichmentCount: failedEnrichmentCount,
      stalledValidationCount: stalledValidationCount,
      scheduledCount: 2,
      archivedCount: 4,
      ingestedLast24h: ingestedLast24h,
      avgTimeToPublishMs: avgTimeToPublishMs,
      latencySampleSize: 12,
      checkedAt: DateTime.parse('2026-07-18T12:00:00.000Z'),
    );

PipelineJobDto makePipelineJobDto({
  String id = 'raw-001',
  String status = 'ai_error',
  String rawUrl = 'https://energymonitor.ai/article/1',
}) =>
    PipelineJobDto(
      id: id,
      rawUrl: rawUrl,
      status: status,
      sourceId: 'src-001',
      createdAt: DateTime.parse('2026-07-18T10:00:00.000Z'),
      updatedAt: DateTime.parse('2026-07-18T10:30:00.000Z'),
    );

// ── Widget test helpers ───────────────────────────────────────────────────────

/// Wraps [child] in a bare [ProviderScope] + [MaterialApp].
/// For tests that need provider overrides, wrap with [ProviderScope] directly.
Widget buildTestWidget(Widget child) =>
    ProviderScope(child: MaterialApp(home: child));
