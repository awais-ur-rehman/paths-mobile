import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Fits the shortest longitude arc without relying on native bounds conversion.
CameraPosition encounterCamera(List<LatLng> points, Size viewport) {
  if (points.isEmpty) throw ArgumentError('At least one encounter is required');
  final longitudes = points.map((p) => p.longitude).toList()..sort();
  var gap = -1.0, start = 0;
  for (var i = 0; i < longitudes.length; i++) {
    final width =
        (i + 1 < longitudes.length
            ? longitudes[i + 1]
            : longitudes.first + 360) -
        longitudes[i];
    if (width > gap) {
      gap = width;
      start = (i + 1) % longitudes.length;
    }
  }
  final west = longitudes[start];
  final span = 360 - gap;
  double mercator(double latitude) {
    final sine = math.sin(
      latitude.clamp(-85.05112878, 85.05112878) * math.pi / 180,
    );
    return .5 - math.log((1 + sine) / (1 - sine)) / (4 * math.pi);
  }

  final ys = points.map((p) => mercator(p.latitude)).toList()..sort();
  final width = math.max(1.0, viewport.width - 144);
  final height = math.max(1.0, viewport.height - 400);
  // MapLibre's world is 512 logical pixels at zoom zero. Symmetric conservative
  // padding keeps markers below the search controls and above navigation.
  double zoomFor(double available, double fraction) =>
      fraction <= 0 ? 15 : math.log(available / (512 * fraction)) / math.ln2;
  final zoom = math
      .min(zoomFor(width, span / 360), zoomFor(height, ys.last - ys.first))
      .clamp(0.0, 15.0);
  final centerY = (ys.first + ys.last) / 2;
  final mercatorY = math.pi * (1 - 2 * centerY);
  final latitude =
      math.atan((math.exp(mercatorY) - math.exp(-mercatorY)) / 2) *
      180 /
      math.pi;
  final longitude = (west + span / 2 + 180) % 360 - 180;
  return CameraPosition(target: LatLng(latitude, longitude), zoom: zoom);
}
