import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/main.dart';
import 'package:paths_mobile/features/auth/data/http_auth_repository.dart';
import 'package:paths_mobile/features/auth/presentation/credential_screens.dart';

import 'auth_repository_test.dart'
    show MemoryVault, MemoryPreferences, ApiAdapter;

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('onboarding CTA fits at width$width text$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final adapter = ApiAdapter();
        final repo = HttpAuthRepository(
          origin: 'https://api.example.invalid',
          vault: MemoryVault(),
          preferences: MemoryPreferences(),
          publicTransport: Dio()..httpClientAdapter = adapter,
          authenticatedTransport: Dio()..httpClientAdapter = adapter,
        );
        await tester.pumpWidget(PathsApp(repository: repo));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Get started'));
        await tester.pumpAndSettle();
        final arrow = tester.getRect(
          find.byKey(const ValueKey('onboarding-arrow')),
        );
        expect(arrow.left, greaterThan(0));
        expect(arrow.right, lessThan(width));
        expect(tester.takeException(), null);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
    }
  }

  testWidgets(
    'onboarding is full bleed, footer-free and animates before login',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final adapter = ApiAdapter();
      final repo = HttpAuthRepository(
        origin: 'https://api.example.invalid',
        vault: MemoryVault(),
        preferences: MemoryPreferences(),
        publicTransport: Dio()..httpClientAdapter = adapter,
        authenticatedTransport: Dio()..httpClientAdapter = adapter,
      );
      await tester.pumpWidget(PathsApp(repository: repo));
      await tester.pumpAndSettle();
      final photo = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName.contains('friends-walking'),
      );
      expect(tester.getRect(photo).left, 0);
      expect(tester.getRect(photo).width, 390);
      expect(tester.getRect(photo).height, closeTo(844 * .52, 2));
      expect(find.textContaining('Already have an account'), findsNothing);
      expect(find.text('Terms'), findsNothing);
      expect(find.text('Image credit'), findsNothing);
      final arrow = find.byKey(const ValueKey('onboarding-arrow'));
      final before = tester.getCenter(arrow).dx;
      await tester.tap(find.text('Get started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(tester.getCenter(arrow).dx, greaterThan(before + 40));
      expect(find.byType(CredentialsScreen), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Log in'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(CredentialsScreen)))
            .scaffoldBackgroundColor,
        Colors.white,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
