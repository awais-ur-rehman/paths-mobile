import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/shared_read_queue.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';

void main() {
  test('cancellation after completion but before dispatch rejects only cancelled subscriber', () async {
    final source = Completer<int>(), token = CancelToken();
    final queue = SharedReadQueue<String, int>(
      load: (_, _) => source.future,
      copy: (x) => x,
    );
    final a = queue.read('same', cancelToken: token), b = queue.read('same');
    final rejected = expectLater(
      a,
      throwsA(isA<AuthFailure>().having((e) => e.code, 'code', 'cancelled')),
    );
    source.complete(7);
    token.cancel();
    await rejected;
    expect(await b, 7);
    queue.dispose();
  });
  test(
    'already cancelled queued subscriber never starts a transport',
    () async {
      final first = Completer<int>(),
          token = CancelToken(),
          started = <String>[];
      final queue = SharedReadQueue<String, int>(
        concurrency: 1,
        load: (key, _) {
          started.add(key);
          return key == 'first' ? first.future : Future.value(2);
        },
        copy: (x) => x,
      );
      final a = queue.read('first'),
          b = queue.read('cancelled', cancelToken: token);
      final rejected = expectLater(b, throwsA(isA<AuthFailure>()));
      first.complete(1);
      token.cancel();
      expect(await a, 1);
      await rejected;
      expect(started, ['first']);
      queue.dispose();
    },
  );
}
