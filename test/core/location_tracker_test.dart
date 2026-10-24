import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/platform/location_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('paths/location');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'pendingSamples') return <Object>[];
          if (call.method == 'queueCount') return 0;
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test(
    'upload acknowledgments are scoped to the current lease and stop on pause',
    () async {
      final tracker = PlatformLocationTracker(channel: channel);
      var uploads = 0;
      final subscription = tracker.uploadStream.listen((_) => uploads++);
      Future<void> event(String session, int epoch) async {
        final done = Completer<void>();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              'paths/location',
              const StandardMethodCodec().encodeMethodCall(
                MethodCall('event', {
                  'uploaded': true,
                  'deviceSessionId': session,
                  'consentEpoch': epoch,
                }),
              ),
              (_) => done.complete(),
            );
        await done.future;
        await Future<void>.delayed(Duration.zero);
      }

      await tracker.start(
        const TrackingPolicy(deviceSessionId: 'current', consentEpoch: 2),
      );
      await event('old', 2);
      await event('current', 1);
      expect(uploads, 0);
      await event('current', 2);
      expect(uploads, 1);
      await tracker.pause();
      await event('current', 2);
      expect(uploads, 1);
      await subscription.cancel();
      await tracker.dispose();
    },
  );
  test(
    'pause invalidates in-flight samples before native completion',
    () async {
      final completer = Completer<List<Object>>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (c) async => c.method == 'pendingSamples' ? completer.future : null,
          );
      final tracker = PlatformLocationTracker(channel: channel);
      await tracker.start(
        const TrackingPolicy(deviceSessionId: 'test', consentEpoch: 1),
      );
      final pending = tracker.pendingSamples();
      await tracker.pause();
      completer.complete([]);
      expect(await pending, isEmpty);
      await tracker.dispose();
    },
  );
  test('logout explicitly stops and purges native storage', () async {
    final tracker = PlatformLocationTracker(channel: channel);
    await tracker.stopAndPurge();
    expect(calls.single.method, 'stopAndPurge');
    expect(await tracker.pendingSamples(), isEmpty);
    await tracker.dispose();
  });
  test('invalid consent cannot start native collection', () async {
    final tracker = PlatformLocationTracker(channel: channel);
    await expectLater(
      tracker.start(const TrackingPolicy(deviceSessionId: '', consentEpoch: 0)),
      throwsArgumentError,
    );
    expect(calls, isEmpty);
    await tracker.dispose();
  });
  test('old epoch and device lease are filtered from pending data', () async {
    final base = {
      'sampleId': 'synthetic',
      'deviceSessionId': 'test',
      'consentEpoch': 1,
      'sequence': 1,
      'capturedAt': DateTime.now().millisecondsSinceEpoch,
      'latitude': 0.0,
      'longitude': 0.0,
      'horizontalAccuracyM': 5.0,
      'appState': 'foreground',
      'precisionMode': 'precise',
      'policyVersion': 'adaptive.v1',
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (c) async => c.method == 'pendingSamples'
              ? [
                  base,
                  {...base, 'consentEpoch': 0},
                  {...base, 'deviceSessionId': 'old'},
                  {
                    ...base,
                    'capturedAt': DateTime.now()
                        .subtract(const Duration(minutes: 16))
                        .millisecondsSinceEpoch,
                  },
                ]
              : null,
        );
    final tracker = PlatformLocationTracker(channel: channel);
    await tracker.start(
      const TrackingPolicy(deviceSessionId: 'test', consentEpoch: 1),
    );
    expect(await tracker.pendingSamples(), hasLength(1));
    await tracker.dispose();
  });
}
