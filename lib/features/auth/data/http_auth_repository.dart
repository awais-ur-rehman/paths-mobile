import '../domain/provider_auth.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../../../core/network/authenticated_media_api.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../../core/network/authenticated_api.dart';
import '../../../core/network/refresh_coordinator.dart';
import '../domain/auth_models.dart';
import '../../profile/domain/profile_repository.dart';
import '../../discovery/domain/location_repository.dart';
import '../../discovery/domain/encounter_repository.dart';
import '../../verification/domain/verification_repository.dart';
import '../domain/auth_repository.dart';

final class HttpAuthRepository
    implements
        AuthRepository,
        ProviderAuthRepository,
        ProfileRepository,
        ProfileSummaryRepository,
        VerificationRepository,
        LocationRepository,
        EncounterRepository,
        AuthenticatedApi,
        AuthenticatedMediaApi {
  HttpAuthRepository({
    required String origin,
    required this._vault,
    required this._preferences,
    Dio? publicTransport,
    Dio? authenticatedTransport,
    this._purgeTracking,
    this._purgeNotifications,
    this.purgeMedia,
  }) : _public = publicTransport ?? Dio(),
       _private = authenticatedTransport ?? Dio() {
    final uri = Uri.tryParse(origin);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        (uri.scheme != 'https' &&
            !(kDebugMode && uri.scheme == 'http' && uri.host == '127.0.0.1'))) {
      throw const AuthFailure('configuration');
    }
    for (final dio in [_public, _private]) {
      dio.options = BaseOptions(
        baseUrl: origin.replaceAll(RegExp(r'/$'), ''),
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
        followRedirects: false,
      );
    }
    _coordinator = RefreshCoordinator(_refresh);
    _private.interceptors.add(
      SessionRefreshInterceptor(_private, _coordinator),
    );
  }
  final Future<void> Function()? purgeMedia;
  final Future<void> Function()? _purgeTracking;
  final Future<void> Function()? _purgeNotifications;
  final TokenVault _vault;
  final AuthPreferences _preferences;
  final Dio _public, _private;
  late final RefreshCoordinator _coordinator;
  final _changes = StreamController<AuthAccount?>.broadcast(sync: true);
  AuthSession? _session;
  int _generation = 0;
  bool _cleanupPending = false;
  Future<void> _storageTail = Future.value();
  Future<String>? _device;
  @override
  Stream<AuthAccount?> get changes => _changes.stream;

  Future<T> _stored<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on SessionUnavailable {
      throw const AuthFailure('cancelled');
    } catch (_) {
      throw const AuthFailure('storage');
    }
  }

  Future<void> _serialize(Future<void> Function() action) {
    final operation = _storageTail.then((_) => _stored(action));
    // Callers receive the error; the tail remains usable for a later cleanup/retry.
    _storageTail = operation.then<void>((_) {}, onError: (Object _) {});
    return operation;
  }

  Future<String> _deviceId() => _device ??= _stored(() async {
    final existing = await _preferences.deviceId();
    if (existing != null) return existing;
    final random = Random.secure();
    final value = List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _preferences.setDeviceId(value);
    return value;
  });
  @override
  String? get accountId => currentTrackingAccountId;
  @override
  Future<String> installationId() => _deviceId();
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) async {
    if (!path.startsWith('/v1/') ||
        Uri.parse(path).hasScheme ||
        path.contains('..')) {
      throw const AuthFailure('configuration');
    }
    final generation = _generation, account = accountId;
    if (account == null) throw const AuthFailure('SESSION_INVALID');
    final result = await _request(
      method,
      path,
      data: data,
      authenticated: true,
      idempotencyKey: idempotencyKey,
      cancelToken: cancelToken,
    );
    if (generation != _generation || account != accountId) {
      throw const AuthFailure('cancelled');
    }
    return result;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    bool authenticated = false,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await (authenticated ? _private : _public)
          .request<Object?>(
            path,
            data: data,
            cancelToken: cancelToken,
            options: Options(
              method: method,
              headers: {
                'X-Device-Id': await _deviceId(),
                if (authenticated &&
                    ![
                      'GET',
                      'HEAD',
                      'OPTIONS',
                      'PUT',
                      'DELETE',
                    ].contains(method))
                  'Idempotency-Key':
                      idempotencyKey ??
                      List.generate(
                        16,
                        (_) => Random.secure()
                            .nextInt(256)
                            .toRadixString(16)
                            .padLeft(2, '0'),
                      ).join(),
              },
            ),
          );
      if (response.data is! Map<String, dynamic>) {
        throw const AuthFailure('invalid_response');
      }
      return response.data! as Map<String, dynamic>;
    } on DioException catch (error) {
      if (error.error is RefreshFailure) {
        throw AuthFailure((error.error! as RefreshFailure).kind.name);
      }
      if (error.error is FormatException) {
        throw const AuthFailure('invalid_response');
      }
      if (error.type == DioExceptionType.cancel) {
        throw const AuthFailure('cancelled');
      }
      if ([
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      ].contains(error.type)) {
        throw const AuthFailure('timeout');
      }
      if (error.response == null) throw const AuthFailure('offline');
      final body = error.response!.data;
      final code = body is Map ? body['code'] : null;
      final requestId = error.response!.headers.value('x-request-id');
      throw AuthFailure(
        code is String && RegExp(r'^[A-Z_]{1,64}$').hasMatch(code)
            ? code
            : 'unavailable',
        requestId:
            requestId != null &&
                RegExp(r'^[a-fA-F0-9-]{36}$').hasMatch(requestId)
            ? requestId
            : null,
      );
    } on FormatException {
      throw const AuthFailure('invalid_response');
    }
  }

  void _mediaId(String id) {
    if (!RegExp(
      r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-4[a-fA-F0-9]{3}-[89abAB][a-fA-F0-9]{3}-[a-fA-F0-9]{12}$',
    ).hasMatch(id)) {
      throw const AuthFailure('configuration');
    }
  }

  Future<Response<T>> _binary<T>(
    String id, {
    Uint8List? bytes,
    bool thumbnail = true,
    CancelToken? cancelToken,
    ProgressCallback? onProgress,
  }) async {
    _mediaId(id);
    if (bytes != null && (bytes.isEmpty || bytes.length > 10 * 1024 * 1024)) {
      throw const AuthFailure('image_size');
    }
    final generation = _generation, account = accountId;
    if (account == null) throw const AuthFailure('SESSION_INVALID');
    try {
      final response = await _private.request<T>(
        '/v1/media/$id/${bytes == null ? 'content?variant=${thumbnail ? 'thumbnail' : 'display'}' : 'source'}',
        data: bytes,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
        options: Options(
          method: bytes == null ? 'GET' : 'PUT',
          responseType: bytes == null ? ResponseType.bytes : ResponseType.json,
          contentType: bytes == null ? null : 'application/octet-stream',
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'X-Device-Id': await _deviceId()},
          receiveDataWhenStatusError: false,
        ),
        onReceiveProgress: (received, total) {
          if (received > 10 * 1024 * 1024) cancelToken?.cancel();
        },
      );
      if (generation != _generation || account != accountId) {
        throw const AuthFailure('cancelled');
      }
      return response;
    } on DioException catch (error) {
      if (error.error is RefreshFailure) {
        throw AuthFailure((error.error! as RefreshFailure).kind.name);
      }
      if (error.type == DioExceptionType.cancel) {
        throw const AuthFailure('cancelled');
      }
      if ([
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      ].contains(error.type)) {
        throw const AuthFailure('timeout');
      }
      throw AuthFailure(
        error.response == null
            ? 'offline'
            : error.response!.statusCode == 404
            ? 'media_unavailable'
            : 'unavailable',
      );
    }
  }

  @override
  Future<void> uploadImage(
    String assetId,
    Uint8List bytes, {
    CancelToken? cancelToken,
    ProgressCallback? onProgress,
  }) async {
    await _binary<Object?>(
      assetId,
      bytes: bytes,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );
  }

  @override
  Future<Uint8List> imageBytes(
    String assetId, {
    bool thumbnail = true,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    final response = await _binary<List<int>>(
      assetId,
      thumbnail: thumbnail,
      cancelToken: token,
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const AuthFailure('invalid_response');
    }
    return Uint8List.fromList(bytes);
  }

  AuthAccount _account(AccountDto dto) => AuthAccount(
    id: dto.userId,
    email: dto.email,
    name: dto.name,
    restricted: dto.accountStatus == 'deactivated',
    adultChecked: dto.setupStage == 'profile',
  );
  AuthSession _decode(SessionDto dto) {
    if (dto.accessToken.isEmpty || dto.refreshToken.isEmpty) {
      throw const FormatException();
    }
    return AuthSession(
      account: AuthAccount(
        id: dto.userId,
        email: dto.email,
        name: dto.name,
        restricted: dto.accountStatus == 'deactivated',
        adultChecked: dto.setupStage == 'profile',
      ),
      tokens: SessionTokens(
        accessToken: dto.accessToken,
        refreshToken: dto.refreshToken,
      ),
      accessExpiresAt: DateTime.parse(dto.accessExpiresAt),
      refreshExpiresAt: DateTime.parse(dto.refreshExpiresAt),
    );
  }

  Map<String, dynamic> _encode(AuthSession session) => SessionDto(
    userId: session.account.id,
    email: session.account.email,
    name: session.account.name,
    accountStatus: session.account.restricted ? 'deactivated' : 'active',
    setupStage: session.account.adultChecked ? 'profile' : 'adult',
    accessToken: session.tokens.accessToken,
    refreshToken: session.tokens.refreshToken,
    accessExpiresAt: session.accessExpiresAt.toUtc().toIso8601String(),
    refreshExpiresAt: session.refreshExpiresAt.toUtc().toIso8601String(),
  ).toJson();
  AuthChallenge _challenge(ChallengeDto dto) => AuthChallenge(
    id: dto.challengeId,
    purpose: dto.purpose,
    expiresAt: DateTime.parse(dto.expiresAt),
    resendAt: DateTime.parse(dto.resendAt),
  );
  Future<void> _persist(AuthSession session, int generation) async {
    await _serialize(() async {
      if (generation != _generation) throw const SessionUnavailable();
      if (_cleanupPending) throw const AuthFailure('storage');
      await _vault.write(jsonEncode(_encode(session)));
      if (generation != _generation) throw const SessionUnavailable();
      await _preferences.setFlag('paths.auth.signedOut', false);
    });
    if (generation != _generation) throw const AuthFailure('cancelled');
    _session = session;
  }

  Future<void> _clearPush() async {
    try {
      await _purgeNotifications?.call();
    } catch (_) {
      throw const AuthFailure('push_cleanup');
    }
  }

  Future<void> _purge({bool notifications = true}) async {
    await Future.wait([
      if (notifications) _clearPush(),
      _clearTracking(),
      if (purgeMedia != null) purgeMedia!(),
    ]);
  }

  Future<void> _clearTracking() async {
    try {
      await _purgeTracking?.call();
    } catch (_) {
      throw const AuthFailure('tracking_cleanup');
    }
  }

  Future<void> _invalidate() async {
    final generation = ++_generation;
    _cleanupPending = true;
    _session = null;
    _coordinator.replace(null);
    try {
      await Future.wait([
        _serialize(() async {
          // Attempt credential deletion even if the durable tombstone cannot be written.
          await Future.wait([
            _preferences.setFlag('paths.auth.signedOut', true),
            _vault.clear(),
          ]);
        }),
        _purge(),
      ]);
    } on AuthFailure catch (error) {
      if (generation == _generation && _changes.hasListener) {
        _changes.addError(error);
      }
      rethrow;
    }
    if (generation == _generation) {
      _cleanupPending = false;
      _changes.add(null);
    }
  }

  Future<AuthSession> _accept(SessionDto dto, int generation) async {
    final session = _decode(dto);
    await _persist(session, generation);
    if (generation != _generation) throw const AuthFailure('cancelled');
    _coordinator.replace(session.tokens);
    return session;
  }

  Future<SessionTokens> _refresh(String token) async {
    final generation = _generation;
    try {
      final dto = SessionDto.fromJson(
        await _request(
          'POST',
          '/v1/auth/refresh',
          data: RefreshInput(refreshToken: token).toJson(),
        ),
      );
      final session = _decode(dto);
      await _persist(session, generation);
      if (generation != _generation) throw const AuthFailure('cancelled');
      _changes.add(session.account);
      return session.tokens;
    } on AuthFailure catch (error) {
      if (generation == _generation &&
          [
            'SESSION_INVALID',
            'UNAUTHENTICATED',
            'INVALID_CREDENTIALS',
          ].contains(error.code)) {
        await _invalidate();
      }
      if (generation != _generation) throw const AuthFailure('cancelled');
      if (error.offline ||
          [
            'unavailable',
            'RATE_LIMITED',
            'INTERNAL_ERROR',
            'DEPENDENCY_UNAVAILABLE',
            'invalid_response',
          ].contains(error.code)) {
        throw RefreshFailure(
          error.code == 'timeout'
              ? RefreshFailureKind.timeout
              : error.code == 'offline'
              ? RefreshFailureKind.offline
              : RefreshFailureKind.unavailable,
        );
      }
      if (error.code == 'storage') {
        await _invalidate();
        throw const RefreshFailure(RefreshFailureKind.storage);
      }
      rethrow;
    } on FormatException {
      if (generation != _generation) throw const AuthFailure('cancelled');
      // A malformed server response does not establish credential revocation.
      throw const RefreshFailure(RefreshFailureKind.unavailable);
    }
  }

  @override
  Future<AuthSession?> restore({CancelToken? cancelToken}) async {
    if (_cleanupPending) {
      await _invalidate();
      return null;
    }
    // Cold restoration clears prior-process resources; a warm validation must not stop live tracking.
    if (_session == null) await _purge(notifications: false);
    if (!await _stored<bool?>(() => _preferences.flag('paths.auth.installed'))
        .then((value) => value ?? false)) {
      await _clearPush();
      await _serialize(() async {
        await _vault.clear();
        await _preferences.setFlag('paths.auth.installed', true);
      });
    }
    if (await _stored<bool?>(() => _preferences.flag('paths.auth.signedOut')) ==
        true) {
      await _clearPush();
      await _serialize(_vault.clear);
      return null;
    }
    if (_session == null) {
      final raw = await _stored(
        () => _vault.read().timeout(const Duration(seconds: 5)),
      );
      if (raw == null) {
        await _clearPush();
        return null;
      }
      try {
        _session = _decode(
          SessionDto.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } on Object {
        await _invalidate();
        throw const AuthFailure('SESSION_INVALID');
      }
      if (!_session!.refreshExpiresAt.isAfter(DateTime.now())) {
        await _invalidate();
        throw const AuthFailure('SESSION_INVALID');
      }
      _coordinator.replace(_session!.tokens);
    }
    final generation = _generation;
    try {
      final account = _account(
        AccountDto.fromJson(
          await _request(
            'GET',
            '/v1/me/session',
            authenticated: true,
            cancelToken: cancelToken,
          ),
        ),
      );
      final current = _session;
      if (current == null || generation != _generation) {
        throw const AuthFailure('cancelled');
      }
      if (account.restricted) await _purge(notifications: false);
      final updated = AuthSession(
        account: account,
        tokens: current.tokens,
        accessExpiresAt: current.accessExpiresAt,
        refreshExpiresAt: current.refreshExpiresAt,
      );
      await _persist(updated, generation);
      if (generation != _generation) throw const AuthFailure('cancelled');
      return updated;
    } on AuthFailure catch (error) {
      if (error.code == 'SESSION_INVALID' && generation == _generation) {
        await _invalidate();
      }
      rethrow;
    } on FormatException {
      throw const AuthFailure('invalid_response');
    }
  }

  ProfileDetails _profile(ProfileDetailsDto dto) => ProfileDetails(
    username: dto.username,
    name: dto.name,
    gender: dto.gender,
    bio: dto.bio,
    visibility: dto.visibility,
    avatarAssetId: dto.avatarAssetId,
    profileComplete: dto.profileComplete,
  );
  @override
  Future<ProfileDetails> loadProfile({CancelToken? cancelToken}) async =>
      _profile(
        ProfileDetailsDto.fromJson(
          await _request(
            'GET',
            '/v1/me/profile',
            authenticated: true,
            cancelToken: cancelToken,
          ),
        ),
      );
  @override
  Future<ProfileDetails> saveProfile(
    ProfileDetails profile, {
    CancelToken? cancelToken,
  }) async => _profile(
    ProfileDetailsDto.fromJson(
      await _request(
        'PUT',
        '/v1/me/profile',
        authenticated: true,
        cancelToken: cancelToken,
        data: ProfileDetailsInput(
          username: profile.username,
          name: profile.name,
          gender: profile.gender,
          bio: profile.bio,
          visibility: profile.visibility,
          avatarAssetId: profile.avatarAssetId,
        ).toJson(),
      ),
    ),
  );

  @override
  Future<ProfileSummary> loadProfileSummary(
    String userId, {
    CancelToken? cancelToken,
  }) async {
    final dto = ProfileSummaryDto.fromJson(
      await _request(
        'GET',
        '/v1/profiles/$userId',
        authenticated: true,
        cancelToken: cancelToken,
      ),
    );
    return ProfileSummary(
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
    );
  }

  @override
  String? get discoveryAccountId => currentTrackingAccountId;

  @override
  Future<EncounterPage> loadEncounters({
    EncounterMode mode = EncounterMode.recent,
    double radiusKm = 1,
    String search = '',
    String? cursor,
    CancelToken? cancelToken,
  }) async {
    if (!encounterRadii.contains(radiusKm)) {
      throw ArgumentError.value(radiusKm, 'radiusKm');
    }
    final path = Uri(
      path: '/v1/encounters',
      queryParameters: {
        'mode': mode.name,
        'limit': '50',
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'radiusKm': radiusKm.toString(),
        'cursor': ?cursor,
      },
    ).toString();
    try {
      final dto = EncounterPageDto.fromJson(
        await _request(
          'GET',
          path,
          authenticated: true,
          cancelToken: cancelToken,
        ),
      );
      return EncounterPage(
        items: dto.items
            .map(
              (item) => Encounter(
                encounterId: item.encounterId,
                avatarAssetId: item.avatarAssetId,
                isSaved: item.isSaved,
                requestState: item.requestState,
                userId: item.userId,
                username: item.username,
                displayName: item.displayName,
                age: item.age.toInt(),
                bio: item.bio,
                verificationStatus: item.verificationStatus,
                coarseAreaId: item.coarseAreaId,
                coarseAreaLabel: item.coarseAreaLabel,
                areaLatitude: item.areaLatitude.toDouble(),
                areaLongitude: item.areaLongitude.toDouble(),
                timeBucket: item.timeBucket,
                encounterDate: item.encounterDate,
                encounterCount: item.encounterCount.toInt(),
                eligibilityExpiresAt: item.eligibilityExpiresAt,
              ),
            )
            .toList(),
        nextCursor: dto.nextCursor,
        nearbyAvailable: dto.nearbyAvailable,
        centerLatitude: dto.centerLatitude?.toDouble(),
        centerLongitude: dto.centerLongitude?.toDouble(),
      );
    } on FormatException {
      throw const AuthFailure('invalid_response');
    }
  }

  VerificationInfo _verification(VerificationDto dto) => VerificationInfo(
    status: dto.status,
    offerSeen: dto.offerSeen,
    uploadsAvailable: dto.uploadsAvailable,
    reason: dto.reason,
  );
  @override
  Future<VerificationInfo> loadVerification({CancelToken? cancelToken}) async =>
      _verification(
        VerificationDto.fromJson(
          await _request(
            'GET',
            '/v1/me/verification',
            authenticated: true,
            cancelToken: cancelToken,
          ),
        ),
      );
  @override
  Future<VerificationInfo> skipVerification({CancelToken? cancelToken}) async =>
      _verification(
        VerificationDto.fromJson(
          await _request(
            'POST',
            '/v1/me/verification/skip',
            authenticated: true,
            cancelToken: cancelToken,
          ),
        ),
      );
  @override
  Future<VerificationInfo> submitVerification({
    required String frontAssetId,
    String? backAssetId,
    required bool consent,
    CancelToken? cancelToken,
  }) async => _verification(
    VerificationDto.fromJson(
      await _request(
        'POST',
        '/v1/me/verification',
        authenticated: true,
        cancelToken: cancelToken,
        data: VerificationInput(
          frontAssetId: frontAssetId,
          backAssetId: backAssetId,
          consent: consent,
        ).toJson(),
      ),
    ),
  );

  Future<String> realtimeToken() async {
    final owner = accountId;
    await request('GET', '/v1/me/session');
    final token = _coordinator.tokens?.accessToken;
    if (owner == null || owner != accountId || token == null) {
      throw const AuthFailure('cancelled');
    }
    return token;
  }

  @override
  String? get currentTrackingAccountId => _session?.account.id;
  TrackingControl _trackingControl(TrackingControlDto dto) =>
      TrackingControl(dto.consentEpoch, dto.paused);
  @override
  Future<TrackingControl> trackingState({CancelToken? cancelToken}) async =>
      _trackingControl(
        TrackingControlDto.fromJson(
          await _request(
            'GET',
            '/v1/me/location',
            authenticated: true,
            cancelToken: cancelToken,
          ),
        ),
      );
  @override
  Future<TrackingControl> pauseTracking(
    int expectedConsentEpoch, {
    CancelToken? cancelToken,
  }) async => _trackingControl(
    TrackingControlDto.fromJson(
      await _request(
        'POST',
        '/v1/me/location/pause',
        authenticated: true,
        cancelToken: cancelToken,
        data: TrackingControlInput(expectedConsentEpoch: expectedConsentEpoch)
            .toJson(),
      ),
    ),
  );
  @override
  Future<LocationLease> createTrackingLease(
    int expectedConsentEpoch, {
    CancelToken? cancelToken,
  }) async {
    final id = List.generate(
      16,
      (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final dto = TrackingLeaseDto.fromJson(
      await _request(
        'POST',
        '/v1/me/location/lease',
        authenticated: true,
        cancelToken: cancelToken,
        data: TrackingLeaseInput(
          expectedConsentEpoch: expectedConsentEpoch,
          requestId: id,
          clientTimeMs: DateTime.now().millisecondsSinceEpoch,
          disclosureVersion: 'location.v1',
          consentAccepted: true,
        ).toJson(),
      ),
    );
    return LocationLease(
      dto.deviceSessionId,
      dto.consentEpoch,
      dto.uploadToken,
      DateTime.parse(dto.expiresAt),
      dto.serverTimeMs,
    );
  }

  @override
  Future<bool> onboardingSeen() async =>
      await _stored<bool?>(() => _preferences.flag('paths.auth.onboarding')) ??
      false;
  @override
  Future<void> finishOnboarding() =>
      _stored(() => _preferences.setFlag('paths.auth.onboarding', true));
  @override
  Future<PolicyConfig> policies({CancelToken? cancelToken}) async {
    final dto = AuthConfigDto.fromJson(
      await _request('GET', '/v1/auth/config', cancelToken: cancelToken),
    );
    return PolicyConfig(
      supportEmail: dto.supportEmail,
      termsUrl: dto.termsUrl,
      privacyUrl: dto.privacyUrl,
    );
  }

  @override
  Future<AuthChallenge> signup(
    String name,
    String email,
    String password,
    bool terms, {
    CancelToken? cancelToken,
  }) async => _challenge(
    ChallengeDto.fromJson(
      await _request(
        'POST',
        '/v1/auth/signup',
        data: SignupInput(
          name: name,
          email: email,
          password: password,
          termsAccepted: terms,
        ).toJson(),
        cancelToken: cancelToken,
      ),
    ),
  );
  @override
  int get providerEpoch => _generation;
  @override
  Future<ProviderConfigDto> providerConfig({CancelToken? cancelToken}) async =>
      ProviderConfigDto.fromJson(
        await _request('GET', '/v1/auth/providers', cancelToken: cancelToken),
      );
  @override
  Future<Map<String, dynamic>> providerRequest(
    String method,
    String path, {
    Map<String, dynamic>? data,
    bool authenticated = false,
    required int epoch,
    CancelToken? cancelToken,
  }) async {
    if (epoch != _generation) throw const AuthFailure('cancelled');
    if (!path.startsWith('/v1/auth/') && !path.startsWith('/v1/me/')) {
      throw const AuthFailure('configuration');
    }
    final result = await _request(
      method,
      path,
      data: data,
      authenticated: authenticated,
      cancelToken: cancelToken,
    );
    if (epoch != _generation || cancelToken?.isCancelled == true) {
      throw const AuthFailure('cancelled');
    }
    return result;
  }

  @override
  Future<AuthSession> acceptProviderSession(
    Map<String, dynamic> value, {
    required int epoch,
    CancelToken? cancelToken,
  }) async {
    if (epoch != _generation || cancelToken?.isCancelled == true) {
      throw const AuthFailure('cancelled');
    }
    final generation = ++_generation;
    _coordinator.replace(null);
    final session = await _accept(SessionDto.fromJson(value), generation);
    if (cancelToken?.isCancelled == true) {
      if (_generation == generation) await _invalidate();
      throw const AuthFailure('cancelled');
    }
    return session;
  }

  @override
  Future<AuthSession> login(
    String email,
    String password, {
    CancelToken? cancelToken,
  }) async {
    final generation = ++_generation;
    _coordinator.replace(null);
    return _accept(
      SessionDto.fromJson(
        await _request(
          'POST',
          '/v1/auth/login',
          data: LoginInput(email: email, password: password).toJson(),
          cancelToken: cancelToken,
        ),
      ),
      generation,
    );
  }

  @override
  Future<AuthChallenge> forgot(
    String email, {
    CancelToken? cancelToken,
  }) async => _challenge(
    ChallengeDto.fromJson(
      await _request(
        'POST',
        '/v1/auth/password/forgot',
        data: EmailInput(email: email).toJson(),
        cancelToken: cancelToken,
      ),
    ),
  );
  @override
  Future<AuthChallenge> resend(
    AuthChallenge challenge, {
    CancelToken? cancelToken,
  }) async => _challenge(
    ChallengeDto.fromJson(
      await _request(
        'POST',
        '/v1/auth/otp/resend',
        data: ChallengeInput(challengeId: challenge.id).toJson(),
        cancelToken: cancelToken,
      ),
    ),
  );
  @override
  Future<Object> verify(
    AuthChallenge challenge,
    String code, {
    CancelToken? cancelToken,
  }) async {
    final generation = _generation;
    final json = await _request(
      'POST',
      '/v1/auth/otp/verify',
      data: VerifyInput(
        challengeId: challenge.id,
        purpose: challenge.purpose,
        code: code,
      ).toJson(),
      cancelToken: cancelToken,
    );
    if (generation != _generation) throw const AuthFailure('cancelled');
    if (challenge.purpose == 'signup') {
      return _accept(SessionDto.fromJson(json), generation);
    }
    final dto = ResetGrantDto.fromJson(json);
    return ResetGrant(dto.resetToken, DateTime.parse(dto.expiresAt));
  }

  @override
  Future<void> reset(
    ResetGrant grant,
    String password, {
    CancelToken? cancelToken,
  }) async {
    await _request(
      'POST',
      '/v1/auth/password/reset',
      data: ResetInput(resetToken: grant.token, password: password).toJson(),
      cancelToken: cancelToken,
    );
    await _invalidate();
  }

  @override
  Future<AuthAccount> checkAdult(
    String dateOfBirth, {
    CancelToken? cancelToken,
  }) async {
    final generation = _generation;
    final account = _account(
      AccountDto.fromJson(
        await _request(
          'POST',
          '/v1/me/adult-check',
          data: AdultInput(dateOfBirth: dateOfBirth).toJson(),
          authenticated: true,
          cancelToken: cancelToken,
        ),
      ),
    );
    final current = _session;
    if (current == null || generation != _generation) {
      throw const AuthFailure('cancelled');
    }
    await _persist(
      AuthSession(
        account: account,
        tokens: current.tokens,
        accessExpiresAt: current.accessExpiresAt,
        refreshExpiresAt: current.refreshExpiresAt,
      ),
      generation,
    );
    if (generation != _generation) throw const AuthFailure('cancelled');
    return account;
  }

  Future<void> eraseAcceptedAccount(String owner) async {
    if (_session != null && _session!.account.id != owner) return;
    await _invalidate();
    await _device;
    await _preferences.clearDeviceId();
    _device = null;
  }

  @override
  Future<void> logout() async {
    final token = _session?.tokens.refreshToken;
    await _invalidate();
    if (token != null) {
      await _request(
        'POST',
        '/v1/auth/logout',
        data: RefreshInput(refreshToken: token).toJson(),
      );
    }
  }

  @override
  Future<void> close() async {
    _generation++;
    _coordinator.replace(null);
    _public.close(force: true);
    _private.close(force: true);
    await _storageTail;
    await _changes.close();
  }
}
