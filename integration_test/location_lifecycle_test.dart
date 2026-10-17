import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paths_mobile/core/platform/location_tracker.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native encrypted queue caps, expires and purges synthetic samples',
    (tester) async {
      const channel = MethodChannel('paths/location');
      final result = await channel.invokeMapMethod<String, bool>(
        'runQueueProbe',
      );
      expect(result, {'capped': true, 'expired': true, 'purged': true});
    },
  );
  testWidgets(
    'pause and logout stop native delivery and purge pending samples',
    (tester) async {
      final tracker = PlatformLocationTracker();
      await tracker.pause();
      expect(await tracker.queueCount(), 0);
      expect(await tracker.pendingSamples(), isEmpty);
      await tracker.stopAndPurge();
      expect(await tracker.queueCount(), 0);
      await tracker.dispose();
    },
  );
  testWidgets(
    'active native delivery stops on pause and logout purges populated storage',
    (tester) async {
      final tracker = PlatformLocationTracker();
      addTearDown(tracker.dispose);
      expect(
        await tracker.requestForegroundPermission(),
        true,
        reason: 'Grant precise foreground location on the phone',
      );
      var delivered = 0;
      final first = Completer<void>();
      final subscription = tracker.sampleStream.listen((_) {
        delivered++;
        if (!first.isCompleted) first.complete();
      });
      addTearDown(subscription.cancel);
      await tracker.start(
        TrackingPolicy(
          deviceSessionId: 'physical-lifecycle',
          consentEpoch: DateTime.now().microsecondsSinceEpoch,
        ),
      );
      await first.future.timeout(const Duration(minutes: 2));
      expect(await tracker.queueCount(), greaterThan(0));
      await tracker.pause();
      final atPause = delivered;
      await Future<void>.delayed(const Duration(seconds: 30));
      expect(delivered, atPause);
      expect(await tracker.queueCount(), 0);
      final second = tracker.sampleStream.first;
      await tracker.start(
        TrackingPolicy(
          deviceSessionId: 'physical-logout',
          consentEpoch: DateTime.now().microsecondsSinceEpoch,
        ),
      );
      await second.timeout(const Duration(minutes: 2));
      expect(await tracker.queueCount(), greaterThan(0));
      await tracker.stopAndPurge();
      expect(await tracker.queueCount(), 0);
    },
    timeout: const Timeout(Duration(minutes: 6)),
    skip: !const bool.fromEnvironment('PATHS_RUN_ACTIVE_LOCATION_TEST'),
  );
}
