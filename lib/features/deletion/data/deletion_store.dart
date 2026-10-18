import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/deletion_repository.dart';

class PlatformDeletionStore implements DeletionStore {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: false,
      storageNamespace: 'paths_deletion',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
      synchronizable: false,
    ),
  );
  static const _key = 'paths.deletion.receipt.v1';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}
