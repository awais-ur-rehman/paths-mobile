import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paths_mobile/features/auth/presentation/credential_screens.dart';
import 'package:paths_mobile/main.dart';

import 'auth_repository_test.dart' show ApiAdapter, MemoryPreferences;
import 'auth_screens_test.dart' show repository;

// A configured provider is visible, but no native SDK or real account is used.
class ProviderUiAdapter extends ApiAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (options.path == '/v1/auth/providers') {
      requests.add(options);
      return ResponseBody.fromString(
        jsonEncode({
          'googleEnabled': true,
          'appleEnabled': false,
          'googleClientId': 'fixture.apps.googleusercontent.com',
          'googleIosClientId': '',
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return super.fetch(options, stream, cancel);
  }
}

Future<void> openForm(
  WidgetTester tester,
  String route,
  Size size, {
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final preferences = MemoryPreferences()
    ..values['paths.auth.onboarding'] = true;
  await tester.pumpWidget(
    PathsApp(
      repository: repository(ProviderUiAdapter(), preferences: preferences),
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(CredentialsScreen))).go(route);
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/auth/google-round.png'),
      tester.element(find.byType(Scaffold).first),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final (name, route, height) in [
    ('login-configured', '/auth/login', 844.0),
    ('signup-configured', '/auth/signup', 1080.0),
    ('forgot', '/auth/forgot-password', 844.0),
  ]) {
    testWidgets('$name reference layout', (tester) async {
      final shadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        await openForm(tester, route, Size(390, height));
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/auth-$name.png'),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        debugDisableShadows = shadows;
      }
    });
  }
}
