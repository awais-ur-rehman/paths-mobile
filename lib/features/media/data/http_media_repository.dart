import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/shared_read_queue.dart';
import '../../../core/network/authenticated_media_api.dart';
import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../../profile/domain/profile_repository.dart';
import '../domain/media_repository.dart';

class HttpMediaRepository extends ChangeNotifier implements MediaRepository {
  HttpMediaRepository(this.api, this.binary) {
    if (api is AuthenticatedAccountChanges) {
      _accounts = (api as AuthenticatedAccountChanges).accountChanges.listen(
        (_) => _synchronizeAccount(),
      );
    }
  }
  StreamSubscription<String?>? _accounts;
  void _synchronizeAccount() {
    if (_readAccount == accountId) return;
    _reads.clear();
    _readAccount = accountId;
  }

  final AuthenticatedApi api;
  final AuthenticatedMediaApi binary;
  String? _readAccount;
  late final _reads = SharedReadQueue<(String, String, bool), Uint8List>(
    load: (key, token) async {
      _synchronizeAccount();
      if (key.$1 != accountId || token.isCancelled) {
        throw const AuthFailure('cancelled');
      }
      final bytes = await binary.imageBytes(
        key.$2,
        thumbnail: key.$3,
        cancelToken: token,
      );
      _synchronizeAccount();
      if (key.$1 != accountId || token.isCancelled) {
        bytes.fillRange(0, bytes.length, 0);
        throw const AuthFailure('cancelled');
      }
      return bytes;
    },
    copy: Uint8List.fromList,
    release: (bytes) => bytes.fillRange(0, bytes.length, 0),
  );
  ({int active, int queued, int peak, int started, int joined, int cancelled})
  get readStatistics => _reads.statistics;
  @override
  String? get accountId => api.accountId;
  MediaAsset _asset(Map<String, dynamic> json) {
    try {
      final a = AssetDto.fromJson(json);
      return MediaAsset(a.id, a.processingState, a.safetyState);
    } on FormatException {
      throw const AuthFailure('invalid_response');
    }
  }

  @override
  Future<MediaAsset> intent(
    MediaKind kind,
    PickedPhoto photo,
    String key, {
    CancelToken? cancelToken,
  }) async => _asset(
    await api.request(
      'POST',
      '/v1/media/intents',
      idempotencyKey: key,
      cancelToken: cancelToken,
      data: UploadIntentInput(
        kind: switch (kind) {
          MediaKind.cnicFront => 'cnic_front',
          MediaKind.cnicBack => 'cnic_back',
          _ => kind.name,
        },
        mimeType: photo.mimeType,
        sizeBytes: photo.bytes.length,
        sha256: sha256.convert(photo.bytes).toString(),
      ).toJson(),
    ),
  );
  @override
  Future<void> upload(
    String id,
    PickedPhoto photo, {
    CancelToken? cancelToken,
    ProgressCallback? onProgress,
  }) => binary.uploadImage(
    id,
    photo.bytes,
    cancelToken: cancelToken,
    onProgress: onProgress,
  );
  @override
  Future<MediaAsset> complete(String id, {CancelToken? cancelToken}) async =>
      _asset(
        await api.request(
          'POST',
          '/v1/media/$id/complete',
          cancelToken: cancelToken,
        ),
      );
  @override
  Future<MediaAsset> status(String id, {CancelToken? cancelToken}) async =>
      _asset(
        await api.request('GET', '/v1/media/$id', cancelToken: cancelToken),
      );
  @override
  Future<void> cancel(String id) async {
    await api.request('DELETE', '/v1/media/$id');
  }

  Future<Uint8List> bytes(
    String id, {
    bool thumbnail = true,
    required CancelToken cancelToken,
  }) async {
    final account = accountId;
    _synchronizeAccount();
    if (account == null) throw const AuthFailure('cancelled');
    return _reads.read(
      (account, id, thumbnail),
      cancelToken: cancelToken,
      priority:
          api is OwnProfileSnapshotRepository &&
          (api as OwnProfileSnapshotRepository)
                  .cachedOwnProfile
                  ?.avatarAssetId ==
              id,
    );
  }

  Future<void> purge() async {
    _reads.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_accounts?.cancel());
    _reads.dispose();
    super.dispose();
  }
}
