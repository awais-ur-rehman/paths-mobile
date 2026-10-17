import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/paths_brand.dart';
import '../../../../shared/widgets/paths_loader.dart';
import '../../domain/encounter_repository.dart';
import '../encounter_bloc.dart';
import 'encounter_card.dart';

class EncounterResults extends StatelessWidget {
  const EncounterResults({
    required this.gutter,
    required this.mapFailed,
    required this.onProfile,
    required this.onLocationSetup,
    super.key,
  });
  final double gutter;
  final bool mapFailed;
  final ValueChanged<String> onProfile;
  final VoidCallback onLocationSetup;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<EncounterBloc, EncounterState>(
        buildWhen: (before, after) =>
            before.items != after.items ||
            (before.items.isEmpty && before.loading != after.loading) ||
            before.error != after.error ||
            before.loadingMore != after.loadingMore ||
            before.nextCursor != after.nextCursor ||
            before.mode != after.mode ||
            before.nearbyAvailable != after.nearbyAvailable,
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: PathsLoader()),
            );
          }
          if (state.items.isEmpty) {
            final needsLocation =
                state.mode == EncounterMode.nearby && !state.nearbyAvailable;
            final title = state.error != null
                ? (state.error!.offline
                      ? 'You’re offline'
                      : 'Couldn’t load your paths')
                : needsLocation
                ? 'Enable location to explore nearby'
                : state.mode == EncounterMode.nearby
                ? 'No recent paths nearby'
                : 'No paths crossed yet';
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.all(gutter),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PathsSymbol(size: 84),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    if (state.error != null)
                      FilledButton(
                        onPressed: () => context.read<EncounterBloc>().add(
                          const RefreshEncounters(),
                        ),
                        child: const Text('Retry'),
                      )
                    else
                      FilledButton(
                        onPressed: onLocationSetup,
                        child: const Text('Location settings'),
                      ),
                  ],
                ),
              ),
            );
          }
          return SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 16),
            sliver: SliverList.list(
              children: [
                if (state.error != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      state.error!.offline
                          ? 'Offline · showing recent paths'
                          : 'Couldn’t refresh',
                    ),
                    trailing: TextButton(
                      onPressed: () => context.read<EncounterBloc>().add(
                        const RefreshEncounters(),
                      ),
                      child: const Text('Retry'),
                    ),
                  ),
                if (mapFailed)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Map unavailable · showing list'),
                  ),
                for (final item in state.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EncounterCard(
                      encounter: item,
                      onTap: () => onProfile(item.userId),
                    ),
                  ),
                if (state.loadingMore)
                  const Center(child: PathsLoader(size: 28))
                else if (state.nextCursor != null)
                  TextButton(
                    onPressed: () => context.read<EncounterBloc>().add(
                      const MoreEncounters(),
                    ),
                    child: const Text('More paths'),
                  ),
              ],
            ),
          );
        },
      );
}
