import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/safety_repository.dart';

final class BlockedState {
  const BlockedState({
    this.items = const [],
    this.loading = true,
    this.cursor,
    this.working,
    this.error,
  });
  final List<BlockedAccountDto> items;
  final bool loading;
  final String? cursor, working;
  final AuthFailure? error;
}

class BlockedCubit extends Cubit<BlockedState> {
  BlockedCubit(this.repository)
    : _account = repository.accountId,
      super(const BlockedState());
  final SafetyRepository repository;
  final String? _account;
  final _cancel = CancelToken();
  bool _loading = false;
  int _generation = 0;
  bool get valid =>
      !isClosed && _account == repository.accountId && _account != null;
  Future<void> load({bool more = false}) async {
    if (_loading || state.working != null || !valid) return;
    _loading = true;
    final generation = ++_generation;
    try {
      final page = await repository.blocked(
        cursor: more ? state.cursor : null,
        cancelToken: _cancel,
      );
      if (valid && generation == _generation) {
        emit(
          BlockedState(
            items: List.unmodifiable([if (more) ...state.items, ...page.items]),
            cursor: page.nextCursor,
            loading: false,
          ),
        );
      }
    } catch (e) {
      if (valid && generation == _generation) {
        emit(
          BlockedState(
            items: state.items,
            cursor: state.cursor,
            loading: false,
            error: e is AuthFailure ? e : const AuthFailure('unavailable'),
          ),
        );
      }
    } finally {
      _loading = false;
    }
  }

  Future<void> unblock(String id) async {
    if (state.working != null || !valid) return;
    ++_generation;
    emit(
      BlockedState(
        items: state.items,
        cursor: state.cursor,
        loading: false,
        working: id,
      ),
    );
    try {
      await repository.unblock(id, cancelToken: _cancel);
      if (valid) {
        emit(
          BlockedState(
            items: List.unmodifiable(state.items.where((x) => x.userId != id)),
            cursor: state.cursor,
            loading: false,
          ),
        );
      }
    } catch (e) {
      if (valid) {
        emit(
          BlockedState(
            items: state.items,
            cursor: state.cursor,
            loading: false,
            error: e is AuthFailure ? e : const AuthFailure('unavailable'),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _cancel.cancel();
    return super.close();
  }
}
