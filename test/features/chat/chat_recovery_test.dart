import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/chat/presentation/chat_bloc.dart';
import 'package:paths_mobile/features/chat/presentation/chat_messages.dart';

import 'chat_bloc_test.dart';

void main() {
  testWidgets(
    'earlier page failure retries that cursor without replacing history',
    (tester) async {
      final repo = FakeChat();
      var olderCalls = 0;
      final cursors = <String?>[];
      repo.historyResult = (cursor, _) async {
        cursors.add(cursor);
        if (cursor == null) return page([message(5)], next: 'older');
        if (olderCalls++ == 0) throw const AuthFailure('offline');
        return page([message(4)]);
      };
      final bloc = ChatBloc(repo, 'c');
      final scroll = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: ChatMessages(accountId: 'owner', controller: scroll),
            ),
          ),
        ),
      );
      bloc.add(const ChatRefresh());
      await tester.pumpAndSettle();
      bloc.add(const ChatOlder());
      await tester.pumpAndSettle();
      expect(find.text('Message 5'), findsOneWidget);
      expect(find.text('Could not load earlier · Retry'), findsOneWidget);
      await tester.tap(find.text('Could not load earlier · Retry'));
      await tester.pumpAndSettle();
      expect(cursors, [null, 'older', 'older']);
      expect(olderCalls, 2);
      expect(bloc.state.messages.map((m) => m.sequence), [4, 5]);
      expect(find.text('Message 4'), findsOneWidget);
      expect(find.text('Message 5'), findsOneWidget);
      expect(olderCalls, 2);
      expect(find.text('Could not load earlier · Retry'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      scroll.dispose();
      await tester.runAsync(() async {
        await bloc.close();
        await repo.changes.close();
      });
    },
  );
}
