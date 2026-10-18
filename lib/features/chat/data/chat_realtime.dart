import 'dart:async';
import 'dart:math';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../domain/chat_repository.dart';

/// Owns only foreground sockets. Tokens stay in memory and never enter URLs/logs.
final class ChatRealtime {
  ChatRealtime({required this.origin, required this.token});
  final String origin;
  final Future<String> Function() token;
  final _events = StreamController<ChatSignal>.broadcast();
  Stream<ChatSignal> get events => _events.stream;
  io.Socket? _socket;
  Timer? _retry;
  bool _foreground = true, _enabled = false, _closed = false;
  int _epoch = 0, _attempt = 0;
  String? _account;
  final _seen = <String>{};
  void refresh() {
    if (!_closed) _events.add(const ChatSignal());
  }

  void configure(String? account) {
    if (_closed) return;
    if (_account == account) return;
    _account = account;
    _enabled = account != null;
    _stop();
    _seen.clear();
    _events.add(const ChatSignal(type: 'reset'));
    if (_enabled && _foreground) unawaited(_connect(_epoch));
  }

  void foreground(bool value) {
    if (_closed) return;
    if (_foreground == value) return;
    _foreground = value;
    _stop();
    if (value && _enabled) unawaited(_connect(_epoch));
  }

  void _stop() {
    _epoch++;
    _retry?.cancel();
    _retry = null;
    final socket = _socket;
    _socket = null;
    socket?.dispose();
  }

  bool _current(int epoch) =>
      !_closed && _enabled && _foreground && epoch == _epoch;
  Future<void> _connect(int epoch) async {
    if (!_current(epoch)) return;
    try {
      final access = await token();
      if (!_current(epoch)) return;
      final socket = io.io(
        origin,
        io.OptionBuilder()
            .setPath('/v1/realtime')
            .setTransports(['websocket'])
            .disableAutoConnect()
            .disableReconnection()
            .enableForceNew()
            .disableMultiplex()
            .setTimeout(5000)
            .setAuth({'token': access})
            .build(),
      );
      _socket?.dispose();
      _socket = socket;
      socket.onConnect((_) {
        if (!_current(epoch)) return;
        _attempt = 0;
        _events.add(const ChatSignal(type: 'reconnected'));
      });
      socket.on('event', (dynamic raw) {
        if (!_current(epoch) || raw is! Map) return;
        final id = raw['eventId'],
            type = raw['type'],
            resource = raw['resourceId'];
        if (id is! String ||
            type is! String ||
            resource is! String ||
            _seen.contains(id)) {
          return;
        }
        if (!const {
          'message.created',
          'connection.updated',
          'conversation.removed',
          'account.restricted',
          'profile.access_changed',
        }.contains(type)) {
          return;
        }
        _seen.add(id);
        if (_seen.length > 200) _seen.remove(_seen.first);
        _events.add(ChatSignal(resourceId: resource, type: type));
      });
      void retry(dynamic _) => _schedule(epoch);
      socket.onDisconnect(retry);
      socket.onConnectError(retry);
      socket.connect();
    } catch (_) {
      // REST/token refresh owns authentication errors; reconnect uses bounded backoff.
      _schedule(epoch);
    }
  }

  void _schedule(int epoch) {
    if (!_current(epoch) || _retry != null) return;
    _events.add(const ChatSignal(type: 'offline'));
    _retry = Timer(Duration(seconds: min(30, 1 << min(_attempt++, 5))), () {
      _retry = null;
      if (_current(epoch)) unawaited(_connect(epoch));
    });
  }

  Future<void> close() async {
    _closed = true;
    _stop();
    await _events.close();
  }
}
