import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/presentation/providers/submission_history_provider.dart';
import 'package:manager_connect/features/insights/presentation/screens/submission_history_screen.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_cards.dart';
import 'package:manager_connect/shared/widgets/mc/mc_shimmer.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/insight_fixtures.dart';

// ── Supabase fakes (screen reads supabaseClientProvider directly) ──────────────

class _MockSupabaseClient extends Mock implements SupabaseClient {}
class _MockGoTrueClient extends Mock implements GoTrueClient {}

_MockSupabaseClient _buildMockClient({User? currentUser}) {
  final auth = _MockGoTrueClient();
  when(() => auth.currentUser).thenReturn(currentUser);
  final client = _MockSupabaseClient();
  when(() => client.auth).thenReturn(auth);
  return client;
}

// ── Stub notifier ─────────────────────────────────────────────────────────────

class _StubHistoryNotifier extends SubmissionHistoryNotifier {
  _StubHistoryNotifier(this._state);
  final SubmissionHistoryState _state;

  @override
  SubmissionHistoryState build() => _state;

  @override
  Future<void> load(String userId) async {}

  @override
  Future<void> refresh(String userId) async {}

  @override
  Future<String?> getPublishedId(String rawId) async => null;
}

Widget _buildScreen(SubmissionHistoryState state, {User? currentUser}) =>
    ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(_buildMockClient(currentUser: currentUser)),
        submissionHistoryProvider.overrideWith(() => _StubHistoryNotifier(state)),
      ],
      child: const MaterialApp(home: SubmissionHistoryScreen()),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('shows shimmer skeleton when loading with no items', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const SubmissionHistoryState(isLoading: true),
    ));
    await tester.pump();

    // Screen uses _LoadingSkeleton (MCShimmerBox), not the shared LoadingState
    expect(find.byType(MCShimmerBox), findsWidgets);
  });

  testWidgets('shows error title when error and no items', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const SubmissionHistoryState(error: 'Failed to load history'),
    ));
    await tester.pump();

    // Screen uses private _ErrorState, not the shared ErrorState widget
    expect(find.text('Could not load submissions'), findsOneWidget);
  });

  testWidgets('shows empty state when loaded with no items', (tester) async {
    await tester.pumpWidget(_buildScreen(const SubmissionHistoryState()));
    await tester.pump();

    expect(find.text('No submissions yet'), findsOneWidget);
  });

  testWidgets('renders submission items when items are present', (tester) async {
    final items = [
      makeInsightRawDto(id: 'raw-001', rawUrl: 'https://energymonitor.ai/article/1'),
      makeInsightRawDto(id: 'raw-002', rawUrl: 'https://energymonitor.ai/article/2', status: 'ai_processed'),
    ];
    await tester.pumpWidget(_buildScreen(SubmissionHistoryState(items: items)));
    await tester.pump();

    // Screen uses _HistoryCard (MCCard), not ListTile
    expect(find.byType(MCCard), findsWidgets);
  });

  testWidgets('pull-to-refresh is present when items loaded', (tester) async {
    final items = [makeInsightRawDto()];
    await tester.pumpWidget(_buildScreen(SubmissionHistoryState(items: items)));
    await tester.pump();

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('does not crash when supabase user is null', (tester) async {
    // Screen guards load() call when userId is null — should show empty state
    await tester.pumpWidget(_buildScreen(
      const SubmissionHistoryState(),
      currentUser: null,
    ));
    await tester.pump();

    expect(find.text('No submissions yet'), findsOneWidget);
  });

  testWidgets('shows pending status chip for pending items', (tester) async {
    final items = [makeInsightRawDto(status: 'pending')];
    await tester.pumpWidget(_buildScreen(SubmissionHistoryState(items: items)));
    await tester.pump();

    // _StatusPill capitalises the status: 'pending' → 'Pending'
    expect(find.text('Pending'), findsOneWidget);
  });
}
