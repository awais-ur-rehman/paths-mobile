import 'package:flutter/material.dart';

import '../../app/theme/paths_tokens.dart';

class PathsAvatar extends StatelessWidget {
  const PathsAvatar({this.size = 104, super.key});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Profile photo unavailable',
    child: CircleAvatar(
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
