import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_widgets.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../../../shared/widgets/verification_badge.dart';
import '../domain/verification_repository.dart';
import 'verification_cubit.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({
    required this.repository,
    this.documents = const UnavailableVerificationDocuments(),
    super.key,
  });
  final VerificationRepository repository;
  final VerificationDocuments documents;
  @override
  Widget build(BuildContext context) =>
      _VerificationOwner(repository: repository, documents: documents);
}

class _VerificationOwner extends StatefulWidget {
  const _VerificationOwner({required this.repository, required this.documents});
  final VerificationRepository repository;
  final VerificationDocuments documents;
  @override
  State<_VerificationOwner> createState() => _VerificationOwnerState();
}

class _VerificationOwnerState extends State<_VerificationOwner> {
  late final cubit = VerificationCubit(widget.repository, widget.documents);
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
    child: BlocListener<VerificationCubit, VerificationState>(
      listenWhen: (a, b) =>
          (b.error != null && a.error != b.error) ||
          a.skipRevision != b.skipRevision ||
          a.submitRevision != b.submitRevision,
      listener: (context, state) {
        if (state.error case final error?) {
          PathsToast.show(context, error.message);
        } else if (state.skipRevision > 0) {
          context.go('/profile');
        } else if (state.submitRevision > 0) {
          PathsToast.show(
            context,
            'Your document is pending review.',
            tone: ToastTone.success,
          );
        }
      },
      child: AuthScaffold(
        title: 'A little more reassurance',
        subtitle: 'Document review is optional. Skip now and return whenever you like.',
        onBack: () => context.go('/setup/profile'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paths can manually review your CNIC. It is not a government check or a safety guarantee. Skipping, waiting for a review or a declined review never removes your normal account access.',
            ),
            const SizedBox(height: 20),
            BlocSelector<VerificationCubit, VerificationState, String?>(
              selector: (s) => s.info?.status,
              builder: (_, status) =>
                  VerificationBadge(status: status ?? 'none'),
            ),
            BlocBuilder<VerificationCubit, VerificationState>(
              buildWhen: (a, b) =>
                  a.info != b.info ||
                  a.loading != b.loading ||
                  (a.info == null && a.error != b.error),
              builder: (context, state) {
                if (state.loading) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: PathsLoader()),
                  );
                }
                if (state.info == null) {
                  return Column(
                    children: [
                      Text(
                        state.error?.message ??
                            'Review status could not be loaded.',
                      ),
                      TextButton(
                        onPressed: cubit.load,
                        child: const Text('Retry'),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.info?.reason case final reason?)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('Review note: $reason'),
                      ),
                    if (state.info?.uploadsAvailable != true)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Document uploads are not available in this build. No CNIC is collected. You can skip this step.',
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const _DocumentTile(side: DocumentSide.front),
            const SizedBox(height: 12),
            const _DocumentTile(side: DocumentSide.back),
            const SizedBox(height: 20),
            const Text(
              'If you submit later, the front is required and the back is optional. Paths retains submitted images, including replaced or declined versions, while your account exists. Only authorized reviewers can access them; account deletion removes them.',
            ),
            const SizedBox(height: 12),
            BlocSelector<VerificationCubit, VerificationState, (bool, bool)>(
              selector: (s) => (s.consent, s.busy),
              builder: (context, value) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: value.$1,
                onChanged: value.$2
                    ? null
                    : (v) => cubit.setConsent(v ?? false),
                title: const Text(
                  'I consent to this document review and retention.',
                ),
              ),
            ),
            const SizedBox(height: 20),
            BlocSelector<VerificationCubit, VerificationState, (bool, bool)>(
              selector: (s) => (s.canSubmit, s.busy),
              builder: (context, value) => FilledButton(
                onPressed: value.$1 ? cubit.submit : null,
                child: value.$2
                    ? const PathsLoader(size: 28)
                    : const Text('Submit for review'),
              ),
            ),
            const SizedBox(height: 8),
            BlocSelector<VerificationCubit, VerificationState, bool>(
              selector: (s) => s.busy || s.loading,
              builder: (context, busy) => TextButton(
                onPressed: busy ? null : cubit.load,
                child: const Text('Refresh status'),
              ),
            ),
            BlocSelector<VerificationCubit, VerificationState, bool>(
              selector: (s) => s.busy && !s.uploading,
              builder: (context, busy) => TextButton(
                onPressed: busy ? null : cubit.skip,
                child: const Text('Skip for now'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.side});
  final DocumentSide side;
  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        VerificationCubit,
        VerificationState,
        (DocumentAsset?, bool)
      >(
        selector: (s) => (
          side == DocumentSide.front ? s.front : s.back,
          !s.loading &&
              !s.busy &&
              s.info?.uploadsAvailable == true &&
              s.info?.status != 'pending' &&
              s.info?.status != 'approved',
        ),
        builder: (context, value) {
          final asset = value.$1;
          final label = side == DocumentSide.front
              ? 'CNIC front'
              : 'CNIC back (optional)';
          final status = asset == null
              ? 'Not selected'
              : asset.processed
              ? 'Processed and ready'
              : 'Processing — not ready to submit';
          return DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD8E4EC)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(status),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: value.$2
                        ? () => context.read<VerificationCubit>().pick(side)
                        : null,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      asset == null ? 'Choose document' : 'Replace document',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
