import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/encounter_repository.dart';
import '../encounter_bloc.dart';
import 'encounter_map.dart';

class EncounterFiltersBar extends StatelessWidget {
  const EncounterFiltersBar({
    required this.styleUrl,
    required this.showMap,
    required this.mapFailed,
    required this.onToggleMap,
    super.key,
  });
  final String styleUrl;
  final bool showMap, mapFailed;
  final VoidCallback onToggleMap;
  @override
  Widget build(BuildContext context) =>
      BlocSelector<EncounterBloc, EncounterState, (EncounterMode, double)>(
        selector: (s) => (s.mode, s.radiusKm),
        builder: (context, value) => Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final mode in EncounterMode.values)
              ChoiceChip(
                label: Text(mode == EncounterMode.recent ? 'Recent' : 'Nearby'),
                selected: value.$1 == mode,
                onSelected: (_) => context.read<EncounterBloc>().add(
                  EncounterFilterChanged(mode, radiusKm: value.$2),
                ),
              ),
            if (value.$1 == EncounterMode.nearby)
              PopupMenuButton<double>(
                tooltip: 'Encounter radius',
                onSelected: (radius) => context.read<EncounterBloc>().add(
                  EncounterFilterChanged(value.$1, radiusKm: radius),
                ),
                itemBuilder: (_) => [
                  for (final radius in encounterRadii)
                    PopupMenuItem(value: radius, child: Text('$radius km')),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('${value.$2} km'),
                ),
              ),
            if (validMapStyle(styleUrl))
              IconButton(
                tooltip: mapFailed
                    ? 'Retry map'
                    : showMap
                    ? 'List view'
                    : 'Map view',
                onPressed: onToggleMap,
                icon: Icon(
                  mapFailed
                      ? Icons.refresh
                      : showMap
                      ? Icons.view_list_outlined
                      : Icons.map_outlined,
                ),
              ),
          ],
        ),
      );
}
