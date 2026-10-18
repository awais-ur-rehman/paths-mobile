import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';

import 'package:paths_mobile/features/media/data/native_picker_cleanup.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paths_mobile/features/media/data/native_photo_picker.dart';
import 'package:paths_mobile/features/media/domain/media_repository.dart';

class Plugin extends ImagePicker {
  Plugin(this.file, {this.onPick});
  final Future<void> Function()? onPick;
  final XFile? file;
  int? quality;
  @override
  Future<LostDataResponse> retrieveLostData() async => LostDataResponse.empty();
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    await onPick?.call();
    quality = imageQuality;
    expect(maxWidth, isNull);
    expect(maxHeight, isNull);
    return file;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('paths/media'),
          (_) async => Directory.systemTemp.path,
        );
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('paths/media'), null);
  });
  test('Android picker cleans its native image cache when Flutter temp is a sibling code cache', () async {
    final sandbox = await Directory.systemTemp.createTemp('paths-cache-roots-');
    final images = await Directory('${sandbox.path}/cache').create();
    final code = await Directory('${sandbox.path}/code_cache').create();
    final file = File('${images.path}/selected.jpg');
    const channel = MethodChannel('paths/media');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'cacheDirectory');
          return images.path;
        });
    try {
      await file.writeAsBytes([255, 216, 255, 1]);
      await IOOverrides.runZoned(() async {
        final picked = await NativePhotoPicker(picker: Plugin(XFile(file.path)))
            .pick(PhotoSource.gallery);
        expect(picked!.bytes, [255, 216, 255, 1]);
        expect(await file.exists(), false);
        picked.clear();
      }, getSystemTempDirectory: () => code);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await sandbox.delete(recursive: true);
    }
  });
  test('native cache confinement preserves originals outside cache and symlink targets', () async {
    final sandbox = await Directory.systemTemp.createTemp(
      'paths-cache-confinement-',
    );
    final cache = await Directory('${sandbox.path}/cache').create();
    final original = await File('${sandbox.path}/original.jpg')
        .writeAsBytes([255, 216, 255, 1]);
    final link = await Link('${cache.path}/selected.jpg').create(original.path);
    const channel = MethodChannel('paths/media');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => cache.path);
    try {
      for (final path in [original.path, link.path]) {
        await expectLater(
          NativePhotoPicker(picker: Plugin(XFile(path)))
              .pick(PhotoSource.gallery),
          throwsA(
            isA<AuthFailure>().having(
              (error) => error.code,
              'code',
              'media_cleanup',
            ),
          ),
        );
        expect(await original.readAsBytes(), [255, 216, 255, 1]);
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await sandbox.delete(recursive: true);
    }
  });
  test(
    'camera cancellation cleans unreturned files from the native image cache',
    () async {
      final cache = await Directory.systemTemp.createTemp(
        'paths-camera-cancel-',
      );
      final file = File(
        '${cache.path}/11111111-1111-4111-8111-111111111111987654.jpg',
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('paths/media'),
            (_) async => cache.path,
          );
      try {
        expect(
          await NativePhotoPicker(
            picker: Plugin(
              null,
              onPick: () async {
                await file.writeAsBytes([255, 216, 255, 1]);
              },
            ),
          ).pick(PhotoSource.camera),
          isNull,
        );
        expect(await file.exists(), false);
      } finally {
        await cache.delete(recursive: true);
      }
    },
  );
  test('unreturned Android camera files are removed without following links or deleting other cache files', () async {
    final root = await Directory.systemTemp.createTemp('paths-camera-cleanup-');
    const name = '11111111-1111-4111-8111-111111111111123456.jpg';
    final file = File('${root.path}/$name'),
        other = File('${root.path}/other.jpg'),
        link = Link('${root.path}/22222222-2222-4222-8222-222222222222456.jpg');
    try {
      await file.writeAsBytes([1, 2, 3]);
      await other.writeAsBytes([4, 5, 6]);
      await link.create(other.path);
      await discardAndroidCameraFiles(root);
      expect(await file.exists(), false);
      expect(await other.readAsBytes(), [4, 5, 6]);
      expect(await link.exists(), true);
      await discardAndroidCameraFiles(root);
    } finally {
      await root.delete(recursive: true);
    }
  });
  test('picker avoids native compression copies and deletes its sole staged file before returning bytes', () async {
    final folder = await Directory.systemTemp.createTemp(
          'paths-native-picker-test-',
        ),
        file = File('${folder.path}/selected.jpg');
    try {
      await file.writeAsBytes([255, 216, 255, 1]);
      final plugin = Plugin(XFile(file.path)),
          picker = NativePhotoPicker(picker: plugin);
      final photo = await picker.pick(PhotoSource.gallery);
      expect(plugin.quality, 100);
      expect(await file.exists(), false);
      expect(photo!.bytes, [255, 216, 255, 1]);
      photo.clear();
    } finally {
      await folder.delete(recursive: true);
    }
  });
}
