import '../../safety/presentation/safety_scope.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_avatar.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../data/relationship_repository.dart';
import 'likes_cubit.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({
    required this.repository,
    required this.onProfile,
    super.key,
  });
  final RelationshipRepository repository;
  final Future<void> Function(String) onProfile;
  @override
  State<LikesScreen> createState() => _LikesState();
}

class _LikesState extends State<LikesScreen> {
  late final cubit = LikesCubit(widget.repository);
  AppLifecycleListener? _lifecycle;
  bool _active = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_active) unawaited(cubit.load());
    _active = active;
  }

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(cubit.load()));
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    unawaited(cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafetyRefresh(
    onChanged: () => unawaited(cubit.invalidate()),
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Likes'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Connections',
            onSelected: (value) => cubit.load(box: value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'connections', child: Text('Connections')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<LikesCubit, LikesState>(
        bloc: cubit,
        builder: (context, state) => Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (final box in ['saved', 'incoming', 'sent'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          {
                            'saved': 'Saved',
                            'incoming': 'Incoming',
                            'sent': 'Sent',
                          }[box]!,
                        ),
                        selected: state.box == box,
                        onSelected: (_) => cubit.load(box: box),
                      ),
                    ),
                ],
              ),
            ),
            if (state.box == 'connections')
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Connections'),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => cubit.load(),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (state.busy && state.items.isEmpty)
                      const Center(child: PathsLoader()),
                    if (state.error != null)
                      Column(
                        children: [
                          Text(
                            state.error!.offline
                                ? 'You’re offline'
                                : 'Could not load Likes',
                          ),
                          TextButton(
                            onPressed: () => cubit.load(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    if (!state.busy &&
                        state.error == null &&
                        state.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Nothing here yet')),
                      ),
                    for (final item in state.items)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: PathsAvatar(
                          size: 48,
                          assetId: item.avatarAssetId,
                        ),
                        title: Text(
                          item.available
                              ? item.displayName
                              : 'Profile unavailable',
                        ),
                        subtitle: Text(
                          item.available
                              ? (item.state == 'none'
                                    ? '@${item.username}'
                                    : {
                                            'pending':
                                                item.direction == 'incoming'
                                                ? 'Wants to connect'
                                                : 'Request sent',
                                            'accepted': 'Connected',
                                            'declined': 'Declined',
                                            'cancelled': 'Cancelled',
                                            'expired': 'Expired',
                                            'disconnected': 'Disconnected',
                                          }[item.state] ??
                                          'Unavailable')
                              : 'Unavailable',
                        ),
                        trailing: !item.available && state.box == 'saved'
                            ? IconButton(
                                tooltip: 'Remove saved profile',
                                icon: const Icon(
                                  Icons.bookmark_remove_outlined,
                                ),
                                onPressed: () async {
                                  try {
                                    await widget.repository.save(
                                      item.targetId,
                                      false,
                                    );
                                    await cubit.load();
                                  } catch (error) {
                                    if (context.mounted) {
                                      PathsToast.show(
                                        context,
                                        'Could not remove. Retry.',
                                      );
                                    }
                                  }
                                },
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: !item.available
                            ? null
                            : () async {
                                await widget.onProfile(item.targetId);
                                if (mounted) await cubit.load();
                              },
                      ),
                    if (state.cursor != null)
                      TextButton(
                        onPressed: state.busy
                            ? null
                            : () => cubit.load(more: true),
                        child: state.busy
                            ? const PathsLoader()
                            : const Text('Load more'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
