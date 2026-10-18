import 'package:paths_mobile/shared/widgets/paths_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/chat/presentation/chat_screen.dart';

import 'package:paths_mobile/features/chat/domain/chat_repository.dart';

import 'chat_bloc_test.dart' show FakeChat, page, message;

void main() {
  testWidgets(
    'composer sends text, retains failed bubble and retries the same intent',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final r = FakeChat();
      r.historyResult = (_, _) async => page([]);
      var calls = 0;
      r.sendResult = (id, text) async {
        if (calls++ == 0) throw const AuthFailure('offline');
        return ChatMessageDto(
          id: 'm',
          conversationId: 'c',
          senderId: 'owner',
          clientMessageId: id,
          sequence: 1,
          text: text,
          createdAt: '2026-10-18T00:00:00Z',
        );
      };
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          builder: (context, child) => PathsToastHost(child: child!),
          home: ChatScreen(
            repository: r,
            conversationId: 'c',
            name: 'Demo Fern',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Hello Fern');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(find.text('Not sent · Retry'), findsOneWidget);
      expect(find.text('Hello Fern'), findsOneWidget);
      await tester.tap(find.text('Not sent · Retry'));
      await tester.pumpAndSettle();
      expect(r.sent.length, 2);
      expect(r.sent[0], r.sent[1]);
      expect(find.text('Not sent · Retry'), findsNothing);
      expect(find.text('Hello Fern'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await r.changes.close();
    },
  );
  testWidgets('disconnected history is readable with no composer', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final r = FakeChat();
    r.historyResult = (_, _) async => page([], canSend: false);
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        builder: (context, child) => PathsToastHost(child: child!),
        home: ChatScreen(repository: r, conversationId: 'c'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Connection ended'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await r.changes.close();
  });
  testWidgets('covered conversation never advances its read watermark', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final r = FakeChat();
    var sequence = 1;
    r.historyResult = (_, _) async => page([message(sequence)]);
    final navigation = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigation,
        theme: PathsTheme.light,
        builder: (context, child) => PathsToastHost(child: child!),
        home: ChatScreen(repository: r, conversationId: 'c'),
      ),
    );
    await tester.pumpAndSettle();
    expect(r.reads, contains(1));
    navigation.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Another conversation')),
      ),
    );
    await tester.pumpAndSettle();
    r.reads.clear();
    sequence = 2;
    r.changes.add(const ChatSignal(resourceId: 'c'));
    await tester.pumpAndSettle();
    expect(r.reads, isEmpty);
    navigation.currentState!.pop();
    await tester.pumpAndSettle();
    expect(r.reads, contains(2));
    await tester.pumpWidget(const SizedBox());
    await r.changes.close();
  });
}
