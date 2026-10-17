import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/auth_repository.dart';

final class PlatformTokenVault implements TokenVault {
  static const _key = 'paths.auth.session.v1';
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: false,
      storageNamespace: 'paths_auth',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
      synchronizable: false,
    ),
  );
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

final class PlatformAuthPreferences implements AuthPreferences {
  final _preferences = SharedPreferencesAsync();
  @override
  Future<bool?> flag(String key) => _preferences.getBool(key);
  @override
  Future<void> setFlag(String key, bool value) =>
      _preferences.setBool(key, value);
  @override
  Future<String?> deviceId() => _preferences.getString('paths.auth.device');
  @override
  Future<void> setDeviceId(String value) =>
      _preferences.setString('paths.auth.device', value);
}
