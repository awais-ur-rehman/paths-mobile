import 'package:dio/dio.dart';
import 'package:paths_mobile/shared/widgets/paths_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/features/deletion/domain/deletion_repository.dart';
import 'package:paths_mobile/features/deletion/presentation/deletion_screen.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';

class OfflineDeletion implements DeletionRepository {
  int sends = 0;
  @override
  Future<DeletionRecord?> saved() async => null;
  @override
  Future<DeletionRecord> submit(
    String password, {
    CancelToken? cancelToken,
  }) async {
    sends++;
    throw const AuthFailure('offline');
  }

  @override
  Future<DeletionRecord?> refresh({CancelToken? cancelToken}) async =>
      const DeletionRecord(error: AuthFailure('deletion_unconfirmed'));
  @override
  Future<void> dismiss() async {}
  @override
  void close() {}
}

void main() {
  testWidgets(
    'deletion requires explicit consent and offline requests never show acceptance at large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = OfflineDeletion();
      var accepted = false;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: PathsToastHost(child: child!),
          ),
          home: DeletionScreen(
            repository: repo,
            onAccepted: () => accepted = true,
          ),
        ),
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.enterText(
        find.byType(TextFormField),
        'Fixture password 123',
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(repo.sends, 1);
      expect(accepted, false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    },
  );
  testWidgets(
    'unconfirmed receipt can return without dismissing the recovery proof',
    (tester) async {
      var returned = false;
      await tester.pumpWidget(
        MaterialApp(
          home: DeletionReceiptScreen(
            repository: OfflineDeletion(),
            onDone: () => returned = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Return to Paths'));
      expect(returned, true);
      expect(find.text('Deletion accepted'), findsNothing);
    },
  );
}
