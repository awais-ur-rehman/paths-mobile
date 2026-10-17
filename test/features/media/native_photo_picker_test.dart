import 'dart:io';

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
