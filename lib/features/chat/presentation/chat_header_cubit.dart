import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/domain/auth_models.dart';
import '../domain/chat_repository.dart';

class ChatHeaderState {
  const ChatHeaderState({
    required this.name,
    this.peerId,
    this.avatarAssetId,
    this.error,
  });
  final String name;
  final String? peerId, avatarAssetId;
  final AuthFailure? error;
}

class ChatHeaderCubit extends Cubit<ChatHeaderState> {
  ChatHeaderCubit(
    this.repository,
    this.id, {
    required String name,
    String? peerId,
    String? avatarAssetId,
  }) : _account = repository.accountId,
       super(
         ChatHeaderState(
           name: name,
           peerId: peerId,
           avatarAssetId: avatarAssetId,
         ),
       ) {
    _subscription = repository.events.listen((event) {
      if (event.type == 'reset' ||
          event.type == 'conversation.removed' && event.resourceId == id) {
        _closedAccess = true;
        _cancel.cancel();
        emit(const ChatHeaderState(name: 'Conversation unavailable'));
      } else if (event.type == 'connection.updated' && event.resourceId == id) {
        unawaited(load());
      }
    });
    if (peerId == null) unawaited(load());
  }
  final ChatRepository repository;
  final String id;
  final String? _account;
  late final StreamSubscription<ChatSignal> _subscription;
  final _cancel = CancelToken();
  bool _busy = false, _closedAccess = false;
  Future<void> load() async {
    if (isClosed || _closedAccess || _busy) return;
    _busy = true;
    try {
      final item = await repository.conversation(id, cancelToken: _cancel);
      if (!isClosed && !_closedAccess && _account == repository.accountId) {
        emit(
          ChatHeaderState(
            name: item.name,
            peerId: item.peerId,
            avatarAssetId: item.avatarAssetId,
          ),
        );
      }
    } catch (error) {
      if (!isClosed && !_closedAccess && _account == repository.accountId) {
        final failure = error is AuthFailure
            ? error
            : const AuthFailure('unavailable');
        final unavailable = const {
          'NOT_FOUND',
          'not_found',
          'UNAUTHORIZED',
          'unauthorized',
        }.contains(failure.code);
        emit(
          ChatHeaderState(
            name: unavailable ? 'Conversation unavailable' : state.name,
            peerId: unavailable ? null : state.peerId,
            avatarAssetId: unavailable ? null : state.avatarAssetId,
            error: failure,
          ),
        );
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Future<void> close() async {
    _closedAccess = true;
    _cancel.cancel();
    await _subscription.cancel();
    return super.close();
  }
}
