import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/domain/auth_models.dart';
import '../domain/deletion_repository.dart';

final class DeletionState {
  const DeletionState({this.busy = false, this.record, this.error});
  final bool busy;
  final DeletionRecord? record;
  final AuthFailure? error;
}

class DeletionCubit extends Cubit<DeletionState> {
  DeletionCubit(this.repository) : super(const DeletionState());
  final DeletionRepository repository;
  CancelToken? _request;
  Future<void> _run(
    Future<DeletionRecord?> Function(CancelToken) action,
  ) async {
    if (isClosed || state.busy) return;
    final token = _request = CancelToken();
    emit(DeletionState(busy: true, record: state.record));
    try {
      final result = await action(token);
      if (!isClosed && !token.isCancelled) {
        emit(DeletionState(record: result, error: result?.error));
      }
    } catch (e) {
      if (!isClosed && !token.isCancelled) {
        emit(
          DeletionState(
            record: state.record,
            error: e is AuthFailure ? e : const AuthFailure('unavailable'),
          ),
        );
      }
    }
  }

  Future<void> submit(String password) =>
      _run((token) => repository.submit(password, cancelToken: token));
  Future<void> submitProvider(String proof) => _run((token) {
    final provider = repository;
    if (provider is! ProviderDeletionRepository) {
      throw const AuthFailure('configuration');
    }
    return (provider as ProviderDeletionRepository).submitWithProof(
      proof,
      cancelToken: token,
    );
  });
  Future<void> load() =>
      _run((token) => repository.refresh(cancelToken: token));
  @override
  Future<void> close() {
    _request?.cancel();
    return super.close();
  }
}
