import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/domain/auth_models.dart';
import '../domain/profile_repository.dart';

final class ProfileState {
  const ProfileState({
    this.details,
    this.loading = false,
    this.saving = false,
    this.error,
    this.saveRevision = 0,
    this.continueSetup = false,
  });
  final ProfileDetails? details;
  final bool loading, saving, continueSetup;
  final AuthFailure? error;
  final int saveRevision;
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this.repository) : super(const ProfileState(loading: true));
  final ProfileRepository repository;
  CancelToken? _request;
  int _generation = 0;
  Future<void> load() async {
    if (isClosed) return;
    _request?.cancel();
    final token = _request = CancelToken();
    final generation = ++_generation;
    emit(const ProfileState(loading: true));
    try {
      final details = await repository.loadProfile(cancelToken: token);
      if (!isClosed && generation == _generation) {
        emit(ProfileState(details: details));
      }
    } on AuthFailure catch (error) {
      if (!isClosed && generation == _generation) {
        emit(ProfileState(error: error));
      }
    } catch (_) {
      if (!isClosed && generation == _generation) {
        emit(const ProfileState(error: AuthFailure('unavailable')));
      }
    }
  }

  Future<void> save(
    ProfileDetails details, {
    bool continueSetup = false,
  }) async {
    if (state.loading || state.saving || isClosed) return;
    final previous = state;
    final token = _request = CancelToken();
    final generation = ++_generation;
    emit(
      ProfileState(
        details: previous.details,
        saving: true,
        saveRevision: previous.saveRevision,
      ),
    );
    try {
      final saved = await repository.saveProfile(details, cancelToken: token);
      if (!isClosed && generation == _generation) {
        emit(
          ProfileState(
            details: saved,
            saveRevision: previous.saveRevision + 1,
            continueSetup: continueSetup,
          ),
        );
      }
    } on AuthFailure catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          ProfileState(
            details: previous.details,
            error: error,
            saveRevision: previous.saveRevision,
          ),
        );
      }
    } catch (_) {
      if (!isClosed && generation == _generation) {
        emit(
          ProfileState(
            details: previous.details,
            error: const AuthFailure('unavailable'),
            saveRevision: previous.saveRevision,
          ),
        );
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
