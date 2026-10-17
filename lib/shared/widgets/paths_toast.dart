import 'dart:async';

import 'package:flutter/material.dart';

enum ToastTone { success, error }

class PathsToast {
  static void show(
    BuildContext context,
    String message, {
    ToastTone tone = ToastTone.error,
  }) {
    final scope = context.getInheritedWidgetOfExactType<_ToastScope>();
    if (scope == null) throw StateError('PathsToastHost is required');
    scope.controller.show(
      message,
      tone,
      persistent: MediaQuery.accessibleNavigationOf(context),
    );
  }
}

class _Message {
  const _Message(this.id, this.text, this.tone);
  final int id;
  final String text;
  final ToastTone tone;
}

class _ToastController extends ChangeNotifier {
  _Message? message;
  Timer? timer;
  int serial = 0;
  void show(String text, ToastTone tone, {required bool persistent}) {
    timer?.cancel();
    final id = ++serial;
    message = _Message(id, text, tone);
    if (!persistent) {
      timer = Timer(const Duration(seconds: 6), () => dismiss(id));
    }
    notifyListeners();
  }

  void dismiss(int id) {
    if (message?.id != id) return;
    timer?.cancel();
    message = null;
    notifyListeners();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

class _ToastScope extends InheritedWidget {
  const _ToastScope({required this.controller, required super.child});
  final _ToastController controller;
  @override
  bool updateShouldNotify(_ToastScope oldWidget) =>
      controller != oldWidget.controller;
}

class PathsToastHost extends StatefulWidget {
  const PathsToastHost({required this.child, super.key});
  final Widget child;
  @override
  State<PathsToastHost> createState() => _PathsToastHostState();
}

class _PathsToastHostState extends State<PathsToastHost> {
  final controller = _ToastController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ToastScope(
    controller: controller,
    child: ListenableBuilder(
      listenable: controller,
      child: widget.child,
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          child!,
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: AnimatedSwitcher(
                    duration: Duration(
                      milliseconds: MediaQuery.disableAnimationsOf(context)
                          ? 0
                          : 240,
                    ),
                    transitionBuilder: (child, animation) => SlideTransition(
                      position:
                          Tween(
                            begin: const Offset(1.1, -.15),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: switch (controller.message) {
                      final message? => _ToastCard(
                        key: ValueKey(message.id),
                        message: message,
                        dismiss: () => controller.dismiss(message.id),
                      ),
                      null => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.message, required this.dismiss, super.key});
  final _Message message;
  final VoidCallback dismiss;
  @override
  Widget build(BuildContext context) {
    final error = message.tone == ToastTone.error;
    final color = error ? const Color(0xFF9E3027) : const Color(0xFF176B4D);
    return Dismissible(
      key: ValueKey('toast-${message.id}'),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => dismiss(),
      child: Semantics(
        liveRegion: true,
        hint: 'Swipe right to dismiss',
        child: Material(
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: .12),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: color.withValues(alpha: .24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 12, 16),
                child: Icon(
                  error
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: color,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF101418),
                    ),
                  ),
                ),
              ),
              Semantics(
                container: true,
                label: 'Dismiss notification',
                button: true,
                child: IconButton(
                  onPressed: dismiss,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
