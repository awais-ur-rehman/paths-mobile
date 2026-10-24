import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../shared/widgets/paths_avatar.dart';
import '../../../../shared/widgets/paths_loader.dart';
import '../../domain/encounter_repository.dart';
import '../encounter_markers.dart';
import '../encounter_camera.dart';

const pathsMapStyle = 'assets/maps/paths-light.json';
String resolveMapStyle(String value) =>
    value.isEmpty || value == 'https://tiles.openfreemap.org/styles/liberty'
    ? pathsMapStyle
    : value;
bool validMapStyle(String value) {
  if (resolveMapStyle(value) == pathsMapStyle) return true;
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      !uri.hasFragment;
}

class EncounterMap extends StatefulWidget {
  const EncounterMap({
    required this.items,
    this.latitude,
    this.longitude,
    required this.styleUrl,
    this.showUserLocation = false,
    required this.onSelected,
    required this.onUnavailable,
    this.focusKey = '',
    super.key,
  });
  final List<Encounter> items;
  final double? latitude, longitude;
  final bool showUserLocation;
  final String styleUrl, focusKey;
  final ValueChanged<List<Encounter>> onSelected;
  final VoidCallback onUnavailable;
  @override
  State<EncounterMap> createState() => EncounterMapState();
}

class EncounterMapState extends State<EncounterMap> {
  MapLibreMapController? _controller;
  Timer? _timeout, _projectionTimer;
  bool _ready = false,
      _failed = false,
      _centeredOnUser = false,
      _projecting = false,
      _again = false,
      _fitPending = false,
      _historyCentered = false;
  LatLng? _userPosition;
  int _generation = 0;
  Size _size = Size.zero;
  List<List<Encounter>> _areas = const [];
  final _markers = ValueNotifier<List<EncounterMarker>>(const []);
  @override
  void initState() {
    super.initState();
    _areas = encounterAreas(widget.items);
    _timeout = Timer(const Duration(seconds: 15), _unavailable);
  }

  void _unavailable() {
    if (!mounted || _failed) return;
    _failed = true;
    _timeout?.cancel();
    widget.onUnavailable();
  }

  void _queueProjection() {
    if (!mounted || !_ready || _failed) return;
    if (_projecting) {
      _again = true;
      return;
    }
    _projectionTimer ??= Timer(const Duration(milliseconds: 32), () {
      _projectionTimer = null;
      unawaited(_project());
    });
  }

  Future<void> _project() async {
    final controller = _controller, generation = _generation, areas = _areas;
    if (!mounted || !_ready || controller == null || _size.isEmpty) return;
    _projecting = true;
    try {
      final points = await controller.toScreenLocationBatch([
        for (final area in areas)
          LatLng(area.first.areaLatitude, area.first.areaLongitude),
      ]);
      if (!mounted || generation != _generation) return;
      final ratio = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? MediaQuery.devicePixelRatioOf(context)
          : 1.0;
      _markers.value = projectEncounterMarkers(
        areas,
        points,
        pixelRatio: ratio,
        viewport: _size,
      );
    } catch (_) {
      if (mounted && generation == _generation) _unavailable();
    } finally {
      _projecting = false;
      if (_again) {
        _again = false;
        _queueProjection();
      }
    }
  }

  Future<bool> centerOnUser() async {
    final point = _userPosition, controller = _controller;
    if (!_ready ||
        point == null ||
        controller == null ||
        !widget.showUserLocation) {
      return false;
    }
    _centeredOnUser = true;
    try {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(point, 15));
      _queueProjection();
      return true;
    } catch (_) {
      _unavailable();
      return false;
    }
  }

  Future<void> showEncounters() async {
    final controller = _controller;
    if (!_ready || controller == null || _areas.isEmpty) {
      _fitPending = true;
      return;
    }
    _fitPending = false;
    try {
      final points = [
        for (final area in _areas)
          LatLng(area.first.areaLatitude, area.first.areaLongitude),
      ];
      if (points.length == 1) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 15),
        );
      } else {
        // Fit in Mercator space: Android's bounds builder loses wrapped longitudes.
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(encounterCamera(points, _size)),
        );
      }
      _queueProjection();
    } catch (_) {
      _unavailable();
    }
  }

  void _userLocation(UserLocation location) {
    if (!widget.showUserLocation ||
        DateTime.now().difference(location.timestamp).abs() >
            const Duration(minutes: 2)) {
      return;
    }
    final p = location.position;
    if (!p.latitude.isFinite ||
        !p.longitude.isFinite ||
        p.latitude.abs() > 90 ||
        p.longitude.abs() > 180) {
      return;
    }
    _userPosition = p;
    if (!_centeredOnUser) unawaited(centerOnUser());
  }

  void _dataChanged() {
    _generation++;
    _areas = encounterAreas(widget.items);
    _markers.value = const [];
    if (_fitPending && _areas.isNotEmpty) {
      unawaited(showEncounters());
    } else if (!_historyCentered && !_centeredOnUser && _areas.isNotEmpty) {
      _historyCentered = true;
      unawaited(showEncounters());
    }
    _queueProjection();
  }

  @override
  void didUpdateWidget(EncounterMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusKey != widget.focusKey) _fitPending = true;
    if (oldWidget.items != widget.items) _dataChanged();
    if (!widget.showUserLocation) {
      _userPosition = null;
      _centeredOnUser = false;
    }
  }

  @override
  void dispose() {
    _generation++;
    _timeout?.cancel();
    _projectionTimer?.cancel();
    _markers.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      if (size != _size) {
        _size = size;
        _queueProjection();
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          MapLibreMap(
            styleString: resolveMapStyle(widget.styleUrl),
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.latitude ?? 0, widget.longitude ?? 0),
              zoom: widget.latitude == null || widget.longitude == null
                  ? 2
                  : 13,
            ),
            annotationOrder: const [],
            compassEnabled: false,
            tiltGesturesEnabled: false,
            rotateGesturesEnabled: false,
            trackCameraPosition: true,
            myLocationEnabled: widget.showUserLocation,
            myLocationTrackingMode: MyLocationTrackingMode.none,
            onUserLocationUpdated: _userLocation,
            attributionButtonPosition: AttributionButtonPosition.bottomLeft,
            attributionButtonMargins: math.Point(
              12,
              MediaQuery.paddingOf(context).bottom + 12,
            ),
            onCameraMove: (_) => _queueProjection(),
            onCameraIdle: _queueProjection,
            onMapCreated: (controller) {
              if (mounted) _controller = controller;
            },
            onStyleLoadedCallback: () {
              if (!mounted) return;
              setState(() => _ready = true);
              _timeout?.cancel();
              if (!_centeredOnUser && _userPosition != null) {
                unawaited(centerOnUser());
              }
              if (_fitPending) unawaited(showEncounters());
              _queueProjection();
            },
          ),
          ValueListenableBuilder<List<EncounterMarker>>(
            valueListenable: _markers,
            builder: (context, markers, _) => Stack(
              children: [
                for (final marker in markers)
                  Positioned(
                    left: marker.position.dx - 30,
                    top: marker.position.dy - 62,
                    child: EncounterMapMarker(
                      items: marker.items,
                      onTap: () => widget.onSelected(marker.items),
                    ),
                  ),
              ],
            ),
          ),
          if (!_ready) const IgnorePointer(child: Center(child: PathsLoader())),
        ],
      );
    },
  );
}

class EncounterMapMarker extends StatelessWidget {
  const EncounterMapMarker({
    required this.items,
    required this.onTap,
    super.key,
  });
  final List<Encounter> items;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: items.length == 1
        ? 'Open ${items.first.displayName}, crossed path.'
        : '${items.length} crossed paths. Open profiles.',
    child: ExcludeSemantics(
      child: SizedBox(
        width: 60,
        height: 68,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  bottom: 5,
                  child: Transform.rotate(
                    angle: math.pi / 4,
                    child: Container(
                      width: 15,
                      height: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: IgnorePointer(
                    child: PathsAvatar(
                      size: 48,
                      assetId: items.first.avatarAssetId,
                    ),
                  ),
                ),
                if (items.length > 1)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B5AA1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
