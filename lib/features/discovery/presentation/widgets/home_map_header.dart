import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/widgets/paths_icon.dart';
import '../../domain/encounter_repository.dart';

class HomeMapHeader extends StatelessWidget {
  const HomeMapHeader({
    required this.search,
    required this.onSearch,
    required this.mode,
    required this.radius,
    required this.onMode,
    required this.onRadius,
    required this.locationButton,
    required this.onOptions,
    super.key,
  });
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final EncounterMode mode;
  final double radius;
  final ValueChanged<EncounterMode> onMode;
  final VoidCallback onRadius;
  final Widget locationButton;
  final VoidCallback onOptions;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                elevation: 3,
                shadowColor: Colors.black12,
                child: TextField(
                  controller: search,
                  onChanged: onSearch,
                  maxLength: 100,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: 'Search your paths',
                    counterText: '',
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(14),
                      child: PathsIcon(PathsIconName.search, size: 20),
                    ),
                    suffixIcon: ValueListenableBuilder(
                      valueListenable: search,
                      builder: (context, value, _) => value.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                search.clear();
                                onSearch('');
                              },
                              icon: Transform.rotate(
                                angle: math.pi / 4,
                                child: const PathsIcon(
                                  PathsIconName.plus,
                                  size: 20,
                                ),
                              ),
                            ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            locationButton,
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MapRoundButton(
              label: 'Map options',
              icon: PathsIconName.more,
              onPressed: onOptions,
            ),
            for (final value in EncounterMode.values)
              ChoiceChip(
                label: Text(
                  value == EncounterMode.recent ? 'Recent' : 'Nearby',
                ),
                selected: mode == value,
                onSelected: (_) => onMode(value),
                showCheckmark: false,
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF0B5AA1),
                labelStyle: TextStyle(
                  color: mode == value ? Colors.white : const Color(0xFF101418),
                ),
                side: BorderSide.none,
                shape: const StadiumBorder(),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            if (mode == EncounterMode.nearby)
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                child: TextButton.icon(
                  onPressed: onRadius,
                  icon: const PathsIcon(PathsIconName.location, size: 18),
                  label: Text('$radius km'),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class MapRoundButton extends StatelessWidget {
  const MapRoundButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });
  final String label;
  final PathsIconName icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    elevation: 3,
    shadowColor: Colors.black12,
    child: IconButton(
      tooltip: label,
      onPressed: onPressed,
      style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
      icon: PathsIcon(icon, size: 23),
    ),
  );
}
