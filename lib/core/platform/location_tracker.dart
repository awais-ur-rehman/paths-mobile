import 'dart:async';

import 'package:flutter/services.dart';

enum TrackingStatus {
  stopped,
  active,
  background,
  paused,
  permissionNeeded,
  inaccurate,
  unavailable,
}

final class TrackingPolicy {
  const TrackingPolicy({
    required this.deviceSessionId,
    required this.consentEpoch,
    this.background = false,
    this.endpoint = '',
    this.testToken = '',
  });
  final String deviceSessionId;
  final int consentEpoch;
  final bool background;
  final String endpoint, testToken;
  Map<String, Object> toMap() => {
    'deviceSessionId': deviceSessionId,
    'consentEpoch': consentEpoch,
    'background': background,
    'policyVersion': 'adaptive.v1',
    'endpoint': endpoint,
    'testToken': testToken,
  };
}

final class LocationSample {
  const LocationSample({
    required this.sampleId,
    required this.deviceSessionId,
    required this.consentEpoch,
    required this.sequence,
    required this.capturedAt,
    required this.latitude,
    required this.longitude,
    required this.horizontalAccuracyM,
    required this.appState,
    required this.precisionMode,
    required this.policyVersion,
  });
  factory LocationSample.fromMap(Map<Object?, Object?> m) => LocationSample(
    sampleId: m['sampleId']! as String,
    deviceSessionId: m['deviceSessionId']! as String,
    consentEpoch: m['consentEpoch']! as int,
    sequence: m['sequence']! as int,
    capturedAt: DateTime.fromMillisecondsSinceEpoch(
      m['capturedAt']! as int,
      isUtc: true,
    ),
    latitude: (m['latitude']! as num).toDouble(),
    longitude: (m['longitude']! as num).toDouble(),
    horizontalAccuracyM: (m['horizontalAccuracyM']! as num).toDouble(),
    appState: m['appState']! as String,
    precisionMode: m['precisionMode']! as String,
    policyVersion: m['policyVersion']! as String,
  );
  final String sampleId,
      deviceSessionId,
      appState,
      precisionMode,
      policyVersion;
  final int consentEpoch, sequence;
  final DateTime capturedAt;
  final double latitude, longitude, horizontalAccuracyM;
  Map<String, Object> toMap() => {
    'sampleId': sampleId,
    'deviceSessionId': deviceSessionId,
    'consentEpoch': consentEpoch,
    'sequence': sequence,
    'capturedAt': capturedAt.millisecondsSinceEpoch,
    'latitude': latitude,
    'longitude': longitude,
    'horizontalAccuracyM': horizontalAccuracyM,
    'appState': appState,
    'precisionMode': precisionMode,
    'policyVersion': policyVersion,
  };
}

abstract interface class LocationTracker {
  Future<void> start(TrackingPolicy policy);
  Future<void> pause();
  Future<void> stopAndPurge();
  Stream<TrackingStatus> get statusStream;
  Stream<LocationSample> get sampleStream;
  Future<int> queueCount();
  Future<TrackingStatus> currentStatus();
  Future<List<LocationSample>> pendingSamples();
  Future<void> acknowledge(List<String> ids);
  Future<bool> requestForegroundPermission();
  Future<bool> requestBackgroundPermission();
  Future<void> openSettings();
  Future<void> dispose();
}

final class PlatformLocationTracker implements LocationTracker {
  PlatformLocationTracker({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('paths/location') {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'event') return;
      final event = call.arguments as Map<Object?, Object?>;
      final rawStatus = event['status'];
      if (rawStatus is String) {
        _statuses.add(
          TrackingStatus.values.firstWhere(
            (s) => s.name == rawStatus,
            orElse: () => TrackingStatus.unavailable,
          ),
        );
      }
      if (event['sample'] case final Map<Object?, Object?> raw) {
        final sample = LocationSample.fromMap(raw);
        final policy = _policy;
        if (policy != null &&
            sample.deviceSessionId == policy.deviceSessionId &&
            sample.consentEpoch == policy.consentEpoch) {
          _samples.add(sample);
        }
      }
    });
  }
  final MethodChannel _channel;
  final _statuses = StreamController<TrackingStatus>.broadcast();
  final _samples = StreamController<LocationSample>.broadcast();
  TrackingPolicy? _policy;
  @override
  Stream<TrackingStatus> get statusStream => _statuses.stream;
  @override
  Stream<LocationSample> get sampleStream => _samples.stream;
  @override
  Future<void> start(TrackingPolicy policy) async {
    if (policy.deviceSessionId.isEmpty || policy.consentEpoch < 1) {
      throw ArgumentError('Invalid tracking policy');
    }
    _policy = null;
    await _channel.invokeMethod<void>('start', policy.toMap());
    _policy = policy;
    _statuses.add(
      policy.background ? TrackingStatus.background : TrackingStatus.active,
    );
  }

  @override
  Future<void> pause() async {
    _policy = null;
    await _channel.invokeMethod<void>('pause');
    _statuses.add(TrackingStatus.paused);
  }

  @override
  Future<void> stopAndPurge() async {
    _policy = null;
    await _channel.invokeMethod<void>('stopAndPurge');
    _statuses.add(TrackingStatus.stopped);
  }

  @override
  Future<TrackingStatus> currentStatus() async {
    final raw = await _channel.invokeMethod<String>('status') ?? 'unavailable';
    final status = TrackingStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => TrackingStatus.unavailable,
    );
    if (status == TrackingStatus.stopped ||
        status == TrackingStatus.permissionNeeded ||
        status == TrackingStatus.unavailable) {
      _policy = null;
    }
    _statuses.add(status);
    return status;
  }

  @override
  Future<int> queueCount() async =>
      await _channel.invokeMethod<int>('queueCount') ?? 0;
  @override
  Future<List<LocationSample>> pendingSamples() async {
    final current = _policy;
    if (current == null) return const [];
    final raw =
        await _channel.invokeListMethod<Object?>('pendingSamples') ?? const [];
    if (_policy != current) return const [];
    final now = DateTime.now().toUtc();
    final result = raw
        .map((e) => LocationSample.fromMap(e! as Map<Object?, Object?>))
        .where(
          (s) =>
              s.consentEpoch == current.consentEpoch &&
              s.deviceSessionId == current.deviceSessionId &&
              now.difference(s.capturedAt) <= const Duration(minutes: 15) &&
              !s.capturedAt.isAfter(now.add(const Duration(seconds: 30))),
        )
        .toList(growable: false);
    return result;
  }

  @override
  Future<void> acknowledge(List<String> ids) =>
      _channel.invokeMethod<void>('acknowledge', ids);
  @override
  Future<bool> requestForegroundPermission() async =>
      await _channel.invokeMethod<bool>('requestForegroundPermission') ?? false;
  @override
  Future<bool> requestBackgroundPermission() async =>
      await _channel.invokeMethod<bool>('requestBackgroundPermission') ?? false;
  @override
  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');
  @override
  Future<void> dispose() async {
    await stopAndPurge();
    _channel.setMethodCallHandler(null);
    await _statuses.close();
    await _samples.close();
  }
}
