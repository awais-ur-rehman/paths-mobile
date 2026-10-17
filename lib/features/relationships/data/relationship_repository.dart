import 'package:dio/dio.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';

abstract interface class RelationshipRepository {
  String? get accountId;
  Future<RelationshipStatusDto> get(String id, {CancelToken? cancelToken});
  Future<RelationshipStatusDto> save(
    String id,
    bool value, {
    CancelToken? cancelToken,
  });
  Future<RelationshipStatusDto> act(
    String id,
    String action,
    String key, {
    String? resourceId,
    CancelToken? cancelToken,
  });
  Future<RelationshipPageDto> page(
    String box, {
    String? cursor,
    CancelToken? cancelToken,
  });
}

final class HttpRelationshipRepository implements RelationshipRepository {
  HttpRelationshipRepository(this.api);
  final AuthenticatedApi api;
  @override
  String? get accountId => api.accountId;
  Future<T> _parse<T>(
    Future<Map<String, dynamic>> request,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      return parse(await request);
    } on FormatException {
      throw const AuthFailure('invalid_response');
    }
  }

  @override
  Future<RelationshipStatusDto> get(String id, {CancelToken? cancelToken}) =>
      _parse(
        api.request(
          'GET',
          '/v1/relationships/${Uri.encodeComponent(id)}',
          cancelToken: cancelToken,
        ),
        RelationshipStatusDto.fromJson,
      );
  @override
  Future<RelationshipStatusDto> save(
    String id,
    bool value, {
    CancelToken? cancelToken,
  }) => _parse(
    api.request(
      value ? 'PUT' : 'DELETE',
      '/v1/likes/${Uri.encodeComponent(id)}',
      cancelToken: cancelToken,
    ),
    RelationshipStatusDto.fromJson,
  );
  @override
  Future<RelationshipStatusDto> act(
    String id,
    String action,
    String key, {
    String? resourceId,
    CancelToken? cancelToken,
  }) {
    final resource = Uri.encodeComponent(resourceId ?? '');
    final (method, path, data) = switch (action) {
      'request' => ('POST', '/v1/requests', <String, dynamic>{'targetId': id}),
      'accept' || 'decline' || 'cancel' when resourceId != null => (
        'POST',
        '/v1/requests/$resource/$action',
        null,
      ),
      'disconnect' when resourceId != null => (
        'DELETE',
        '/v1/connections/$resource',
        null,
      ),
      _ => throw const AuthFailure('invalid_response'),
    };
    return _parse(
      api.request(
        method,
        path,
        data: data,
        idempotencyKey: key,
        cancelToken: cancelToken,
      ),
      RelationshipStatusDto.fromJson,
    );
  }

  @override
  Future<RelationshipPageDto> page(
    String box, {
    String? cursor,
    CancelToken? cancelToken,
  }) {
    final path = switch (box) {
      'saved' => '/v1/likes',
      'incoming' || 'sent' => '/v1/requests',
      'connections' => '/v1/connections',
      _ => throw const AuthFailure('invalid_response'),
    };
    final uri = Uri(
      path: path,
      queryParameters: {
        if (box == 'incoming' || box == 'sent') 'box': box,
        'cursor': ?cursor,
      },
    );
    return _parse(
      api.request('GET', uri.toString(), cancelToken: cancelToken),
      RelationshipPageDto.fromJson,
    );
  }
}
