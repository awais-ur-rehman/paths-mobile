import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/chat_repository.dart';

final class ChatListState {
  const ChatListState({this.items = const [], this.loading = true, this.error});
  final List<ConversationDto> items;
  final bool loading;
  final AuthFailure? error;
}

class ChatListCubit extends Cubit<ChatListState> {
  ChatListCubit(this.repository)
    : _account = repository.accountId,
      super(const ChatListState()) {
    _subscription = repository.events.listen((signal) {
      if (signal.type == 'reset') {
        _epoch++;
        _cancel.cancel();
        _cancel = CancelToken();
        emit(const ChatListState(loading: false));
        return;
      }
      if (signal.type == 'conversation.removed') {
        _epoch++;
        _cancel.cancel();
        _cancel = CancelToken();
        emit(
          ChatListState(
            items: List.unmodifiable(
              state.items.where((c) => c.id != signal.resourceId),
            ),
            loading: false,
          ),
        );
      }
      if (signal.type != 'offline') unawaited(load());
    });
  }
  final ChatRepository repository;
  final String? _account;
  late final StreamSubscription<ChatSignal> _subscription;
  CancelToken _cancel = CancelToken();
  int _epoch = 0;
  bool _loading = false, _again = false;
  Future<void> load() async {
    if (_loading) {
      _again = true;
      return;
    }
    _loading = true;
    try {
      do {
        _again = false;
        final epoch = _epoch;
        try {
          final page = await repository.conversations(cancelToken: _cancel);
          if (isClosed || _account != repository.accountId) return;
          if (epoch != _epoch) {
            _again = true;
            continue;
          }
          emit(ChatListState(items: page, loading: false));
        } catch (error) {
          if (!isClosed && epoch == _epoch) {
            final e = error is AuthFailure
                ? error
                : const AuthFailure('unavailable');
            emit(ChatListState(items: state.items, loading: false, error: e));
          }
        }
      } while (_again && !isClosed);
    } finally {
      _loading = false;
    }
  }

  @override
  Future<void> close() async {
    _epoch++;
    _cancel.cancel();
    await _subscription.cancel();
    return super.close();
  }
}
