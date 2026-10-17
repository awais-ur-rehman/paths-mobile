import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../data/relationship_repository.dart';

final class RelationshipState {
  const RelationshipState({this.value, this.busy = false, this.error});
  final RelationshipStatusDto? value;
  final bool busy;
  final AuthFailure? error;
}

class RelationshipCubit extends Cubit<RelationshipState> {
  RelationshipCubit(this.repository, this.target)
    : super(const RelationshipState());
  final RelationshipRepository repository;
  final String target;
  CancelToken? _cancel;
  int _generation = 0;
  String? _intent, _key;
  Future<void> load() =>
      _run((token) => repository.get(target, cancelToken: token));
  Future<void> save() {
    final before = state.value;
    if (before == null || state.busy) return Future.value();
    final optimistic = RelationshipStatusDto.fromJson({
      ...before.toJson(),
      'saved': !before.saved,
    });
    return _run(
      (token) => repository.save(target, !before.saved, cancelToken: token),
      optimistic: optimistic,
    );
  }

  Future<void> act(String action) {
    if (state.busy) return Future.value();
    final id = action == 'disconnect'
        ? state.value?.connectionId
        : state.value?.requestId;
    final intent = '$action:${id ?? target}';
    if (_intent != intent) {
      _intent = intent;
      _key = newIntentKey();
    }
    return _run(
      (token) => repository.act(
        target,
        action,
        _key!,
        resourceId: id,
        cancelToken: token,
      ),
      clearIntent: true,
    );
  }

  Future<void> _run(
    Future<RelationshipStatusDto> Function(CancelToken) action, {
    RelationshipStatusDto? optimistic,
    bool clearIntent = false,
  }) async {
    final account = repository.accountId,
        generation = ++_generation,
        before = state.value;
    _cancel?.cancel();
    final token = _cancel = CancelToken();
    emit(RelationshipState(value: optimistic ?? before, busy: true));
    bool current() {
      if (isClosed || generation != _generation) return false;
      if (account != repository.accountId) {
        emit(const RelationshipState());
        return false;
      }
      return true;
    }

    try {
      if (account == null) throw const AuthFailure('SESSION_INVALID');
      final value = await Future.any([
        action(token),
        token.whenCancel.then<RelationshipStatusDto>(
          (_) => throw const AuthFailure('cancelled'),
        ),
      ]);
      if (!current()) return;
      if (clearIntent) {
        _intent = null;
        _key = null;
      }
      emit(RelationshipState(value: value));
    } catch (error) {
      if (!current()) return;
      final failure = error is AuthFailure
          ? error
          : const AuthFailure('invalid_response');
      emit(RelationshipState(value: before, error: failure));
    }
  }

  @override
  Future<void> close() {
    _generation++;
    _cancel?.cancel();
    return super.close();
  }
}
