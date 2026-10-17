import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../../auth/domain/auth_models.dart';
import '../../media/presentation/media_scope.dart';
import '../../media/presentation/private_image.dart';
import 'posts_cubit.dart';

class PostsGrid extends StatefulWidget {
  const PostsGrid({required this.scope, required this.owner, super.key});
  final MediaScope scope;
  final String owner;
  @override
  State<PostsGrid> createState() => _PostsGridState();
}

class _PostsGridState extends State<PostsGrid> {
  late final cubit = PostsCubit(widget.scope.posts, widget.owner);
  late final AppLifecycleListener lifecycle;
  @override
  void initState() {
    super.initState();
    widget.scope.media.addListener(_revalidate);
    lifecycle = AppLifecycleListener(onResume: refresh);
    unawaited(cubit.load());
  }

  void refresh() {
    unawaited(widget.scope.media.purge());
  }

  void _revalidate() {
    unawaited(cubit.load());
  }

  @override
  void didUpdateWidget(PostsGrid old) {
    super.didUpdateWidget(old);
    if (old.key != widget.key) refresh();
  }

  @override
  void dispose() {
    widget.scope.media.removeListener(_revalidate);
    lifecycle.dispose();
    unawaited(cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<PostsCubit, PostsState>(
    bloc: cubit,
    builder: (context, state) {
      if (state.locked) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.lock_outline, color: Colors.white70),
              SizedBox(height: 8),
              Text('Private posts', style: TextStyle(color: Colors.white70)),
            ],
          ),
        );
      }
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Posts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                tooltip: 'Refresh posts',
                onPressed: state.loading ? null : refresh,
                icon: const Icon(Icons.refresh, color: Colors.white70),
              ),
            ],
          ),
          if (state.items.isEmpty && !state.loading && state.error == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No posts yet',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .8,
            ),
            itemBuilder: (context, index) {
              final post = state.items[index];
              return InkWell(
                onTap: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => PostDetail(
                      scope: widget.scope,
                      post: post,
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
              );
            },
          ),
          if (state.loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: PathsLoader(color: Colors.white),
            ),
          if (state.error != null)
            TextButton(
              onPressed: () => cubit.load(more: state.items.isNotEmpty),
              child: const Text('Retry'),
            ),
          if (state.cursor != null && !state.loading)
            TextButton(
              onPressed: () => cubit.load(more: true),
              child: const Text('More'),
            ),
        ],
      );
    },
  );
}

class PostDetail extends StatefulWidget {
  const PostDetail({
    required this.scope,
    required this.post,
    required this.own,
    super.key,
  });
  final MediaScope scope;
  final PostDto post;
  final bool own;
  @override
  State<PostDetail> createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {
  PostDto? post;
  AuthFailure? error;
  bool busy = false;
  CancelToken? token;
  int generation = 0;
  late final AppLifecycleListener lifecycle;
  @override
  void initState() {
    super.initState();
    widget.scope.media.addListener(_revalidateDetail);
    lifecycle = AppLifecycleListener(
      onPause: () {
        ++generation;
        token?.cancel();
        if (mounted) setState(() => post = null);
      },
      onResume: load,
    );
    unawaited(load());
  }

  void _revalidateDetail() {
    unawaited(load());
  }

  Future<void> load() async {
    token?.cancel();
    final request = token = CancelToken(), current = ++generation;
    setState(() {
      post = null;
      error = null;
    });
    try {
      final value = await widget.scope.posts.read(
        widget.post.id,
        cancelToken: request,
      );
      if (mounted && current == generation) setState(() => post = value);
    } catch (e) {
      if (mounted && current == generation) {
        setState(
          () => error = e is AuthFailure ? e : const AuthFailure('unavailable'),
        );
      }
    }
  }

  Future<void> remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.scope.posts.remove(widget.post.id);
      await widget.scope.media.purge();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        PathsToast.show(
          context,
          (e is AuthFailure ? e : const AuthFailure('unavailable')).message,
        );
      }
    }
  }

  @override
  void dispose() {
    ++generation;
    token?.cancel();
    widget.scope.media.removeListener(_revalidateDetail);
    lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .9,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          if (widget.own)
            IconButton(
              tooltip: 'Delete post',
              onPressed: busy ? null : remove,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: post == null
          ? Center(
              child: error == null
                  ? const PathsLoader()
                  : TextButton(
                      onPressed: load,
                      child: const Text('Photo unavailable. Retry'),
                    ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: post!.state == 'rejected'
                        ? const Center(child: Text('Not approved'))
                        : PrivateImage(
                            repository: widget.scope.media,
                            assetId: post!.assetId,
                            thumbnail: false,
                          ),
                  ),
                  if (post!.caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(post!.caption),
                    ),
                  if (post!.state == 'pending')
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('In review'),
                    ),
                ],
              ),
            ),
    ),
  );
}
