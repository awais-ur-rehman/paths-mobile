import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/media/data/http_media_repository.dart';
import 'package:paths_mobile/features/media/presentation/media_scope.dart';
import 'package:paths_mobile/features/posts/data/post_repository.dart';
import 'package:paths_mobile/features/profile/presentation/profile_surface.dart';
import 'package:paths_mobile/features/settings/presentation/profile_settings_screen.dart';
import 'package:paths_mobile/shared/widgets/paths_icon.dart';

import '../media/private_image_lifecycle_test.dart' show PictureFixture;
import '../media/photo_screen_test.dart' show PhotoPickerFixture;
import '../posts/posts_cubit_test.dart' show Api;
import 'profile_surface_redesign_test.dart' show profile;

import 'package:paths_mobile/features/profile/domain/profile_repository.dart';

class SamplePhoto extends PictureFixture {
  SamplePhoto(this.bytes);
  final Uint8List bytes;
  @override
  Future<Uint8List> imageBytes(
    String id, {
    bool thumbnail = true,
    CancelToken? cancelToken,
  }) async => Uint8List.fromList(bytes);
}

class SamplePosts extends Api {
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) async => {
    'items': [
      for (var i = 0; i < 4; i++)
        PostDto(
          id: 'p$i',
          assetId: 'image$i',
          caption: '',
          state: 'published',
          createdDate: '2026-01-01',
        ).toJson(),
    ],
    'nextCursor': null,
    'locked': false,
  };
}

List<ProfileSetting> settings() => [
  for (final (section, label, icon) in [
    ('Your account', 'Edit profile', PathsIconName.profile),
    ('Your account', 'Verification', PathsIconName.verified),
    ('Your account', 'Sign-in methods', PathsIconName.key),
    ('Privacy and preferences', 'Profile privacy', PathsIconName.lock),
    (
      'Privacy and preferences',
      'Location & permissions',
      PathsIconName.location,
    ),
    ('Privacy and preferences', 'Notifications', PathsIconName.bell),
    ('Safety', 'Blocked accounts', PathsIconName.block),
    ('Safety', 'Reviews', PathsIconName.review),
    ('Account actions', 'Delete account', PathsIconName.trash),
    ('Account actions', 'Sign out', PathsIconName.logout),
  ])
    ProfileSetting(section: section, label: label, icon: icon, onTap: () {}),
];
void main() {
  setUpAll(() async {
    for (final (name, path) in [
      ('Inter', 'assets/fonts/Inter-Variable.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(name)..addFont(rootBundle.load(path))).load();
    }
  });
  for (final width in [320.0, 390.0]) {
    for (final own in [true, false]) {
      testWidgets('portrait ${own ? 'own' : 'member'} $width', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final bytes = (await rootBundle.load(
              'assets/onboarding/friends-walking.jpg',
            )).buffer.asUint8List(),
            photo = SamplePhoto(bytes),
            media = HttpMediaRepository(SamplePosts(), photo);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: PathsTheme.light,
            home: MediaScope(
              media: media,
              picker: PhotoPickerFixture(),
              posts: PostRepository(SamplePosts()),
              child: Scaffold(
                body: ProfileSurface(
                  profile: ProfileSummary(
                    userId: profile.userId,
                    username: profile.username,
                    name: profile.name,
                    age: 26,
                    gender: 'man',
                    bio: 'A familiar face. A new connection.',
                    visibility: 'public',
                    verificationStatus: own ? 'approved' : 'none',
                    avatarAssetId: 'portrait',
                    photoState: 'ready',
                  ),
                  menu: own ? ProfileSettingsButton(onPressed: () {}) : null,
                  onBack: own ? null : () {},
                  action: own
                      ? null
                      : FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Message'),
                        ),
                ),
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
          matchesGoldenFile(
            'goldens/profile-${own ? 'own' : 'member'}-${width.toInt()}.png',
          ),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        media.dispose();
      });
    }
  }
  for (final width in [320.0, 390.0]) {
    testWidgets('settings $width', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: PathsTheme.light,
          home: ProfileSettingsScreen(entries: settings(), onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/settings-${width.toInt()}.png'),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/settings-actions-${width.toInt()}.png'),
      );
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final screen in ['profile', 'settings']) {
    testWidgets('$screen fits large text and keyboard', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: PathsTheme.light,
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 700),
              textScaler: TextScaler.linear(2),
              viewInsets: EdgeInsets.only(bottom: 280),
            ),
            child: child!,
          ),
          home: screen == 'profile'
              ? Scaffold(
                  body: ProfileSurface(
                    profile: profile,
                    menu: ProfileSettingsButton(onPressed: () {}),
                  ),
                )
              : ProfileSettingsScreen(entries: settings(), onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
