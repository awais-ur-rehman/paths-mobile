import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/authenticated_api.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/posts/data/post_repository.dart';
import 'package:paths_mobile/features/posts/presentation/posts_cubit.dart';

class Api implements AuthenticatedApi {
  @override
  String? accountId = 'one';
  Completer<Map<String, dynamic>>? pending;
  bool denied = false;
  final calls = <String>[];
  @override
  Future<String> installationId() async => 'test-device';
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) async {
    calls.add(path);
    if (denied) throw const AuthFailure('unavailable');
    if (pending != null) return pending!.future;
    return {
      'items': [
        const PostDto(
          id: 'post',
          assetId: 'asset',
          caption: 'Fixture',
          state: 'pending',
          createdDate: '2026-10-17',
        ).toJson(),
      ],
      'nextCursor': null,
      'locked': false,
    };
  }
}

void main() {
  test('stale pages cannot cross accounts and permission failures clear previous posts', () async {
    final api = Api(), c = PostsCubit(PostRepository(api), 'owner');
    await c.load();
    expect(c.state.items.single.state, 'pending');
    api.denied = true;
    await c.load();
    expect(c.state.items, isEmpty);
    expect(c.state.error, isNotNull);
    api.denied = false;
    api.pending = Completer();
    final work = c.load();
    api.accountId = 'two';
    api.pending!.complete({'items': [], 'nextCursor': null, 'locked': false});
    await work;
    expect(c.state.items, isEmpty);
    await c.close();
  });
  test(
    'private profiles return a locked panel without fabricated posts',
    () async {
      final api = Api()..pending = Completer(),
          c = PostsCubit(PostRepository(api), 'owner');
      final work = c.load();
      api.pending!.complete({'items': [], 'nextCursor': null, 'locked': true});
      await work;
      expect(c.state.locked, true);
      expect(c.state.items, isEmpty);
      await c.close();
    },
  );
}
