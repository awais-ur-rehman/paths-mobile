import 'package:flutter/material.dart';
import 'package:paths_mobile/features/safety/presentation/safety_scope.dart';

import '../safety/safety_test.dart' show FakeSafety;

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:paths_mobile/features/discovery/presentation/home_screen.dart';
import 'package:paths_mobile/features/discovery/presentation/widgets/encounter_map.dart';
import 'package:paths_mobile/features/discovery/presentation/widgets/encounter_preview.dart';
import 'package:paths_mobile/features/relationships/presentation/relationship_controls.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';

import '../requests/relationship_cubit_test.dart' show RelationshipFixture;
import 'home_screen_test.dart' show HomeFixture;
import 'map_platform_fixture.dart';

class NoStyleMap extends TestMapPlatform {
  @override
  Future<void> initPlatform(int id) async {}
}

void main() {
  final original = MapLibrePlatform.createInstance;
  setUp(() => MapLibrePlatform.createInstance = () => TestMapPlatform());
  tearDown(() => MapLibrePlatform.createInstance = original);
  testWidgets(
    'Home is a full-screen map; markers open a preview before any request',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          home: HomeScreen(
            repository: HomeFixture(),
            relationships: RelationshipFixture(),
            onProfile: (_) {},
            onLocationSetup: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EncounterMap), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      expect(
        tester.getSize(find.byType(EncounterMap)),
        tester.getSize(find.byType(Scaffold).first),
      );
      await tester.tap(
        find.bySemanticsLabel('2 crossed paths. Open profiles.'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EncounterPreview), findsOneWidget);
      expect(find.text('Fixture a, 30'), findsOneWidget);
      expect(find.byType(RelationshipControls), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Send request'), findsOneWidget);
      await tester.ensureVisible(find.text('Send request'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(find.text('Send a connection request?'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('branch preview confirmation closes on pause', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => HomeScreen(
              repository: HomeFixture(),
              relationships: RelationshipFixture(),
              onProfile: (_) {},
              onLocationSetup: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('2 crossed paths. Open profiles.'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();
    expect(find.text('Send a connection request?'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(EncounterPreview), findsNothing);
    expect(find.byType(EncounterMap), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('branch confirmation closes on safety invalidation', (
    tester,
  ) async {
    final safety = FakeSafety();
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        home: SafetyScope(
          repository: safety,
          child: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => HomeScreen(
                repository: HomeFixture(),
                relationships: RelationshipFixture(),
                onProfile: (_) {},
                onLocationSetup: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('2 crossed paths. Open profiles.'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();
    safety.events.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(EncounterPreview), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await safety.events.close();
  });

  testWidgets('native style timeout offers retry without a card fallback', (
    tester,
  ) async {
    final platforms = <TestMapPlatform>[];
    MapLibrePlatform.createInstance = () {
      final platform = platforms.isEmpty ? NoStyleMap() : TestMapPlatform();
      platforms.add(platform);
      return platform;
    };
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        home: HomeScreen(
          repository: HomeFixture(),
          onProfile: (_) {},
          onLocationSetup: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 16));
    await tester.pump();
    expect(find.text('Retry map'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    await tester.tap(find.text('Retry map'));
    await tester.pumpAndSettle();
    expect(find.byType(EncounterMap), findsOneWidget);
    expect(platforms, hasLength(2));
    expect(platforms.first.disposed, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
