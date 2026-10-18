import 'package:dio/dio.dart';

import 'generated/api_contract.dart';

enum ApiFailureKind {
  offline,
  timeout,
  unavailable,
  invalidResponse,
  cancelled,
}

final class ApiFailure implements Exception {
  const ApiFailure(this.kind, {this.requestId});
  final ApiFailureKind kind;
  final String? requestId;
}

final class ApiClient {
  ApiClient({required String origin, Dio? transport})
    : _dio =
          transport ??
          Dio(
            BaseOptions(
              baseUrl: origin,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              sendTimeout: const Duration(seconds: 5),
            ),
          );
  final Dio _dio;
  Future<HealthDto> readiness({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get<Object?>(
        '/health/ready',
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException();
      }
      return HealthDto.fromJson(data);
    } on DioException catch (error) {
      if (error.error is FormatException) {
        throw const ApiFailure(ApiFailureKind.invalidResponse);
      }
      if (CancelToken.isCancel(error)) {
        throw const ApiFailure(ApiFailureKind.cancelled);
      }
      final timeout = [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      ].contains(error.type);
      throw ApiFailure(
        timeout
            ? ApiFailureKind.timeout
            : error.response != null
            ? ApiFailureKind.unavailable
            : ApiFailureKind.offline,
        requestId: error.response?.headers.value('x-request-id'),
      );
    } on FormatException {
      throw const ApiFailure(ApiFailureKind.invalidResponse);
    }
  }

  void close() => _dio.close(force: true);
}
