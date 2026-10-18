import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/platform/location_tracker.dart';
import '../data/experiment_api.dart';

final class ExperimentState {
  const ExperimentState({
    this.status = 'Stopped',
    this.count = 0,
    this.busy = false,
    this.error,
    this.matched,
    this.remotePending = false,
  });
  final String status;
  final int count;
  final bool busy, remotePending;
  final String? error;
  final bool? matched;
}

final class ExperimentCubit extends Cubit<ExperimentState> {
  ExperimentCubit(this._tracker, this._api) : super(const ExperimentState());
  final LocationTracker _tracker;
  final ExperimentGateway _api;
  Timer? _timer;
  int _operation = 0;
  bool _refreshing = false;
  bool _running = false;
  bool _visible = true;
  Future<void> start({required bool background}) async {
    if (state.busy || _running) return;
    final operation = ++_operation;
    emit(const ExperimentState(busy: true, status: 'Requesting permission'));
    try {
      if (!await _tracker.requestForegroundPermission()) {
        if (operation == _operation && !isClosed) {
          emit(
            const ExperimentState(
              status: 'Permission needed',
              error: 'Precise location is required for this experiment. Existing app features will not depend on permission.',
            ),
          );
        }
        return;
      }
      if (background && !await _tracker.requestBackgroundPermission()) {
        if (operation == _operation && !isClosed) {
          emit(
            const ExperimentState(
              status: 'Background permission needed',
              error: 'Choose Always location in system settings, then retry. Foreground capture remains available.',
            ),
          );
        }
        return;
      }
      if (operation != _operation || isClosed) return;
      final random = Random.secure();
      final session = List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      final epoch = DateTime.now().microsecondsSinceEpoch;
      await _api.lease(session, epoch);
      if (operation != _operation || isClosed) return;
      await _tracker.start(
        TrackingPolicy(
          deviceSessionId: session,
          consentEpoch: epoch,
          background: background,
          endpoint: const String.fromEnvironment('PATHS_TEST_ENDPOINT'),
          testToken: const String.fromEnvironment('PATHS_TEST_TOKEN'),
        ),
      );
      if (operation != _operation || isClosed) {
        await _tracker.stopAndPurge();
        return;
      }
      _running = true;
      emit(
        ExperimentState(
          status: background ? 'Background best effort' : 'Foreground capture',
        ),
      );
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => refresh());
    } catch (_) {
      bool stopped = false, remoteStopped = false;
      try {
        await _tracker.stopAndPurge();
        stopped = true;
      } catch (_) {
        /* Report unconfirmed local stop below. */
      }
      try {
        await _api.stop();
        remoteStopped = true;
      } catch (_) {
        /* Retain lease for explicit retry. */
      }
      if (operation == _operation && !isClosed) {
        emit(
          ExperimentState(
            status: stopped ? 'Stopped' : 'Stop needs attention',
            remotePending: !remoteStopped,
            error: stopped
                ? 'Could not start. Check precise location, background permission and private server configuration.'
                : 'Native stop could not be confirmed. Disable location in system settings.',
          ),
        );
      }
    }
  }

  Future<void> refresh() async {
    if (_refreshing || !_visible || isClosed || state.busy) return;
    _refreshing = true;
    final operation = _operation;
    try {
      final nativeStatus = await _tracker.currentStatus();
      final count = await _tracker.queueCount();
      if (operation != _operation || isClosed) return;
      final active = [
        TrackingStatus.active,
        TrackingStatus.background,
        TrackingStatus.inaccurate,
      ].contains(nativeStatus);
      final wasRunning = _running;
      _running = active;
      emit(
        ExperimentState(
          status: nativeStatus.name,
          count: count,
          matched: state.matched,
          remotePending: state.remotePending,
        ),
      );
      try {
        if ((wasRunning && !active) || state.remotePending) await _api.stop();
        final matched = await _api.matched();
        if (operation == _operation && !isClosed) {
          emit(
            ExperimentState(
              status: nativeStatus.name,
              count: count,
              matched: matched,
            ),
          );
        }
      } catch (_) {
        if (operation == _operation && !isClosed) {
          emit(
            ExperimentState(
              status: nativeStatus.name,
              count: count,
              matched: state.matched,
              remotePending: !active,
              error: active
                  ? 'Private test server unavailable. Encrypted capture continues within the queue limits.'
                  : 'Stopped locally. Remote stop is pending; reconnect and tap Pause again.',
            ),
          );
        }
      }
    } catch (_) {
      _running = false;
      if (operation == _operation && !isClosed) {
        emit(
          const ExperimentState(
            status: 'Tracker unavailable',
            error: 'Native state could not be confirmed. Disable location in system settings and retry Pause.',
          ),
        );
      }
    } finally {
      _refreshing = false;
    }
  }

  void visibility(bool visible) {
    _visible = visible;
    if (visible) unawaited(refresh());
  }

  Future<void> stop({bool logout = false}) async {
    if (state.busy) return;
    ++_operation;
    _running = false;
    _timer?.cancel();
    _api.cancel();
    emit(ExperimentState(status: 'Stopping', count: state.count, busy: true));
    try {
      if (logout) {
        await _tracker.stopAndPurge();
      } else {
        await _tracker.pause();
      }
      try {
        await _api.stop();
        if (!isClosed) {
          emit(
            ExperimentState(
              status: logout ? 'Signed out · purged' : 'Paused · purged',
            ),
          );
        }
      } catch (_) {
        if (!isClosed) {
          emit(
            const ExperimentState(
              status: 'Stopped locally · purged',
              remotePending: true,
              error: 'Remote stop is pending. The offline server cannot yet know you paused. Reconnect and tap Pause again.',
            ),
          );
        }
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          const ExperimentState(
            status: 'Stop needs attention',
            error: 'Native stop could not be confirmed. Disable location in system settings, then reopen and retry.',
          ),
        );
      }
    }
  }

  Future<void> settings() async {
    try {
      await _tracker.openSettings();
    } catch (_) {
      if (!isClosed) {
        emit(
          const ExperimentState(
            error: 'Open Paths permissions in system settings.',
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    ++_operation;
    _timer?.cancel();
    _api.dispose();
    await _tracker.dispose();
    return super.close();
  }
}
