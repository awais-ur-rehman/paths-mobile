import 'package:dio/dio.dart';

import 'auth_models.dart';

abstract interface class AuthRepository {
  Stream<AuthAccount?> get changes;
  Future<AuthSession?> restore({CancelToken? cancelToken});
  Future<bool> onboardingSeen();
  Future<void> finishOnboarding();
  Future<PolicyConfig> policies({CancelToken? cancelToken});
  Future<AuthChallenge> signup(
    String name,
    String email,
    String password,
    bool terms, {
    CancelToken? cancelToken,
  });
  Future<AuthSession> login(
    String email,
    String password, {
    CancelToken? cancelToken,
  });
  Future<AuthChallenge> forgot(String email, {CancelToken? cancelToken});
  Future<AuthChallenge> resend(
    AuthChallenge challenge, {
    CancelToken? cancelToken,
  });
  Future<Object> verify(
    AuthChallenge challenge,
    String code, {
    CancelToken? cancelToken,
  });
  Future<void> reset(
    ResetGrant grant,
    String password, {
    CancelToken? cancelToken,
  });
  Future<AuthAccount> checkAdult(
    String dateOfBirth, {
    CancelToken? cancelToken,
  });
  Future<void> logout();
  Future<void> close();
}

abstract interface class TokenVault {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

abstract interface class AuthPreferences {
  Future<bool?> flag(String key);
  Future<void> setFlag(String key, bool value);
  Future<String?> deviceId();
  Future<void> setDeviceId(String value);
}
