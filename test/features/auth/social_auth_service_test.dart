import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/data/social_auth_service.dart';
import 'package:paths_mobile/features/auth/domain/provider_auth.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';

class GoogleFixture extends GoogleSignInPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final nonces = <String?>[];
  int cleanups = 0;
  Completer<void>? wait;
  bool cancel = false;
  @override
  Future<void> init(InitParameters params) async {
    nonces.add(params.nonce);
  }

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    await wait?.future;
    if (cancel) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );
    }
    return const AuthenticationResults(
      user: GoogleSignInUserData(
        displayName: 'Fixture',
        email: 'fixture@example.invalid',
        id: 'fixture',
        photoUrl: null,
      ),
      authenticationTokens: AuthenticationTokenData(
        idToken: 'fixture-id-token',
      ),
    );
  }

  @override
  Future<void> signOut(SignOutParams params) async {
    cleanups++;
  }
}

void main() {
  const config = ProviderConfigDto(
    googleEnabled: true,
    appleEnabled: false,
    googleClientId: 'fixture.apps.googleusercontent.com',
    googleIosClientId: '',
  );
  test('each Google attempt gets its own nonce and clears SDK state', () async {
    final google = GoogleFixture(), sdk = SocialAuthService(google: google);
    expect(
      (await sdk.authenticate(
        IdentityProvider.google,
        'nonce-one',
        config,
      ))!.idToken,
      'fixture-id-token',
    );
    await sdk.authenticate(IdentityProvider.google, 'nonce-two', config);
    expect(google.nonces, ['nonce-one', 'nonce-two']);
    expect(google.cleanups, 2);
  });
  test(
    'cancellation is quiet and duplicate SDK launches cannot replace a nonce',
    () async {
      final google = GoogleFixture()..wait = Completer<void>(),
          sdk = SocialAuthService(google: google);
      final pending = sdk.authenticate(IdentityProvider.google, 'one', config);
      await expectLater(
        sdk.authenticate(IdentityProvider.google, 'two', config),
        throwsA(isA<AuthFailure>()),
      );
      google.cancel = true;
      google.wait!.complete();
      expect(await pending, isNull);
      expect(google.nonces, ['one']);
      expect(google.cleanups, 1);
    },
  );
}
