import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/paths_tokens.dart';
import '../../../core/platform/location_tracker.dart';
import '../../../shared/widgets/paths_brand.dart';
import 'widgets/encounter_filters.dart';
import 'widgets/encounter_results.dart';
import '../data/location_sync_service.dart';
import '../domain/encounter_repository.dart';
import 'encounter_bloc.dart';
import 'location_cubit.dart';
import 'widgets/encounter_card.dart';
import 'widgets/encounter_map.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.repository,
    required this.onProfile,
    required this.onLocationSetup,
    this.locations,
    this.mapStyleUrl = const String.fromEnvironment('PATHS_MAP_STYLE_URL'),
    super.key,
  });
  final EncounterRepository repository;
  final ValueChanged<String> onProfile;
  final VoidCallback onLocationSetup;
  final LocationSyncService? locations;
  final String mapStyleUrl;
  @override
  Widget build(BuildContext context) => _HomeOwner(configuration: this);
}

class _HomeOwner extends StatefulWidget {
  const _HomeOwner({required this.configuration});
  final HomeScreen configuration;
  @override
  State<_HomeOwner> createState() => _HomeOwnerState();
}

class _HomeOwnerState extends State<_HomeOwner> {
  late final bloc = EncounterBloc(widget.configuration.repository);
  LocationCubit? location;
  AppLifecycleListener? _lifecycle;
  late bool _showMap = validMapStyle(widget.configuration.mapStyleUrl);
  bool _mapFailed = false;
  @override
  void initState() {
    super.initState();
    bloc.add(const RefreshEncounters());
    final sync = widget.configuration.locations;
    if (sync != null) {
      location = LocationCubit(sync);
      unawaited(location!.initialize());
    }
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (mounted && TickerMode.valuesOf(context).enabled) {
          bloc.add(const RefreshEncounters());
          unawaited(location?.refresh());
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    unawaited(bloc.close());
    unawaited(location?.close());
    super.dispose();
  }

  void _area(String area) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            for (final item in bloc.state.items.where(
              (item) => item.coarseAreaId == area,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EncounterCard(
                  encounter: item,
                  onTap: () {
                    Navigator.pop(context);
                    widget.configuration.onProfile(item.userId);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _locationButton() {
    Widget button(TrackingStatus status) => TextButton.icon(
      onPressed: widget.configuration.onLocationSetup,
      icon: const Icon(Icons.location_on_outlined, size: 18),
      label: Text(switch (status) {
        TrackingStatus.active || TrackingStatus.background => 'Sharing',
        TrackingStatus.offline => 'Offline',
        TrackingStatus.inaccurate => 'Approximate',
        _ => 'Paused',
      }),
    );
    final cubit = location;
    if (cubit == null) {
      return IconButton(
        tooltip: 'Location settings',
        onPressed: widget.configuration.onLocationSetup,
        icon: const Icon(Icons.location_on_outlined),
      );
    }
    return BlocSelector<LocationCubit, LocationState, TrackingStatus>(
      bloc: cubit,
      selector: (s) => s.status,
      builder: (_, status) => button(status),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: bloc,
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gutter = PathsTokens.gutter(constraints.maxWidth);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: RefreshIndicator(
                  onRefresh: () async {
                    final done = bloc.stream
                        .where((s) => !s.loading)
                        .take(1)
                        .drain<void>();
                    bloc.add(const RefreshEncounters());
                    await done;
                  },
                  child: CustomScrollView(
                    key: const PageStorageKey('encounter-list'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 8),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const PathsWordmark(width: 116),
                                  const Spacer(),
                                  _locationButton(),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Crossed paths',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                              const SizedBox(height: 16),
                              EncounterFiltersBar(
                                styleUrl: widget.configuration.mapStyleUrl,
                                showMap: _showMap,
                                mapFailed: _mapFailed,
                                onToggleMap: () => setState(() {
                                  _showMap = _mapFailed ? true : !_showMap;
                                  _mapFailed = false;
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showMap &&
                          !_mapFailed &&
                          TickerMode.valuesOf(context).enabled)
                        BlocSelector<
                          EncounterBloc,
                          EncounterState,
                          (List<Encounter>, double?, double?)
                        >(
                          selector: (s) =>
                              (s.items, s.centerLatitude, s.centerLongitude),
                          builder: (context, value) {
                            if (value.$2 == null || value.$3 == null) {
                              return const SliverToBoxAdapter(
                                child: SizedBox.shrink(),
                              );
                            }
                            return SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                gutter,
                                8,
                                gutter,
                                16,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: SizedBox(
                                    height: 280,
                                    child: EncounterMap(
                                      key: ValueKey('${value.$2}:${value.$3}'),
                                      items: value.$1,
                                      latitude: value.$2!,
                                      longitude: value.$3!,
                                      styleUrl:
                                          widget.configuration.mapStyleUrl,
                                      onAreaSelected: _area,
                                      onUnavailable: () {
                                        if (mounted) {
                                          setState(() {
                                            _mapFailed = true;
                                            _showMap = false;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      EncounterResults(
                        gutter: gutter,
                        mapFailed: _mapFailed,
                        onProfile: widget.configuration.onProfile,
                        onLocationSetup: widget.configuration.onLocationSetup,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
