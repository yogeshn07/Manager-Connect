import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/data/models/pipeline_health_dto.dart';

void main() {
  group('PipelineJobDto.fromJson', () {
    const json = <String, dynamic>{
      'id': 'raw-007',
      'raw_url': 'https://energymonitor.ai/article/7',
      'status': 'ai_error',
      'source_id': 'src-002',
      'created_at': '2026-07-18T08:00:00.000Z',
      'updated_at': '2026-07-18T08:45:00.000Z',
    };

    test('parses all fields', () {
      final dto = PipelineJobDto.fromJson(json);

      expect(dto.id, 'raw-007');
      expect(dto.rawUrl, 'https://energymonitor.ai/article/7');
      expect(dto.status, 'ai_error');
      expect(dto.sourceId, 'src-002');
      expect(dto.createdAt, DateTime.parse('2026-07-18T08:00:00.000Z'));
      expect(dto.updatedAt, DateTime.parse('2026-07-18T08:45:00.000Z'));
    });

    test('parses validated status for stalled jobs', () {
      final dto = PipelineJobDto.fromJson({
        ...json,
        'status': 'validated',
      });
      expect(dto.status, 'validated');
    });
  });

  group('PipelineHealthDto construction', () {
    test('stores all fields', () {
      final checkedAt = DateTime.parse('2026-07-18T12:00:00.000Z');
      final dto = PipelineHealthDto(
        rawQueueByStatus: const {'pending': 3, 'ai_error': 1},
        rawTotal: 4,
        catalystByStatus: const {'review': 2, 'active': 10},
        catalystTotal: 12,
        failedEnrichmentCount: 1,
        stalledValidationCount: 0,
        scheduledCount: 1,
        archivedCount: 3,
        ingestedLast24h: 8,
        avgTimeToPublishMs: 250000.0,
        latencySampleSize: 8,
        checkedAt: checkedAt,
      );

      expect(dto.rawTotal, 4);
      expect(dto.catalystTotal, 12);
      expect(dto.failedEnrichmentCount, 1);
      expect(dto.stalledValidationCount, 0);
      expect(dto.ingestedLast24h, 8);
      expect(dto.avgTimeToPublishMs, 250000.0);
      expect(dto.latencySampleSize, 8);
      expect(dto.checkedAt, checkedAt);
      expect(dto.rawQueueByStatus['pending'], 3);
      expect(dto.catalystByStatus['active'], 10);
    });

    test('avgTimeToPublishMs can be null', () {
      final dto = PipelineHealthDto(
        rawQueueByStatus: const {},
        rawTotal: 0,
        catalystByStatus: const {},
        catalystTotal: 0,
        failedEnrichmentCount: 0,
        stalledValidationCount: 0,
        scheduledCount: 0,
        archivedCount: 0,
        ingestedLast24h: 0,
        avgTimeToPublishMs: null,
        latencySampleSize: 0,
        checkedAt: DateTime.now(),
      );
      expect(dto.avgTimeToPublishMs, isNull);
    });
  });
}
