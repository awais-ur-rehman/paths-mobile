import '../../safety/presentation/message_evidence_picker.dart';
import '../../safety/presentation/report_sheet.dart';
import '../../safety/domain/safety_repository.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../domain/chat_repository.dart';
import 'chat_bloc.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({
    required this.repository,
    required this.conversationId,
    this.name = 'Chat',
    this.peerId,
    this.onOpened,
    super.key,
  });
  final ChatRepository repository;
  final String conversationId, name;
  final String? peerId;
  final VoidCallback? onOpened;
  @override
  Widget build(BuildContext context) => _ThreadOwner(
    key: ValueKey((repository.accountId, conversationId)),
    configuration: this,
  );
}

class _ThreadOwner extends StatefulWidget {
  const _ThreadOwner({required this.configuration, super.key});
  final ChatScreen configuration;
  @override
  State<_ThreadOwner> createState() => _ThreadOwnerState();
}

class _ThreadOwnerState extends State<_ThreadOwner> {
  late final bloc = ChatBloc(
    widget.configuration.repository,
    widget.configuration.conversationId,
  );
  final input = TextEditingController(), scroll = ScrollController();
  AppLifecycleListener? lifecycle;
  bool _opened = false;
  bool _routeVisible = true;
  bool _appVisible =
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  bool? _active;
  void _visibility() {
    final active = _routeVisible && _appVisible;
    if (active == _active) return;
    _active = active;
    bloc.add(ChatVisibility(active));
    if (active) {
      // A response may have completed under another route without a new sync page.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (!scroll.hasClients || scroll.position.pixels < 80)) {
          _seen();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeVisible = ModalRoute.isCurrentOf(context) ?? true;
    _visibility();
  }

  @override
  void initState() {
    super.initState();
    scroll.addListener(_scrolled);
    lifecycle = AppLifecycleListener(
      onHide: () {
        _appVisible = false;
        _visibility();
      },
      onResume: () {
        _appVisible = true;
        _visibility();
      },
    );
  }

  void _scrolled() {
    if (!scroll.hasClients) return;
    if (scroll.position.pixels < 80) _seen();
    if (scroll.position.pixels >= scroll.position.maxScrollExtent - 160) {
      bloc.add(const ChatOlder());
    }
  }

  void _seen() {
    if (mounted && _active == true && bloc.state.messages.isNotEmpty) {
      bloc.add(ChatSeen(bloc.state.messages.last.sequence));
    }
  }

  void _send() {
    final text = input.text;
    if (text.runes.length > 4000) {
      PathsToast.show(context, 'Keep messages under 4,000 characters.');
      return;
    }
    if (text.trim().isEmpty ||
        text.runes.length > 4000 ||
        !bloc.state.canSend) {
      return;
    }
    bloc.add(ChatSend(text));
    input.clear();
    if (scroll.hasClients) {
      unawaited(
        scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  @override
  void dispose() {
    lifecycle?.dispose();
    scroll.dispose();
    input.dispose();
    unawaited(bloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: bloc,
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.configuration.name),
        actions: [
          BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (a, b) => a.messages != b.messages,
            builder: (context, state) {
              final peer =
                  widget.configuration.peerId ??
                  state.messages
                      .where(
                        (m) =>
                            m.senderId !=
                            widget.configuration.repository.accountId,
                      )
                      .firstOrNull
                      ?.senderId;
              return peer == null
                  ? const SizedBox.shrink()
                  : MessageSafetyMenuButton(subject: peer);
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => bloc.add(const ChatRefresh()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocListener<ChatBloc, ChatState>(
          listenWhen: (a, b) =>
              a.error != b.error ||
              a.messages.length != b.messages.length ||
              a.loading != b.loading,
          listener: (context, state) {
            if (!_opened &&
                !state.loading &&
                state.available &&
                state.error == null) {
              _opened = true;
              widget.configuration.onOpened?.call();
            }
            if (state.error != null && state.error!.code != 'cancelled') {
              PathsToast.show(context, state.error!.message);
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  (!scroll.hasClients || scroll.position.pixels < 80)) {
                _seen();
              }
            });
          },
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<ChatBloc, ChatState>(
                  buildWhen: (a, b) =>
                      a.messages != b.messages ||
                      a.pending != b.pending ||
                      a.loading != b.loading ||
                      a.available != b.available ||
                      a.loadingOlder != b.loadingOlder ||
                      a.error != b.error,
                  builder: (context, state) {
                    if (state.loading) {
                      return const Center(child: PathsLoader());
                    }
                    if (!state.available) {
                      return const Center(
                        child: Text('Conversation unavailable'),
                      );
                    }
                    if (state.messages.isEmpty && state.pending.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.error?.offline == true
                                  ? 'You’re offline'
                                  : 'Say hello',
                            ),
                            if (state.error != null)
                              TextButton(
                                onPressed: () => bloc.add(const ChatRefresh()),
                                child: const Text('Retry'),
                              ),
                          ],
                        ),
                      );
                    }
                    final rows = <Widget>[
                      for (final message in state.messages)
                        GestureDetector(
                          onLongPress:
                              message.senderId ==
                                  widget.configuration.repository.accountId
                              ? null
                              : () => showSafetyActions(
                                  context,
                                  SafetyTarget(
                                    message.senderId,
                                    kind: 'message',
                                    contentId: message.id,
                                  ),
                                ),
                          child: _Bubble(
                            text: message.text,
                            mine:
                                message.senderId ==
                                widget.configuration.repository.accountId,
                          ),
                        ),
                      for (final pending in state.pending)
                        _Bubble(
                          text: pending.text,
                          mine: true,
                          status: pending.failed
                              ? 'Not sent · Retry'
                              : 'Sending…',
                          onRetry: pending.failed
                              ? () => bloc.add(
                                  ChatSend(
                                    pending.text,
                                    clientId: pending.clientId,
                                  ),
                                )
                              : null,
                        ),
                    ];
                    return ListView.builder(
                      controller: scroll,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: rows.length + (state.loadingOlder ? 1 : 0),
                      itemBuilder: (context, index) => index == rows.length
                          ? const Center(child: PathsLoader())
                          : rows[rows.length - 1 - index],
                    );
                  },
                ),
              ),
              BlocSelector<
                ChatBloc,
                ChatState,
                ({bool available, bool canSend, bool loading})
              >(
                selector: (s) => (
                  available: s.available,
                  canSend: s.canSend,
                  loading: s.loading,
                ),
                builder: (context, status) {
                  if (!status.available) return const SizedBox.shrink();
                  if (!status.canSend) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(status.loading ? '' : 'Connection ended'),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: input,
                            minLines: 1,
                            maxLines: 5,
                            maxLength: 4000,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(24),
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Send message',
                          onPressed: _send,
                          icon: const Icon(Icons.arrow_upward),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.mine,
    this.status,
    this.onRetry,
  });
  final String text;
  final bool mine;
  final String? status;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .78,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: mine ? const Color(0xff111719) : const Color(0xffedf3f5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: mine ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            if (status != null)
              onRetry != null
                  ? TextButton(onPressed: onRetry, child: Text(status!))
                  : Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4),
                      child: Text(
                        status!,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
          ],
        ),
      ),
    ),
  );
}
