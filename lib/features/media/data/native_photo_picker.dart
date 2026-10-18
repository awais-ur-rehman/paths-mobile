import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/domain/auth_models.dart';
import '../domain/media_repository.dart';
import 'native_picker_cleanup.dart';

final class NativePhotoPicker implements PhotoPicker {
  NativePhotoPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  bool _recovered = false;
  Future<Directory> _cacheDirectory() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return Directory.systemTemp;
    }
    // Flutter's systemTemp uses code_cache; image_picker uses Context.cacheDir.
    final path = await const MethodChannel('paths/media')
        .invokeMethod<String>('cacheDirectory');
    if (path == null || !Directory(path).isAbsolute) {
      throw const AuthFailure('media_cleanup');
    }
    return Directory(path);
  }

  Future<void> _discard(XFile file) async {
    final root = await (await _cacheDirectory()).resolveSymbolicLinks();
    final candidate = File(file.path);
    if (!await candidate.exists()) return;
    final path = await candidate.resolveSymbolicLinks();
    // Plugin-owned cache files only; never delete a gallery original or follow a link outside cache.
    if (!path.startsWith('$root${Platform.pathSeparator}')) {
      throw const AuthFailure('media_cleanup');
    }
    await File(path).delete();
  }

  @override
  Future<void> discardLostSelection() async {
    if (_recovered) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await discardAndroidCameraFiles(await _cacheDirectory());
      final lost = await _picker.retrieveLostData();
      for (final file in lost.files ?? <XFile>[]) {
        await _discard(file);
      }
    }
    await _discardIOSFiles();
    _recovered = true;
  }

  Future<void> _discardIOSFiles() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await for (final entity in Directory.systemTemp.list(
        followLinks: false,
      )) {
        if (entity is File &&
            entity.uri.pathSegments.last.startsWith('image_picker_')) {
          await _discard(XFile(entity.path));
        }
      }
    }
  }

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    try {
      await discardLostSelection();
      PickedPhoto? selected;
      try {
        final file = await _picker.pickImage(
          source: source == PhotoSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          // Android otherwise leaves an unreturned original beside its compressed copy.
          // The server owns resizing and metadata removal.
          imageQuality: 100,
          requestFullMetadata: false,
        );
        if (file == null) return null;
        try {
          final size = await file.length();
          if (size <= 0 || size > 10 * 1024 * 1024) {
            throw const AuthFailure('image_size');
          }
          final bytes = await file.readAsBytes();
          final jpeg =
              bytes.length >= 3 &&
              bytes[0] == 255 &&
              bytes[1] == 216 &&
              bytes[2] == 255;
          final png =
              bytes.length >= 8 &&
              bytes[0] == 137 &&
              bytes[1] == 80 &&
              bytes[2] == 78 &&
              bytes[3] == 71;
          final webp =
              bytes.length >= 12 &&
              String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
              String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
          if (!jpeg && !png && !webp) {
            bytes.fillRange(0, bytes.length, 0);
            throw const AuthFailure('image_format');
          }
          return selected = PickedPhoto(
            bytes,
            jpeg
                ? 'image/jpeg'
                : png
                ? 'image/png'
                : 'image/webp',
          );
        } finally {
          try {
            await _discard(file);
            await _discardIOSFiles();
          } catch (_) {
            selected?.clear();
            rethrow;
          }
        }
      } finally {
        if (defaultTargetPlatform == TargetPlatform.android) {
          try {
            await discardAndroidCameraFiles(await _cacheDirectory());
          } catch (_) {
            selected?.clear();
            throw const AuthFailure('media_cleanup');
          }
        }
      }
    } on AuthFailure {
      rethrow;
    } on PlatformException catch (error) {
      if (error.code == 'media_cleanup') {
        throw const AuthFailure('media_cleanup');
      }
      throw AuthFailure(
        error.code.contains('denied') || error.code.contains('restricted')
            ? 'photo_permission'
            : 'photo_unavailable',
      );
    } catch (_) {
      throw const AuthFailure('photo_unavailable');
    }
  }
}
