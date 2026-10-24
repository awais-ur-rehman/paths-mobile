import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/discovery/domain/encounter_repository.dart';
import 'package:paths_mobile/features/discovery/presentation/home_screen.dart';
import 'package:paths_mobile/features/media/data/http_media_repository.dart';
import 'package:paths_mobile/features/media/presentation/media_scope.dart';
import 'package:paths_mobile/features/posts/data/post_repository.dart';
import 'package:paths_mobile/shared/widgets/paths_bottom_navigation.dart';

import '../profile/profile_visual_test.dart' show SamplePhoto, SamplePosts;
import '../media/photo_screen_test.dart' show PhotoPickerFixture;
import '../requests/relationship_cubit_test.dart' show RelationshipFixture;
import 'home_screen_test.dart' show HomeFixture;
import 'map_platform_fixture.dart';

void main() {
  final original = MapLibrePlatform.createInstance;
  setUp(() => MapLibrePlatform.createInstance = () => TestMapPlatform());
  tearDown(() => MapLibrePlatform.createInstance = original);
  setUpAll(() async {
    for (final (name, path) in [
      ('Inter', 'assets/fonts/Inter-Variable.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(name)..addFont(rootBundle.load(path))).load();
    }
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('map and member preview $width', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final fixture = HomeFixture();
      final items = fixture.result.items
          .map(
            (e) => Encounter(
              encounterId: e.encounterId,
              avatarAssetId: 'layout-fixture',
              userId: e.userId,
              username: e.username,
              displayName: e.displayName,
              age: e.age,
              bio: 'A familiar face. A new connection.',
              verificationStatus: 'approved',
              coarseAreaId: e.coarseAreaId,
              coarseAreaLabel: e.coarseAreaLabel,
              areaLatitude: e.areaLatitude,
              areaLongitude: e.areaLongitude,
              timeBucket: e.timeBucket,
              encounterDate: e.encounterDate,
              encounterCount: 3,
              eligibilityExpiresAt: e.eligibilityExpiresAt,
            ),
          )
          .toList();
      fixture.result = EncounterPage(
        items: items,
        nextCursor: null,
        nearbyAvailable: false,
        centerLatitude: null,
        centerLongitude: null,
      );
      final bytes = (await rootBundle.load(
        'assets/onboarding/friends-walking.jpg',
      )).buffer.asUint8List();
      final media = HttpMediaRepository(SamplePosts(), SamplePhoto(bytes));
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: PathsTheme.light,
          builder: (context, child) => MediaScope(
            media: media,
            picker: PhotoPickerFixture(),
            posts: PostRepository(SamplePosts()),
            child: child!,
          ),
          home: Scaffold(
            extendBody: true,
            body: HomeScreen(
              repository: fixture,
              relationships: RelationshipFixture(),
              onProfile: (_) {},
              onLocationSetup: () {},
            ),
            bottomNavigationBar: PathsBottomNavigationBar(
              items: PathsNavItem.values,
              selectedIndex: 0,
              onSelected: (_) {},
              onCamera: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home-map-${width.toInt()}.png'),
      );
      await tester.tap(
        find.bySemanticsLabel('2 crossed paths. Open profiles.'),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home-preview-${width.toInt()}.png'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}
