import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/domain/auth_models.dart';
import '../domain/profile_repository.dart';

final class ProfilePreviewState {
  const ProfilePreviewState({this.profile, this.loading = false, this.error});
  final ProfileSummary? profile;
  final bool loading;
  final AuthFailure? error;
}

class ProfilePreviewCubit extends Cubit<ProfilePreviewState> {
  ProfilePreviewCubit(this.repository, this.userId)
    : super(const ProfilePreviewState(loading: true));
  final ProfileSummaryRepository repository;
  final String userId;
  CancelToken? _request;
  int _generation = 0;
  Future<void> load() async {
    if (isClosed) return;
    _request?.cancel();
    final token = _request = CancelToken();
    final generation = ++_generation;
    emit(const ProfilePreviewState(loading: true));
    try {
      final profile = await repository.loadProfileSummary(
        userId,
        cancelToken: token,
      );
      if (!isClosed && generation == _generation) {
        emit(ProfilePreviewState(profile: profile));
      }
    } on AuthFailure catch (error) {
      if (!isClosed && generation == _generation) {
        emit(ProfilePreviewState(error: error));
      }
    } catch (_) {
      if (!isClosed && generation == _generation) {
        emit(const ProfilePreviewState(error: AuthFailure('unavailable')));
      }
    }
  }

  @override
  Future<void> close() {
    _generation++;
    _request?.cancel();
    return super.close();
  }
}
