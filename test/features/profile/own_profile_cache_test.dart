import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/auth/data/http_auth_repository.dart';
import 'package:paths_mobile/features/profile/domain/profile_repository.dart';
import 'package:paths_mobile/features/profile/presentation/profile_preview_cubit.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';

import '../auth/auth_repository_test.dart'
    show ApiAdapter, MemoryVault, MemoryPreferences;

const owner = '11111111-1111-4111-8111-111111111111';
const peer = '22222222-2222-4222-8222-222222222222';

class SummaryTransport extends ApiAdapter {
  int summaries = 0;
  String summaryName = 'Original';
  bool delayed = false;
  int? failureStatus;
  String sessionOwner = owner;
  bool expiredAccess = false;
  @override
  Map<String, Object> session(String access, String refresh) => {
    ...super.session(access, refresh),
    'userId': sessionOwner,
    if (expiredAccess && access == 'old-access')
      'accessExpiresAt': DateTime.now()
          .subtract(const Duration(minutes: 1))
          .toUtc()
          .toIso8601String(),
  };
  final pending = <Completer<ResponseBody>>[];
  Completer<void>? started;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) {
    if (!options.path.startsWith('/v1/profiles/')) {
      return super.fetch(options, stream, cancel);
    }
    summaries++;
    if (failureStatus != null) {
      return Future.value(
        ResponseBody.fromString(
          jsonEncode({
            'code': failureStatus == 403
                ? 'FORBIDDEN'
                : 'DEPENDENCY_UNAVAILABLE',
          }),
          failureStatus!,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );
    }
    if (delayed) {
      final c = Completer<ResponseBody>();
      pending.add(c);
      started?.complete();
      return c.future;
    }
    return Future.value(response(options.path.split('/').last));
  }

  ResponseBody response(String id, {String? name}) => ResponseBody.fromString(
    jsonEncode({
      'userId': id,
      'username': 'fixture_user',
      'name': name ?? summaryName,
      'age': 26,
      'gender': 'man',
      'bio': 'Fixture',
      'visibility': 'private',
      'verificationStatus': 'none',
      'photoState': 'approved',
      'avatarAssetId': '33333333-3333-4333-8333-333333333333',
    }),
    200,
    headers: {
      'content-type': ['application/json'],
    },
  );
}

HttpAuthRepository repository(
  SummaryTransport adapter, {
  DateTime Function()? clock,
}) => HttpAuthRepository(
  profileCacheClock: clock,
  origin: 'https://api.example.invalid',
  vault: MemoryVault(),
  preferences: MemoryPreferences(),
  publicTransport: Dio()..httpClientAdapter = adapter,
  authenticatedTransport: Dio()..httpClientAdapter = adapter,
);
void main() {
  test(
    'twenty returning own-profile reads reuse one validated snapshot',
    () async {
      final api = SummaryTransport()..adultChecked = true;
      final repo = repository(api);
      await repo.login('fixture@example.invalid', 'fixture password');
      final first = await repo.loadProfileSummary(owner);
      for (var i = 0; i < 20; i++) {
        expect((await repo.loadProfileSummary(owner)).name, first.name);
      }
      expect(api.summaries, 1);
      await repo.close();
    },
  );
  test(
    'peers always reauthorize and are never retained as own-profile snapshots',
    () async {
      final api = SummaryTransport()..adultChecked = true;
      final repo = repository(api);
      await repo.login('fixture@example.invalid', 'fixture password');
      await repo.loadProfileSummary(peer);
      await repo.loadProfileSummary(peer);
      expect(api.summaries, 2);
      await repo.close();
    },
  );
  test('saving a profile invalidates the previous summary', () async {
    final api = SummaryTransport()..adultChecked = true;
    final repo = repository(api);
    await repo.login('fixture@example.invalid', 'fixture password');
    await repo.loadProfileSummary(owner);
    await repo.saveProfile(
      const ProfileDetails(
        username: 'fixture_user',
        name: 'Changed',
        gender: 'man',
        bio: '',
      ),
    );
    api.summaryName = 'Changed';
    expect((await repo.loadProfileSummary(owner)).name, 'Changed');
    expect(api.summaries, 2);
    await repo.close();
  });
  test(
    'snapshot expires exactly at the TTL and explicit refresh bypasses it',
    () async {
      var now = DateTime.utc(2026, 10, 24);
      final api = SummaryTransport()..adultChecked = true;
      final repo = repository(api, clock: () => now);
      await repo.login('fixture@example.invalid', 'fixture password');
      await repo.loadProfileSummary(owner);
      now = now.add(const Duration(seconds: 29));
      await repo.loadProfileSummary(owner);
      expect(api.summaries, 1);
      now = now.add(const Duration(seconds: 1));
      expect(repo.cachedOwnProfile, isNull);
      api.summaryName = 'Fresh';
      await repo.loadProfileSummary(owner);
      expect(api.summaries, 2);
      api.summaryName = 'Forced';
      expect((await repo.refreshOwnProfile()).name, 'Forced');
      expect(api.summaries, 3);
      await repo.close();
      expect(repo.cachedOwnProfile, isNull);
    },
  );
  test(
    'terminal refresh failure evicts the previously usable snapshot',
    () async {
      final api = SummaryTransport()..adultChecked = true;
      final repo = repository(api);
      await repo.login('fixture@example.invalid', 'fixture password');
      await repo.loadProfileSummary(owner);
      api.failureStatus = 403;
      await expectLater(repo.refreshOwnProfile(), throwsA(isA<AuthFailure>()));
      expect(repo.cachedOwnProfile, isNull);
      await repo.close();
    },
  );
  test('verification write invalidates own summary immediately', () async {
    final api = SummaryTransport()..adultChecked = true;
    final repo = repository(api);
    await repo.login('fixture@example.invalid', 'fixture password');
    await repo.loadProfileSummary(owner);
    await repo.skipVerification();
    expect(repo.cachedOwnProfile, isNull);
    await repo.loadProfileSummary(owner);
    expect(api.summaries, 2);
    await repo.close();
  });
  test(
    'old delayed response cannot overwrite a successful profile edit',
    () async {
      final api = SummaryTransport()..adultChecked = true;
      final repo = repository(api);
      await repo.login('fixture@example.invalid', 'fixture password');
      await repo.loadProfileSummary(owner);
      api.delayed = true;
      api.started = Completer<void>();
      final old = repo.refreshOwnProfile();
      final rejected = expectLater(
        old,
        throwsA(isA<AuthFailure>().having((e) => e.code, 'code', 'cancelled')),
      );
      await api.started!.future;
      await repo.saveProfile(
        const ProfileDetails(
          username: 'fixture_user',
          name: 'Changed',
          gender: 'man',
          bio: '',
        ),
      );
      api.delayed = false;
      api.summaryName = 'Changed';
      expect((await repo.loadProfileSummary(owner)).name, 'Changed');
      api.pending.single.complete(api.response(owner, name: 'Old'));
      await rejected;
      await Future<void>.delayed(Duration.zero);
      expect(repo.cachedOwnProfile!.name, 'Changed');
      await repo.close();
    },
  );
  test('restriction, logout and account replacement cannot reuse the previous snapshot', () async {
    final api = SummaryTransport()..adultChecked = true;
    final repo = repository(api);
    await repo.login('fixture@example.invalid', 'fixture password');
    await repo.loadProfileSummary(owner);
    api.restricted = true;
    await repo.restore();
    expect(repo.cachedOwnProfile, isNull);
    api.restricted = false;
    await repo.login('fixture@example.invalid', 'fixture password');
    await repo.loadProfileSummary(owner);
    await repo.logout();
    expect(repo.cachedOwnProfile, isNull);
    api.sessionOwner = peer;
    api.summaryName = 'Other';
    await repo.login('other@example.invalid', 'fixture password');
    expect(repo.cachedOwnProfile, isNull);
    expect((await repo.loadProfileSummary(peer)).userId, peer);
    await repo.close();
  });

  test('returning profile preview starts with a fresh own snapshot', () async {
    final api = SummaryTransport()..adultChecked = true;
    final repo = repository(api);
    await repo.login('fixture@example.invalid', 'fixture password');
    await repo.loadProfileSummary(owner);
    final cubit = ProfilePreviewCubit(repo, owner);
    expect(cubit.state.profile?.name, 'Original');
    expect(cubit.state.loading, false);
    await cubit.load();
    expect(api.summaries, 1);
    await cubit.close();
    await repo.close();
  });

  test('expired access cannot expose cache but explicit refresh still reaches server', () async {
    final api = SummaryTransport()
      ..adultChecked = true
      ..expiredAccess = true;
    final repo = repository(api);
    await repo.login('fixture@example.invalid', 'fixture password');
    expect(repo.cachedOwnProfile, isNull);
    expect((await repo.refreshOwnProfile()).name, 'Original');
    expect(api.summaries, 1);
    await repo.close();
  });
}
