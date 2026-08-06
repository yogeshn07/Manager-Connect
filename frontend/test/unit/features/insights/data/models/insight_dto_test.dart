import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/data/models/insight_dto.dart';

import '../../../../../helpers/insight_fixtures.dart';

void main() {
  // ── InsightCategory ───────────────────────────────────────────────────────

  group('InsightCategory.fromJson', () {
    test('maps all six known values', () {
      expect(InsightCategory.fromJson('grid_technology'), InsightCategory.gridTechnology);
      expect(InsightCategory.fromJson('energy_transition'), InsightCategory.energyTransition);
      expect(InsightCategory.fromJson('industry_standards'), InsightCategory.industryStandards);
      expect(InsightCategory.fromJson('engineering_leadership'), InsightCategory.engineeringLeadership);
      expect(InsightCategory.fromJson('policy_markets'), InsightCategory.policyMarkets);
      expect(InsightCategory.fromJson('innovation'), InsightCategory.innovation);
    });

    test('unknown value falls back to innovation', () {
      expect(InsightCategory.fromJson('unknown_value'), InsightCategory.innovation);
      expect(InsightCategory.fromJson(''), InsightCategory.innovation);
    });
  });

  group('InsightCategory.toJson', () {
    test('round-trips all six values', () {
      for (final cat in InsightCategory.values) {
        expect(InsightCategory.fromJson(cat.toJson()), cat);
      }
    });

    test('produces correct snake_case strings', () {
      expect(InsightCategory.gridTechnology.toJson(), 'grid_technology');
      expect(InsightCategory.energyTransition.toJson(), 'energy_transition');
      expect(InsightCategory.industryStandards.toJson(), 'industry_standards');
      expect(InsightCategory.engineeringLeadership.toJson(), 'engineering_leadership');
      expect(InsightCategory.policyMarkets.toJson(), 'policy_markets');
      expect(InsightCategory.innovation.toJson(), 'innovation');
    });
  });

  group('InsightCategory.displayLabel', () {
    test('returns human-readable label for each category', () {
      expect(InsightCategory.gridTechnology.displayLabel, 'Grid Technology');
      expect(InsightCategory.energyTransition.displayLabel, 'Energy Transition');
      expect(InsightCategory.industryStandards.displayLabel, 'Industry Standards');
      expect(InsightCategory.engineeringLeadership.displayLabel, 'Engineering Leadership');
      expect(InsightCategory.policyMarkets.displayLabel, 'Policy & Markets');
      expect(InsightCategory.innovation.displayLabel, 'Innovation');
    });
  });

  // ── InsightDto.fromJson ───────────────────────────────────────────────────

  group('InsightDto.fromJson', () {
    test('parses all fields from a fully-populated map', () {
      final dto = InsightDto.fromJson(kBaseInsightJson);

      expect(dto.id, 'ci-001');
      expect(dto.rawId, 'raw-001');
      expect(dto.sourceId, 'src-001');
      expect(dto.urlFingerprint, 'abc123');
      expect(dto.aiHeadline, 'Grid modernisation accelerates in Southeast Asia');
      expect(dto.aiSummary, 'Summary text');
      expect(dto.aiWhyMatters, 'Why it matters');
      expect(dto.aiKeyTakeaway, 'Key takeaway');
      expect(dto.aiTags, ['grid', 'southeast-asia']);
      expect(dto.aiConfidence, closeTo(0.92, 0.001));
      expect(dto.sourceName, 'Energy Monitor');
      expect(dto.sourceUrl, 'https://energymonitor.ai/article/1');
      expect(dto.articleDate, '2026-07-01');
      expect(dto.readingTimeMinutes, 5);
      expect(dto.heroImageUrl, 'https://example.com/img.jpg');
      expect(dto.category, InsightCategory.gridTechnology);
      expect(dto.isAiGenerated, isTrue);
      expect(dto.status, 'active');
      expect(dto.scheduledFor, isNull);
      expect(dto.publishedAt, DateTime.parse('2026-07-02T10:00:00.000Z'));
      expect(dto.isEvergreen, isFalse);
      expect(dto.reviewedBy, 'user-admin-1');
      expect(dto.reviewedAt, '2026-07-02T09:55:00.000Z');
      expect(dto.createdAt, DateTime.parse('2026-06-30T08:00:00.000Z'));
      expect(dto.updatedAt, DateTime.parse('2026-07-02T10:00:00.000Z'));
    });

    test('ai_tags null defaults to empty list', () {
      final json = Map<String, dynamic>.from(kBaseInsightJson)
        ..['ai_tags'] = null;
      final dto = InsightDto.fromJson(json);
      expect(dto.aiTags, isEmpty);
    });

    test('is_ai_generated null defaults to true', () {
      final json = Map<String, dynamic>.from(kBaseInsightJson)
        ..['is_ai_generated'] = null;
      final dto = InsightDto.fromJson(json);
      expect(dto.isAiGenerated, isTrue);
    });

    test('is_evergreen null defaults to false', () {
      final json = Map<String, dynamic>.from(kBaseInsightJson)
        ..['is_evergreen'] = null;
      final dto = InsightDto.fromJson(json);
      expect(dto.isEvergreen, isFalse);
    });

    test('nullable text fields parse to null', () {
      final json = Map<String, dynamic>.from(kBaseInsightJson)
        ..['ai_headline'] = null
        ..['ai_summary'] = null
        ..['ai_why_matters'] = null
        ..['ai_key_takeaway'] = null
        ..['hero_image_url'] = null
        ..['published_at'] = null
        ..['reviewed_by'] = null
        ..['reviewed_at'] = null;
      final dto = InsightDto.fromJson(json);
      expect(dto.aiHeadline, isNull);
      expect(dto.aiSummary, isNull);
      expect(dto.aiWhyMatters, isNull);
      expect(dto.aiKeyTakeaway, isNull);
      expect(dto.heroImageUrl, isNull);
      expect(dto.publishedAt, isNull);
      expect(dto.reviewedBy, isNull);
      expect(dto.reviewedAt, isNull);
    });

    test('scheduled_for parses to DateTime when present', () {
      final json = Map<String, dynamic>.from(kBaseInsightJson)
        ..['scheduled_for'] = '2026-08-01T09:00:00.000Z';
      final dto = InsightDto.fromJson(json);
      expect(dto.scheduledFor, DateTime.parse('2026-08-01T09:00:00.000Z'));
    });

    test('ai_confidence coerces int to double', () {
      final json = Map<String, dynamic>.from(kBaseInsightJson)
        ..['ai_confidence'] = 1;
      final dto = InsightDto.fromJson(json);
      expect(dto.aiConfidence, 1.0);
      expect(dto.aiConfidence, isA<double>());
    });
  });
}
