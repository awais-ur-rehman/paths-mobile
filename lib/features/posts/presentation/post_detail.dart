import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../../auth/domain/auth_models.dart';
import '../../media/presentation/media_scope.dart';
import '../../media/presentation/private_image.dart';
import '../../safety/presentation/report_sheet.dart';
import '../../safety/domain/safety_repository.dart';

class PostDetail extends StatefulWidget {
  const PostDetail({
    required this.scope,
    required this.post,
    required this.own,
    required this.owner,
    super.key,
  });
  final MediaScope scope;
  final PostDto post;
  final bool own;
  final String owner;
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
          if (!widget.own)
            SafetyMenuButton(
              target: SafetyTarget(
                widget.owner,
                kind: 'post',
                contentId: widget.post.id,
              ),
            ),
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
