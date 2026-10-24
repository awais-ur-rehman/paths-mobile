import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../data/relationship_repository.dart';

typedef LikesCriteria = ({
  String box,
  String query,
  bool verifiedOnly,
  bool pendingOnly,
});
const initialLikesCriteria = (
  box: 'saved',
  query: '',
  verifiedOnly: false,
  pendingOnly: false,
);

final class LikesState {
  const LikesState({
    this.criteria = initialLikesCriteria,
    this.items = const [],
    this.cursor,
    this.busy = false,
    this.retryMore = false,
    this.error,
    this.removing,
  });
  final LikesCriteria criteria;
  final List<RelationshipCardDto> items;
  final String? cursor, removing;
  final bool busy, retryMore;
  final AuthFailure? error;
  String get box => criteria.box;
  String get query => criteria.query;
  bool get verifiedOnly => criteria.verifiedOnly;
  bool get pendingOnly => criteria.pendingOnly;
  bool get requestBox => box == 'incoming' || box == 'sent';
  bool get filtered =>
      query.isNotEmpty || verifiedOnly || (requestBox && pendingOnly);
}

class LikesCubit extends Cubit<LikesState> {
  LikesCubit(this.repository) : super(const LikesState());
  final RelationshipRepository repository;
  CancelToken? _cancel, _remove;
  Timer? _debounce;
  int _generation = 0;
  String? _account;
  LikesCriteria _criteria({
    String? box,
    String? query,
    bool? verifiedOnly,
    bool? pendingOnly,
  }) => (
    box: box ?? state.box,
    query: query ?? state.query,
    verifiedOnly: verifiedOnly ?? state.verifiedOnly,
    pendingOnly: pendingOnly ?? state.pendingOnly,
  );
  void _cancelWork() {
    _generation++;
    _cancel?.cancel();
    _debounce?.cancel();
  }

  void search(String value) {
    final criteria = _criteria(query: value.trim());
    if (isClosed || criteria == state.criteria) return;
    _cancelWork();
    emit(LikesState(criteria: criteria, busy: true, removing: state.removing));
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(load()),
    );
  }

  Future<void> filter({bool? verifiedOnly, bool? pendingOnly}) async {
    if (isClosed) return;
    final criteria = _criteria(
      verifiedOnly: verifiedOnly,
      pendingOnly: pendingOnly,
    );
    _cancelWork();
    emit(LikesState(criteria: criteria, removing: state.removing));
    await load();
  }

  Future<void> resetFilters() async {
    if (isClosed) return;
    _cancelWork();
    emit(
      LikesState(
        criteria: (
          box: state.box,
          query: '',
          verifiedOnly: false,
          pendingOnly: false,
        ),
        removing: state.removing,
      ),
    );
    await load();
  }

  Future<void> invalidate() {
    if (isClosed) return Future.value();
    _cancelWork();
    _remove?.cancel();
    emit(LikesState(criteria: state.criteria));
    return load();
  }

  Future<void> load({String? box, bool more = false}) async {
    if (isClosed || (more && (state.busy || state.cursor == null))) return;
    final account = repository.accountId, criteria = _criteria(box: box);
    final before = criteria == state.criteria && account == _account
        ? state
        : LikesState(criteria: criteria);
    _account = account;
    _cancelWork();
    final generation = _generation, token = _cancel = CancelToken();
    emit(
      LikesState(
        criteria: criteria,
        items: before.items,
        cursor: before.cursor,
        busy: true,
        removing: state.removing,
      ),
    );
    bool current() {
      if (isClosed || generation != _generation) return false;
      if (account != repository.accountId) {
        emit(LikesState(criteria: criteria));
        return false;
      }
      return true;
    }

    try {
      if (account == null) throw const AuthFailure('SESSION_INVALID');
      final page = await Future.any([
        repository.page(
          criteria.box,
          cursor: more ? before.cursor : null,
          search: criteria.query,
          verifiedOnly: criteria.verifiedOnly,
          pendingOnly:
              (criteria.box == 'incoming' || criteria.box == 'sent') &&
              criteria.pendingOnly,
          cancelToken: token,
        ),
        token.whenCancel.then<RelationshipPageDto>(
          (_) => throw const AuthFailure('cancelled'),
        ),
      ]);
      if (!current()) return;
      emit(
        LikesState(
          criteria: criteria,
          items: List.unmodifiable(
            {
              if (more)
                for (final item in before.items) item.id: item,
              for (final item in page.items) item.id: item,
            }.values,
          ),
          cursor: page.nextCursor,
          removing: state.removing,
        ),
      );
    } catch (error) {
      if (!current()) return;
      final failure = error is AuthFailure
          ? error
          : const AuthFailure('invalid_response');
      emit(
        LikesState(
          criteria: criteria,
          items: failure.offline ? before.items : const [],
          cursor: failure.offline ? before.cursor : null,
          error: failure,
          retryMore: more && failure.offline && before.cursor != null,
          removing: state.removing,
        ),
      );
    }
  }

  Future<void> retry() => load(more: state.retryMore);

  void _removing(String? id) => emit(
    LikesState(
      criteria: state.criteria,
      items: state.items,
      cursor: state.cursor,
      busy: state.busy,
      error: state.error,
      retryMore: state.retryMore,
      removing: id,
    ),
  );
  Future<void> removeSaved(String id) async {
    if (isClosed || state.removing != null) return;
    final account = repository.accountId, token = _remove = CancelToken();
    _removing(id);
    try {
      await repository.save(id, false, cancelToken: token);
      if (!isClosed && account == repository.accountId) {
        if (state.box == 'saved') {
          emit(
            LikesState(
              criteria: state.criteria,
              items: List.unmodifiable(
                state.items.where((item) => item.targetId != id),
              ),
              cursor: state.cursor,
              removing: id,
            ),
          );
        }
        await load();
      }
    } catch (error) {
      if (!isClosed && account == repository.accountId) rethrow;
    } finally {
      if (!isClosed && account == repository.accountId) _removing(null);
      if (identical(_remove, token)) _remove = null;
    }
  }

  @override
  Future<void> close() {
    _cancelWork();
    _remove?.cancel();
    return super.close();
  }
}
