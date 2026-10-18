import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/verification/domain/verification_repository.dart';
import 'package:paths_mobile/features/verification/presentation/verification_cubit.dart';

class FixtureVerification
    implements VerificationRepository, VerificationDocuments {
  @override
  bool get available => true;
  VerificationInfo info = const VerificationInfo(
    status: 'none',
    offerSeen: false,
    uploadsAvailable: true,
  );
  DocumentAsset asset = const DocumentAsset('front-fixture', processed: false);
  int submissions = 0, skips = 0;
  bool fail = false;
  CancelToken? token;
  Completer<VerificationInfo>? pending;
  Completer<DocumentAsset?>? pendingAsset;
  CancelToken? uploadToken;
  @override
  Future<VerificationInfo> loadVerification({CancelToken? cancelToken}) async =>
      info;
  @override
  Future<DocumentAsset?> pickAndUpload(
    DocumentSide side, {
    CancelToken? cancelToken,
  }) async {
    uploadToken = cancelToken;
    return pendingAsset?.future ?? asset;
  }

  @override
  Future<VerificationInfo> submitVerification({
    required String frontAssetId,
    String? backAssetId,
    required bool consent,
    CancelToken? cancelToken,
  }) async {
    submissions++;
    token = cancelToken;
    if (fail) throw const AuthFailure('offline');
    return pending?.future ??
        const VerificationInfo(
          status: 'pending',
          offerSeen: true,
          uploadsAvailable: true,
        );
  }

  @override
  Future<VerificationInfo> skipVerification({CancelToken? cancelToken}) async {
    skips++;
    if (fail) throw const AuthFailure('offline');
    return VerificationInfo(
      status: info.status,
      offerSeen: true,
      uploadsAvailable: info.uploadsAvailable,
    );
  }
}

void main() {
  test(
    'skip cancels an in-flight document upload and ignores its late result',
    () async {
      final repo = FixtureVerification()
        ..pendingAsset = Completer<DocumentAsset?>();
      final cubit = VerificationCubit(repo, repo);
      await cubit.load();
      final upload = cubit.pick(DocumentSide.front);
      await cubit.skip();
      expect(repo.uploadToken?.isCancelled, true);
      expect(cubit.state.skipRevision, 1);
      repo.pendingAsset!.complete(
        const DocumentAsset('late-document', processed: true),
      );
      await upload;
      expect(cubit.state.front, isNull);
      await cubit.close();
    },
  );

  test('consent and a processed front are required; duplicate submit is suppressed', () async {
    final repo = FixtureVerification(),
        cubit = VerificationCubit(
          FixtureVerification(),
          const UnavailableVerificationDocuments(),
        );
    await cubit.close();
    final actual = VerificationCubit(repo, repo);
    await actual.load();
    await actual.pick(DocumentSide.front);
    actual.setConsent(true);
    await actual.submit();
    expect(repo.submissions, 0);
    repo.asset = const DocumentAsset('front-fixture', processed: true);
    await actual.pick(DocumentSide.front);
    actual.setConsent(false);
    await actual.submit();
    expect(repo.submissions, 0);
    actual.setConsent(true);
    repo.pending = Completer<VerificationInfo>();
    final request = actual.submit();
    await actual.submit();
    expect(repo.submissions, 1);
    repo.pending!.complete(
      const VerificationInfo(
        status: 'pending',
        offerSeen: true,
        uploadsAvailable: true,
      ),
    );
    await request;
    expect(actual.state.info?.status, 'pending');
    expect(actual.state.submitRevision, 1);
    await actual.submit();
    expect(repo.submissions, 1);
    await actual.close();
  });
  test('skip is available during media outage; offline skip does not navigate or discard draft', () async {
    final repo = FixtureVerification()
      ..info = const VerificationInfo(
        status: 'none',
        offerSeen: false,
        uploadsAvailable: false,
      );
    final cubit = VerificationCubit(repo, repo);
    await cubit.load();
    repo.fail = true;
    await cubit.skip();
    expect(cubit.state.skipRevision, 0);
    expect(cubit.state.error?.offline, true);
    repo.fail = false;
    await cubit.skip();
    expect(cubit.state.skipRevision, 1);
    expect(cubit.state.info?.offerSeen, true);
    await cubit.close();
  });
  test('closing cancels submission and drops late success', () async {
    final repo = FixtureVerification()
      ..asset = const DocumentAsset('front', processed: true)
      ..pending = Completer<VerificationInfo>();
    final cubit = VerificationCubit(repo, repo);
    await cubit.load();
    await cubit.pick(DocumentSide.front);
    cubit.setConsent(true);
    final request = cubit.submit();
    await cubit.close();
    expect(repo.token?.isCancelled, true);
    repo.pending!.complete(
      const VerificationInfo(
        status: 'pending',
        offerSeen: true,
        uploadsAvailable: true,
      ),
    );
    await request;
    expect(cubit.state.submitRevision, 0);
  });
  test(
    'failed submit retains processed assets and consent for explicit retry',
    () async {
      final repo = FixtureVerification()
        ..asset = const DocumentAsset('front', processed: true)
        ..fail = true;
      final cubit = VerificationCubit(repo, repo);
      await cubit.load();
      await cubit.pick(DocumentSide.front);
      cubit.setConsent(true);
      await cubit.submit();
      expect(cubit.state.front?.id, 'front');
      expect(cubit.state.consent, true);
      expect(cubit.state.error?.offline, true);
      repo.fail = false;
      await cubit.submit();
      expect(cubit.state.info?.status, 'pending');
      await cubit.close();
    },
  );
}
