import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_repository_test.dart';
import '../auth/auth_screens_test.dart' show signInForSetup, tap;

void main() {
  testWidgets('profile controls stay at the top of the cover', (tester) async {
    final adapter = ApiAdapter()
      ..adultChecked = true
      ..profile = {
        'username': 'fixture_user',
        'name': 'Fixture User',
        'gender': 'man',
        'bio': '',
        'visibility': 'private',
      };
    await signInForSetup(tester, adapter);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/profile');
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byTooltip('Profile options')).dy,
      lessThan(80),
    );
    expect(find.text('Follow'), findsNothing);
    expect(find.text('Followers'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('a failed summary still allows signout through profile options', (
    tester,
  ) async {
    await signInForSetup(tester, ApiAdapter()..adultChecked = true);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/profile');
    await tester.pumpAndSettle();
    expect(find.text('Profile unavailable'), findsOneWidget);
    await tester.tap(find.byTooltip('Profile options'));
    await tester.pumpAndSettle();
    await tap(tester, 'Sign out');
    expect(find.text('Good to see you'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('creation has one Next action and concise visibility', (
    tester,
  ) async {
    final adapter = ApiAdapter()
      ..adultChecked = true
      ..profile = {
        'username': 'fixture_user',
        'name': 'Fixture User',
        'gender': 'man',
        'bio': 'Fixture biography',
        'visibility': 'private',
      };
    await signInForSetup(tester, adapter);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Save details'), findsNothing);
    expect(find.text('Save and continue'), findsNothing);
    expect(find.text('Sign out'), findsNothing);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).subtitle,
      isNull,
    );
    await tap(tester, 'Next');
    expect(find.text('Verification'), findsOneWidget);
    expect(
      adapter.requests
          .where((r) => r.method == 'PUT' && r.path == '/v1/me/profile')
          .length,
      1,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('disabled CNIC placeholders are side by side with two actions', (
    tester,
  ) async {
    final adapter = ApiAdapter()..adultChecked = true;
    await signInForSetup(tester, adapter);
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .go('/setup/verification');
    await tester.pumpAndSettle();
    expect(find.text('Verification'), findsOneWidget);
    final front = find.text('CNIC front'), back = find.text('CNIC back');
    expect(tester.getCenter(front).dy, tester.getCenter(back).dy);
    expect(tester.getCenter(front).dx, lessThan(tester.getCenter(back).dx));
    expect(find.text('Choose document'), findsNothing);
    expect(find.text('Refresh status'), findsNothing);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Submit for review'),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Skip'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
