import 'dart:async';

import 'package:flutter/services.dart';

import '../../features/auth/domain/auth_models.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../network/generated/api_contract.dart';

final class PushStatus {
  const PushStatus({
    required this.configured,
    required this.granted,
    required this.optedIn,
    required this.bound,
  });
  final bool configured, granted, optedIn, bound;
  factory PushStatus.parse(Map<dynamic, dynamic> value) {
    if (value['configured'] is! bool ||
        value['granted'] is! bool ||
        value['optedIn'] is! bool ||
        value['bound'] is! bool) {
      throw const AuthFailure('invalid_response');
    }
    return PushStatus(
      configured: value['configured'] as bool,
      granted: value['granted'] as bool,
      optedIn: value['optedIn'] as bool,
      bound: value['bound'] as bool,
    );
  }
}

/// Native code owns OS resources; no access or refresh token crosses this channel.
class PushClient {
  PushClient({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('paths/push');
  final MethodChannel _channel;
  final _events = StreamController<String>.broadcast();
  Stream<String> get events => _events.stream;
  AuthFailure? lastFailure;
  NotificationRepository? _repository;
  int _epoch = 0;
  bool _closed = false;
  Future<void>? _sync;
  String? _pendingEvent;
  Future<void> initialize(NotificationRepository repository) async {
    _repository = repository;
    _channel.setMethodCallHandler((call) async {
      if (_closed) return;
      if (call.method == 'tokenChanged') {
        await resume();
      }
      if (call.method == 'tap' && call.arguments is String) {
        _pendingEvent = call.arguments as String;
        _events.add(_pendingEvent!);
      }
      if (call.method == 'received') {
        _events.add('');
      }
    });
    await _channel.invokeMethod<void>('configure', {
      'projectId': const String.fromEnvironment('PATHS_FIREBASE_PROJECT_ID'),
      'applicationId': const String.fromEnvironment('PATHS_FIREBASE_APP_ID'),
      'apiKey': const String.fromEnvironment('PATHS_FIREBASE_API_KEY'),
      'senderId': const String.fromEnvironment('PATHS_FIREBASE_SENDER_ID'),
      'apnsEnabled': const bool.fromEnvironment('PATHS_APNS_ENABLED'),
    });
  }

  Future<PushStatus> status() async => PushStatus.parse(
    await _channel.invokeMapMethod<dynamic, dynamic>('status') ?? {},
  );
  Future<void> enable() async {
    final current = await status();
    if (!current.configured) throw const AuthFailure('configuration');
    final granted =
        await _channel.invokeMethod<bool>('requestPermission') ?? false;
    if (!granted) throw const AuthFailure('push_permission');
    await synchronize(force: true);
  }

  Future<void> synchronize({bool force = false}) async {
    if (_sync != null) {
      await _sync;
      if (force && !_closed) await synchronize(force: true);
      return;
    }
    final operation = _register(force);
    _sync = operation;
    try {
      await operation;
    } finally {
      if (identical(_sync, operation)) _sync = null;
    }
  }

  Future<void> _register(bool force) async {
    final repository = _repository,
        epoch = _epoch,
        account = _repository?.accountId;
    if (_closed || repository == null || account == null) return;
    final current = await status();
    if (!current.configured ||
        !current.granted ||
        (!force && !current.optedIn)) {
      return;
    }
    final token = await _channel
        .invokeMapMethod<String, dynamic>('token')
        .timeout(const Duration(seconds: 15));
    if (token == null ||
        token['token'] is! String ||
        !['fcm', 'apns'].contains(token['provider'])) {
      throw const AuthFailure('invalid_response');
    }
    final installation = await repository.api.installationId();
    final generation = await _channel.invokeMethod<int>('nextGeneration');
    if (generation == null || generation < 1) {
      throw const AuthFailure('storage');
    }
    if (_closed || epoch != _epoch || account != repository.accountId) return;
    final device = await repository.register(
      DeviceInput(
        installationId: installation,
        generation: generation,
        provider: token['provider'] as String,
        token: token['token'] as String,
      ),
    );
    if (_closed || epoch != _epoch || account != repository.accountId) return;
    final bound = await _channel.invokeMethod<bool>('bind', {
      'bindingId': device.bindingId,
      'generation': generation,
    });
    if (bound != true) throw const AuthFailure('cancelled');
  }

  Future<void> resume() async {
    try {
      await synchronize();
      lastFailure = null;
    } catch (error) {
      lastFailure = error is AuthFailure
          ? error
          : const AuthFailure('push_registration');
    }
  }

  Future<String?> takeTap() async {
    final native = await _channel.invokeMethod<String>('pendingTap');
    final value = _pendingEvent ?? native;
    _pendingEvent = null;
    return value;
  }

  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');
  Future<void> clear() async {
    _epoch++;
    _pendingEvent = null;
    await _channel.invokeMethod<void>('clear');
  }

  Future<void> dispose() async {
    _closed = true;
    _epoch++;
    _channel.setMethodCallHandler(null);
    await _events.close();
  }
}
