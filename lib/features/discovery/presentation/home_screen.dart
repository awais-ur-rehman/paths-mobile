import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/platform/location_tracker.dart';
import '../../../shared/widgets/paths_icon.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_options_menu.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../../media/presentation/media_scope.dart';
import '../../safety/presentation/safety_scope.dart';
import '../../relationships/data/relationship_repository.dart';
import '../data/location_sync_service.dart';
import '../domain/encounter_repository.dart';
import 'encounter_bloc.dart';
import 'location_cubit.dart';
import 'widgets/encounter_map.dart';
import 'widgets/encounter_preview.dart';
import 'widgets/home_map_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.repository,
    required this.onProfile,
    required this.onLocationSetup,
    this.locations,
    this.relationships,
    this.onNotifications,
    this.onChat,
    this.mapStyleUrl = const String.fromEnvironment('PATHS_MAP_STYLE_URL'),
    super.key,
  });
  final EncounterRepository repository;
  final RelationshipRepository? relationships;
  final FutureOr<void> Function(String) onProfile;
  final Future<void> Function(String)? onChat;
  final VoidCallback onLocationSetup;
  final VoidCallback? onNotifications;
  final LocationSyncService? locations;
  final String mapStyleUrl;
  @override
  Widget build(BuildContext context) => _HomeOwner(
    key: ValueKey((repository, repository.discoveryAccountId)),
    configuration: this,
  );
}

class _HomeOwner extends StatefulWidget {
  const _HomeOwner({required this.configuration, super.key});
  final HomeScreen configuration;
  @override
  State<_HomeOwner> createState() => _HomeOwnerState();
}

class _HomeOwnerState extends State<_HomeOwner> {
  late final bloc = EncounterBloc(widget.configuration.repository);
  LocationCubit? location;
  AppLifecycleListener? _lifecycle;
  final _search = TextEditingController();
  var _mapKey = GlobalKey<EncounterMapState>();
  bool _mapFailed = false,
      _active = true,
      _foreground = true,
      _sheetOpen = false;
  bool _openingSettings = false, _requestingLocation = false;
  Route<dynamic>? _homeRoute;
  @override
  void initState() {
    super.initState();
    bloc.add(const RefreshEncounters());
    if (widget.configuration.locations case final sync?) {
      location = LocationCubit(sync);
      unawaited(_prepareLocation());
    }
    _lifecycle = AppLifecycleListener(
      onPause: () {
        if (mounted) {
          _dismissPreview();
          setState(() => _foreground = false);
        }
      },
      onResume: () {
        if (mounted) {
          setState(() => _foreground = true);
          if (_active) unawaited(_resumeLocation());
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_active) bloc.add(const RefreshEncounters());
    _active = active;
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _search.dispose();
    unawaited(bloc.close());
    unawaited(location?.close());
    super.dispose();
  }

  void _dismissPreview() {
    if (!_sheetOpen) return;
    _sheetOpen = false;
    final route = _homeRoute;
    if (route != null) {
      Navigator.of(context).popUntil((current) => identical(current, route));
    }
  }

  void _invalidate() {
    _dismissPreview();
    bloc.add(const InvalidateEncounters());
  }

  Future<void> _openProfile(String id) async {
    await widget.configuration.onProfile(id);
    if (mounted && _active) bloc.add(const RefreshEncounters());
  }

  Future<void> _preview(List<Encounter> items) async {
    if (_sheetOpen || items.isEmpty) return;
    FocusScope.of(context).unfocus();
    _sheetOpen = true;
    _homeRoute = ModalRoute.of(context);
    var navigated = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      builder: (sheet) => EncounterPreview(
        items: items,
        relationships: widget.configuration.relationships,
        onProfile: (id) {
          navigated = true;
          _dismissPreview();
          unawaited(_openProfile(id));
        },
        onChat: widget.configuration.onChat == null
            ? null
            : (id) {
                navigated = true;
                _dismissPreview();
                unawaited(widget.configuration.onChat!(id));
              },
      ),
    );
    _sheetOpen = false;
    if (mounted && _active && _foreground && !navigated) {
      bloc.add(const RefreshEncounters());
    }
  }

  void _refresh() {
    unawaited(MediaScope.maybeOf(context)?.media.purge());
    bloc.add(const RefreshEncounters());
  }

  Future<void> _options() async {
    final action = await showPathsOptions(context, [
      const PathsMenuOption('refresh', 'Refresh paths', PathsIconName.review),
      if (bloc.state.items.isNotEmpty)
        const PathsMenuOption('browse', 'Browse paths', PathsIconName.profile),
      if (widget.configuration.onNotifications != null)
        const PathsMenuOption(
          'notifications',
          'Notifications',
          PathsIconName.bell,
        ),
      const PathsMenuOption(
        'location',
        'Location sharing',
        PathsIconName.location,
      ),
    ]);
    if (!mounted) return;
    switch (action) {
      case 'refresh':
        _refresh();
      case 'browse':
        await _preview(bloc.state.items);
      case 'notifications':
        widget.configuration.onNotifications?.call();
      case 'location':
        await _requestLocation();
    }
  }

  Future<void> _radius() async {
    final value = await showPathsOptions(context, [
      for (final radius in encounterRadii)
        PathsMenuOption('$radius', '$radius km', PathsIconName.location),
    ]);
    if (!mounted || value == null) return;
    bloc.add(
      EncounterFilterChanged(bloc.state.mode, radiusKm: double.parse(value)),
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
      return MapRoundButton(
        label: 'Enable location',
        icon: PathsIconName.location,
        onPressed: _requestLocation,
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
        builder: (_, value) => MapRoundButton(
          label: value.$2 ? 'Location settings' : 'Enable location',
          icon: PathsIconName.location,
          onPressed: value.$1 ? null : _requestLocation,
        ),
      ),
    );
  }

  Widget _map(EncounterState state) {
    Widget map(bool enabled) => EncounterMap(
      key: _mapKey,
      items: state.items,
      latitude: state.centerLatitude,
      longitude: state.centerLongitude,
      showUserLocation: enabled,
      styleUrl: widget.configuration.mapStyleUrl,
      focusKey: '${state.query}:${state.mode}:${state.radiusKm}',
      onSelected: (items) => unawaited(_preview(items)),
      onUnavailable: () {
        if (mounted) setState(() => _mapFailed = true);
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

  Widget _status(EncounterState state) {
    String? label;
    VoidCallback? action;
    String? actionLabel;
    if (_mapFailed || !validMapStyle(widget.configuration.mapStyleUrl)) {
      label = 'Map unavailable';
      actionLabel = 'Retry map';
      action = () {
        setState(() {
          _mapFailed = false;
          _mapKey = GlobalKey<EncounterMapState>();
        });
      };
    } else if (state.error != null) {
      label = state.error!.offline ? 'You’re offline' : 'Could not load paths';
      actionLabel = 'Retry';
      action = () => bloc.add(const RetryEncounters());
    } else if (state.mode == EncounterMode.nearby &&
        !state.nearbyAvailable &&
        !state.loading) {
      label = 'Location needed for Nearby';
      actionLabel = 'Enable';
      action = _requestLocation;
    } else if (state.loading && state.items.isEmpty) {
      label = 'Finding paths';
    } else if (state.items.isEmpty) {
      label = state.query.isEmpty
          ? 'No paths crossed yet'
          : 'No matching paths';
    } else if (state.nextCursor != null || state.loadingMore) {
      label = state.loadingMore ? 'Loading paths' : 'More paths';
      if (!state.loadingMore) {
        actionLabel = 'Load';
        action = () => bloc.add(const MoreEncounters());
      }
    }
    if (label == null) return const SizedBox.shrink();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.loading || state.loadingMore) ...[
              const PathsLoader(size: 20),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF52616D),
                  ),
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: TextButton(onPressed: action, child: Text(actionLabel!)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafetyRefresh(
    onChanged: _invalidate,
    child: BlocProvider.value(
      value: bloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F3),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_active &&
                _foreground &&
                !_mapFailed &&
                validMapStyle(widget.configuration.mapStyleUrl))
              BlocBuilder<EncounterBloc, EncounterState>(
                buildWhen: (a, b) =>
                    a.items != b.items ||
                    a.centerLatitude != b.centerLatitude ||
                    a.centerLongitude != b.centerLongitude ||
                    a.query != b.query ||
                    a.mode != b.mode ||
                    a.radiusKm != b.radiusKm,
                builder: (context, state) => _map(state),
              ),
            Positioned(
              top: 12,
              left: 20,
              right: 20,
              child:
                  BlocSelector<
                    EncounterBloc,
                    EncounterState,
                    (EncounterMode, double)
                  >(
                    selector: (s) => (s.mode, s.radiusKm),
                    builder: (context, filter) => HomeMapHeader(
                      search: _search,
                      onSearch: (query) =>
                          bloc.add(EncounterSearchChanged(query)),
                      mode: filter.$1,
                      radius: filter.$2,
                      onMode: (mode) => bloc.add(
                        EncounterFilterChanged(mode, radiusKm: filter.$2),
                      ),
                      onRadius: _radius,
                      locationButton: _locationButton(),
                      onOptions: () => unawaited(_options()),
                    ),
                  ),
            ),
            if (MediaQuery.viewInsetsOf(context).bottom == 0)
              Positioned(
                right: 20,
                bottom: MediaQuery.paddingOf(context).bottom + 88,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MapRoundButton(
                      label: 'Your location',
                      icon: PathsIconName.locate,
                      onPressed: () async {
                        final centered =
                            await _mapKey.currentState?.centerOnUser() ?? false;
                        if (!centered && context.mounted) {
                          if (location?.state.permissions?.granted == true) {
                            PathsToast.show(
                              context,
                              'Waiting for your location',
                            );
                          } else {
                            await _requestLocation();
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    BlocSelector<EncounterBloc, EncounterState, bool>(
                      selector: (s) => s.items.isNotEmpty,
                      builder: (context, available) => MapRoundButton(
                        label: 'Show crossed paths',
                        icon: PathsIconName.fit,
                        onPressed: available
                            ? () => unawaited(
                                _mapKey.currentState?.showEncounters(),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: BlocBuilder<EncounterBloc, EncounterState>(
                  builder: (context, state) => _status(state),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
