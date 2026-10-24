import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paths_mobile/app/discovery_shell.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/shared/widgets/paths_bottom_navigation.dart';

GoRouter router({bool likes = true, bool chats = true, bool camera = true}) =>
    GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => DiscoveryShell(
            shell: shell,
            hasLikes: likes,
            hasChats: chats,
            onCamera: camera ? () => context.push('/camera') : null,
          ),
          branches: [
            for (final name in [
              'home',
              if (likes) 'likes',
              if (chats) 'chats',
              'profile',
            ])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/$name',
                    builder: (context, state) => ColoredBox(
                      color: const Color(0xFFC4F2F3),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => context.push('/$name/detail'),
                              child: Text('$name page'),
                            ),
                            const Text('Bottom content'),
                          ],
                        ),
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'detail',
                        builder: (_, _) => Center(child: Text('$name detail')),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
        GoRoute(
          path: '/camera',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Close camera'),
            ),
          ),
        ),
      ],
    );

void main() {
  testWidgets(
    'icon-only tabs preserve branches; reselect resets; camera returns to current branch',
    (tester) async {
      final routes = router();
      addTearDown(routes.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: PathsTheme.light, routerConfig: routes),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsNothing);
      final semantics = tester.ensureSemantics();

      expect(
        tester.getSemantics(find.bySemanticsLabel('Home')),
        isSemantics(
          label: 'Home',
          isButton: true,
          isSelected: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      semantics.dispose();
      await tester.tap(find.text('home page'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Chats'));
      await tester.pumpAndSettle();
      expect(routes.routeInformationProvider.value.uri.path, '/chats');
      await tester.tap(find.byTooltip('Home'));
      await tester.pumpAndSettle();
      expect(find.text('home detail'), findsOneWidget);
      await tester.tap(find.byTooltip('Home'));
      await tester.pumpAndSettle();
      expect(find.text('home page'), findsOneWidget);
      await tester.tap(find.byTooltip('Chats'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Camera'));
      await tester.pumpAndSettle();
      expect(find.text('Close camera'), findsOneWidget);
      await tester.tap(find.text('Close camera'));
      await tester.pumpAndSettle();
      expect(find.text('chats page'), findsOneWidget);
      final home = tester.getCenter(find.byTooltip('Home'));
      final camera = tester.getCenter(find.byTooltip('Camera'));
      expect(camera.dy, lessThan(home.dy - 20));
      expect(camera.dx, closeTo(400, 1));
    },
  );

  testWidgets('page shows through notch while safe content clears the bar', (
    tester,
  ) async {
    final routes = router();
    addTearDown(routes.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: PathsTheme.light, routerConfig: routes),
    );
    await tester.pumpAndSettle();
    final camera = tester.getRect(find.byTooltip('Camera'));
    expect(
      tester.getRect(find.text('Bottom content')).bottom,
      lessThanOrEqualTo(camera.top),
    );
    await tester.runAsync(() async {
      final image = await captureImage(
        tester.element(find.byType(Scaffold).first),
      );
      try {
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final offset =
            ((camera.bottom + 3).round() * image.width +
                camera.center.dx.round()) *
            4;
        // Shadows may darken the aqua page but must not replace it with gray.
        expect(
          pixels.getUint8(offset + 1) - pixels.getUint8(offset),
          greaterThan(25),
        );
        expect(
          pixels.getUint8(offset + 2) - pixels.getUint8(offset),
          greaterThan(25),
        );
      } finally {
        image.dispose();
      }
    });
  });

  for (final likes in [true, false]) {
    for (final chats in [true, false]) {
      for (final camera in [true, false]) {
        testWidgets('320px safe area with capabilities $likes/$chats/$camera', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(320, 700);
          tester.view.devicePixelRatio = 1;
          tester.view.padding = const FakeViewPadding(bottom: 24);
          addTearDown(tester.view.reset);
          final routes = router(likes: likes, chats: chats, camera: camera);
          addTearDown(routes.dispose);
          await tester.pumpWidget(
            MaterialApp.router(
              theme: PathsTheme.light,
              routerConfig: routes,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final name in [
            'Home',
            if (likes) 'Likes',
            if (chats) 'Chats',
            'Profile',
            if (camera) 'Camera',
          ]) {
            final button = find.byTooltip(name);
            final rect = tester.getRect(button);
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.bottom, lessThanOrEqualTo(676));
            await tester.tap(button);
            await tester.pumpAndSettle();
            if (name != 'Camera') {
              expect(
                routes.routeInformationProvider.value.uri.path,
                '/${name.toLowerCase()}',
              );
            }
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  testWidgets(
    'keyboard can activate tabs and software keyboard hides the bar',
    (tester) async {
      var selected = -1;
      var cameras = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          home: Scaffold(
            bottomNavigationBar: PathsBottomNavigationBar(
              items: PathsNavItem.values,
              selectedIndex: 0,
              onSelected: (value) => selected = value,
              onCamera: () => cameras++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Traverse in visual order: Home, Likes, Camera, Chats, Profile.
      for (final index in [0, 1, null, 2, 3]) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        if (index == null) {
          expect(cameras, 1);
          expect(selected, 1);
        } else {
          expect(selected, index);
        }
      }
      expect(cameras, 1);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Camera'), findsNothing);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Camera'), findsOneWidget);
    },
  );

  testWidgets(
    'RTL mirrors side tabs without moving center action or callbacks',
    (tester) async {
      var selected = -1;
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              bottomNavigationBar: PathsBottomNavigationBar(
                items: PathsNavItem.values,
                selectedIndex: 0,
                onSelected: (value) => selected = value,
                onCamera: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(find.byTooltip('Home')).dx,
        greaterThan(tester.getCenter(find.byTooltip('Profile')).dx),
      );
      expect(tester.getCenter(find.byTooltip('Camera')).dx, closeTo(400, 1));
      await tester.tap(find.byTooltip('Profile'));
      expect(selected, 3);
    },
  );

  for (final width in [320.0, 390.0]) {
    testWidgets('sculpted bar visual at $width', (tester) async {
      tester.view.physicalSize = Size(width, 180);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final shadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: PathsTheme.light,
            home: Scaffold(
              backgroundColor: const Color(0xFFF1F5F8),
              bottomNavigationBar: PathsBottomNavigationBar(
                items: PathsNavItem.values,
                selectedIndex: 2,
                onSelected: (_) {},
                onCamera: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/bottom-navigation-${width.toInt()}.png'),
        );
      } finally {
        debugDisableShadows = shadows;
      }
    });
  }
}
