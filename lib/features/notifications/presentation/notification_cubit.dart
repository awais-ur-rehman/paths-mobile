import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../data/notification_repository.dart';

final class NotificationState {
  const NotificationState({
    this.items = const [],
    this.cursor,
    this.busy = false,
    this.error,
  });
  final List<NotificationDto> items;
  final String? cursor;
  final bool busy;
  final AuthFailure? error;
}

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit(this.repository) : super(const NotificationState());
  final NotificationRepository repository;
  CancelToken? _cancel;
  int _generation = 0;
  String? _account;
  Future<void> load({bool more = false}) async {
    if (more && (state.busy || state.cursor == null)) return;
    final account = repository.accountId,
        before = _account == repository.accountId
            ? state
            : const NotificationState();
    _account = account;
    final generation = ++_generation;
    _cancel?.cancel();
    final token = _cancel = CancelToken();
    emit(
      NotificationState(items: before.items, cursor: before.cursor, busy: true),
    );
    bool current() {
      if (isClosed || generation != _generation) return false;
      if (account != repository.accountId) {
        emit(const NotificationState());
        return false;
      }
      return true;
    }

    try {
      if (account == null) throw const AuthFailure('SESSION_INVALID');
      final page = await Future.any([
        repository.page(
          cursor: more ? before.cursor : null,
          cancelToken: token,
        ),
        token.whenCancel.then<NotificationPageDto>(
          (_) => throw const AuthFailure('cancelled'),
        ),
      ]);
      if (!current()) return;
      emit(
        NotificationState(
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
        NotificationState(
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
