import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/app/theme/paths_theme.dart';
import 'package:paths_mobile/shared/widgets/paths_toast.dart';
import 'package:paths_mobile/features/media/domain/media_repository.dart';
import 'package:paths_mobile/features/media/presentation/photo_screen.dart';

import 'upload_cubit_test.dart' show Media;

class PhotoPickerFixture implements PhotoPicker {
  @override
  Future<void> discardLostSelection() async {}
  @override
  Future<PickedPhoto?> pick(PhotoSource source) async => PickedPhoto(
    Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aF9sAAAAASUVORK5CYII=',
      ),
    ),
    'image/png',
  );
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'Inter': 'assets/fonts/Inter-Variable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'photo preview fits width $width text $scale and confirms discard',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          bool cancelled = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: PathsTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: PathsToastHost(child: child!),
              ),
              home: PhotoScreen(
                media: Media(),
                picker: PhotoPickerFixture(),
                kind: MediaKind.avatar,
                onReady: (_) {},
                onCancel: () => cancelled = true,
              ),
            ),
          );
          await tester.ensureVisible(find.text('Gallery'));
          await tester.tap(find.text('Gallery'));
          await tester.pumpAndSettle();
          expect(find.text('Use photo'), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (width == 390 && scale == 1) {
            await expectLater(
              find.byType(Scaffold).first,
              matchesGoldenFile('goldens/photo-preview.png'),
            );
          }
          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle();
          expect(find.text('Discard photo?'), findsOneWidget);
          await tester.tap(find.text('Discard'));
          await tester.pumpAndSettle();
          expect(cancelled, true);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
