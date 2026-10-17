import 'dart:typed_data';

import 'package:dio/dio.dart';

enum MediaKind { avatar, post, cnicFront, cnicBack }

enum PhotoSource { camera, gallery }

final class PickedPhoto {
  PickedPhoto(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String mimeType;
  void clear() => bytes.fillRange(0, bytes.length, 0);
}

abstract interface class PhotoPicker {
  Future<PickedPhoto?> pick(PhotoSource source);
  Future<void> discardLostSelection();
}

final class MediaAsset {
  const MediaAsset(this.id, this.state, this.safety);
  final String id, state, safety;
  bool get ready => state == 'ready';
  bool get terminal => state == 'rejected' || state == 'removed';
}

abstract interface class MediaRepository {
  String? get accountId;
  Future<MediaAsset> intent(
    MediaKind kind,
    PickedPhoto photo,
    String key, {
    CancelToken? cancelToken,
  });
  Future<void> upload(
    String id,
    PickedPhoto photo, {
    CancelToken? cancelToken,
    ProgressCallback? onProgress,
  });
  Future<MediaAsset> complete(String id, {CancelToken? cancelToken});
  Future<MediaAsset> status(String id, {CancelToken? cancelToken});
  Future<void> cancel(String id);
}
