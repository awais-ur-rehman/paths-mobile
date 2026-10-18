import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/domain/auth_models.dart';
import '../../profile/domain/profile_repository.dart';
import '../../verification/domain/verification_repository.dart';
import '../domain/setup_progress.dart';

enum SetupDestination { profile, verification, permissions, home }

final class SetupResumeState {
  const SetupResumeState({this.loading = false, this.destination, this.error});
  final bool loading;
  final SetupDestination? destination;
  final AuthFailure? error;
}

class SetupResumeCubit extends Cubit<SetupResumeState> {
  SetupResumeCubit(
    this.profiles,
    this.verification,
    this.progress,
    this.owner,
    this.currentAccount, {
    this.requirePermissionEducation = true,
  }) : super(const SetupResumeState());
  final ProfileRepository profiles;
  final VerificationRepository verification;
  final SetupProgressStore progress;
  final String owner;
  final String? Function() currentAccount;
  final bool requirePermissionEducation;
  CancelToken? _token;
  int _generation = 0;
  Future<void> load() async {
    if (isClosed) return;
    _token?.cancel();
    final token = _token = CancelToken(), generation = ++_generation;
    bool current() =>
        !isClosed && generation == _generation && currentAccount() == owner;
    emit(const SetupResumeState(loading: true));
    try {
      final profile = await profiles.loadProfile(cancelToken: token);
      if (!current()) return;
      var destination = SetupDestination.profile;
      if (profile.profileComplete) {
        final offer = await verification.loadVerification(cancelToken: token);
        if (!current()) return;
        if (!offer.offerSeen) {
          destination = SetupDestination.verification;
        } else if (requirePermissionEducation &&
            !await progress.permissionSeen(owner)) {
          destination = SetupDestination.permissions;
        } else {
          destination = SetupDestination.home;
        }
      }
      if (current()) emit(SetupResumeState(destination: destination));
    } catch (error) {
      if (current()) {
        emit(
          SetupResumeState(
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
    ++_generation;
    _token?.cancel();
    return super.close();
  }
}
