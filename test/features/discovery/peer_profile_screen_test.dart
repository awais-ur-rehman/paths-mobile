import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/profile/domain/profile_repository.dart';
import 'package:paths_mobile/features/profile/presentation/peer_profile_screen.dart';

class PendingProfiles implements ProfileSummaryRepository {
  final requests = <String, Completer<ProfileSummary>>{};
  final tokens = <String, CancelToken?>{};
  @override
  Future<ProfileSummary> loadProfileSummary(
    String userId, {
    CancelToken? cancelToken,
  }) {
    tokens[userId] = cancelToken;
    return (requests[userId] = Completer<ProfileSummary>()).future;
  }
}

ProfileSummary profile(String id) => ProfileSummary(
  userId: id,
  username: id,
  name: id,
  age: 30,
  gender: 'man',
  bio: '',
  visibility: 'private',
  verificationStatus: 'none',
);
void main() {
  testWidgets(
    'replacing a peer while loading cancels the old request and shows the new peer',
    (tester) async {
      final repository = PendingProfiles();
      Widget screen(String id) => MaterialApp(
        home: PeerProfileScreen(
          repository: repository,
          userId: id,
          onBack: () {},
        ),
      );
      await tester.pumpWidget(screen('first'));
      await tester.pump();
      await tester.pumpWidget(screen('second'));
      await tester.pump();
      expect(repository.tokens['first']!.isCancelled, true);
      repository.requests['second']!.complete(profile('second'));
      await tester.pumpAndSettle();
      repository.requests['first']!.complete(profile('first'));
      await tester.pumpAndSettle();
      expect(find.text('second, 30'), findsOneWidget);
      expect(find.text('first, 30'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
