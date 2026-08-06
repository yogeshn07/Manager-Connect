import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/presentation/providers/insights_provider.dart';
import 'package:manager_connect/features/insights/presentation/screens/insights_feed_screen.dart';
import 'package:manager_connect/shared/widgets/mc/mc_shimmer.dart';

import '../../../helpers/insight_fixtures.dart';

// ── Stub notifiers ────────────────────────────────────────────────────────────

class _StubFeedNotifier extends InsightsFeedNotifier {
  _StubFeedNotifier(this._state);
  final InsightsFeedState _state;

  @override
  InsightsFeedState build() => _state;

  @override
  Future<void> load() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> refresh() async {}

  @override
  void setCategory(String? category) {}
}

Widget _buildScreen(InsightsFeedState state) => ProviderScope(
      overrides: [
        insightsFeedProvider.overrideWith(() => _StubFeedNotifier(state)),
      ],
      child: const MaterialApp(home: InsightsFeedScreen()),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('shows shimmer skeleton when loading with no items', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const InsightsFeedState(isLoading: true),
    ));
    await tester.pump();

    // Screen uses custom _InsightCardSkeleton (MCShimmerBox), not the shared LoadingState
    expect(find.byType(MCShimmerBox), findsWidgets);
  });

  testWidgets('shows error title when error and no items', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const InsightsFeedState(error: 'Network error'),
    ));
    await tester.pump();

    // Screen uses private _ErrorState (not shared ErrorState widget)
    expect(find.text('Failed to load insights'), findsOneWidget);
  });

  testWidgets('error state has a retry button', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const InsightsFeedState(error: 'Network error'),
    ));
    await tester.pump();

    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('shows empty-state text when loaded with no items', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const InsightsFeedState(),
    ));
    await tester.pump();

    expect(find.text('No insights yet'), findsOneWidget);
  });

  testWidgets('renders list when items are present', (tester) async {
    final items = List.generate(3, (i) => makeInsightDto(id: 'ci-00$i'));
    await tester.pumpWidget(_buildScreen(
      InsightsFeedState(items: items),
    ));
    await tester.pump();

    // At least one item headline should appear
    expect(find.text('Grid modernisation accelerates in Southeast Asia'), findsWidgets);
  });

  testWidgets('category chips row is rendered', (tester) async {
    await tester.pumpWidget(_buildScreen(const InsightsFeedState()));
    await tester.pump();

    // The "All" chip is always present
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('pull-to-refresh indicator exists when items are present', (tester) async {
    final items = [makeInsightDto()];
    await tester.pumpWidget(_buildScreen(InsightsFeedState(items: items)));
    await tester.pump();

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('does NOT show skeleton or error when items already loaded',
      (tester) async {
    final items = [makeInsightDto()];
    await tester.pumpWidget(_buildScreen(InsightsFeedState(items: items)));
    await tester.pump();

    // No shimmer skeleton when items are loaded
    expect(find.byType(MCShimmerBox), findsNothing);
    // No error message when items are loaded
    expect(find.text('Failed to load insights'), findsNothing);
  });
}
