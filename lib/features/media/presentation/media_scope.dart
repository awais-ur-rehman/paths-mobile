import 'package:flutter/widgets.dart';

import '../data/http_media_repository.dart';
import '../domain/media_repository.dart';
import '../../posts/data/post_repository.dart';

class MediaScope extends InheritedWidget {
  const MediaScope({
    required this.media,
    required this.picker,
    required this.posts,
    required super.child,
    super.key,
  });
  final HttpMediaRepository media;
  final PhotoPicker picker;
  final PostRepository posts;
  static MediaScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MediaScope>();
  @override
  bool updateShouldNotify(MediaScope old) =>
      old.media != media || old.picker != picker || old.posts != posts;
}
