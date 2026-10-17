import 'dart:io';

// image_picker_android creates camera files with UUID + Java's random decimal
// suffix in the app cache, including when camera cancellation returns no XFile.
// Match that exact plugin-owned name; leave other cache files and links alone.
Future<void> discardAndroidCameraFiles(Directory cache) async {
  final cameraName = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[0-9]+\.jpg$',
  );
  await for (final entry in cache.list(followLinks: false)) {
    if (entry is File && cameraName.hasMatch(entry.uri.pathSegments.last)) {
      await entry.delete();
    }
  }
}
