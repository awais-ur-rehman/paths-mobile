import '../../auth/domain/auth_models.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/location_tracker.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../../auth/presentation/auth_widgets.dart';
import '../data/location_sync_service.dart';
import 'location_cubit.dart';

class LocationSetupScreen extends StatelessWidget {
  const LocationSetupScreen({required this.sync, this.onContinue, super.key});
  final Future<void> Function()? onContinue;
  final LocationSyncService sync;
  @override
  Widget build(BuildContext context) =>
      _LocationOwner(sync: sync, onContinue: onContinue);
}

class _LocationOwner extends StatefulWidget {
  const _LocationOwner({required this.sync, this.onContinue});
  final Future<void> Function()? onContinue;
  final LocationSyncService sync;
  @override
  State<_LocationOwner> createState() => _LocationOwnerState();
}

class _LocationOwnerState extends State<_LocationOwner> {
  late final cubit = LocationCubit(widget.sync);
  AppLifecycleListener? lifecycle;
  bool continuing = false;
  Future<void> _continue() async {
    if (continuing) return;
    if (widget.onContinue == null) {
      context.go('/profile');
      return;
    }
    setState(() => continuing = true);
    try {
      await widget.onContinue!();
    } catch (error) {
      if (mounted) {
        PathsToast.show(
          context,
          (error is AuthFailure ? error : const AuthFailure('storage')).message,
        );
      }
    } finally {
      if (mounted) setState(() => continuing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(cubit.initialize());
    lifecycle = AppLifecycleListener(
      onResume: () => unawaited(cubit.refresh()),
    );
  }

  @override
  void dispose() {
    lifecycle?.dispose();
    unawaited(cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: cubit,
    child: BlocListener<LocationCubit, LocationState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) =>
          PathsToast.show(context, state.error!.message),
      child: AuthScaffold(
        title: 'Location',
        subtitle:
            'Find people you cross paths with. Others see approximate areas.',
        onBack: _continue,
        child: BlocBuilder<LocationCubit, LocationState>(
          builder: (context, state) {
            final permissions = state.permissions;
            final sharing =
                !state.pendingStop &&
                [
                  TrackingStatus.active,
                  TrackingStatus.background,
                  TrackingStatus.inaccurate,
                  TrackingStatus.offline,
                ].contains(state.status);
            final settings =
                permissions?.servicesEnabled == false ||
                permissions?.precise == false && permissions?.granted == true ||
                permissions?.granted == false &&
                    permissions?.canRequestForeground == false;
            final label = state.pendingStop
                ? 'Paused · waiting to sync'
                : permissions?.servicesEnabled == false
                ? 'Device location is off'
                : permissions?.granted == true && permissions?.precise == false
                ? 'Approximate location'
                : sharing
                ? (permissions?.backgroundEnabled == true
                      ? 'Background sharing on'
                      : 'Sharing while using Paths')
                : 'Sharing paused';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                if (state.status == TrackingStatus.inaccurate &&
                    permissions?.precise == true) ...[
                  const SizedBox(height: 8),
                  const Text('Waiting for a clearer GPS signal.'),
                ],
                if (state.status == TrackingStatus.offline) ...[
                  const SizedBox(height: 8),
                  const Text('Offline · updates will retry.'),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: state.busy
                      ? null
                      : sharing
                      ? cubit.pause
                      : () => cubit.enable(false),
                  child: state.busy
                      ? const PathsLoader(size: 28, color: Colors.white)
                      : Text(sharing ? 'Pause sharing' : 'Enable location'),
                ),
                if (permissions?.granted == true) ...[
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Background sharing'),
                    subtitle: const Text(
                      'Keep finding paths when you leave the app. Uses more battery.',
                    ),
                    value: sharing && permissions?.backgroundEnabled == true,
                    onChanged: state.busy ? null : cubit.enable,
                  ),
                ],
                if (settings)
                  TextButton(
                    onPressed: state.busy ? null : cubit.openSettings,
                    child: const Text('Open device settings'),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: continuing || state.busy ? null : _continue,
                  child: continuing
                      ? const PathsLoader(size: 24)
                      : Text(widget.onContinue == null ? 'Done' : 'Continue'),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
