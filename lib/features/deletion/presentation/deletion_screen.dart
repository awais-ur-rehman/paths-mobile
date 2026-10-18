import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../domain/deletion_repository.dart';
import 'deletion_cubit.dart';

class DeletionScreen extends StatelessWidget {
  const DeletionScreen({
    required this.repository,
    required this.onAccepted,
    super.key,
  });
  final DeletionRepository repository;
  final VoidCallback onAccepted;
  @override
  Widget build(BuildContext context) =>
      _DeletionOwner(repository: repository, onAccepted: onAccepted);
}

class _DeletionOwner extends StatefulWidget {
  const _DeletionOwner({required this.repository, required this.onAccepted});
  final DeletionRepository repository;
  final VoidCallback onAccepted;
  @override
  State<_DeletionOwner> createState() => _DeletionOwnerState();
}

class _DeletionOwnerState extends State<_DeletionOwner> {
  late final cubit = DeletionCubit(widget.repository);
  final password = TextEditingController(), form = GlobalKey<FormState>();
  bool confirmed = false;
  @override
  void dispose() {
    password.dispose();
    unawaited(cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Delete account')),
    body: BlocConsumer<DeletionCubit, DeletionState>(
      bloc: cubit,
      listener: (context, state) {
        if (state.record?.accepted == true) {
          password.clear();
          widget.onAccepted();
        } else if (state.error != null) {
          PathsToast.show(
            context,
            state.error!.offline
                ? 'Deletion isn’t confirmed. Reconnect and retry.'
                : state.error!.message,
          );
        }
      },
      builder: (context, state) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Leave Paths?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your profile, photos, identity documents and encounter history will be removed. Shared chats disappear for both people.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Access ends immediately. Live data is removed within 24 hours; backups expire within 7 days. Screenshots and delivered notifications cannot be erased.',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  enabled: !state.busy,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) => value == null || value.length < 12
                      ? 'Enter your password.'
                      : null,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: confirmed,
                  onChanged: state.busy
                      ? null
                      : (value) => setState(() => confirmed = value == true),
                  title: const Text('I understand this is permanent.'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: state.busy || !confirmed
                      ? null
                      : () {
                          if (form.currentState!.validate()) {
                            unawaited(cubit.submit(password.text));
                          }
                        },
                  child: state.busy
                      ? const PathsLoader(size: 24, color: Colors.white)
                      : const Text('Delete account'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class DeletionReceiptScreen extends StatelessWidget {
  const DeletionReceiptScreen({
    required this.repository,
    required this.onDone,
    super.key,
  });
  final DeletionRepository repository;
  final VoidCallback onDone;
  @override
  Widget build(BuildContext context) =>
      _ReceiptOwner(repository: repository, onDone: onDone);
}

class _ReceiptOwner extends StatefulWidget {
  const _ReceiptOwner({required this.repository, required this.onDone});
  final DeletionRepository repository;
  final VoidCallback onDone;
  @override
  State<_ReceiptOwner> createState() => _ReceiptOwnerState();
}

class _ReceiptOwnerState extends State<_ReceiptOwner> {
  late final cubit = DeletionCubit(widget.repository);
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
    appBar: AppBar(
      title: const Text('Deletion status'),
      automaticallyImplyLeading: false,
    ),
    body: BlocBuilder<DeletionCubit, DeletionState>(
      bloc: cubit,
      builder: (context, state) {
        final record = state.record, receipt = record?.receipt;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (state.busy && record == null)
                const Center(child: PathsLoader()),
              if (receipt != null) ...[
                const Icon(Icons.check_circle_outline, size: 56),
                const SizedBox(height: 24),
                Text(
                  receipt.state == 'complete'
                      ? 'Account data removed'
                      : 'Deletion accepted',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  receipt.state == 'complete'
                      ? 'Live account data has been removed.'
                      : 'Access has ended. Live account data is being removed.',
                ),
                const SizedBox(height: 12),
                Text(
                  'Backup expiry: ${receipt.backupExpiresAt.split('T').first}',
                ),
                const SizedBox(height: 24),
                const Text('Your receipt'),
                const SizedBox(height: 8),
                SelectableText(
                  receipt.receipt,
                  style: const TextStyle(fontSize: 12),
                ),
              ] else if (!state.busy)
                Text(
                  record?.pending != null
                      ? 'Deletion isn’t confirmed. Retry to check the request.'
                      : 'No deletion receipt on this phone.',
                ),
              if (record?.cleanupOwner != null) ...[
                const SizedBox(height: 20),
                const Text('Phone cleanup needs to finish. Tap Retry.'),
              ],
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  state.error!.code == 'deletion_unconfirmed'
                      ? 'The request isn’t confirmed yet.'
                      : state.error!.message,
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: state.busy ? null : () => cubit.load(),
                child: const Text('Retry / refresh'),
              ),
              if (receipt == null && !state.busy)
                TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Return to Paths'),
                ),
              if (receipt != null && record?.cleanupOwner == null)
                TextButton(
                  onPressed: state.busy
                      ? null
                      : () async {
                          try {
                            await widget.repository.dismiss();
                            if (context.mounted) widget.onDone();
                          } catch (_) {
                            if (context.mounted) {
                              PathsToast.show(
                                context,
                                'Could not save the receipt. Retry.',
                              );
                            }
                          }
                        },
                  child: const Text('Done'),
                ),
            ],
          ),
        );
      },
    ),
  );
}
