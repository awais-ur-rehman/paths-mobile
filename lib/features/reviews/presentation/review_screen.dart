import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../domain/review_repository.dart';
import 'review_cubit.dart';
import 'review_submit_cubit.dart';
export '../domain/review_repository.dart' show ReviewDraft;

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({required this.repository, this.draft, super.key});
  final ReviewRepository repository;
  final ReviewDraft? draft;
  @override
  Widget build(BuildContext context) => _ReviewOwner(
    key: ValueKey(repository.accountId),
    repository: repository,
    draft: draft,
  );
}

class _ReviewOwner extends StatefulWidget {
  const _ReviewOwner({required this.repository, this.draft, super.key});
  final ReviewRepository repository;
  final ReviewDraft? draft;
  @override
  State<_ReviewOwner> createState() => _ReviewOwnerState();
}

class _ReviewOwnerState extends State<_ReviewOwner> {
  late final cubit = ReviewCubit(widget.repository);
  late final submission = widget.draft == null
      ? null
      : ReviewSubmitCubit(widget.repository, widget.draft!);
  final explanation = TextEditingController();
  final form = GlobalKey<FormState>();
  AppLifecycleListener? lifecycle;
  @override
  void initState() {
    super.initState();
    unawaited(cubit.load());
    lifecycle = AppLifecycleListener(onResume: () => unawaited(cubit.load()));
  }

  @override
  void dispose() {
    lifecycle?.dispose();
    explanation.dispose();
    unawaited(submission?.close());
    unawaited(cubit.close());
    super.dispose();
  }

  String title(String kind) => switch (kind) {
    'verification' => 'Verification',
    'image' => 'Photo review',
    'report' => 'Report',
    'warning' => 'Account notice',
    _ => 'Appeal',
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reviews')),
    body: RefreshIndicator(
      onRefresh: () => cubit.load(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (submission != null)
            BlocConsumer<ReviewSubmitCubit, ReviewSubmitState>(
              bloc: submission,
              listener: (context, state) {
                if (state.sent) {
                  PathsToast.show(context, 'Sent for review');
                  unawaited(cubit.load());
                } else if (state.error != null) {
                  PathsToast.show(context, state.error!.message);
                }
              },
              builder: (context, state) => state.sent
                  ? const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Text('Review requested'),
                    )
                  : Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Request a review',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (widget.draft!.content.isNotEmpty)
                            Text(widget.draft!.content),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: explanation,
                            enabled: !state.busy,
                            maxLength: 500,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Why should we review this?',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Add a short reason.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: state.busy
                                ? null
                                : () {
                                    if (form.currentState!.validate()) {
                                      unawaited(
                                        submission!.submit(explanation.text),
                                      );
                                    }
                                  },
                            child: state.busy
                                ? const PathsLoader(
                                    size: 24,
                                    color: Colors.white,
                                  )
                                : const Text('Submit'),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
            ),
          BlocBuilder<ReviewCubit, ReviewState>(
            bloc: cubit,
            builder: (context, state) => Column(
              children: [
                if (state.busy && state.items.isEmpty) const PathsLoader(),
                if (state.error != null)
                  Column(
                    children: [
                      Text(
                        state.error!.offline
                            ? 'You’re offline'
                            : 'Could not load reviews',
                      ),
                      TextButton(
                        onPressed: () => cubit.load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                if (!state.busy && state.error == null && state.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No reviews yet'),
                  ),
                for (final item in state.items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.fact_check_outlined),
                    title: Text(title(item.kind)),
                    subtitle: Text(
                      [
                        item.status,
                        if (item.reason != null) item.reason!,
                      ].join('\n'),
                    ),
                    isThreeLine: item.reason != null,
                    trailing:
                        item.kind == 'image' &&
                            item.status == 'rejected' &&
                            item.resourceId != null
                        ? TextButton(
                            onPressed: () => context.push(
                              '/reviews',
                              extra: ReviewDraft(
                                kind: 'image',
                                content: '',
                                assetId: item.resourceId,
                              ),
                            ),
                            child: const Text('Appeal'),
                          )
                        : null,
                  ),
                if (state.cursor != null)
                  TextButton(
                    onPressed: state.busy ? null : () => cubit.load(more: true),
                    child: const Text('Load more'),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
