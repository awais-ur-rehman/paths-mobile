import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_avatar.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/verification_badge.dart';
import '../domain/profile_repository.dart';
import 'profile_preview_cubit.dart';

class PeerProfileScreen extends StatelessWidget {
  const PeerProfileScreen({
    required this.repository,
    required this.userId,
    required this.onBack,
    super.key,
  });
  final ProfileSummaryRepository repository;
  final String userId;
  final VoidCallback onBack;
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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back',
        onPressed: widget.configuration.onBack,
        icon: const Icon(Icons.arrow_back),
      ),
      title: const Text('Profile'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: BlocBuilder<ProfilePreviewCubit, ProfilePreviewState>(
            bloc: cubit,
            builder: (context, state) {
              if (state.loading) return const Center(child: PathsLoader());
              final profile = state.profile;
              if (profile == null) {
                return Center(
                  child: Column(
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
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: PathsAvatar(size: 104)),
                    const SizedBox(height: 24),
                    Text(
                      '${profile.name}, ${profile.age}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text('@${profile.username}'),
                    VerificationBadge(status: profile.verificationStatus),
                    const SizedBox(height: 24),
                    if (profile.bio.isNotEmpty) Text(profile.bio),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
