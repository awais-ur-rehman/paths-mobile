import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/chat_repository.dart';

final class ChatListState {
  const ChatListState({
    this.items = const [],
    this.recent = const [],
    this.query = '',
    this.loading = true,
    this.refreshing = false,
    this.loadingMore = false,
    this.cursor,
    this.revision,
    this.error,
    this.moreError,
  });
  final List<ConversationDto> items, recent;
  final String query;
  final bool loading, refreshing, loadingMore;
  final String? cursor;
  final int? revision;
  final AuthFailure? error, moreError;
  ChatListState copy({
    List<ConversationDto>? items,
    List<ConversationDto>? recent,
    bool? loading,
    bool? refreshing,
    bool? loadingMore,
    AuthFailure? error,
    AuthFailure? moreError,
  }) => ChatListState(
    items: items ?? this.items,
    recent: recent ?? this.recent,
    query: query,
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    loadingMore: loadingMore ?? this.loadingMore,
    cursor: cursor,
    revision: revision,
    error: error,
    moreError: moreError,
  );
}

class ChatListCubit extends Cubit<ChatListState> {
  ChatListCubit(this.repository)
    : _account = repository.accountId,
      super(const ChatListState()) {
    _subscription = repository.events.listen((signal) {
      if (signal.type == 'reset') {
        _reset = true;
        _invalidate();
        _debounce?.cancel();
        _refreshing = null;
        emit(const ChatListState(loading: false));
        return;
      }
      if (signal.type == 'offline') {
        emit(state.copy(error: const AuthFailure('offline')));
        return;
      }
      if (signal.type == 'conversation.removed') {
        _invalidate();
        _refreshing = null;
        emit(
          ChatListState(
            items: List.unmodifiable(
              state.items.where((c) => c.id != signal.resourceId),
            ),
            recent: List.unmodifiable(
              state.recent.where((c) => c.id != signal.resourceId),
            ),
            query: state.query,
            loading: false,
          ),
        );
      }
      unawaited(load());
    });
  }
  final ChatRepository repository;
  final String? _account;
  late final StreamSubscription<ChatSignal> _subscription;
  CancelToken _cancel = CancelToken();
  Timer? _debounce;
  Future<void>? _refreshing;
  String? _refreshQuery;
  int _epoch = 0;
  bool _reset = false, _again = false;
  bool _valid(int epoch) =>
      !isClosed &&
      !_reset &&
      epoch == _epoch &&
      _account != null &&
      _account == repository.accountId;
  void _invalidate() {
    _epoch++;
    _cancel.cancel();
    _cancel = CancelToken();
  }

  void search(String value) {
    final query = value.trim();
    if (isClosed || _reset || query == state.query) return;
    _debounce?.cancel();
    _invalidate();
    _again = false;
    _refreshing = null;
    emit(ChatListState(query: query, recent: state.recent));
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(load()),
    );
  }

  Future<void> load() {
    if (isClosed || _reset || _account != repository.accountId) {
      return Future.value();
    }
    _debounce?.cancel();
    if (_refreshing != null && _refreshQuery == state.query) {
      _again = true;
      return _refreshing!;
    }
    _again = false;
    _invalidate();
    final epoch = _epoch, query = state.query, cancel = _cancel;
    _refreshQuery = query;
    late final Future<void> operation;
    operation = _first(epoch, query, cancel).whenComplete(() {
      if (identical(_refreshing, operation)) {
        _refreshing = null;
        if (_again && !isClosed && !_reset) {
          _again = false;
          unawaited(load());
        }
      }
    });
    _refreshing = operation;
    return operation;
  }

  Future<void> _first(int epoch, String query, CancelToken cancel) async {
    emit(state.copy(refreshing: true, loadingMore: false));
    try {
      final pages = await Future.wait([
        repository.conversations(search: query, cancelToken: cancel),
        if (query.isNotEmpty)
          repository.conversations(limit: 4, cancelToken: cancel),
      ]);
      if (!_valid(epoch)) return;
      final page = pages.first;
      emit(
        ChatListState(
          items: List.unmodifiable(page.items),
          recent: List.unmodifiable(
            (query.isEmpty ? page.items : pages.last.items).take(4),
          ),
          query: query,
          loading: false,
          cursor: page.nextCursor,
          revision: page.revision,
        ),
      );
    } catch (error) {
      if (_valid(epoch)) {
        emit(
          state.copy(
            loading: false,
            refreshing: false,
            error: error is AuthFailure
                ? error
                : const AuthFailure('unavailable'),
          ),
        );
      }
    }
  }

  Future<void> more({bool retry = false}) async {
    if (isClosed ||
        _reset ||
        state.loading ||
        state.refreshing ||
        state.loadingMore ||
        state.cursor == null ||
        (!retry && state.moreError != null)) {
      return;
    }
    final epoch = _epoch, cursor = state.cursor, revision = state.revision;
    emit(state.copy(loadingMore: true));
    try {
      final page = await repository.conversations(
        search: state.query,
        cursor: cursor,
        revision: revision,
        cancelToken: _cancel,
      );
      if (!_valid(epoch)) return;
      if (page.revision != revision) {
        await load();
        return;
      }
      final items = {
        for (final item in state.items) item.id: item,
        for (final item in page.items) item.id: item,
      };
      emit(
        ChatListState(
          items: List.unmodifiable(items.values),
          recent: state.recent,
          query: state.query,
          loading: false,
          cursor: page.nextCursor,
          revision: page.revision,
        ),
      );
    } catch (error) {
      if (!_valid(epoch)) return;
      final failure = error is AuthFailure
          ? error
          : const AuthFailure('unavailable');
      if (const {'CONFLICT', 'conflict'}.contains(failure.code)) {
        await load();
      } else {
        emit(state.copy(loadingMore: false, moreError: failure));
      }
    }
  }

  @override
  Future<void> close() async {
    _reset = true;
    _invalidate();
    _debounce?.cancel();
    await _subscription.cancel();
    return super.close();
  }
}
