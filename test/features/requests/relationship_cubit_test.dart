import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/relationships/data/relationship_repository.dart';
import 'package:paths_mobile/features/relationships/presentation/relationship_cubit.dart';

RelationshipStatusDto status({bool saved = false}) => RelationshipStatusDto(
  targetId: 'peer',
  saved: saved,
  status: 'none',
  requestId: null,
  connectionId: null,
  cooldownUntil: null,
  available: true,
  canRequest: true,
);

class RelationshipFixture implements RelationshipRepository {
  @override
  String? accountId = 'a';
  Completer<RelationshipStatusDto>? pending;
  final keys = <String>[];
  bool fail = false;
  @override
  Future<RelationshipStatusDto> get(
    String id, {
    CancelToken? cancelToken,
  }) async => status();
  @override
  Future<RelationshipStatusDto> save(
    String id,
    bool value, {
    CancelToken? cancelToken,
  }) async {
    if (fail) throw const AuthFailure('offline');
    return status(saved: value);
  }

  @override
  Future<RelationshipStatusDto> act(
    String id,
    String action,
    String key, {
    String? resourceId,
    CancelToken? cancelToken,
  }) async {
    keys.add(key);
    if (fail) throw const AuthFailure('timeout');
    return pending == null ? status() : pending!.future;
  }

  @override
  Future<RelationshipPageDto> page(
    String box, {
    String? cursor,
    CancelToken? cancelToken,
  }) async => const RelationshipPageDto(items: [], nextCursor: null);
}

void main() {
  test('failed optimistic save restores confirmed state', () async {
    final r = RelationshipFixture(), c = RelationshipCubit(r, 'peer');
    await c.load();
    r.fail = true;
    await c.save();
    expect(c.state.value!.saved, false);
    expect(c.state.error!.offline, true);
    await c.close();
  });
  test(
    'a retry retains intent key and a different action gets a new key',
    () async {
      final r = RelationshipFixture(), c = RelationshipCubit(r, 'peer');
      await c.load();
      r.fail = true;
      await c.act('request');
      await c.act('request');
      expect(r.keys[0], r.keys[1]);
      expect(
        RegExp(
          r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
        ).hasMatch(r.keys[0]),
        true,
      );
      await c.act('cancel');
      expect(r.keys[2], isNot(r.keys[0]));
      await c.close();
    },
  );
  test(
    'late response after account change cannot restore private state',
    () async {
      final r = RelationshipFixture(), c = RelationshipCubit(r, 'peer');
      await c.load();
      r.pending = Completer();
      final request = c.act('request');
      r.accountId = 'b';
      r.pending!.complete(status(saved: true));
      await request;
      expect(c.state.value, isNull);
      await c.close();
    },
  );
  test('closing cancels pending operation without emitting', () async {
    final r = RelationshipFixture(), c = RelationshipCubit(r, 'peer');
    await c.load();
    r.pending = Completer();
    final request = c.act('request');
    await c.close();
    r.pending!.complete(status());
    await request;
    expect(c.isClosed, true);
  });
}
