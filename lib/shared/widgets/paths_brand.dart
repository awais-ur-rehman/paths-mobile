import 'package:flutter/material.dart';

// Geometry matches the editable Paths SVG sources in assets/brand.
List<Path> createPathsCurves() => [
  Path()
    ..moveTo(32, 96)
    ..cubicTo(32, 58, 96, 70, 96, 32),
  Path()
    ..moveTo(32, 32)
    ..cubicTo(32, 70, 96, 58, 96, 96),
];

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
      height: width * 128 / 408,
      child: CustomPaint(painter: _BrandPainter(color, true)),
    ),
  );
}

class PathsSymbol extends StatelessWidget {
  const PathsSymbol({
    this.size = 72,
    this.color = const Color(0xFF147DCE),
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
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / (wordmark ? 408 : 128), size.height / 128);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final curve in createPathsCurves()) {
      canvas.drawPath(curve, stroke);
    }
    if (wordmark) {
      final letters = Path()
        ..moveTo(155, 86)
        ..lineTo(155, 42)
        ..lineTo(173, 42)
        ..cubicTo(198, 42, 198, 66, 173, 66)
        ..lineTo(155, 66)
        ..moveTo(211, 86)
        ..lineTo(227, 42)
        ..lineTo(243, 86)
        ..moveTo(217, 72)
        ..lineTo(237, 72)
        ..moveTo(255, 42)
        ..lineTo(287, 42)
        ..moveTo(271, 42)
        ..lineTo(271, 86)
        ..moveTo(300, 42)
        ..lineTo(300, 86)
        ..moveTo(332, 42)
        ..lineTo(332, 86)
        ..moveTo(300, 64)
        ..lineTo(332, 64)
        ..moveTo(376, 47)
        ..cubicTo(352, 32, 341, 59, 363, 64)
        ..cubicTo(389, 71, 376, 96, 349, 82);
      canvas.drawPath(letters, stroke..strokeWidth = 6);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrandPainter old) =>
      old.color != color || old.wordmark != wordmark;
}
