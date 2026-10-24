import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/auth/data/http_auth_repository.dart';
import 'package:paths_mobile/features/profile/data/own_persistent_cache.dart';

import '../../core/storage/own_persistent_cache_test.dart' show CacheFixture;
import '../auth/auth_repository_test.dart' show MemoryVault, MemoryPreferences;
import 'own_profile_cache_test.dart' show SummaryTransport, owner;

class PersistentTransport extends SummaryTransport {
  int snapshots = 0, downloads = 0;
  bool changed = false;
  bool reject = false, malformed = false;
  DateTime? accessExpiry;
  @override
  Map<String, Object> session(String access, String refresh) => {
    ...super.session(access, refresh),
    if (accessExpiry != null)
      "accessExpiresAt": accessExpiry!.toUtc().toIso8601String(),
  };
  String? knownRevision;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (options.uri.path == '/v1/me/profile/snapshot') {
      snapshots++;
      if (reject) {
        return ResponseBody.fromString(
          '{"code":"ACCOUNT_RESTRICTED"}',
          403,
          headers: {
            'content-type': ['application/json'],
          },
        );
      }
      if (malformed) {
        return ResponseBody.fromString(
          '{"revision":"bad","notModified":true}',
          200,
          headers: {
            'content-type': ['application/json'],
          },
        );
      }
      knownRevision = options.uri.queryParameters['revision'];
      final revision = (changed ? 'b' : 'a') * 64;
      final profile = jsonDecode(
        await response(owner).stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .join(),
      );
      return ResponseBody.fromString(
        jsonEncode({
          'revision': revision,
          'notModified': knownRevision == revision,
          if (knownRevision != revision) 'profile': profile,
        }),
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    if (options.path.startsWith('/v1/media/')) {
      downloads++;
      return ResponseBody.fromBytes(
        [255, 216, 255, 217],
        200,
        headers: {
          'content-type': ['image/jpeg'],
        },
      );
    }
    return super.fetch(options, stream, cancel);
  }
}

HttpAuthRepository create(
  PersistentTransport api,
  CacheFixture store,
  MemoryVault vault,
  MemoryPreferences prefs,
) => HttpAuthRepository(
  origin: 'https://api.example.invalid',
  vault: vault,
  preferences: prefs,
  ownCache: OwnPersistentCache(store),
  publicTransport: Dio()..httpClientAdapter = api,
  authenticatedTransport: Dio()..httpClientAdapter = api,
);
void main() {
  test('restart requires session and conditional snapshot before serving cached own avatar', () async {
    final api = PersistentTransport()..adultChecked = true;
    final store = CacheFixture(),
        vault = MemoryVault(),
        prefs = MemoryPreferences();
    final first = create(api, store, vault, prefs);
    await first.login('fixture@example.invalid', 'fixture password');
    final profile = await first.loadProfileSummary(owner);
    await first.imageBytes(profile.avatarAssetId!);
    expect(api.downloads, 1);
    await first.close();
    final second = create(api, store, vault, prefs);
    await second.restore();
    final fresh = await second.loadProfileSummary(owner);
    expect(api.knownRevision, 'a' * 64);
    expect(api.snapshots, 2);
    expect(await second.imageBytes(fresh.avatarAssetId!), [255, 216, 255, 217]);
    expect(api.downloads, 1);
    await second.logout();
    expect(store.files, isEmpty);
    await second.close();
  });
  for (final malformed in [false, true]) {
    test(
      'rejected snapshot cannot authorize cached image (malformed=$malformed)',
      () async {
        final api = PersistentTransport()..adultChecked = true;
        final store = CacheFixture(),
            vault = MemoryVault(),
            prefs = MemoryPreferences();
        final first = create(api, store, vault, prefs);
        await first.login('fixture@example.invalid', 'fixture password');
        final profile = await first.loadProfileSummary(owner);
        await first.imageBytes(profile.avatarAssetId!);
        await first.close();
        final second = create(api, store, vault, prefs);
        await second.restore();
        api.reject = !malformed;
        api.malformed = malformed;
        await expectLater(second.loadProfileSummary(owner), throwsA(anything));
        await second.imageBytes(profile.avatarAssetId!);
        expect(
          api.downloads,
          2,
          reason: 'A rejected snapshot must not unlock disk pixels',
        );
        await second.close();
      },
    );
  }
  test('changed revision returns fresh server profile', () async {
    final api = PersistentTransport()..adultChecked = true;
    final store = CacheFixture(),
        vault = MemoryVault(),
        prefs = MemoryPreferences();
    final first = create(api, store, vault, prefs);
    await first.login('fixture@example.invalid', 'fixture password');
    await first.loadProfileSummary(owner);
    await first.close();
    api.changed = true;
    final second = create(api, store, vault, prefs);
    await second.restore();
    expect((await second.loadProfileSummary(owner)).userId, owner);
    expect(api.knownRevision, 'a' * 64);
    await second.close();
  });
  test('expired session cannot reuse encrypted avatar', () async {
    final api = PersistentTransport()
      ..adultChecked = true
      ..accessExpiry = DateTime.now().add(const Duration(seconds: 1));
    final store = CacheFixture(),
        vault = MemoryVault(),
        prefs = MemoryPreferences();
    final repo = create(api, store, vault, prefs);
    await repo.login('fixture@example.invalid', 'fixture password');
    final profile = await repo.loadProfileSummary(owner);
    await repo.imageBytes(profile.avatarAssetId!);
    await Future<void>.delayed(const Duration(seconds: 1));
    await repo.imageBytes(profile.avatarAssetId!);
    expect(api.downloads, 2);
    await repo.close();
  });
  test('refresh restriction destroys persisted profile and avatar', () async {
    final api = PersistentTransport()..adultChecked = true;
    final store = CacheFixture(),
        vault = MemoryVault(),
        prefs = MemoryPreferences();
    final repo = create(api, store, vault, prefs);
    await repo.login('fixture@example.invalid', 'fixture password');
    final profile = await repo.loadProfileSummary(owner);
    await repo.imageBytes(profile.avatarAssetId!);
    api.restricted = true;
    await repo.request('GET', '/v1/me/session');
    expect(store.files, isEmpty);
    await repo.close();
  });
}
