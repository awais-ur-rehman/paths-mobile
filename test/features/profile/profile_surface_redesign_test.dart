import 'package:flutter/material.dart';
import 'package:paths_mobile/features/media/data/http_media_repository.dart';
import 'package:paths_mobile/features/media/presentation/media_scope.dart';
import 'package:paths_mobile/features/media/presentation/private_image.dart';
import 'package:paths_mobile/features/posts/data/post_repository.dart';

import '../media/private_image_lifecycle_test.dart' show PictureFixture;
import '../media/photo_screen_test.dart' show PhotoPickerFixture;
import '../posts/posts_cubit_test.dart' show Api;

import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/features/profile/domain/profile_repository.dart';
import 'package:paths_mobile/features/profile/presentation/profile_surface.dart';

const profile = ProfileSummary(
  userId: 'owner',
  username: 'fixture_user',
  name: 'Fixture User',
  age: 26,
  gender: 'man',
  bio: 'A plain biography',
  visibility: 'public',
  verificationStatus: 'approved',
);
void main() {
  testWidgets(
    'identity has parallel status, plain bio and a right-side back control',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          home: Scaffold(
            body: ProfileSurface(profile: profile, onBack: () {}),
          ),
        ),
      );
      expect(find.text('Fixture User'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(tester.getCenter(find.byTooltip('Back')).dx, greaterThan(600));
      expect(
        tester.getCenter(find.text('Verified')).dy,
        closeTo(tester.getCenter(find.text('Public profile')).dy, 1),
      );
      expect(
        find.ancestor(
          of: find.text('A plain biography'),
          matching: find.byType(Container),
        ),
        findsNothing,
      );
      expect(find.byType(CustomScrollView), findsOneWidget);
    },
  );
  testWidgets('portrait blur reuses its decoded private frame', (tester) async {
    final picture = PictureFixture();
    final repository = HttpMediaRepository(picture, picture);
    await tester.pumpWidget(
      MaterialApp(
        theme: PathsTheme.light,
        home: MediaScope(
          media: repository,
          picker: PhotoPickerFixture(),
          posts: PostRepository(Api()),
          child: const Scaffold(
            body: ProfileSurface(
              profile: ProfileSummary(
                userId: 'owner',
                username: 'fixture',
                name: 'Fixture',
                age: 26,
                gender: 'man',
                bio: '',
                visibility: 'public',
                verificationStatus: 'none',
                avatarAssetId: 'portrait',
                photoState: 'ready',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ImageFiltered), findsOneWidget);
    final portraitImages = tester
        .widgetList<RawImage>(
          find.descendant(
            of: find.byType(ImageFiltered),
            matching: find.byType(RawImage),
          ),
        )
        .toList();
    expect(portraitImages, hasLength(1));
    final shared = tester
        .widgetList<RawImage>(
          find.descendant(
            of: find.byType(PrivateImage).first,
            matching: find.byType(RawImage),
          ),
        )
        .toList();
    expect(shared, hasLength(2));
    expect(identical(shared[0].image, shared[1].image), isTrue);
    expect(picture.reads.where((thumbnail) => !thumbnail), hasLength(1));
    await repository.purge();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    repository.dispose();
  });
}
