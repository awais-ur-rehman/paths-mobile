import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/notifications/data/notification_repository.dart';
import 'package:paths_mobile/features/notifications/presentation/notification_cubit.dart';

import 'push_client_test.dart' show Api;

class Inbox extends NotificationRepository {
  Inbox(super.api);
  Completer<NotificationPageDto>? pending;
  bool offline = false;
  @override
  Future<NotificationPageDto> page({
    String? cursor,
    CancelToken? cancelToken,
  }) async {
    if (offline) throw const AuthFailure('offline');
    return pending == null
        ? const NotificationPageDto(
            items: [
              NotificationDto(
                id: 'notice',
                kind: 'encounter',
                title: 'Paths',
                body: 'You crossed paths with someone.',
                createdDate: '2026-10-17',
                read: false,
                available: true,
              ),
            ],
            nextCursor: null,
          )
        : pending!.future;
  }
}

void main() {
  test(
    'inbox refresh keeps offline history and does not mark unread cards read',
    () async {
      final repo = Inbox(Api()), cubit = NotificationCubit(repo);
      await cubit.load();
      expect(cubit.state.items.single.read, false);
      repo.offline = true;
      await cubit.load();
      expect(cubit.state.items.single.read, false);
      expect(cubit.state.error!.offline, true);
      await cubit.close();
    },
  );
  test('inbox cannot retain a late response from a previous account', () async {
    final api = Api(),
        repo = Inbox(api)..pending = Completer(),
        cubit = NotificationCubit(repo);
    final load = cubit.load();
    api.accountId = 'other';
    repo.pending!.complete(
      const NotificationPageDto(items: [], nextCursor: null),
    );
    await load;
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.busy, false);
    await cubit.close();
  });
}
