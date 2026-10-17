import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/auth/presentation/auth_cubit.dart';
import 'package:paths_mobile/features/auth/data/http_auth_repository.dart';
import 'package:dio/dio.dart';

import 'auth_repository_test.dart'
    show MemoryVault, MemoryPreferences, ApiAdapter;

void main() {
  test('duplicate login submissions produce one request and one authenticated transition', () async {
    final adapter = ApiAdapter();
    final repo = HttpAuthRepository(
      origin: 'https://api.example.invalid',
      vault: MemoryVault(),
      preferences: MemoryPreferences(),
      publicTransport: Dio()..httpClientAdapter = adapter,
      authenticatedTransport: Dio()..httpClientAdapter = adapter,
    );
    final cubit = AuthCubit(repo);
    await Future.wait([
      cubit.login('fixture@example.invalid', 'a long fixture password'),
      cubit.login('fixture@example.invalid', 'a long fixture password'),
    ]);
    expect(cubit.state.stage, AuthStage.authenticated);
    expect(adapter.requests.where((r) => r.path == '/v1/auth/login').length, 1);
    await cubit.close();
    await repo.close();
  });
  test(
    'cancelled pending storage cannot navigate back to authenticated',
    () async {
      final adapter = ApiAdapter(), vault = MemoryVault();
      vault.pause = Completer<void>();
      final repo = HttpAuthRepository(
        origin: 'https://api.example.invalid',
        vault: vault,
        preferences: MemoryPreferences(),
        publicTransport: Dio()..httpClientAdapter = adapter,
        authenticatedTransport: Dio()..httpClientAdapter = adapter,
      );
      final cubit = AuthCubit(repo);
      final login = cubit.login(
        'fixture@example.invalid',
        'a long fixture password',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final cancel = cubit.cancelFlow();
      vault.pause!.complete();
      await login;
      await cancel;
      expect(cubit.state.stage, AuthStage.signedOut);
      expect(vault.value, null);
      await cubit.close();
      await repo.close();
    },
  );
}
