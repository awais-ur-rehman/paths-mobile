import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/shared/widgets/verification_badge.dart';
import 'package:paths_mobile/shared/widgets/paths_icon.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
  });
  testWidgets('badge family on light and profile surfaces', (tester) async {
    tester.view.physicalSize = const Size(360, 160);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: PathsTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VerificationBadge(status: 'approved'),
                  VerificationBadge(status: 'none'),
                ],
              ),
              ColoredBox(
                color: const Color(0xFF292A2F),
                child: Theme(
                  data: PathsTheme.light.copyWith(
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white70,
                      ),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      VerificationBadge(status: 'approved'),
                      VerificationBadge(status: 'none'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/verification-badges.png'),
    );
  });
  for (final (status, label) in [
    ('none', 'Unverified'),
    ('approved', 'Verified'),
    ('pending', 'Review pending'),
    ('declined', 'Review declined'),
  ]) {
    testWidgets('$status has a named custom badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: VerificationBadge(status: status)),
        ),
      );
      expect(find.text(label), findsOneWidget);
      expect(find.byType(PathsIcon), findsOneWidget);
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(48),
      );
      if (status == 'approved') {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('not a government identity check'),
          findsOneWidget,
        );
      }
    });
  }
}
