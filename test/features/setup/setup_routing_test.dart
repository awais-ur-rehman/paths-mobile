import 'setup_resume_test.dart' show Progress;

import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paths_mobile/main.dart';
import 'package:paths_mobile/features/auth/data/http_auth_repository.dart';
import 'package:paths_mobile/features/discovery/data/location_sync_service.dart';

import '../auth/auth_repository_test.dart';
import '../auth/auth_screens_test.dart' show tap;
import '../discovery/encounter_repository_test.dart' show EncounterAdapter;
import '../discovery/location_sync_service_test.dart';
import '../media/photo_screen_test.dart' show PhotoPickerFixture;

class DelayedVault extends MemoryVault {
  final ready = Completer<void>();
  @override
  Future<String?> read() async {
    await ready.future;
    return value;
  }
}

class SetupAdapter extends EncounterAdapter {
  bool complete = true, offer = true;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (options.path == '/v1/me/profile') {
      return ResponseBody.fromString(
        jsonEncode({
          ...profile,
          'avatarAssetId': complete
              ? '11111111-1111-4111-8111-111111111111'
              : null,
          'profileComplete': complete,
        }),
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    if (options.path.startsWith('/v1/me/verification')) {
      if (options.path.endsWith('/skip')) offer = true;
      return ResponseBody.fromString(
        jsonEncode({
          'status': 'none',
          'offerSeen': offer,
          'uploadsAvailable': true,
          'reason': null,
        }),
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    return super.fetch(options, stream, cancel);
  }
}

Future<({GoRouter router, LocationSyncService sync, CapturingTracker tracker})>
start(
  WidgetTester tester,
  SetupAdapter adapter,
  Progress progress, {
  String? destination,
  bool restore = false,
}) async {
  adapter.adultChecked = true;
  adapter.profile = {
    'username': 'fixture_user',
    'name': 'Fixture',
    'gender': 'man',
    'bio': '',
    'visibility': 'private',
  };
  final vault = DelayedVault();
  if (restore) {
    vault.value = jsonEncode(
      adapter.session('restored-access', 'restored-refresh'),
    );
  } else {
    vault.ready.complete();
  }
  final repo = HttpAuthRepository(
    origin: 'https://api.example.invalid',
    vault: vault,
    preferences: MemoryPreferences()..values['paths.auth.onboarding'] = true,
    publicTransport: Dio()..httpClientAdapter = adapter,
    authenticatedTransport: Dio()..httpClientAdapter = adapter,
  );
  final tracker = CapturingTracker(),
      sync = LocationSyncService(
        FixtureLocationRepository(),
        tracker,
        MemoryTrackingControls(),
        'https://api.example.invalid',
      );
  await tester.pumpWidget(
    PathsApp(
      repository: repo,
      locationSync: sync,
      photoPicker: PhotoPickerFixture(),
      setupProgress: progress,
    ),
  );
  if (restore) {
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go(destination!);
    await tester.pump();
    expect(router.routeInformationProvider.value.uri.path, '/');
    vault.ready.complete();
    await tester.pumpAndSettle();
    return (router: router, sync: sync, tracker: tracker);
  }
  await tester.pumpAndSettle();
  if (destination != null) {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(destination);
    await tester.pumpAndSettle();
  }
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email'),
    'fixture@example.invalid',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    'fixture password',
  );
  await tap(tester, 'Sign in');
  return (
    router: GoRouter.of(tester.element(find.byType(Scaffold).first)),
    sync: sync,
    tracker: tracker,
  );
}

Future<void> stop(
  WidgetTester tester,
  LocationSyncService sync,
  CapturingTracker tracker,
) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
  await sync.close();
  await tracker.dispose();
}

void main() {
  testWidgets(
    'a completed returning account opens Home rather than profile creation',
    (tester) async {
      final app = await start(
        tester,
        SetupAdapter(),
        Progress()..seen.add('11111111-1111-4111-8111-111111111111'),
      );
      expect(app.router.routeInformationProvider.value.uri.path, '/home');
      await stop(tester, app.sync, app.tracker);
    },
  );
  testWidgets(
    'a signed-out protected destination survives sign-in and setup checks',
    (tester) async {
      final app = await start(
        tester,
        SetupAdapter(),
        Progress()..seen.add('11111111-1111-4111-8111-111111111111'),
        destination: '/likes',
      );
      expect(app.router.routeInformationProvider.value.uri.path, '/likes');
      await stop(tester, app.sync, app.tracker);
    },
  );
  testWidgets(
    'a protected destination survives delayed secure-session restoration',
    (tester) async {
      final app = await start(
        tester,
        SetupAdapter(),
        Progress()..seen.add('11111111-1111-4111-8111-111111111111'),
        destination: '/likes',
        restore: true,
      );
      expect(app.router.routeInformationProvider.value.uri.path, '/likes');
      await stop(tester, app.sync, app.tracker);
    },
  );
  testWidgets(
    'incomplete setup cannot bypass guards and continues through optional review and education',
    (tester) async {
      final adapter = SetupAdapter()
            ..complete = false
            ..offer = false,
          progress = Progress(),
          app = await start(tester, adapter, progress);
      expect(
        app.router.routeInformationProvider.value.uri.path,
        '/setup/profile',
      );
      app.router.go('/home');
      await tester.pumpAndSettle();
      expect(
        app.router.routeInformationProvider.value.uri.path,
        '/setup/profile',
      );
      app.router.go('/media/avatar');
      await tester.pumpAndSettle();
      expect(find.text('Profile photo'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(
        app.router.routeInformationProvider.value.uri.path,
        '/setup/profile',
      );
      adapter.complete = true;
      app.router.go('/setup/resume');
      await tester.pumpAndSettle();
      expect(
        app.router.routeInformationProvider.value.uri.path,
        '/setup/verification',
      );
      await tap(tester, 'Skip');
      expect(
        app.router.routeInformationProvider.value.uri.path,
        '/setup/permissions',
      );
      expect(progress.seen, isEmpty);
      progress.failWrite = true;
      await tap(tester, 'Continue');
      expect(
        app.router.routeInformationProvider.value.uri.path,
        '/setup/permissions',
      );
      expect(progress.seen, isEmpty);
      progress.failWrite = false;
      await tap(tester, 'Continue');
      expect(app.router.routeInformationProvider.value.uri.path, '/home');
      expect(progress.seen, contains('11111111-1111-4111-8111-111111111111'));
      await stop(tester, app.sync, app.tracker);
    },
  );
}
