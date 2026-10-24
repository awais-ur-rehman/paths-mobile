import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/verification/domain/verification_repository.dart';
import 'package:paths_mobile/features/verification/presentation/verification_screen.dart';
import 'package:paths_mobile/shared/widgets/paths_toast.dart';
import 'package:paths_mobile/shared/widgets/paths_brand.dart';
import 'package:paths_mobile/shared/widgets/verification_badge.dart';

import 'verification_cubit_test.dart';

Future<void> mount(
  WidgetTester tester,
  FixtureVerification repo, {
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      theme: PathsTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: PathsToastHost(child: child!),
      ),
      home: VerificationScreen(repository: repo, documents: repo),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'Inter': 'assets/fonts/Inter-Variable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });
  tearDown(() {});
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('optional review fits $width at $scale text', (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = FixtureVerification()
          ..info = const VerificationInfo(
            status: 'none',
            offerSeen: false,
            uploadsAvailable: false,
          );
        await mount(tester, repo, width: width, scale: scale);
        await tester.ensureVisible(find.text('Skip'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Skip'), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
    }
  }
  testWidgets(
    'server availability cannot enable a missing local document adapter',
    (tester) async {
      final repo = FixtureVerification();
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          home: VerificationScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      final tile = find
          .ancestor(of: find.text('CNIC front'), matching: find.byType(InkWell))
          .first;
      expect(tester.widget<InkWell>(tile).onTap, isNull);
      expect(find.byType(CheckboxListTile), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'pull refresh updates pending review without adding another button',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FixtureVerification()
        ..info = const VerificationInfo(
          status: 'pending',
          offerSeen: true,
          uploadsAvailable: false,
        );
      await mount(tester, repo);
      expect(find.text('Review pending'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      repo.info = const VerificationInfo(
        status: 'approved',
        offerSeen: true,
        uploadsAvailable: false,
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 350),
      );
      await tester.pumpAndSettle();
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Refresh status'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'pending processing cannot submit; declined note and retry remain visible',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FixtureVerification()
        ..info = const VerificationInfo(
          status: 'declined',
          offerSeen: true,
          uploadsAvailable: true,
          reason: 'Front is unreadable',
        );
      await mount(tester, repo);
      expect(find.text('Review note: Front is unreadable'), findsOneWidget);
      await tester.ensureVisible(find.text('CNIC front'));
      await tester.tap(find.text('CNIC front'));
      await tester.pumpAndSettle();
      expect(find.text('Processing'), findsOneWidget);
      final badgeBefore = tester.widget<VerificationBadge>(
        find.byType(VerificationBadge),
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(
        tester.widget<VerificationBadge>(find.byType(VerificationBadge)),
        same(badgeBefore),
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(repo.submissions, 0);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('approved badge explains limited document review', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        home: const Scaffold(body: VerificationBadge(status: 'approved')),
      ),
    );
    await tester.tap(find.text('Verified'));
    await tester.pumpAndSettle();
    expect(find.text('Document reviewed by Paths'), findsOneWidget);
    expect(find.textContaining('not a government'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });
  testWidgets('verification visual fixture', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FixtureVerification()
      ..info = const VerificationInfo(
        status: 'none',
        offerSeen: false,
        uploadsAvailable: false,
      );
    await mount(tester, repo);
    final symbolBounds = tester.getRect(find.byType(PathsSymbol));
    await tester.runAsync(() async {
      final image = await captureImage(tester.element(find.byType(Scaffold)));
      try {
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        var inkPixels = 0;
        for (
          var y = symbolBounds.top.ceil();
          y < symbolBounds.bottom.floor();
          y++
        ) {
          for (
            var x = symbolBounds.left.ceil();
            x < symbolBounds.right.floor();
            x++
          ) {
            final offset = (y * image.width + x) * 4;
            if (pixels.getUint8(offset) < 80 &&
                pixels.getUint8(offset + 1) < 80 &&
                pixels.getUint8(offset + 2) < 80 &&
                pixels.getUint8(offset + 3) > 0) {
              inkPixels++;
            }
          }
        }
        expect(
          inkPixels,
          greaterThan(100),
          reason: 'The P symbol must be painted',
        );
      } finally {
        image.dispose();
      }
    });
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/optional-verification.png'),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
