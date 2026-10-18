import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'dart:ui' show FrameTiming;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paths_mobile/main.dart' as app;
import 'package:paths_mobile/features/auth/presentation/auth_cubit.dart';
import 'package:paths_mobile/features/discovery/presentation/home_screen.dart';

import 'support/frame_summary.dart';

// Owner-operated only. Uses actual composition, repositories, API and platform tracking.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'production navigation, frame and native-cleanup journey',
    (tester) async {
      const email = String.fromEnvironment('PATHS_TEST_EMAIL'),
          password = String.fromEnvironment('PATHS_TEST_PASSWORD');
      expect(
        email,
        isNotEmpty,
        reason: 'Provide a private disposable test account in paths.performance.local.json',
      );
      expect(password, isNotEmpty);
      final frames = <FrameSample>[];
      void collect(List<FrameTiming> timings) {
        for (final t in timings) {
          frames.add(
            FrameSample(
              t.buildDuration.inMicroseconds / 1000,
              t.rasterDuration.inMicroseconds / 1000,
            ),
          );
        }
      }

      binding.addTimingsCallback(collect);
      addTearDown(() => binding.removeTimingsCallback(collect));
      binding.reportData = {
        'task13': {
          'status': 'started',
          'limitation': 'No device measurements completed yet.',
        },
      };
      app.main();
      await tester.pump();
      Future<void> waitFor(Finder finder) async {
        for (var i = 0; i < 80 && finder.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(finder, findsWidgets);
      }

      await waitFor(find.byType(app.PathsApp));
      // Authentication is the production Cubit, without printing credentials or adding test controls to the product.
      final context = tester.element(find.byType(app.PathsApp));
      AuthCubit? auth;
      for (var i = 0; i < 80 && auth == null; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        final nested = find.byType(HomeScreen).evaluate();
        if (nested.isNotEmpty) {
          auth = BlocProvider.of<AuthCubit>(nested.first);
          break;
        }
        final provider = find
            .byWidgetPredicate((w) => w is BlocListener<AuthCubit, AuthState>)
            .evaluate();
        if (provider.isNotEmpty) {
          auth = BlocProvider.of<AuthCubit>(provider.first);
        }
      }
      if (auth == null) {
        // The router's first rendered auth screen is below the same production provider.
        final scaffold = find.byType(Scaffold).first;
        await waitFor(scaffold);
        auth = BlocProvider.of<AuthCubit>(tester.element(scaffold));
      }
      if (auth.state.account?.email != email) {
        await auth.login(email, password);
      }
      await waitFor(find.byType(HomeScreen));
      final tracker = tester
          .widget<HomeScreen>(find.byType(HomeScreen))
          .locations!
          .tracker;
      var observations = 0;
      final subscription = tracker.sampleStream.listen((_) => observations++);
      addTearDown(subscription.cancel);
      if (const bool.fromEnvironment(
        'PATHS_VERIFY_ACTIVE_TRACKING',
        defaultValue: true,
      )) {
        await tester.runAsync(
          () => tracker.sampleStream.first.timeout(const Duration(minutes: 2)),
        );
        expect(
          observations,
          greaterThan(0),
          reason: 'Enable production location sharing with precise permission before this test.',
        );
      }
      final samplesBefore = frames.length, peakStart = ProcessInfo.currentRss;
      var peak = peakStart;
      for (var cycle = 0; cycle < 3; cycle++) {
        for (final label in ['Likes', 'Chats', 'Profile', 'Home']) {
          final destination = find.widgetWithText(NavigationDestination, label);
          await tester.ensureVisible(destination);
          await tester.tap(destination);
          await tester.pump(const Duration(seconds: 1));
          final rss = ProcessInfo.currentRss;
          if (rss > peak) peak = rss;
          final scrollable = find.byType(Scrollable).hitTestable();
          if (scrollable.evaluate().isNotEmpty) {
            await tester.drag(scrollable.first, const Offset(0, -250));
            await tester.pump(const Duration(milliseconds: 400));
          }
        }
      }
      await auth.logout();
      await tester.pump(const Duration(seconds: 1));
      expect(await tracker.queueCount(), 0);
      expect(await tracker.pendingSamples(), isEmpty);
      final measuredFrames = frames.skip(samplesBefore).toList();
      expect(
        measuredFrames,
        isNotEmpty,
        reason: 'No real frame timings were collected.',
      );
      final summary = {
        'status': 'completed',
        ...frameSummary(measuredFrames),
        'mode': const bool.fromEnvironment('dart.vm.product')
            ? 'release'
            : const bool.fromEnvironment('dart.vm.profile')
            ? 'profile'
            : 'debug',
        'rssStartBytes': peakStart,
        'rssPeakBytes': peak,
        'globalImageCacheBytes':
            PaintingBinding.instance.imageCache.currentSizeBytes,
        'globalImageCacheLiveImages':
            PaintingBinding.instance.imageCache.liveImageCount,
        'nativeQueueAfterLogout': 0,
        'observedProductionSamples': observations,
        'privacy': 'aggregate only; no profile content or coordinates',
        'limitation': 'debug timings do not establish the 60Hz goal; RSS includes native map and decoded pixels; global cache excludes private image ownership',
      };
      binding.reportData = {'task13': summary};
      debugPrint('PATHS_TASK13_METRICS ${jsonEncode(summary)}');
      expect(context.mounted, true);
    },
    skip: !const bool.fromEnvironment('PATHS_RUN_FULL_JOURNEY'),
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
