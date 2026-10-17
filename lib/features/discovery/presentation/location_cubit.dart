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
  });
  final TrackingStatus status;
  final TrackingPermissions? permissions;
  final int queued;
  final bool pendingStop, busy;
  final AuthFailure? error;
  LocationState copy({
    TrackingStatus? status,
    TrackingPermissions? permissions,
    int? queued,
    bool? pendingStop,
    bool? busy,
    AuthFailure? error,
    bool clearError = false,
  }) => LocationState(
    status: status ?? this.status,
    permissions: permissions ?? this.permissions,
    queued: queued ?? this.queued,
    pendingStop: pendingStop ?? this.pendingStop,
    busy: busy ?? this.busy,
    error: clearError ? null : error ?? this.error,
  );
}

class LocationCubit extends Cubit<LocationState> {
  LocationCubit(this.sync) : super(const LocationState());
  final LocationSyncService sync;
  StreamSubscription<TrackingStatus>? _subscription;
  int _generation = 0, _read = 0;
  Future<void> initialize() async {
    _subscription ??= sync.tracker.statusStream.listen((status) {
      if (!isClosed) {
        emit(state.copy(status: status));
        unawaited(_metadata(_generation));
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
            emit(state.copy(status: status));
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
    await super.close();
  }
}
