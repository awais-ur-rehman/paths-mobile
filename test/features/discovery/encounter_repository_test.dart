import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/auth/data/http_auth_repository.dart';
import 'package:paths_mobile/features/discovery/domain/encounter_repository.dart';

import '../auth/auth_repository_test.dart';

class EncounterAdapter extends ApiAdapter {
  RequestOptions? discovery;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path != '/v1/encounters') {
      return super.fetch(options, requestStream, cancelFuture);
    }
    discovery = options;
    return ResponseBody.fromString(
      jsonEncode({
        'items': [
          {
            'encounterId': 'event-a',
            'userId': 'peer-a',
            'username': 'fixture',
            'displayName': 'Fixture',
            'age': 30,
            'bio': 'Test',
            'verificationStatus': 'none',
            'photoState': 'unavailable',
            'coarseAreaId': 'area.v1:1:2',
            'coarseAreaLabel': 'Encounter area',
            'areaLatitude': 33.7,
            'areaLongitude': 73.1,
            'timeBucket': 'recently',
            'encounterDate': '2026-10-17',
            'encounterCount': 2,
            'requestState': 'none',
            'eligibilityExpiresAt': '2026-11-16',
          },
        ],
        'nextCursor': null,
        'nearbyAvailable': true,
        'centerLatitude': 33.7,
        'centerLongitude': 73.1,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  test('discovery maps the authenticated coarse contract and sends only bounded filters', () async {
    final adapter = EncounterAdapter();
    final repo = HttpAuthRepository(
      origin: 'https://api.example.invalid',
      vault: MemoryVault(),
      preferences: MemoryPreferences(),
      publicTransport: Dio()..httpClientAdapter = adapter,
      authenticatedTransport: Dio()..httpClientAdapter = adapter,
    );
    await repo.login('fixture@example.invalid', 'a long fixture password');
    final page = await repo.loadEncounters(
      mode: EncounterMode.nearby,
      radiusKm: 3,
      cursor: 'opaque',
    );
    expect(page.items.single.userId, 'peer-a');
    expect(page.items.single.encounterCount, 2);
    expect(page.items.single.timeLabel, 'Recently');
    expect(adapter.discovery!.headers['Authorization'], 'Bearer old-access');
    expect(adapter.discovery!.uri.queryParameters, {
      'mode': 'nearby',
      'radiusKm': '3.0',
      'cursor': 'opaque',
    });
    expect(() => page.items.clear(), throwsUnsupportedError);
    await repo.close();
  });
}
