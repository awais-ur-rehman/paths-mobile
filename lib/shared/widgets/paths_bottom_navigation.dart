import 'package:flutter/material.dart';

import '../../app/theme/paths_theme.dart';
import 'paths_icon.dart';

enum PathsNavItem {
  home('Home', PathsIconName.home),
  likes('Likes', PathsIconName.likes),
  chats('Chats', PathsIconName.chats),
  profile('Profile', PathsIconName.profile);

  const PathsNavItem(this.label, this.icon);
  final String label;
  final PathsIconName icon;
}

class PathsBottomNavigationBar extends StatelessWidget {
  const PathsBottomNavigationBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.onCamera,
    super.key,
  });
  final List<PathsNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onCamera;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    final camera = onCamera != null;
    final split = (items.length / 2).ceil();
    Widget tab(int index) {
      final item = items[index];
      final selected = selectedIndex == index;
      return Expanded(
        child: MergeSemantics(
          child: Semantics(
            label: item.label,
            selected: selected,
            child: SizedBox(
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: IconButton(
                      tooltip: item.label,
                      onPressed: () => onSelected(index),
                      style: IconButton.styleFrom(
                        foregroundColor: PathsTheme.blue,
                      ),
                      icon: PathsIcon(
                        item.icon,
                        color: selected ? PathsTheme.blue : PathsTheme.ink,
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      bottom: 7,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: PathsTheme.blue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const SizedBox(width: 14, height: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Align(
          heightFactor: 1,
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SizedBox(
              height: camera ? 104 : 76,
              child: Stack(
                children: [
                  Positioned.fill(
                    top: camera ? 28 : 0,
                    child: Material(
                      color: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(0x24101418),
                      shape: _NavigationShape(notched: camera),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            if (camera) ...[
                              Expanded(
                                child: Row(
                                  children: [
                                    for (var i = 0; i < split; i++) tab(i),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 72),
                              Expanded(
                                child: Row(
                                  children: [
                                    for (var i = split; i < items.length; i++)
                                      tab(i),
                                  ],
                                ),
                              ),
                            ] else ...[
                              for (var i = 0; i < items.length; i++) tab(i),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (camera)
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox.square(
                        dimension: 56,
                        child: Material(
                          color: PathsTheme.blue,
                          elevation: 3,
                          shadowColor: const Color(0x24101418),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Camera',
                            onPressed: onCamera,
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: const CircleBorder(),
                            ),
                            icon: const PathsIcon(
                              PathsIconName.plus,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationShape extends ShapeBorder {
  const _NavigationShape({required this.notched});
  final bool notched;
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  ShapeBorder scale(double t) => this;
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    if (!notched) {
      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(34)));
    }
    final x = rect.center.dx, top = rect.top;
    return Path()
      ..moveTo(rect.left + 34, top)
      ..lineTo(x - 64, top)
      ..cubicTo(x - 40, top, x - 32, top + 34, x, top + 34)
      ..cubicTo(x + 32, top + 34, x + 40, top, x + 64, top)
      ..lineTo(rect.right - 34, top)
      ..quadraticBezierTo(rect.right, top, rect.right, top + 34)
      ..lineTo(rect.right, rect.bottom - 34)
      ..quadraticBezierTo(rect.right, rect.bottom, rect.right - 34, rect.bottom)
      ..lineTo(rect.left + 34, rect.bottom)
      ..quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - 34)
      ..lineTo(rect.left, top + 34)
      ..quadraticBezierTo(rect.left, top, rect.left + 34, top)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
}
