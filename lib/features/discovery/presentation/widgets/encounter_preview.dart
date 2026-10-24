import 'package:flutter/material.dart';

import '../../../../shared/widgets/paths_avatar.dart';
import '../../../../shared/widgets/paths_icon.dart';
import '../../../relationships/data/relationship_repository.dart';
import '../../../relationships/presentation/relationship_controls.dart';
import '../../domain/encounter_repository.dart';

class EncounterPreview extends StatelessWidget {
  const EncounterPreview({
    required this.items,
    required this.onProfile,
    this.relationships,
    this.onChat,
    super.key,
  });
  final List<Encounter> items;
  final ValueChanged<String> onProfile;
  final ValueChanged<String>? onChat;
  final RelationshipRepository? relationships;
  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: .57,
    minChildSize: .32,
    maxChildSize: .9,
    builder: (context, scroll) => _PreviewBody(
      items: items,
      scroll: scroll,
      onProfile: onProfile,
      onChat: onChat,
      relationships: relationships,
    ),
  );
}

class _PreviewBody extends StatefulWidget {
  const _PreviewBody({
    required this.items,
    required this.scroll,
    required this.onProfile,
    this.onChat,
    this.relationships,
  });
  final List<Encounter> items;
  final ScrollController scroll;
  final ValueChanged<String> onProfile;
  final ValueChanged<String>? onChat;
  final RelationshipRepository? relationships;
  @override
  State<_PreviewBody> createState() => _PreviewBodyState();
}

class _PreviewBodyState extends State<_PreviewBody> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final item = widget.items[selected];
    return ListView(
      controller: widget.scroll,
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (widget.items.length > 1) ...[
          Text(
            '${widget.items.length} paths here',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => Semantics(
                selected: index == selected,
                button: true,
                label: 'Show ${widget.items[index].displayName}',
                child: Tooltip(
                  message: widget.items[index].displayName,
                  child: InkWell(
                    onTap: () => setState(() => selected = index),
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: index == selected
                              ? const Color(0xFF0B5AA1)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ExcludeSemantics(
                        child: IgnorePointer(
                          child: PathsAvatar(
                            size: 48,
                            assetId: widget.items[index].avatarAssetId,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => widget.onProfile(item.userId),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: IgnorePointer(
                      child: PathsAvatar(size: 72, assetId: item.avatarAssetId),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.displayName}, ${item.age}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '@${item.username}',
                          style: const TextStyle(
                            color: Color(0xFF52616D),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.verificationStatus == 'approved')
                    const Tooltip(
                      message: 'Verified',
                      child: PathsIcon(
                        PathsIconName.verified,
                        size: 22,
                        color: Color(0xFF0B5AA1),
                      ),
                    ),
                  const SizedBox(width: 6),
                  const PathsIcon(PathsIconName.chevronRight, size: 22),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${item.coarseAreaLabel} · ${item.timeLabel}',
          style: const TextStyle(color: Color(0xFF52616D), fontSize: 13),
        ),
        if (item.encounterCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${item.encounterCount} encounters',
              style: const TextStyle(color: Color(0xFF52616D), fontSize: 13),
            ),
          ),
        if (item.bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              item.bio,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.5),
            ),
          ),
        const SizedBox(height: 24),
        if (widget.relationships != null)
          RelationshipControls(
            key: ValueKey(item.userId),
            repository: widget.relationships!,
            target: item.userId,
            onLightSurface: true,
            useRootNavigator: false,
            onChat: widget.onChat == null
                ? null
                : () => widget.onChat!(item.userId),
          ),
      ],
    );
  }
}
