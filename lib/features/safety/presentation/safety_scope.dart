import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/safety_repository.dart';

class SafetyScope extends InheritedWidget {
  const SafetyScope({
    required this.repository,
    required super.child,
    super.key,
  });
  final SafetyRepository? repository;
  static SafetyRepository? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SafetyScope>()?.repository;
  @override
  bool updateShouldNotify(SafetyScope old) => repository != old.repository;
}

/// Revalidates mounted views after access changes, and owns the subscription.
class SafetyRefresh extends StatefulWidget {
  const SafetyRefresh({
    required this.onChanged,
    required this.child,
    super.key,
  });
  final VoidCallback onChanged;
  final Widget child;
  @override
  State<SafetyRefresh> createState() => _SafetyRefreshState();
}

class _SafetyRefreshState extends State<SafetyRefresh> {
  SafetyRepository? observed;
  late final AppLifecycleListener lifecycle;
  @override
  void initState() {
    super.initState();
    lifecycle = AppLifecycleListener(
      onResume: () {
        if (mounted) widget.onChanged();
      },
    );
  }

  StreamSubscription<void>? subscription;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = SafetyScope.maybeOf(context);
    if (current != observed) {
      unawaited(subscription?.cancel());
      observed = current;
      subscription = current?.changes.listen((_) {
        if (mounted) widget.onChanged();
      });
    }
  }

  @override
  void dispose() {
    lifecycle.dispose();
    unawaited(subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
