import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/paths_icon.dart';
import '../../media/presentation/media_scope.dart';
import '../../posts/presentation/posts_grid.dart';
import '../domain/profile_repository.dart';
import 'profile_hero.dart';

/// Shared composition; owner/member actions are supplied by their guarded screens.
class ProfileSurface extends StatelessWidget {
  const ProfileSurface({
    required this.profile,
    this.onBack,
    this.menu,
    this.action,
    this.onRefresh,
    super.key,
  });
  final ProfileSummary profile;
  final VoidCallback? onBack;
  final Widget? menu, action;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final scope = MediaScope.maybeOf(context);
        final scroll = CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ProfileHero(
                profile: profile,
                viewportHeight: constraints.maxHeight,
                action: action,
              ),
            ),
            if (scope != null)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  32 + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: PostsGrid(scope: scope, owner: profile.userId),
              ),
          ],
        );
        return ColoredBox(
          color: profileInk,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ScrollNotificationObserver(
                child: onRefresh == null
                    ? scroll
                    : RefreshIndicator(onRefresh: onRefresh!, child: scroll),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ProfileHeader(onBack: onBack, menu: menu),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    this.onBack,
    this.menu,
    this.foregroundColor = Colors.white,
    super.key,
  });
  final VoidCallback? onBack;
  final Widget? menu;
  final Color foregroundColor;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Spacer(),
          if (menu != null)
            menu!
          else if (onBack != null)
            ProfileCoverButton(
              label: 'Back',
              icon: PathsIconName.back,
              onPressed: onBack!,
              color: foregroundColor,
            ),
        ],
      ),
    ),
  );
}

class ProfileSettingsButton extends StatelessWidget {
  const ProfileSettingsButton({
    required this.onPressed,
    this.color = Colors.white,
    super.key,
  });
  final VoidCallback onPressed;
  final Color color;
  @override
  Widget build(BuildContext context) => ProfileCoverButton(
    label: 'Settings',
    icon: PathsIconName.settings,
    onPressed: onPressed,
    color: color,
  );
}

class ProfileCoverButton extends StatelessWidget {
  const ProfileCoverButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
    super.key,
  });
  final String label;
  final PathsIconName icon;
  final VoidCallback onPressed;
  final Color color;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: label,
    onPressed: onPressed,
    icon: PathsIcon(icon, size: 24),
    style: IconButton.styleFrom(
      backgroundColor: color == Colors.white
          ? const Color(0x660B1824)
          : color.withValues(alpha: .08),
      foregroundColor: color,
      minimumSize: const Size(48, 48),
    ),
  );
}
