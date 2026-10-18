import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/authenticated_api.dart';
import 'package:paths_mobile/core/network/authenticated_media_api.dart';
import 'package:paths_mobile/features/media/data/http_media_repository.dart';
import 'package:paths_mobile/features/media/presentation/private_image.dart';

class PictureFixture implements AuthenticatedApi, AuthenticatedMediaApi {
  final reads = <bool>[];
  @override
  String? accountId = 'fixture';
  @override
  Future<String> installationId() async => 'fixture';
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) => throw UnsupportedError('No JSON requests in image fixture');
  @override
  Future<void> uploadImage(
    String assetId,
    Uint8List bytes, {
    CancelToken? cancelToken,
    ProgressCallback? onProgress,
  }) => throw UnsupportedError('No uploads in image fixture');
  @override
  Future<Uint8List> imageBytes(
    String assetId, {
    bool thumbnail = true,
    CancelToken? cancelToken,
  }) async {
    reads.add(thumbnail);
    return base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGMQqT33HwAEZwJfK8P9SAAAAABJRU5ErkJggg==',
    );
  }
}

void main() {
  testWidgets('a photo mounted while backgrounded waits for resume', (
    tester,
  ) async {
    final fixture = PictureFixture(),
        repo = HttpMediaRepository(fixture, fixture);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PrivateImage(repository: repo, assetId: 'fixture'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(fixture.reads, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(fixture.reads, [true]);
    await tester.pumpWidget(const SizedBox());
    repo.dispose();
  });
  testWidgets(
    'hidden private photos do not fetch or retain pixels and resume only when visible',
    (tester) async {
      final fixture = PictureFixture(),
          repo = HttpMediaRepository(fixture, fixture);
      Widget host(bool visible) => MaterialApp(
        home: Material(
          child: TickerMode(
            enabled: visible,
            child: PrivateImage(repository: repo, assetId: 'fixture'),
          ),
        ),
      );
      await tester.pumpWidget(host(false));
      await tester.pumpAndSettle();
      expect(fixture.reads, isEmpty);
      await tester.pumpWidget(host(true));
      await tester.pumpAndSettle();
      expect(fixture.reads, [true]);
      for (var i = 0; i < 20 && find.byType(RawImage).evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      await tester.pumpWidget(host(false));
      await tester.pumpAndSettle();
      expect(find.byType(RawImage), findsNothing);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(fixture.reads, [true]);
      await tester.pumpWidget(host(true));
      await tester.pumpAndSettle();
      expect(fixture.reads, [true, true]);
      await tester.pumpWidget(const SizedBox());
      repo.dispose();
    },
  );
  testWidgets(
    'switching from thumbnail to full image reauthorizes the requested variant',
    (tester) async {
      final fixture = PictureFixture(),
          repo = HttpMediaRepository(fixture, fixture);
      Widget host(bool thumbnail) => MaterialApp(
        home: Material(
          child: PrivateImage(
            repository: repo,
            assetId: 'fixture',
            thumbnail: thumbnail,
          ),
        ),
      );
      await tester.pumpWidget(host(true));
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(false));
      await tester.pumpAndSettle();
      expect(fixture.reads, [true, false]);
      await tester.pumpWidget(const SizedBox());
      repo.dispose();
    },
  );
}
