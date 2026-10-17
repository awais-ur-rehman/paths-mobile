import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../domain/encounter_repository.dart';

bool validMapStyle(String value) {
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
    required this.latitude,
    required this.longitude,
    required this.styleUrl,
    required this.onAreaSelected,
    required this.onUnavailable,
    super.key,
  });
  final List<Encounter> items;
  final double latitude, longitude;
  final String styleUrl;
  final ValueChanged<String> onAreaSelected;
  final VoidCallback onUnavailable;
  @override
  State<EncounterMap> createState() => _EncounterMapState();
}

class _EncounterMapState extends State<EncounterMap> {
  MapLibreMapController? _controller;
  Timer? _timeout;
  bool _ready = false, _failed = false;
  int _generation = 0;
  Future<void> _tail = Future.value();
  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(seconds: 12), _unavailable);
  }

  void _unavailable() {
    if (!mounted || _failed) return;
    _failed = true;
    _timeout?.cancel();
    widget.onUnavailable();
  }

  void _tap(Circle circle) {
    final area = circle.data?['areaId'];
    if (mounted && area is String) widget.onAreaSelected(area);
  }

  void _render() {
    final generation = ++_generation, items = widget.items;
    _tail = _tail
        .then((_) async {
          final controller = _controller;
          if (!mounted ||
              !_ready ||
              controller == null ||
              generation != _generation) {
            return;
          }
          await controller.clearCircles();
          final areas = <String, Encounter>{
            for (final item in items) item.coarseAreaId: item,
          };
          for (final item in areas.values) {
            if (!mounted || generation != _generation) return;
            await controller.addCircle(
              CircleOptions(
                geometry: LatLng(item.areaLatitude, item.areaLongitude),
                circleColor: '#147DCE',
                circleRadius: 14,
                circleOpacity: .75,
                circleStrokeColor: '#FFFFFF',
                circleStrokeWidth: 3,
              ),
              {'areaId': item.coarseAreaId},
            );
          }
        })
        .catchError((Object _) {
          _unavailable();
        });
  }

  @override
  void didUpdateWidget(covariant EncounterMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) _render();
  }

  @override
  void dispose() {
    _generation++;
    _timeout?.cancel();
    _controller?.onCircleTapped.remove(_tap);
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!validMapStyle(widget.styleUrl)) {
      return const Center(child: Text('Map unavailable'));
    }
    // MapLibreMap owns and disposes its controller/platform view. This wrapper owns only listeners and timeout.
    return Semantics(
      label: 'Approximate encounter areas. Profiles are also available in list view.',
      child: MapLibreMap(
        styleString: widget.styleUrl,
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.latitude, widget.longitude),
          zoom: 13,
        ),
        myLocationEnabled: false,
        myLocationTrackingMode: MyLocationTrackingMode.none,
        attributionButtonPosition: AttributionButtonPosition.bottomRight,
        onMapCreated: (controller) {
          if (!mounted) return;
          _controller = controller;
          controller.onCircleTapped.add(_tap);
        },
        onStyleLoadedCallback: () {
          if (!mounted) return;
          _ready = true;
          _timeout?.cancel();
          _render();
        },
      ),
    );
  }
}
