import 'dart:math';

import 'package:flutter/widgets.dart';

import '../domain/encounter_repository.dart';

List<List<Encounter>> encounterAreas(List<Encounter> items) {
  final areas = <String, List<Encounter>>{};
  for (final item in items) {
    if (!item.areaLatitude.isFinite ||
        !item.areaLongitude.isFinite ||
        item.areaLatitude.abs() > 90 ||
        item.areaLongitude.abs() > 180) {
      continue;
    }
    (areas[item.coarseAreaId] ??= []).add(item);
  }
  return [for (final items in areas.values) List.unmodifiable(items)];
}

final class EncounterMarker {
  EncounterMarker(this.position, List<Encounter> items)
    : items = List.unmodifiable(items);
  final Offset position;
  final List<Encounter> items;
}

List<EncounterMarker> projectEncounterMarkers(
  List<List<Encounter>> areas,
  List<Point> points, {
  required double pixelRatio,
  required Size viewport,
}) {
  if (areas.length != points.length ||
      !pixelRatio.isFinite ||
      pixelRatio <= 0) {
    throw ArgumentError('Invalid map projection');
  }
  const spacing = 64.0;
  final positions = <Offset>[],
      groups = <List<Encounter>>[],
      cells = <(int, int), List<int>>{};
  for (var i = 0; i < areas.length; i++) {
    final p = Offset(points[i].x / pixelRatio, points[i].y / pixelRatio);
    if (!p.dx.isFinite ||
        !p.dy.isFinite ||
        p.dx < -32 ||
        p.dy < -32 ||
        p.dx > viewport.width + 32 ||
        p.dy > viewport.height + 32) {
      continue;
    }
    final x = (p.dx / spacing).floor(), y = (p.dy / spacing).floor();
    int? found;
    for (var dx = -1; dx <= 1 && found == null; dx++) {
      for (var dy = -1; dy <= 1 && found == null; dy++) {
        for (final index in cells[(x + dx, y + dy)] ?? const <int>[]) {
          if ((positions[index] - p).distance < spacing) {
            found = index;
            break;
          }
        }
      }
    }
    if (found != null) {
      groups[found].addAll(areas[i]);
    } else {
      (cells[(x, y)] ??= []).add(positions.length);
      positions.add(p);
      groups.add([...areas[i]]);
    }
  }
  return [
    for (var i = 0; i < positions.length; i++)
      EncounterMarker(positions[i], groups[i]),
  ];
}
