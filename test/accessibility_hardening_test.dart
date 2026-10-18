import 'package:flutter/material.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/discovery/presentation/home_screen.dart';
import 'package:paths_mobile/features/discovery/presentation/widgets/encounter_map.dart';

import 'features/discovery/home_screen_test.dart' as home;

import 'package:paths_mobile/shared/widgets/paths_loader.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0, 430.0, 600.0, 768.0, 1024.0]) {
    testWidgets(
      'Home fits width$width at200percent with labeled 48px actions',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(home.app(home.HomeFixture(), scale: 2));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        semantics.dispose();
      },
    );
  }
  testWidgets(
    'inactive Home never constructs the native map even with valid map data',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          home: TickerMode(
            enabled: false,
            child: HomeScreen(
              repository: home.HomeFixture(),
              onProfile: (_) {},
              onLocationSetup: () {},
              mapStyleUrl: 'https://map.example.invalid/style.json',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EncounterMap), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('reduced-motion loader does not schedule decorative frames', (
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
    expect(tester.binding.hasScheduledFrame, false);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });
}
