import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/shared/widgets/arrow_slide_button.dart';

void main() {
  testWidgets('arrow remains at the destination during navigation handoff', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: ArrowSlideButton(
                onContinue: () async {
                  calls++;
                  return true;
                },
              ),
            ),
          ),
        ),
      ),
    );
    final arrow = find.byKey(const ValueKey('onboarding-arrow'));
    final start = tester.getCenter(arrow).dx;
    await tester.tap(find.byType(ArrowSlideButton));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tester.getCenter(arrow).dx, greaterThan(start + 200));
    await tester.tap(find.byType(ArrowSlideButton));
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('failed continuation resets the arrow and permits retry', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: ArrowSlideButton(
                onContinue: () async {
                  calls++;
                  return false;
                },
              ),
            ),
          ),
        ),
      ),
    );
    final arrow = find.byKey(const ValueKey('onboarding-arrow'));
    final start = tester.getCenter(arrow).dx;
    await tester.tap(find.byType(ArrowSlideButton));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tester.getCenter(arrow).dx, closeTo(start, .01));
    await tester.tap(find.byType(ArrowSlideButton));
    await tester.pumpAndSettle();
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('reduced motion continues on the first frame', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: ArrowSlideButton(
                  onContinue: () async {
                    calls++;
                    return true;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ArrowSlideButton));
    await tester.pump();
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
