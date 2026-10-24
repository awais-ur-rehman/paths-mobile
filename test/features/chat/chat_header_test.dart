import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/chat/domain/chat_repository.dart';
import 'package:paths_mobile/features/chat/presentation/chat_header_cubit.dart';

import 'chat_bloc_test.dart';

class HeaderChat extends FakeChat {
  Future<ConversationDto> Function() detail = () async => conversationFixture();
  int calls = 0;
  @override
  Future<ConversationDto> conversation(String id, {CancelToken? cancelToken}) {
    calls++;
    return detail();
  }
}

void main() {
  test(
    'deep links fetch only their conversation and reset clears metadata',
    () async {
      final repo = HeaderChat();
      final pending = Completer<ConversationDto>();
      repo.detail = () => pending.future;
      final cubit = ChatHeaderCubit(repo, 'c', name: 'Chat');
      expect(repo.calls, 1);
      await cubit.load();
      expect(repo.calls, 1);
      repo.changes.add(const ChatSignal(type: 'reset'));
      pending.complete(conversationFixture());
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.name, 'Conversation unavailable');
      expect(cubit.state.peerId, isNull);
      await cubit.close();
      await repo.changes.close();
    },
  );
  test('cached title retries errors and removal hides identity', () async {
    final repo = HeaderChat();
    final cubit = ChatHeaderCubit(
      repo,
      'c',
      name: 'Cached',
      peerId: 'peer',
      avatarAssetId: 'photo',
    );
    expect(repo.calls, 0);
    repo.detail = () async => throw const AuthFailure('offline');
    await cubit.load();
    expect(cubit.state.name, 'Cached');
    expect(cubit.state.error?.offline, isTrue);
    repo.detail = () async => conversationFixture();
    await cubit.load();
    expect(cubit.state.name, 'Demo');
    expect(cubit.state.error, isNull);
    repo.changes.add(
      const ChatSignal(type: 'conversation.removed', resourceId: 'c'),
    );
    expect(cubit.state.peerId, isNull);
    expect(cubit.state.avatarAssetId, isNull);
    await cubit.load();
    expect(repo.calls, 2);
    await cubit.close();
    await repo.changes.close();
  });
}
