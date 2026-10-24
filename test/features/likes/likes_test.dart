import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/relationships/presentation/likes_cubit.dart';
import 'package:paths_mobile/features/relationships/presentation/likes_screen.dart';
import 'package:paths_mobile/shared/widgets/paths_toast.dart';

import '../requests/relationship_cubit_test.dart' show RelationshipFixture;

RelationshipCardDto card(String id, {bool available = true}) =>
    RelationshipCardDto(
      id: id,
      targetId: 'peer-$id',
      displayName: 'Alex',
      username: 'alex',
      age: 28,
      bio: 'A test biography',
      verificationStatus: 'none',
      photoState: 'unavailable',
      available: available,
      saved: true,
      state: 'none',
      direction: 'none',
      expiresAt: null,
    );

class Pages extends RelationshipFixture {
  final pendingPages = <String, Completer<RelationshipPageDto>>{};
  bool wait = false, offline = false;
  int loads = 0;
  @override
  Future<RelationshipPageDto> page(
    String box, {
    String? cursor,
    String search = '',
    bool verifiedOnly = false,
    bool pendingOnly = false,
    CancelToken? cancelToken,
  }) async {
    loads++;
    if (offline) throw const AuthFailure('offline');
    if (wait) return (pendingPages[box] = Completer()).future;
    return RelationshipPageDto(
      items: [card('1'), card('2', available: false)],
      nextCursor: null,
    );
  }
}

Widget app(Widget child, double scale) => MaterialApp(
  theme: PathsTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: PathsToastHost(child: child!),
  ),
  home: child,
);
void main() {
  setUpAll(() async {
    for (final entry in {
      'Inter': 'assets/fonts/Inter-Variable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });

  testWidgets('reactivating a mounted Likes tab refreshes saves', (
    tester,
  ) async {
    final repo = Pages();
    bool enabled = true;
    late StateSetter toggle;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) {
            toggle = setState;
            return TickerMode(
              enabled: enabled,
              child: LikesScreen(repository: repo, onProfile: (_) async {}),
            );
          },
        ),
        1,
      ),
    );
    await tester.pumpAndSettle();
    final before = repo.loads;
    toggle(() => enabled = false);
    await tester.pump();
    toggle(() => enabled = true);
    await tester.pumpAndSettle();
    expect(repo.loads, before + 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  test('switching tabs cancels stale pages and offline refresh retains current cards', () async {
    final repo = Pages()..wait = true, cubit = LikesCubit(repo);
    final old = cubit.load();
    final fresh = cubit.load(box: 'incoming');
    repo.pendingPages['incoming']!.complete(
      RelationshipPageDto(items: [card('fresh')], nextCursor: null),
    );
    await fresh;
    repo.pendingPages['saved']!.complete(
      RelationshipPageDto(items: [card('stale')], nextCursor: null),
    );
    await old;
    expect(cubit.state.box, 'incoming');
    expect(cubit.state.items.single.id, 'fresh');
    repo.offline = true;
    await cubit.load();
    expect(cubit.state.items.single.id, 'fresh');
    expect(cubit.state.error!.offline, true);
    await cubit.close();
  });
  test('switching accounts discards a previous page even when the transport ignores cancellation', () async {
    final repo = Pages()..wait = true, cubit = LikesCubit(repo);
    final load = cubit.load();
    repo.accountId = 'other';
    repo.pendingPages['saved']!.complete(
      RelationshipPageDto(items: [card('private')], nextCursor: null),
    );
    await load;
    expect(cubit.state.items, isEmpty);
    await cubit.close();
  });
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets(
      'Likes fits $width at 200% and refreshes after a profile closes',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = Pages();
        String? opened;
        final key = GlobalKey();
        await tester.pumpWidget(
          app(
            RepaintBoundary(
              key: key,
              child: LikesScreen(
                repository: repo,
                onProfile: (id) async {
                  opened = id;
                },
              ),
            ),
            2,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Saved'), findsOneWidget);
        expect(find.text('Profile unavailable'), findsOneWidget);
        await tester.tap(find.text('Alex'));
        await tester.pumpAndSettle();
        expect(opened, 'peer-1');
        if (width == 390 && Platform.environment['PATHS_CAPTURE'] == '1') {
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            await File('/tmp/paths-task7-likes.png')
                .writeAsBytes(png!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
}
