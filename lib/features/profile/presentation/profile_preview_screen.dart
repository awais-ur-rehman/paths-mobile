import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_cubit.dart';
import '../../../shared/widgets/paths_loader.dart';
import 'profile_surface.dart';
import '../domain/profile_repository.dart';
import 'profile_preview_cubit.dart';

class ProfilePreviewScreen extends StatelessWidget {
  const ProfilePreviewScreen({
    required this.repository,
    required this.userId,
    this.onLocationSetup,
    this.onBlockedAccounts,
    this.onSignInMethods,
    this.onDeleteAccount,
    this.onBack,
    super.key,
  });
  final ProfileSummaryRepository repository;
  final String userId;
  final VoidCallback? onLocationSetup,
      onBack,
      onBlockedAccounts,
      onSignInMethods,
      onDeleteAccount;
  @override
  Widget build(BuildContext context) => _PreviewOwner(
    key: ValueKey(userId),
    repository: repository,
    userId: userId,
    onLocationSetup: onLocationSetup,
    onBlockedAccounts: onBlockedAccounts,
    onSignInMethods: onSignInMethods,
    onDeleteAccount: onDeleteAccount,
    onBack: onBack,
  );
}

class _PreviewOwner extends StatefulWidget {
  const _PreviewOwner({
    required this.repository,
    required this.userId,
    this.onLocationSetup,
    this.onBlockedAccounts,
    this.onSignInMethods,
    this.onDeleteAccount,
    this.onBack,
    super.key,
  });
  final VoidCallback? onLocationSetup,
      onBack,
      onBlockedAccounts,
      onSignInMethods,
      onDeleteAccount;
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
          unawaited(cubit.load());
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

  void _options() {
    final auth = context.read<AuthCubit>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: const Text('Verification'),
                onTap: () {
                  Navigator.pop(sheet);
                  context.go('/setup/verification?return=profile');
                },
              ),
              if (widget.onLocationSetup != null)
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Location & permissions'),
                  onTap: () {
                    Navigator.pop(sheet);
                    widget.onLocationSetup!();
                  },
                ),
              if (widget.onSignInMethods != null)
                ListTile(
                  leading: const Icon(Icons.key_outlined),
                  title: const Text('Sign-in methods'),
                  onTap: () {
                    Navigator.pop(sheet);
                    widget.onSignInMethods!();
                  },
                ),
              if (widget.onBlockedAccounts != null)
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Blocked accounts'),
                  onTap: () {
                    Navigator.pop(sheet);
                    widget.onBlockedAccounts!();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: const Text('Reviews'),
                onTap: () {
                  Navigator.pop(sheet);
                  context.push('/reviews');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Sign out'),
                onTap: () {
                  Navigator.pop(sheet);
                  unawaited(auth.logout());
                },
              ),
            ],
          ),
        ),
      ),
    );
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
            onBack: widget.onBack,
            foregroundColor: ink,
            menu: ProfileOptionsButton(onPressed: _options, color: ink),
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
        if (state.loading) return _withOptions(const PathsLoader());
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
          onBack: widget.onBack,
          menu: ProfileOptionsButton(onPressed: _options),
          action: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF101418),
            ),
            onPressed: () => context.go('/setup/profile?edit=1'),
            child: const Text('Edit profile'),
          ),
        );
      },
    ),
  );
}
