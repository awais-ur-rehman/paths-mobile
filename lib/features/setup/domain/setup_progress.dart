abstract interface class SetupProgressStore {
  Future<bool> permissionSeen(String account);
  Future<void> markPermissionSeen(String account);
}
