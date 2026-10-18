import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/chat/domain/chat_repository.dart';
import 'package:paths_mobile/features/chat/presentation/chat_bloc.dart';
import 'package:paths_mobile/features/chat/presentation/chat_list_cubit.dart';

ChatMessageDto message(int n, {String? client}) => ChatMessageDto(
  id: 'm$n',
  conversationId: 'c',
  senderId: 'peer',
  clientMessageId: client ?? 'client$n',
  sequence: n,
  text: 'Message $n',
  createdAt: '2026-10-18T00:00:00.000Z',
);
ChatHistoryDto page(
  List<ChatMessageDto> items, {
  bool canSend = true,
  String? next,
  String sync = 'sync',
  int revision = 1,
}) => ChatHistoryDto(
  items: items,
  nextCursor: next,
  syncCursor: sync,
  canSend: canSend,
  revision: revision,
);
ConversationDto conversation() => const ConversationDto(
  id: 'c',
  peerId: 'peer',
  name: 'Demo',
  avatarAssetId: null,
  canSend: true,
  unreadCount: 1,
  lastSequence: 1,
  lastText: 'Message',
  updatedAt: '2026-10-18T00:00:00.000Z',
);

class FakeChat implements ChatRepository {
  @override
  String? accountId = 'owner';
  final changes = StreamController<ChatSignal>.broadcast(sync: true);
  @override
  Stream<ChatSignal> get events => changes.stream;
  Future<ChatHistoryDto> Function(String?, String?) historyResult = (
    _,
    _,
  ) async => page([]);
  Future<ChatMessageDto> Function(String, String) sendResult = (
    id,
    text,
  ) async => message(1, client: id);
  Future<List<ConversationDto>> Function() listResult = () async => [
    conversation(),
  ];
  final sent = <String>[], reads = <int>[];
  @override
  Future<ChatHistoryDto> history(
    String id, {
    String? cursor,
    String? after,
    CancelToken? cancelToken,
  }) => historyResult(cursor, after);
  @override
  Future<ChatMessageDto> send(
    String id,
    String clientId,
    String text, {
    CancelToken? cancelToken,
  }) {
    sent.add(clientId);
    return sendResult(clientId, text);
  }

  @override
  Future<void> read(String id, int sequence, {CancelToken? cancelToken}) async {
    reads.add(sequence);
  }

  @override
  Future<List<ConversationDto>> conversations({CancelToken? cancelToken}) =>
      listResult();
}

Future<void> settle() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test(
    'reconnect merges duplicate and out-of-order history by server sequence',
    () async {
      final r = FakeChat();
      var calls = 0;
      r.historyResult = (cursor, after) async {
        calls++;
        return calls == 1
            ? page([message(1)])
            : page([message(3), message(1), message(2)]);
      };
      final b = ChatBloc(r, 'c');
      b.add(const ChatRefresh());
      await settle();
      r.changes.add(const ChatSignal(resourceId: 'c'));
      r.changes.add(const ChatSignal(resourceId: 'c'));
      await settle();
      expect(b.state.messages.map((m) => m.sequence), [1, 2, 3]);
      await b.close();
      await r.changes.close();
    },
  );
  test(
    'failed send retries the identical client ID and reconciles only one ACK',
    () async {
      final r = FakeChat();
      var calls = 0;
      r.sendResult = (id, text) async {
        if (calls++ == 0) throw const AuthFailure('offline');
        return message(1, client: id);
      };
      final b = ChatBloc(r, 'c');
      b.add(const ChatRefresh());
      await settle();
      b.add(const ChatSend('hello'));
      await settle();
      expect(b.state.pending.single.failed, true);
      final id = b.state.pending.single.clientId;
      b.add(ChatSend('hello', clientId: id));
      await settle();
      expect(r.sent, [id, id]);
      expect(b.state.messages.length, 1);
      expect(b.state.pending, isEmpty);
      await b.close();
      await r.changes.close();
    },
  );
  test('unavailable sync erases cached history and disconnected history prevents sends', () async {
    final r = FakeChat();
    r.historyResult = (_, _) async => page([message(1)], canSend: false);
    final b = ChatBloc(r, 'c');
    b.add(const ChatRefresh());
    await settle();
    b.add(const ChatSend('denied'));
    await settle();
    expect(r.sent, isEmpty);
    expect(b.state.messages.length, 1);
    r.historyResult = (_, _) async => throw const AuthFailure('NOT_FOUND');
    b.add(const ChatRefresh());
    await settle();
    expect(b.state.messages, isEmpty);
    expect(b.state.available, false);
    await b.close();
    await r.changes.close();
  });
  test(
    'logout and a late send ACK cannot restore old-account messages',
    () async {
      final r = FakeChat(), pending = Completer<ChatMessageDto>();
      r.sendResult = (_, _) => pending.future;
      final b = ChatBloc(r, 'c');
      b.add(const ChatRefresh());
      await settle();
      b.add(const ChatSend('private'));
      await settle();
      r.accountId = 'other';
      r.changes.add(const ChatSignal(type: 'reset'));
      await settle();
      pending.complete(message(1));
      await settle();
      expect(b.state.messages, isEmpty);
      expect(b.state.pending, isEmpty);
      expect(b.state.available, false);
      await b.close();
      await r.changes.close();
    },
  );
  test(
    'read watermark is private, monotonic and never advances in background',
    () async {
      final r = FakeChat();
      r.historyResult = (_, _) async => page([message(1), message(2)]);
      final b = ChatBloc(r, 'c');
      b.add(const ChatRefresh());
      await settle();
      b.add(const ChatVisibility(false));
      b.add(const ChatSeen(2));
      await settle();
      expect(r.reads, isEmpty);
      b.add(const ChatVisibility(true));
      await settle();
      b.add(const ChatSeen(2));
      await settle();
      b.add(const ChatSeen(1));
      await settle();
      expect(r.reads, [2]);
      await b.close();
      await r.changes.close();
    },
  );
  test(
    'removed conversations cannot reappear from an older in-flight list',
    () async {
      final r = FakeChat(), pending = Completer<List<ConversationDto>>();
      var calls = 0;
      r.listResult = () {
        if (calls++ == 0) return pending.future;
        return Future.value([]);
      };
      final c = ChatListCubit(r);
      final load = c.load();
      r.changes.add(
        const ChatSignal(type: 'conversation.removed', resourceId: 'c'),
      );
      pending.complete([conversation()]);
      await load;
      await settle();
      expect(c.state.items, isEmpty);
      await c.close();
      await r.changes.close();
    },
  );
  test('an older page cannot re-enable a disconnected composer', () async {
    final r = FakeChat(), old = Completer<ChatHistoryDto>();
    r.historyResult = (cursor, after) async {
      if (cursor != null) return old.future;
      if (after == null) return page([message(2)], next: 'older', revision: 1);
      return page([], canSend: false, revision: 2);
    };
    final b = ChatBloc(r, 'c');
    b.add(const ChatRefresh());
    await settle();
    b.add(const ChatOlder());
    await settle();
    b.add(const ChatRefresh());
    await settle();
    expect(b.state.canSend, false);
    old.complete(page([message(1)], canSend: true, revision: 1));
    await settle();
    expect(b.state.canSend, false);
    expect(b.state.loadingOlder, false);
    await b.close();
    await r.changes.close();
  });
}
