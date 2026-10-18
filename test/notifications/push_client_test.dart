import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/authenticated_api.dart';
import 'package:paths_mobile/core/platform/push_client.dart';
import 'package:paths_mobile/features/notifications/data/notification_repository.dart';

class Api implements AuthenticatedApi {
  @override
  String? accountId = 'a';
  Completer<Map<String, dynamic>>? pending;
  int registrations = 0;
  @override
  Future<String> installationId() async => 'fixture-installation-1234';
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) async {
    registrations++;
    return pending == null
        ? {'id': 'registration', 'bindingId': 'binding', 'provider': 'fcm'}
        : pending!.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('paths/push');
  late Api api;
  late PushClient client;
  late List<String> calls;
  bool configured = true, granted = true, opted = true;
  int generation = 0;
  Completer<void>? registered;
  setUp(() async {
    api = Api();
    client = PushClient(channel: channel);
    calls = [];
    configured = true;
    granted = true;
    opted = true;
    generation = 0;
    registered = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'status':
              return {
                'configured': configured,
                'granted': granted,
                'optedIn': opted,
                'bound': true,
              };
            case 'token':
              return {'provider': 'fcm', 'token': 'fixture-token'};
            case 'nextGeneration':
              registered?.complete();
              return ++generation;
            case 'bind':
              return (call.arguments as Map)['generation'] == generation;
            case 'requestPermission':
              return granted;
            case 'clear':
              generation++;
              return null;
            default:
              return null;
          }
        });
    await client.initialize(NotificationRepository(api));
  });
  tearDown(() async {
    await client.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test(
    'unconfigured or opted-out installs do not fetch a token or register',
    () async {
      configured = false;
      await client.synchronize();
      expect(calls, isNot(contains('token')));
      configured = true;
      opted = false;
      await client.synchronize();
      expect(api.registrations, 0);
    },
  );
  test('explicit permission denial cannot register or bind', () async {
    granted = false;
    await expectLater(client.enable(), throwsA(anything));
    expect(api.registrations, 0);
    expect(calls, isNot(contains('bind')));
  });
  test('logout invalidates a registration that is still in flight', () async {
    api.pending = Completer();
    registered = Completer();
    final task = client.synchronize();
    await registered!.future;
    await Future<void>.delayed(Duration.zero);
    await client.clear();
    api.pending!.complete({'id': 'r', 'bindingId': 'old', 'provider': 'fcm'});
    await task;
    expect(calls, isNot(contains('bind')));
  });
  test('late registration from a different account cannot bind', () async {
    api.pending = Completer();
    registered = Completer();
    final task = client.synchronize();
    await registered!.future;
    api.accountId = 'b';
    api.pending!.complete({'id': 'r', 'bindingId': 'old', 'provider': 'fcm'});
    await task;
    expect(calls, isNot(contains('bind')));
  });
  test('successful opt-in binds only after backend registration', () async {
    await client.enable();
    expect(api.registrations, 1);
    expect(calls.indexOf('nextGeneration'), lessThan(calls.indexOf('bind')));
  });
}
