import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/media/data/http_media_repository.dart';
import 'package:paths_mobile/features/media/presentation/media_scope.dart';
import 'package:paths_mobile/features/posts/data/post_repository.dart';
import 'package:paths_mobile/features/posts/presentation/posts_grid.dart';

import '../posts/posts_cubit_test.dart' show Api;
import '../posts/post_revocation_test.dart' show Binary;
import '../media/photo_screen_test.dart' show PhotoPickerFixture;

class PhotoPages extends Api {
  final cursors = <String?>[];
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) async {
    final cursor = Uri.parse(path).queryParameters['cursor'];
    cursors.add(cursor);
    if (cursors.length == 2) throw const AuthFailure('offline');
    return {
      'items': [
        for (var i = 0; i < (cursor == null ? 20 : 21); i++)
          PostDto(
            id: 'p$i',
            assetId: 'image$i',
            caption: '',
            state: 'published',
            createdDate: '2026-01-01',
          ).toJson(),
      ],
      'nextCursor': cursor == null ? 'next' : null,
      'locked': false,
    };
  }
}

void main() {
  testWidgets(
    'photo grid builds lazily, pauses after errors and retries its cursor',
    (tester) async {
      final api = PhotoPages(), media = HttpMediaRepository(Api(), Binary());
      await tester.pumpWidget(
        MaterialApp(
          home: MediaScope(
            media: media,
            picker: PhotoPickerFixture(),
            posts: PostRepository(api),
            child: Builder(
              builder: (context) => Scaffold(
                body: ScrollNotificationObserver(
                  child: CustomScrollView(
                    slivers: [
                      PostsGrid(
                        scope: MediaScope.maybeOf(context)!,
                        owner: 'owner',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(api.cursors, [null]);
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(SliverGrid), findsOneWidget);
      expect(find.bySemanticsLabel('Photo 20'), findsNothing);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
      await tester.pumpAndSettle();
      expect(api.cursors, [null, 'next']);
      expect(find.text('You’re offline · Retry'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(api.cursors, hasLength(2));
      await tester.tap(find.text('You’re offline · Retry'));
      await tester.pumpAndSettle();
      expect(api.cursors, [null, 'next', 'next']);
      expect(find.text('You’re offline · Retry'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      media.dispose();
    },
  );
}
