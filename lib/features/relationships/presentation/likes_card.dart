import 'package:flutter/material.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../../shared/widgets/paths_icon.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../media/presentation/media_scope.dart';
import '../../media/presentation/private_image.dart';

class LikesCard extends StatelessWidget {
  const LikesCard({
    required this.item,
    required this.onOpen,
    this.onRemove,
    this.removing = false,
    super.key,
  });
  final RelationshipCardDto item;
  final VoidCallback onOpen;
  final VoidCallback? onRemove;
  final bool removing;
  @override
  Widget build(BuildContext context) {
    if (!item.available) {
      return Material(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PathsIcon(
                PathsIconName.profile,
                size: 40,
                color: Color(0xFF85939E),
              ),
              const SizedBox(height: 12),
              const Text(
                'Profile unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF52616D)),
              ),
              if (onRemove != null || removing)
                IconButton(
                  tooltip: 'Remove saved profile',
                  onPressed: removing ? null : onRemove,
                  icon: removing
                      ? const PathsLoader(size: 20)
                      : const PathsIcon(PathsIconName.trash, size: 21),
                ),
            ],
          ),
        ),
      );
    }
    final media = MediaScope.maybeOf(context)?.media;
    final status = switch (item.state) {
      'pending' =>
        item.direction == 'incoming' ? 'Wants to connect' : 'Request sent',
      'accepted' => 'Connected',
      'declined' => 'Declined',
      'cancelled' => 'Cancelled',
      'expired' => 'Expired',
      'disconnected' => 'Disconnected',
      _ => '@${item.username}',
    };
    return Semantics(
      button: true,
      label: 'Open ${item.displayName}',
      child: Material(
        color: const Color(0xFF374D5D),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.avatarAssetId != null && media != null)
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: PrivateImage(
                      repository: media,
                      assetId: item.avatarAssetId!,
                    ),
                  ),
                )
              else
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF607B90), Color(0xFF253F54)],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment(0, -.3),
                    child: PathsIcon(
                      PathsIconName.profile,
                      size: 64,
                      color: Colors.white38,
                    ),
                  ),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x18000000),
                      Color(0xE6000000),
                    ],
                    stops: [0, .35, 1],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (item.verificationStatus == 'approved')
                          const Padding(
                            padding: EdgeInsets.only(left: 6, top: 1),
                            child: Tooltip(
                              message: 'Verified',
                              child: PathsIcon(
                                PathsIconName.verified,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE3EAF0),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
