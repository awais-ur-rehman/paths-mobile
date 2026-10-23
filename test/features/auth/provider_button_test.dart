import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/auth/domain/provider_auth.dart';
import 'package:paths_mobile/features/auth/presentation/provider_button.dart';

void main() {
  for (final provider in IdentityProvider.values) {
    testWidgets(
      '${provider.name} circle keeps a named keyboard action and disabled state',
      (tester) async {
        var calls = 0;
        final label = provider == IdentityProvider.google
            ? 'Sign in with Google'
            : 'Sign in with Apple';
        Future<void> render(bool enabled) => tester.pumpWidget(
          MaterialApp(
            theme: PathsTheme.light,
            home: Scaffold(
              body: Center(
                child: ProviderButton(
                  provider: provider,
                  onPressed: enabled ? () => calls++ : null,
                ),
              ),
            ),
          ),
        );
        await render(true);
        final size = tester.getSize(find.byType(ProviderButton));
        expect(size.width, size.height);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(find.byTooltip(label), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(calls, 1);
        await render(false);
        await tester.tap(find.byType(ProviderButton));
        await tester.pump();
        expect(calls, 1);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
