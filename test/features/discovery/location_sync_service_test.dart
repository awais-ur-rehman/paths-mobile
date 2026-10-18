import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/discovery/domain/location_repository.dart';
import 'package:paths_mobile/features/discovery/data/location_sync_service.dart';
import 'package:paths_mobile/core/platform/location_tracker.dart';

import '../../experiment_cubit_test.dart';

class MemoryTrackingControls implements TrackingControlStore {
  bool pending = false;
  TrackingStop? control;
  @override
  Future<TrackingStop?> pendingControl() async => control;
  @override
  Future<bool> pendingStop() async => pending;
  @override
  Future<void> setPendingStop(bool value, {TrackingStop? control}) async {
    pending = value;
    this.control = value ? control : null;
  }
}

class FixtureLocationRepository implements LocationRepository {
  String accountId = 'fixture-account';
  @override
  String? get currentTrackingAccountId => accountId;
  int epoch = 1, grants = 0, pauses = 0;
  bool offline = false;
  Completer<LocationLease>? blockedGrant;
  CancelToken? grantToken;
  @override
  Future<TrackingControl> trackingState({CancelToken? cancelToken}) async {
    if (offline) throw const AuthFailure('offline');
    return TrackingControl(epoch, true);
  }

  @override
  Future<TrackingControl> pauseTracking(
    int expected, {
    CancelToken? cancelToken,
  }) async {
    if (offline) throw const AuthFailure('offline');
    pauses++;
    if (expected != epoch) throw const AuthFailure('CONFLICT');
    epoch++;
    return TrackingControl(epoch, true);
  }

  @override
  Future<LocationLease> createTrackingLease(
    int expected, {
    CancelToken? cancelToken,
  }) async {
    grants++;
    grantToken = cancelToken;
    if (offline) throw const AuthFailure('offline');
    if (expected != epoch) throw const AuthFailure('CONFLICT');
    epoch++;
    return blockedGrant?.future ??
        LocationLease(
          '11111111-1111-4111-8111-111111111111',
          epoch,
          'a' * 64,
          DateTime.now().add(const Duration(hours: 24)),
          DateTime.now().millisecondsSinceEpoch,
        );
  }
}

class CapturingTracker extends TestTracker {
  TrackingPolicy? policy;
  @override
  Future<void> start(TrackingPolicy p) async {
    policy = p;
    await super.start(p);
  }

  @override
  Future<TrackingPermissions> permissions() async => TrackingPermissions(
    granted: granted,
    precise: granted,
    backgroundAllowed: backgroundGranted,
    backgroundEnabled:
        policy?.background == true &&
        status != TrackingStatus.paused &&
        status != TrackingStatus.stopped,
    servicesEnabled: true,
  );
  @override
  Future<void> flushPending() async {}
}

class DelayedPauseTracker extends CapturingTracker {
  Completer<void>? nextPause;
  @override
  Future<void> pause() async {
    final pending = nextPause;
    nextPause = null;
    await super.pause();
    await pending?.future;
  }
}

void main() {
  test('accepted deletion clears native samples and the saved account/epoch without another server control', () async {
    final repository = FixtureLocationRepository(),
        tracker = CapturingTracker(),
        controls = MemoryTrackingControls()
          ..pending = true
          ..control = const TrackingStop('fixture-account', 3);
    final sync = LocationSyncService(
      repository,
      tracker,
      controls,
      'https://api.example.invalid',
    );
    await sync.eraseDeletedAccount('fixture-account');
    expect(controls.pending, isFalse);
    expect(controls.control, isNull);
    expect(repository.pauses, 0);
    expect(await tracker.currentStatus(), TrackingStatus.stopped);
    await sync.close();
  });

  test('a persisted old-account stop never pauses the new account', () async {
    final repo = FixtureLocationRepository()..accountId = 'new-account';
    final tracker = CapturingTracker(),
        store = MemoryTrackingControls()
          ..pending = true
          ..control = const TrackingStop('old-account', 3);
    final sync = LocationSyncService(
      repo,
      tracker,
      store,
      'https://api.example.invalid',
    );
    await sync.initialize();
    expect(repo.pauses, 0);
    expect(store.pending, false);
    expect(tracker.starts, 0);
    await sync.close();
    await tracker.dispose();
  });
  test(
    'a persisted stale-epoch stop cannot pause a newer selected device',
    () async {
      final repo = FixtureLocationRepository()..epoch = 9;
      final tracker = CapturingTracker(),
          store = MemoryTrackingControls()
            ..pending = true
            ..control = const TrackingStop('fixture-account', 3);
      final sync = LocationSyncService(
        repo,
        tracker,
        store,
        'https://api.example.invalid',
      );
      await sync.initialize();
      expect(repo.epoch, 9);
      expect(store.pending, false);
      expect(tracker.starts, 0);
      await sync.close();
      await tracker.dispose();
    },
  );

  test(
    'an older slow local pause cannot pause a later explicit enable',
    () async {
      final repo = FixtureLocationRepository(),
          tracker = DelayedPauseTracker(),
          store = MemoryTrackingControls();
      final sync = LocationSyncService(
        repo,
        tracker,
        store,
        'https://api.example.invalid',
      );
      await sync.enable(background: false);
      final blocked = Completer<void>();
      tracker.nextPause = blocked;
      final pause = sync.pause();
      await Future<void>.delayed(Duration.zero);
      await sync.enable(background: false);
      blocked.complete();
      await pause;
      expect(repo.pauses, 2);
      expect(tracker.starts, 2);
      await sync.close();
      await tracker.dispose();
    },
  );

  test('consent starts native production upload only after remote pause and a fresh lease', () async {
    final repo = FixtureLocationRepository(),
        tracker = CapturingTracker(),
        store = MemoryTrackingControls();
    final sync = LocationSyncService(
      repo,
      tracker,
      store,
      'https://api.example.invalid',
    );
    await sync.enable(background: false);
    expect(repo.pauses, 1);
    expect(repo.grants, 1);
    expect(tracker.starts, 1);
    expect(tracker.policy?.uploadMode, 'production');
    expect(
      tracker.policy?.endpoint,
      'https://api.example.invalid/v1/locations',
    );
    expect(store.pending, false);
    await sync.close();
    await tracker.dispose();
  });
  test('offline pause clears native queue immediately and resume reconciles before capture', () async {
    final repo = FixtureLocationRepository(),
        tracker = CapturingTracker(),
        store = MemoryTrackingControls();
    final sync = LocationSyncService(
      repo,
      tracker,
      store,
      'https://api.example.invalid',
    );
    await sync.enable(background: false);
    tracker.count = 20;
    repo.offline = true;
    final pause = expectLater(sync.pause(), throwsA(isA<AuthFailure>()));
    await Future<void>.delayed(Duration.zero);
    expect(tracker.count, 0);
    expect(store.pending, true);
    await pause;
    await expectLater(
      sync.enable(background: false),
      throwsA(isA<AuthFailure>()),
    );
    expect(tracker.starts, 1);
    repo.offline = false;
    await sync.enable(background: false);
    expect(repo.pauses, 2);
    expect(tracker.starts, 2);
    expect(store.pending, false);
    await sync.close();
    await tracker.dispose();
  });
  test(
    'pause cancels a pending grant and no late lease may restart collection',
    () async {
      final repo = FixtureLocationRepository()
        ..blockedGrant = Completer<LocationLease>();
      final tracker = CapturingTracker(), store = MemoryTrackingControls();
      final sync = LocationSyncService(
        repo,
        tracker,
        store,
        'https://api.example.invalid',
      );
      final enable = sync.enable(background: false);
      await Future<void>.delayed(Duration.zero);
      final pause = sync.pause();
      await Future<void>.delayed(Duration.zero);
      expect(repo.grantToken?.isCancelled, true);
      repo.blockedGrant!.complete(
        LocationLease(
          '11111111-1111-4111-8111-111111111111',
          3,
          'a' * 64,
          DateTime.now().add(const Duration(hours: 24)),
          DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await enable;
      await pause;
      expect(tracker.starts, 0);
      expect(store.pending, false);
      await sync.close();
      await tracker.dispose();
    },
  );
  test('permission denial never obtains a lease and leaves a purged stopped tracker', () async {
    final repo = FixtureLocationRepository(),
        tracker = CapturingTracker()..granted = false,
        store = MemoryTrackingControls();
    final sync = LocationSyncService(
      repo,
      tracker,
      store,
      'https://api.example.invalid',
    );
    await expectLater(
      sync.enable(background: false),
      throwsA(isA<AuthFailure>()),
    );
    expect(repo.grants, 0);
    expect(tracker.starts, 0);
    expect(store.pending, true);
    await sync.close();
    await tracker.dispose();
  });
}
