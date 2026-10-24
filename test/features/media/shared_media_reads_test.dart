import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/media/data/http_media_repository.dart';

import 'private_image_lifecycle_test.dart' show PictureFixture;

class PendingPhoto {
  PendingPhoto(this.id, this.token);
  final String id;
  final CancelToken? token;
  final result = Completer<Uint8List>();
}

class DelayedPhotos extends PictureFixture {
  final pending = <PendingPhoto>[];
  @override
  Future<Uint8List> imageBytes(
    String assetId, {
    bool thumbnail = true,
    CancelToken? cancelToken,
  }) {
    final request = PendingPhoto('$assetId:$thumbnail', cancelToken);
    pending.add(request);
    return request.result.future;
  }

  void finish() {
    for (final p in pending.where((p) => !p.result.isCompleted)) {
      p.result.complete(Uint8List.fromList([1, 2, 3]));
    }
  }
}

Future<void> turn() => Future<void>.delayed(Duration.zero);
final cancelled = throwsA(
  isA<AuthFailure>().having((e) => e.code, 'code', 'cancelled'),
);
void main() {
  test('duplicate media reads share transport but receive independent private buffers', () async {
    final api = DelayedPhotos();
    final actual = HttpMediaRepository(api, api);
    final a = actual.bytes('photo', cancelToken: CancelToken());
    final b = actual.bytes('photo', cancelToken: CancelToken());
    await turn();
    expect(api.pending.length, 1);
    final source = Uint8List.fromList([7, 8, 9]);
    api.pending.single.result.complete(source);
    final values = await Future.wait([a, b]);
    expect(values[0], [7, 8, 9]);
    expect(values[1], [7, 8, 9]);
    values[0].fillRange(0, 3, 0);
    expect(values[1], [7, 8, 9]);
    expect(source, [0, 0, 0]);
    actual.dispose();
  });
  test(
    'cancelling one subscriber cannot cancel the other photo consumer',
    () async {
      final api = DelayedPhotos(), first = CancelToken();
      final repo = HttpMediaRepository(api, api);
      final a = repo.bytes('photo', cancelToken: first);
      final rejected = expectLater(a, cancelled);
      final b = repo.bytes('photo', cancelToken: CancelToken());
      await turn();
      first.cancel();
      await turn();
      expect(api.pending.single.token!.isCancelled, false);
      api.finish();
      await rejected;
      expect(await b, [1, 2, 3]);
      repo.dispose();
    },
  );
  test('offscreen queued reads never start and cancelled active reads retain their slots', () async {
    final api = DelayedPhotos();
    final actual = HttpMediaRepository(api, api);
    final tokens = List.generate(12, (_) => CancelToken());
    final reads = [
      for (var i = 0; i < 12; i++)
        actual.bytes('photo$i', cancelToken: tokens[i]),
    ];
    final rejected = [for (final r in reads) expectLater(r, cancelled)];
    await turn();
    expect(api.pending.length, 4);
    for (final token in tokens) {
      token.cancel();
    }
    await turn();
    final next = actual.bytes('new', cancelToken: CancelToken());
    await turn();
    expect(api.pending.length, 4);
    api.finish();
    await turn();
    expect(api.pending.length, 5);
    api.finish();
    await Future.wait(rejected);
    expect(await next, [1, 2, 3]);
    actual.dispose();
  });
  test(
    'privacy purge rejects all subscribers and wipes late transport bytes',
    () async {
      final api = DelayedPhotos();
      final repo = HttpMediaRepository(api, api);
      final pending = repo.bytes('photo', cancelToken: CancelToken());
      final rejected = expectLater(pending, cancelled);
      await turn();
      await repo.purge();
      final source = Uint8List.fromList([5, 6]);
      api.pending.single.result.complete(source);
      await rejected;
      await turn();
      expect(source, [0, 0]);
      repo.dispose();
    },
  );
  test(
    'account change rejects late photos even without an explicit purge',
    () async {
      final api = DelayedPhotos();
      final repo = HttpMediaRepository(api, api);
      final pending = repo.bytes('photo', cancelToken: CancelToken());
      final rejected = expectLater(pending, cancelled);
      await turn();
      api.accountId = 'other';
      api.finish();
      await rejected;
      repo.dispose();
    },
  );
  test('20 switching waves share duplicate photos and keep transport pressure bounded', () async {
    final api = DelayedPhotos();
    final repo = HttpMediaRepository(api, api);
    for (var wave = 0; wave < 20; wave++) {
      final reads = [
        for (var i = 0; i < 10; i++)
          repo.bytes('photo${i % 6}', cancelToken: CancelToken()),
      ];
      for (var pass = 0; pass < 3; pass++) {
        await turn();
        api.finish();
      }
      final bytes = await Future.wait(reads);
      expect(bytes.every((b) => b.length == 3 && b[0] == 1), true);
    }
    expect(api.pending.length, 120);
    expect(repo.readStatistics.peak, 4);
    expect(repo.readStatistics.joined, 80);
    expect(repo.readStatistics.active, 0);
    repo.dispose();
  });
  test(
    'failed photo read can be retried and variants never share authorization',
    () async {
      final api = DelayedPhotos();
      final repo = HttpMediaRepository(api, api);
      final a = repo.bytes('photo', cancelToken: CancelToken());
      final error = expectLater(a, throwsA(isA<AuthFailure>()));
      await turn();
      api.pending.single.result.completeError(const AuthFailure('offline'));
      await error;
      final b = repo.bytes('photo', cancelToken: CancelToken());
      final c = repo.bytes(
        'photo',
        thumbnail: false,
        cancelToken: CancelToken(),
      );
      await turn();
      expect(api.pending.length, 3);
      api.finish();
      expect(await b, [1, 2, 3]);
      expect(await c, [1, 2, 3]);
      repo.dispose();
    },
  );
}
