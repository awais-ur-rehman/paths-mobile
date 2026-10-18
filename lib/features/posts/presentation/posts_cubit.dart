import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../data/post_repository.dart';

class PostsState {
  const PostsState({
    this.items = const [],
    this.cursor,
    this.locked = false,
    this.loading = false,
    this.error,
  });
  final List<PostDto> items;
  final String? cursor;
  final bool locked, loading;
  final AuthFailure? error;
}

class PostsCubit extends Cubit<PostsState> {
  PostsCubit(this.repository, this.owner) : super(const PostsState());
  final PostRepository repository;
  final String owner;
  CancelToken? token;
  int generation = 0;
  Future<void> load({bool more = false}) async {
    if (isClosed || (more && (state.loading || state.cursor == null))) return;
    token?.cancel();
    final request = token = CancelToken(),
        revision = ++generation,
        account = repository.accountId,
        previous = state;
    emit(
      PostsState(
        items: more ? previous.items : const [],
        cursor: more ? previous.cursor : null,
        loading: true,
      ),
    );
    try {
      final page = await repository.list(
        owner,
        cursor: more ? previous.cursor : null,
        cancelToken: request,
      );
      if (isClosed ||
          revision != generation ||
          account != repository.accountId) {
        return;
      }
      emit(
        PostsState(
          items: List.unmodifiable(
            {
              ...{
                if (more)
                  for (final item in previous.items) item.id: item,
              },
              for (final item in page.items) item.id: item,
            }.values,
          ),
          cursor: page.nextCursor,
          locked: page.locked,
        ),
      );
    } catch (error) {
      if (!isClosed &&
          revision == generation &&
          account == repository.accountId) {
        emit(
          PostsState(
            items: more && error is AuthFailure && error.offline
                ? previous.items
                : const [],
            cursor: more && error is AuthFailure && error.offline
                ? previous.cursor
                : null,
            error: error is AuthFailure
                ? error
                : const AuthFailure('unavailable'),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    ++generation;
    token?.cancel();
    return super.close();
  }
}
