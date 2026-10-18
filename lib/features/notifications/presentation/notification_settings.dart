import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/generated/api_contract.dart';
import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../data/notification_repository.dart';
import '../../../core/platform/push_client.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({required this.repository, this.push, super.key});
  final NotificationRepository repository;
  final PushClient? push;
  @override
  State<NotificationSettings> createState() => _SettingsState();
}

class _SettingsState extends State<NotificationSettings> {
  NotificationPreferencesDto? value;
  String? error;
  bool busy = false;
  PushStatus? permission;
  int _generation = 0;
  AppLifecycleListener? _lifecycle;
  @override
  void initState() {
    super.initState();
    unawaited(load());
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (!busy) unawaited(load());
      },
    );
  }

  Future<void> load() async {
    final generation = ++_generation, account = widget.repository.accountId;
    setState(() => busy = true);
    try {
      final result = await widget.repository.preferences(),
          status = await widget.push?.status();
      if (mounted &&
          generation == _generation &&
          account == widget.repository.accountId) {
        setState(() {
          value = result;
          permission = status;
          error = null;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => error = 'Could not load settings');
      }
    } finally {
      if (mounted && generation == _generation) setState(() => busy = false);
    }
  }

  Future<void> update(String key, bool enabled) async {
    final before = value;
    if (before == null || busy) return;
    final generation = ++_generation, account = widget.repository.accountId;
    setState(() => busy = true);
    try {
      final result = await widget.repository.setPreferences(
        NotificationPreferencesDto.fromJson({...before.toJson(), key: enabled}),
      );
      if (mounted &&
          generation == _generation &&
          account == widget.repository.accountId) {
        setState(() => value = result);
      }
    } catch (_) {
      if (mounted) PathsToast.show(context, 'Could not save. Retry.');
    } finally {
      if (mounted && generation == _generation) setState(() => busy = false);
    }
  }

  Future<void> enable() async {
    setState(() => busy = true);
    try {
      await widget.push?.enable();
    } catch (_) {
      if (mounted) {
        PathsToast.show(
          context,
          'Notifications could not start. Check Settings and retry.',
        );
      }
    } finally {
      if (mounted) await load();
    }
  }

  @override
  void dispose() {
    _generation++;
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (value == null && busy) const Center(child: PathsLoader()),
        if (error != null)
          Column(
            children: [
              Text(error!),
              TextButton(
                onPressed: busy ? null : load,
                child: const Text('Retry'),
              ),
            ],
          ),
        if (value case final current?)
          for (final entry in {
            'encounters': 'Crossed paths',
            'requests': 'Connection requests',
            'messages': 'Messages',
            'review': 'Verification',
          }.entries)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.value),
              value: current.toJson()[entry.key] as bool,
              onChanged: busy ? null : (enabled) => update(entry.key, enabled),
            ),
        if (widget.push != null) ...[
          const Divider(),
          Text(
            permission?.configured == true
                ? (permission!.granted
                      ? (permission!.bound && widget.push?.lastFailure == null
                            ? 'Phone notifications enabled'
                            : 'Phone registration pending')
                      : 'Phone notifications off')
                : 'Push setup pending',
          ),
          const SizedBox(height: 12),
          if (permission?.configured == true)
            FilledButton(
              onPressed: busy ? null : enable,
              child: const Text('Enable on this phone'),
            ),
          if (permission?.configured == true)
            TextButton(
              onPressed: busy ? null : widget.push!.openSettings,
              child: const Text('Phone settings'),
            ),
        ],
      ],
    ),
  );
}
