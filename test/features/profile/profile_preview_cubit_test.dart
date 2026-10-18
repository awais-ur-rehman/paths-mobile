import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/profile/domain/profile_repository.dart';
import 'package:paths_mobile/features/profile/presentation/profile_preview_cubit.dart';

class FixtureSummary implements ProfileSummaryRepository {
  final pending = Completer<ProfileSummary>();
  CancelToken? token;
  @override
  Future<ProfileSummary> loadProfileSummary(
    String userId, {
    CancelToken? cancelToken,
  }) {
    token = cancelToken;
    return pending.future;
  }
}

void main() {
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
