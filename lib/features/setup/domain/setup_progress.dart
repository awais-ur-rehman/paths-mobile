abstract interface class SetupProgressStore {
  Future<void> erase(String account);
  Future<bool> permissionSeen(String account);
  Future<void> markPermissionSeen(String account);
}
