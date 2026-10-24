import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/platform/location_tracker.dart';
import 'package:paths_mobile/features/experiment/data/experiment_api.dart';
import 'package:paths_mobile/features/experiment/presentation/experiment_cubit.dart';

class TestTracker implements LocationTracker {
  TrackingStatus status = TrackingStatus.stopped;
  bool granted = true;
  bool backgroundGranted = true;
  bool failStart = false;
  int count = 0, starts = 0;
  final uploads = StreamController<void>.broadcast();
  @override
  Stream<void> get uploadStream => uploads.stream;
  final statuses = StreamController<TrackingStatus>.broadcast();
  final samples = StreamController<LocationSample>.broadcast();
  @override
  Future<void> start(TrackingPolicy p) async {
    if (failStart) throw StateError('native failure');
    starts++;
    status = TrackingStatus.active;
  }

  @override
  Future<void> pause() async {
    status = TrackingStatus.paused;
    count = 0;
  }

  @override
  Future<void> stopAndPurge() async {
    status = TrackingStatus.stopped;
    count = 0;
  }

  @override
  Future<TrackingStatus> currentStatus() async => status;
  @override
  Future<TrackingPermissions> permissions() async => TrackingPermissions(
    granted: granted,
    precise: granted,
    backgroundAllowed: backgroundGranted,
    servicesEnabled: true,
  );
  @override
  Future<void> flushPending() async {}
  @override
  Future<int> queueCount() async => count;
  @override
  Future<List<LocationSample>> pendingSamples() async => [];
  @override
  Future<void> acknowledge(List<String> ids) async {}
  @override
  Future<bool> requestForegroundPermission() async => granted;
  @override
  Future<bool> requestBackgroundPermission() async => backgroundGranted;
  @override
  Future<void> openSettings() async {}
  @override
  Stream<TrackingStatus> get statusStream => statuses.stream;
  @override
  Stream<LocationSample> get sampleStream => samples.stream;
  @override
  Future<void> dispose() async {
    await stopAndPurge();
    await uploads.close();
    await statuses.close();
    await samples.close();
  }
}

class TestGateway implements ExperimentGateway {
  bool offline = false;
  int stops = 0, leases = 0;
  @override
  bool get enabled => true;
  @override
  Future<void> lease(String s, int e) async {
    leases++;
  }

  @override
  Future<void> stop() async {
    stops++;
    if (offline) throw StateError('offline');
  }

  @override
  Future<bool?> matched() async {
    if (offline) throw StateError('offline');
    return false;
  }

  @override
  void cancel() {}
  @override
  void dispose() {}
}

void main() {
  test(
    'native stop is visible while offline and capture can be restarted',
    () async {
      final tracker = TestTracker();
      final api = TestGateway();
      final cubit = ExperimentCubit(tracker, api);
      await cubit.start(background: false);
      tracker.status = TrackingStatus.stopped;
      api.offline = true;
      await cubit.refresh();
      expect(cubit.state.status, 'stopped');
      expect(cubit.state.remotePending, true);
      expect(api.stops, 1);
      api.offline = false;
      await cubit.start(background: false);
      expect(tracker.starts, 2);
      await cubit.close();
    },
  );
  test('native failure after remote lease revokes it and purges', () async {
    final tracker = TestTracker()..failStart = true;
    final api = TestGateway();
    final cubit = ExperimentCubit(tracker, api);
    await cubit.start(background: false);
    expect(api.leases, 1);
    expect(api.stops, 1);
    expect(tracker.count, 0);
    expect(cubit.state.busy, false);
    await cubit.close();
  });
  test('denied foreground or deferred background permission does not start capture', () async {
    final tracker = TestTracker()..granted = false;
    final api = TestGateway();
    final cubit = ExperimentCubit(tracker, api);
    await cubit.start(background: false);
    expect(api.leases, 0);
    expect(tracker.starts, 0);
    tracker.granted = true;
    tracker.backgroundGranted = false;
    await cubit.start(background: true);
    expect(tracker.starts, 0);
    expect(api.leases, 0);
    expect(cubit.state.status, 'Background permission needed');
    await cubit.close();
  });
  test(
    'offline pause purges locally, retains remote-pending state and retries',
    () async {
      final tracker = TestTracker();
      final api = TestGateway();
      final cubit = ExperimentCubit(tracker, api);
      await cubit.start(background: false);
      tracker.count = 5;
      api.offline = true;
      await cubit.stop();
      expect(tracker.count, 0);
      expect(cubit.state.remotePending, true);
      api.offline = false;
      await cubit.stop();
      expect(cubit.state.remotePending, false);
      expect(api.stops, 2);
      await cubit.close();
    },
  );
}
