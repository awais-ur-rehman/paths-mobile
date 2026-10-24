import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/profile/domain/profile_repository.dart';
import 'package:paths_mobile/features/profile/presentation/profile_preview_cubit.dart';

class FixtureSummary implements ProfileSummaryRepository {
  final pending = Completer<ProfileSummary>();
  int reads = 0;
  CancelToken? token;
  @override
  Future<ProfileSummary> loadProfileSummary(
    String userId, {
    CancelToken? cancelToken,
  }) {
    reads++;
    token = cancelToken;
    return pending.future;
  }
}

void main() {
  test(
    'refresh retains the visible profile and coalesces overlapping reads',
    () async {
      final repo = FixtureSummary();
      final cubit = ProfilePreviewCubit(repo, 'fixture');
      const profile = ProfileSummary(
        userId: 'fixture',
        username: 'fixture',
        name: 'Fixture',
        age: 26,
        gender: 'man',
        bio: '',
        visibility: 'private',
        verificationStatus: 'none',
      );
      final first = cubit.load();
      final duplicate = cubit.load();
      expect(repo.reads, 1);
      repo.pending.complete(profile);
      await Future.wait([first, duplicate]);
      final refresh = cubit.load();
      expect(cubit.state.profile, same(profile));
      await refresh;
      await cubit.close();
    },
  );
  test(
    'disposal cancels preview read and excludes late account data',
    () async {
      final repo = FixtureSummary(),
          cubit = ProfilePreviewCubit(FixtureSummary(), 'unused');
      await cubit.close();
      final actual = ProfilePreviewCubit(repo, 'fixture');
      final load = actual.load();
      await actual.close();
      expect(repo.token?.isCancelled, true);
      repo.pending.complete(
        const ProfileSummary(
          userId: 'fixture',
          username: 'fixture',
          name: 'Fixture',
          age: 26,
          gender: 'man',
          bio: '',
          visibility: 'private',
          verificationStatus: 'none',
        ),
      );
      await load;
      expect(actual.state.profile, isNull);
    },
  );
}
