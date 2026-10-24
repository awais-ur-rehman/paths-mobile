import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/platform/location_tracker.dart';
import '../../auth/domain/auth_models.dart';
import '../data/location_sync_service.dart';

final class LocationState {
  const LocationState({
    this.status = TrackingStatus.stopped,
    this.permissions,
    this.queued = 0,
    this.pendingStop = false,
    this.busy = false,
    this.error,
    this.fix,
  });
  final TrackingStatus status;
  final TrackingPermissions? permissions;
  final int queued;
  final bool pendingStop, busy;
  final AuthFailure? error;
  final LocationSample? fix;
  LocationState copy({
    TrackingStatus? status,
    TrackingPermissions? permissions,
    int? queued,
    bool? pendingStop,
    bool? busy,
    AuthFailure? error,
    bool clearError = false,
    LocationSample? fix,
    bool clearFix = false,
  }) => LocationState(
    status: status ?? this.status,
    permissions: permissions ?? this.permissions,
    queued: queued ?? this.queued,
    pendingStop: pendingStop ?? this.pendingStop,
    busy: busy ?? this.busy,
    error: clearError ? null : error ?? this.error,
    fix: clearFix ? null : fix ?? this.fix,
  );
}

class LocationCubit extends Cubit<LocationState> {
  LocationCubit(this.sync) : super(const LocationState());
  final LocationSyncService sync;
  StreamSubscription<TrackingStatus>? _subscription;
  StreamSubscription<LocationSample>? _samples;
  int _generation = 0, _read = 0;
  Future<void> initialize() async {
    _subscription ??= sync.tracker.statusStream.listen((status) {
      if (!isClosed) {
        emit(
          state.copy(
            status: status,
            clearFix: [
              TrackingStatus.paused,
              TrackingStatus.stopped,
              TrackingStatus.permissionNeeded,
              TrackingStatus.unavailable,
            ].contains(status),
          ),
        );
        unawaited(_metadata(_generation));
      }
    });
    _samples ??= sync.tracker.sampleStream.listen((sample) {
      final now = DateTime.now();
      if (!isClosed &&
          state.permissions?.granted == true &&
          state.permissions?.servicesEnabled == true &&
          !state.pendingStop &&
          [
            TrackingStatus.active,
            TrackingStatus.background,
            TrackingStatus.inaccurate,
            TrackingStatus.offline,
          ].contains(state.status) &&
          sample.latitude.isFinite &&
          sample.longitude.isFinite &&
          sample.latitude.abs() <= 90 &&
          sample.longitude.abs() <= 180 &&
          !sample.capturedAt.isBefore(
            now.subtract(const Duration(minutes: 2)),
          ) &&
          !sample.capturedAt.isAfter(now.add(const Duration(seconds: 30)))) {
        emit(state.copy(fix: sample));
      }
    });
    await _run(sync.initialize);
  }

  Future<void> _metadata(int generation) async {
    final read = ++_read;
    try {
      final permissions = await sync.tracker.permissions(),
          queued = await sync.tracker.queueCount();
      final pending = await sync.controls.pendingStop();
      if (!isClosed && generation == _generation && read == _read) {
        emit(
          state.copy(
            permissions: permissions,
            queued: queued,
            pendingStop: pending,
            clearFix:
                !permissions.granted || !permissions.servicesEnabled || pending,
          ),
        );
      }
    } catch (_) {
      if (!isClosed && generation == _generation && read == _read) {
        emit(state.copy(error: const AuthFailure('location_unavailable')));
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (isClosed) return;
    final generation = ++_generation;
    emit(state.copy(busy: true, clearError: true));
    try {
      await action();
    } on AuthFailure catch (error) {
      if (!isClosed && generation == _generation) {
        emit(state.copy(error: error));
      }
    } catch (_) {
      if (!isClosed && generation == _generation) {
        emit(state.copy(error: const AuthFailure('location_unavailable')));
      }
    } finally {
      if (!isClosed && generation == _generation) {
        try {
          final status = await sync.tracker.currentStatus();
          if (!isClosed && generation == _generation) {
            emit(
              state.copy(
                status: status,
                clearFix: [
                  TrackingStatus.paused,
                  TrackingStatus.stopped,
                  TrackingStatus.permissionNeeded,
                  TrackingStatus.unavailable,
                ].contains(status),
              ),
            );
          }
        } catch (_) {
          if (!isClosed && generation == _generation) {
            emit(state.copy(error: const AuthFailure('location_unavailable')));
          }
        }
        await _metadata(generation);
        if (!isClosed && generation == _generation) {
          emit(state.copy(busy: false));
        }
      }
    }
  }

  Future<void> enable(bool background) => state.busy
      ? Future.value()
      : _run(() => sync.enable(background: background));
  Future<void> pause() => _run(sync.pause);
  Future<void> refresh() => state.busy ? Future.value() : _run(sync.retry);
  Future<void> openSettings() => _run(sync.tracker.openSettings);
  @override
  Future<void> close() async {
    _generation++;
    await _subscription?.cancel();
    await _samples?.cancel();
    await super.close();
  }
}
