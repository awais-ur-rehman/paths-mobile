import 'dart:math';

import 'package:dio/dio.dart';

abstract interface class AuthenticatedApi {
  String? get accountId;
  Future<String> installationId();
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    String? idempotencyKey,
    CancelToken? cancelToken,
  });
}

String newIntentKey() {
  final random = Random.secure(),
      bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Optional session lifecycle for repositories that own private in-flight work.
abstract interface class AuthenticatedAccountChanges {
  Stream<String?> get accountChanges;
}
