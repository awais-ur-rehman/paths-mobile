import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paths_mobile/main.dart';
import 'package:paths_mobile/features/auth/data/http_auth_repository.dart';
import 'package:paths_mobile/features/auth/presentation/credential_screens.dart';
import 'package:paths_mobile/features/auth/presentation/otp_screen.dart';

import 'auth_repository_test.dart'
    show MemoryVault, MemoryPreferences, ApiAdapter;

HttpAuthRepository repository(
  ApiAdapter adapter, {
  MemoryPreferences? preferences,
}) => HttpAuthRepository(
  origin: 'https://api.example.invalid',
  vault: MemoryVault(),
  preferences: preferences ?? MemoryPreferences(),
  publicTransport: Dio()..httpClientAdapter = adapter,
  authenticatedTransport: Dio()..httpClientAdapter = adapter,
);
Future<void> tap(WidgetTester tester, String text) async {
  final item = find.text(text).last;
  await tester.ensureVisible(item);
  await tester.tap(item);
  await tester.pumpAndSettle();
}

Future<void> signInForSetup(WidgetTester tester, ApiAdapter adapter) async {
  final preferences = MemoryPreferences()
    ..values['paths.auth.onboarding'] = true;
  await tester.pumpWidget(
    PathsApp(repository: repository(adapter, preferences: preferences)),
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email'),
    'fixture@example.invalid',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    'a long fixture password',
  );
  await tap(tester, 'Sign in');
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'Inter': 'assets/fonts/Inter-Variable.ttf',
      'LilitaOne': 'assets/fonts/LilitaOne-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });
  testWidgets(
    'signup, pasted OTP and guarded adult setup complete without opening discovery',
    (tester) async {
      final adapter = ApiAdapter();
      final preferences = MemoryPreferences();
      preferences.values['paths.auth.onboarding'] = false;
      await tester.pumpWidget(
        PathsApp(repository: repository(adapter, preferences: preferences)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Meet people you\ncross paths with'), findsOneWidget);
      await tap(tester, 'Get started');
      expect(find.text('Good to see you'), findsOneWidget);
      await tap(tester, 'New to Paths? Create an account');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Fixture User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'fixture@example.invalid',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'a long fixture password',
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tap(tester, 'Create account');
      expect(find.byType(OtpScreen), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Verification code'),
        '123456',
      );
      await tap(tester, 'Verify code');
      expect(find.text('Confirm you’re 18 or over'), findsOneWidget);
      expect(find.text('Contact support'), findsNothing);
      expect(find.text('Sign out'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Date of birth'),
        '1990-01-01',
      );
      await tap(tester, 'Confirm age');
      expect(find.text('Age confirmed'), findsNothing);
      expect(find.text('Contact support'), findsNothing);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
      expect(adapter.requests.any((r) => r.path.contains('locations')), false);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'reset OTP gives a reset form and mismatched confirmation makes no request',
    (tester) async {
      final adapter = ApiAdapter();
      final preferences = MemoryPreferences();
      preferences.values['paths.auth.onboarding'] = true;
      await tester.pumpWidget(
        PathsApp(repository: repository(adapter, preferences: preferences)),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'Forgot password?');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'fixture@example.invalid',
      );
      await tap(tester, 'Send reset code');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Verification code'),
        '123456',
      );
      await tap(tester, 'Verify code');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New password'),
        'a changed fixture password',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        'does not match',
      );
      await tap(tester, 'Reset password');
      expect(find.text('The passwords do not match.'), findsOneWidget);
      expect(
        adapter.requests.any((r) => r.path == '/v1/auth/password/reset'),
        false,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        'a changed fixture password',
      );
      await tap(tester, 'Reset password');
      expect(
        find.text('Your password was changed. Sign in with your new password.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'signed-out deep links cannot enter setup and policy text remains accessible',
    (tester) async {
      final preferences = MemoryPreferences();
      preferences.values['paths.auth.onboarding'] = true;
      await tester.pumpWidget(
        PathsApp(
          repository: repository(ApiAdapter(), preferences: preferences),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(
        tester.element(find.byType(CredentialsScreen)),
      );
      router.go('/setup/profile');
      await tester.pumpAndSettle();
      expect(find.text('Good to see you'), findsOneWidget);
      router.go('/policies/privacy');
      await tester.pumpAndSettle();
      expect(find.text('Development testing notice'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'signup remains usable at width$width text$scale with keyboard',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final preferences = MemoryPreferences();
          preferences.values['paths.auth.onboarding'] = true;
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: PathsApp(
                repository: repository(ApiAdapter(), preferences: preferences),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            MediaQuery.textScalerOf(
              tester.element(find.byType(CredentialsScreen)),
            ).scale(10),
            10 * scale,
          );
          await tap(tester, 'New to Paths? Create an account');
          tester.view.viewInsets = FakeViewPadding(bottom: 300);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Create account').last);
          expect(tester.takeException(), null);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          expect(tester.takeException(), null);
        },
      );
    }
  }
  testWidgets(
    'profile details save keeps edits on conflict and persists the canonical form',
    (tester) async {
      final adapter = ApiAdapter()..adultChecked = true;
      await signInForSetup(tester, adapter);
      expect(find.text('Make it your profile'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'Test_Case',
      );
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prefer not to say').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bio (optional)'),
        'A fixture bio',
      );
      adapter.profileConflict = true;
      await tap(tester, 'Save details');
      expect(
        find.text('That username is already taken. Choose another.'),
        findsOneWidget,
      );
      expect(find.text('Test_Case'), findsOneWidget);
      adapter.profileConflict = false;
      await tap(tester, 'Save details');
      expect(find.text('Your profile details are saved.'), findsOneWidget);
      expect(adapter.profile['username'], 'test_case');
      expect(adapter.profile['gender'], 'prefer_not_to_say');
      expect(adapter.profile['bio'], 'A fixture bio');
      expect(adapter.profile.containsKey('dateOfBirth'), false);
      expect(find.text('Age confirmed'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'retrying an edit does not announce saved while the retry is pending',
    (tester) async {
      final adapter = ApiAdapter()..adultChecked = true;
      await signInForSetup(tester, adapter);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'fixture_person',
      );
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Man').last);
      await tester.pumpAndSettle();
      await tap(tester, 'Save details');
      expect(find.text('Your profile details are saved.'), findsOneWidget);
      adapter.profileConflict = true;
      await tap(tester, 'Save details');
      expect(
        find.text('That username is already taken. Choose another.'),
        findsOneWidget,
      );
      adapter.profileSaveStarted = Completer<void>();
      adapter.profileSaveRelease = Completer<void>();
      await tester.tap(find.text('Save details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(adapter.profileSaveStarted!.isCompleted, true);
      expect(find.text('Your profile details are saved.'), findsNothing);
      adapter.profileSaveRelease!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Your profile details are saved.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  for (final adult in [false, true]) {
    testWidgets('${adult ? 'profile details' : 'age check'} visual fixture', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final adapter = ApiAdapter()..adultChecked = adult;
      await signInForSetup(tester, adapter);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/${adult ? 'profile-details' : 'age-check'}.png',
        ),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
  testWidgets(
    'profile setup keeps sign-out available after the age-only page',
    (tester) async {
      final adapter = ApiAdapter()..adultChecked = true;
      await signInForSetup(tester, adapter);
      expect(find.text('Sign out'), findsOneWidget);
      await tap(tester, 'Sign out');
      expect(find.text('Good to see you'), findsOneWidget);
      expect(find.text('Make it your profile'), findsNothing);
      expect(
        adapter.requests.where((r) => r.path == '/v1/auth/logout').length,
        1,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('onboarding visual fixture', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PathsApp(repository: repository(ApiAdapter())));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future.wait([
        precacheImage(
          const AssetImage('assets/onboarding/friends-walking.jpg'),
          tester.element(find.byType(Image).first),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/auth-onboarding.png'),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('sign-in visual fixture', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferences = MemoryPreferences();
    preferences.values['paths.auth.onboarding'] = true;
    await tester.pumpWidget(
      PathsApp(repository: repository(ApiAdapter(), preferences: preferences)),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/auth-login.png'),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets(
    'restricted accounts retain support and deletion contact routes',
    (tester) async {
      final preferences = MemoryPreferences();
      preferences.values['paths.auth.onboarding'] = true;
      final adapter = ApiAdapter()..restricted = true;
      await tester.pumpWidget(
        PathsApp(repository: repository(adapter, preferences: preferences)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'fixture@example.invalid',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'a long fixture password',
      );
      await tap(tester, 'Sign in');
      expect(find.text('Your account is restricted'), findsOneWidget);
      expect(find.text('Contact support'), findsOneWidget);
      expect(find.text('Ask support about deletion'), findsOneWidget);
      final router = GoRouter.of(
        tester.element(find.text('Your account is restricted')),
      );
      router.go('/setup/profile');
      await tester.pumpAndSettle();
      expect(find.text('Your account is restricted'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
