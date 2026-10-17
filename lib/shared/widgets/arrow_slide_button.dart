import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'paths_loader.dart';

class ArrowSlideButton extends StatefulWidget {
  const ArrowSlideButton({
    required this.onContinue,
    this.busy = false,
    super.key,
  });
  final Future<void> Function() onContinue;
  final bool busy;
  @override
  State<ArrowSlideButton> createState() => _ArrowSlideButtonState();
}

class _ArrowSlideButtonState extends State<ArrowSlideButton>
    with SingleTickerProviderStateMixin {
  late final motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  bool running = false;
  Future<void> _continue() async {
    if (running || widget.busy) return;
    setState(() => running = true);
    try {
      if (!MediaQuery.disableAnimationsOf(context)) {
        await motion.forward().orCancel;
      }
      if (!mounted) return;
      await widget.onContinue();
    } on TickerCanceled {
      // Route disposal owns cancellation of the arrow's ticker.
    } finally {
      if (mounted) {
        motion.reset();
        setState(() => running = false);
      }
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Get started',
    enabled: !running && !widget.busy,
    onTap: running || widget.busy ? null : _continue,
    excludeSemantics: true,
    child: SizedBox(
      height: math.max(
        62.0,
        MediaQuery.textScalerOf(context).scale(16) * 2 + 20,
      ),
      child: Material(
        color: const Color(0xFF050708),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: running || widget.busy ? null : _continue,
          borderRadius: BorderRadius.circular(999),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = math.max(
                62.0,
                MediaQuery.textScalerOf(context).scale(16) * 2 + 20,
              );
              return SizedBox(
                width: constraints.maxWidth,
                height: height,
                child: AnimatedBuilder(
                  animation: motion,
                  builder: (context, _) {
                    final progress = Curves.easeInOutCubic.transform(
                      motion.value,
                    );
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 60),
                          child: Opacity(
                            opacity: 1 - progress,
                            child: const Text(
                              'Get started',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 6 + (constraints.maxWidth - 62) * progress,
                          top: (height - 50) / 2,
                          child: Container(
                            key: const ValueKey('onboarding-arrow'),
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: widget.busy
                                ? const Center(child: PathsLoader(size: 32))
                                : const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Color(0xFF101418),
                                    size: 24,
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
