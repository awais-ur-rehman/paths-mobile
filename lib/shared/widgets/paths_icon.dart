import 'package:flutter/material.dart';

import 'generated/paths_icon_geometry.dart';
export 'generated/paths_icon_geometry.dart' show PathsIconName;

/// Original rounded-stroke family, compiled from editable SVG masters.
class PathsIcon extends StatelessWidget {
  const PathsIcon(this.name, {this.size = 28, this.color, super.key});
  final PathsIconName name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _IconPainter(name, color ?? IconTheme.of(context).color!),
      ),
    ),
  );
}

class _IconPainter extends CustomPainter {
  const _IconPainter(this.name, this.color);
  final PathsIconName name;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      pathsIconGeometry[name]!,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = pathsIconStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.name != name || old.color != color;
}
