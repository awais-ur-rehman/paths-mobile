import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/deletion_repository.dart';

class HttpDeletionRepository implements DeletionRepository {
  HttpDeletionRepository({
    required String origin,
    required this.store,
    required this.accountId,
    required this.token,
    required this.clearDevice,
    Dio? transport,
  }) : _http = transport ?? Dio() {
    _http.options = BaseOptions(
      baseUrl: origin,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 5),
      followRedirects: false,
    );
  }
  final DeletionStore store;
  final String? Function() accountId;
  final Future<String> Function() token;
  final Future<void> Function(String) clearDevice;
  final Dio _http;
  DeletionRecord? _latest;
  bool _submitting = false;
  @override
  Future<DeletionRecord?> saved() async {
    if (_latest != null) return _latest;
    try {
      final raw = await store.read();
      if (raw == null) return null;
      return _latest = DeletionRecord.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      throw const AuthFailure('storage');
    }
  }

  Future<void> _save(DeletionRecord value) async {
    _latest = value;
    try {
      await store.write(jsonEncode(value.toJson()));
    } catch (_) {
      throw const AuthFailure('storage');
    }
  }

  Future<DeletionReceiptDto> _send(
    String path,
    Map<String, dynamic> data, {
    String? access,
    CancelToken? cancelToken,
  }) async {
    try {
      final result = await _http.post<Object?>(
        '/v1/$path',
        data: data,
        cancelToken: cancelToken,
        options: Options(
          headers: access == null ? {} : {'Authorization': 'Bearer $access'},
        ),
      );
      if (result.data is! Map<String, dynamic>) throw const FormatException();
      return DeletionReceiptDto.fromJson(result.data! as Map<String, dynamic>);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) throw const AuthFailure('cancelled');
      final code = e.response?.data;
      throw AuthFailure(
        e.response?.statusCode == 404
            ? 'deletion_unconfirmed'
            : e.response == null
            ? 'offline'
            : code is Map && code['code'] is String
            ? code['code'] as String
            : 'unavailable',
      );
    } on FormatException {
      throw const AuthFailure('invalid_response');
    }
  }

  @override
  Future<DeletionRecord> submit(
    String password, {
    CancelToken? cancelToken,
  }) async {
    if (_submitting) throw const AuthFailure('cancelled');
    _submitting = true;
    try {
      final owner = accountId();
      if (owner == null) throw const AuthFailure('SESSION_INVALID');
      final previous = await saved();
      var pending = previous?.pending;
      if (pending != null && pending.owner != owner) {
        throw const AuthFailure('deletion_pending_account');
      }
      if (pending == null) {
        final random = Random.secure();
        pending = PendingDeletion(
          owner: owner,
          clientId: newIntentKey(),
          recoveryKey: base64UrlEncode(
            List.generate(32, (_) => random.nextInt(256)),
          ).replaceAll('=', ''),
        );
        await _save(DeletionRecord(pending: pending));
      }
      await _save(DeletionRecord(pending: pending));
      final access = await token();
      if (accountId() != owner) throw const AuthFailure('cancelled');
      final receipt = await _send(
        'me/deletion',
        DeleteAccountInput(
          clientId: pending.clientId,
          recoveryKey: pending.recoveryKey,
          password: password,
          confirmation: 'DELETE',
        ).toJson(),
        access: access,
        cancelToken: cancelToken,
      );
      final record = DeletionRecord(receipt: receipt, cleanupOwner: owner);
      try {
        await _save(record);
        return record;
      } on AuthFailure catch (e) {
        return DeletionRecord(receipt: receipt, cleanupOwner: owner, error: e);
      }
    } finally {
      _submitting = false;
    }
  }

  Future<DeletionRecord> _cleanup(DeletionRecord record) async {
    final owner = record.cleanupOwner;
    if (owner == null) return record;
    try {
      if (accountId() == null || accountId() == owner) await clearDevice(owner);
      final clean = DeletionRecord(
        receipt: record.receipt,
        dismissed: record.dismissed,
      );
      await _save(clean);
      return clean;
    } on AuthFailure catch (e) {
      return DeletionRecord(
        receipt: record.receipt,
        cleanupOwner: owner,
        error: e,
      );
    } catch (_) {
      return DeletionRecord(
        receipt: record.receipt,
        cleanupOwner: owner,
        error: const AuthFailure('storage'),
      );
    }
  }

  @override
  Future<DeletionRecord?> refresh({CancelToken? cancelToken}) async {
    final initial = await saved();
    if (initial == null) return null;
    DeletionRecord local = initial;
    try {
      if (local.receipt == null && local.pending != null) {
        final pending = local.pending!;
        final result = await _send(
          'public/deletion/recover',
          DeletionRecoveryInput(
            clientId: pending.clientId,
            recoveryKey: pending.recoveryKey,
          ).toJson(),
          cancelToken: cancelToken,
        );
        local = DeletionRecord(receipt: result, cleanupOwner: pending.owner);
        await _save(local);
      }
      if (local.receipt != null) {
        local = await _cleanup(local);
        if (local.cleanupOwner != null) return local;
        final result = await _send(
          'public/deletion/receipt',
          DeletionReceiptInput(receipt: local.receipt!.receipt).toJson(),
          cancelToken: cancelToken,
        );
        local = DeletionRecord(receipt: result, dismissed: local.dismissed);
        await _save(local);
      }
      return local;
    } on AuthFailure catch (e) {
      if (e.code == 'cancelled') rethrow;
      return DeletionRecord(
        receipt: local.receipt,
        pending: local.pending,
        cleanupOwner: local.cleanupOwner,
        dismissed: local.dismissed,
        error: e,
      );
    }
  }

  @override
  Future<void> dismiss() async {
    final local = await saved();
    if (local?.receipt == null || local!.cleanupOwner != null) {
      throw const AuthFailure('storage');
    }
    await _save(DeletionRecord(receipt: local.receipt, dismissed: true));
  }

  @override
  void close() => _http.close(force: true);
}
