import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/discovery/domain/encounter_repository.dart';
import 'package:paths_mobile/features/discovery/presentation/encounter_markers.dart';

import 'encounter_bloc_test.dart' show encounter;

Encounter at(String id, String area, {double latitude = 33.7}) {
  final e = encounter(id);
  return Encounter(
    encounterId: e.encounterId,
    userId: e.userId,
    username: e.username,
    displayName: e.displayName,
    age: e.age,
    bio: e.bio,
    verificationStatus: e.verificationStatus,
    coarseAreaId: area,
    coarseAreaLabel: e.coarseAreaLabel,
    areaLatitude: latitude,
    areaLongitude: e.areaLongitude,
    timeBucket: e.timeBucket,
    encounterDate: e.encounterDate,
    encounterCount: e.encounterCount,
    eligibilityExpiresAt: e.eligibilityExpiresAt,
  );
}

void main() {
  test('one coarse area retains every person; invalid positions never reach projection', () {
    final areas = encounterAreas([
      at('a', 'one'),
      at('b', 'one'),
      at('c', 'two'),
      at('bad', 'bad', latitude: double.nan),
    ]);
    expect(areas.map((x) => x.length), [2, 1]);
    expect(areas.first.map((x) => x.userId), ['a', 'b']);
  });
  test('Android physical points become logical pixels and offscreen markers are culled', () {
    final areas = encounterAreas([at('a', 'a'), at('b', 'b'), at('c', 'c')]);
    final markers = projectEncounterMarkers(
      areas,
      [
        const Point(300, 600),
        const Point(9000, 9000),
        const Point(double.nan, 50),
      ],
      pixelRatio: 3,
      viewport: const Size(390, 844),
    );
    expect(markers.single.position, const Offset(100, 200));
    expect(markers.single.items.single.userId, 'a');
  });
  test('collisions across grid boundaries open a single group without invented geographic offsets', () {
    final areas = encounterAreas([at('a', 'a'), at('b', 'b'), at('c', 'c')]);
    final markers = projectEncounterMarkers(
      areas,
      [const Point(63, 100), const Point(66, 100), const Point(260, 100)],
      pixelRatio: 1,
      viewport: const Size(390, 844),
    );
    expect(markers, hasLength(2));
    expect(markers.first.items.map((x) => x.userId), ['a', 'b']);
    expect(markers.first.position, const Offset(63, 100));
    expect(
      () => markers.first.items.add(encounter('d')),
      throwsUnsupportedError,
    );
  });
}
