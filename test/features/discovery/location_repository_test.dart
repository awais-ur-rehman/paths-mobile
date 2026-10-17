import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/auth/data/http_auth_repository.dart';

import '../auth/auth_repository_test.dart';

void main() {
  test('lease mapping binds the account and keeps the upload credential out of the account vault', () async {
    final adapter = ApiAdapter(), vault = MemoryVault();
    final repo = HttpAuthRepository(
      origin: 'https://api.example.invalid',
      vault: vault,
      preferences: MemoryPreferences(),
      publicTransport: Dio()..httpClientAdapter = adapter,
      authenticatedTransport: Dio()..httpClientAdapter = adapter,
    );
    await repo.login('fixture@example.invalid', 'a long fixture password');
    expect(
      repo.currentTrackingAccountId,
      '11111111-1111-4111-8111-111111111111',
    );
    final state = await repo.trackingState();
    final paused = await repo.pauseTracking(state.consentEpoch);
    final lease = await repo.createTrackingLease(paused.consentEpoch);
    expect(lease.consentEpoch, 3);
    expect(lease.uploadToken, 'a' * 64);
    expect(vault.value, isNot(contains(lease.uploadToken)));
    final request = adapter.requests.last;
    expect(request.headers['Authorization'], 'Bearer old-access');
    expect((request.data as Map)['consentAccepted'], true);
    expect((request.data as Map)['disclosureVersion'], 'location.v1');
    await repo.close();
  });
}
