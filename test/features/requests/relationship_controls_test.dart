import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/relationships/presentation/relationship_controls.dart';
import 'package:paths_mobile/shared/widgets/paths_toast.dart';

import 'relationship_cubit_test.dart' show RelationshipFixture;

class Connected extends RelationshipFixture {
  @override
  Future<RelationshipStatusDto> get(
    String id, {
    CancelToken? cancelToken,
  }) async => RelationshipStatusDto(
    targetId: id,
    saved: false,
    status: 'connected',
    requestId: null,
    connectionId: 'connection',
    cooldownUntil: null,
    available: true,
    canRequest: false,
  );
}

void main() {
  testWidgets('connection requests require explicit confirmation', (
    tester,
  ) async {
    final repo = RelationshipFixture();
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        builder: (context, child) => PathsToastHost(child: child!),
        home: Scaffold(
          body: RelationshipControls(repository: repo, target: 'peer'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(repo.keys, isEmpty);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(repo.keys, isEmpty);
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(repo.keys.length, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('connected member uses message and custom connection options', (
    tester,
  ) async {
    final repo = Connected();
    var messages = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        home: Scaffold(
          body: RelationshipControls(
            repository: repo,
            target: 'peer',
            onChat: () => messages++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Message'));
    expect(messages, 1);
    await tester.tap(find.byTooltip('Connection options'));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.text('Disconnect'), findsOneWidget);
    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    expect(
      repo.keys,
      isEmpty,
    ); // Still requires the original explicit confirmation.
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
