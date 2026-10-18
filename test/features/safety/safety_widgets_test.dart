import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/safety/domain/safety_repository.dart';
import 'package:paths_mobile/features/safety/presentation/report_sheet.dart';
import 'package:paths_mobile/features/safety/presentation/safety_scope.dart';
import 'package:paths_mobile/shared/widgets/paths_toast.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/safety/presentation/message_evidence_picker.dart';

import 'safety_test.dart' show FakeSafety;

Widget app(
  FakeSafety repository, {
  double scale = 1,
  bool picker = false,
  SafetyTarget target = const SafetyTarget(
    'peer',
    kind: 'message',
    contentId: 'message',
  ),
}) => MaterialApp(
  theme: PathsTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: PathsToastHost(
      child: SafetyScope(repository: repository, child: child!),
    ),
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => picker
            ? chooseMessageReport(context, 'peer', alreadyBlocked: true)
            : showSafetyActions(context, target),
        child: const Text('Open safety'),
      ),
    ),
  ),
);
void main() {
  testWidgets(
    'selected message reports acknowledge only the persisted reference',
    (tester) async {
      final r = FakeSafety();
      await tester.pumpWidget(app(r));
      await tester.tap(find.text('Open safety'));
      await tester.pumpAndSettle();
      expect(find.text('Report message'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'A fixture report');
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(r.sent.single.kind, 'message');
      expect(r.sent.single.contentId, 'message');
      expect(find.text('Report received'), findsOneWidget);
      expect(find.text('Reference: reference'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Report received'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await r.events.close();
    },
  );
  testWidgets('blocking preserves the report form and selected message', (
    tester,
  ) async {
    final r = FakeSafety();
    await tester.pumpWidget(app(r));
    await tester.tap(find.text('Open safety'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block member'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();
    expect(find.text('Blocked'), findsOneWidget);
    expect(find.text('Send report'), findsOneWidget);
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(r.sent.single.contentId, 'message');
    expect(find.text('Report received'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await r.events.close();
  });
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('report form fits $width at 200 percent text', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final r = FakeSafety();
      await tester.pumpWidget(app(r, scale: 2));
      await tester.tap(find.text('Open safety'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Harassment'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Under 18'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await r.events.close();
    });
  }
  testWidgets(
    'blocked member message picker retains only the selected evidence',
    (tester) async {
      final r = FakeSafety();
      r.messageResponse = () async => ReportMessagesPageDto(
        items: [
          ChatMessageDto.fromJson({
            'id': 'old-message',
            'conversationId': 'conversation',
            'senderId': 'peer',
            'clientMessageId': 'intent',
            'sequence': 1,
            'text': 'Selected fixture message',
            'createdAt': '2026-10-18T00:00:00Z',
          }),
        ],
        nextCursor: null,
      );
      await tester.pumpWidget(app(r, picker: true));
      await tester.tap(find.text('Open safety'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selected fixture message'));
      await tester.pumpAndSettle();
      expect(find.text('Blocked'), findsOneWidget);
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(r.sent.single.contentId, 'old-message');
      expect(find.text('Report received'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await r.events.close();
    },
  );
  testWidgets(
    'unavailable post evidence permits blocking then explicit member report',
    (tester) async {
      final r = FakeSafety();
      r.prepareResponse = () async => throw const AuthFailure('NOT_FOUND');
      await tester.pumpWidget(
        app(
          r,
          target: const SafetyTarget('peer', kind: 'post', contentId: 'post'),
        ),
      );
      await tester.tap(find.text('Open safety'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block member'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();
      expect(find.text('Blocked'), findsOneWidget);
      await tester.tap(find.text('Report member instead'));
      await tester.pumpAndSettle();
      expect(find.text('Report member'), findsOneWidget);
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(r.sent.single.kind, 'profile');
      expect(r.sent.single.contentId, isNull);
      await tester.pumpWidget(const SizedBox());
      await r.events.close();
    },
  );
}
