import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paths_mobile/main.dart';
import 'package:paths_mobile/features/auth/data/http_auth_repository.dart';
import 'package:paths_mobile/features/discovery/data/location_sync_service.dart';

import '../auth/auth_repository_test.dart';
import '../auth/auth_screens_test.dart' show tap;
import 'encounter_repository_test.dart' show EncounterAdapter;
import 'location_sync_service_test.dart';

void main() {
  testWidgets(
    'adult Home/profile stacks preserve filters and signout removes discovery',
    (tester) async {
      final adapter = EncounterAdapter()
        ..adultChecked = true
        ..profile = {
          'username': 'fixture_user',
          'name': 'Fixture User',
          'gender': 'man',
          'bio': '',
          'visibility': 'private',
        };
      final preferences = MemoryPreferences()
        ..values['paths.auth.onboarding'] = true;
      final repo = HttpAuthRepository(
        origin: 'https://api.example.invalid',
        vault: MemoryVault(),
        preferences: preferences,
        publicTransport: Dio()..httpClientAdapter = adapter,
        authenticatedTransport: Dio()..httpClientAdapter = adapter,
      );
      final tracker = CapturingTracker();
      final sync = LocationSyncService(
        FixtureLocationRepository(),
        tracker,
        MemoryTrackingControls(),
        'https://api.example.invalid',
      );
      await tester.pumpWidget(PathsApp(repository: repo, locationSync: sync));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'),
        'fixture@example.invalid',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'a long fixture password',
      );
      await tap(tester, 'Login');
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.go('/profiles/11111111-1111-4111-8111-111111111111');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/profile');
      expect(find.text('Connect'), findsNothing);
      router.go('/profile');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Home'), findsOneWidget);
      await tester.tap(find.byTooltip('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Crossed paths'), findsOneWidget);
      await tap(tester, 'Nearby');
      expect(adapter.discovery!.uri.queryParameters['mode'], 'nearby');
      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Home'));
      await tester.pumpAndSettle();
      expect(adapter.discovery!.uri.queryParameters['mode'], 'nearby');
      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tap(tester, 'Sign out');
      expect(find.text('Log in'), findsOneWidget);
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Crossed paths'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await sync.close();
      await tracker.dispose();
    },
  );
}
