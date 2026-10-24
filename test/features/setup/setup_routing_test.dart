import 'setup_resume_test.dart' show Progress;

import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paths_mobile/features/auth/presentation/auth_cubit.dart';

import 'dart:async';
import 'dart:typed_data';

import 'package:paths_mobile/features/media/domain/media_repository.dart';
import 'package:paths_mobile/features/media/presentation/private_image.dart';

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
              ? profile['avatarAssetId'] ??
                    '11111111-1111-4111-8111-111111111111'
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

class ProfilePickerFixture extends PhotoPickerFixture {
  @override
  Future<PickedPhoto?> pick(PhotoSource source) async => PickedPhoto(
    Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNQSpv5HwAD8AIhWOkYZwAAAABJRU5ErkJggg==',
      ),
    ),
    'image/png',
  );
}

class PhotoSetupAdapter extends SetupAdapter {
  static const assetId = '22222222-2222-4222-8222-222222222222';
  Map<String, dynamic>? saved;
  bool cancelled = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (options.path.startsWith('/v1/media/')) {
      if (options.method == 'DELETE') cancelled = true;
      if (options.method == 'PUT' && stream != null) {
        await for (final _ in stream) {}
      }
      if (options.uri.path.endsWith('/content')) {
        final photo = await ProfilePickerFixture().pick(PhotoSource.gallery);
        return ResponseBody.fromBytes(
          photo!.bytes,
          200,
          headers: {
            'content-type': ['image/png'],
          },
        );
      }
      return ResponseBody.fromString(
        jsonEncode({
          'id': assetId,
          'kind': 'avatar',
          'processingState': options.path.endsWith('/intents')
              ? 'intent'
              : 'ready',
          'safetyState': 'pending',
          'expiresAt': '2026-10-18T00:00:00Z',
          'failureCode': null,
        }),
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    if (options.path == '/v1/me/profile' && options.method == 'PUT') {
      saved = Map<String, dynamic>.from(options.data as Map);
      profile = Map<String, Object>.from(saved!);
      complete = saved!['avatarAssetId'] == assetId;
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
      photoPicker: ProfilePickerFixture(),
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
    find.widgetWithText(TextFormField, 'Email address'),
    'fixture@example.invalid',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    'fixture password',
  );
  await tap(tester, 'Login');
  return (
    router: GoRouter.of(tester.element(find.byType(Scaffold).first)),
    sync: sync,
    tracker: tracker,
  );
}

Future<void> resumeApp(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pumpAndSettle();
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
  testWidgets('Chats tab remains reachable after completed setup', (
    tester,
  ) async {
    final app = await start(
      tester,
      SetupAdapter(),
      Progress()..seen.add('11111111-1111-4111-8111-111111111111'),
    );
    await tester.tap(find.byTooltip('Chats'));
    await tester.pumpAndSettle();
    expect(app.router.routeInformationProvider.value.uri.path, '/chats');
    expect(find.text('Chats'), findsWidgets);
    await stop(tester, app.sync, app.tracker);
  });
  for (final complete in [true, false]) {
    testWidgets(
      'review route remains reachable during and after setup ($complete)',
      (tester) async {
        final adapter = SetupAdapter()..complete = complete;
        final app = await start(
          tester,
          adapter,
          Progress()..seen.add('11111111-1111-4111-8111-111111111111'),
        );
        app.router.push('/reviews');
        await tester.pumpAndSettle();
        expect(find.text('Reviews'), findsOneWidget);
        await stop(tester, app.sync, app.tracker);
      },
    );
  }

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
    'logout does not carry the previous session destination into a later sign-in',
    (tester) async {
      final app = await start(
        tester,
        SetupAdapter(),
        Progress()..seen.add('11111111-1111-4111-8111-111111111111'),
      );
      app.router.go('/likes');
      await tester.pumpAndSettle();
      final logout = tester
          .element(find.byType(Scaffold).first)
          .read<AuthCubit>()
          .logout();
      await tester.pumpAndSettle();
      await logout;
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'),
        'fixture@example.invalid',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'fixture password',
      );
      await tap(tester, 'Login');
      expect(app.router.routeInformationProvider.value.uri.path, '/home');
      await stop(tester, app.sync, app.tracker);
    },
  );
  for (final resume in [false, true]) {
    testWidgets(
      'Use photo returns the owned asset and Next saves it (resume=$resume)',
      (tester) async {
        final adapter = PhotoSetupAdapter()
          ..complete = false
          ..offer = false;
        final app = await start(tester, adapter, Progress());
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'),
          'Draft name',
        );
        await tap(tester, 'Add photo');
        await tap(tester, 'Gallery');
        if (resume) {
          await resumeApp(tester);
        }

        await tap(tester, 'Use photo');
        expect(find.text('Discard photo?'), findsNothing);
        expect(
          app.router.routeInformationProvider.value.uri.path,
          '/setup/profile',
        );
        expect(find.text('Change photo'), findsOneWidget);
        expect(find.text('Draft name'), findsOneWidget);
        expect(find.byType(PrivateImage), findsOneWidget);
        expect(
          tester.widget<PrivateImage>(find.byType(PrivateImage)).assetId,
          PhotoSetupAdapter.assetId,
        );
        final decoded = find.descendant(
          of: find.byType(PrivateImage),
          matching: find.byType(RawImage),
        );
        for (
          var attempt = 0;
          attempt < 50 && decoded.evaluate().isEmpty;
          attempt++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        expect(
          tester
              .widget<RawImage>(
                find.descendant(
                  of: find.byType(PrivateImage),
                  matching: find.byType(RawImage),
                ),
              )
              .image,
          isNotNull,
        );
        await tester.ensureVisible(find.text('Next'));
        await tap(tester, 'Next');
        expect(adapter.saved?['avatarAssetId'], PhotoSetupAdapter.assetId);
        expect(
          app.router.routeInformationProvider.value.uri.path,
          '/setup/verification',
        );
        expect(adapter.cancelled, false);
        await stop(tester, app.sync, app.tracker);
      },
    );
  }
  testWidgets(
    'account restriction discovered on resume still closes the photo route',
    (tester) async {
      final adapter = PhotoSetupAdapter()..complete = false;
      final app = await start(tester, adapter, Progress());
      await tap(tester, 'Add photo');
      await tap(tester, 'Gallery');
      adapter.restricted = true;
      await resumeApp(tester);
      expect(
        app.router.routeInformationProvider.value.uri.path,
        '/account/restricted',
      );
      expect(find.text('Use photo'), findsNothing);
      expect(adapter.saved, isNull);
      await stop(tester, app.sync, app.tracker);
    },
  );
  testWidgets(
    'incomplete setup cannot bypass guards and optional review continues to Home',
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
      expect(app.router.routeInformationProvider.value.uri.path, '/home');
      // Permission education is now a compact Home prompt, never an onboarding gate.
      expect(progress.seen, isEmpty);
      await stop(tester, app.sync, app.tracker);
    },
  );
}
