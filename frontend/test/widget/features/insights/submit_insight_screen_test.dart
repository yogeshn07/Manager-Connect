import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager_connect/features/insights/presentation/providers/submit_insight_provider.dart';
import 'package:manager_connect/features/insights/presentation/screens/submit_insight_screen.dart';


// ── Stub notifier ─────────────────────────────────────────────────────────────

class _StubSubmitNotifier extends SubmitInsightNotifier {
  _StubSubmitNotifier(this._state);
  final SubmitInsightState _state;

  @override
  SubmitInsightState build() => _state;

  @override
  Future<void> loadSources() async {}

  @override
  void setUrl(String url) {}

  @override
  void setSource(dynamic source) {}

  @override
  Future<void> submit() async {}

  @override
  void clearSubmissionError() {}
}

Widget _buildScreen(SubmitInsightState state) => ProviderScope(
      overrides: [
        submitInsightProvider.overrideWith(() => _StubSubmitNotifier(state)),
      ],
      child: const MaterialApp(
        home: SubmitInsightScreen(),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('renders Submit Insight AppBar title', (tester) async {
    await tester.pumpWidget(_buildScreen(const SubmitInsightState()));
    await tester.pump();

    expect(find.text('Submit Insight'), findsOneWidget);
  });

  testWidgets('shows URL field label', (tester) async {
    await tester.pumpWidget(_buildScreen(const SubmitInsightState()));
    await tester.pump();

    expect(find.text('Article URL'), findsOneWidget);
  });

  testWidgets('shows source publication label', (tester) async {
    await tester.pumpWidget(_buildScreen(const SubmitInsightState()));
    await tester.pump();

    expect(find.text('Source publication'), findsOneWidget);
  });

  testWidgets('shows loading indicator when sources are loading', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const SubmitInsightState(isLoadingSources: true),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows source error when sources failed to load', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const SubmitInsightState(sourcesError: 'Failed to load sources'),
    ));
    await tester.pump();

    // _SourceLoadError renders a fixed message, not the raw sourcesError string
    expect(find.textContaining('Failed to load sources'), findsOneWidget);
  });

  testWidgets('shows url validation error', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const SubmitInsightState(urlError: 'Enter a valid URL'),
    ));
    await tester.pump();

    expect(find.text('Enter a valid URL'), findsOneWidget);
  });

  testWidgets('shows source validation error', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const SubmitInsightState(sourceError: 'Select a source publication'),
    ));
    await tester.pump();

    expect(find.text('Select a source publication'), findsOneWidget);
  });

  testWidgets('shows success state when isSuccess is true', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const SubmitInsightState(isSuccess: true, rawId: 'raw-001'),
    ));
    await tester.pump();

    // _SuccessState renders 'Insight submitted!' as its headline
    expect(find.text('Insight submitted!'), findsOneWidget);
  });

  testWidgets('submit button is present when canSubmit is false', (tester) async {
    await tester.pumpWidget(_buildScreen(
      const SubmitInsightState(url: '', selectedSource: null),
    ));
    await tester.pump();

    // The submit button in _SubmitBar is labelled 'Submit to pipeline'
    expect(find.text('Submit to pipeline'), findsOneWidget);
  });
}
