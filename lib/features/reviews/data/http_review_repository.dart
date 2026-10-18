import 'package:dio/dio.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/review_repository.dart';

class HttpReviewRepository implements ReviewRepository {
  HttpReviewRepository(this.api);
  final AuthenticatedApi api;
  @override
  String? get accountId => api.accountId;
  @override
  Future<ReviewUpdatePageDto> page({
    String? cursor,
    CancelToken? cancelToken,
  }) async {
    try {
      return ReviewUpdatePageDto.fromJson(
        await api.request(
          'GET',
          Uri(
            path: '/v1/me/review-updates',
            queryParameters: {'cursor': ?cursor},
          ).toString(),
          cancelToken: cancelToken,
        ),
      );
    } on FormatException {
      throw const AuthFailure('invalid_response');
    }
  }

  @override
  Future<void> submit(AppealInput input, {CancelToken? cancelToken}) async {
    try {
      ReportReceiptDto.fromJson(
        await api.request(
          'POST',
          '/v1/me/content-appeals',
          data: input.toJson(),
          cancelToken: cancelToken,
        ),
      );
    } on FormatException {
      throw const AuthFailure('invalid_response');
    }
  }
}
