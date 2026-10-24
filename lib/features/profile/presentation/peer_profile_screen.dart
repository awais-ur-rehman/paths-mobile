import '../../safety/presentation/report_sheet.dart';
import '../../safety/domain/safety_repository.dart';
import '../../safety/presentation/safety_scope.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_icon.dart';
import 'profile_surface.dart';
import '../../relationships/data/relationship_repository.dart';
import '../../relationships/presentation/relationship_controls.dart';
import '../domain/profile_repository.dart';
import 'profile_preview_cubit.dart';

class PeerProfileScreen extends StatelessWidget {
  const PeerProfileScreen({
    required this.repository,
    required this.userId,
    required this.onBack,
    this.relationships,
    this.onOpened,
    this.onChat,
    super.key,
  });
  final ProfileSummaryRepository repository;
  final String userId;
  final VoidCallback onBack;
  final RelationshipRepository? relationships;
  final VoidCallback? onOpened, onChat;
  @override
  Widget build(BuildContext context) =>
      _PeerOwner(key: ValueKey(userId), configuration: this);
}

class _PeerOwner extends StatefulWidget {
  const _PeerOwner({required this.configuration, super.key});
  final PeerProfileScreen configuration;
  @override
  State<_PeerOwner> createState() => _PeerOwnerState();
}

class _PeerOwnerState extends State<_PeerOwner> {
  late final cubit = ProfilePreviewCubit(
    widget.configuration.repository,
    widget.configuration.userId,
  );
  @override
  void initState() {
    super.initState();
    unawaited(cubit.load());
  }

  @override
  void dispose() {
    unawaited(cubit.close());
    super.dispose();
  }

  Widget _withBack(Widget child) => Stack(
    fit: StackFit.expand,
    children: [
      Center(child: child),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: ProfileHeader(
          onBack: widget.configuration.onBack,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => SafetyRefresh(
    onChanged: () => unawaited(cubit.load()),
    child: Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<ProfilePreviewCubit, ProfilePreviewState>(
        bloc: cubit,
        listenWhen: (before, after) =>
            before.profile == null && after.profile != null,
        listener: (_, _) => widget.configuration.onOpened?.call(),
        child: BlocBuilder<ProfilePreviewCubit, ProfilePreviewState>(
          bloc: cubit,
          builder: (context, state) {
            if (state.loading) return _withBack(const PathsLoader());
            final profile = state.profile;
            if (profile == null) {
              return _withBack(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.error?.offline == true
                          ? 'You’re offline'
                          : 'Profile unavailable',
                    ),
                    if (state.error?.offline == true)
                      TextButton(
                        onPressed: cubit.load,
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              );
            }
            return ProfileSurface(
              profile: profile,
              onRefresh: cubit.load,
              action: Column(
                children: [
                  if (widget.configuration.relationships != null)
                    RelationshipControls(
                      key: ValueKey(widget.configuration.userId),
                      repository: widget.configuration.relationships!,
                      target: widget.configuration.userId,
                      onChat: widget.configuration.onChat,
                    ),
                  if (SafetyScope.maybeOf(context) != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      icon: const PathsIcon(PathsIconName.unverified, size: 18),
                      label: const Text('Report'),
                      onPressed: () => showSafetyActions(
                        context,
                        SafetyTarget(widget.configuration.userId),
                      ),
                    ),
                ],
              ),
              onBack: widget.configuration.onBack,
            );
          },
        ),
      ),
    ),
  );
}
