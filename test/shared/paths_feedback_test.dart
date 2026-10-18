import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/shared/widgets/paths_toast.dart';
import 'package:paths_mobile/shared/widgets/paths_loader.dart';

void main() {
  Widget app() => MaterialApp(
    builder: (_, child) => PathsToastHost(child: child!),
    home: Scaffold(
      body: Builder(
        builder: (context) => Column(
          children: [
            TextButton(
              onPressed: () => PathsToast.show(context, 'First failure'),
              child: const Text('Error'),
            ),
            TextButton(
              onPressed: () => PathsToast.show(
                context,
                'Saved details',
                tone: ToastTone.success,
              ),
              child: const Text('Success'),
            ),
          ],
        ),
      ),
    ),
  );
  testWidgets('toast enters top right and swipes off the right edge', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app());
    await tester.tap(find.text('Error'));
    await tester.pumpAndSettle();
    final card = find.text('First failure');
    expect(tester.getRect(card).top, lessThan(100));
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    await tester.fling(card, const Offset(500, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('First failure'), findsNothing);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });
  testWidgets(
    'replacing a toast cancels the prior timeout and manual close works',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.tap(find.text('Error'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.text('Success'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Saved details'), findsOneWidget);
      expect(find.text('First failure'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Dismiss notification'));
      await tester.pumpAndSettle();
      expect(find.text('Saved details'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    },
  );
  testWidgets('loader is static for reduced motion and releases its ticker', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: PathsLoader(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.binding.hasScheduledFrame, false);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), null);
  });
}
