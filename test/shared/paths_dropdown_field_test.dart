import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/shared/widgets/paths_dropdown_field.dart';

const choices = [
  PathsDropdownOption('man', 'Man'),
  PathsDropdownOption('woman', 'Woman'),
  PathsDropdownOption('another', 'Another identity'),
  PathsDropdownOption('private', 'Prefer not to say'),
];
void main() {
  testWidgets(
    'system back dismisses the menu and open-menu disposal releases focus',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          home: Scaffold(
            body: PathsDropdownField<String>(
              label: 'Gender',
              options: choices,
              value: null,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PathsDropdownField<String>));
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNWidgets(4));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNothing);
      await tester.tap(find.byType(PathsDropdownField<String>));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'validation, selection and reopening reflect the selected option',
    (tester) async {
      final form = GlobalKey<FormState>();
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          home: Scaffold(
            body: Form(
              key: form,
              child: PathsDropdownField<String>(
                label: 'Gender',
                options: choices,
                value: null,
                onChanged: (value) => selected = value,
                validator: (value) =>
                    value == null ? 'Choose an option.' : null,
              ),
            ),
          ),
        ),
      );
      expect(form.currentState!.validate(), false);
      await tester.pump();
      expect(find.text('Choose an option.'), findsOneWidget);
      await tester.tap(find.byType(PathsDropdownField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Woman').last);
      await tester.pumpAndSettle();
      expect(selected, 'woman');
      expect(form.currentState!.validate(), true);
      await tester.pump();
      expect(find.text('Choose an option.'), findsNothing);
      await tester.tap(find.byType(PathsDropdownField<String>));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNothing);
      expect(find.text('Woman'), findsOneWidget);
    },
  );
  testWidgets(
    'disabled field cannot open and externally loaded value updates',
    (tester) async {
      Widget screen(String? value, bool enabled) => MaterialApp(
        theme: PathsTheme.light,
        home: Scaffold(
          body: PathsDropdownField<String>(
            label: 'Gender',
            options: choices,
            value: value,
            enabled: enabled,
            onChanged: (_) => fail('disabled field changed'),
          ),
        ),
      );
      await tester.pumpWidget(screen('man', true));
      await tester.pumpWidget(screen('woman', false));
      expect(find.text('Woman'), findsOneWidget);
      await tester.tap(find.byType(PathsDropdownField<String>));
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNothing);
    },
  );
  testWidgets('menu remains readable on a narrow screen at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: PathsDropdownField<String>(
              label: 'Gender',
              options: choices,
              value: null,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(PathsDropdownField<String>));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Prefer not to say'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Prefer not to say'));
    await tester.pumpAndSettle();
    expect(find.text('Prefer not to say'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
