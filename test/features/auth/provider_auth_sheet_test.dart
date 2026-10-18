import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/auth/presentation/provider_auth_sheet.dart';
import 'package:paths_mobile/features/auth/domain/provider_auth.dart';
import 'package:paths_mobile/shared/widgets/paths_toast.dart';

import 'provider_auth_cubit_test.dart' show Repository, Sdk;

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('provider setup fits $width at $scale with the keyboard', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = Repository()..emailRequired = true;
        await tester.pumpWidget(
          MaterialApp(
            theme: PathsTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                viewInsets: const EdgeInsets.only(bottom: 240),
              ),
              child: PathsToastHost(child: child!),
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showModalBottomSheet<Object>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ProviderAuthSheet(
                      repository: repo,
                      sdk: Sdk(),
                      provider: IdentityProvider.google,
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Email'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Continue').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(repo.accepted, 0);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets(
    'provider email collision offers one sign-in action without accepting a session',
    (tester) async {
      final repo = Repository()..kind = 'linkRequired';
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          home: Scaffold(
            body: PathsToastHost(
              child: ProviderAuthSheet(
                repository: repo,
                sdk: Sdk(),
                provider: IdentityProvider.google,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsOneWidget);
      expect(repo.accepted, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
