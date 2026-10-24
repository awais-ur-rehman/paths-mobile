import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/chat/presentation/chats_screen.dart';

import 'chat_bloc_test.dart' show FakeChat, conversation;

class SearchChat extends FakeChat {
  final queries = <String>[];
  @override
  Future<ConversationPageDto> conversations({
    String? cursor,
    int? revision,
    String search = '',
    String? peerId,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    queries.add(search);
    return ConversationPageDto(
      items: search == 'Nobody' ? [] : [conversation()],
      nextCursor: null,
      revision: 1,
    );
  }
}

void main() {
  testWidgets(
    'conversation header uses search and recent contacts without a title or reload button',
    (tester) async {
      final repository = FakeChat();
      repository.listResult = () async => [conversation()];
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          home: ChatsScreen(repository: repository, onOpen: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text("Let's Stay Connected"), findsOneWidget);
      expect(find.text('Chats'), findsNothing);
      expect(find.byTooltip('Refresh'), findsNothing);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await repository.changes.close();
    },
  );
  testWidgets('name search changes results and swipe retries the same query', (
    tester,
  ) async {
    final repo = SearchChat();
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        home: ChatsScreen(repository: repo, onOpen: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Demo'), findsNWidgets(2));
    await tester.enterText(find.byType(TextField), 'Nobody');
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pumpAndSettle();
    expect(find.text('No conversations found'), findsOneWidget);
    expect(
      find.text('Demo'),
      findsOneWidget,
    ); // Recent contacts stay unfiltered.
    expect(repo.queries.where((q) => q == 'Nobody').length, 1);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 420));
    await tester.pumpAndSettle();
    expect(repo.queries.where((q) => q == 'Nobody').length, 2);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pumpAndSettle();
    expect(find.text('No conversations found'), findsNothing);
    expect(find.text('Demo'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
    await repo.changes.close();
  });
}
