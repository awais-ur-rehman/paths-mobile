import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_repository_test.dart';
import '../auth/auth_screens_test.dart' show signInForSetup, tap;

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
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('profile edit and preview fit $width at $scale text', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final adapter = ApiAdapter()
          ..adultChecked = true
          ..profile = {
            'username': 'fixture_user',
            'name': 'Fixture User',
            'gender': 'prefer_not_to_say',
            'bio': 'Fixture biography',
            'visibility': 'private',
          };
        await signInForSetup(tester, adapter);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Next'));
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/profile');
        await tester.pumpAndSettle();
        expect(find.text('Fixture User, 26'), findsOneWidget);
        await tester.ensureVisible(find.text('Edit profile'));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
    }
  }
  testWidgets('own profile visual fixture', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final adapter = ApiAdapter()
      ..adultChecked = true
      ..profile = {
        'username': 'fixture_user',
        'name': 'Fixture User',
        'gender': 'prefer_not_to_say',
        'bio': 'A familiar face. A new connection.',
        'visibility': 'private',
      };
    await signInForSetup(tester, adapter);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/profile');
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/own-profile.png'),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('adult with no profile can recover after skipping review', (
    tester,
  ) async {
    final adapter = ApiAdapter()..adultChecked = true;
    await signInForSetup(tester, adapter);
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go('/setup/verification');
    await tester.pumpAndSettle();
    await tap(tester, 'Skip');
    expect(
      adapter.requests.where((r) => r.path.startsWith('/v1/profiles/')).length,
      1,
    );
    expect(find.text('Back to profile setup'), findsOneWidget);
    await tap(tester, 'Back to profile setup');
    expect(find.text('Make it your profile'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets(
    'privacy is saved and continuing opens optional review; skip is durable',
    (tester) async {
      final adapter = ApiAdapter()
        ..adultChecked = true
        ..profile = {
          'username': 'fixture_user',
          'name': 'Fixture User',
          'gender': 'prefer_not_to_say',
          'bio': 'Fixture biography',
          'visibility': 'private',
        };
      await signInForSetup(tester, adapter);
      expect(find.text('Private profile'), findsOneWidget);
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      await tap(tester, 'Next');
      expect(adapter.profile['visibility'], 'public');
      expect(find.text('Verification'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      await tap(tester, 'Skip');
      expect(adapter.verificationSeen, true);
      expect(find.text('Follow'), findsNothing);
      expect(find.text('Followers'), findsNothing);
      expect(find.text('Fixture User, 26'), findsOneWidget);
      await tap(tester, 'Edit profile');
      expect(find.text('Public profile'), findsOneWidget);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.go('/profile');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Profile options'));
      await tester.pumpAndSettle();
      await tap(tester, 'Sign out');
      router.go('/setup/verification');
      await tester.pumpAndSettle();
      expect(find.text('Log in'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('non-adult users cannot deep-link to profile or verification', (
    tester,
  ) async {
    final adapter = ApiAdapter();
    await signInForSetup(tester, adapter);
    final context = tester.element(find.byType(Scaffold).first);
    final router = GoRouter.of(context);
    router.go('/setup/verification');
    await tester.pumpAndSettle();
    expect(find.text('Confirm you’re 18 or over'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
