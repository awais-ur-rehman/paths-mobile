import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/media/data/http_media_repository.dart';
import 'package:paths_mobile/features/media/presentation/private_image.dart';

import 'private_image_lifecycle_test.dart' show PictureFixture;

class LargeImage extends PictureFixture {
  LargeImage(this.bytes);
  final Uint8List bytes;
  @override
  Future<Uint8List> imageBytes(
    String id, {
    bool thumbnail = true,
    CancelToken? cancelToken,
  }) async => Uint8List.fromList(bytes);
}

void main() {
  testWidgets('small private avatar decodes to rendered physical width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.blue, BlendMode.src);
    final picture = recorder.endRecording();
    final image = await tester.runAsync(() => picture.toImage(512, 512));
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    image!.dispose();
    picture.dispose();
    final api = LargeImage(data!.buffer.asUint8List());
    final actual = HttpMediaRepository(api, api);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: SizedBox(
              width: 48,
              height: 48,
              child: PrivateImage(repository: actual, assetId: 'fixture'),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 30 && find.byType(RawImage).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(tester.widget<RawImage>(find.byType(RawImage)).image!.width, 96);
    await tester.pumpWidget(const SizedBox());
    actual.dispose();
  });
}
