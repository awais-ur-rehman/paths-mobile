import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'paths_brand.dart';

/// The approved Open P route, with a traveller following its open contour.
class PathsLoader extends StatefulWidget {
  const PathsLoader({this.size = 40, this.color, super.key});
  final double size;
  final Color? color;
  @override
  State<PathsLoader> createState() => _PathsLoaderState();
}

class _PathsLoaderState extends State<PathsLoader>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool reduced = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      controller.stop();
      controller.value = .35;
    } else {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading',
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(
            painter: _RoutePainter(
              controller,
              widget.color ?? const Color(0xFF101418),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.progress, this.color) : super(repaint: progress);
  final Animation<double> progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 256, size.height / 256);
    final curve = createPathsRoute();
    final base = Paint()
      ..color = color.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(curve, base);
    final metric = curve.computeMetrics().first;
    final t = progress.value;
    final trailStart = math.max(0.0, t - .2);
    canvas.drawPath(
      metric.extractPath(metric.length * trailStart, metric.length * t),
      base..color = color,
    );
    final position = metric.getTangentForOffset(metric.length * t)!.position;
    canvas.drawCircle(position, 12, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) =>
      old.color != color || old.progress != progress;
}
