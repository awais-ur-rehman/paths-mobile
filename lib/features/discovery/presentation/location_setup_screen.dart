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
  const LocationSetupScreen({required this.sync, super.key});
  final LocationSyncService sync;
  @override
  Widget build(BuildContext context) => _LocationOwner(sync: sync);
}

class _LocationOwner extends StatefulWidget {
  const _LocationOwner({required this.sync});
  final LocationSyncService sync;
  @override
  State<_LocationOwner> createState() => _LocationOwnerState();
}

class _LocationOwnerState extends State<_LocationOwner> {
  late final cubit = LocationCubit(widget.sync);
  AppLifecycleListener? lifecycle;
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
        title: 'Cross paths on your terms',
        subtitle: 'Location sharing is optional. You can pause it whenever you like. Enabling on this phone replaces sharing from another device.',
        onBack: () => context.go('/profile'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paths uses your exact location on its server to detect people you cross paths with. Other members see approximate encounter areas, not your exact location.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Observations are kept for up to 24 hours. Offline updates stay encrypted on this phone for up to 15 minutes. Pausing clears waiting updates and stops collection.',
            ),
            const SizedBox(height: 24),
            BlocSelector<
              LocationCubit,
              LocationState,
              (TrackingStatus, bool, TrackingPermissions?, int)
            >(
              selector: (s) =>
                  (s.status, s.pendingStop, s.permissions, s.queued),
              builder: (context, value) {
                final label = value.$2
                    ? 'Paused on this phone. Server pause is pending until Paths reconnects.'
                    : switch (value.$1) {
                        TrackingStatus.active => 'Sharing while Paths is open',
                        TrackingStatus.background =>
                          'Background sharing enabled',
                        TrackingStatus.inaccurate => 'Reduced accuracy',
                        TrackingStatus.offline => 'Offline — waiting to send',
                        TrackingStatus.permissionNeeded =>
                          'Location permission needed',
                        TrackingStatus.unavailable =>
                          'Location sharing needs attention',
                        _ => 'Location sharing is paused',
                      };
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF4FF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (value.$3?.servicesEnabled == false)
                          const Text(
                            'Turn on device location services to enable sharing.',
                          ),
                        if (value.$3?.granted == true &&
                            value.$3?.precise == false)
                          const Text(
                            'Approximate permission reduces encounter detection. Your profile remains available.',
                          ),
                        if (value.$3?.granted == false &&
                            value.$3?.canRequestForeground == false)
                          const Text(
                            'Allow location in device settings. Paths will not repeat the permission prompt.',
                          ),
                        Text('Pending updates: ${value.$4}'),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            BlocSelector<LocationCubit, LocationState, bool>(
              selector: (s) => s.busy,
              builder: (context, busy) => FilledButton(
                onPressed: busy ? null : () => cubit.enable(false),
                child: busy
                    ? const PathsLoader(size: 28, color: Colors.white)
                    : const Text('Enable while using Paths'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Background sharing needs a separate choice. Android shows an ongoing notification; iOS needs Always location access. Delivery is best effort and may stop with permission changes, power saving or a force-stop.',
            ),
            const SizedBox(height: 12),
            BlocSelector<LocationCubit, LocationState, bool>(
              selector: (s) => s.busy,
              builder: (context, busy) => OutlinedButton(
                onPressed: busy ? null : () => cubit.enable(true),
                child: const Text('Enable background sharing'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: cubit.pause,
              child: const Text('Pause and clear updates'),
            ),
            TextButton(
              onPressed: cubit.refresh,
              child: const Text('Refresh status and retry'),
            ),
            TextButton(
              onPressed: cubit.openSettings,
              child: const Text('Open device settings'),
            ),
            TextButton(
              onPressed: () => context.go('/profile'),
              child: const Text('Not now — back to profile'),
            ),
          ],
        ),
      ),
    ),
  );
}
