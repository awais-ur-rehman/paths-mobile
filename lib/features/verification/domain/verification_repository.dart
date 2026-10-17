import 'package:dio/dio.dart';

import '../../auth/domain/auth_models.dart';

final class VerificationInfo {
  const VerificationInfo({
    required this.status,
    required this.offerSeen,
    required this.uploadsAvailable,
    this.reason,
  });
  final String status;
  final bool offerSeen, uploadsAvailable;
  final String? reason;
}

enum DocumentSide { front, back }

final class DocumentAsset {
  const DocumentAsset(this.id, {required this.processed});
  final String id;
  final bool processed;
}

abstract interface class VerificationRepository {
  Future<VerificationInfo> loadVerification({CancelToken? cancelToken});
  Future<VerificationInfo> skipVerification({CancelToken? cancelToken});
  Future<VerificationInfo> submitVerification({
    required String frontAssetId,
    String? backAssetId,
    required bool consent,
    CancelToken? cancelToken,
  });
}

abstract interface class VerificationDocuments {
  Future<DocumentAsset?> pickAndUpload(
    DocumentSide side, {
    CancelToken? cancelToken,
  });
}

// Task8 must supply a protected picker/upload implementation before collecting any CNIC.
final class UnavailableVerificationDocuments implements VerificationDocuments {
  const UnavailableVerificationDocuments();
  @override
  Future<DocumentAsset?> pickAndUpload(
    DocumentSide side, {
    CancelToken? cancelToken,
  }) async => throw const AuthFailure('media_unavailable');
}
