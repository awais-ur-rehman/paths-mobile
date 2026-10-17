import 'dart:io';

import 'package:paths_mobile/features/media/data/native_picker_cleanup.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paths_mobile/features/media/data/native_photo_picker.dart';
import 'package:paths_mobile/features/media/domain/media_repository.dart';

class Plugin extends ImagePicker {
  Plugin(this.file);
  final XFile file;
  int? quality;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    quality = imageQuality;
    expect(maxWidth, isNull);
    expect(maxHeight, isNull);
    return file;
  }
}

void main() {
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
