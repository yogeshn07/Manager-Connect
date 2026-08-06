import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/data/models/insight_dto.dart';
import 'package:manager_connect/features/insights/data/models/insight_review_dto.dart';

import '../../../../../helpers/insight_fixtures.dart';

void main() {
  group('InsightReviewDto.fromJson', () {
    test('parses all fields', () {
      final dto = InsightReviewDto.fromJson(kBaseReviewJson);

      expect(dto.id, 'ci-001');
      expect(dto.aiHeadline, 'Grid modernisation accelerates');
      expect(dto.aiSummary, 'Summary');
      expect(dto.aiWhyMatters, 'Why it matters');
      expect(dto.aiKeyTakeaway, 'Key takeaway');
      expect(dto.aiTags, ['grid']);
      expect(dto.aiConfidence, closeTo(0.87, 0.001));
      expect(dto.category, 'energy_transition');
      expect(dto.sourceName, 'Energy Monitor');
      expect(dto.sourceUrl, 'https://energymonitor.ai/article/1');
      expect(dto.articleDate, '2026-07-01');
      expect(dto.readingTimeMinutes, 4);
      expect(dto.heroImageUrl, isNull);
      expect(dto.isEvergreen, isFalse);
      expect(dto.createdAt, DateTime.parse('2026-06-30T08:00:00.000Z'));
    });

    test('ai_tags null defaults to empty list', () {
      final json = Map<String, dynamic>.from(kBaseReviewJson)..['ai_tags'] = null;
      expect(InsightReviewDto.fromJson(json).aiTags, isEmpty);
    });

    test('is_evergreen null defaults to false', () {
      final json = Map<String, dynamic>.from(kBaseReviewJson)..['is_evergreen'] = null;
      expect(InsightReviewDto.fromJson(json).isEvergreen, isFalse);
    });

    test('ai_confidence null is preserved as null', () {
      final json = Map<String, dynamic>.from(kBaseReviewJson)..['ai_confidence'] = null;
      expect(InsightReviewDto.fromJson(json).aiConfidence, isNull);
    });

    test('nullable text fields parse to null', () {
      final json = Map<String, dynamic>.from(kBaseReviewJson)
        ..['ai_headline'] = null
        ..['source_name'] = null
        ..['source_url'] = null
        ..['article_date'] = null
        ..['reading_time_minutes'] = null;
      final dto = InsightReviewDto.fromJson(json);
      expect(dto.aiHeadline, isNull);
      expect(dto.sourceName, isNull);
      expect(dto.sourceUrl, isNull);
      expect(dto.articleDate, isNull);
      expect(dto.readingTimeMinutes, isNull);
    });
  });

  group('InsightReviewDto.insightCategory', () {
    test('delegates to InsightCategory.fromJson', () {
      final dto = makeReviewDto(category: 'energy_transition');
      expect(dto.insightCategory, InsightCategory.energyTransition);
    });

    test('maps all six categories correctly', () {
      const pairs = {
        'grid_technology': InsightCategory.gridTechnology,
        'energy_transition': InsightCategory.energyTransition,
        'industry_standards': InsightCategory.industryStandards,
        'engineering_leadership': InsightCategory.engineeringLeadership,
        'policy_markets': InsightCategory.policyMarkets,
        'innovation': InsightCategory.innovation,
      };
      for (final entry in pairs.entries) {
        expect(makeReviewDto(category: entry.key).insightCategory, entry.value);
      }
    });
  });
}
