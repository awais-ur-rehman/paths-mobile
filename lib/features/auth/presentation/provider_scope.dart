import 'package:flutter/widgets.dart';

import '../../../core/network/generated/api_contract.dart';
import '../domain/provider_auth.dart';

class ProviderAuthScope extends InheritedWidget {
  const ProviderAuthScope({
    required this.repository,
    required this.sdk,
    required this.linkOffer,
    required super.child,
    super.key,
  });
  final ProviderAuthRepository? repository;
  final ProviderSdk sdk;
  final ValueNotifier<ProviderSetupDto?> linkOffer;
  static ProviderAuthScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProviderAuthScope>();
  @override
  bool updateShouldNotify(ProviderAuthScope oldWidget) =>
      repository != oldWidget.repository || sdk != oldWidget.sdk;
}
