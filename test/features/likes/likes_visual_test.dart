import 'package:flutter/material.dart';
import 'package:paths_mobile/features/relationships/presentation/likes_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/media/data/http_media_repository.dart';
import 'package:paths_mobile/features/media/presentation/media_scope.dart';
import 'package:paths_mobile/features/posts/data/post_repository.dart';
import 'package:paths_mobile/features/relationships/presentation/likes_screen.dart';

import '../media/photo_screen_test.dart' show PhotoPickerFixture;
import '../posts/posts_cubit_test.dart' show Api;
import '../profile/profile_visual_test.dart' show SamplePhoto;
import 'likes_search_test.dart' show SearchPages;

void main() {
  setUpAll(() async {
    for (final (name, path) in [
      ('Inter', 'assets/fonts/Inter-Variable.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(name)..addFont(rootBundle.load(path))).load();
    }
  });
  testWidgets('photo failure announces only the working profile action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final media = HttpMediaRepository(Api(), SamplePhoto(Uint8List(0)));
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          home: MediaScope(
            media: media,
            picker: PhotoPickerFixture(),
            posts: PostRepository(Api()),
            child: Scaffold(
              body: SizedBox(
                width: 180,
                height: 240,
                child: LikesCard(
                  item: const RelationshipCardDto(
                    id: '1',
                    targetId: 'peer',
                    displayName: 'Alex',
                    username: 'alex',
                    age: 27,
                    bio: '',
                    verificationStatus: 'none',
                    photoState: 'ready',
                    avatarAssetId: 'photo',
                    available: true,
                    saved: true,
                    state: 'none',
                    direction: 'none',
                    expiresAt: null,
                  ),
                  onOpen: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('Photo unavailable')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Open Alex')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    } finally {
      semantics.dispose();
      media.dispose();
    }
  });
  for (final width in [320.0, 390.0]) {
    for (final largeText in [false, true]) {
      testWidgets('Likes photo grid $width large text $largeText', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final photo = SamplePhoto(
          (await rootBundle.load('assets/onboarding/friends-walking.jpg'))
              .buffer
              .asUint8List(),
        );
        final media = HttpMediaRepository(Api(), photo);
        final repo = SearchPages()
          ..result = (_, _) async => RelationshipPageDto(
            items: [
              for (var i = 0; i < 4; i++)
                RelationshipCardDto(
                  id: '$i',
                  targetId: 'peer$i',
                  displayName: i == 0 ? 'Alex Morgan' : 'Sam Taylor',
                  username: 'demo_$i',
                  age: 27,
                  bio: '',
                  verificationStatus: i.isEven ? 'approved' : 'none',
                  photoState: 'ready',
                  avatarAssetId: 'demo$i',
                  available: true,
                  saved: true,
                  state: 'none',
                  direction: 'none',
                  expiresAt: null,
                ),
            ],
            nextCursor: null,
          );
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: PathsTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(largeText ? 2 : 1),
                viewInsets: largeText
                    ? const EdgeInsets.only(bottom: 280)
                    : EdgeInsets.zero,
              ),
              child: child!,
            ),
            home: MediaScope(
              media: media,
              picker: PhotoPickerFixture(),
              posts: PostRepository(Api()),
              child: LikesScreen(repository: repo, onProfile: (_) async {}),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/likes-${width.toInt()}${largeText ? '-large-keyboard' : ''}.png',
          ),
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        media.dispose();
      });
    }
  }
}
