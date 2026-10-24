import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../safety/presentation/report_sheet.dart';
import '../../safety/domain/safety_repository.dart';
import 'chat_bloc.dart';
import 'chat_style.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({
    required this.accountId,
    required this.controller,
    super.key,
  });
  final String? accountId;
  final ScrollController controller;
  @override
  Widget build(BuildContext context) => BlocBuilder<ChatBloc, ChatState>(
    buildWhen: (a, b) =>
        a.messages != b.messages ||
        a.pending != b.pending ||
        a.loading != b.loading ||
        a.available != b.available ||
        a.loadingOlder != b.loadingOlder ||
        a.olderFailed != b.olderFailed ||
        a.error != b.error,
    builder: (context, state) {
      if (state.loading) {
        return const Center(child: PathsLoader());
      }
      if (!state.available) {
        return const Center(
          child: Text(
            'Conversation unavailable',
            style: TextStyle(color: Colors.white),
          ),
        );
      }
      if (state.messages.isEmpty && state.pending.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.error?.offline == true ? 'You’re offline' : 'Say hello',
                style: const TextStyle(color: Colors.white),
              ),
              if (state.error != null)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () =>
                      context.read<ChatBloc>().add(const ChatRefresh()),
                  child: const Text('Retry'),
                ),
            ],
          ),
        );
      }
      final count = state.messages.length + state.pending.length;
      return Column(
        children: [
          if (state.error != null &&
              state.error!.code != 'cancelled' &&
              state.error!.code != 'CONTENT_REVIEW_REQUIRED' &&
              !state.pending.any((p) => p.failed))
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => context.read<ChatBloc>().add(
                state.olderFailed ? const ChatOlder() : const ChatRefresh(),
              ),
              child: Text(
                state.olderFailed
                    ? 'Could not load earlier · Retry'
                    : 'Could not sync · Retry',
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: count + (state.loadingOlder ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == count) {
                  return const Center(child: PathsLoader());
                }
                final position = count - 1 - index;
                if (position < state.messages.length) {
                  final message = state.messages[position];
                  return GestureDetector(
                    key: ValueKey(message.id),
                    onLongPress: message.senderId == accountId
                        ? null
                        : () => showSafetyActions(
                            context,
                            SafetyTarget(
                              message.senderId,
                              kind: 'message',
                              contentId: message.id,
                            ),
                          ),
                    child: _Bubble(
                      text: message.text,
                      mine: message.senderId == accountId,
                      createdAt: message.createdAt,
                    ),
                  );
                }
                final pending = state.pending[position - state.messages.length];
                return _Bubble(
                  key: ValueKey(pending.clientId),
                  text: pending.text,
                  mine: true,
                  status: pending.failed ? 'Not sent · Retry' : 'Sending…',
                  onRetry: pending.failed
                      ? () => context.read<ChatBloc>().add(
                          ChatSend(pending.text, clientId: pending.clientId),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.mine,
    this.status,
    this.onRetry,
    this.createdAt,
    super.key,
  });
  final String text;
  final bool mine;
  final String? status, createdAt;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .78,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: mine ? const Color(0xFF074A83) : const Color(0xFFF4FAFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        color: mine ? Colors.white : const Color(0xFF101418),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        messageTimestamp(context, createdAt!),
                        style: TextStyle(
                          color: mine
                              ? const Color(0xFFD7EAF9)
                              : const Color(0xFF52616D),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (status != null)
              onRetry != null
                  ? TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onRetry,
                      child: Text(status!),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4),
                      child: Text(
                        status!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
          ],
        ),
      ),
    ),
  );
}
