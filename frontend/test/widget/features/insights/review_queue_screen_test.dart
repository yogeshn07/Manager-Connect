import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/presentation/providers/review_queue_provider.dart';
import 'package:manager_connect/features/insights/presentation/screens/review_queue_screen.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';

import '../../../helpers/insight_fixtures.dart';

// ── Stub notifier ─────────────────────────────────────────────────────────────

class _StubReviewQueueNotifier extends ReviewQueueNotifier {
  _StubReviewQueueNotifier(this._state);
  final ReviewQueueState _state;

  @override
  ReviewQueueState build() => _state;

  @override
  Future<void> load() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<bool> approve(String insightId) async => true;

  @override
  Future<bool> reject(String insightId, {String? reason}) async => true;
}

Widget _buildScreen(ReviewQueueState state) => ProviderScope(
      overrides: [
        reviewQueueProvider.overrideWith(() => _StubReviewQueueNotifier(state)),
      ],
      child: const MaterialApp(home: ReviewQueueScreen()),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('shows LoadingState when loading with no items', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const ReviewQueueState(isLoading: true),
    ));
    await tester.pump();

    expect(find.byType(LoadingState), findsOneWidget);
  });

  testWidgets('shows ErrorState when error and no items', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const ReviewQueueState(error: 'EF unreachable'),
    ));
    await tester.pump();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('ErrorState has retry button', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const ReviewQueueState(error: 'EF unreachable'),
    ));
    await tester.pump();

    expect(find.text('Try Again'), findsOneWidget);
  });

  testWidgets('shows empty queue state when queue is clear', (tester) async {
    await tester.pumpWidget(_buildScreen(const ReviewQueueState()));
    await tester.pump();

    expect(find.text('Queue is clear'), findsOneWidget);
  });

  testWidgets('renders queue items when items are present', (tester) async {
    final items = [
      makeReviewDto(id: 'ci-001'),
      makeReviewDto(id: 'ci-002'),
    ];
    await tester.pumpWidget(_buildScreen(ReviewQueueState(items: items)));
    await tester.pump();

    // Each card shows the headline
    expect(find.text('Grid modernisation accelerates'), findsWidgets);
  });

  testWidgets('pull-to-refresh exists when items are present', (tester) async {
    final items = [makeReviewDto()];
    await tester.pumpWidget(_buildScreen(ReviewQueueState(items: items)));
    await tester.pump();

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('shows Approve and Reject buttons per item', (tester) async {
    final items = [makeReviewDto(id: 'ci-001')];
    await tester.pumpWidget(_buildScreen(ReviewQueueState(items: items)));
    await tester.pump();

    // "Approve" action is labelled "Publish" in the _ActionRow widget
    expect(find.text('Publish'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });

  testWidgets('does not show loading when items already present', (tester) async {
    final items = [makeReviewDto()];
    await tester.pumpWidget(_buildScreen(ReviewQueueState(items: items)));
    await tester.pump();

    expect(find.byType(LoadingState), findsNothing);
  });
}
