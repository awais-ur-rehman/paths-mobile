import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/chat/presentation/chats_screen.dart';
import 'package:paths_mobile/features/chat/presentation/chat_screen.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/shared/widgets/paths_options_menu.dart';
import 'package:paths_mobile/shared/widgets/paths_icon.dart';

import 'package:paths_mobile/features/safety/presentation/safety_scope.dart';

import '../safety/safety_test.dart' show FakeSafety;
import 'chat_bloc_test.dart' show FakeChat, page;

ConversationDto row(int n) => ConversationDto(
  id: 'c$n',
  peerId: 'peer$n',
  name: ['Demo Fern', 'Demo Dune', 'Demo Tide', 'Demo Lake'][n],
  avatarAssetId: null,
  canSend: true,
  unreadCount: n == 0 ? 2 : 0,
  lastSequence: 2,
  lastText: [
    'See you soon!',
    'That sounds good',
    'Thanks for the update',
    'Hello from the demo',
  ][n],
  updatedAt: '2026-01-01T10:23:00Z',
);
void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [320.0, 390.0]) {
    for (final screen in ['list', 'thread']) {
      testWidgets('$screen golden $width', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        final repo = FakeChat();
        repo.listResult = () async => [for (var i = 0; i < 4; i++) row(i)];
        repo.historyResult = (_, _) async => page([
          for (var i = 1; i < 7; i++)
            ChatMessageDto(
              id: 'm$i',
              conversationId: 'c',
              senderId: i.isEven ? 'owner' : 'peer',
              clientMessageId: 'client$i',
              sequence: i,
              text: [
                'Hello! How has your day been?',
                'Good, thanks! What about you?',
                'Just finished a walk.',
                'Sounds lovely. Let’s catch up soon.',
                'Absolutely!',
                'Looking forward to it.',
              ][i - 1],
              createdAt: DateTime(
                2026,
                1,
                1,
                10,
                10 + i,
              ).toUtc().toIso8601String(),
            ),
        ]);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: PathsTheme.light,
            builder: (context, child) =>
                SafetyScope(repository: FakeSafety(), child: child!),
            home: screen == 'list'
                ? ChatsScreen(repository: repo, onOpen: (_) {})
                : ChatScreen(
                    repository: repo,
                    conversationId: 'c',
                    peerId: 'peer',
                    name: 'Demo Fern',
                  ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/chat-$screen-${width.toInt()}.png'),
        );
        expect(find.byTooltip('Refresh'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await repo.changes.close();
      });
    }
  }
  testWidgets(
    'themed options select and dismiss with readable large-text rows',
    (tester) async {
      String? selected;
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('Options'),
                  onPressed: () async {
                    selected = await showPathsOptions(context, const [
                      PathsMenuOption(
                        'message',
                        'Report a message',
                        PathsIconName.chats,
                      ),
                    ]);
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Options'));
      await tester.pumpAndSettle();
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      await tester.tap(find.text('Report a message'));
      await tester.pumpAndSettle();
      expect(selected, 'message');
      expect(tester.takeException(), isNull);
    },
  );
  for (final screen in ['list', 'thread']) {
    testWidgets('$screen fits large text and keyboard', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = FakeChat();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: screen == 'list'
              ? ChatsScreen(repository: repo, onOpen: (_) {})
              : ChatScreen(
                  repository: repo,
                  conversationId: 'c',
                  peerId: 'peer',
                  name: 'An unusually long demo display name',
                ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpWidget(const SizedBox());
      await repo.changes.close();
    });
  }
}
