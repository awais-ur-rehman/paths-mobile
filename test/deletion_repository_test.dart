import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/deletion/data/http_deletion_repository.dart';
import 'package:paths_mobile/features/deletion/domain/deletion_repository.dart';

class Store implements DeletionStore {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async {
    if (fail) throw StateError('Synthetic storage failure');
    value = next;
  }
}

class DeleteAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  bool offline = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    calls.add(options);
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'receipt': 'opaque',
        'state': 'pending',
        'acceptedAt': '2026-10-18T00:00:00Z',
        'backupExpiresAt': '2026-10-25T00:00:00Z',
        'completedAt': null,
      }),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('every attempted delete first persists recovery proof; storage failures cannot submit', () async {
    final store = Store()..fail = true, adapter = DeleteAdapter();
    final repo = HttpDeletionRepository(
      origin: 'https://api.example.invalid',
      store: store,
      accountId: () => 'owner',
      token: () async => 'access',
      clearDevice: (_) async {},
      transport: Dio()..httpClientAdapter = adapter,
    );
    for (var i = 0; i < 2; i++) {
      await expectLater(
        repo.submit('Fixture password 123'),
        throwsA(isA<Exception>()),
      );
    }
    expect(adapter.calls, isEmpty);
    repo.close();
  });
  test('lost-response retries reuse proof and never store the password or access token', () async {
    final store = Store(), adapter = DeleteAdapter()..offline = true;
    String? owner = 'owner';
    var cleaned = 0;
    final repo = HttpDeletionRepository(
      origin: 'https://api.example.invalid',
      store: store,
      accountId: () => owner,
      token: () async => 'private-access-token',
      clearDevice: (_) async {
        cleaned++;
      },
      transport: Dio()..httpClientAdapter = adapter,
    );
    await expectLater(
      repo.submit('Fixture password 123'),
      throwsA(isA<Exception>()),
    );
    final first = Map<String, dynamic>.from(adapter.calls.single.data as Map);
    expect(store.value, isNot(contains('password')));
    expect(store.value, isNot(contains('private-access-token')));
    adapter.offline = false;
    final accepted = await repo.submit('Fixture password 123');
    expect(accepted.accepted, isTrue);
    expect(adapter.calls.last.data['clientId'], first['clientId']);
    expect(adapter.calls.last.data['recoveryKey'], first['recoveryKey']);
    expect(cleaned, 0);
    owner = 'another-account';
    await repo.refresh();
    expect(cleaned, 0);
    expect((await repo.saved())?.cleanupOwner, isNull);
    repo.close();
  });
}
