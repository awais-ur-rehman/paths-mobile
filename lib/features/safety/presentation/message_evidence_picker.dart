import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/safety_repository.dart';
import 'safety_scope.dart';
import 'report_sheet.dart';
import '../../../shared/widgets/paths_icon.dart';
import '../../../shared/widgets/paths_options_menu.dart';

Future<void> chooseMessageReport(
  BuildContext context,
  String subject, {
  bool alreadyBlocked = false,
}) async {
  final repository = SafetyScope.maybeOf(context);
  if (repository == null) return;
  final message = await showModalBottomSheet<ChatMessageDto>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _EvidenceOwner(repository: repository, subject: subject),
  );
  if (context.mounted && message != null) {
    await showSafetyActions(
      context,
      SafetyTarget(
        subject,
        kind: 'message',
        contentId: message.id,
        alreadyBlocked: alreadyBlocked,
      ),
    );
  }
}

class MessageSafetyMenuButton extends StatelessWidget {
  const MessageSafetyMenuButton({
    required this.subject,
    this.alreadyBlocked = false,
    super.key,
  });
  final String subject;
  final bool alreadyBlocked;
  @override
  Widget build(BuildContext context) => SafetyScope.maybeOf(context) == null
      ? const SizedBox.shrink()
      : IconButton(
          tooltip: 'Report options',
          icon: const PathsIcon(PathsIconName.more, size: 24),
          onPressed: () async {
            final value = await showPathsOptions(context, const [
              PathsMenuOption(
                'profile',
                'Report member',
                PathsIconName.profile,
              ),
              PathsMenuOption(
                'message',
                'Report a message',
                PathsIconName.chats,
              ),
            ]);
            if (!context.mounted || value == null) return;
            if (value == 'message') {
              await chooseMessageReport(
                context,
                subject,
                alreadyBlocked: alreadyBlocked,
              );
            } else {
              await showSafetyActions(
                context,
                SafetyTarget(subject, alreadyBlocked: alreadyBlocked),
              );
            }
          },
        );
}

final class EvidenceState {
  const EvidenceState({
    this.items = const [],
    this.cursor,
    this.loading = true,
    this.error,
  });
  final List<ChatMessageDto> items;
  final String? cursor;
  final bool loading;
  final AuthFailure? error;
}

class MessageEvidenceCubit extends Cubit<EvidenceState> {
  MessageEvidenceCubit(this.repository, this.subject)
    : _account = repository.accountId,
      super(const EvidenceState());
  final SafetyRepository repository;
  final String subject;
  final String? _account;
  final _cancel = CancelToken();
  bool _loading = false;
  bool get valid =>
      !isClosed && _account == repository.accountId && _account != null;
  Future<void> load({bool more = false}) async {
    if (_loading || !valid || (more && state.cursor == null)) return;
    _loading = true;
    try {
      final page = await repository.reportableMessages(
        subject,
        cursor: more ? state.cursor : null,
        cancelToken: _cancel,
      );
      if (valid) {
        emit(
          EvidenceState(
            items: List.unmodifiable([if (more) ...state.items, ...page.items]),
            cursor: page.nextCursor,
            loading: false,
          ),
        );
      }
    } catch (e) {
      if (valid) {
        emit(
          EvidenceState(
            items: state.items,
            cursor: state.cursor,
            loading: false,
            error: e is AuthFailure ? e : const AuthFailure('unavailable'),
          ),
        );
      }
    } finally {
      _loading = false;
    }
  }

  @override
  Future<void> close() {
    _cancel.cancel();
    return super.close();
  }
}

class _EvidenceOwner extends StatefulWidget {
  const _EvidenceOwner({required this.repository, required this.subject});
  final SafetyRepository repository;
  final String subject;
  @override
  State<_EvidenceOwner> createState() => _EvidenceOwnerState();
}

class _EvidenceOwnerState extends State<_EvidenceOwner> {
  late final cubit = MessageEvidenceCubit(widget.repository, widget.subject);
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
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .75,
    child: Scaffold(
      appBar: AppBar(title: const Text('Choose a message')),
      body: BlocBuilder<MessageEvidenceCubit, EvidenceState>(
        bloc: cubit,
        builder: (context, state) {
          if (state.loading) return const Center(child: PathsLoader());
          if (state.items.isEmpty) {
            return Center(
              child: state.error == null
                  ? const Text('No messages to report')
                  : TextButton(
                      onPressed: () => cubit.load(),
                      child: const Text('Retry'),
                    ),
            );
          }
          return ListView(
            children: [
              for (final message in state.items)
                ListTile(
                  title: Text(message.text),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, message),
                ),
              if (state.error != null)
                TextButton(
                  onPressed: () => cubit.load(more: state.cursor != null),
                  child: const Text('Retry'),
                ),
              if (state.cursor != null)
                TextButton(
                  onPressed: () => cubit.load(more: true),
                  child: const Text('More'),
                ),
            ],
          );
        },
      ),
    ),
  );
}
