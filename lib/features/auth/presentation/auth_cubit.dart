import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

enum AuthStage {
  booting,
  blocked,
  onboarding,
  signedOut,
  otp,
  reset,
  authenticated,
}

final class AuthState {
  const AuthState({
    required this.stage,
    this.account,
    this.challenge,
    this.grant,
    this.email = '',
    this.busy = false,
    this.error,
    this.notice,
    this.signupPreferred = false,
    this.policies = const PolicyConfig(),
  });
  final AuthStage stage;
  final AuthAccount? account;
  final AuthChallenge? challenge;
  final ResetGrant? grant;
  final String email;
  final bool busy, signupPreferred;
  final AuthFailure? error;
  final String? notice;
  final PolicyConfig policies;
  AuthState update({
    bool? busy,
    AuthFailure? error,
    AuthAccount? account,
    AuthStage? stage,
  }) => AuthState(
    stage: stage ?? this.stage,
    account: account ?? this.account,
    challenge: challenge,
    grant: grant,
    email: email,
    busy: busy ?? this.busy,
    error: error,
    notice: notice,
    signupPreferred: signupPreferred,
    policies: policies,
  );
}

final class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository)
    : super(const AuthState(stage: AuthStage.booting)) {
    _subscription = _repository.changes.listen(
      (account) {
        if (isClosed || _signingOut) return;
        if (account == null) {
          _cancel();
          emit(
            AuthState(
              stage: AuthStage.signedOut,
              notice: 'Your session ended. Sign in again.',
              policies: _policies,
            ),
          );
        } else if (state.stage == AuthStage.authenticated) {
          emit(state.update(account: account));
        }
      },
      onError: (Object error) {
        if (isClosed || _signingOut) return;
        _cancel();
        emit(
          AuthState(
            stage: AuthStage.blocked,
            error: error is AuthFailure ? error : const AuthFailure('storage'),
            policies: _policies,
          ),
        );
      },
    );
  }
  final AuthRepository _repository;
  late final StreamSubscription<AuthAccount?> _subscription;
  PolicyConfig _policies = const PolicyConfig();
  CancelToken? _token;
  int _operation = 0;
  bool _signingOut = false;
  void _cancel() {
    _operation++;
    _token?.cancel();
    _token = null;
  }

  Future<void> _run(Future<AuthState> Function(CancelToken) action) async {
    if (state.busy || isClosed) return;
    final operation = ++_operation;
    final token = CancelToken();
    _token = token;
    emit(state.update(busy: true));
    try {
      final next = await action(token);
      if (!isClosed && operation == _operation) emit(next);
    } on AuthFailure catch (error) {
      if (!isClosed && operation == _operation) {
        emit(
          state.update(
            busy: false,
            error: error,
            stage: state.stage == AuthStage.booting ? AuthStage.blocked : null,
          ),
        );
      }
    } catch (error) {
      if (!isClosed && operation == _operation) {
        emit(
          state.update(
            busy: false,
            error: AuthFailure(
              error is FormatException ? 'invalid_response' : 'unavailable',
            ),
            stage: state.stage == AuthStage.booting ? AuthStage.blocked : null,
          ),
        );
      }
    } finally {
      if (operation == _operation) _token = null;
    }
  }

  Future<void> initialize() => _run((token) async {
    final seen = await _repository.onboardingSeen();
    final session = await _repository.restore(cancelToken: token);
    _policies = await _repository.policies(cancelToken: token);
    return AuthState(
      stage: session != null
          ? AuthStage.authenticated
          : seen
          ? AuthStage.signedOut
          : AuthStage.onboarding,
      account: session?.account,
      policies: _policies,
    );
  });
  Future<void> finishOnboarding({bool signIn = false}) => _run((_) async {
    await _repository.finishOnboarding();
    return AuthState(
      stage: AuthStage.signedOut,
      signupPreferred: !signIn,
      policies: _policies,
    );
  });
  Future<void> signup(String name, String email, String password, bool terms) =>
      _run((token) async {
        final challenge = await _repository.signup(
          name.trim(),
          email.trim().toLowerCase(),
          password,
          terms,
          cancelToken: token,
        );
        return AuthState(
          stage: AuthStage.otp,
          challenge: challenge,
          email: email.trim(),
          policies: _policies,
        );
      });
  void acceptProviderSession(AuthSession session) {
    if (isClosed || state.stage != AuthStage.signedOut || state.busy) return;
    _cancel();
    emit(
      AuthState(
        stage: AuthStage.authenticated,
        account: session.account,
        policies: _policies,
      ),
    );
  }

  Future<void> login(String email, String password) => _run((token) async {
    final session = await _repository.login(
      email.trim().toLowerCase(),
      password,
      cancelToken: token,
    );
    return AuthState(
      stage: AuthStage.authenticated,
      account: session.account,
      policies: _policies,
    );
  });
  Future<void> forgot(String email) => _run((token) async {
    final challenge = await _repository.forgot(
      email.trim().toLowerCase(),
      cancelToken: token,
    );
    return AuthState(
      stage: AuthStage.otp,
      challenge: challenge,
      email: email.trim(),
      notice: 'If an account exists for that address, a code has been sent.',
      policies: _policies,
    );
  });
  Future<void> verify(String code) => _run((token) async {
    final challenge = state.challenge;
    if (challenge == null) throw const AuthFailure('OTP_INVALID');
    final result = await _repository.verify(
      challenge,
      code,
      cancelToken: token,
    );
    if (result is AuthSession) {
      return AuthState(
        stage: AuthStage.authenticated,
        account: result.account,
        policies: _policies,
      );
    }
    if (result is ResetGrant) {
      return AuthState(
        stage: AuthStage.reset,
        grant: result,
        policies: _policies,
      );
    }
    throw const AuthFailure('invalid_response');
  });
  Future<void> resend() => _run((token) async {
    final challenge = state.challenge;
    if (challenge == null) throw const AuthFailure('OTP_INVALID');
    final next = await _repository.resend(challenge, cancelToken: token);
    return AuthState(
      stage: AuthStage.otp,
      challenge: next,
      email: state.email,
      notice: state.notice,
      policies: _policies,
    );
  });
  Future<void> reset(String password) => _run((token) async {
    final grant = state.grant;
    if (grant == null || !grant.expiresAt.isAfter(DateTime.now())) {
      throw const AuthFailure('RESET_INVALID');
    }
    _signingOut = true;
    try {
      await _repository.reset(grant, password, cancelToken: token);
    } finally {
      _signingOut = false;
    }
    return AuthState(
      stage: AuthStage.signedOut,
      notice: 'Your password was changed. Sign in with your new password.',
      policies: _policies,
    );
  });
  Future<void> checkAdult(String dateOfBirth) => _run((token) async {
    final account = await _repository.checkAdult(
      dateOfBirth,
      cancelToken: token,
    );
    return AuthState(
      stage: AuthStage.authenticated,
      account: account,
      policies: _policies,
    );
  });
  Future<void> refreshSession() => _run((token) async {
    final session = await _repository.restore(cancelToken: token);
    return AuthState(
      stage: session == null ? AuthStage.signedOut : AuthStage.authenticated,
      account: session?.account,
      policies: _policies,
    );
  });
  Future<void> logout() async {
    _cancel();
    _signingOut = true;
    emit(AuthState(stage: AuthStage.booting, busy: true, policies: _policies));
    try {
      await _repository.logout();
      if (!isClosed) {
        emit(AuthState(stage: AuthStage.signedOut, policies: _policies));
      }
    } on AuthFailure catch (error) {
      if (!isClosed) {
        emit(
          AuthState(
            stage: ['storage', 'tracking_cleanup'].contains(error.code)
                ? AuthStage.blocked
                : AuthStage.signedOut,
            error: error,
            notice: error.offline
                ? 'Signed out on this phone. Paths could not confirm server sign-out.'
                : null,
            policies: _policies,
          ),
        );
      }
    } finally {
      _signingOut = false;
    }
  }

  Future<void> cancelFlow() => logout();
  @override
  Future<void> close() async {
    _cancel();
    await _subscription.cancel();
    await super.close();
  }
}
