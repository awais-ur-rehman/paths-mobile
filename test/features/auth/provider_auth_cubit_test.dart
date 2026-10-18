import 'package:paths_mobile/core/network/refresh_coordinator.dart';

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/auth/domain/provider_auth.dart';
import 'package:paths_mobile/features/auth/presentation/provider_auth_cubit.dart';

const config = ProviderConfigDto(
  googleEnabled: true,
  appleEnabled: true,
  googleClientId: 'fixture',
  googleIosClientId: 'fixture-ios',
);

class Sdk implements ProviderSdk {
  Completer<ProviderCredential?>? wait;
  ProviderCredential? credential = const ProviderCredential('fixture-id-token');
  int calls = 0;
  @override
  bool supports(IdentityProvider p, ProviderConfigDto c) => true;
  @override
  Future<ProviderCredential?> authenticate(
    IdentityProvider p,
    String n,
    ProviderConfigDto c,
  ) async {
    calls++;
    return wait == null ? credential : wait!.future;
  }
}

class Repository implements ProviderAuthRepository {
  @override
  int providerEpoch = 0;
  final calls =
      <({String path, Map<String, dynamic>? data, bool authenticated})>[];
  String kind = 'setupRequired';
  bool emailRequired = false, failStorage = false;
  int accepted = 0;
  @override
  Future<ProviderConfigDto> providerConfig({CancelToken? cancelToken}) async =>
      config;
  Map<String, dynamic> pending() => {
    'kind': kind,
    'pendingToken': 'pending-fixture',
    'emailRequired': emailRequired,
    'provider': 'google',
    'expiresAt': DateTime.now()
        .add(const Duration(minutes: 5))
        .toIso8601String(),
  };
  Map<String, dynamic> session() => {
    'kind': 'session',
    'session': {
      'userId': 'fixture-user',
      'email': 'fixture@example.invalid',
      'name': 'Fixture',
      'accountStatus': 'active',
      'setupStage': 'adult',
      'accessToken': 'fixture-access',
      'refreshToken': 'fixture-refresh',
      'accessExpiresAt': DateTime.now()
          .add(const Duration(minutes: 10))
          .toIso8601String(),
      'refreshExpiresAt': DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String(),
    },
  };
  @override
  Future<Map<String, dynamic>> providerRequest(
    String method,
    String path, {
    Map<String, dynamic>? data,
    bool authenticated = false,
    required int epoch,
    CancelToken? cancelToken,
  }) async {
    if (epoch != providerEpoch || cancelToken?.isCancelled == true) {
      throw const AuthFailure('cancelled');
    }
    calls.add((path: path, data: data, authenticated: authenticated));
    if (path.endsWith('/challenge')) {
      return {
        'challengeId': 'fixture',
        'verifier': 'fixture',
        'nonce': 'fresh-nonce',
        'expiresAt': DateTime.now()
            .add(const Duration(minutes: 5))
            .toIso8601String(),
      };
    }
    if (path.endsWith('/identities')) {
      return {
        'passwordEnabled': true,
        'providers': ['google'],
      };
    }
    if (path.endsWith('/password')) {
      return {
        'kind': 'reauthenticated',
        'token': 'proof',
        'expiresAt': DateTime.now()
            .add(const Duration(minutes: 5))
            .toIso8601String(),
      };
    }
    if (path.endsWith('/link')) return {'status': 'linked'};
    if (path.endsWith('/email')) {
      return {
        'kind': 'emailRequired',
        'pendingToken': 'pending-fixture',
        'challenge': {
          'challengeId': 'otp-fixture',
          'purpose': 'provider-email',
          'expiresAt': DateTime.now()
              .add(const Duration(minutes: 5))
              .toIso8601String(),
          'resendAt': DateTime.now()
              .add(const Duration(seconds: 60))
              .toIso8601String(),
        },
      };
    }
    if (path.endsWith('/verify') ||
        path.endsWith('/continue') ||
        kind == 'session') {
      return session();
    }
    return pending();
  }

  @override
  Future<AuthSession> acceptProviderSession(
    Map<String, dynamic> value, {
    required int epoch,
    CancelToken? cancelToken,
  }) async {
    if (failStorage) throw const AuthFailure('storage');
    accepted++;
    return AuthSession(
      account: const AuthAccount(
        id: 'fixture-user',
        email: 'fixture@example.invalid',
        name: 'Fixture',
        restricted: false,
        adultChecked: false,
      ),
      tokens: const SessionTokens(
        accessToken: 'fixture-access',
        refreshToken: 'fixture-refresh',
      ),
      accessExpiresAt: DateTime.now(),
      refreshExpiresAt: DateTime.now(),
    );
  }
}

void main() {
  test('new verified identity requires explicit terms and uses existing adult-gated session', () async {
    final repo = Repository(),
        sdk = Sdk(),
        cubit = ProviderAuthCubit(repo, sdk);
    await cubit.load();
    await cubit.select(IdentityProvider.google);
    expect(cubit.state.step, ProviderStep.setup);
    expect(repo.accepted, 0);
    await cubit.continueSetup('');
    expect(repo.calls.last.data!['termsAccepted'], true);
    expect(cubit.state.session!.account.adultChecked, false);
    expect(repo.accepted, 1);
    await cubit.close();
  });
  test(
    'missing email uses its own challenge and keeps pending proof in memory',
    () async {
      final repo = Repository()..emailRequired = true,
          cubit = ProviderAuthCubit(repo, Sdk());
      await cubit.load();
      await cubit.select(IdentityProvider.google);
      await cubit.continueSetup('fixture@example.invalid');
      expect(cubit.state.step, ProviderStep.emailCode);
      await cubit.verifyEmail('123456');
      expect(repo.calls.last.data!['challengeId'], 'otp-fixture');
      expect(repo.calls.last.data!['pendingToken'], 'pending-fixture');
      expect(repo.accepted, 1);
      await cubit.close();
    },
  );
  test('email collision cannot accept a session or auto-link', () async {
    final repo = Repository()..kind = 'linkRequired',
        cubit = ProviderAuthCubit(repo, Sdk());
    await cubit.load();
    await cubit.select(IdentityProvider.google);
    expect(cubit.state.step, ProviderStep.collision);
    expect(repo.accepted, 0);
    expect(repo.calls.any((c) => c.path.endsWith('/link')), false);
    await cubit.close();
  });
  test('closing or signing out during SDK interaction ignores the late result; duplicate taps deduplicate', () async {
    final repo = Repository(),
        sdk = Sdk()..wait = Completer<ProviderCredential?>(),
        cubit = ProviderAuthCubit(repo, sdk);
    await cubit.load();
    final running = cubit.select(IdentityProvider.google);
    await Future<void>.delayed(Duration.zero);
    await cubit.select(IdentityProvider.apple);
    await cubit.close();
    sdk.wait!.complete(const ProviderCredential('late'));
    await running;
    expect(sdk.calls, 1);
    expect(repo.calls.where((c) => c.path.endsWith('/google')), isEmpty);
    expect(repo.accepted, 0);
    final next = ProviderAuthCubit(
      repo,
      Sdk()..wait = Completer<ProviderCredential?>(),
    );
    await next.load();
    final second = next.select(IdentityProvider.google);
    await Future<void>.delayed(Duration.zero);
    repo.providerEpoch++;
    (next.sdk as Sdk).wait!.complete(const ProviderCredential('stale'));
    await second;
    expect(next.state.error!.code, 'cancelled');
    expect(repo.accepted, 0);
    await next.close();
  });
  test('cancel is quiet and failed secure storage never yields authenticated state', () async {
    final repo = Repository()
          ..kind = 'session'
          ..failStorage = true,
        cubit = ProviderAuthCubit(repo, Sdk());
    await cubit.load();
    await cubit.select(IdentityProvider.google);
    expect(cubit.state.error!.code, 'storage');
    expect(cubit.state.session, isNull);
    expect(repo.accepted, 0);
    await cubit.close();
    final cancelled = ProviderAuthCubit(Repository(), Sdk()..credential = null);
    await cancelled.load();
    await cancelled.select(IdentityProvider.google);
    expect(cancelled.state.error, isNull);
    expect(cancelled.state.result!['status'], 'cancelled');
    await cancelled.close();
  });
  test(
    'reauth never accepts a sign-in session in place of its scoped proof',
    () async {
      final repo = Repository()..kind = 'session',
          cubit = ProviderAuthCubit(repo, Sdk(), action: ReauthAction.deletion);
      await cubit.load();
      await cubit.select(IdentityProvider.google);
      expect(repo.accepted, 0);
      expect(cubit.state.error!.code, 'invalid_response');
      await cubit.close();
    },
  );
  test(
    'reauth action and explicit account-bound linking never replace a session',
    () async {
      final repo = Repository(),
          cubit = ProviderAuthCubit(repo, Sdk(), action: ReauthAction.deletion);
      await cubit.load();
      await cubit.password('fixture-password');
      expect(repo.calls.last.data!['action'], 'deletion');
      expect(cubit.state.result!['token'], 'proof');
      await cubit.close();
      final link = ProviderAuthCubit(repo, Sdk(), linking: true)
        ..acceptLinkProof('link-proof');
      await link.load();
      await link.select(IdentityProvider.google);
      final challenge = repo.calls
          .where((c) => c.path.endsWith('/challenge'))
          .last;
      expect(challenge.data!['purpose'], 'link');
      expect(challenge.authenticated, true);
      expect(repo.calls.last.data!['reauthToken'], 'link-proof');
      expect(repo.accepted, 0);
      expect(link.state.result!['status'], 'linked');
      await link.close();
    },
  );
}
