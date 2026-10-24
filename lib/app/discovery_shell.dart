import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/widgets/paths_bottom_navigation.dart';

class DiscoveryShell extends StatelessWidget {
  const DiscoveryShell({
    required this.shell,
    this.hasLikes = false,
    this.hasChats = false,
    this.onCamera,
    super.key,
  });
  final StatefulNavigationShell shell;
  final bool hasLikes, hasChats;
  final VoidCallback? onCamera;
  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: shell,
    bottomNavigationBar: PathsBottomNavigationBar(
      selectedIndex: shell.currentIndex,
      onSelected: (branch) =>
          shell.goBranch(branch, initialLocation: branch == shell.currentIndex),
      onCamera: onCamera,
      items: [
        PathsNavItem.home,
        if (hasLikes) PathsNavItem.likes,
        if (hasChats) PathsNavItem.chats,
        PathsNavItem.profile,
      ],
    ),
  );
}
