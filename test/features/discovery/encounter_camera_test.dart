import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:paths_mobile/features/discovery/presentation/encounter_camera.dart';

void main() {
  test('date-line neighbors fit locally using a camera, not native bounds', () {
    final camera = encounterCamera(const [
      LatLng(10, 179),
      LatLng(11, -179),
    ], const Size(390, 844));
    expect(camera.target.longitude.abs(), closeTo(180, .001));
    expect(camera.target.latitude, closeTo(10.5, .1));
    expect(camera.zoom, inExclusiveRange(5, 8));
    expect(camera.bearing, 0);
    expect(camera.tilt, 0);
  });
  test('duplicate points and poles produce finite bounded cameras', () {
    for (final points in [
      const [LatLng(90, 0), LatLng(-90, 0)],
      const [LatLng(33, 73), LatLng(33, 73)],
    ]) {
      final camera = encounterCamera(points, const Size(320, 600));
      expect(camera.zoom.isFinite, isTrue);
      expect(camera.zoom, inInclusiveRange(0, 15));
      expect(camera.target.latitude.isFinite, isTrue);
    }
  });
}
