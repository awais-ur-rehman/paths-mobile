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
    : super(_initial(repository, userId));
  static ProfilePreviewState _initial(
    ProfileSummaryRepository repository,
    String userId,
  ) {
    final profile = repository is OwnProfileSnapshotRepository
        ? (repository as OwnProfileSnapshotRepository).cachedOwnProfile
        : null;
    return ProfilePreviewState(
      profile: profile?.userId == userId ? profile : null,
      loading: profile?.userId != userId,
    );
  }

  final ProfileSummaryRepository repository;
  final String userId;
  CancelToken? _request;
  int _generation = 0;
  Future<void>? _inFlight;
  Future<void> load({bool force = false}) {
    if (isClosed) return Future.value();
    if (!force && _inFlight != null) return _inFlight!;
    late final Future<void> result;
    result = _load(force: force).whenComplete(() {
      if (identical(_inFlight, result)) _inFlight = null;
    });
    return _inFlight = result;
  }

  Future<void> _load({required bool force}) async {
    if (isClosed) return;
    _request?.cancel();
    final token = _request = CancelToken();
    final generation = ++_generation;
    emit(ProfilePreviewState(profile: state.profile, loading: true));
    try {
      final profile = force && repository is OwnProfileSnapshotRepository
          ? await (repository as OwnProfileSnapshotRepository)
                .refreshOwnProfile(cancelToken: token)
          : await repository.loadProfileSummary(userId, cancelToken: token);
      if (!isClosed && generation == _generation) {
        emit(ProfilePreviewState(profile: profile));
      }
    } on AuthFailure catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          ProfilePreviewState(
            profile: error.offline ? state.profile : null,
            error: error,
          ),
        );
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
