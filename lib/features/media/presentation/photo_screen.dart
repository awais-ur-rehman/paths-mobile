import 'package:go_router/go_router.dart';

import '../../reviews/presentation/review_screen.dart';

import 'dart:async';

import 'raw_photo.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../../posts/data/post_repository.dart';
import '../../posts/presentation/post_publish_cubit.dart';
import '../domain/media_repository.dart';
import 'upload_cubit.dart';

class PhotoScreen extends StatefulWidget {
  const PhotoScreen({
    required this.media,
    required this.picker,
    required this.kind,
    required this.onReady,
    required this.onCancel,
    this.posts,
    super.key,
  });
  final MediaRepository media;
  final PhotoPicker picker;
  final MediaKind kind;
  final PostRepository? posts;
  final ValueChanged<String> onReady;
  final VoidCallback onCancel;
  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  late final upload = UploadCubit(widget.media, widget.picker, widget.kind);
  late final publish = widget.posts == null
      ? null
      : PostPublishCubit(widget.posts!);
  final caption = TextEditingController();
  bool leaving = false;
  Future<void> _cancel() async {
    if (leaving || publish?.state.busy == true) return;
    if (upload.state.photo != null) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    leaving = true;
    await upload.cancel();
    if (!mounted) return;
    if (upload.state.error case final error?) {
      PathsToast.show(context, error.message);
    }
    widget.onCancel();
  }

  void _ready(UploadState state) {
    if (!state.busy && state.asset?.ready == true && state.error == null) {
      if (widget.kind == MediaKind.post) {
        unawaited(publish!.publish(state.asset!.id, caption.text));
      } else {
        upload.release();
        widget.onReady(state.asset!.id);
      }
    }
  }

  @override
  void dispose() {
    unawaited(upload.close());
    unawaited(publish?.close());
    caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: leaving,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) unawaited(_cancel());
    },
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(switch (widget.kind) {
          MediaKind.avatar => 'Profile photo',
          MediaKind.cnicFront => 'CNIC front',
          MediaKind.cnicBack => 'CNIC back',
          MediaKind.post => 'New post',
        }),
        leading: IconButton(
          onPressed: publish?.state.busy == true ? null : _cancel,
          icon: const Icon(Icons.close),
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<UploadCubit, UploadState>(
            bloc: upload,
            listener: (context, state) {
              if (state.error case final error?) {
                PathsToast.show(context, error.message);
              } else {
                _ready(state);
              }
            },
          ),
          if (publish != null)
            BlocListener<PostPublishCubit, PostPublishState>(
              bloc: publish!,
              listener: (context, state) {
                setState(() {});
                if (state.error case final error?) {
                  PathsToast.show(context, error.message);
                }
                if (state.postId != null) {
                  upload.release();
                  widget.onReady(state.postId!);
                }
              },
            ),
        ],
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: BlocBuilder<UploadCubit, UploadState>(
                  bloc: upload,
                  builder: (context, state) {
                    final photo = state.photo;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 3 / 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: photo == null
                                ? const ColoredBox(
                                    color: Color(0xFFF3F4F5),
                                    child: Center(
                                      child: Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 56,
                                      ),
                                    ),
                                  )
                                : RawPhoto(bytes: photo.bytes),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (widget.kind == MediaKind.post && photo != null)
                          TextField(
                            controller: caption,
                            readOnly: state.busy || publish?.state.busy == true,
                            maxLength: 500,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Add a caption (optional)',
                            ),
                          ),
                        if (publish?.state.error?.code ==
                            'CONTENT_REVIEW_REQUIRED')
                          TextButton(
                            onPressed: () => context.push(
                              '/reviews',
                              extra: ReviewDraft(
                                kind: 'caption',
                                content: caption.text,
                              ),
                            ),
                            child: const Text('Request review'),
                          ),
                        if (state.busy)
                          Center(
                            child: Column(
                              children: [
                                const PathsLoader(),
                                if (state.progress > 0 && state.progress < 1)
                                  Text('${(state.progress * 100).round()}%'),
                              ],
                            ),
                          ),
                        if (!state.busy)
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: publish?.state.busy == true
                                    ? null
                                    : () => upload.pick(PhotoSource.camera),
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: Text(
                                  photo == null ? 'Camera' : 'Retake',
                                ),
                              ),
                              TextButton.icon(
                                onPressed: publish?.state.busy == true
                                    ? null
                                    : () => upload.pick(PhotoSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Gallery'),
                              ),
                            ],
                          ),
                        if (photo != null) ...[
                          const SizedBox(height: 16),
                          if (publish == null)
                            _button(state, false)
                          else
                            BlocBuilder<PostPublishCubit, PostPublishState>(
                              bloc: publish!,
                              buildWhen: (a, b) => a.busy != b.busy,
                              builder: (context, publishing) =>
                                  _button(state, publishing.busy),
                            ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget _button(UploadState state, bool publishing) => FilledButton(
    onPressed: state.busy || publishing
        ? null
        : () => state.asset?.ready == true ? _ready(state) : upload.upload(),
    child: state.busy || publishing
        ? const PathsLoader(size: 26, color: Colors.white)
        : Text(
            state.error != null
                ? 'Retry'
                : widget.kind == MediaKind.post
                ? 'Post'
                : 'Use photo',
          ),
  );
}
