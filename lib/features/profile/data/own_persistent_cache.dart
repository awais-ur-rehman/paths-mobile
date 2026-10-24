import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/generated/api_contract.dart';
import '../../../core/storage/own_cache_store.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/profile_repository.dart';

class StoredOwnProfile {
  const StoredOwnProfile(this.profile, this.revision);
  final ProfileSummary profile;
  final String revision;
}

/// Native authenticated encryption is mandatory; there is no plaintext fallback.
class OwnPersistentCache {
  OwnPersistentCache(this.store, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final OwnCacheStore store;
  final DateTime Function() clock;
  String? _owner, _lease, _storedAvatar;
  int _epoch = 0, _validation = 0;
  StoredOwnProfile? _validated;
  DateTime? _validatedAt;
  String? lastFailure;
  String? get owner => _owner;
  bool get ready => _lease != null;
  bool _current(int epoch) => epoch == _epoch && _lease != null;
  Future<void> activate(String owner) async {
    final epoch = ++_epoch, lease = newIntentKey();
    _owner = owner;
    _lease = null;
    invalidate();
    lastFailure = null;
    try {
      await store.activate(owner, lease);
      if (epoch == _epoch) _lease = lease;
    } on PlatformException {
      if (epoch == _epoch) lastFailure = 'platform';
    }
  }

  void invalidate() {
    _validation++;
    _validated = null;
    _validatedAt = null;
  }

  Future<Uint8List?> _read(OwnCacheEntry entry) async {
    final epoch = _epoch, owner = _owner, lease = _lease;
    if (owner == null || lease == null) return null;
    try {
      final bytes = await store.read(owner, lease, entry);
      if (!_current(epoch)) {
        bytes?.fillRange(0, bytes.length, 0);
        return null;
      }
      return bytes;
    } on PlatformException {
      if (epoch == _epoch) {
        lastFailure = 'read';
        _lease = null;
      }
      return null;
    }
  }

  Future<void> _write(OwnCacheEntry entry, Uint8List bytes) async {
    final epoch = _epoch, owner = _owner, lease = _lease;
    try {
      if (owner != null && lease != null && _current(epoch)) {
        await store.write(owner, lease, entry, bytes);
      }
    } on PlatformException {
      if (epoch == _epoch) {
        lastFailure = 'write';
        _lease = null;
      }
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
  }

  bool _valid(Map<String, dynamic> value) =>
      value['schema'] == 1 &&
      value['owner'] == _owner &&
      value['expiresAt'] is int &&
      value['savedAt'] is int &&
      clock().millisecondsSinceEpoch >= value['savedAt'] &&
      clock().millisecondsSinceEpoch < value['expiresAt'] &&
      value['expiresAt'] - value['savedAt'] ==
          const Duration(hours: 24).inMilliseconds;
  Map<String, Object?> _envelope() {
    final saved = clock().millisecondsSinceEpoch;
    return {
      'schema': 1,
      'owner': _owner,
      'savedAt': saved,
      'expiresAt': saved + const Duration(hours: 24).inMilliseconds,
    };
  }

  Future<void> _remove(OwnCacheEntry entry) async {
    final epoch = _epoch, owner = _owner, lease = _lease;
    if (owner == null || lease == null) return;
    try {
      await store.remove(owner, lease, entry);
    } on PlatformException {
      if (epoch == _epoch) {
        lastFailure = 'remove';
        _lease = null;
      }
    }
  }

  Future<StoredOwnProfile?> candidate() async {
    final epoch = _epoch;
    final bytes = await _read(OwnCacheEntry.profile);
    if (bytes == null) return null;
    if (!_current(epoch)) {
      bytes.fillRange(0, bytes.length, 0);
      return null;
    }
    try {
      if (bytes.length > 65536) throw const FormatException();
      final value = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (!_valid(value) ||
          value['revision'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(value['revision'])) {
        throw const FormatException();
      }
      final dto = ProfileSummaryDto.fromJson(
        value['profile'] as Map<String, dynamic>,
      );
      if (dto.userId != _owner) throw const FormatException();
      _storedAvatar = dto.avatarAssetId;
      return StoredOwnProfile(
        ProfileSummary(
          userId: dto.userId,
          username: dto.username,
          name: dto.name,
          age: dto.age.toInt(),
          gender: dto.gender,
          bio: dto.bio,
          visibility: dto.visibility,
          verificationStatus: dto.verificationStatus,
          avatarAssetId: dto.avatarAssetId,
          photoState: dto.photoState,
        ),
        value['revision'],
      );
    } on FormatException {
      lastFailure = 'invalid';
      await _remove(OwnCacheEntry.profile);
      return null;
    } on TypeError {
      lastFailure = 'invalid';
      await _remove(OwnCacheEntry.profile);
      return null;
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
  }

  Future<void> record(ProfileSummary profile, String revision) async {
    if (profile.userId != _owner || _lease == null) return;
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(revision)) {
      throw const AuthFailure('invalid_response');
    }
    final epoch = _epoch, validation = _validation;
    if (_storedAvatar != profile.avatarAssetId ||
        profile.photoState != 'approved') {
      await _remove(OwnCacheEntry.thumbnail);
      if (!_current(epoch) || validation != _validation) return;
      await _remove(OwnCacheEntry.display);
      if (!_current(epoch) || validation != _validation) return;
    }
    _storedAvatar = profile.avatarAssetId;
    _validated = StoredOwnProfile(profile, revision);
    _validatedAt = clock();
    final dto = ProfileSummaryDto(
      userId: profile.userId,
      username: profile.username,
      name: profile.name,
      age: profile.age,
      gender: profile.gender,
      bio: profile.bio,
      visibility: profile.visibility,
      verificationStatus: profile.verificationStatus,
      avatarAssetId: profile.avatarAssetId,
      photoState: profile.photoState,
    );
    await _write(
      OwnCacheEntry.profile,
      Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            ..._envelope(),
            'revision': revision,
            'profile': dto.toJson(),
          }),
        ),
      ),
    );
  }

  bool _eligible(String asset) {
    final profile = _validated?.profile, at = _validatedAt;
    return _lease != null &&
        profile?.userId == _owner &&
        profile?.avatarAssetId == asset &&
        profile?.photoState == 'approved' &&
        at != null &&
        clock().difference(at) >= Duration.zero &&
        clock().difference(at) < const Duration(seconds: 30);
  }

  Future<Uint8List?> avatar(String asset, bool thumbnail) async {
    if (!_eligible(asset)) return null;
    final epoch = _epoch,
        entry = thumbnail ? OwnCacheEntry.thumbnail : OwnCacheEntry.display;
    final bytes = await _read(entry);
    if (bytes == null) return null;
    try {
      if (bytes.length < 5) throw const FormatException();
      final length = ByteData.sublistView(bytes).getUint32(0);
      if (length > 1024 || length + 4 >= bytes.length) {
        throw const FormatException();
      }
      final value = jsonDecode(
        utf8.decode(bytes.sublist(4, 4 + length)),
      ) as Map<String, dynamic>;
      if (!_current(epoch) || !_eligible(asset)) return null;
      if (!_valid(value) || value['asset'] != asset) {
        await _remove(entry);
        return null;
      }
      return Uint8List.fromList(bytes.sublist(4 + length));
    } on FormatException {
      lastFailure = 'invalid';
      await _remove(entry);
      return null;
    } on TypeError {
      lastFailure = 'invalid';
      await _remove(entry);
      return null;
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
  }

  Future<void> writeAvatar(
    String asset,
    bool thumbnail,
    Uint8List bytes,
  ) async {
    if (!_eligible(asset) ||
        bytes.isEmpty ||
        bytes.length > (thumbnail ? 1047000 : 8387000)) {
      return;
    }
    final header = utf8.encode(jsonEncode({..._envelope(), 'asset': asset}));
    final record = Uint8List(4 + header.length + bytes.length);
    ByteData.sublistView(record).setUint32(0, header.length);
    record.setRange(4, 4 + header.length, header);
    record.setRange(4 + header.length, record.length, bytes);
    await _write(
      thumbnail ? OwnCacheEntry.thumbnail : OwnCacheEntry.display,
      record,
    );
  }

  Future<void> purge() async {
    ++_epoch;
    _owner = null;
    _lease = null;
    invalidate();
    try {
      await store.purge();
    } on PlatformException {
      lastFailure = 'cleanup';
      throw const AuthFailure('cache_cleanup');
    }
  }

  Future<void> close() async {
    final owner = _owner, lease = _lease;
    ++_epoch;
    _owner = null;
    _lease = null;
    invalidate();
    try {
      if (owner != null && lease != null) await store.deactivate(owner, lease);
    } on PlatformException {
      lastFailure = 'deactivate';
    }
  }
}
