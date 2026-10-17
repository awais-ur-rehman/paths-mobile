import '../../media/presentation/media_scope.dart';
import '../../media/presentation/private_image.dart';
import '../../posts/presentation/posts_grid.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/widgets/verification_badge.dart';
import '../domain/profile_repository.dart';

/// The shared portrait/identity composition for owner and eligible peer profiles.
class ProfileSurface extends StatelessWidget {
  const ProfileSurface({
    required this.profile,
    this.onBack,
    this.menu,
    this.action,
    super.key,
  });
  final ProfileSummary profile;
  final VoidCallback? onBack;
  final Widget? menu, action;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final coverHeight = (constraints.maxHeight * .56).clamp(320.0, 540.0);
      return ColoredBox(
        color: const Color(0xFF292A2F),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF8D969C),
                      const Color(0xFF454950),
                      const Color(0xFF292A2F),
                    ],
                    stops: const [0, .58, 1],
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: coverHeight,
                        child:
                            profile.avatarAssetId != null &&
                                MediaScope.maybeOf(context) != null
                            ? PrivateImage(
                                repository: MediaScope.maybeOf(context)!.media,
                                assetId: profile.avatarAssetId!,
                                thumbnail: false,
                              )
                            : Center(
                                child: Semantics(
                                  label: profile.photoState == 'pending'
                                      ? 'Profile photo awaiting review'
                                      : 'Profile photo unavailable',
                                  child: ExcludeSemantics(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person_outline_rounded,
                                          size: math.min(
                                            constraints.maxWidth * .64,
                                            280,
                                          ),
                                          color: Colors.white.withValues(
                                            alpha: .24,
                                          ),
                                        ),
                                        Text(
                                          profile.photoState == 'pending'
                                              ? 'Photo in review'
                                              : 'No photo yet',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${profile.name}, ${profile.age}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 34,
                                height: 1.15,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '@${profile.username}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFD5D7DB),
                                fontSize: 17,
                              ),
                            ),
                            if (profile.verificationStatus != 'none')
                              Center(
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        disabledForegroundColor: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  child: VerificationBadge(
                                    status: profile.verificationStatus,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  profile.visibility == 'private'
                                      ? Icons.lock_outline
                                      : Icons.public_outlined,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  profile.visibility == 'private'
                                      ? 'Private profile'
                                      : 'Public profile',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (action != null) ...[
                              const SizedBox(height: 24),
                              action!,
                            ],
                            if (profile.bio.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: .16),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .14),
                                  ),
                                ),
                                child: Text(
                                  profile.bio,
                                  style: const TextStyle(
                                    color: Color(0xFFF1F2F4),
                                    fontSize: 16,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                            if (MediaScope.maybeOf(context)
                                case final scope?) ...[
                              const SizedBox(height: 24),
                              PostsGrid(scope: scope, owner: profile.userId),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
          if (onBack != null)
            _CoverButton(
              label: 'Close profile',
              icon: Icons.close_rounded,
              onPressed: onBack!,
              color: foregroundColor,
            ),
          const Spacer(),
          ?menu,
        ],
      ),
    ),
  );
}

class ProfileOptionsButton extends StatelessWidget {
  const ProfileOptionsButton({
    required this.onPressed,
    this.color = Colors.white,
    super.key,
  });
  final Color color;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => _CoverButton(
    color: color,
    label: 'Profile options',
    icon: Icons.more_horiz_rounded,
    onPressed: onPressed,
  );
}

class _CoverButton extends StatelessWidget {
  const _CoverButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
  });
  final Color color;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: label,
    onPressed: onPressed,
    icon: Icon(icon),
    style: IconButton.styleFrom(
      backgroundColor: color.withValues(alpha: .14),
      foregroundColor: color,
      minimumSize: const Size(48, 48),
    ),
  );
}
