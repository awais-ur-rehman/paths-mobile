import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'profile_skeleton.dart';
import 'profile_surface.dart';
import '../domain/profile_repository.dart';
import 'profile_preview_cubit.dart';

class ProfilePreviewScreen extends StatelessWidget {
  const ProfilePreviewScreen({
    required this.repository,
    required this.userId,
    required this.onSettings,
    super.key,
  });
  final ProfileSummaryRepository repository;
  final String userId;
  final VoidCallback onSettings;
  @override
  Widget build(BuildContext context) => _PreviewOwner(
    key: ValueKey(userId),
    repository: repository,
    userId: userId,
    onSettings: onSettings,
  );
}

class _PreviewOwner extends StatefulWidget {
  const _PreviewOwner({
    required this.repository,
    required this.userId,
    required this.onSettings,
    super.key,
  });
  final VoidCallback onSettings;
  final ProfileSummaryRepository repository;
  final String userId;
  @override
  State<_PreviewOwner> createState() => _PreviewOwnerState();
}

class _PreviewOwnerState extends State<_PreviewOwner> {
  late final cubit = ProfilePreviewCubit(widget.repository, widget.userId);
  AppLifecycleListener? lifecycle;
  bool? visible;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.isCurrentOf(context) ?? true;
    if (visible == false && current) unawaited(cubit.load());
    visible = current;
  }

  @override
  void initState() {
    super.initState();
    lifecycle = AppLifecycleListener(
      onResume: () {
        if (visible != false && !cubit.state.loading) {
          unawaited(cubit.load(force: true));
        }
      },
    );
    unawaited(cubit.load());
  }

  @override
  void dispose() {
    lifecycle?.dispose();
    unawaited(cubit.close());
    super.dispose();
  }

  Widget _withOptions(Widget child) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ProfileHeader(
            foregroundColor: ink,
            menu: ProfileSettingsButton(
              onPressed: widget.onSettings,
              color: ink,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocBuilder<ProfilePreviewCubit, ProfilePreviewState>(
      bloc: cubit,
      builder: (context, state) {
        if (state.loading && state.profile == null) {
          return _withOptions(const ProfileSkeleton());
        }
        final profile = state.profile;
        if (profile == null) {
          return _withOptions(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.error?.offline == true
                      ? 'You’re offline'
                      : 'Profile unavailable',
                ),
                TextButton(onPressed: cubit.load, child: const Text('Retry')),
                TextButton(
                  onPressed: () => context.go('/setup/profile'),
                  child: const Text('Back to profile setup'),
                ),
              ],
            ),
          );
        }
        return ProfileSurface(
          profile: profile,
          onRefresh: () => cubit.load(force: true),
          menu: ProfileSettingsButton(onPressed: widget.onSettings),
        );
      },
    ),
  );
}
