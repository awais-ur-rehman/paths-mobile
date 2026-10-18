import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../../shared/widgets/paths_avatar.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../domain/chat_repository.dart';
import 'chat_list_cubit.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({
    required this.repository,
    required this.onOpen,
    super.key,
  });
  final ChatRepository repository;
  final void Function(ConversationDto) onOpen;
  @override
  Widget build(BuildContext context) => _ChatsOwner(configuration: this);
}

class _ChatsOwner extends StatefulWidget {
  const _ChatsOwner({required this.configuration});
  final ChatsScreen configuration;
  @override
  State<_ChatsOwner> createState() => _ChatsOwnerState();
}

class _ChatsOwnerState extends State<_ChatsOwner> {
  late final cubit = ChatListCubit(widget.configuration.repository);
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
    unawaited(cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: const Text('Chats'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: cubit.load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: BlocBuilder<ChatListCubit, ChatListState>(
      bloc: cubit,
      builder: (context, state) {
        if (state.loading) return const Center(child: PathsLoader());
        if (state.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 40),
                const SizedBox(height: 16),
                Text(
                  state.error == null
                      ? 'Your conversations start here'
                      : state.error!.offline
                      ? 'You’re offline'
                      : 'Could not load chats',
                ),
                if (state.error != null)
                  TextButton(onPressed: cubit.load, child: const Text('Retry')),
              ],
            ),
          );
        }
        return Column(
          children: [
            if (state.error != null)
              MaterialBanner(
                content: Text(
                  state.error!.offline ? 'You’re offline' : 'Could not refresh',
                ),
                actions: [
                  TextButton(onPressed: cubit.load, child: const Text('Retry')),
                ],
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: cubit.load,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 84),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      leading: PathsAvatar(
                        size: 48,
                        assetId: item.avatarAssetId,
                      ),
                      title: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: item.unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        item.lastText ??
                            (item.canSend ? 'Say hello' : 'Connection ended'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: item.unreadCount > 0
                          ? Badge(label: Text('${item.unreadCount}'))
                          : item.canSend
                          ? null
                          : const Icon(Icons.lock_outline, size: 18),
                      onTap: () => widget.configuration.onOpen(item),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
