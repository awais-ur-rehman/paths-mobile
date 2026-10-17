import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/relationships/presentation/relationship_controls.dart';
import 'package:paths_mobile/shared/widgets/paths_toast.dart';

import 'relationship_cubit_test.dart' show RelationshipFixture;

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
}
