import 'dart:typed_data';

import 'package:dio/dio.dart';

abstract interface class AuthenticatedMediaApi {
  Future<void> uploadImage(
    String assetId,
    Uint8List bytes, {
    CancelToken? cancelToken,
    ProgressCallback? onProgress,
  });
  Future<Uint8List> imageBytes(
    String assetId, {
    bool thumbnail = true,
    CancelToken? cancelToken,
  });
}
