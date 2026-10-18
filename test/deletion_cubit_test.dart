import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/deletion/domain/deletion_repository.dart';
import 'package:paths_mobile/features/deletion/presentation/deletion_cubit.dart';

class ReviewsFixture implements DeletionRepository {
  final result = Completer<DeletionRecord>();
  int sends = 0;
  CancelToken? cancel;
  @override
  Future<DeletionRecord> submit(String password, {CancelToken? cancelToken}) {
    sends++;
    cancel = cancelToken;
    return result.future;
  }

  @override
  Future<DeletionRecord?> saved() async => null;
  @override
  Future<DeletionRecord?> refresh({CancelToken? cancelToken}) => result.future;
  @override
  Future<void> dismiss() async {}
  @override
  void close() {}
}

void main() {
  test('offline deletion never emits acceptance and duplicate taps send one request', () async {
    final repo = ReviewsFixture(), c = DeletionCubit(repo);
    final pending = c.submit('Fixture password 123');
    await c.submit('Fixture password 123');
    expect(repo.sends, 1);
    repo.result.completeError(const AuthFailure('offline'));
    await pending;
    expect(c.state.record?.accepted, falseOrNull);
    expect(c.state.error?.offline, isTrue);
    await c.close();
  });
  test('an accepted receipt remains accepted when device cleanup still needs retry', () async {
    final repo = ReviewsFixture(), c = DeletionCubit(repo);
    final load = c.load();
    repo.result.complete(
      const DeletionRecord(
        receipt: DeletionReceiptDto(
          receipt: 'opaque',
          state: 'pending',
          acceptedAt: '2026-10-18',
          backupExpiresAt: '2026-10-25',
          completedAt: null,
        ),
        cleanupOwner: 'owner',
        error: AuthFailure('tracking_cleanup'),
      ),
    );
    await load;
    expect(c.state.record?.accepted, isTrue);
    expect(c.state.record?.cleanupOwner, 'owner');
    await c.close();
  });
}

Matcher get falseOrNull => anyOf(isFalse, isNull);
