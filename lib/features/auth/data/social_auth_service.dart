import 'package:flutter/foundation.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/network/generated/api_contract.dart';
import '../domain/auth_models.dart';
import '../domain/provider_auth.dart';

class SocialAuthService implements ProviderSdk {
  SocialAuthService({GoogleSignInPlatform? google})
    : _google = google ?? GoogleSignInPlatform.instance;
  final GoogleSignInPlatform _google;
  bool _busy = false;
  static const _iosClientId = String.fromEnvironment(
    'PATHS_GOOGLE_IOS_CLIENT_ID',
  );
  @override
  bool supports(IdentityProvider provider, ProviderConfigDto config) {
    if (kIsWeb) return false;
    return switch (provider) {
      IdentityProvider.google =>
        config.googleEnabled &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS &&
                    config.googleIosClientId.isNotEmpty &&
                    _iosClientId == config.googleIosClientId),
      IdentityProvider.apple =>
        config.appleEnabled && defaultTargetPlatform == TargetPlatform.iOS,
    };
  }

  @override
  Future<ProviderCredential?> authenticate(
    IdentityProvider provider,
    String nonce,
    ProviderConfigDto config,
  ) async {
    if (_busy) throw const AuthFailure('cancelled');
    _busy = true;
    try {
      if (provider == IdentityProvider.apple) {
        final result = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );
        final token = result.identityToken;
        if (token == null || token.isEmpty) {
          throw const AuthFailure('PROVIDER_INVALID');
        }
        return ProviderCredential(
          token,
          authorizationCode: result.authorizationCode,
          name: [
            result.givenName,
            result.familyName,
          ].whereType<String>().join(' '),
        );
      }
      // The public singleton initializes once and owns persistent streams. The
      // official platform bridge lets each serialized attempt configure a nonce
      // without accumulating subscriptions or reusing a previous nonce.
      try {
        await _google.init(
          InitParameters(
            clientId: defaultTargetPlatform == TargetPlatform.iOS
                ? config.googleIosClientId
                : null,
            serverClientId: config.googleClientId,
            nonce: nonce,
          ),
        );
        final result = await _google.authenticate(
          const AuthenticateParameters(),
        );
        final token = result.authenticationTokens.idToken;
        if (token == null || token.isEmpty) {
          throw const AuthFailure('PROVIDER_INVALID');
        }
        return ProviderCredential(token, name: result.user.displayName);
      } finally {
        await _google.signOut(const SignOutParams());
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw const AuthFailure('PROVIDER_UNAVAILABLE');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw const AuthFailure('PROVIDER_UNAVAILABLE');
    } on AuthFailure {
      rethrow;
    } catch (_) {
      // Vendor errors may include credentials; expose only the app failure code.
      throw const AuthFailure('PROVIDER_UNAVAILABLE');
    } finally {
      _busy = false;
    }
  }
}
