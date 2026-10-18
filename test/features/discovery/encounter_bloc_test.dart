import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/discovery/domain/encounter_repository.dart';
import 'package:paths_mobile/features/discovery/presentation/encounter_bloc.dart';

Encounter encounter(String id) => Encounter(
  encounterId: 'event-$id',
  userId: id,
  username: 'fixture_$id',
  displayName: 'Fixture $id',
  age: 30,
  bio: 'A test profile',
  verificationStatus: 'none',
  coarseAreaId: 'area.v1:1:2',
  coarseAreaLabel: 'Encounter area',
  areaLatitude: 33.7,
  areaLongitude: 73.1,
  timeBucket: 'recently',
  encounterDate: '2026-10-17',
  encounterCount: 1,
  eligibilityExpiresAt: '2026-11-16',
);
EncounterPage page(List<String> ids, {String? cursor, bool nearby = true}) =>
    EncounterPage(
      items: ids.map(encounter).toList(),
      nextCursor: cursor,
      nearbyAvailable: nearby,
      centerLatitude: 33.7,
      centerLongitude: 73.1,
    );

class PendingEncounterRequest {
  PendingEncounterRequest(this.mode, this.radius, this.cursor, this.cancel);
  final EncounterMode mode;
  final double radius;
  final String? cursor;
  final CancelToken? cancel;
  final result = Completer<EncounterPage>();
}

class FixtureEncounters implements EncounterRepository {
  @override
  String? discoveryAccountId = 'account-a';
  final requests = <PendingEncounterRequest>[];
  @override
  Future<EncounterPage> loadEncounters({
    EncounterMode mode = EncounterMode.recent,
    double radiusKm = 1,
    String? cursor,
    CancelToken? cancelToken,
  }) {
    final request = PendingEncounterRequest(
      mode,
      radiusKm,
      cursor,
      cancelToken,
    );
    requests.add(request);
    return request.result.future;
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);
void main() {
  test(
    'an account change during refresh clears the previous account cards',
    () async {
      final repo = FixtureEncounters(), bloc = EncounterBloc(repo);
      bloc.add(const RefreshEncounters());
      await settle();
      repo.requests.last.result.complete(page(['old-account']));
      await settle();
      bloc.add(const RefreshEncounters());
      await settle();
      repo.discoveryAccountId = 'account-b';
      repo.requests.last.result.complete(page(['old-account']));
      await settle();
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.loading, false);
      await bloc.close();
    },
  );

  test(
    'switching accounts clears existing cards before the new request resolves',
    () async {
      final repo = FixtureEncounters(), bloc = EncounterBloc(repo);
      bloc.add(const RefreshEncounters());
      await settle();
      repo.requests.last.result.complete(page(['old-account']));
      await settle();
      repo.discoveryAccountId = 'account-b';
      bloc.add(const RefreshEncounters());
      await settle();
      expect(bloc.state.items, isEmpty);
      repo.requests.last.result.complete(page(['new-account']));
      await settle();
      expect(bloc.state.items.single.userId, 'new-account');
      await bloc.close();
    },
  );

  test(
    'filter changes cancel previous requests and ignore late replies',
    () async {
      final repo = FixtureEncounters(), bloc = EncounterBloc(repo);
      bloc.add(const RefreshEncounters());
      await settle();
      bloc.add(const EncounterFilterChanged(EncounterMode.nearby, radiusKm: 3));
      await settle();
      expect(repo.requests.first.cancel!.isCancelled, true);
      expect(repo.requests.last.radius, 3);
      repo.requests.last.result.complete(page(['new']));
      await settle();
      repo.requests.first.result.complete(page(['old']));
      await settle();
      expect(bloc.state.items.single.userId, 'new');
      expect(bloc.state.mode, EncounterMode.nearby);
      await bloc.close();
    },
  );
  test('pagination is single flight and deduplicates repeated peers', () async {
    final repo = FixtureEncounters(), bloc = EncounterBloc(repo);
    bloc.add(const RefreshEncounters());
    await settle();
    repo.requests.last.result.complete(page(['a'], cursor: 'next'));
    await settle();
    bloc.add(const MoreEncounters());
    bloc.add(const MoreEncounters());
    await settle();
    expect(repo.requests.length, 2);
    expect(repo.requests.last.cursor, 'next');
    repo.requests.last.result.complete(
      EncounterPage(
        items: [encounter('a'), encounter('b')],
        nextCursor: null,
        nearbyAvailable: true,
        centerLatitude: 20,
        centerLongitude: 40,
      ),
    );
    await settle();
    expect(bloc.state.items.map((e) => e.userId), ['a', 'b']);
    expect(bloc.state.nextCursor, isNull);
    expect(bloc.state.centerLatitude, 33.7);
    expect(bloc.state.centerLongitude, 73.1);
    await bloc.close();
  });
  test('offline refresh retains recent history but definitive authorization failure clears it', () async {
    final repo = FixtureEncounters(), bloc = EncounterBloc(repo);
    bloc.add(const RefreshEncounters());
    await settle();
    repo.requests.last.result.complete(page(['a']));
    await settle();
    bloc.add(const RefreshEncounters());
    await settle();
    repo.requests.last.result.completeError(const AuthFailure('offline'));
    await settle();
    expect(bloc.state.items.length, 1);
    expect(bloc.state.error!.offline, true);
    bloc.add(const RefreshEncounters());
    await settle();
    repo.requests.last.result.completeError(
      const AuthFailure('SESSION_INVALID'),
    );
    await settle();
    expect(bloc.state.items, isEmpty);
    await bloc.close();
  });
  test(
    'account change and disposal never publish stale discovery data',
    () async {
      final repo = FixtureEncounters(), bloc = EncounterBloc(repo);
      bloc.add(const RefreshEncounters());
      await settle();
      repo.discoveryAccountId = 'account-b';
      repo.requests.last.result.complete(page(['a']));
      await settle();
      expect(bloc.state.items, isEmpty);
      bloc.add(const RefreshEncounters());
      await settle();
      await bloc.close();
      expect(repo.requests.last.cancel!.isCancelled, true);
      repo.requests.last.result.complete(page(['b']));
      await settle();
    },
  );
}
