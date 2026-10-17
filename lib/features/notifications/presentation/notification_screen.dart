import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../data/notification_repository.dart';
import 'notification_cubit.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    required this.repository,
    required this.onOpen,
    required this.onSettings,
    super.key,
  });
  final NotificationRepository repository;
  final Future<void> Function(String) onOpen;
  final VoidCallback onSettings;
  @override
  State<NotificationScreen> createState() => _InboxState();
}

class _InboxState extends State<NotificationScreen> {
  late final cubit = NotificationCubit(widget.repository);
  String? opening;
  AppLifecycleListener? _lifecycle;
  @override
  void initState() {
    super.initState();
    unawaited(cubit.load());
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(cubit.load()));
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    unawaited(cubit.close());
    super.dispose();
  }

  Future<void> open(String id) async {
    if (opening != null) return;
    setState(() => opening = id);
    try {
      await widget.onOpen(id);
      if (mounted) await cubit.load();
    } catch (error) {
      if (mounted) PathsToast.show(context, 'Could not open. Retry.');
    } finally {
      if (mounted) setState(() => opening = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [
        IconButton(
          tooltip: 'Notification settings',
          onPressed: widget.onSettings,
          icon: const Icon(Icons.tune),
        ),
      ],
    ),
    body: BlocBuilder<NotificationCubit, NotificationState>(
      bloc: cubit,
      builder: (context, state) => RefreshIndicator(
        onRefresh: () => cubit.load(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (state.busy && state.items.isEmpty)
              const Center(child: PathsLoader()),
            if (state.error != null)
              Column(
                children: [
                  Text(
                    state.error!.offline
                        ? 'You’re offline'
                        : 'Could not load notifications',
                  ),
                  TextButton(
                    onPressed: () => cubit.load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            if (!state.busy && state.error == null && state.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('You’re all caught up')),
              ),
            for (final item in state.items)
              ListTile(
                leading: Icon(
                  item.kind == 'encounter'
                      ? Icons.alt_route
                      : Icons.person_add_outlined,
                ),
                title: Text(
                  item.body,
                  style: TextStyle(
                    fontWeight: item.read ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  item.available ? item.createdDate : 'Unavailable',
                ),
                trailing: opening == item.id ? const PathsLoader() : null,
                onTap: opening != null ? null : () => open(item.id),
              ),
            if (state.cursor != null)
              TextButton(
                onPressed: state.busy ? null : () => cubit.load(more: true),
                child: const Text('Load more'),
              ),
          ],
        ),
      ),
    ),
  );
}
