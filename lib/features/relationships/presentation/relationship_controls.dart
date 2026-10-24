import '../../media/presentation/media_scope.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_icon.dart';
import '../../../shared/widgets/paths_options_menu.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../data/relationship_repository.dart';
import 'relationship_cubit.dart';

class RelationshipControls extends StatefulWidget {
  const RelationshipControls({
    required this.repository,
    required this.target,
    this.onChat,
    this.onLightSurface = false,
    this.useRootNavigator = true,
    super.key,
  });
  final RelationshipRepository repository;
  final String target;
  final VoidCallback? onChat;
  final bool onLightSurface;
  final bool useRootNavigator;
  @override
  State<RelationshipControls> createState() => _ControlsState();
}

class _ControlsState extends State<RelationshipControls> {
  late final cubit = RelationshipCubit(widget.repository, widget.target);
  @override
  void initState() {
    super.initState();
    unawaited(cubit.load());
  }

  @override
  void dispose() {
    unawaited(cubit.close());
    super.dispose();
  }

  Future<void> _confirm(String action, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: widget.useRootNavigator,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await cubit.act(action);
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<RelationshipCubit, RelationshipState>(
    bloc: cubit,
    listenWhen: (a, b) =>
        (b.error != null && a.error != b.error) ||
        (a.busy && a.value != null && !b.busy && b.error == null),
    listener: (context, state) {
      if (state.error case final error?) {
        PathsToast.show(context, error.message);
      } else {
        unawaited(MediaScope.maybeOf(context)?.media.purge());
      }
    },
    builder: (context, state) {
      final value = state.value;
      if (value == null) {
        return Center(
          child: state.busy
              ? const PathsLoader()
              : TextButton(onPressed: cubit.load, child: const Text('Retry')),
        );
      }
      return Theme(
        data: Theme.of(context).copyWith(
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: widget.onLightSurface
                  ? const Color(0xFF050708)
                  : Colors.white,
              foregroundColor: widget.onLightSurface
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.onLightSurface
                  ? const Color(0xFF101418)
                  : Colors.white,
              side: BorderSide(
                color: widget.onLightSurface
                    ? const Color(0xFFD8E4EC)
                    : Colors.white54,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: widget.onLightSurface
                  ? const Color(0xFF0B5AA1)
                  : Colors.white,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                if (value.status != 'connected' || widget.onChat == null)
                  OutlinedButton.icon(
                    onPressed: state.busy ? null : cubit.save,
                    icon: const PathsIcon(PathsIconName.likes, size: 20),
                    label: Text(value.saved ? 'Saved' : 'Save'),
                  ),
                if (value.available)
                  switch (value.status) {
                    'none' => FilledButton(
                      onPressed: !state.busy && value.canRequest
                          ? () => _confirm(
                              'request',
                              'Send a connection request?',
                            )
                          : null,
                      child: Text(
                        widget.onLightSurface ? 'Send request' : 'Connect',
                      ),
                    ),
                    'incoming' => FilledButton(
                      onPressed: state.busy ? null : () => cubit.act('accept'),
                      child: const Text('Accept'),
                    ),
                    'sent' => OutlinedButton(
                      onPressed: state.busy ? null : () => cubit.act('cancel'),
                      child: const Text('Cancel request'),
                    ),
                    'connected' when widget.onChat != null => Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: state.busy ? null : widget.onChat,
                            icon: const PathsIcon(
                              PathsIconName.chats,
                              size: 20,
                            ),
                            label: const Text('Message'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Connection options',
                          icon: PathsIcon(
                            PathsIconName.more,
                            color: widget.onLightSurface
                                ? const Color(0xFF101418)
                                : Colors.white,
                          ),
                          onPressed: state.busy
                              ? null
                              : () async {
                                  final action = await showPathsOptions(
                                    context,
                                    [
                                      PathsMenuOption(
                                        'save',
                                        value.saved ? 'Unsave' : 'Save',
                                        PathsIconName.likes,
                                      ),
                                      const PathsMenuOption(
                                        'disconnect',
                                        'Disconnect',
                                        PathsIconName.block,
                                      ),
                                    ],
                                  );
                                  if (!mounted || action == null) return;
                                  if (action == 'save') {
                                    await cubit.save();
                                  } else {
                                    await _confirm('disconnect', 'Disconnect?');
                                  }
                                },
                        ),
                      ],
                    ),
                    'connected' => OutlinedButton(
                      onPressed: state.busy
                          ? null
                          : () => _confirm('disconnect', 'Disconnect?'),
                      child: const Text('Disconnect'),
                    ),
                    'cooldown' => Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Try connecting later',
                        style: TextStyle(
                          color: widget.onLightSurface
                              ? const Color(0xFF52616D)
                              : Colors.white70,
                        ),
                      ),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                if (value.status == 'incoming')
                  TextButton(
                    onPressed: state.busy ? null : () => cubit.act('decline'),
                    child: const Text('Decline'),
                  ),
              ],
            ),
            if (state.busy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: PathsLoader(),
                ),
              ),
          ],
        ),
      );
    },
  );
}
