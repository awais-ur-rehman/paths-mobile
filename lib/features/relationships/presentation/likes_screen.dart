import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../../media/presentation/media_scope.dart';
import '../../safety/presentation/safety_scope.dart';
import '../data/relationship_repository.dart';
import 'likes_cubit.dart';
import 'likes_header.dart';
import 'likes_card.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({
    required this.repository,
    required this.onProfile,
    super.key,
  });
  final RelationshipRepository repository;
  final Future<void> Function(String) onProfile;
  @override
  Widget build(BuildContext context) => _LikesOwner(
    key: ValueKey((repository, repository.accountId)),
    configuration: this,
  );
}

class _LikesOwner extends StatefulWidget {
  const _LikesOwner({required this.configuration, super.key});
  final LikesScreen configuration;
  @override
  State<_LikesOwner> createState() => _LikesState();
}

class _LikesState extends State<_LikesOwner> {
  late final cubit = LikesCubit(widget.configuration.repository);
  final search = TextEditingController();
  AppLifecycleListener? lifecycle;
  bool active = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = TickerMode.valuesOf(context).enabled;
    if (current && !active) unawaited(cubit.load());
    active = current;
  }

  @override
  void initState() {
    super.initState();
    lifecycle = AppLifecycleListener(
      onResume: () {
        if (active) unawaited(cubit.load());
      },
    );
  }

  @override
  void dispose() {
    lifecycle?.dispose();
    search.dispose();
    unawaited(cubit.close());
    super.dispose();
  }

  Future<void> refresh() async {
    await MediaScope.maybeOf(context)?.media.purge();
    await cubit.load();
  }

  Future<void> remove(String target) async {
    try {
      await cubit.removeSaved(target);
    } catch (_) {
      if (mounted && active) {
        PathsToast.show(context, 'Could not remove. Retry.');
      }
    }
  }

  Future<void> open(String target) async {
    await widget.configuration.onProfile(target);
    if (mounted && active) await cubit.load();
  }

  @override
  Widget build(BuildContext context) => SafetyRefresh(
    onChanged: () => unawaited(cubit.invalidate()),
    child: Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (event) {
            if ((event is ScrollUpdateNotification ||
                    event is ScrollEndNotification) &&
                event.depth == 0 &&
                event.metrics.pixels > 0 &&
                event.metrics.extentAfter < 280 &&
                cubit.state.error == null) {
              unawaited(cubit.load(more: true));
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: LikesHeader(cubit: cubit, controller: search),
              ),
              BlocBuilder<LikesCubit, LikesState>(
                bloc: cubit,
                builder: (context, state) {
                  if (state.items.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: state.busy
                              ? const PathsLoader()
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      state.error != null
                                          ? (state.error!.offline
                                                ? 'You’re offline'
                                                : 'Could not load Likes')
                                          : state.filtered
                                          ? 'No matches'
                                          : switch (state.box) {
                                              'incoming' => 'No requests yet',
                                              'sent' => 'No sent requests yet',
                                              'connections' =>
                                                'No connections yet',
                                              _ => 'No saved profiles yet',
                                            },
                                      textAlign: TextAlign.center,
                                    ),
                                    if (state.error != null)
                                      TextButton(
                                        onPressed: cubit.retry,
                                        child: const Text('Retry'),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  }
                  final scale = MediaQuery.textScalerOf(context)
                      .scale(1)
                      .clamp(1.0, 1.6);
                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      4,
                      20,
                      24 + MediaQuery.paddingOf(context).bottom,
                    ),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverGrid.builder(
                          itemCount: state.items.length,
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 260,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: .76 / scale,
                              ),
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return LikesCard(
                              key: ValueKey(item.id),
                              item: item,
                              onOpen: () => unawaited(open(item.targetId)),
                              onRemove:
                                  !item.available &&
                                      state.box == 'saved' &&
                                      state.removing == null
                                  ? () => unawaited(remove(item.targetId))
                                  : null,
                              removing: state.removing == item.targetId,
                            );
                          },
                        ),
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              if (state.busy)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: PathsLoader(),
                                ),
                              if (state.error != null)
                                TextButton(
                                  onPressed: cubit.retry,
                                  child: Text(
                                    state.error!.offline
                                        ? 'You’re offline · Retry'
                                        : 'Could not refresh · Retry',
                                  ),
                                ),
                              if (state.cursor != null &&
                                  !state.busy &&
                                  state.error == null)
                                TextButton(
                                  onPressed: () => cubit.load(more: true),
                                  child: const Text('More profiles'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
