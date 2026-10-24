import 'map_platform_fixture.dart';

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paths_mobile/features/discovery/presentation/encounter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paths_mobile/core/platform/location_tracker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/discovery/domain/encounter_repository.dart';
import 'package:paths_mobile/features/discovery/presentation/home_screen.dart';
import 'package:paths_mobile/shared/widgets/paths_toast.dart';

import 'encounter_bloc_test.dart' show page;
import 'location_sync_service_test.dart';

import 'package:paths_mobile/features/discovery/data/location_sync_service.dart';
import 'package:paths_mobile/features/discovery/presentation/widgets/encounter_map.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class SettingsTracker extends CapturingTracker {
  int settingsOpened = 0;
  @override
  Future<TrackingPermissions> permissions() async => TrackingPermissions(
    granted: granted,
    precise: granted,
    backgroundAllowed: false,
    servicesEnabled: true,
    canRequestForeground: false,
  );
  @override
  Future<void> openSettings() async {
    settingsOpened++;
  }
}

class HomeFixture implements EncounterRepository {
  @override
  String? discoveryAccountId = 'fixture-account';
  EncounterPage result = page(['a', 'b']);
  AuthFailure? error;
  Completer<EncounterPage>? pause;
  final modes = <EncounterMode>[];
  @override
  Future<EncounterPage> loadEncounters({
    EncounterMode mode = EncounterMode.recent,
    double radiusKm = 1,
    String search = '',
    String? cursor,
    CancelToken? cancelToken,
  }) async {
    modes.add(mode);
    if (error != null) throw error!;
    return pause?.future ?? result;
  }
}

Widget app(
  HomeFixture repo, {
  ValueChanged<String>? onProfile,
  VoidCallback? onLocation,
  double scale = 1,
}) => MaterialApp(
  theme: PathsTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: PathsToastHost(child: child!),
  ),
  home: HomeScreen(
    repository: repo,
    onProfile: onProfile ?? (_) {},
    onLocationSetup: onLocation ?? () {},
    mapStyleUrl: '',
  ),
);
void main() {
  final originalMapFactory = MapLibrePlatform.createInstance;
  setUp(() {
    MapLibrePlatform.createInstance = () => TestMapPlatform();
  });
  tearDown(() {
    MapLibrePlatform.createInstance = originalMapFactory;
  });
  testWidgets('empty history still renders map before server center exists', (
    tester,
  ) async {
    final repo = HomeFixture()
      ..result = EncounterPage(
        items: [],
        nextCursor: null,
        nearbyAvailable: false,
        centerLatitude: null,
        centerLongitude: null,
      );
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        home: HomeScreen(
          repository: repo,
          onProfile: (_) {},
          onLocationSetup: () {},
          mapStyleUrl: 'https://map.example.invalid/style.json',
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(EncounterMap), findsOneWidget);
    expect(
      tester.widget<MapLibreMap>(find.byType(MapLibreMap)).myLocationEnabled,
      false,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets(
    'own-location layer follows permission changes without encounter history',
    (tester) async {
      final tracker = CapturingTracker()..status = TrackingStatus.active;
      final sync = LocationSyncService(
        FixtureLocationRepository(),
        tracker,
        MemoryTrackingControls(),
        'https://api.example.invalid',
      );
      final repo = HomeFixture()
        ..result = EncounterPage(
          items: [],
          nextCursor: null,
          nearbyAvailable: false,
          centerLatitude: null,
          centerLongitude: null,
        );
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          builder: (_, child) => PathsToastHost(child: child!),
          home: HomeScreen(
            repository: repo,
            locations: sync,
            onProfile: (_) {},
            onLocationSetup: () {},
            mapStyleUrl: 'https://map.example.invalid/style.json',
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<MapLibreMap>(find.byType(MapLibreMap)).myLocationEnabled,
        true,
      );
      tracker.granted = false;
      tracker.statuses.add(TrackingStatus.permissionNeeded);
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<MapLibreMap>(find.byType(MapLibreMap)).myLocationEnabled,
        false,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await sync.close();
      await tracker.dispose();
    },
  );
  testWidgets('an existing OS grant does not silently restart paused sharing', (
    tester,
  ) async {
    final tracker = CapturingTracker();
    final data = FixtureLocationRepository();
    final sync = LocationSyncService(
      data,
      tracker,
      MemoryTrackingControls(),
      'https://api.example.invalid',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        builder: (_, child) => PathsToastHost(child: child!),
        home: HomeScreen(
          repository: HomeFixture(),
          locations: sync,
          onProfile: (_) {},
          onLocationSetup: () {},
          mapStyleUrl: '',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(data.grants, 0);
    expect(tracker.starts, 0);
    expect(find.byTooltip('Enable location'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await sync.close();
    await tracker.dispose();
  });
  testWidgets('permanent denial uses Settings and resumes an explicit grant', (
    tester,
  ) async {
    final tracker = SettingsTracker()..granted = false;
    final data = FixtureLocationRepository();
    final sync = LocationSyncService(
      data,
      tracker,
      MemoryTrackingControls(),
      'https://api.example.invalid',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        builder: (_, child) => PathsToastHost(child: child!),
        home: HomeScreen(
          repository: HomeFixture(),
          locations: sync,
          onProfile: (_) {},
          onLocationSetup: () {},
          mapStyleUrl: '',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Allow location'), findsNothing);
    await tester.tap(find.byTooltip('Enable location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(tracker.settingsOpened, 1);
    expect(data.grants, 0);
    tracker.granted = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(data.grants, 1);
    expect(tracker.policy?.background, false);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await sync.close();
    await tracker.dispose();
  });
  testWidgets(
    'first Home visit offers location once and denial keeps Home usable',
    (tester) async {
      final tracker = CapturingTracker()..granted = false;
      final sync = LocationSyncService(
        FixtureLocationRepository(),
        tracker,
        MemoryTrackingControls(),
        'https://api.example.invalid',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          builder: (_, child) => PathsToastHost(child: child!),
          home: HomeScreen(
            repository: HomeFixture(),
            locations: sync,
            onProfile: (_) {},
            onLocationSetup: () {},
            mapStyleUrl: '',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Allow location'), findsOneWidget);
      await tester.tap(find.text('Allow location'));
      await tester.pumpAndSettle();
      expect(tracker.starts, 0);
      expect(find.text('Recent'), findsOneWidget);
      expect(find.byTooltip('Enable location'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Enable location'));
      await tester.pumpAndSettle();
      expect(find.text('Allow location'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await sync.close();
      await tracker.dispose();
    },
  );
  testWidgets('returning from a peer refreshes Home relationship metadata', (
    tester,
  ) async {
    final repo = HomeFixture();
    final returned = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        home: HomeScreen(
          repository: repo,
          onProfile: (_) => returned.future,
          onLocationSetup: () {},
          mapStyleUrl: '',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = repo.modes.length;
    await tester.tap(find.bySemanticsLabel('2 crossed paths. Open profiles.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fixture a, 30'));
    await tester.pump();
    expect(repo.modes.length, before);
    returned.complete();
    await tester.pumpAndSettle();
    expect(repo.modes.length, before + 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('an in-flight refresh does not rebuild unchanged encounter map', (
    tester,
  ) async {
    final repo = HomeFixture();
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    final before = tester.widget<EncounterMap>(find.byType(EncounterMap));
    repo.pause = Completer();
    final bloc = tester
        .element(find.byType(EncounterMap))
        .read<EncounterBloc>();
    bloc.add(const RefreshEncounters());
    await tester.pump();
    await tester.pump();
    expect(bloc.state.loading, true);
    expect(
      identical(before, tester.widget<EncounterMap>(find.byType(EncounterMap))),
      true,
    );
    repo.pause!.complete(repo.result);
    await tester.pumpAndSettle();
  });
  setUpAll(() async {
    for (final e in {
      'Inter': 'assets/fonts/Inter-Variable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Home remains concise and usable at$width text$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = HomeFixture();
        String? selected;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: app(repo, onProfile: (id) => selected = id, scale: scale),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Recent'), findsOneWidget);
        expect(find.text('Nearby'), findsOneWidget);
        expect(find.text('Fixture a, 30'), findsNothing);
        await tester.tap(
          find.bySemanticsLabel('2 crossed paths. Open profiles.'),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Fixture a, 30'));
        await tester.tap(find.text('Fixture a, 30'));
        await tester.pumpAndSettle();
        expect(selected, 'a');
        expect(find.byType(FilledButton), findsNothing);
        expect(find.textContaining('Observations are kept'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
    }
  }
  testWidgets(
    'denied Nearby keeps Recent available and offers one contextual action',
    (tester) async {
      final repo = HomeFixture()..result = page([], nearby: false);
      var settings = 0;
      await tester.pumpWidget(app(repo, onLocation: () => settings++));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nearby'));
      await tester.pumpAndSettle();
      expect(repo.modes.last, EncounterMode.nearby);
      expect(find.text('Location needed for Nearby'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Enable'), findsOneWidget);
      await tester.tap(find.text('Enable'));
      expect(settings, 1);
      await tester.tap(find.text('Recent'));
      await tester.pumpAndSettle();
      expect(find.text('No paths crossed yet'), findsOneWidget);
    },
  );
  testWidgets('API error retries without replacing the map', (tester) async {
    final repo = HomeFixture()..error = const AuthFailure('offline');
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.text('You’re offline'), findsOneWidget);
    repo.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(EncounterMapMarker), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('Home visual fixture', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(HomeFixture()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/home-encounters.png'),
    );
  });
}
