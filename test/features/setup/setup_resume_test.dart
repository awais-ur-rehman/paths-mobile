import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/profile/domain/profile_repository.dart';
import 'package:paths_mobile/features/verification/domain/verification_repository.dart';
import 'package:paths_mobile/features/setup/domain/setup_progress.dart';
import 'package:paths_mobile/features/setup/presentation/setup_resume_cubit.dart';

class Progress implements SetupProgressStore {
  final seen = <String>{};
  bool fail = false, failWrite = false;
  @override
  Future<bool> permissionSeen(String account) async {
    if (fail) throw const AuthFailure('storage');
    return seen.contains(account);
  }

  @override
  Future<void> markPermissionSeen(String account) async {
    if (failWrite) throw const AuthFailure('storage');
    seen.add(account);
  }
}

class Profiles implements ProfileRepository {
  bool complete = false, fail = false;
  Completer<ProfileDetails>? pending;
  @override
  Future<ProfileDetails> loadProfile({CancelToken? cancelToken}) async {
    if (fail) throw const AuthFailure('offline');
    return pending == null
        ? ProfileDetails(
            username: 'fixture',
            name: 'Fixture',
            gender: 'man',
            bio: '',
            profileComplete: complete,
          )
        : pending!.future;
  }

  @override
  Future<ProfileDetails> saveProfile(
    ProfileDetails profile, {
    CancelToken? cancelToken,
  }) async => profile;
}

class Verification implements VerificationRepository {
  bool seen = false;
  @override
  Future<VerificationInfo> loadVerification({CancelToken? cancelToken}) async =>
      VerificationInfo(status: 'none', offerSeen: seen, uploadsAvailable: true);
  @override
  Future<VerificationInfo> skipVerification({CancelToken? cancelToken}) async {
    seen = true;
    return loadVerification();
  }

  @override
  Future<VerificationInfo> submitVerification({
    required String frontAssetId,
    String? backAssetId,
    required bool consent,
    CancelToken? cancelToken,
  }) async {
    seen = true;
    return loadVerification();
  }
}

void main() {
  test(
    'server progress resumes profile, optional offer, education, then Home',
    () async {
      final profiles = Profiles(),
          verification = Verification(),
          progress = Progress(),
          c = SetupResumeCubit(
            profiles,
            verification,
            progress,
            'owner',
            () => 'owner',
          );
      await c.load();
      expect(c.state.destination, SetupDestination.profile);
      profiles.complete = true;
      await c.load();
      expect(c.state.destination, SetupDestination.verification);
      verification.seen = true;
      await c.load();
      expect(c.state.destination, SetupDestination.permissions);
      await progress.markPermissionSeen('owner');
      await c.load();
      expect(c.state.destination, SetupDestination.home);
      await c.close();
    },
  );
  test('offline setup cannot claim completion and retry uses current server progress', () async {
    final profiles = Profiles()..fail = true,
        verification = Verification()..seen = true,
        progress = Progress()..seen.add('owner'),
        c = SetupResumeCubit(
          profiles,
          verification,
          progress,
          'owner',
          () => 'owner',
        );
    await c.load();
    expect(c.state.destination, isNull);
    expect(c.state.error?.code, 'offline');
    profiles.fail = false;
    profiles.complete = true;
    await c.load();
    expect(c.state.destination, SetupDestination.home);
    await c.close();
  });
  test('permission education is scoped to the account and local storage errors remain visible', () async {
    final profiles = Profiles()..complete = true,
        verification = Verification()..seen = true,
        progress = Progress()..seen.add('other'),
        c = SetupResumeCubit(
          profiles,
          verification,
          progress,
          'owner',
          () => 'owner',
        );
    await c.load();
    expect(c.state.destination, SetupDestination.permissions);
    progress.fail = true;
    await c.load();
    expect(c.state.error?.code, 'storage');
    expect(c.state.destination, isNull);
    await c.close();
  });
  test(
    'an account change or disposal discards a delayed setup result',
    () async {
      String? account = 'owner';
      final profiles = Profiles()..pending = Completer(),
          c = SetupResumeCubit(
            profiles,
            Verification(),
            Progress(),
            'owner',
            () => account,
          );
      final work = c.load();
      account = 'other';
      await c.close();
      profiles.pending!.complete(
        const ProfileDetails(
          username: 'fixture',
          name: 'Fixture',
          gender: 'man',
          bio: '',
          profileComplete: true,
        ),
      );
      await work;
      expect(c.state.destination, isNull);
    },
  );
}
