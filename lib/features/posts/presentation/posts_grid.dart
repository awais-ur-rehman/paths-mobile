import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_icon.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../media/presentation/media_scope.dart';
import '../../media/presentation/private_image.dart';
import 'posts_cubit.dart';
import 'post_detail.dart';
export 'post_detail.dart' show PostDetail;

/// A lazy profile sliver; scope/account changes replace its lifecycle owner.
class PostsGrid extends StatelessWidget {
  const PostsGrid({required this.scope, required this.owner, super.key});
  final MediaScope scope;
  final String owner;
  @override
  Widget build(BuildContext context) => _PostsOwner(
    key: ValueKey((scope.media, scope.posts, scope.posts.accountId, owner)),
    scope: scope,
    owner: owner,
  );
}

class _PostsOwner extends StatefulWidget {
  const _PostsOwner({required this.scope, required this.owner, super.key});
  final MediaScope scope;
  final String owner;
  @override
  State<_PostsOwner> createState() => _PostsOwnerState();
}

class _PostsOwnerState extends State<_PostsOwner> {
  late final cubit = PostsCubit(widget.scope.posts, widget.owner);
  late final AppLifecycleListener lifecycle;
  ScrollNotificationObserverState? observer;
  @override
  void initState() {
    super.initState();
    widget.scope.media.addListener(_reload);
    lifecycle = AppLifecycleListener(onResume: refresh);
    unawaited(cubit.load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ScrollNotificationObserver.maybeOf(context);
    if (observer != current) {
      observer?.removeListener(_scroll);
      observer = current;
      observer?.addListener(_scroll);
    }
  }

  void refresh() => unawaited(widget.scope.media.purge());
  void _reload() => unawaited(cubit.load());
  void _scroll(ScrollNotification event) {
    if ((event is ScrollUpdateNotification || event is ScrollEndNotification) &&
        event.depth == 0 &&
        event.metrics.pixels > 0 &&
        event.metrics.maxScrollExtent > 0 &&
        event.metrics.extentAfter < 360 &&
        cubit.state.error == null) {
      unawaited(cubit.load(more: true));
    }
  }

  @override
  void dispose() {
    observer?.removeListener(_scroll);
    widget.scope.media.removeListener(_reload);
    lifecycle.dispose();
    unawaited(cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<PostsCubit, PostsState>(
    bloc: cubit,
    builder: (context, state) {
      if (state.locked) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                PathsIcon(PathsIconName.lock, color: Colors.white70),
                SizedBox(height: 8),
                Text('Private photos', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        );
      }
      return SliverMainAxisGroup(
        slivers: [
          if (state.items.isEmpty && !state.loading && state.error == null)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No photos yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          SliverGrid.builder(
            itemCount: state.items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .8,
            ),
            itemBuilder: (context, index) {
              final post = state.items[index];
              return Semantics(
                label: 'Photo ${index + 1}',
                button: true,
                child: InkWell(
                  onTap: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => PostDetail(
                        scope: widget.scope,
                        post: post,
                        owner: widget.owner,
                        own: widget.owner == widget.scope.posts.accountId,
                      ),
                    );
                    if (mounted) refresh();
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (post.state != 'rejected')
                          PrivateImage(
                            repository: widget.scope.media,
                            assetId: post.assetId,
                          ),
                        if (post.state != 'published')
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              color: Colors.black54,
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                post.state == 'pending'
                                    ? 'In review'
                                    : 'Not approved',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (state.loading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: PathsLoader(color: Colors.white),
                  ),
                if (state.error != null)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => cubit.load(more: state.cursor != null),
                    child: Text(
                      state.error!.offline
                          ? 'You’re offline · Retry'
                          : 'Could not load photos · Retry',
                    ),
                  ),
                if (state.cursor != null &&
                    !state.loading &&
                    state.error == null)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => cubit.load(more: true),
                    child: const Text('More photos'),
                  ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
