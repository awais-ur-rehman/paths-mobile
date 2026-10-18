import 'message_evidence_picker.dart';
import 'blocked_accounts_cubit.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../domain/safety_repository.dart';

class BlockedAccountsScreen extends StatelessWidget {
  const BlockedAccountsScreen({required this.repository, super.key});
  final SafetyRepository repository;
  @override
  Widget build(BuildContext context) => _BlockedOwner(
    repository: repository,
    key: ValueKey(repository.accountId),
  );
}

class _BlockedOwner extends StatefulWidget {
  const _BlockedOwner({required this.repository, super.key});
  final SafetyRepository repository;
  @override
  State<_BlockedOwner> createState() => _BlockedOwnerState();
}

class _BlockedOwnerState extends State<_BlockedOwner> {
  late final cubit = BlockedCubit(widget.repository);
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

  Future<void> unblock(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Unblock this member?'),
        content: const Text('Your connection won’t be restored.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await cubit.unblock(id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Blocked accounts')),
    body: BlocConsumer<BlockedCubit, BlockedState>(
      bloc: cubit,
      listenWhen: (a, b) => a.error != b.error,
      listener: (c, s) {
        if (s.error != null) PathsToast.show(c, s.error!.message);
      },
      builder: (context, state) {
        if (state.loading) return const Center(child: PathsLoader());
        if (state.items.isEmpty) {
          return Center(
            child: state.error == null
                ? const Text('No blocked accounts')
                : TextButton(
                    onPressed: () => cubit.load(),
                    child: const Text('Retry'),
                  ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => cubit.load(),
          child: ListView(
            children: [
              for (final item in state.items)
                ListTile(
                  title: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Wrap(
                    children: [
                      MessageSafetyMenuButton(
                        subject: item.userId,
                        alreadyBlocked: true,
                      ),
                      TextButton(
                        onPressed: state.working != null
                            ? null
                            : () => unblock(item.userId),
                        child: Text(
                          state.working == item.userId
                              ? 'Unblocking…'
                              : 'Unblock',
                        ),
                      ),
                    ],
                  ),
                ),
              if (state.cursor != null)
                TextButton(
                  onPressed: () => cubit.load(more: true),
                  child: const Text('More'),
                ),
            ],
          ),
        );
      },
    ),
  );
}
