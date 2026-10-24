import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

// Only the native renderer boundary is replaced. Map/Home state is real.
class TestMapPlatform extends MapLibrePlatform {
  bool created = false, disposed = false;
  double density = 1;
  final cameraUpdates = <CameraUpdate>[];
  @override
  Future<void> initPlatform(int id) async {
    scheduleMicrotask(() => onMapStyleLoadedPlatform(null));
  }

  @override
  Widget buildView(
    Map<String, dynamic> params,
    OnPlatformViewCreatedCallback ready,
    Set<Factory<OneSequenceGestureRecognizer>>? recognizers,
  ) {
    if (!created) {
      created = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!disposed) ready(1);
      });
    }
    return Builder(
      builder: (context) {
        density = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? MediaQuery.devicePixelRatioOf(context)
            : 1;
        return const CustomPaint(
          painter: MapFixturePainter(),
          size: Size.infinite,
        );
      },
    );
  }

  @override
  Future<List<Point>> toScreenLocationBatch(Iterable<LatLng> points) async => [
    for (var i = 0; i < points.length; i++)
      Point((100 + (i % 3) * 85) * density, (270 + (i ~/ 3) * 100) * density),
  ];
  @override
  Future<CameraPosition?> updateMapOptions(
    Map<String, dynamic> options,
  ) async => null;
  @override
  Future<bool?> animateCamera(CameraUpdate update, {Duration? duration}) async {
    cameraUpdates.add(update);
    return true;
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MapFixturePainter extends CustomPainter {
  const MapFixturePainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFF5F5F3), BlendMode.src);
    final blocks = Paint()..color = const Color(0xFFE1E3E3);
    for (var x = -80.0; x < size.width + 100; x += 108) {
      for (var y = 90.0; y < size.height; y += 116) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 85, 90),
            const Radius.circular(3),
          ),
          blocks,
        );
      }
    }
    canvas.drawOval(
      Rect.fromLTWH(-70, 0, 190, 215),
      Paint()..color = const Color(0xFFBBD87D),
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width - 45, 230, 90, 115),
      Paint()..color = const Color(0xFFBBD87D),
    );
    final water = Path()
      ..moveTo(0, size.height * .73)
      ..lineTo(size.width, size.height * .65)
      ..lineTo(size.width, size.height * .75)
      ..lineTo(0, size.height * .83)
      ..close();
    canvas.drawPath(water, Paint()..color = const Color(0xFF7BCED5));
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 13;
    canvas.drawLine(
      Offset(size.width * .45, 0),
      Offset(size.width * .63, size.height),
      road,
    );
    for (var y = 210.0; y < size.height; y += 205) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 110), road);
    }
  }

  @override
  bool shouldRepaint(MapFixturePainter old) => false;
}
