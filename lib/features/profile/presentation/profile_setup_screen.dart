import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_widgets.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_avatar.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../domain/profile_repository.dart';
import 'profile_cubit.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({
    required this.repository,
    this.editing = false,
    super.key,
  });
  final bool editing;
  final ProfileRepository repository;
  @override
  Widget build(BuildContext context) =>
      _ProfileOwner(repository: repository, editing: editing);
}

class _ProfileOwner extends StatefulWidget {
  const _ProfileOwner({required this.repository, required this.editing});
  final bool editing;
  final ProfileRepository repository;
  @override
  State<_ProfileOwner> createState() => _ProfileOwnerState();
}

class _ProfileOwnerState extends State<_ProfileOwner> {
  late final cubit = ProfileCubit(widget.repository);
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
    child: BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (a, b) =>
          (b.error != null && a.error != b.error) ||
          a.saveRevision != b.saveRevision,
      listener: (context, state) {
        if (state.error case final error?) {
          PathsToast.show(context, error.message);
        } else if (state.saveRevision > 0) {
          if (state.continueSetup) {
            context.go('/setup/verification');
          } else {
            PathsToast.show(
              context,
              'Your profile details are saved.',
              tone: ToastTone.success,
            );
          }
        }
      },
      child: AuthScaffold(
        title: widget.editing ? 'Edit your profile' : 'Make it your profile',
        onBack: widget.editing ? () => context.go('/profile') : null,
        subtitle: 'Start with the basics. Your profile stays private while you finish setup.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocBuilder<ProfileCubit, ProfileState>(
              buildWhen: (a, b) =>
                  a.loading != b.loading ||
                  a.details != b.details ||
                  (a.details == null && a.error != b.error),
              builder: (context, state) {
                if (state.loading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: PathsLoader(),
                    ),
                  );
                }
                if (state.details case final details?) {
                  return _ProfileForm(details: details);
                }
                return Column(
                  children: [
                    Text(
                      state.error?.message ??
                          'Your details could not be loaded.',
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: cubit.load,
                      child: const Text('Retry'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.read<AuthCubit>().logout(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.details});
  final ProfileDetails details;
  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.details.name);
  late final username = TextEditingController(text: widget.details.username);
  late final bio = TextEditingController(text: widget.details.bio);
  late bool privateProfile = widget.details.visibility == 'private';
  late String? gender = widget.details.gender.isEmpty
      ? null
      : widget.details.gender;
  @override
  void didUpdateWidget(_ProfileForm old) {
    super.didUpdateWidget(old);
    if (old.details != widget.details) {
      name.text = widget.details.name;
      username.text = widget.details.username;
      bio.text = widget.details.bio;
      gender = widget.details.gender;
      privateProfile = widget.details.visibility == 'private';
    }
  }

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    bio.dispose();
    super.dispose();
  }

  void save({bool continueSetup = false}) {
    if (form.currentState!.validate()) {
      context.read<ProfileCubit>().save(
        ProfileDetails(
          username: username.text.trim().toLowerCase(),
          name: name.text.trim(),
          gender: gender!,
          bio: bio.text,
          visibility: privateProfile ? 'private' : 'public',
        ),
        continueSetup: continueSetup,
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<ProfileCubit, ProfileState, bool>(
        selector: (state) => state.saving,
        builder: (context, saving) => Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: PathsAvatar(size: 72)),
              const SizedBox(height: 12),
              const Text('Profile photo required', textAlign: TextAlign.center),
              const SizedBox(height: 4),
              const Text(
                'Photo uploads aren’t available in this build yet. Your profile is not yet complete.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: name,
                readOnly: saving,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null ||
                        v.trim().runes.length < 2 ||
                        v.trim().runes.length > 80
                    ? 'Use 2–80 characters.'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: username,
                readOnly: saving,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixText: '@',
                  helperText: '3–24 letters, numbers or underscores.',
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null ||
                        !RegExp(r'^[a-z0-9_]{3,24}$')
                            .hasMatch(v.trim().toLowerCase())
                    ? 'Use 3–24 letters, numbers or underscores.'
                    : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: gender,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'man', child: Text('Man')),
                  DropdownMenuItem(value: 'woman', child: Text('Woman')),
                  DropdownMenuItem(
                    value: 'another_identity',
                    child: Text('Another identity'),
                  ),
                  DropdownMenuItem(
                    value: 'prefer_not_to_say',
                    child: Text('Prefer not to say'),
                  ),
                ],
                onChanged: saving ? null : (value) => gender = value,
                validator: (v) => v == null ? 'Choose an option.' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: bio,
                readOnly: saving,
                maxLines: 4,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Bio (optional)',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v?.runes.length ?? 0) > 300
                    ? 'Use up to 300 characters.'
                    : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: privateProfile,
                onChanged: saving
                    ? null
                    : (value) => setState(() => privateProfile = value),
                title: Text(
                  privateProfile ? 'Private profile' : 'Public profile',
                ),
                subtitle: Text(
                  privateProfile
                      ? 'Only connections can see your posts. Your basic card remains visible to eligible members.'
                      : 'Eligible signed-in members can see your posts. Your exact location and date of birth stay private.',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: saving ? null : () => save(),
                child: saving
                    ? const PathsLoader(size: 28, color: Colors.white)
                    : const Text('Save details'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: saving ? null : () => save(continueSetup: true),
                child: const Text('Save and continue'),
              ),
              if (widget.details.username.isNotEmpty)
                TextButton(
                  onPressed: saving ? null : () => context.go('/profile'),
                  child: const Text('View your profile'),
                ),
            ],
          ),
        ),
      );
}
