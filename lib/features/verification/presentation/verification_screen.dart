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
        title: 'Verification',
        onRefresh: cubit.refresh,
        subtitle: 'Upload your CNIC to get verified.',
        onBack: () => context.go('/setup/profile'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _DocumentTile(side: DocumentSide.front)),
                SizedBox(width: 12),
                Expanded(child: _DocumentTile(side: DocumentSide.back)),
              ],
            ),
            BlocSelector<VerificationCubit, VerificationState, bool>(
              selector: (s) => s.info?.uploadsAvailable == true,
              builder: (context, available) => available
                  ? Column(
                      children: [
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Document review'),
                              content: const SingleChildScrollView(
                                child: Text(
                                  'Review is optional and is not a government check or a safety guarantee. The front is required; the back is optional. Submitted images, including replaced or declined versions, are retained while your account exists. Only authorized reviewers can access them. Account deletion removes them.',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          ),
                          child: const Text('Review details'),
                        ),
                        BlocSelector<
                          VerificationCubit,
                          VerificationState,
                          (bool, bool)
                        >(
                          selector: (s) => (s.consent, s.busy),
                          builder: (context, value) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: value.$1,
                            onChanged: value.$2
                                ? null
                                : (v) => cubit.setConsent(v ?? false),
                            title: const Text(
                              'I agree to document review and retention.',
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
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
              selector: (s) => s.busy && !s.uploading,
              builder: (context, busy) => TextButton(
                onPressed: busy ? null : cubit.skip,
                child: const Text('Skip'),
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
              s.info?.status != 'pending',
        ),
        builder: (context, value) {
          final asset = value.$1;
          final label = side == DocumentSide.front ? 'CNIC front' : 'CNIC back';
          return Semantics(
            button: true,
            enabled: value.$2,
            label: '$label${value.$2 ? '' : ', uploads unavailable'}',
            child: CustomPaint(
              painter: const _DottedBorder(),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: value.$2
                    ? () => context.read<VerificationCubit>().pick(side)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 30,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          asset == null
                              ? Icons.badge_outlined
                              : Icons.description_outlined,
                          size: 30,
                          color: value.$2
                              ? const Color(0xFF147DCE)
                              : const Color(0xFF8D99A4),
                        ),
                        const SizedBox(height: 12),
                        Text(label, textAlign: TextAlign.center),
                        if (asset != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            asset.processed ? 'Ready' : 'Processing',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _DottedBorder extends CustomPainter {
  const _DottedBorder();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      );
    final paint = Paint()
      ..color = const Color(0xFFADB8C1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 9) {
        canvas.drawPath(metric.extractPath(offset, offset + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBorder oldDelegate) => false;
}
