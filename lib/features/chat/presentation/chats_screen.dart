import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../../shared/widgets/paths_avatar.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../domain/chat_repository.dart';
import 'chat_list_cubit.dart';
import 'chat_style.dart';
import 'chat_list_header.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({
    required this.repository,
    required this.onOpen,
    super.key,
  });
  final ChatRepository repository;
  final void Function(ConversationDto) onOpen;
  @override
  Widget build(BuildContext context) =>
      _ChatsOwner(key: ValueKey(repository.accountId), configuration: this);
}

class _ChatsOwner extends StatefulWidget {
  const _ChatsOwner({required this.configuration, super.key});
  final ChatsScreen configuration;
  @override
  State<_ChatsOwner> createState() => _ChatsOwnerState();
}

class _ChatsOwnerState extends State<_ChatsOwner> {
  late final cubit = ChatListCubit(widget.configuration.repository);
  final search = TextEditingController();
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
    search.dispose();
    unawaited(cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: RefreshIndicator(
      onRefresh: cubit.load,
      child: NotificationListener<ScrollNotification>(
        onNotification: (event) {
          if (event.depth == 0 && event.metrics.extentAfter < 280) {
            unawaited(cubit.more());
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ChatListHeader(
                controller: search,
                cubit: cubit,
                onSearch: cubit.search,
                onOpen: widget.configuration.onOpen,
              ),
            ),
            BlocBuilder<ChatListCubit, ChatListState>(
              bloc: cubit,
              buildWhen: (a, b) =>
                  a.items != b.items ||
                  a.loading != b.loading ||
                  a.error != b.error ||
                  a.loadingMore != b.loadingMore ||
                  a.moreError != b.moreError ||
                  a.query != b.query,
              builder: (context, state) {
                if (state.loading) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: PathsLoader()),
                  );
                }
                if (state.items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.error != null
                                  ? (state.error!.offline
                                        ? 'You’re offline'
                                        : 'Could not load conversations')
                                  : state.query.isNotEmpty
                                  ? 'No conversations found'
                                  : 'Your conversations start here',
                              textAlign: TextAlign.center,
                            ),
                            if (state.error != null)
                              TextButton(
                                onPressed: cubit.load,
                                child: const Text('Retry'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    16,
                    12,
                    16 + MediaQuery.paddingOf(context).bottom,
                  ),
                  sliver: SliverList.builder(
                    itemCount: state.items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == state.items.length) {
                        return Column(
                          children: [
                            if (state.error != null)
                              TextButton(
                                onPressed: cubit.load,
                                child: Text(
                                  state.error!.offline
                                      ? 'You’re offline · Retry'
                                      : 'Could not refresh · Retry',
                                ),
                              ),
                            if (state.loadingMore)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: PathsLoader(),
                              ),
                            if (state.moreError != null)
                              TextButton(
                                onPressed: () => cubit.more(retry: true),
                                child: const Text(
                                  'Could not load more · Retry',
                                ),
                              ),
                          ],
                        );
                      }
                      final item = state.items[index];
                      return _ConversationRow(
                        key: ValueKey(item.id),
                        item: item,
                        onTap: () => widget.configuration.onOpen(item),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.item, required this.onTap, super.key});
  final ConversationDto item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Row(
        children: [
          PathsAvatar(size: 54, assetId: item.avatarAssetId),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: item.unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      chatTimestamp(context, item.updatedAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF52616D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.lastText ??
                            (item.canSend ? 'Say hello' : 'Connection ended'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF52616D),
                        ),
                      ),
                    ),
                    if (item.unreadCount > 0)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          constraints: const BoxConstraints(minWidth: 22),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B5AA1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.unreadCount > 99
                                ? '99+'
                                : '${item.unreadCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
