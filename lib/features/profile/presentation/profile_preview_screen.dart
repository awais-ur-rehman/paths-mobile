import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_cubit.dart';
import '../../auth/presentation/auth_widgets.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_avatar.dart';
import '../../../shared/widgets/verification_badge.dart';
import '../domain/profile_repository.dart';
import 'profile_preview_cubit.dart';

class ProfilePreviewScreen extends StatelessWidget {
  const ProfilePreviewScreen({
    required this.repository,
    required this.userId,
    super.key,
  });
  final ProfileSummaryRepository repository;
  final String userId;
  @override
  Widget build(BuildContext context) =>
      _PreviewOwner(repository: repository, userId: userId);
}

class _PreviewOwner extends StatefulWidget {
  const _PreviewOwner({required this.repository, required this.userId});
  final ProfileSummaryRepository repository;
  final String userId;
  @override
  State<_PreviewOwner> createState() => _PreviewOwnerState();
}

class _PreviewOwnerState extends State<_PreviewOwner> {
  late final cubit = ProfilePreviewCubit(widget.repository, widget.userId);
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
  Widget build(BuildContext context) => BlocProvider.value(
    value: cubit,
    child: AuthScaffold(
      title: 'Your profile',
      subtitle: 'Your details are saved. Photo uploads aren’t available in this build yet.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<ProfilePreviewCubit, ProfilePreviewState>(
            builder: (context, state) {
              if (state.loading) return const Center(child: PathsLoader());
              final p = state.profile;
              if (p == null) {
                return Column(
                  children: [
                    Text(
                      state.error?.message ??
                          'Your profile could not be loaded.',
                    ),
                    TextButton(
                      onPressed: cubit.load,
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/setup/profile'),
                      child: const Text('Back to profile setup'),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: PathsAvatar(size: 104)),
                  const SizedBox(height: 20),
                  Text(
                    '${p.name}, ${p.age}',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text('@${p.username}'),
                  VerificationBadge(status: p.verificationStatus),
                  const SizedBox(height: 12),
                  Text(switch (p.gender) {
                    'man' => 'Man',
                    'woman' => 'Woman',
                    'another_identity' => 'Another identity',
                    _ => 'Prefer not to say',
                  }),
                  if (p.bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(p.bio),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        p.visibility == 'private'
                            ? Icons.lock_outline
                            : Icons.public_outlined,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.visibility == 'private'
                              ? 'Private profile. Posts are visible only to connections.'
                              : 'Public profile. Posts are visible to eligible signed-in members.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.go('/setup/profile?edit=1'),
                    child: const Text('Edit profile'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.go('/setup/verification'),
                    child: const Text('Document review'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => context.read<AuthCubit>().logout(),
            child: const Text('Sign out'),
          ),
        ],
      ),
    ),
  );
}
