import 'package:flutter/material.dart';

@immutable
class PathsTokens extends ThemeExtension<PathsTokens> {
  const PathsTokens({
    this.line = const Color(0xFFD8E4EC),
    this.muted = const Color(0xFF52616D),
    this.softSurface = const Color(0xFFDDF4FF),
  });
  final Color line, muted, softSurface;
  static const inputRadius = 14.0,
      cardRadius = 24.0,
      sheetRadius = 32.0,
      maxFormWidth = 480.0;
  static double gutter(double width) => width < 360 ? 16 : 20;
  @override
  PathsTokens copyWith({Color? line, Color? muted, Color? softSurface}) =>
      PathsTokens(
        line: line ?? this.line,
        muted: muted ?? this.muted,
        softSurface: softSurface ?? this.softSurface,
      );
  @override
  PathsTokens lerp(covariant PathsTokens? other, double t) => other == null
      ? this
      : PathsTokens(
          line: Color.lerp(line, other.line, t)!,
          muted: Color.lerp(muted, other.muted, t)!,
          softSurface: Color.lerp(softSurface, other.softSurface, t)!,
        );
}
