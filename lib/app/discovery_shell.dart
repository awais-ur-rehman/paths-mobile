import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex:
          shell.currentIndex +
          (onCamera != null && shell.currentIndex >= (hasLikes ? 2 : 1)
              ? 1
              : 0),
      onDestinationSelected: (index) {
        final cameraIndex = hasLikes ? 2 : 1;
        if (onCamera != null && index == cameraIndex) {
          onCamera!();
          return;
        }
        final branch =
            index - (onCamera != null && index > cameraIndex ? 1 : 0);
        shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        if (hasLikes)
          const NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Likes',
          ),
        if (onCamera != null)
          const NavigationDestination(
            icon: Icon(Icons.add_a_photo_outlined),
            label: 'Camera',
          ),
        if (hasChats)
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}
