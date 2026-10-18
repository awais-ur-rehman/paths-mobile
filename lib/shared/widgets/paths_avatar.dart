import '../../features/media/presentation/media_scope.dart';
import '../../features/media/presentation/private_image.dart';

import 'package:flutter/material.dart';

import '../../app/theme/paths_tokens.dart';

class PathsAvatar extends StatelessWidget {
  const PathsAvatar({this.size = 104, this.assetId, super.key});
  final double size;
  final String? assetId;
  @override
  Widget build(BuildContext context) => Semantics(
    label: assetId == null ? 'Profile photo unavailable' : 'Profile photo',
    child: assetId != null && MediaScope.maybeOf(context) != null
        ? SizedBox(
            width: size,
            height: size,
            child: ClipOval(
              child: PrivateImage(
                repository: MediaScope.maybeOf(context)!.media,
                assetId: assetId!,
              ),
            ),
          )
        : CircleAvatar(
            radius: size / 2,
            backgroundColor:
                Theme.of(context).extension<PathsTokens>()?.softSurface ??
                const Color(0xFFDDF4FF),
            child: Icon(
              Icons.person_outline,
              size: size * .46,
              color: const Color(0xFF075A9E),
            ),
          ),
  );
}
