import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/data/models/insight_raw_dto.dart';

import '../../../../../helpers/insight_fixtures.dart';

void main() {
  group('InsightRawDto.fromJson', () {
    test('parses all fields', () {
      final dto = InsightRawDto.fromJson(kBaseRawJson);

      expect(dto.id, 'raw-001');
      expect(dto.sourceId, 'src-001');
      expect(dto.rawUrl, 'https://energymonitor.ai/article/1');
      expect(dto.urlFingerprint, 'abc123');
      expect(dto.titleFingerprint, isNull);
      expect(dto.status, 'pending');
      expect(dto.ogTitle, isNull);
      expect(dto.ogDescription, isNull);
      expect(dto.ogImageUrl, isNull);
      expect(dto.submittedBy, 'user-1');
      expect(dto.createdAt, DateTime.parse('2026-06-30T08:00:00.000Z'));
      expect(dto.updatedAt, DateTime.parse('2026-06-30T08:10:00.000Z'));
    });

    test('parses optional OG fields when present', () {
      final json = Map<String, dynamic>.from(kBaseRawJson)
        ..['og_title'] = 'Grid article title'
        ..['og_description'] = 'Some description'
        ..['og_image_url'] = 'https://example.com/img.jpg'
        ..['title_fingerprint'] = 'tfp123';
      final dto = InsightRawDto.fromJson(json);

      expect(dto.ogTitle, 'Grid article title');
      expect(dto.ogDescription, 'Some description');
      expect(dto.ogImageUrl, 'https://example.com/img.jpg');
      expect(dto.titleFingerprint, 'tfp123');
    });

    test('submittedBy is null when absent', () {
      final json = Map<String, dynamic>.from(kBaseRawJson)
        ..['submitted_by'] = null;
      final dto = InsightRawDto.fromJson(json);
      expect(dto.submittedBy, isNull);
    });

    test('parses all pipeline statuses', () {
      const statuses = [
        'pending', 'validated', 'duplicate', 'rejected',
        'ai_processed', 'review', 'scheduled', 'active', 'archived', 'ai_error',
      ];
      for (final status in statuses) {
        final json = Map<String, dynamic>.from(kBaseRawJson)..['status'] = status;
        expect(InsightRawDto.fromJson(json).status, status);
      }
    });
  });
}
