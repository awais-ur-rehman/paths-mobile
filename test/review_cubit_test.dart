import 'dart:async';

import 'package:dio/dio.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/reviews/presentation/review_submit_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/reviews/domain/review_repository.dart';
import 'package:paths_mobile/features/reviews/presentation/review_cubit.dart';

class FakeReviews implements ReviewRepository {
  @override
  String? accountId = 'one';
  final pages = <Completer<ReviewUpdatePageDto>>[];
  CancelToken? token;
  @override
  Future<ReviewUpdatePageDto> page({String? cursor, CancelToken? cancelToken}) {
    token = cancelToken;
    final c = Completer<ReviewUpdatePageDto>();
    pages.add(c);
    return c.future;
  }

  @override
  Future<void> submit(AppealInput input, {CancelToken? cancelToken}) async {}
}

void main() {
  test('appeal retries keep the intent key and changed explanations create a new intent', () async {
    final repo = SubmitReviews();
    final submit = ReviewSubmitCubit(
      repo,
      const ReviewDraft(kind: 'bio', content: 'fixture'),
    );
    await submit.submit('Context');
    expect(submit.state.error, isNotNull);
    await submit.submit('Context');
    expect(repo.inputs[0].clientId, repo.inputs[1].clientId);
    repo.fail = false;
    await submit.submit('Changed');
    expect(repo.inputs[2].clientId, isNot(repo.inputs[1].clientId));
    expect(submit.state.sent, isTrue);
    await submit.close();
  });
  test('a pending submission ignores duplicate taps and cannot complete under another account', () async {
    final repo = SubmitReviews()
      ..fail = false
      ..waiting = Completer<void>();
    final cubit = ReviewSubmitCubit(
      repo,
      const ReviewDraft(kind: 'caption', content: 'fixture'),
    );
    final pending = cubit.submit('Context');
    await cubit.submit('Context');
    expect(repo.inputs, hasLength(1));
    repo.accountId = 'other';
    repo.waiting!.complete();
    await pending;
    expect(cubit.state.sent, isFalse);
    await cubit.close();
  });

  test('late review responses cannot cross account boundaries', () async {
    final repo = FakeReviews();
    final current = ReviewCubit(repo);
    final load = current.load();
    repo.accountId = 'two';
    repo.pages.single.complete(
      const ReviewUpdatePageDto(
        items: [
          ReviewUpdateDto(
            id: 'private',
            resourceId: null,
            kind: 'appeal',
            status: 'pending',
            reason: null,
            createdAt: '2026-10-18',
          ),
        ],
        nextCursor: null,
      ),
    );
    await load;
    expect(current.state.items, isEmpty);
    await current.close();
  });
  test('closing review state cancels a pending request', () async {
    final repo = FakeReviews(), cubit = ReviewCubit(repo);
    final load = cubit.load();
    await cubit.close();
    await load;
    expect(repo.token!.isCancelled, isTrue);
  });
}

class SubmitReviews implements ReviewRepository {
  @override
  String? accountId = 'owner';
  final inputs = <AppealInput>[];
  bool fail = true;
  Completer<void>? waiting;
  @override
  Future<ReviewUpdatePageDto> page({
    String? cursor,
    CancelToken? cancelToken,
  }) async => const ReviewUpdatePageDto(items: [], nextCursor: null);
  @override
  Future<void> submit(AppealInput input, {CancelToken? cancelToken}) async {
    inputs.add(input);
    if (waiting != null) await waiting!.future;
    if (fail) throw const AuthFailure('offline');
  }
}
