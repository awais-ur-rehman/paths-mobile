import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/chat_repository.dart';

sealed class ChatEvent {
  const ChatEvent();
}

final class ChatRefresh extends ChatEvent {
  const ChatRefresh();
}

final class ChatOlder extends ChatEvent {
  const ChatOlder();
}

final class ChatSend extends ChatEvent {
  const ChatSend(this.text, {this.clientId});
  final String text;
  final String? clientId;
}

final class ChatSeen extends ChatEvent {
  const ChatSeen(this.sequence);
  final int sequence;
}

final class ChatVisibility extends ChatEvent {
  const ChatVisibility(this.visible);
  final bool visible;
}

final class ChatReset extends ChatEvent {
  const ChatReset();
}

final class PendingMessage {
  const PendingMessage(this.clientId, this.text, {this.failed = false});
  final String clientId, text;
  final bool failed;
}

final class ChatState {
  const ChatState({
    this.messages = const [],
    this.pending = const [],
    this.loading = true,
    this.loadingOlder = false,
    this.canSend = false,
    this.available = true,
    this.error,
    this.older,
  });
  final List<ChatMessageDto> messages;
  final List<PendingMessage> pending;
  final bool loading, loadingOlder, canSend, available;
  final AuthFailure? error;
  final String? older;
  ChatState copy({
    List<ChatMessageDto>? messages,
    List<PendingMessage>? pending,
    bool? loading,
    bool? loadingOlder,
    bool? canSend,
    bool? available,
    AuthFailure? error,
    String? older,
    bool keepOlder = true,
  }) => ChatState(
    messages: messages ?? this.messages,
    pending: pending ?? this.pending,
    loading: loading ?? this.loading,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    canSend: canSend ?? this.canSend,
    available: available ?? this.available,
    error: error,
    older: keepOlder ? older ?? this.older : older,
  );
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(this.repository, this.conversationId)
    : _account = repository.accountId,
      super(const ChatState()) {
    on<ChatRefresh>(_refresh);
    on<ChatOlder>(_older);
    on<ChatSend>(_send);
    on<ChatSeen>(_seen);
    on<ChatReset>((_, emit) {
      _epoch++;
      _cancel.cancel();
      _cancel = CancelToken();
      _after = null;
      _read = 0;
      _revision = -1;
      emit(const ChatState(loading: false, available: false));
    });
    on<ChatVisibility>((event, emit) {
      _visible = event.visible;
      if (_visible) add(const ChatRefresh());
    });
    _subscription = repository.events.listen((event) {
      if (event.type == 'reset' ||
          event.type == 'conversation.removed' &&
              event.resourceId == conversationId) {
        _epoch++;
        _cancel.cancel();
        add(const ChatReset());
        return;
      }
      if (_visible &&
          event.type != 'offline' &&
          (event.resourceId == null || event.resourceId == conversationId)) {
        add(const ChatRefresh());
      }
    });
  }
  final ChatRepository repository;
  final String conversationId;
  final String? _account;
  late final StreamSubscription<ChatSignal> _subscription;
  CancelToken _cancel = CancelToken();
  String? _after;
  int _epoch = 0, _read = 0, _revision = -1;
  bool _refreshing = false, _again = false, _visible = true;
  bool valid(int epoch) =>
      !isClosed &&
      epoch == _epoch &&
      _account != null &&
      repository.accountId == _account;
  AuthFailure failure(Object e) =>
      e is AuthFailure ? e : const AuthFailure('unavailable');
  bool gone(AuthFailure e) => const {
    'NOT_FOUND',
    'FORBIDDEN',
    'ACCOUNT_RESTRICTED',
    'SESSION_INVALID',
  }.contains(e.code);
  ChatState merged(
    Iterable<ChatMessageDto> incoming, {
    bool? canSend,
    String? older,
    bool replaceOlder = false,
  }) {
    final byId = {
      for (final m in state.messages) m.id: m,
      ...{for (final m in incoming) m.id: m},
    };
    final messages = byId.values.toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final acknowledged = messages.map((m) => m.clientMessageId).toSet();
    return state.copy(
      messages: List.unmodifiable(messages),
      pending: List.unmodifiable(
        state.pending.where((p) => !acknowledged.contains(p.clientId)),
      ),
      loading: false,
      canSend: canSend,
      older: older,
      keepOlder: !replaceOlder,
    );
  }

  Future<void> _refresh(ChatRefresh event, Emitter<ChatState> emit) async {
    if (_refreshing) {
      _again = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _again = false;
        final epoch = _epoch;
        try {
          var page = await repository.history(
            conversationId,
            after: _after,
            cancelToken: _cancel,
          );
          if (!valid(epoch)) return;
          if (page.revision < _revision) {
            _again = true;
            continue;
          }
          _revision = page.revision;
          final initial = _after == null;
          emit(
            merged(
              page.items,
              canSend: page.canSend,
              older: initial ? page.nextCursor : state.older,
              replaceOlder: initial,
            ),
          );
          _after = page.syncCursor;
          if (!initial) {
            while (page.nextCursor != null) {
              page = await repository.history(
                conversationId,
                after: page.nextCursor,
                cancelToken: _cancel,
              );
              if (!valid(epoch)) return;
              if (page.revision < _revision) {
                _again = true;
                break;
              }
              _revision = page.revision;
              emit(merged(page.items, canSend: page.canSend));
              _after = page.syncCursor;
            }
          }
        } catch (error) {
          if (!valid(epoch)) return;
          final e = failure(error);
          if (gone(e)) {
            _after = null;
            emit(ChatState(loading: false, available: false, error: e));
          } else if (e.code != 'cancelled') {
            emit(state.copy(loading: false, error: e));
          }
        }
      } while (_again && !isClosed && _visible);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _older(ChatOlder event, Emitter<ChatState> emit) async {
    final cursor = state.older;
    if (cursor == null || state.loadingOlder || !state.available) return;
    final epoch = _epoch;
    emit(state.copy(loadingOlder: true));
    try {
      final page = await repository.history(
        conversationId,
        cursor: cursor,
        cancelToken: _cancel,
      );
      if (!valid(epoch)) return;
      if (page.revision < _revision) {
        emit(state.copy(loadingOlder: false));
        return;
      }
      _revision = page.revision;
      emit(
        merged(
          page.items,
          canSend: page.canSend,
          older: page.nextCursor,
          replaceOlder: true,
        ).copy(loadingOlder: false),
      );
    } catch (error) {
      if (valid(epoch)) {
        final e = failure(error);
        emit(
          gone(e)
              ? ChatState(loading: false, available: false, error: e)
              : state.copy(loadingOlder: false, error: e),
        );
      }
    }
  }

  Future<void> _send(ChatSend event, Emitter<ChatState> emit) async {
    if (!state.available ||
        !state.canSend ||
        event.text.trim().isEmpty ||
        event.text.runes.length > 4000) {
      return;
    }
    final epoch = _epoch, id = event.clientId ?? newIntentKey();
    final existing = state.pending.where((p) => p.clientId == id).firstOrNull;
    if (existing != null && !existing.failed) return;
    emit(
      state.copy(
        pending: List.unmodifiable([
          ...state.pending.where((p) => p.clientId != id),
          PendingMessage(id, event.text),
        ]),
      ),
    );
    try {
      final message = await repository.send(
        conversationId,
        id,
        event.text,
        cancelToken: _cancel,
      );
      if (!valid(epoch)) return;
      emit(merged([message]));
    } catch (error) {
      if (!valid(epoch)) return;
      final e = failure(error);
      if (gone(e)) {
        emit(ChatState(loading: false, available: false, error: e));
        return;
      }
      emit(
        state.copy(
          canSend: e.code == 'CONFLICT' ? false : state.canSend,
          pending: List.unmodifiable(
            state.pending.map(
              (p) => p.clientId == id
                  ? PendingMessage(id, event.text, failed: true)
                  : p,
            ),
          ),
          error: e,
        ),
      );
      if (e.code == 'CONFLICT') add(const ChatRefresh());
    }
  }

  Future<void> _seen(ChatSeen event, Emitter<ChatState> emit) async {
    if (!_visible || !state.available || event.sequence <= _read) return;
    final epoch = _epoch;
    try {
      await repository.read(
        conversationId,
        event.sequence,
        cancelToken: _cancel,
      );
      if (valid(epoch)) _read = event.sequence > _read ? event.sequence : _read;
    } catch (error) {
      if (valid(epoch) && failure(error).code != 'cancelled') {
        final e = failure(error);
        emit(
          gone(e)
              ? ChatState(loading: false, available: false, error: e)
              : state.copy(error: e),
        );
      }
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
