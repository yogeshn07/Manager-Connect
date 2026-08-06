// Root test entry point — delegates to feature test suites.
// Run all tests with: flutter test
// Run a specific suite: flutter test test/unit/features/insights/...
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test runner sanity check', () {
    expect(1 + 1, 2);
  });
}
