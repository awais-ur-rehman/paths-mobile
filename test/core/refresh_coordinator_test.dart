import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/refresh_coordinator.dart';

class AuthAdapter implements HttpClientAdapter {
  AuthAdapter({this.alwaysUnauthorized = false, this.started, this.release});
  final Completer<void>? started;
  final Future<void>? release;
  final bool alwaysUnauthorized;
  int calls = 0;
  final counts = <String, int>{};
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    calls++;
    counts.update(options.path, (count) => count + 1, ifAbsent: () => 1);
    if (started != null && !started!.isCompleted) started!.complete();
    if (release != null) {
      await release;
    } else {
      await Future<void>.delayed(Duration.zero);
    }
    return ResponseBody.fromString(
      '{}',
      !alwaysUnauthorized &&
              options.headers['Authorization'] == 'Bearer new-access'
          ? 200
          : 401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const original = SessionTokens(
    accessToken: 'old-access',
    refreshToken: 'old-refresh',
  );
  const rotated = SessionTokens(
    accessToken: 'new-access',
    refreshToken: 'new-refresh',
  );
  test(
    'ten simultaneous 401s rotate once and replay every request once',
    () async {
      var refreshes = 0;
      final coordinator = RefreshCoordinator((token) async {
        expect(token, 'old-refresh');
        refreshes++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return rotated;
      })..replace(original);
      final adapter = AuthAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.invalid'))
        ..httpClientAdapter = adapter;
      dio.interceptors.add(SessionRefreshInterceptor(dio, coordinator));
      try {
        final responses = await Future.wait(
          List.generate(10, (i) => dio.get<Object?>('/private/$i')),
        );
        expect(responses.every((response) => response.statusCode == 200), true);
        expect(refreshes, 1);
        expect(adapter.calls, 20);
        expect(adapter.counts.values.every((count) => count == 2), true);
      } finally {
        dio.close(force: true);
      }
    },
  );
  test('a replayed 401 cannot refresh again', () async {
    var refreshes = 0;
    final coordinator = RefreshCoordinator((_) async {
      refreshes++;
      return rotated;
    })..replace(original);
    final adapter = AuthAdapter(alwaysUnauthorized: true);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.invalid'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(SessionRefreshInterceptor(dio, coordinator));
    try {
      await expectLater(
        dio.get<Object?>('/private'),
        throwsA(isA<DioException>()),
      );
      expect(refreshes, 1);
      expect(adapter.calls, 2);
    } finally {
      dio.close(force: true);
    }
  });
  test('logout invalidates a refresh already in flight', () async {
    final pending = Completer<SessionTokens>();
    final coordinator = RefreshCoordinator((_) => pending.future)
      ..replace(original);
    final result = coordinator.recover('old-access');
    final assertion = expectLater(result, throwsA(isA<SessionUnavailable>()));
    coordinator.replace(null);
    pending.complete(rotated);
    await assertion;
    expect(coordinator.tokens, null);
  });
  test('a newer sign-in cannot be overwritten by a stale refresh', () async {
    final pending = Completer<SessionTokens>();
    final coordinator = RefreshCoordinator((_) => pending.future)
      ..replace(original);
    final result = coordinator.recover('old-access');
    final assertion = expectLater(result, throwsA(isA<SessionUnavailable>()));
    coordinator.replace(
      const SessionTokens(
        accessToken: 'another-user',
        refreshToken: 'another-refresh',
      ),
    );
    pending.complete(rotated);
    await assertion;
    expect(coordinator.tokens?.accessToken, 'another-user');
  });
  test(
    'failed refresh is shared without looping or losing the current session',
    () async {
      var calls = 0;
      final coordinator = RefreshCoordinator((_) async {
        calls++;
        await Future<void>.delayed(Duration.zero);
        throw const SessionUnavailable();
      })..replace(original);
      final results = List.generate(
        10,
        (_) => expectLater(
          coordinator.recover('old-access'),
          throwsA(isA<SessionUnavailable>()),
        ),
      );
      await Future.wait(results);
      expect(calls, 1);
      expect(coordinator.tokens, original);
    },
  );
  test('an absolute foreign URL cannot receive session credentials', () async {
    final coordinator = RefreshCoordinator((_) async => rotated)
      ..replace(original);
    final adapter = AuthAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.invalid'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(SessionRefreshInterceptor(dio, coordinator));
    try {
      await expectLater(
        dio.get<Object?>('https://other.example.invalid/private'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 0);
    } finally {
      dio.close(force: true);
    }
  });
  test(
    'cancellation during refresh does not replay the cancelled request',
    () async {
      final started = Completer<void>();
      final pending = Completer<SessionTokens>();
      final coordinator = RefreshCoordinator((_) {
        started.complete();
        return pending.future;
      })..replace(original);
      final adapter = AuthAdapter();
      final cancel = CancelToken();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.invalid'))
        ..httpClientAdapter = adapter;
      dio.interceptors.add(SessionRefreshInterceptor(dio, coordinator));
      try {
        final response = dio.get<Object?>('/private', cancelToken: cancel);
        final assertion = expectLater(
          response,
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.cancel,
            ),
          ),
        );
        await started.future;
        cancel.cancel();
        pending.complete(rotated);
        await assertion;
        await Future<void>.delayed(Duration.zero);
        expect(adapter.calls, 1);
      } finally {
        dio.close(force: true);
      }
    },
  );
  test(
    'a request from an earlier sign-in cannot replay for a new account',
    () async {
      final coordinator = RefreshCoordinator((_) async => rotated)
        ..replace(original);
      final started = Completer<void>();
      final release = Completer<void>();
      final adapter = AuthAdapter(started: started, release: release.future);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.invalid'))
        ..httpClientAdapter = adapter;
      dio.interceptors.add(SessionRefreshInterceptor(dio, coordinator));
      try {
        // The transport completes on a later event turn, after this account change.
        final request = dio.get<Object?>('/private');
        await started.future;
        coordinator.replace(
          const SessionTokens(
            accessToken: 'another-user',
            refreshToken: 'another-refresh',
          ),
        );
        release.complete();
        await expectLater(
          request,
          throwsA(
            isA<DioException>().having(
              (e) => e.response,
              'old response excluded',
              null,
            ),
          ),
        );
        expect(adapter.calls, 1);
      } finally {
        dio.close(force: true);
      }
    },
  );
  for (final logout in [true, false]) {
    test(
      'successful old-account response is discarded after ${logout ? 'logout' : 'account switch'}',
      () async {
        final coordinator = RefreshCoordinator((_) async => rotated)
          ..replace(rotated);
        final started = Completer<void>();
        final release = Completer<void>();
        final adapter = AuthAdapter(started: started, release: release.future);
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.invalid'))
          ..httpClientAdapter = adapter;
        dio.interceptors.add(SessionRefreshInterceptor(dio, coordinator));
        try {
          final response = dio.get<Object?>('/private');
          final assertion = expectLater(
            response,
            throwsA(
              isA<DioException>()
                  .having((e) => e.type, 'type', DioExceptionType.cancel)
                  .having((e) => e.response, 'private response excluded', null),
            ),
          );
          await started.future;
          coordinator.replace(logout ? null : original);
          release.complete();
          await assertion;
          expect(adapter.calls, 1);
        } finally {
          dio.close(force: true);
        }
      },
    );
  }
  test(
    'a refresh transport failure never exposes the refresh request',
    () async {
      final coordinator = RefreshCoordinator((_) async {
        throw DioException(
          requestOptions: RequestOptions(
            path: '/auth/refresh',
            data: {'refreshToken': 'fixture-sensitive'},
          ),
        );
      })..replace(original);
      final adapter = AuthAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.invalid'))
        ..httpClientAdapter = adapter;
      dio.interceptors.add(SessionRefreshInterceptor(dio, coordinator));
      try {
        await expectLater(
          dio.get<Object?>('/private'),
          throwsA(
            isA<DioException>()
                .having(
                  (e) => e.requestOptions.path,
                  'original request',
                  '/private',
                )
                .having(
                  (e) => e.requestOptions.data,
                  'no refresh secret',
                  null,
                ),
          ),
        );
        expect(adapter.calls, 1);
      } finally {
        dio.close(force: true);
      }
    },
  );
}
