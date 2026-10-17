import 'package:dio/dio.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';

class PostRepository {
  PostRepository(this.api);
  final AuthenticatedApi api;
  String? get accountId => api.accountId;
  Future<PostDto> create(
    String asset,
    String caption,
    String key, {
    CancelToken? cancelToken,
  }) async {
    try {
      return PostDto.fromJson(
        await api.request(
          'POST',
          '/v1/posts',
          data: PostInput(assetId: asset, caption: caption).toJson(),
          idempotencyKey: key,
          cancelToken: cancelToken,
        ),
      );
    } on FormatException {
      throw const AuthFailure('invalid_response');
    }
  }

  Future<PostPageDto> list(
    String owner, {
    String? cursor,
    CancelToken? cancelToken,
  }) async {
    try {
      return PostPageDto.fromJson(
        await api.request(
          'GET',
          Uri(
            path: '/v1/profiles/$owner/posts',
            queryParameters: {'cursor': ?cursor},
          ).toString(),
          cancelToken: cancelToken,
        ),
      );
    } on FormatException {
      throw const AuthFailure('invalid_response');
    }
  }

  Future<PostDto> read(String id, {CancelToken? cancelToken}) async {
    try {
      return PostDto.fromJson(
        await api.request('GET', '/v1/posts/$id', cancelToken: cancelToken),
      );
    } on FormatException {
      throw const AuthFailure('invalid_response');
    }
  }

  Future<void> remove(String id, {CancelToken? cancelToken}) async {
    await api.request('DELETE', '/v1/posts/$id', cancelToken: cancelToken);
  }
}
