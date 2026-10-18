import '../../safety/presentation/safety_scope.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/paths_tokens.dart';
import '../../../core/platform/location_tracker.dart';
import '../../../shared/widgets/paths_brand.dart';
import '../../../shared/widgets/paths_toast.dart';
import 'widgets/encounter_filters.dart';
import 'widgets/encounter_results.dart';
import '../data/location_sync_service.dart';
import '../domain/encounter_repository.dart';
import 'encounter_bloc.dart';
import 'location_cubit.dart';
import 'widgets/encounter_card.dart';
import 'widgets/encounter_map.dart';
import '../../relationships/data/relationship_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.repository,
    required this.onProfile,
    required this.onLocationSetup,
    this.locations,
    this.relationships,
    this.onNotifications,
    this.mapStyleUrl = const String.fromEnvironment('PATHS_MAP_STYLE_URL'),
    super.key,
  });
  final EncounterRepository repository;
  final RelationshipRepository? relationships;
  final FutureOr<void> Function(String) onProfile;
  final VoidCallback onLocationSetup;
  final VoidCallback? onNotifications;
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
  bool _active = true;
  bool _openingSettings = false, _requestingLocation = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_active) bloc.add(const RefreshEncounters());
    _active = active;
  }

  Future<void> _openProfile(String id) async {
    await widget.configuration.onProfile(id);
    if (mounted) bloc.add(const RefreshEncounters());
  }

  @override
  void initState() {
    super.initState();
    bloc.add(const RefreshEncounters());
    final sync = widget.configuration.locations;
    if (sync != null) {
      location = LocationCubit(sync);
      unawaited(_prepareLocation());
    }
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (mounted && TickerMode.valuesOf(context).enabled) {
          bloc.add(const RefreshEncounters());
          unawaited(_resumeLocation());
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
                  relationships: widget.configuration.relationships,
                  onTap: () {
                    Navigator.pop(context);
                    unawaited(_openProfile(item.userId));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _prepareLocation() async {
    final cubit = location!;
    await cubit.initialize();
    if (!mounted || !TickerMode.valuesOf(context).enabled) return;
    final permissions = cubit.state.permissions;
    if (permissions?.granted == false &&
        permissions?.canRequestForeground == true) {
      await _requestLocation();
    }
  }

  Future<void> _resumeLocation() async {
    final cubit = location;
    if (cubit == null) return;
    await cubit.refresh();
    if (!mounted || !_openingSettings) return;
    _openingSettings = false;
    if (cubit.state.permissions?.granted == true &&
        cubit.state.permissions?.servicesEnabled == true) {
      await cubit.enable(false);
    }
  }

  Future<void> _requestLocation() async {
    final cubit = location;
    if (cubit == null) {
      widget.configuration.onLocationSetup();
      return;
    }
    if (_requestingLocation || cubit.state.busy) return;
    _requestingLocation = true;
    try {
      final permissions = cubit.state.permissions;
      if (permissions?.granted == true &&
          permissions?.servicesEnabled == true &&
          ![
            TrackingStatus.stopped,
            TrackingStatus.paused,
            TrackingStatus.permissionNeeded,
          ].contains(cubit.state.status) &&
          !cubit.state.pendingStop) {
        widget.configuration.onLocationSetup();
        return;
      }
      final settings =
          permissions?.servicesEnabled == false ||
          (permissions?.granted == false &&
              permissions?.canRequestForeground == false);
      final accepted = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Find your paths',
                  style: Theme.of(sheet).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  settings ? 'Enable location for Paths in device settings.' : 'Paths uses your precise location on its server to find crossed paths. Others see approximate areas.',
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(sheet, true),
                  child: Text(settings ? 'Open settings' : 'Allow location'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(sheet, false),
                  child: const Text('Not now'),
                ),
              ],
            ),
          ),
        ),
      );
      if (!mounted || accepted != true) return;
      if (settings) {
        _openingSettings = true;
        await cubit.openSettings();
      } else {
        await cubit.enable(false);
      }
    } finally {
      _requestingLocation = false;
    }
  }

  Widget _locationButton() {
    final cubit = location;
    if (cubit == null) {
      return IconButton(
        tooltip: 'Enable location',
        onPressed: _requestLocation,
        icon: const Icon(Icons.location_on_outlined),
      );
    }
    return BlocListener<LocationCubit, LocationState>(
      bloc: cubit,
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) =>
          PathsToast.show(context, state.error!.message),
      child: BlocSelector<LocationCubit, LocationState, (bool, bool)>(
        bloc: cubit,
        selector: (s) => (
          s.busy,
          s.permissions?.granted == true &&
              !s.pendingStop &&
              ![
                TrackingStatus.stopped,
                TrackingStatus.paused,
                TrackingStatus.permissionNeeded,
              ].contains(s.status),
        ),
        builder: (_, value) => IconButton(
          tooltip: value.$2 ? 'Location settings' : 'Enable location',
          onPressed: value.$1 ? null : _requestLocation,
          icon: Icon(value.$2 ? Icons.location_on : Icons.location_on_outlined),
        ),
      ),
    );
  }

  Widget _map(EncounterState state) {
    Widget map(bool enabled) => EncounterMap(
      items: state.items,
      latitude: state.centerLatitude,
      longitude: state.centerLongitude,
      showUserLocation: enabled,
      styleUrl: widget.configuration.mapStyleUrl,
      onAreaSelected: _area,
      onUnavailable: () {
        if (mounted) {
          setState(() {
            _mapFailed = true;
            _showMap = false;
          });
        }
      },
    );
    final cubit = location;
    if (cubit == null) return map(false);
    return BlocSelector<LocationCubit, LocationState, bool>(
      bloc: cubit,
      selector: (s) =>
          s.permissions?.granted == true &&
          s.permissions?.servicesEnabled == true,
      builder: (_, enabled) => map(enabled),
    );
  }

  @override
  Widget build(BuildContext context) => SafetyRefresh(
    onChanged: () => bloc.add(const InvalidateEncounters()),
    child: BlocProvider.value(
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
                                    if (widget.configuration.onNotifications !=
                                        null)
                                      IconButton(
                                        tooltip: "Notifications",
                                        onPressed: widget
                                            .configuration
                                            .onNotifications,
                                        icon: const Icon(
                                          Icons.notifications_outlined,
                                        ),
                                      ),
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
                          BlocBuilder<EncounterBloc, EncounterState>(
                            buildWhen: (a, b) =>
                                a.items != b.items ||
                                a.centerLatitude != b.centerLatitude ||
                                a.centerLongitude != b.centerLongitude,
                            builder: (context, state) => SliverPadding(
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
                                    height: 360,
                                    child: _map(state),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        EncounterResults(
                          relationships: widget.configuration.relationships,
                          gutter: gutter,
                          mapFailed: _mapFailed,
                          onProfile: (id) => unawaited(_openProfile(id)),
                          onLocationSetup: _requestLocation,
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
    ),
  );
}
