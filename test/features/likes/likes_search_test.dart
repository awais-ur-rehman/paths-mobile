import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/relationships/presentation/likes_cubit.dart';

import '../requests/relationship_cubit_test.dart' show RelationshipFixture;
import 'likes_test.dart' show card;

class SearchPages extends RelationshipFixture {
  final calls =
      <
        ({
          String box,
          String query,
          bool verified,
          bool pending,
          String? cursor,
        })
      >[];
  Future<RelationshipPageDto> Function(String, String?) result =
      (_, cursor) async => RelationshipPageDto(
        items: [card(cursor ?? 'first')],
        nextCursor: cursor == null ? 'next' : null,
      );
  @override
  Future<RelationshipPageDto> page(
    String box, {
    String? cursor,
    String search = '',
    bool verifiedOnly = false,
    bool pendingOnly = false,
    CancelToken? cancelToken,
  }) {
    calls.add((
      box: box,
      query: search,
      verified: verifiedOnly,
      pending: pendingOnly,
      cursor: cursor,
    ));
    return result(search, cursor);
  }
}

void main() {
  test('confirmed saved removal stays removed if refresh is offline', () async {
    final repo = SearchPages();
    final cubit = LikesCubit(repo);
    await cubit.load();
    repo.result = (_, _) async => throw const AuthFailure('offline');
    await cubit.removeSaved('peer-first');
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.error!.offline, isTrue);
    expect(cubit.state.removing, isNull);
    await cubit.close();
  });

  test(
    'debounce cancels old query; filter and pages bind to current selection',
    () async {
      final repo = SearchPages(), old = Completer<RelationshipPageDto>();
      repo.result = (q, _) => q.isEmpty
          ? old.future
          : Future.value(
              RelationshipPageDto(items: [card(q)], nextCursor: 'next'),
            );
      final c = LikesCubit(repo);
      final first = c.load();
      c.search('Al');
      c.search('Alex');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      old.complete(RelationshipPageDto(items: [card('old')], nextCursor: null));
      await first;
      expect(c.state.items.single.id, 'Alex');
      expect(repo.calls.map((x) => x.query), ['', 'Alex']);
      repo.result = (_, cursor) async => RelationshipPageDto(
        items: [card('Alex')],
        nextCursor: cursor == null ? 'next' : null,
      );
      await c.filter(verifiedOnly: true);
      expect(repo.calls.last.verified, isTrue);
      expect(repo.calls.last.cursor, isNull);
      await c.load(more: true);
      expect(repo.calls.last.cursor, 'next');
      expect(repo.calls.last.query, 'Alex');
      expect(c.state.items, hasLength(1));
      await c.load(box: 'incoming');
      await c.filter(pendingOnly: true);
      expect(repo.calls.last.pending, isTrue);
      await c.resetFilters();
      expect(c.state.query, '');
      expect(c.state.verifiedOnly, isFalse);
      expect(c.state.pendingOnly, isFalse);
      await c.close();
    },
  );
  test(
    'paging failure preserves records and invalidation cancels queued search',
    () async {
      final repo = SearchPages(), c = LikesCubit(repo);
      await c.load();
      repo.result = (_, _) async => throw const AuthFailure('offline');
      await c.load(more: true);
      expect(c.state.items.single.id, 'first');
      expect(c.state.cursor, 'next');
      c.search('stale');
      final count = repo.calls.length;
      await c.invalidate();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(repo.calls.length, count + 1);
      expect(c.state.items, isEmpty);
      await c.close();
    },
  );
}
