import 'package:flutter/material.dart';

import 'generated/paths_geometry.dart';
export 'generated/paths_geometry.dart' show createPathsRoute;

class PathsWordmark extends StatelessWidget {
  const PathsWordmark({
    this.width = 140,
    this.color = const Color(0xFF101418),
    super.key,
  });
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Paths',
    child: SizedBox(
      width: width,
      height: width * 256 / 650,
      child: CustomPaint(painter: _BrandPainter(color, true)),
    ),
  );
}

class PathsSymbol extends StatelessWidget {
  const PathsSymbol({
    this.size = 72,
    this.color = const Color(0xFF101418),
    super.key,
  });
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Paths',
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _BrandPainter(color, false)),
    ),
  );
}

class _BrandPainter extends CustomPainter {
  const _BrandPainter(this.color, this.wordmark);
  final Color color;
  final bool wordmark;
  static final _route = createPathsRoute();
  static final _lettering = createPathsLettering();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / (wordmark ? 650 : 256), size.height / 256);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = pathsSymbolStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    if (wordmark) {
      canvas.translate(pathsSymbolOffset.dx, pathsSymbolOffset.dy);
      canvas.scale(pathsSymbolScale);
    }
    canvas.drawPath(_route, stroke);
    canvas.restore();
    if (wordmark) {
      canvas.translate(pathsWordmarkOffset.dx, pathsWordmarkOffset.dy);
      canvas.scale(pathsWordmarkScale);
      canvas.drawPath(_lettering, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrandPainter old) =>
      old.color != color || old.wordmark != wordmark;
}
