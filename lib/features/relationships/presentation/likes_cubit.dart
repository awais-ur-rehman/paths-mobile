import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../data/relationship_repository.dart';

final class LikesState {
  const LikesState({
    this.box = 'saved',
    this.items = const [],
    this.cursor,
    this.busy = false,
    this.error,
  });
  final String box;
  final List<RelationshipCardDto> items;
  final String? cursor;
  final bool busy;
  final AuthFailure? error;
}

class LikesCubit extends Cubit<LikesState> {
  LikesCubit(this.repository) : super(const LikesState());
  final RelationshipRepository repository;
  CancelToken? _cancel;
  int _generation = 0;
  String? _account;
  Future<void> invalidate() {
    _generation++;
    _cancel?.cancel();
    emit(LikesState(box: state.box));
    return load();
  }

  Future<void> load({String? box, bool more = false}) async {
    if (more && (state.busy || state.cursor == null)) return;
    final account = repository.accountId, selected = box ?? state.box;
    final before = selected == state.box && account == _account
        ? state
        : LikesState(box: selected);
    _account = account;
    final generation = ++_generation;
    _cancel?.cancel();
    final token = _cancel = CancelToken();
    emit(
      LikesState(
        box: selected,
        items: before.items,
        cursor: before.cursor,
        busy: true,
      ),
    );
    bool current() {
      if (isClosed || generation != _generation) return false;
      if (account != repository.accountId) {
        emit(LikesState(box: selected));
        return false;
      }
      return true;
    }

    try {
      if (account == null) throw const AuthFailure('SESSION_INVALID');
      final page = await Future.any([
        repository.page(
          selected,
          cursor: more ? before.cursor : null,
          cancelToken: token,
        ),
        token.whenCancel.then<RelationshipPageDto>(
          (_) => throw const AuthFailure('cancelled'),
        ),
      ]);
      if (!current()) return;
      emit(
        LikesState(
          box: selected,
          items: List.unmodifiable(
            {
              if (more)
                for (final item in before.items) item.id: item,
              for (final item in page.items) item.id: item,
            }.values,
          ),
          cursor: page.nextCursor,
        ),
      );
    } catch (error) {
      if (!current()) return;
      final failure = error is AuthFailure
          ? error
          : const AuthFailure('invalid_response');
      emit(
        LikesState(
          box: selected,
          items: failure.offline ? before.items : const [],
          cursor: failure.offline ? before.cursor : null,
          error: failure,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _generation++;
    _cancel?.cancel();
    return super.close();
  }
}
