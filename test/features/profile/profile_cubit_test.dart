import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/profile/domain/profile_repository.dart';
import 'package:paths_mobile/features/profile/presentation/profile_cubit.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';

class FixtureProfiles implements ProfileRepository {
  final draft = const ProfileDetails(
    username: 'fixture',
    name: 'Test Person',
    gender: 'prefer_not_to_say',
    bio: '',
  );
  Completer<ProfileDetails>? pending;
  bool conflict = false;
  int saves = 0;
  CancelToken? token;
  @override
  Future<ProfileDetails> loadProfile({CancelToken? cancelToken}) async => draft;
  @override
  Future<ProfileDetails> saveProfile(
    ProfileDetails profile, {
    CancelToken? cancelToken,
  }) async {
    saves++;
    token = cancelToken;
    if (conflict) throw const AuthFailure('USERNAME_TAKEN');
    return pending == null ? profile : pending!.future;
  }
}

void main() {
  test(
    'duplicate saves share one request and failures preserve loaded details',
    () async {
      final repo = FixtureProfiles(), cubit = ProfileCubit(FixtureProfiles());
      await cubit.close();
      final actual = ProfileCubit(repo);
      await actual.load();
      repo.conflict = true;
      await actual.save(repo.draft);
      expect(actual.state.error?.code, 'USERNAME_TAKEN');
      expect(actual.state.details, repo.draft);
      repo.conflict = false;
      repo.pending = Completer<ProfileDetails>();
      final saving = actual.save(repo.draft);
      await actual.save(repo.draft);
      expect(repo.saves, 2);
      repo.pending!.complete(repo.draft);
      await saving;
      expect(actual.state.saveRevision, 1);
      await actual.close();
    },
  );
  test('closing cancels the save and rejects its late success', () async {
    final repo = FixtureProfiles();
    final cubit = ProfileCubit(repo);
    await cubit.load();
    repo.pending = Completer<ProfileDetails>();
    final saving = cubit.save(repo.draft);
    await cubit.close();
    expect(repo.token?.isCancelled, true);
    repo.pending!.complete(repo.draft);
    await saving;
    expect(cubit.state.saveRevision, 0);
  });
}
