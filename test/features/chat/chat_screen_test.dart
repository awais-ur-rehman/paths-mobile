import 'dart:async';

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
      await tester.pump();
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
  testWidgets('returning reads a response completed under the covering route', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final r = FakeChat();
    final pending = Completer<ChatHistoryDto>();
    var calls = 0;
    r.historyResult = (_, _) {
      calls++;
      if (calls == 1) return Future.value(page([message(1)]));
      if (calls == 2) return pending.future;
      return Future.value(page([]));
    };
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
    r.reads.clear();
    r.changes.add(const ChatSignal(resourceId: 'c'));
    await tester.pump();
    navigation.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Another conversation')),
      ),
    );
    await tester.pumpAndSettle();
    pending.complete(page([message(2)]));
    await tester.pumpAndSettle();
    expect(r.reads, isEmpty);
    navigation.currentState!.pop();
    await tester.pumpAndSettle();
    expect(r.reads, contains(2));
    await tester.pumpWidget(const SizedBox());
    await r.changes.close();
  });
  testWidgets(
    'populated sync failure keeps history and offers an inline retry',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final repo = FakeChat();
      repo.historyResult = (_, _) async => page([message(1)]);
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          builder: (_, child) => PathsToastHost(child: child!),
          home: ChatScreen(
            repository: repo,
            conversationId: 'c',
            peerId: 'peer',
          ),
        ),
      );
      await tester.pumpAndSettle();
      repo.historyResult = (_, _) async => throw const AuthFailure('offline');
      repo.changes.add(
        const ChatSignal(type: 'message.created', resourceId: 'c'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Message 1'), findsOneWidget);
      expect(find.text('Could not sync · Retry'), findsOneWidget);
      repo.historyResult = (_, _) async => page([message(2)]);
      await tester.tap(find.text('Could not sync · Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Message 2'), findsOneWidget);
      expect(find.text('Could not sync · Retry'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await repo.changes.close();
    },
  );
  testWidgets('gradient empty and review actions have light foregrounds', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final repo = FakeChat();
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        builder: (_, child) => PathsToastHost(child: child!),
        home: ChatScreen(repository: repo, conversationId: 'c', peerId: 'peer'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('Say hello')).style?.color,
      Colors.white,
    );
    repo.sendResult = (_, _) async =>
        throw const AuthFailure('CONTENT_REVIEW_REQUIRED');
    await tester.enterText(find.byType(TextField), 'Review check');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    final review = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Request review'),
    );
    expect(review.style?.foregroundColor?.resolve({}), Colors.white);
    await tester.pumpWidget(const SizedBox());
    await repo.changes.close();
  });
}
