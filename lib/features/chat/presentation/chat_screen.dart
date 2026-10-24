import 'package:go_router/go_router.dart';

import '../../reviews/presentation/review_screen.dart';
import '../../safety/presentation/message_evidence_picker.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/paths_avatar.dart';
import '../../../shared/widgets/paths_icon.dart';
import 'chat_style.dart';
import 'chat_messages.dart';
import 'chat_composer.dart';
import 'chat_header_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_toast.dart';
import '../domain/chat_repository.dart';
import 'chat_bloc.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({
    required this.repository,
    required this.conversationId,
    this.name = 'Chat',
    this.peerId,
    this.avatarAssetId,
    this.onOpened,
    super.key,
  });
  final ChatRepository repository;
  final String conversationId, name;
  final String? peerId, avatarAssetId;
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
  late final header = ChatHeaderCubit(
    widget.configuration.repository,
    widget.configuration.conversationId,
    name: widget.configuration.name,
    peerId: widget.configuration.peerId,
    avatarAssetId: widget.configuration.avatarAssetId,
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
        unawaited(header.load());
      },
    );
  }

  void _scrolled() {
    if (!scroll.hasClients) return;
    if (scroll.position.pixels < 80) _seen();
    if (!bloc.state.olderFailed &&
        scroll.position.pixels >= scroll.position.maxScrollExtent - 160) {
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
    unawaited(header.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: bloc,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            toolbarHeight: 72,
            leading: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: const PathsIcon(PathsIconName.back, color: Colors.white),
            ),
            titleSpacing: 0,
            title: BlocBuilder<ChatHeaderCubit, ChatHeaderState>(
              bloc: header,
              builder: (context, state) => Tooltip(
                message: state.error == null
                    ? 'Conversation'
                    : 'Could not load details. Tap to retry.',
                child: GestureDetector(
                  onTap: state.error == null ? null : header.load,
                  child: Row(
                    children: [
                      PathsAvatar(size: 42, assetId: state.avatarAssetId),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              BlocBuilder<ChatHeaderCubit, ChatHeaderState>(
                bloc: header,
                builder: (context, state) => state.peerId == null
                    ? const SizedBox.shrink()
                    : MessageSafetyMenuButton(subject: state.peerId!),
              ),
            ],
          ),
          body: BlocListener<ChatBloc, ChatState>(
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
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: chatGradient,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.paddingOf(context).top + 72,
                      ),
                      child: Column(
                        children: [
                          BlocSelector<ChatBloc, ChatState, String?>(
                            selector: (state) =>
                                state.error?.code == 'CONTENT_REVIEW_REQUIRED'
                                ? state.pending
                                      .where((p) => p.failed)
                                      .lastOrNull
                                      ?.text
                                : null,
                            builder: (context, text) => text == null
                                ? const SizedBox.shrink()
                                : TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => context.push(
                                      '/reviews',
                                      extra: ReviewDraft(
                                        kind: 'message',
                                        content: text,
                                        conversationId:
                                            widget.configuration.conversationId,
                                      ),
                                    ),
                                    child: const Text('Request review'),
                                  ),
                          ),
                          Expanded(
                            child: ChatMessages(
                              accountId:
                                  widget.configuration.repository.accountId,
                              controller: scroll,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    return ChatComposer(controller: input, onSend: _send);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
