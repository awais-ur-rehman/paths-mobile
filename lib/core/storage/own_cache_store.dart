import 'package:flutter/services.dart';

enum OwnCacheEntry { profile, thumbnail, display }

abstract interface class OwnCacheStore {
  Future<void> activate(String owner, String lease);
  Future<Uint8List?> read(String owner, String lease, OwnCacheEntry entry);
  Future<void> write(
    String owner,
    String lease,
    OwnCacheEntry entry,
    Uint8List bytes,
  );
  Future<void> remove(String owner, String lease, OwnCacheEntry entry);
  Future<void> purge();
  Future<void> deactivate(String owner, String lease);
}

class PlatformOwnCacheStore implements OwnCacheStore {
  static const channel = MethodChannel('paths/own_cache');
  Map<String, Object> _args(String owner, String lease, OwnCacheEntry entry) =>
      {'owner': owner, 'lease': lease, 'entry': entry.name};
  @override
  Future<void> activate(String owner, String lease) =>
      channel.invokeMethod('activate', {'owner': owner, 'lease': lease});
  @override
  Future<Uint8List?> read(String owner, String lease, OwnCacheEntry entry) =>
      channel.invokeMethod<Uint8List>('read', _args(owner, lease, entry));
  @override
  Future<void> write(
    String owner,
    String lease,
    OwnCacheEntry entry,
    Uint8List bytes,
  ) => channel.invokeMethod('write', {
    ..._args(owner, lease, entry),
    'bytes': bytes,
  });
  @override
  Future<void> remove(String owner, String lease, OwnCacheEntry entry) =>
      channel.invokeMethod('remove', _args(owner, lease, entry));
  @override
  Future<void> purge() => channel.invokeMethod('purge');
  @override
  Future<void> deactivate(String owner, String lease) =>
      channel.invokeMethod('deactivate', {'owner': owner, 'lease': lease});
}
