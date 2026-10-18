import 'package:dio/dio.dart';

import '../../../core/network/generated/api_contract.dart';
import 'auth_models.dart';

enum IdentityProvider { google, apple }

enum ReauthAction { link, unlink, deletion }

final class ProviderCredential {
  const ProviderCredential(this.idToken, {this.authorizationCode, this.name});
  final String idToken;
  final String? authorizationCode, name;
}

abstract interface class ProviderSdk {
  bool supports(IdentityProvider provider, ProviderConfigDto config);
  Future<ProviderCredential?> authenticate(
    IdentityProvider provider,
    String nonce,
    ProviderConfigDto config,
  );
}

abstract interface class ProviderAuthRepository {
  int get providerEpoch;
  Future<ProviderConfigDto> providerConfig({CancelToken? cancelToken});
  Future<Map<String, dynamic>> providerRequest(
    String method,
    String path, {
    Map<String, dynamic>? data,
    bool authenticated = false,
    required int epoch,
    CancelToken? cancelToken,
  });
  Future<AuthSession> acceptProviderSession(
    Map<String, dynamic> session, {
    required int epoch,
    CancelToken? cancelToken,
  });
}
