import 'package:dio/dio.dart';

/// Two test participants only. Not the production auth or locations API.
abstract interface class ExperimentGateway {
  bool get enabled;
  Future<void> lease(String session, int epoch);
  Future<void> stop();
  Future<bool?> matched();
  void cancel();
  void dispose();
}

final class ExperimentApi implements ExperimentGateway {
  ExperimentApi({
    required String endpoint,
    required String token,
    Dio? transport,
  }) : enabled = endpoint.isNotEmpty && token.isNotEmpty,
       _dio =
           transport ??
           Dio(
             BaseOptions(
               baseUrl: endpoint,
               connectTimeout: const Duration(seconds: 5),
               receiveTimeout: const Duration(seconds: 5),
               sendTimeout: const Duration(seconds: 5),
               headers: {'Authorization': 'Bearer $token'},
             ),
           );
  final Dio _dio;
  @override
  final bool enabled;
  Map<String, Object>? _lease;
  CancelToken _cancel = CancelToken();
  @override
  void cancel() {
    _cancel.cancel();
    _cancel = CancelToken();
  }

  @override
  Future<void> lease(String session, int epoch) async {
    final uri = Uri.tryParse(_dio.options.baseUrl);
    if ((enabled &&
            (uri == null ||
                !uri.isAbsolute ||
                !uri.hasAuthority ||
                !['http', 'https'].contains(uri.scheme))) ||
        (!enabled &&
            (_dio.options.baseUrl.isNotEmpty ||
                _dio.options.headers['Authorization'] != 'Bearer '))) {
      throw ArgumentError(
        'Configure both a valid endpoint and test token, or neither',
      );
    }
    _lease = {'deviceSessionId': session, 'consentEpoch': epoch};
    if (enabled) {
      await _dio.post<Object>(
        '/lease',
        data: {'deviceSessionId': session, 'consentEpoch': epoch},
        cancelToken: _cancel,
      );
    }
  }

  @override
  Future<void> stop() async {
    final lease = _lease;
    if (enabled && lease != null) {
      await _dio.post<Object>('/stop', data: lease, cancelToken: _cancel);
      if (identical(_lease, lease)) _lease = null;
    }
  }

  @override
  Future<bool?> matched() async {
    if (!enabled) return null;
    final r = await _dio.get<Map<String, dynamic>>(
      '/summary',
      cancelToken: _cancel,
    );
    return r.data?['matched'] as bool?;
  }

  @override
  void dispose() {
    cancel();
    _dio.close(force: true);
  }
}
