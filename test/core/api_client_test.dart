import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/api_client.dart';

class ResponseAdapter implements HttpClientAdapter {
  ResponseAdapter(this.body, this.status);
  final String body;
  final int status;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
      'x-request-id': ['fixture-request'],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  test('readiness decodes only the pinned contract', () async {
    final dio = Dio()
      ..httpClientAdapter = ResponseAdapter(
        '{"status":"ok","contractVersion":"1.10.0"}',
        200,
      );
    final api = ApiClient(origin: '', transport: dio);
    expect((await api.readiness()).contractVersion, '1.10.0');
    dio.httpClientAdapter = ResponseAdapter(
      '{"status":"ok","contractVersion":"other"}',
      200,
    );
    await expectLater(
      api.readiness(),
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.kind,
          'kind',
          ApiFailureKind.invalidResponse,
        ),
      ),
    );
    api.close();
  });
  test(
    'service errors preserve request ID without leaking response bodies',
    () async {
      final dio = Dio()
        ..httpClientAdapter = ResponseAdapter('{"private":"never echo"}', 503);
      final api = ApiClient(origin: '', transport: dio);
      await expectLater(
        api.readiness(),
        throwsA(
          isA<ApiFailure>()
              .having((e) => e.kind, 'kind', ApiFailureKind.unavailable)
              .having((e) => e.requestId, 'requestId', 'fixture-request'),
        ),
      );
      api.close();
    },
  );
  test(
    'malformed JSON is a contract failure rather than an offline result',
    () async {
      final dio = Dio()..httpClientAdapter = ResponseAdapter('{invalid', 200);
      final api = ApiClient(origin: '', transport: dio);
      try {
        await expectLater(
          api.readiness(),
          throwsA(
            isA<ApiFailure>().having(
              (e) => e.kind,
              'kind',
              ApiFailureKind.invalidResponse,
            ),
          ),
        );
      } finally {
        api.close();
      }
    },
  );
}
