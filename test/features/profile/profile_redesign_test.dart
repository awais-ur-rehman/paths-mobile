import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_repository_test.dart';
import '../auth/auth_screens_test.dart' show signInForSetup, tap;

void main() {
  testWidgets(
    'own profile uses Settings instead of edit or connection buttons',
    (tester) async {
      final adapter = ApiAdapter()
        ..adultChecked = true
        ..profile = {
          'username': 'fixture_user',
          'name': 'Fixture User',
          'gender': 'man',
          'bio': 'A plain biography',
          'visibility': 'public',
        };
      await signInForSetup(tester, adapter);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.go('/profile');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.text('Edit profile'), findsNothing);
      expect(find.text('Message'), findsNothing);
      expect(find.text('Connect'), findsNothing);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings and activity'), findsOneWidget);
      expect(find.text('Edit profile'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'privacy');
      await tester.pumpAndSettle();
      expect(find.text('Profile privacy'), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);
      await tester.tap(find.text('Profile privacy'));
      await tester.pumpAndSettle();
      expect(find.byType(SwitchListTile), findsOneWidget);
      router.go('/settings');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Sign out');
      await tester.pumpAndSettle();
      await tap(tester, 'Sign out');
      expect(find.text('Log in'), findsOneWidget);
      router.go('/settings');
      await tester.pumpAndSettle();
      expect(find.text('Log in'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('adult check protects settings deep links', (tester) async {
    await signInForSetup(tester, ApiAdapter());
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/settings');
    await tester.pumpAndSettle();
    expect(find.text('Confirm you’re 18 or over'), findsOneWidget);
    expect(find.text('Settings and activity'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
