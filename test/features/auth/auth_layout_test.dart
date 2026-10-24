import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paths_mobile/main.dart';
import 'package:paths_mobile/features/auth/presentation/credential_screens.dart';
import 'package:paths_mobile/shared/widgets/paths_brand.dart';

import 'auth_repository_test.dart' show ApiAdapter, MemoryPreferences;
import 'auth_screens_test.dart' show repository, tap;

Finder field(String label) => find.ancestor(
  of: find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  ),
  matching: find.byType(TextFormField),
);

Future<void> signup(WidgetTester tester, ApiAdapter adapter) async {
  final preferences = MemoryPreferences()
    ..values['paths.auth.onboarding'] = true;
  await tester.pumpWidget(
    PathsApp(repository: repository(adapter, preferences: preferences)),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(CredentialsScreen)))
      .go('/auth/signup');
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
  });
  testWidgets('large text retains the complete confirmation label', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await signup(tester, ApiAdapter());
    await tester.ensureVisible(find.text('Confirm password'));
    await tester.pumpAndSettle();
    final label = tester.renderObject<RenderParagraph>(
      find.text('Confirm password'),
    );
    expect(label.didExceedMaxLines, false);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('signup mismatch preserves edits and sends no signup request', (
    tester,
  ) async {
    final adapter = ApiAdapter();
    await signup(tester, adapter);
    expect(field('Confirm password'), findsOneWidget);
    await tester.enterText(field('Name'), 'Fixture User');
    await tester.enterText(field('Email address'), 'fixture@example.invalid');
    await tester.enterText(field('Password'), 'a long fixture password');
    await tester.enterText(
      field('Confirm password'),
      'a different fixture password',
    );
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tap(tester, 'Create account');
    expect(find.text('The passwords do not match.'), findsOneWidget);
    expect(adapter.requests.where((r) => r.path == '/v1/auth/signup'), isEmpty);
    expect(
      tester.widget<TextFormField>(field('Name')).controller!.text,
      'Fixture User',
    );
    await tester.enterText(
      field('Confirm password'),
      'a long fixture password',
    );
    await tap(tester, 'Create account');
    expect(
      adapter.requests.where((r) => r.path == '/v1/auth/signup'),
      hasLength(1),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('confirmation reveal is independent and does not submit signup', (
    tester,
  ) async {
    final adapter = ApiAdapter();
    await signup(tester, adapter);
    expect(field('Confirm password'), findsOneWidget);
    await tester.enterText(field('Confirm password'), 'private fixture text');
    final reveal = find.descendant(
      of: field('Confirm password'),
      matching: find.byTooltip('Show password'),
    );
    await tester.ensureVisible(reveal);
    await tester.tap(reveal);
    await tester.pump();
    final confirmation = find.descendant(
      of: field('Confirm password'),
      matching: find.byType(EditableText),
    );
    final password = find.descendant(
      of: field('Password'),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(confirmation).obscureText, false);
    expect(tester.widget<EditableText>(password).obscureText, true);
    expect(
      tester.widget<TextFormField>(field('Confirm password')).controller!.text,
      'private fixture text',
    );
    expect(adapter.requests.where((r) => r.path == '/v1/auth/signup'), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'signup Back does not shift the centered symbol or show the wordmark',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await signup(tester, ApiAdapter());
      expect(find.byType(PathsWordmark), findsNothing);
      expect(find.byType(PathsSymbol), findsOneWidget);
      expect(tester.getCenter(find.byType(PathsSymbol)).dx, closeTo(195, .5));
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(field('Confirm password'), findsNothing);
      expect(tester.getCenter(find.byType(PathsSymbol)).dx, closeTo(195, .5));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'consent keeps a full tap target and policy visits preserve signup edits',
    (tester) async {
      await signup(tester, ApiAdapter());
      await tester.enterText(field('Name'), 'Fixture User');
      await tester.ensureVisible(find.byType(Checkbox));
      final target = tester.getSize(find.byType(Checkbox));
      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.height, greaterThanOrEqualTo(48));
      await tester.tap(find.widgetWithText(TextButton, 'Terms'));
      await tester.pumpAndSettle();
      expect(find.text('Development testing notice'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(field('Name')).controller!.text,
        'Fixture User',
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, false);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
