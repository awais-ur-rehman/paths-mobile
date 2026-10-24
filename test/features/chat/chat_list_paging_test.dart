import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/chat/presentation/chat_list_cubit.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/chat/domain/chat_repository.dart';

import 'chat_bloc_test.dart' show FakeChat, conversation, settle;

class PagedChat extends FakeChat {
  final calls = <({String search, String? cursor, int? revision, int limit})>[];
  Future<ConversationPageDto> Function(String, String?, int?) result =
      (_, _, _) async => ConversationPageDto(
        items: [conversation()],
        nextCursor: null,
        revision: 1,
      );
  @override
  Future<ConversationPageDto> conversations({
    String? cursor,
    int? revision,
    String search = '',
    String? peerId,
    int limit = 20,
    CancelToken? cancelToken,
  }) {
    calls.add((
      search: search,
      cursor: cursor,
      revision: revision,
      limit: limit,
    ));
    return result(search, cursor, revision);
  }
}

void main() {
  test('first page stays bounded; more carries revision, deduplicates, and stops at end', () async {
    final repo = PagedChat();
    repo.result = (_, cursor, _) async => ConversationPageDto(
      items: [conversation()],
      nextCursor: cursor == null ? 'next' : null,
      revision: 7,
    );
    final cubit = ChatListCubit(repo);
    await cubit.load();
    expect(repo.calls.length, 1);
    expect(repo.calls.single.limit, 20);
    await cubit.more();
    expect(repo.calls.last.revision, 7);
    expect(cubit.state.items.length, 1);
    expect(cubit.state.cursor, null);
    await cubit.more();
    expect(repo.calls.length, 2);
    await cubit.close();
    await repo.changes.close();
  });
  test('debounced search discards old response and gets bounded unfiltered recents', () async {
    final repo = PagedChat(), old = Completer<ConversationPageDto>();
    repo.result = (query, _, _) => query.isEmpty
        ? old.future
        : Future.value(
            const ConversationPageDto(items: [], nextCursor: null, revision: 2),
          );
    final cubit = ChatListCubit(repo);
    final initial = cubit.load();
    cubit.search('A');
    cubit.search('Alice');
    old.complete(
      ConversationPageDto(
        items: [conversation()],
        nextCursor: null,
        revision: 1,
      ),
    );
    await initial;
    await Future<void>.delayed(const Duration(milliseconds: 340));
    await settle();
    expect(cubit.state.query, 'Alice');
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.recent.length, 1);
    expect(repo.calls.where((call) => call.search == 'A'), isEmpty);
    expect(repo.calls.last.limit, 4);
    await cubit.close();
    await repo.changes.close();
  });
  test('page conflict restarts snapshot; offline page failure keeps loaded data for explicit retry', () async {
    final repo = PagedChat();
    var conflict = true;
    repo.result = (_, cursor, _) async {
      if (cursor != null) throw AuthFailure(conflict ? 'CONFLICT' : 'offline');
      return ConversationPageDto(
        items: [conversation()],
        nextCursor: 'next',
        revision: 3,
      );
    };
    final cubit = ChatListCubit(repo);
    await cubit.load();
    await cubit.more();
    expect(repo.calls.where((c) => c.cursor == null).length, 2);
    conflict = false;
    await cubit.more();
    expect(cubit.state.items.length, 1);
    expect(cubit.state.moreError!.offline, true);
    final count = repo.calls.length;
    await cubit.more();
    expect(repo.calls.length, count);
    await cubit.more(retry: true);
    expect(repo.calls.length, count + 1);
    await cubit.close();
    await repo.changes.close();
  });
  test('reset cancels debounced work and stale responses cannot expose prior account', () async {
    final repo = PagedChat(), pending = Completer<ConversationPageDto>();
    repo.result = (_, _, _) => pending.future;
    final cubit = ChatListCubit(repo);
    final load = cubit.load();
    cubit.search('Alice');
    repo.changes.add(const ChatSignal(type: 'reset'));
    pending.complete(
      ConversationPageDto(
        items: [conversation()],
        nextCursor: null,
        revision: 1,
      ),
    );
    await load;
    await Future<void>.delayed(const Duration(milliseconds: 340));
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.recent, isEmpty);
    expect(repo.calls.length, 1);
    await cubit.close();
    await repo.changes.close();
  });
}
