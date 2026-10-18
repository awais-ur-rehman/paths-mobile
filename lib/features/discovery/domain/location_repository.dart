import 'package:dio/dio.dart';

final class TrackingControl {
  const TrackingControl(this.consentEpoch, this.paused);
  final int consentEpoch;
  final bool paused;
}

final class LocationLease {
  const LocationLease(
    this.deviceSessionId,
    this.consentEpoch,
    this.uploadToken,
    this.expiresAt,
    this.serverTimeMs,
  );
  final String deviceSessionId, uploadToken;
  final int consentEpoch, serverTimeMs;
  final DateTime expiresAt;
}

abstract interface class LocationRepository {
  String? get currentTrackingAccountId;
  Future<TrackingControl> trackingState({CancelToken? cancelToken});
  Future<TrackingControl> pauseTracking(
    int expectedConsentEpoch, {
    CancelToken? cancelToken,
  });
  Future<LocationLease> createTrackingLease(
    int expectedConsentEpoch, {
    CancelToken? cancelToken,
  });
}

final class TrackingStop {
  const TrackingStop(this.accountId, this.epoch);
  final String accountId;
  final int epoch;
}

abstract interface class TrackingControlStore {
  Future<TrackingStop?> pendingControl();
  Future<bool> pendingStop();
  Future<void> setPendingStop(bool value, {TrackingStop? control});
}
