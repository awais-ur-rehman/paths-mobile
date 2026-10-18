import 'package:dio/dio.dart';

import '../../../core/network/generated/api_contract.dart';

final class SafetyTarget {
  const SafetyTarget(
    this.subjectId, {
    this.kind = 'profile',
    this.contentId,
    this.alreadyBlocked = false,
  });
  final String subjectId, kind;
  final String? contentId;
  final bool alreadyBlocked;
}

abstract interface class SafetyRepository {
  String? get accountId;
  Stream<void> get changes;
  Future<void> block(String target, {CancelToken? cancelToken});
  Future<void> unblock(String target, {CancelToken? cancelToken});
  Future<BlockedPageDto> blocked({String? cursor, CancelToken? cancelToken});
  Future<ReportEvidenceDto> preparePost(
    ReportEvidenceInput input, {
    CancelToken? cancelToken,
  });
  Future<ReportMessagesPageDto> reportableMessages(
    String subject, {
    String? cursor,
    CancelToken? cancelToken,
  });
  Future<ReportReceiptDto> report(
    ReportInput input, {
    CancelToken? cancelToken,
  });
}
