import 'package:dio/dio.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';

final class PendingDeletion {
  const PendingDeletion({
    required this.owner,
    required this.clientId,
    required this.recoveryKey,
  });
  final String owner, clientId, recoveryKey;
  Map<String, dynamic> toJson() => {
    'owner': owner,
    'clientId': clientId,
    'recoveryKey': recoveryKey,
  };
  factory PendingDeletion.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'],
        id = json['clientId'],
        key = json['recoveryKey'];
    if (owner is! String ||
        id is! String ||
        key is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(key)) {
      throw const FormatException();
    }
    return PendingDeletion(owner: owner, clientId: id, recoveryKey: key);
  }
}

final class DeletionRecord {
  const DeletionRecord({
    this.pending,
    this.receipt,
    this.cleanupOwner,
    this.dismissed = false,
    this.error,
  });
  final PendingDeletion? pending;
  final DeletionReceiptDto? receipt;
  final String? cleanupOwner;
  final bool dismissed;
  final AuthFailure? error;
  bool get accepted => receipt != null;
  bool get shouldResume =>
      pending != null || cleanupOwner != null || receipt != null && !dismissed;
  Map<String, dynamic> toJson() => {
    'pending': pending?.toJson(),
    'receipt': receipt?.toJson(),
    'cleanupOwner': cleanupOwner,
    'dismissed': dismissed,
  };
  factory DeletionRecord.fromJson(Map<String, dynamic> json) => DeletionRecord(
    pending: json['pending'] == null
        ? null
        : PendingDeletion.fromJson(json['pending'] as Map<String, dynamic>),
    receipt: json['receipt'] == null
        ? null
        : DeletionReceiptDto.fromJson(json['receipt'] as Map<String, dynamic>),
    cleanupOwner: json['cleanupOwner'] as String?,
    dismissed: json['dismissed'] == true,
  );
}

abstract interface class DeletionStore {
  Future<String?> read();
  Future<void> write(String value);
}

abstract interface class DeletionRepository {
  Future<DeletionRecord?> saved();
  Future<DeletionRecord> submit(String password, {CancelToken? cancelToken});
  Future<DeletionRecord?> refresh({CancelToken? cancelToken});
  Future<void> dismiss();
  void close();
}

abstract interface class ProviderDeletionRepository {
  Future<DeletionRecord> submitWithProof(
    String proof, {
    CancelToken? cancelToken,
  });
}
