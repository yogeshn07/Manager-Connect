import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/presentation/providers/insights_provider.dart';
import 'package:manager_connect/features/insights/presentation/screens/insight_detail_screen.dart';
import 'package:manager_connect/shared/widgets/mc/mc_shimmer.dart';

import '../../../helpers/insight_fixtures.dart';

// ── Stub notifier ─────────────────────────────────────────────────────────────

class _StubDetailNotifier extends InsightDetailNotifier {
  _StubDetailNotifier(this._state);
  final InsightDetailState _state;

  @override
  InsightDetailState build() => _state;

  @override
  Future<void> load(String insightId) async {}
}

Widget _buildScreen(InsightDetailState state) => ProviderScope(
      overrides: [
        insightDetailProvider.overrideWith(() => _StubDetailNotifier(state)),
      ],
      child: const MaterialApp(
        home: InsightDetailScreen(insightId: 'ci-001'),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('shows shimmer skeleton while loading', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const InsightDetailState(isLoading: true),
    ));
    await tester.pump();

    // Screen uses _DetailSkeleton (MCShimmerBox), not CircularProgressIndicator
    expect(find.byType(MCShimmerBox), findsWidgets);
  });

  testWidgets('shows error title when error is set', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const InsightDetailState(error: 'Not found'),
    ));
    await tester.pump();

    // Screen uses private _DetailErrorState, not shared ErrorState widget
    expect(find.text('Failed to load insight'), findsOneWidget);
  });

  testWidgets('error state has a Try Again button', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const InsightDetailState(error: 'Not found'),
    ));
    await tester.pump();

    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('shows insight headline when insight is loaded', (tester) async {
    final insight = makeInsightDto(
      aiHeadline: 'Grid modernisation accelerates in Southeast Asia',
    );
    await tester.pumpWidget(_buildScreen(
      InsightDetailState(insight: insight),
    ));
    await tester.pump();

    expect(
      find.text('Grid modernisation accelerates in Southeast Asia'),
      findsOneWidget,
    );
  });

  testWidgets('shows source name when insight is loaded', (tester) async {
    final insight = makeInsightDto();
    await tester.pumpWidget(_buildScreen(InsightDetailState(insight: insight)));
    await tester.pump();

    expect(find.text('Energy Monitor'), findsOneWidget);
  });

  testWidgets('error state after prior success clears correctly', (tester) async {
    // Simulates S5-INT-001 bug scenario: successful load after error
    final insight = makeInsightDto();
    // After S5-INT-001 fix: state is {insight: dto, error: null} after retry.
    await tester.pumpWidget(_buildScreen(
      InsightDetailState(insight: insight, error: null),
    ));
    await tester.pump();

    // Must show content, NOT error
    expect(find.text('Failed to load insight'), findsNothing);
    expect(find.text('Energy Monitor'), findsOneWidget);
  });

  testWidgets('renders AppBar with back button', (tester) async {
    final insight = makeInsightDto();
    await tester.pumpWidget(_buildScreen(InsightDetailState(insight: insight)));
    await tester.pump();

    expect(find.byType(AppBar), findsOneWidget);
  });
}
