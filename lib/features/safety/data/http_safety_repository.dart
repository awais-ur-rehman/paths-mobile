import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/safety_repository.dart';

final class HttpSafetyRepository implements SafetyRepository {
  HttpSafetyRepository(this.api, {required this.onAccessChanged});
  final AuthenticatedApi api;
  final Future<void> Function() onAccessChanged;
  final _changes = StreamController<void>.broadcast();
  bool _closed = false;
  @override
  String? get accountId => api.accountId;
  @override
  Stream<void> get changes => _changes.stream;
  void invalidate() {
    if (!_closed) _changes.add(null);
  }

  Future<T> _parse<T>(
    Future<Map<String, dynamic>> response,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      return parse(await response);
    } on FormatException {
      throw const AuthFailure('invalid_response');
    }
  }

  Future<void> _block(
    String target,
    bool value,
    CancelToken? cancelToken,
  ) async {
    final account = accountId;
    await _parse(
      api.request(
        value ? 'POST' : 'DELETE',
        '/v1/blocks/$target',
        cancelToken: cancelToken,
      ),
      BlockReceiptDto.fromJson,
    );
    if (_closed || account == null || account != accountId) {
      throw const AuthFailure('cancelled');
    }
    // Publish invalidation even if native pixel cleanup fails after the server commit.
    try {
      await onAccessChanged();
    } finally {
      invalidate();
    }
  }

  @override
  Future<void> block(String target, {CancelToken? cancelToken}) =>
      _block(target, true, cancelToken);
  @override
  Future<void> unblock(String target, {CancelToken? cancelToken}) =>
      _block(target, false, cancelToken);
  @override
  Future<BlockedPageDto> blocked({String? cursor, CancelToken? cancelToken}) =>
      _parse(
        api.request(
          'GET',
          Uri(
            path: '/v1/blocks',
            queryParameters: {'limit': '50', 'cursor': ?cursor},
          ).toString(),
          cancelToken: cancelToken,
        ),
        BlockedPageDto.fromJson,
      );
  @override
  Future<ReportEvidenceDto> preparePost(
    ReportEvidenceInput input, {
    CancelToken? cancelToken,
  }) => _parse(
    api.request(
      'POST',
      '/v1/reports/post-evidence',
      data: input.toJson(),
      cancelToken: cancelToken,
    ),
    ReportEvidenceDto.fromJson,
  );
  @override
  Future<ReportMessagesPageDto> reportableMessages(
    String subject, {
    String? cursor,
    CancelToken? cancelToken,
  }) => _parse(
    api.request(
      'GET',
      Uri(
        path: '/v1/reports/messages/$subject',
        queryParameters: {'limit': '20', 'cursor': ?cursor},
      ).toString(),
      cancelToken: cancelToken,
    ),
    ReportMessagesPageDto.fromJson,
  );
  @override
  Future<ReportReceiptDto> report(
    ReportInput input, {
    CancelToken? cancelToken,
  }) => _parse(
    api.request(
      'POST',
      '/v1/reports',
      data: input.toJson(),
      cancelToken: cancelToken,
    ),
    ReportReceiptDto.fromJson,
  );
  Future<void> close() async {
    _closed = true;
    await _changes.close();
  }
}
