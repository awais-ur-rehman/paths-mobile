import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/platform/location_tracker.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/location_repository.dart';

// Native owns encrypted batching. Controls persist only non-secret account/epoch metadata.
class LocationSyncService {
  LocationSyncService(
    this.repository,
    this.tracker,
    this.controls,
    this.origin,
  );
  final LocationRepository repository;
  final LocationTracker tracker;
  final TrackingControlStore controls;
  final String origin;
  int _generation = 0;
  bool _closed = false, _mayHaveLease = false;
  TrackingStop? _scope;
  CancelToken? _request;
  Future<void> _tail = Future.value(), _storageTail = Future.value();
  bool _current(int generation) => !_closed && generation == _generation;
  Future<void> _persist(bool value, {int? generation, TrackingStop? scope}) {
    final control = scope ?? _scope;
    final next = _storageTail.then((_) async {
      if (!value && generation != null && !_current(generation)) return;
      await controls.setPendingStop(value, control: value ? control : null);
    });
    _storageTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<void> _serial(Future<void> Function() action) {
    final next = _tail.then((_) => action());
    _tail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<TrackingControl> _pauseRemote(
    CancelToken token,
    int generation, {
    required bool freshIntent,
  }) async {
    final persisted = await controls.pendingControl();
    if (!freshIntent && persisted != null) {
      if (persisted.accountId != repository.currentTrackingAccountId) {
        await _persist(false, generation: generation);
        return TrackingControl(persisted.epoch, true);
      }
      try {
        final result = await repository.pauseTracking(
          persisted.epoch,
          cancelToken: token,
        );
        if (!_current(generation)) throw const AuthFailure('cancelled');
        await _persist(false, generation: generation);
        _scope = TrackingStop(persisted.accountId, result.consentEpoch);
        return result;
      } on AuthFailure catch (error) {
        if (error.code != 'CONFLICT') rethrow;
        await _persist(false, generation: generation);
        return TrackingControl(persisted.epoch, true);
      }
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      if (!_current(generation)) throw const AuthFailure('cancelled');
      final account = repository.currentTrackingAccountId;
      if (account == null) throw const AuthFailure('SESSION_INVALID');
      final state = await repository.trackingState(cancelToken: token);
      try {
        final paused = await repository.pauseTracking(
          state.consentEpoch,
          cancelToken: token,
        );
        if (!_current(generation)) throw const AuthFailure('cancelled');
        _scope = TrackingStop(account, paused.consentEpoch);
        await _persist(false, generation: generation);
        return paused;
      } on AuthFailure catch (error) {
        if (error.code != 'CONFLICT' || attempt == 1) rethrow;
      }
    }
    throw const AuthFailure('CONFLICT');
  }

  Future<void> stopLocalAndMarkPending({bool forcePending = true}) async {
    _generation++;
    _request?.cancel();
    final stopped = tracker.pause();
    final pending = () async {
      if (forcePending || _mayHaveLease || await controls.pendingStop()) {
        await _persist(true);
      }
    }();
    await Future.wait([stopped, pending]);
  }

  Future<void> eraseDeletedAccount(String owner) async {
    final current = repository.currentTrackingAccountId;
    if (current != null && current != owner) return;
    _generation++;
    _request?.cancel();
    await tracker.stopAndPurge();
    _scope = null;
    _mayHaveLease = false;
    await _persist(false);
  }

  Future<void> initialize() async {
    if (!await controls.pendingStop()) {
      await tracker.flushPending();
      return;
    }
    final scope = await controls.pendingControl();
    if (scope == null) {
      await tracker.pause();
      return;
    }
    final generation = ++_generation;
    await _serial(() async {
      if (!_current(generation)) return;
      final token = _request = CancelToken();
      await _pauseRemote(token, generation, freshIntent: false);
    });
  }

  Future<void> enable({required bool background}) {
    final generation = ++_generation;
    _request?.cancel();
    return _serial(() async {
      if (!_current(generation)) return;
      final token = _request = CancelToken();
      try {
        await tracker.pause();
        await _persist(true);
        if (!await tracker.requestForegroundPermission()) {
          throw const AuthFailure('location_permission');
        }
        var useBackground = background;
        if (useBackground && !await tracker.requestBackgroundPermission()) {
          useBackground = false;
        }
        final paused = await _pauseRemote(token, generation, freshIntent: true);
        if (!_current(generation)) return;
        final account = repository.currentTrackingAccountId;
        _mayHaveLease = true;
        final lease = await repository.createTrackingLease(
          paused.consentEpoch,
          cancelToken: token,
        );
        if (!_current(generation)) return;
        final lifetime =
            lease.expiresAt.millisecondsSinceEpoch - lease.serverTimeMs;
        if (lifetime <= 0 ||
            lifetime > const Duration(hours: 24, minutes: 1).inMilliseconds ||
            account == null) {
          throw const AuthFailure('invalid_response');
        }
        _scope = TrackingStop(account, lease.consentEpoch);
        await tracker.start(
          TrackingPolicy(
            deviceSessionId: lease.deviceSessionId,
            consentEpoch: lease.consentEpoch,
            background: useBackground,
            endpoint: '${origin.replaceAll(RegExp(r'/$'), '')}/v1/locations',
            uploadToken: lease.uploadToken,
            uploadMode: 'production',
            expiresAtMs: DateTime.now().millisecondsSinceEpoch + lifetime,
          ),
        );
        if (!_current(generation)) {
          await tracker.pause();
          return;
        }
        await _persist(false, generation: generation);
      } on AuthFailure catch (error) {
        if (!_current(generation) || error.code == 'cancelled') return;
        await tracker.pause();
        await _persist(true);
        rethrow;
      } catch (_) {
        if (!_current(generation)) return;
        await tracker.pause();
        await _persist(true);
        throw const AuthFailure('location_unavailable');
      }
    });
  }

  Future<void> pause() async {
    final stopped = stopLocalAndMarkPending();
    final generation = _generation;
    await stopped;
    await _serial(() async {
      if (!_current(generation)) return;
      final token = _request = CancelToken();
      await _pauseRemote(token, generation, freshIntent: false);
    });
  }

  Future<void> retry() async {
    if (await controls.pendingStop()) {
      await initialize();
    } else {
      await tracker.flushPending();
    }
  }

  Future<void> close() async {
    _closed = true;
    _generation++;
    _request?.cancel();
    await _tail;
    await _storageTail;
  }
}
