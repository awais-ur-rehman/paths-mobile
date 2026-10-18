import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/chat/data/chat_realtime.dart';

void main() {
  test('real Socket.IO handshake keeps tokens out of URLs, deduplicates and closes in background', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final upgraded = Completer<WebSocket>(), closed = Completer<void>();
    final requests = <Uri>[];
    final listener = server.listen((request) async {
      requests.add(request.uri);
      final socket = await WebSocketTransformer.upgrade(request);
      upgraded.complete(socket);
      socket.add(
        '0${jsonEncode({'sid': 'fixture', 'upgrades': [], 'pingInterval': 25000, 'pingTimeout': 20000, 'maxPayload': 100000})}',
      );
      socket.listen(
        (dynamic data) {
          if (data is String && data.startsWith('40')) {
            expect(
              jsonDecode(data.substring(2))['token'],
              'fixture-access-token',
            );
            socket.add('40${jsonEncode({'sid': 'fixture-socket'})}');
          }
        },
        onDone: () {
          if (!closed.isCompleted) closed.complete();
        },
      );
    });
    final realtime = ChatRealtime(
      origin: 'http://127.0.0.1:${server.port}',
      token: () async => 'fixture-access-token',
    );
    final connected = realtime.events.firstWhere((e) => e.type == 'reconnected');
    realtime.configure('owner');
    await connected.timeout(const Duration(seconds: 5));
    final socket = await upgraded.future;
    expect(requests.single.query.contains('token'), false);
    var events = 0;
    final subscription = realtime.events
        .where((e) => e.type == 'message.created')
        .listen((_) {
          events++;
        });
    final received = realtime.events.firstWhere(
      (e) => e.type == 'message.created',
    );
    final event =
        '42${jsonEncode([
          'event',
          {'eventId': 'event-1', 'type': 'message.created', 'resourceId': 'conversation', 'occurredAt': '2026-10-18', 'version': 1},
        ])}';
    socket.add(event);
    socket.add(event);
    await received;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(events, 1);
    realtime.foreground(false);
    await closed.future.timeout(const Duration(seconds: 5));
    expect(requests.length, 1);
    await subscription.cancel();
    await realtime.close();
    await listener.cancel();
    await server.close(force: true);
  });
  test(
    'background/logout during token refresh cannot create a late socket',
    () async {
      final pending = Completer<String>(),
          server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var requests = 0;
      final listener = server.listen((r) {
        requests++;
        r.response.close();
      });
      final realtime = ChatRealtime(
        origin: 'http://127.0.0.1:${server.port}',
        token: () => pending.future,
      );
      realtime.configure('old-account');
      realtime.foreground(false);
      realtime.configure(null);
      pending.complete('old-token');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(requests, 0);
      await realtime.close();
      await listener.cancel();
      await server.close(force: true);
    },
  );
}
