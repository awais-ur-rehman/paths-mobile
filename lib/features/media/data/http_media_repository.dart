import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/authenticated_media_api.dart';
import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/media_repository.dart';

class HttpMediaRepository extends ChangeNotifier implements MediaRepository {
  HttpMediaRepository(this.api, this.binary);
  final AuthenticatedApi api;
  final AuthenticatedMediaApi binary;
  final _reads = <CancelToken>{};
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
    _reads.add(cancelToken);
    try {
      return await binary.imageBytes(
        id,
        thumbnail: thumbnail,
        cancelToken: cancelToken,
      );
    } finally {
      _reads.remove(cancelToken);
    }
  }

  Future<void> purge() async {
    for (final token in _reads.toList()) {
      token.cancel();
    }
    _reads.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final token in _reads) {
      token.cancel();
    }
    _reads.clear();
    super.dispose();
  }
}
