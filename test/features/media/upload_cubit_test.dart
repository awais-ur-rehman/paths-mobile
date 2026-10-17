import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/media/domain/media_repository.dart';
import 'package:paths_mobile/features/media/presentation/upload_cubit.dart';

class Picker implements PhotoPicker {
  final photo = PickedPhoto(Uint8List.fromList([1, 2, 3]), 'image/jpeg');
  Completer<PickedPhoto?>? pending;
  @override
  Future<PickedPhoto?> pick(PhotoSource source) async =>
      pending == null ? photo : pending!.future;
  @override
  Future<void> discardLostSelection() async {}
}

class Media implements MediaRepository {
  @override
  String? accountId = 'owner';
  int uploads = 0, cancels = 0;
  bool fail = true;
  final keys = <String>[];
  @override
  Future<MediaAsset> intent(
    MediaKind kind,
    PickedPhoto photo,
    String key, {
    CancelToken? cancelToken,
  }) async {
    keys.add(key);
    return const MediaAsset('asset', 'intent', 'pending');
  }

  @override
  Future<void> upload(
    String id,
    PickedPhoto photo, {
    CancelToken? cancelToken,
    ProgressCallback? onProgress,
  }) async {
    uploads++;
    onProgress?.call(1, 3);
    if (fail) throw const AuthFailure('offline');
  }

  @override
  Future<MediaAsset> complete(String id, {CancelToken? cancelToken}) async =>
      const MediaAsset('asset', 'queued', 'pending');
  @override
  Future<MediaAsset> status(String id, {CancelToken? cancelToken}) async =>
      const MediaAsset('asset', 'ready', 'pending');
  @override
  Future<void> cancel(String id) async {
    cancels++;
  }
}

void main() {
  test('retry keeps intent and bytes, processing ends ready without claiming approval', () async {
    final media = Media(),
        picker = Picker(),
        c = UploadCubit(
          media,
          picker,
          MediaKind.post,
          pollDelay: Duration.zero,
        );
    await c.pick(PhotoSource.gallery);
    await c.upload();
    expect(c.state.error?.code, 'offline');
    media.fail = false;
    await c.upload();
    expect(media.keys.length, 1);
    expect(media.uploads, 2);
    expect(c.state.asset?.ready, true);
    expect(c.state.asset?.safety, 'pending');
    expect(c.state.progress, 1);
    c.release();
    await c.close();
    expect(picker.photo.bytes, everyElement(0));
    expect(media.cancels, 0);
  });
  test(
    'a picker returning after close is discarded and never uploaded',
    () async {
      final media = Media(),
          picker = Picker()..pending = Completer(),
          c = UploadCubit(media, picker, MediaKind.avatar);
      final work = c.pick(PhotoSource.camera);
      await Future<void>.delayed(Duration.zero);
      await c.close();
      picker.pending!.complete(picker.photo);
      await work;
      expect(picker.photo.bytes, everyElement(0));
      expect(media.uploads, 0);
    },
  );
  test('account change prevents upload and explicit cancel clears the private draft', () async {
    final media = Media(),
        picker = Picker(),
        c = UploadCubit(media, picker, MediaKind.cnicFront);
    await c.pick(PhotoSource.gallery);
    media.accountId = 'another';
    await c.upload();
    expect(media.uploads, 0);
    expect(c.state.error?.code, 'cancelled');
    await c.close();
    expect(picker.photo.bytes, everyElement(0));
  });
}
