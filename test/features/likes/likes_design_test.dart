import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/relationships/presentation/likes_screen.dart';

import 'likes_search_test.dart' show SearchPages;
import 'likes_test.dart' show card;

import 'package:paths_mobile/features/auth/domain/auth_models.dart';

void main() {
  testWidgets('Retry repeats a failed refresh rather than fetching page two', (
    tester,
  ) async {
    final repo = SearchPages();
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        home: LikesScreen(repository: repo, onProfile: (_) async {}),
      ),
    );
    await tester.pumpAndSettle();
    repo.result = (_, _) async => throw const AuthFailure('offline');
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('You’re offline · Retry'), findsOneWidget);
    expect(repo.calls.last.cursor, isNull);
    repo.result = (_, cursor) async =>
        RelationshipPageDto(items: [card('new')], nextCursor: null);
    await tester.ensureVisible(find.text('You’re offline · Retry'));
    await tester.tap(find.text('You’re offline · Retry'));
    await tester.pumpAndSettle();
    expect(repo.calls.last.cursor, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'four sections, whole-list search and explicit resettable filters',
    (tester) async {
      final repo = SearchPages()
        ..result = (q, _) async => RelationshipPageDto(
          items: q == 'Nobody' ? [] : [card('1')],
          nextCursor: null,
        );
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          home: LikesScreen(repository: repo, onProfile: (_) async {}),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in ['Saved', 'Requests', 'Sent', 'Connected']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      await tester.tap(find.text('Verified'));
      await tester.pumpAndSettle();
      expect(repo.calls.last.verified, isTrue);
      await tester.enterText(find.byType(TextField), 'Nobody');
      await tester.pump(const Duration(milliseconds: 301));
      await tester.pumpAndSettle();
      expect(find.text('No matches'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(repo.calls.last.query, '');
      expect(repo.calls.last.verified, isFalse);
      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pending only'));
      await tester.pumpAndSettle();
      expect(repo.calls.last.pending, isTrue);
      expect(repo.calls.last.box, 'incoming');
      await tester.tap(find.text('Connected'));
      await tester.pumpAndSettle();
      expect(repo.calls.last.box, 'connections');
      expect(repo.calls.last.pending, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
