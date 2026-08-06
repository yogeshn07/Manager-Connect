import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/presentation/providers/pipeline_health_provider.dart';
import 'package:manager_connect/features/insights/presentation/screens/pipeline_health_screen.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';

import '../../../helpers/insight_fixtures.dart';

// ── Stub notifier ─────────────────────────────────────────────────────────────

class _StubPipelineHealthNotifier extends PipelineHealthNotifier {
  _StubPipelineHealthNotifier(this._state);
  final PipelineHealthState _state;

  @override
  PipelineHealthState build() => _state;

  @override
  Future<void> load() async {}

  @override
  Future<void> refresh() async {}
}

Widget _buildScreen(PipelineHealthState state) => ProviderScope(
      overrides: [
        pipelineHealthProvider.overrideWith(
          () => _StubPipelineHealthNotifier(state),
        ),
      ],
      child: const MaterialApp(home: PipelineHealthScreen()),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('shows LoadingState on initial load', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const PipelineHealthState(isLoading: true),
    ));
    await tester.pump();

    expect(find.byType(LoadingState), findsOneWidget);
  });

  testWidgets('shows ErrorState when error and no health data', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const PipelineHealthState(error: 'RLS denied'),
    ));
    await tester.pump();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('ErrorState has retry button', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const PipelineHealthState(error: 'RLS denied'),
    ));
    await tester.pump();

    expect(find.text('Try Again'), findsOneWidget);
  });

  testWidgets('renders Pipeline Health title in top bar', (tester) async {
    await tester.pumpWidget(_buildScreen(
      PipelineHealthState(health: makePipelineHealthDto()),
    ));
    await tester.pump();

    expect(find.text('Pipeline Health'), findsOneWidget);
  });

  testWidgets('shows HEALTH SIGNALS section header when data loaded', (tester) async {
    await tester.pumpWidget(_buildScreen(
      PipelineHealthState(health: makePipelineHealthDto()),
    ));
    await tester.pump();

    expect(find.text('HEALTH SIGNALS'), findsOneWidget);
  });

  testWidgets('health signals grid renders stat labels when data loaded', (tester) async {
    // The signals grid (top-most section) is always visible —
    // checks that 'Failed', 'Stalled', 'Ingested (24h)' labels are rendered.
    await tester.pumpWidget(_buildScreen(
      PipelineHealthState(health: makePipelineHealthDto()),
    ));
    await tester.pump();

    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Stalled'), findsOneWidget);
    expect(find.text('Ingested (24h)'), findsOneWidget);
  });

  testWidgets('health signals show non-zero failed count when jobs are failing',
      (tester) async {
    final failedJobs = [
      makePipelineJobDto(id: 'raw-001', status: 'ai_error'),
      makePipelineJobDto(id: 'raw-002', status: 'ai_error'),
    ];
    await tester.pumpWidget(_buildScreen(
      PipelineHealthState(
        health: makePipelineHealthDto(failedEnrichmentCount: 2),
        failedJobs: failedJobs,
      ),
    ));
    await tester.pump();

    // failedEnrichmentCount = 2 → signal chip shows '2'
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('health signals show non-zero stalled count when jobs are stalled',
      (tester) async {
    final stalledJobs = [makePipelineJobDto(status: 'validated')];
    await tester.pumpWidget(_buildScreen(
      PipelineHealthState(
        health: makePipelineHealthDto(stalledValidationCount: 1),
        stalledJobs: stalledJobs,
      ),
    ));
    await tester.pump();

    // stalledValidationCount = 1 → signal chip shows '1'
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('pull-to-refresh exists when health data loaded', (tester) async {
    await tester.pumpWidget(_buildScreen(
      PipelineHealthState(health: makePipelineHealthDto()),
    ));
    await tester.pump();

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('refresh icon shown when health data present', (tester) async {
    await tester.pumpWidget(_buildScreen(
      PipelineHealthState(health: makePipelineHealthDto()),
    ));
    await tester.pump();

    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });
}
