import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/auth_repository.dart';
import '../../features/discovery/domain/location_repository.dart';

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
  Future<void> clearDeviceId() => _preferences.remove('paths.auth.device');
  @override
  Future<String?> deviceId() => _preferences.getString('paths.auth.device');
  @override
  Future<void> setDeviceId(String value) =>
      _preferences.setString('paths.auth.device', value);
}

final class PlatformTrackingControls implements TrackingControlStore {
  final _preferences = SharedPreferencesAsync();
  @override
  Future<bool> pendingStop() async =>
      await _preferences.getBool('paths.location.pendingStop') ?? false;
  @override
  Future<TrackingStop?> pendingControl() async {
    final account = await _preferences.getString('paths.location.stopAccount');
    final epoch = await _preferences.getInt('paths.location.stopEpoch');
    return account == null || epoch == null
        ? null
        : TrackingStop(account, epoch);
  }

  @override
  Future<void> setPendingStop(bool value, {TrackingStop? control}) async {
    if (value && control != null) {
      await _preferences.setString(
        'paths.location.stopAccount',
        control.accountId,
      );
      await _preferences.setInt('paths.location.stopEpoch', control.epoch);
    } else {
      await _preferences.remove('paths.location.stopAccount');
      await _preferences.remove('paths.location.stopEpoch');
    }
    await _preferences.setBool('paths.location.pendingStop', value);
  }
}
