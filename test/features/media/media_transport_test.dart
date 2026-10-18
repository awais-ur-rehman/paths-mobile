import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/auth/data/http_auth_repository.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';

import '../auth/auth_repository_test.dart'
    show ApiAdapter, MemoryVault, MemoryPreferences;

class MediaAdapter extends ApiAdapter {
  final uploads = <List<int>>[];
  Completer<void>? imageStarted, imageRelease;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (!options.path.startsWith('/v1/media/')) {
      return super.fetch(options, stream, cancel);
    }
    if (options.method == 'PUT') {
      final bytes = <int>[];
      if (stream != null) {
        await for (final chunk in stream) {
          bytes.addAll(chunk);
        }
      }
      uploads.add(bytes);
      return ResponseBody.fromString(
        '{}',
        uploads.length == 1 ? 401 : 200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    imageStarted?.complete();
    await imageRelease?.future;
    return ResponseBody.fromBytes(
      [255, 216, 255, 217],
      200,
      headers: {
        'content-type': ['image/jpeg'],
      },
    );
  }
}

const asset = '11111111-1111-4111-8111-111111111111';
void main() {
  test('binary upload refresh replays the same bounded bytes once without serialization', () async {
    final adapter = MediaAdapter(),
        repo = HttpAuthRepository(
          origin: 'https://api.example.invalid',
          vault: MemoryVault(),
          preferences: MemoryPreferences(),
          publicTransport: Dio()..httpClientAdapter = adapter,
          authenticatedTransport: Dio()..httpClientAdapter = adapter,
        );
    await repo.login('fixture@example.invalid', 'fixture password');
    final bytes = Uint8List.fromList([255, 216, 255, 0, 1, 2]);
    await repo.uploadImage(asset, bytes);
    expect(adapter.refreshes, 1);
    expect(adapter.uploads, [bytes.toList(), bytes.toList()]);
    await repo.close();
  });
  test('logout wins over a delayed binary response and unsafe IDs never reach the transport', () async {
    final adapter = MediaAdapter()
          ..imageStarted = Completer()
          ..imageRelease = Completer(),
        repo = HttpAuthRepository(
          origin: 'https://api.example.invalid',
          vault: MemoryVault(),
          preferences: MemoryPreferences(),
          publicTransport: Dio()..httpClientAdapter = adapter,
          authenticatedTransport: Dio()..httpClientAdapter = adapter,
        );
    await repo.login('fixture@example.invalid', 'fixture password');
    await expectLater(
      repo.imageBytes('../../other'),
      throwsA(
        isA<AuthFailure>().having((e) => e.code, 'code', 'configuration'),
      ),
    );
    final pending = repo.imageBytes(asset);
    final result = expectLater(
      pending,
      throwsA(isA<AuthFailure>().having((e) => e.code, 'code', 'cancelled')),
    );
    await adapter.imageStarted!.future;
    await repo.logout();
    adapter.imageRelease!.complete();
    await result;
    await repo.close();
  });
}
