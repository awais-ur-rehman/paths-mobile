import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/experiment/data/experiment_api.dart';

class TestTransport implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    calls.add(options);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('runbook loopback origin without a trailing slash leases and sends a scoped stop', () async {
    const endpoint = 'http://127.0.0.1:8787';
    final adapter = TestTransport();
    final transport = Dio(BaseOptions(baseUrl: endpoint))
      ..httpClientAdapter = adapter;
    final api = ExperimentApi(
      endpoint: endpoint,
      token: 'synthetic-test-key',
      transport: transport,
    );
    await api.lease('test-session', 123);
    await api.stop();
    expect(adapter.calls.map((c) => c.path), ['/lease', '/stop']);
    expect(adapter.calls.last.data, {
      'deviceSessionId': 'test-session',
      'consentEpoch': 123,
    });
    api.dispose();
  });
  test(
    'incomplete and unsupported endpoint configuration cannot start a lease',
    () async {
      final api = ExperimentApi(endpoint: '', token: 'synthetic-test-key');
      await expectLater(api.lease('session', 1), throwsArgumentError);
      api.dispose();
    },
  );
}
