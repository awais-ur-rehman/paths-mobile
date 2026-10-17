import 'dart:async';

import 'package:dio/dio.dart';

final class SessionTokens {
  const SessionTokens({required this.accessToken, required this.refreshToken});
  final String accessToken;
  final String refreshToken;
}

final class SessionUnavailable implements Exception {
  const SessionUnavailable();
}

/// Coordinates volatile credentials. The auth repository owns secure persistence,
/// server revocation policy and calls replace on every sign-in or sign-out.
final class RefreshCoordinator {
  RefreshCoordinator(this._refresh);
  final Future<SessionTokens> Function(String) _refresh;
  SessionTokens? _tokens;
  Future<SessionTokens>? _inFlight;
  int _generation = 0;

  SessionTokens? get tokens => _tokens;
  int get generation => _generation;

  void replace(SessionTokens? tokens) {
    _generation++;
    _tokens = tokens;
    _inFlight = null;
  }

  Future<SessionTokens> recover(String rejectedAccessToken) async {
    final current = _tokens;
    if (current == null) throw const SessionUnavailable();
    // A late response for an older token must reuse the already rotated session.
    if (current.accessToken != rejectedAccessToken) return current;
    final pending = _inFlight;
    if (pending != null) return pending;
    final generation = _generation;
    final future =
        Future<SessionTokens>.sync(() => _refresh(current.refreshToken))
            .then((rotated) {
              if (generation != _generation || !identical(current, _tokens)) {
                throw const SessionUnavailable();
              }
              _tokens = rotated;
              return rotated;
            });
    _inFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlight, future)) _inFlight = null;
    }
  }
}

/// Attach only to the authenticated API transport. Refresh uses a separate
/// transport so a rejected refresh cannot recursively enter this interceptor.
final class SessionRefreshInterceptor extends Interceptor {
  SessionRefreshInterceptor(this._dio, this._sessions)
    : _origin = Uri.parse(_dio.options.baseUrl).origin;
  final Dio _dio;
  final RefreshCoordinator _sessions;
  final String _origin;
  static const _replayed = 'paths.auth.replayed';
  static const _generation = 'paths.auth.generation';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final tokens = _sessions.tokens;
    final generation = options.extra[_generation];
    if (options.uri.origin != _origin ||
        tokens == null ||
        (generation != null && generation != _sessions.generation)) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: const SessionUnavailable(),
        ),
      );
      return;
    }
    options.followRedirects = false;
    options.extra[_generation] = _sessions.generation;
    options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final request = response.requestOptions;
    if (request.extra[_generation] != _sessions.generation) {
      handler.reject(
        DioException(
          requestOptions: request,
          type: DioExceptionType.cancel,
          error: const SessionUnavailable(),
        ),
      );
      return;
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (request.extra[_generation] != _sessions.generation) {
      handler.next(
        DioException(
          requestOptions: request,
          type: DioExceptionType.cancel,
          error: const SessionUnavailable(),
        ),
      );
      return;
    }
    final authorization = request.headers['Authorization'];
    if (err.response?.statusCode != 401 ||
        request.extra[_replayed] == true ||
        authorization is! String ||
        !authorization.startsWith('Bearer ') ||
        request.data is Stream ||
        request.cancelToken?.isCancelled == true) {
      handler.next(err);
      return;
    }
    try {
      await _sessions.recover(authorization.substring(7));
    } catch (_) {
      // Never expose the separate refresh request, which contains a refresh secret.
      handler.next(
        _sessions.generation == request.extra[_generation]
            ? err
            : DioException(
                requestOptions: request,
                type: DioExceptionType.cancel,
                error: const SessionUnavailable(),
              ),
      );
      return;
    }
    try {
      if (request.cancelToken?.isCancelled == true) {
        handler.next(request.cancelToken!.cancelError!);
        return;
      }
      final data = request.data;
      final response = await _dio.fetch<Object?>(
        request.copyWith(
          data: data is FormData ? data.clone() : data,
          extra: {...request.extra, _replayed: true},
        ),
      );
      handler.resolve(response);
    } on DioException catch (failure) {
      handler.next(failure);
    } catch (_) {
      // Keep the original unauthorized response; refresh errors may include secrets.
      handler.next(err);
    }
  }
}
