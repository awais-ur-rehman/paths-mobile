import 'package:flutter/material.dart';

import '../../../../shared/widgets/paths_avatar.dart';
import '../../../../app/theme/paths_tokens.dart';
import '../../domain/encounter_repository.dart';

class EncounterCard extends StatelessWidget {
  const EncounterCard({
    required this.encounter,
    required this.onTap,
    super.key,
  });
  final Encounter encounter;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).extension<PathsTokens>()!.muted;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Theme.of(context).extension<PathsTokens>()!.line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PathsAvatar(size: 60),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${encounter.displayName}, ${encounter.age}',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (encounter.verificationStatus == 'approved')
                      const Tooltip(
                        message: 'Document reviewed',
                        child: Icon(
                          Icons.verified_outlined,
                          color: Color(0xFF147DCE),
                          size: 20,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '${encounter.coarseAreaLabel} · ${encounter.timeLabel}',
                      style: TextStyle(color: muted),
                    ),
                    if (encounter.encounterCount > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${encounter.encounterCount} encounters',
                          style: TextStyle(color: muted),
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
