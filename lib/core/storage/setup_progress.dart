import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/auth_models.dart';
import '../../features/setup/domain/setup_progress.dart';

final class PlatformSetupProgress implements SetupProgressStore {
  final _preferences = SharedPreferencesAsync();
  String _key(String account) => 'paths.setup.permissions.$account';
  @override
  Future<bool> permissionSeen(String account) async {
    try {
      return await _preferences.getBool(_key(account)) ?? false;
    } catch (_) {
      throw const AuthFailure('storage');
    }
  }

  @override
  Future<void> markPermissionSeen(String account) async {
    try {
      await _preferences.setBool(_key(account), true);
    } catch (_) {
      throw const AuthFailure('storage');
    }
  }
}
