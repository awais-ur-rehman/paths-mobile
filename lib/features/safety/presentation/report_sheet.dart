import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_dropdown_field.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../domain/safety_repository.dart';
import 'report_cubit.dart';
import 'safety_scope.dart';

Future<void> showSafetyActions(
  BuildContext context,
  SafetyTarget target,
) async {
  final repository = SafetyScope.maybeOf(context);
  if (repository == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => _ReportOwner(repository: repository, target: target),
  );
}

class SafetyMenuButton extends StatelessWidget {
  const SafetyMenuButton({required this.target, super.key});
  final SafetyTarget target;
  @override
  Widget build(BuildContext context) => SafetyScope.maybeOf(context) == null
      ? const SizedBox.shrink()
      : IconButton(
          tooltip: 'Safety options',
          icon: const Icon(Icons.more_horiz),
          onPressed: () => showSafetyActions(context, target),
        );
}

class _ReportOwner extends StatefulWidget {
  const _ReportOwner({required this.repository, required this.target});
  final SafetyRepository repository;
  final SafetyTarget target;
  @override
  State<_ReportOwner> createState() => _ReportOwnerState();
}

class _ReportOwnerState extends State<_ReportOwner> {
  late final cubit = ReportCubit(widget.repository, widget.target);
  final details = TextEditingController();
  String category = 'harassment';
  @override
  void initState() {
    super.initState();
    unawaited(cubit.prepare());
  }

  @override
  void dispose() {
    details.dispose();
    unawaited(cubit.close());
    super.dispose();
  }

  Future<void> block() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Block this member?'),
        content: const Text('You won’t see or message each other.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await cubit.block();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ReportCubit, ReportState>(
    bloc: cubit,
    listenWhen: (a, b) => a.error != b.error,
    listener: (c, s) {
      if (s.error != null) PathsToast.show(c, s.error!.message);
    },
    builder: (context, state) => PopScope(
      canPop: !state.busy,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      state.receipt == null
                          ? (cubit.kind == 'profile'
                                ? 'Report member'
                                : 'Report ${cubit.kind}')
                          : 'Report received',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: state.busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.receipt == null) ...[
                PathsDropdownField<String>(
                  label: 'Reason',
                  value: category,
                  enabled: !state.busy,
                  options: const [
                    PathsDropdownOption('suspected_minor', 'Under 18'),
                    PathsDropdownOption('threats', 'Threats'),
                    PathsDropdownOption('harassment', 'Harassment'),
                    PathsDropdownOption('impersonation', 'Impersonation'),
                    PathsDropdownOption(
                      'sexual_exploitation',
                      'Sexual exploitation',
                    ),
                    PathsDropdownOption('other', 'Something else'),
                  ],
                  onChanged: (v) => setState(() => category = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: details,
                  enabled: !state.busy,
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Details (optional)',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 20),
                if (state.problem != null) ...[
                  const Text('This post can no longer be attached.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: state.busy ? null : cubit.reportMemberInstead,
                    child: const Text('Report member instead'),
                  ),
                ] else
                  FilledButton(
                    onPressed: state.busy
                        ? null
                        : () => cubit.submit(category, details.text),
                    child: state.busy
                        ? const PathsLoader(size: 24, color: Colors.white)
                        : const Text('Send report'),
                  ),
              ] else ...[
                const Text('Thanks. Our team will review it.'),
                const SizedBox(height: 8),
                SelectableText('Reference: ${state.receipt}'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: state.busy ? null : () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: state.busy || state.blocked ? null : block,
                child: Text(state.blocked ? 'Blocked' : 'Block member'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
