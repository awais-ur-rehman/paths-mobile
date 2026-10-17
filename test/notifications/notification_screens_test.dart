import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/notifications/data/notification_repository.dart';
import 'package:paths_mobile/features/notifications/presentation/notification_screen.dart';
import 'package:paths_mobile/features/notifications/presentation/notification_settings.dart';
import 'package:paths_mobile/shared/widgets/paths_toast.dart';

import 'push_client_test.dart' show Api;

class ScreensApi extends Api {
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) async {
    if (path.contains('preferences'))
      return data ??
          {
            'encounters': true,
            'requests': true,
            'messages': true,
            'review': true,
          };
    return {
      'items': [
        {
          'id': 'event',
          'kind': 'request_received',
          'title': 'Paths',
          'body': 'You have a connection request.',
          'createdDate': '2026-10-17',
          'read': false,
          'available': true,
        },
      ],
      'nextCursor': null,
    };
  }
}

void main() {
  for (final width in [320.0, 390.0, 768.0])
    testWidgets('inbox and preferences fit $width at 200%', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = NotificationRepository(ScreensApi());
      String? opened;
      Widget app(Widget screen) => MaterialApp(
        theme: PathsTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: PathsToastHost(child: child!),
        ),
        home: screen,
      );
      await tester.pumpWidget(
        app(
          NotificationScreen(
            repository: repo,
            onOpen: (id) async {
              opened = id;
            },
            onSettings: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('You have a connection request.'));
      await tester.pumpAndSettle();
      expect(opened, 'event');
      await tester.pumpWidget(app(NotificationSettings(repository: repo)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SwitchListTile), findsNWidgets(4));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
}
