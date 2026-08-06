import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/data/models/insight_source_dto.dart';

import '../../../../../helpers/insight_fixtures.dart';

void main() {
  group('InsightSourceDto.fromJson', () {
    test('parses all fields', () {
      final dto = InsightSourceDto.fromJson(kBaseSourceJson);

      expect(dto.id, 'src-001');
      expect(dto.name, 'Energy Monitor');
      expect(dto.approvedDomain, 'energymonitor.ai');
      expect(dto.tier, 1);
    });
  });

  group('InsightSourceDto.tierLabel', () {
    test('tier 1 is Premier', () {
      expect(makeSourceDto(tier: 1).tierLabel, 'Premier');
    });

    test('tier 2 is Validated', () {
      expect(makeSourceDto(tier: 2).tierLabel, 'Validated');
    });

    test('tier 3 is Trade', () {
      expect(makeSourceDto(tier: 3).tierLabel, 'Trade');
    });

    test('tier values above 3 fall back to Trade', () {
      expect(makeSourceDto(tier: 99).tierLabel, 'Trade');
    });
  });
}
