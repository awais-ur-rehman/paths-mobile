import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paths_mobile/features/discovery/presentation/encounter_bloc.dart';
import 'package:paths_mobile/features/discovery/presentation/widgets/encounter_card.dart';
import 'package:paths_mobile/features/discovery/presentation/widgets/encounter_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/discovery/domain/encounter_repository.dart';
import 'package:paths_mobile/features/discovery/presentation/home_screen.dart';
import 'package:paths_mobile/shared/widgets/paths_toast.dart';

import 'encounter_bloc_test.dart' show page;

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
  testWidgets(
    'an in-flight refresh does not rebuild unchanged encounter cards',
    (tester) async {
      final repo = HomeFixture();
      await tester.pumpWidget(app(repo));
      await tester.pumpAndSettle();
      final before = tester.widget<EncounterCard>(
        find.byType(EncounterCard).first,
      );
      repo.pause = Completer();
      final bloc = tester
          .element(find.byType(EncounterCard).first)
          .read<EncounterBloc>();
      bloc.add(const RefreshEncounters());
      await tester.pump();
      await tester.pump();
      expect(bloc.state.loading, true);
      expect(
        identical(
          before,
          tester.widget<EncounterCard>(find.byType(EncounterCard).first),
        ),
        true,
      );
      repo.pause!.complete(repo.result);
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'map fallback offers an explicit retry without adding another primary action',
    (tester) async {
      final bloc = EncounterBloc(HomeFixture());
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: Scaffold(
              body: EncounterFiltersBar(
                styleUrl: 'https://map.example.invalid/style.json',
                showMap: false,
                mapFailed: true,
                onToggleMap: () => retried = true,
              ),
            ),
          ),
        ),
      );
      expect(find.byTooltip('Retry map'), findsOneWidget);
      await tester.tap(find.byTooltip('Retry map'));
      expect(retried, true);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(bloc.close);
    },
  );

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
        expect(find.text('Fixture a, 30'), findsOneWidget);
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
      expect(find.text('Enable location to explore nearby'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Location settings'),
        findsOneWidget,
      );
      await tester.tap(find.text('Location settings'));
      expect(settings, 1);
      await tester.tap(find.text('Recent'));
      await tester.pumpAndSettle();
      expect(find.text('No paths crossed yet'), findsOneWidget);
    },
  );
  testWidgets('API error retries and unavailable map retains real list', (
    tester,
  ) async {
    final repo = HomeFixture()..error = const AuthFailure('offline');
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.text('You’re offline'), findsOneWidget);
    repo.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Fixture a, 30'), findsOneWidget);
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
