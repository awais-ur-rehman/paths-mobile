import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/auth/domain/auth_repository.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/auth/data/http_auth_repository.dart';

class MemoryVault implements TokenVault {
  String? value;
  Completer<void>? pause;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async {
    await pause?.future;
    value = next;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class MemoryPreferences implements AuthPreferences {
  final values = <String, bool>{'paths.auth.installed': true};
  String? device;
  @override
  Future<bool?> flag(String key) async => values[key];
  @override
  Future<void> setFlag(String key, bool value) async {
    values[key] = value;
  }

  @override
  Future<String?> deviceId() async => device;
  @override
  Future<void> setDeviceId(String value) async {
    device = value;
  }
}

class ApiAdapter implements HttpClientAdapter {
  int refreshes = 0;
  bool revoked = false;
  bool offline = false;
  bool restricted = false;
  final requests = <RequestOptions>[];
  Map<String, Object> session(String access, String refresh) => {
    'userId': '11111111-1111-4111-8111-111111111111',
    'email': 'fixture@example.invalid',
    'name': 'Fixture User',
    'accountStatus': restricted ? 'deactivated' : 'active',
    'setupStage': 'adult',
    'accessToken': access,
    'refreshToken': refresh,
    'accessExpiresAt': DateTime.now()
        .add(const Duration(minutes: 10))
        .toUtc()
        .toIso8601String(),
    'refreshExpiresAt': DateTime.now()
        .add(const Duration(days: 30))
        .toUtc()
        .toIso8601String(),
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    var status = 200;
    Object body = {};
    if (options.path == '/v1/auth/config') {
      body = {
        'supportEmail': 'support@example.invalid',
        'termsUrl': '',
        'privacyUrl': '',
      };
    } else if (options.path == '/v1/auth/signup' ||
        options.path == '/v1/auth/password/forgot' ||
        options.path == '/v1/auth/otp/resend') {
      body = {
        'challengeId': '22222222-2222-4222-8222-222222222222',
        'purpose': options.path == '/v1/auth/password/forgot'
            ? 'reset'
            : 'signup',
        'expiresAt': DateTime.now()
            .add(const Duration(minutes: 5))
            .toUtc()
            .toIso8601String(),
        'resendAt': DateTime.now()
            .add(const Duration(seconds: 60))
            .toUtc()
            .toIso8601String(),
      };
    } else if (options.path == '/v1/auth/otp/verify') {
      final input = options.data as Map;
      if (input['code'] != '123456') {
        status = 400;
        body = {'code': 'OTP_INVALID'};
      } else if (input['purpose'] == 'reset') {
        body = {
          'resetToken': 'fixture-reset-grant',
          'expiresAt': DateTime.now()
              .add(const Duration(minutes: 5))
              .toUtc()
              .toIso8601String(),
        };
      } else {
        body = session('new-access', 'new-refresh');
      }
    } else if (options.path == '/v1/me/adult-check') {
      body = {...session('new-access', 'new-refresh'), 'setupStage': 'profile'};
    } else if (options.path == '/v1/auth/login') {
      body = session('old-access', 'old-refresh');
    } else if (options.path == '/v1/auth/refresh') {
      refreshes++;
      if (offline) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      status = revoked ? 401 : 200;
      body = revoked
          ? {'code': 'SESSION_INVALID'}
          : session('new-access', 'new-refresh');
    } else if (options.path == '/v1/me/session') {
      status = options.headers['Authorization'] == 'Bearer new-access'
          ? 200
          : 401;
      body = status == 200
          ? session('new-access', 'new-refresh')
          : {'code': 'SESSION_INVALID'};
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'a rotated refresh secret is persisted before authorized replay completes',
    () async {
      final vault = MemoryVault(),
          preferences = MemoryPreferences(),
          adapter = ApiAdapter();
      final repo = HttpAuthRepository(
        origin: 'https://api.example.invalid',
        vault: vault,
        preferences: preferences,
        publicTransport: Dio()..httpClientAdapter = adapter,
        authenticatedTransport: Dio()..httpClientAdapter = adapter,
      );
      try {
        await repo.login('fixture@example.invalid', 'a long fixture password');
        await repo.restore();
        expect(adapter.refreshes, 1);
        expect(vault.value, contains('new-refresh'));
        expect(vault.value, isNot(contains('old-refresh')));
      } finally {
        await repo.close();
      }
    },
  );
  test(
    'a terminal refresh failure clears secure credentials and does not loop',
    () async {
      final vault = MemoryVault(), adapter = ApiAdapter();
      final repo = HttpAuthRepository(
        origin: 'https://api.example.invalid',
        vault: vault,
        preferences: MemoryPreferences(),
        publicTransport: Dio()..httpClientAdapter = adapter,
        authenticatedTransport: Dio()..httpClientAdapter = adapter,
      );
      try {
        await repo.login('fixture@example.invalid', 'a long fixture password');
        adapter.revoked = true;
        await expectLater(repo.restore(), throwsA(isA<AuthFailure>()));
        expect(vault.value, null);
        expect(adapter.refreshes, 1);
      } finally {
        await repo.close();
      }
    },
  );
  test('logout wins over a secure-storage write already in flight', () async {
    final vault = MemoryVault(), adapter = ApiAdapter();
    final repo = HttpAuthRepository(
      origin: 'https://api.example.invalid',
      vault: vault,
      preferences: MemoryPreferences(),
      publicTransport: Dio()..httpClientAdapter = adapter,
      authenticatedTransport: Dio()..httpClientAdapter = adapter,
    );
    vault.pause = Completer<void>();
    final login = repo.login(
      'fixture@example.invalid',
      'a long fixture password',
    );
    final assertion = expectLater(login, throwsA(isA<AuthFailure>()));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final logout = repo.logout();
    vault.pause!.complete();
    await assertion;
    await logout;
    expect(vault.value, null);
    await repo.close();
  });
  test(
    'offline refresh preserves secure credentials for an explicit retry',
    () async {
      final vault = MemoryVault(), adapter = ApiAdapter();
      final repo = HttpAuthRepository(
        origin: 'https://api.example.invalid',
        vault: vault,
        preferences: MemoryPreferences(),
        publicTransport: Dio()..httpClientAdapter = adapter,
        authenticatedTransport: Dio()..httpClientAdapter = adapter,
      );
      try {
        await repo.login('fixture@example.invalid', 'a long fixture password');
        adapter.offline = true;
        await expectLater(
          repo.restore(),
          throwsA(
            isA<AuthFailure>().having((e) => e.code, 'offline', 'offline'),
          ),
        );
        expect(vault.value, contains('old-refresh'));
        adapter.offline = false;
        expect(await repo.restore(), isNotNull);
      } finally {
        await repo.close();
      }
    },
  );
  test(
    'a new installation clears a surviving keychain session before restoring',
    () async {
      final vault = MemoryVault()..value = 'old keychain data';
      final preferences = MemoryPreferences()..values.clear();
      final repo = HttpAuthRepository(
        origin: 'https://api.example.invalid',
        vault: vault,
        preferences: preferences,
      );
      try {
        expect(await repo.restore(), null);
        expect(vault.value, null);
        expect(preferences.values['paths.auth.installed'], true);
      } finally {
        await repo.close();
      }
    },
  );
  test(
    'native cleanup failure does not skip local credential removal',
    () async {
      final vault = MemoryVault(), adapter = ApiAdapter();
      final repo = HttpAuthRepository(
        origin: 'https://api.example.invalid',
        vault: vault,
        preferences: MemoryPreferences(),
        publicTransport: Dio()..httpClientAdapter = adapter,
        authenticatedTransport: Dio()..httpClientAdapter = adapter,
        purgeTracking: () async => throw StateError('fixture native failure'),
      );
      try {
        await repo.login('fixture@example.invalid', 'a long fixture password');
        await expectLater(
          repo.logout(),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.code,
              'code',
              'tracking_cleanup',
            ),
          ),
        );
        expect(vault.value, null);
      } finally {
        await repo.close();
      }
    },
  );
}
