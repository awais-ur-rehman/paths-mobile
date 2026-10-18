import 'dart:async';

import 'package:dio/dio.dart';
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
  test('late review responses cannot cross account boundaries', () async {
    final repo = FakeReviews(), cubit = ReviewCubit(FakeReviews());
    await cubit.close();
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
