import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/storage/own_cache_store.dart';
import 'package:paths_mobile/features/profile/data/own_persistent_cache.dart';
import 'package:paths_mobile/features/profile/domain/profile_repository.dart';

class CacheFixture implements OwnCacheStore {
  String? owner, lease;
  int purges = 0;
  final files = <OwnCacheEntry, Uint8List>{};
  @override
  Future<void> activate(String user, String session) async {
    if (owner != null && owner != user) files.clear();
    owner = user;
    lease = session;
  }

  void check(String user, String session) {
    if (owner != user || lease != session) throw StateError('inactive');
  }

  @override
  Future<Uint8List?> read(
    String user,
    String session,
    OwnCacheEntry entry,
  ) async {
    check(user, session);
    return files[entry] == null ? null : Uint8List.fromList(files[entry]!);
  }

  @override
  Future<void> write(
    String user,
    String session,
    OwnCacheEntry entry,
    Uint8List bytes,
  ) async {
    check(user, session);
    files[entry] = Uint8List.fromList(bytes);
  }

  @override
  Future<void> remove(String user, String session, OwnCacheEntry entry) async {
    check(user, session);
    files.remove(entry);
  }

  @override
  Future<void> purge() async {
    purges++;
    files.clear();
    owner = null;
    lease = null;
  }

  @override
  Future<void> deactivate(String user, String session) async {
    if (owner == user && lease == session) lease = null;
  }
}

class FailingStore extends CacheFixture {
  bool failPurge = false;
  @override
  Future<void> write(
    String owner,
    String lease,
    OwnCacheEntry entry,
    Uint8List bytes,
  ) async {
    throw PlatformException(code: 'unavailable');
  }

  @override
  Future<void> purge() async {
    if (failPurge) throw PlatformException(code: 'cleanup');
    await super.purge();
  }
}

class DelayedRemoval extends CacheFixture {
  final started = Completer<void>(), release = Completer<void>();
  bool once = false;
  @override
  Future<void> remove(String owner, String lease, OwnCacheEntry entry) async {
    if (!once) {
      once = true;
      started.complete();
      await release.future;
    }
    await super.remove(owner, lease, entry);
  }
}

class DelayedReadFailure extends CacheFixture {
  final started = Completer<void>(), release = Completer<void>();
  @override
  Future<Uint8List?> read(
    String owner,
    String lease,
    OwnCacheEntry entry,
  ) async {
    started.complete();
    await release.future;
    throw PlatformException(code: 'read_failed');
  }
}

const owner = '11111111-1111-4111-8111-111111111111';
const avatar = '22222222-2222-4222-8222-222222222222';
const profile = ProfileSummary(
  userId: owner,
  username: 'fixture',
  name: 'Fixture',
  age: 26,
  gender: 'man',
  bio: 'Private fixture',
  visibility: 'private',
  verificationStatus: 'approved',
  avatarAssetId: avatar,
  photoState: 'approved',
);
final revision = 'a' * 64;
void main() {
  test(
    'storage write failure disables cache without failing server result',
    () async {
      final store = FailingStore();
      final cache = OwnPersistentCache(store);
      await cache.activate(owner);
      await cache.record(profile, revision);
      expect(cache.ready, false);
      expect(cache.lastFailure, 'write');
      expect(await cache.avatar(avatar, true), isNull);
      await cache.purge();
    },
  );
  test(
    'failed purge is explicit and cannot leave usable authorization',
    () async {
      final store = FailingStore();
      final cache = OwnPersistentCache(store);
      await cache.activate(owner);
      store.failPurge = true;
      await expectLater(cache.purge(), throwsA(anything));
      expect(cache.ready, false);
      expect(cache.owner, isNull);
      expect(await cache.avatar(avatar, true), isNull);
    },
  );
  test('persisted metadata is only a conditional candidate, not an authorized avatar lease', () async {
    final store = CacheFixture();
    final actual = OwnPersistentCache(store);
    await actual.activate(owner);
    await actual.record(profile, revision);
    await actual.writeAvatar(avatar, true, Uint8List.fromList([7, 8]));
    await actual.close();
    final reopened = OwnPersistentCache(store);
    await reopened.activate(owner);
    expect((await reopened.candidate())!.profile.name, 'Fixture');
    expect(await reopened.avatar(avatar, true), isNull);
    await reopened.record(profile, revision);
    expect(await reopened.avatar(avatar, true), [7, 8]);
    await reopened.purge();
    expect(store.files, isEmpty);
  });
  test(
    'expiry and malformed envelopes become misses and remove the entry',
    () async {
      var now = DateTime.utc(2026, 10, 24);
      final store = CacheFixture();
      final cache = OwnPersistentCache(store, clock: () => now);
      await cache.activate(owner);
      await cache.record(profile, revision);
      now = now.add(const Duration(hours: 24));
      expect(await cache.candidate(), isNull);
      expect(store.files.containsKey(OwnCacheEntry.profile), false);
      store.files[OwnCacheEntry.profile] = Uint8List.fromList([1, 2]);
      expect(await cache.candidate(), isNull);
      await cache.purge();
    },
  );
  test('only current server-approved own asset is readable and authorization expires', () async {
    var now = DateTime.utc(2026, 10, 24);
    final store = CacheFixture();
    final cache = OwnPersistentCache(store, clock: () => now);
    await cache.activate(owner);
    await cache.record(profile, revision);
    await cache.writeAvatar(avatar, false, Uint8List.fromList([9]));
    expect(
      await cache.avatar('33333333-3333-4333-8333-333333333333', false),
      isNull,
    );
    now = now.add(const Duration(seconds: 30));
    expect(await cache.avatar(avatar, false), isNull);
    cache.invalidate();
    expect(await cache.avatar(avatar, false), isNull);
    await cache.purge();
  });
  test(
    'account change and purge cannot revive previous profile or avatar',
    () async {
      final store = CacheFixture();
      final actual = OwnPersistentCache(store);
      await actual.activate(owner);
      await actual.record(profile, revision);
      await actual.activate('33333333-3333-4333-8333-333333333333');
      expect(await actual.candidate(), isNull);
      expect(await actual.avatar(avatar, true), isNull);
      await actual.purge();
      expect(await actual.candidate(), isNull);
    },
  );
  test(
    'clock tick while saving cannot invalidate a new cache record',
    () async {
      var ticks = 0;
      final store = CacheFixture();
      final cache = OwnPersistentCache(
        store,
        clock: () =>
            DateTime.utc(2026, 10, 24).add(Duration(milliseconds: ticks++)),
      );
      await cache.activate(owner);
      await cache.record(profile, revision);
      expect((await cache.candidate())?.profile.name, 'Fixture');
      await cache.purge();
    },
  );
  test(
    'invalidation during file retirement cannot revive avatar authorization',
    () async {
      final store = DelayedRemoval();
      final actual = OwnPersistentCache(store);
      await actual.activate(owner);
      final pending = actual.record(profile, revision);
      await store.started.future;
      actual.invalidate();
      store.release.complete();
      await pending;
      await actual.writeAvatar(avatar, true, Uint8List.fromList([1, 2]));
      expect(store.files.containsKey(OwnCacheEntry.thumbnail), false);
      await actual.purge();
    },
  );
  test(
    'late old-session cache failure cannot disable a new account cache',
    () async {
      final store = DelayedReadFailure();
      final actual = OwnPersistentCache(store);
      await actual.activate(owner);
      final pending = actual.candidate();
      await store.started.future;
      await actual.activate('33333333-3333-4333-8333-333333333333');
      store.release.complete();
      expect(await pending, isNull);
      expect(actual.ready, true);
      await actual.purge();
    },
  );
}
