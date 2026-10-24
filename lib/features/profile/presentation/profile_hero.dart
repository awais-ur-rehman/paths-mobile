import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../shared/widgets/paths_icon.dart';
import '../../../shared/widgets/verification_badge.dart';
import '../../media/presentation/media_scope.dart';
import '../../media/presentation/private_image.dart';
import '../domain/profile_repository.dart';

const profileInk = Color(0xFF171B22);

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    required this.profile,
    required this.viewportHeight,
    this.action,
    super.key,
  });
  final ProfileSummary profile;
  final double viewportHeight;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: RepaintBoundary(
          child: ClipRect(child: _Portrait(profile: profile)),
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          (viewportHeight * .52).clamp(280, 560),
          24,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              profile.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w600,
                height: 1.15,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '@${profile.username}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFDFE3E8), fontSize: 16),
            ),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFFDFE3E8),
                  ),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  VerificationBadge(status: profile.verificationStatus),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PathsIcon(
                          profile.visibility == 'private'
                              ? PathsIconName.lock
                              : PathsIconName.globe,
                          size: 18,
                          color: const Color(0xFFDFE3E8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          profile.visibility == 'private'
                              ? 'Private profile'
                              : 'Public profile',
                          style: const TextStyle(
                            color: Color(0xFFDFE3E8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
            if (profile.bio.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                profile.bio,
                style: const TextStyle(
                  color: Color(0xFFF1F3F5),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _Portrait extends StatelessWidget {
  const _Portrait({required this.profile});
  final ProfileSummary profile;
  @override
  Widget build(BuildContext context) {
    final media = MediaScope.maybeOf(context)?.media;
    if (profile.avatarAssetId == null || media == null) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF455762), profileInk],
          ),
        ),
        child: Align(
          alignment: const Alignment(0, -.4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PathsIcon(
                PathsIconName.profile,
                size: 120,
                color: Colors.white38,
              ),
              const SizedBox(height: 16),
              Text(
                profile.photoState == 'pending'
                    ? 'Photo in review'
                    : 'No photo yet',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }
    return IconTheme.merge(
      data: const IconThemeData(color: Colors.white70),
      child: PrivateImage(
        repository: media,
        assetId: profile.avatarAssetId!,
        thumbnail: false,
        imageBuilder: (context, image) => Stack(
          fit: StackFit.expand,
          children: [
            RawImage(
              image: image,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            // Repaint one decoded frame twice; the gradient masks only the blurred copy.
            ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment(0, -.22),
                end: Alignment(0, .6),
                colors: [Colors.transparent, Colors.black],
              ).createShader(bounds),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: RawImage(
                  image: image,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x16000000),
                    Color(0x00000000),
                    Color(0xA6171B22),
                    profileInk,
                  ],
                  stops: [0, .3, .6, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
