import '../../reviews/presentation/review_screen.dart';
import '../../media/presentation/media_scope.dart';
import '../../media/presentation/private_image.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_widgets.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_dropdown_field.dart';
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
          if (MediaScope.maybeOf(context) != null) {
            context.go(
              widget.editing ? '/setup/resume?return=profile' : '/setup/resume',
            );
            return;
          }
          context.go(
            widget.editing
                ? '/profile?revision=${DateTime.now().microsecondsSinceEpoch}'
                : '/setup/verification',
          );
        }
      },
      child: AuthScaffold(
        title: widget.editing ? 'Edit your profile' : 'Make it your profile',
        onBack: widget.editing ? () => context.go('/profile') : null,
        subtitle: 'A few details about you.',
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
                  return _ProfileForm(
                    details: details,
                    editing: widget.editing,
                  );
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
          ],
        ),
      ),
    ),
  );
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.details, required this.editing});
  final bool editing;
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
  late String? avatarAssetId = widget.details.avatarAssetId;
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

  void save() {
    if (MediaScope.maybeOf(context) != null && avatarAssetId == null) {
      PathsToast.show(context, 'Add a profile photo.');
      return;
    }
    if (form.currentState!.validate()) {
      context.read<ProfileCubit>().save(
        ProfileDetails(
          revision: widget.details.revision,
          username: username.text.trim().toLowerCase(),
          name: name.text.trim(),
          gender: gender!,
          bio: bio.text,
          avatarAssetId: avatarAssetId,
          visibility: privateProfile ? 'private' : 'public',
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocSelector<ProfileCubit, ProfileState, bool>(
    selector: (state) => state.saving,
    builder: (context, saving) => Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (MediaScope.maybeOf(context) case final media?) ...[
            Center(
              child: SizedBox(
                width: 112,
                height: 112,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: avatarAssetId == null
                      ? const ColoredBox(
                          color: Color(0xFFF3F4F5),
                          child: Icon(Icons.person_outline, size: 48),
                        )
                      : PrivateImage(
                          repository: media.media,
                          assetId: avatarAssetId!,
                        ),
                ),
              ),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      final id = await context.push<String>('/media/avatar');
                      if (mounted && id != null) {
                        setState(() => avatarAssetId = id);
                      }
                    },
              child: Text(avatarAssetId == null ? 'Add photo' : 'Change photo'),
            ),
            const SizedBox(height: 20),
          ],
          AuthFieldSurface(
            child: TextFormField(
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
          ),
          const SizedBox(height: 20),
          AuthFieldSurface(
            child: TextFormField(
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
          ),
          const SizedBox(height: 20),
          AuthFieldSurface(
            child: PathsDropdownField<String>(
              label: 'Gender',
              value: gender,
              enabled: !saving,
              options: const [
                PathsDropdownOption('man', 'Man'),
                PathsDropdownOption('woman', 'Woman'),
                PathsDropdownOption('another_identity', 'Another identity'),
                PathsDropdownOption('prefer_not_to_say', 'Prefer not to say'),
              ],
              onChanged: (value) => gender = value,
              validator: (value) => value == null ? 'Choose an option.' : null,
            ),
          ),
          const SizedBox(height: 20),
          AuthFieldSurface(
            child: TextFormField(
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
          ),
          BlocSelector<ProfileCubit, ProfileState, bool>(
            selector: (state) => state.error?.code == 'CONTENT_REVIEW_REQUIRED',
            builder: (context, review) => review
                ? TextButton(
                    onPressed: () => context.push(
                      '/reviews',
                      extra: ReviewDraft(kind: 'bio', content: bio.text),
                    ),
                    child: const Text('Request review'),
                  )
                : const SizedBox.shrink(),
          ),
          BlocSelector<ProfileCubit, ProfileState, bool>(
            selector: (state) => state.error?.code == 'PROFILE_CHANGED',
            builder: (context, changed) => changed
                ? TextButton(
                    onPressed: () => context.read<ProfileCubit>().load(),
                    child: const Text('Reload latest profile'),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: privateProfile,
            onChanged: saving
                ? null
                : (value) => setState(() => privateProfile = value),
            title: Text(privateProfile ? 'Private profile' : 'Public profile'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: saving ? null : save,
            child: saving
                ? const PathsLoader(size: 28, color: Colors.white)
                : Text(widget.editing ? 'Save' : 'Next'),
          ),
        ],
      ),
    ),
  );
}
