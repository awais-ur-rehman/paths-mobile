import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../profile/domain/profile_repository.dart';
import '../../verification/domain/verification_repository.dart';
import '../domain/setup_progress.dart';
import 'setup_resume_cubit.dart';

class SetupResumeScreen extends StatelessWidget {
  const SetupResumeScreen({
    required this.profiles,
    required this.verification,
    required this.progress,
    required this.owner,
    required this.currentAccount,
    required this.onDestination,
    this.requirePermissionEducation = true,
    super.key,
  });
  final ProfileRepository profiles;
  final VerificationRepository verification;
  final SetupProgressStore progress;
  final String owner;
  final String? Function() currentAccount;
  final ValueChanged<SetupDestination> onDestination;
  final bool requirePermissionEducation;
  @override
  Widget build(BuildContext context) =>
      _ResumeOwner(key: ValueKey(owner), configuration: this);
}

class _ResumeOwner extends StatefulWidget {
  const _ResumeOwner({required this.configuration, super.key});
  final SetupResumeScreen configuration;
  @override
  State<_ResumeOwner> createState() => _ResumeOwnerState();
}

class _ResumeOwnerState extends State<_ResumeOwner> {
  late final cubit = SetupResumeCubit(
    widget.configuration.profiles,
    widget.configuration.verification,
    widget.configuration.progress,
    widget.configuration.owner,
    widget.configuration.currentAccount,
    requirePermissionEducation: widget.configuration.requirePermissionEducation,
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
    body: SafeArea(
      child: BlocConsumer<SetupResumeCubit, SetupResumeState>(
        bloc: cubit,
        listenWhen: (a, b) =>
            a.destination != b.destination && b.destination != null,
        listener: (context, state) =>
            widget.configuration.onDestination(state.destination!),
        builder: (context, state) => Center(
          child: state.error == null
              ? const PathsLoader()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.error!.message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: cubit.load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    ),
  );
}
