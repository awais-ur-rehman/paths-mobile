import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'paths_brand.dart';

/// The two original Paths curves are drawn as vectors, with a traveller on each.
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
            painter: _CrossingPainter(
              controller,
              widget.color ?? const Color(0xFF147DCE),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CrossingPainter extends CustomPainter {
  _CrossingPainter(this.progress, this.color) : super(repaint: progress);
  final Animation<double> progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 128, size.height / 128);
    final curves = createPathsCurves();
    final base = Paint()
      ..color = color.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < curves.length; i++) {
      canvas.drawPath(curves[i], base);
      final metric = curves[i].computeMetrics().first;
      final t = (progress.value + i * .5) % 1;
      final trailStart = math.max(0.0, t - .2);
      canvas.drawPath(
        metric.extractPath(metric.length * trailStart, metric.length * t),
        base..color = color,
      );
      base.color = color.withValues(alpha: .22);
      final position = metric.getTangentForOffset(metric.length * t)!.position;
      canvas.drawCircle(position, 7, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _CrossingPainter old) =>
      old.color != color || old.progress != progress;
}
