import 'package:dio/dio.dart';

import '../../../core/network/generated/api_contract.dart';

final class ReviewDraft {
  const ReviewDraft({
    required this.kind,
    required this.content,
    this.conversationId,
    this.assetId,
  });
  final String kind, content;
  final String? conversationId, assetId;
}

abstract interface class ReviewRepository {
  String? get accountId;
  Future<ReviewUpdatePageDto> page({String? cursor, CancelToken? cancelToken});
  Future<void> submit(AppealInput input, {CancelToken? cancelToken});
}
