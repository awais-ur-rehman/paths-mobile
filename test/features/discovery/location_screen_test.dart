import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paths_mobile/main.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/auth/data/http_auth_repository.dart';
import 'package:paths_mobile/features/discovery/data/location_sync_service.dart';
import 'package:paths_mobile/features/discovery/presentation/location_setup_screen.dart';
import 'package:paths_mobile/shared/widgets/paths_toast.dart';

import '../auth/auth_repository_test.dart';
import '../auth/auth_screens_test.dart' show tap;
import 'location_sync_service_test.dart';

void main() {
  setUpAll(() async {
    for (final e in {
      'Inter': 'assets/fonts/Inter-Variable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  testWidgets(
    'profile exposes optional permission setup and collection survives leaving the page',
    (tester) async {
      final tracker = CapturingTracker(),
          data = FixtureLocationRepository(),
          store = MemoryTrackingControls();
      final sync = LocationSyncService(
        data,
        tracker,
        store,
        'https://api.example.invalid',
      );
      final adapter = ApiAdapter()
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
      final auth = HttpAuthRepository(
        origin: 'https://api.example.invalid',
        vault: MemoryVault(),
        preferences: preferences,
        publicTransport: Dio()..httpClientAdapter = adapter,
        authenticatedTransport: Dio()..httpClientAdapter = adapter,
        purgeTracking: sync.stopLocalAndMarkPending,
      );
      await tester.pumpWidget(PathsApp(repository: auth, locationSync: sync));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'fixture@example.invalid',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'a long fixture password',
      );
      await tap(tester, 'Sign in');
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.go('/profile');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Profile options'));
      await tester.pumpAndSettle();
      await tap(tester, 'Location & permissions');
      expect(
        find.textContaining('exact location on its server'),
        findsOneWidget,
      );
      expect(tracker.starts, 0);
      await tap(tester, 'Enable while using Paths');
      expect(tracker.starts, 1);
      expect(data.grants, 1);
      await tap(tester, 'Not now — back to profile');
      expect(tracker.starts, 1);
      expect(find.text('Fixture User, 26'), findsOneWidget);
      await tester.tap(find.byTooltip('Profile options'));
      await tester.pumpAndSettle();
      await tap(tester, 'Sign out');
      expect(tracker.status.name, 'paused');
      expect(store.pending, true);
      expect(find.text('Good to see you'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await sync.close();
      await tracker.dispose();
    },
  );
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('permissions remain optional at $width and text$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final tracker = CapturingTracker()..granted = false,
            data = FixtureLocationRepository(),
            store = MemoryTrackingControls();
        final sync = LocationSyncService(
          data,
          tracker,
          store,
          'https://api.example.invalid',
        );
        final router = GoRouter(
          initialLocation: '/setup/permissions',
          routes: [
            GoRoute(
              path: '/setup/permissions',
              builder: (_, _) => LocationSetupScreen(sync: sync),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, _) =>
                  const Scaffold(body: Text('Profile destination')),
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp.router(
            theme: PathsTheme.light,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: PathsToastHost(child: child!),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Not now — back to profile'));
        expect(tester.takeException(), isNull);
        expect(data.grants, 0);
        await tap(tester, 'Not now — back to profile');
        expect(find.text('Profile destination'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        router.dispose();
        await sync.close();
        await tracker.dispose();
      });
    }
  }
  testWidgets(
    'offline pause is local success with pending server control, not resumed capture',
    (tester) async {
      final tracker = CapturingTracker(),
          data = FixtureLocationRepository(),
          store = MemoryTrackingControls();
      final sync = LocationSyncService(
        data,
        tracker,
        store,
        'https://api.example.invalid',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          builder: (context, child) => PathsToastHost(child: child!),
          home: LocationSetupScreen(sync: sync),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'Enable while using Paths');
      tracker.count = 15;
      data.offline = true;
      await tap(tester, 'Pause and clear updates');
      expect(tracker.count, 0);
      expect(find.textContaining('Server pause is pending'), findsOneWidget);
      expect(store.pending, true);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await sync.close();
      await tracker.dispose();
    },
  );
  testWidgets('location disclosure visual fixture', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tracker = CapturingTracker(),
        data = FixtureLocationRepository(),
        store = MemoryTrackingControls();
    final sync = LocationSyncService(
      data,
      tracker,
      store,
      'https://api.example.invalid',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        builder: (context, child) => PathsToastHost(child: child!),
        home: LocationSetupScreen(sync: sync),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/location-permissions.png'),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await sync.close();
    await tracker.dispose();
  });
}
