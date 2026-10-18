import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/generated/api_contract.dart';
import '../domain/auth_models.dart';
import '../domain/provider_auth.dart';

enum ProviderStep { choose, setup, emailCode, collision, done }

final class ProviderState {
  const ProviderState({
    this.step = ProviderStep.choose,
    this.busy = false,
    this.config,
    this.methods,
    this.pending,
    this.challenge,
    this.result,
    this.error,
    this.session,
  });
  final ProviderStep step;
  final bool busy;
  final ProviderConfigDto? config;
  final IdentityMethodsDto? methods;
  final ProviderSetupDto? pending;
  final ProviderEmailChallengeDto? challenge;
  final Map<String, dynamic>? result;
  final AuthFailure? error;
  final AuthSession? session;
  ProviderState update({
    bool? busy,
    AuthFailure? error,
    ProviderConfigDto? config,
    IdentityMethodsDto? methods,
  }) => ProviderState(
    step: step,
    busy: busy ?? this.busy,
    config: config ?? this.config,
    methods: methods ?? this.methods,
    pending: pending,
    challenge: challenge,
    result: result,
    error: error,
    session: session,
  );
}

class ProviderAuthCubit extends Cubit<ProviderState> {
  ProviderAuthCubit(
    this.repository,
    this.sdk, {
    this.action,
    this.linking = false,
    this.initialPending,
  }) : epoch = repository.providerEpoch,
       super(const ProviderState());
  final ProviderAuthRepository repository;
  final ProviderSdk sdk;
  final ReauthAction? action;
  final bool linking;
  final ProviderSetupDto? initialPending;
  final int epoch;
  CancelToken? _request;
  String? _proof;
  Future<void> _run(Future<void> Function(CancelToken) work) async {
    if (isClosed || state.busy) return;
    final token = _request = CancelToken();
    emit(state.update(busy: true));
    try {
      await work(token);
    } catch (e) {
      if (!isClosed && !token.isCancelled) {
        emit(
          state.update(
            busy: false,
            error: e is AuthFailure ? e : const AuthFailure('unavailable'),
          ),
        );
      }
    } finally {
      if (!isClosed && !token.isCancelled && state.busy) {
        emit(state.update(busy: false));
      }
    }
  }

  Future<Map<String, dynamic>> _call(
    String path,
    CancelToken token, {
    Map<String, dynamic>? data,
    bool authenticated = false,
    String method = 'POST',
  }) => repository.providerRequest(
    method,
    '/v1/$path',
    data: data,
    authenticated: authenticated,
    epoch: epoch,
    cancelToken: token,
  );
  Future<void> load() => _run((token) async {
    final config = await repository.providerConfig(cancelToken: token);
    final methods = action != null || linking
        ? IdentityMethodsDto.fromJson(
            await _call(
              'me/identities',
              token,
              method: 'GET',
              authenticated: true,
            ),
          )
        : null;
    if (!isClosed && !token.isCancelled) {
      emit(ProviderState(config: config, methods: methods));
    }
  });
  Future<void> select(IdentityProvider provider) => _run((token) async {
    final config = state.config;
    if (config == null || !sdk.supports(provider, config)) {
      throw const AuthFailure('PROVIDER_UNAVAILABLE');
    }
    final challenge = ProviderChallengeDto.fromJson(
      await _call(
        'auth/providers/challenge',
        token,
        authenticated: action != null || linking,
        data: ProviderChallengeInput(
          provider: provider.name,
          purpose: linking
              ? 'link'
              : action == null
              ? 'signin'
              : 'reauth',
          action: linking ? 'link' : action?.name,
        ).toJson(),
      ),
    );
    final credential = await sdk.authenticate(
      provider,
      challenge.nonce,
      config,
    );
    if (isClosed || token.isCancelled) return;
    if (credential == null) {
      emit(
        const ProviderState(
          step: ProviderStep.done,
          result: {'status': 'cancelled'},
        ),
      );
      return;
    }
    final result = await _call(
      'auth/${provider.name}',
      token,
      authenticated: action != null || linking,
      data: ProviderCredentialInput(
        challengeId: challenge.challengeId,
        verifier: challenge.verifier,
        idToken: credential.idToken,
        authorizationCode: credential.authorizationCode,
        displayName: credential.name?.isEmpty == true ? null : credential.name,
      ).toJson(),
    );
    await _receive(result, token);
  });
  Future<void> _receive(Map<String, dynamic> result, CancelToken token) async {
    if (isClosed || token.isCancelled) return;
    final kind = result['kind'];
    if (kind == 'reauthenticated') {
      final proof = ReauthGrantDto.fromJson(result);
      _proof = proof.token;
      if (initialPending != null) {
        await _call(
          'auth/identities/link',
          token,
          authenticated: true,
          data: IdentityLinkInput(
            pendingToken: initialPending!.pendingToken,
            reauthToken: proof.token,
          ).toJson(),
        );
        if (!isClosed && !token.isCancelled) {
          emit(
            ProviderState(
              step: ProviderStep.done,
              result: const {'status': 'linked'},
            ),
          );
        }
      } else if (!isClosed && !token.isCancelled) {
        emit(ProviderState(step: ProviderStep.done, result: result));
      }
      return;
    }
    if (kind == 'session' && !linking && action == null) {
      final value = ProviderSessionDto.fromJson(result);
      final session = await repository.acceptProviderSession(
        value.session.toJson(),
        epoch: epoch,
        cancelToken: token,
      );
      if (!isClosed && !token.isCancelled) {
        emit(ProviderState(step: ProviderStep.done, session: session));
      }
      return;
    }
    if (kind == 'setupRequired' || kind == 'linkRequired') {
      final pending = ProviderSetupDto.fromJson(result);
      if (linking) {
        if (_proof == null) throw const AuthFailure('REAUTH_REQUIRED');
        await _call(
          'auth/identities/link',
          token,
          authenticated: true,
          data: IdentityLinkInput(
            pendingToken: pending.pendingToken,
            reauthToken: _proof!,
          ).toJson(),
        );
        if (!isClosed && !token.isCancelled) {
          emit(
            const ProviderState(
              step: ProviderStep.done,
              result: {'status': 'linked'},
            ),
          );
        }
      } else {
        emit(
          ProviderState(
            step: kind == 'linkRequired'
                ? ProviderStep.collision
                : ProviderStep.setup,
            config: state.config,
            pending: pending,
          ),
        );
      }
      return;
    }
    if (kind == 'emailRequired') {
      final value = ProviderEmailStepDto.fromJson(result);
      emit(
        ProviderState(
          step: ProviderStep.emailCode,
          config: state.config,
          pending: state.pending,
          challenge: value.challenge,
        ),
      );
      return;
    }
    throw const AuthFailure('invalid_response');
  }

  Future<void> continueSetup(String email) => _run((token) async {
    final pending = state.pending;
    if (pending == null ||
        !DateTime.parse(pending.expiresAt).isAfter(DateTime.now())) {
      throw const AuthFailure('PROVIDER_INVALID');
    }
    await _receive(
      await _call(
        pending.emailRequired
            ? 'auth/providers/email'
            : 'auth/providers/continue',
        token,
        data: pending.emailRequired
            ? ProviderEmailInput(
                pendingToken: pending.pendingToken,
                termsAccepted: true,
                email: email.trim(),
              ).toJson()
            : ProviderContinueInput(
                pendingToken: pending.pendingToken,
                termsAccepted: true,
              ).toJson(),
      ),
      token,
    );
  });
  Future<void> verifyEmail(String code) => _run((token) async {
    await _receive(
      await _call(
        'auth/providers/email/verify',
        token,
        data: ProviderEmailVerifyInput(
          pendingToken: state.pending!.pendingToken,
          challengeId: state.challenge!.challengeId,
          code: code,
        ).toJson(),
      ),
      token,
    );
  });
  Future<void> password(String password) => _run((token) async {
    final result = await _call(
      'me/reauth/password',
      token,
      authenticated: true,
      data: ReauthPasswordInput(
        password: password,
        action: action?.name ?? 'link',
      ).toJson(),
    );
    if (linking && initialPending == null) {
      _proof = ReauthGrantDto.fromJson(result).token;
      emit(ProviderState(config: state.config, methods: state.methods));
    } else {
      await _receive(result, token);
    }
  });
  Future<void> unlink(IdentityProvider provider, String proof) => _run((
    token,
  ) async {
    await _call(
      'me/identities/unlink',
      token,
      authenticated: true,
      data: IdentityUnlinkInput(
        provider: provider.name,
        reauthToken: proof,
      ).toJson(),
    );
    final methods = IdentityMethodsDto.fromJson(
      await _call('me/identities', token, authenticated: true, method: 'GET'),
    );
    if (!isClosed && !token.isCancelled) {
      emit(ProviderState(config: state.config, methods: methods));
    }
  });
  bool get hasLinkProof => _proof != null;
  void acceptLinkProof(String proof) {
    _proof = proof;
  }

  @override
  Future<void> close() {
    _request?.cancel();
    _proof = null;
    return super.close();
  }
}
