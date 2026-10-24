import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/authenticated_media_api.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/media/data/http_media_repository.dart';
import 'package:paths_mobile/features/media/presentation/media_scope.dart';
import 'package:paths_mobile/features/posts/data/post_repository.dart';
import 'package:paths_mobile/features/posts/presentation/posts_grid.dart';
import 'package:paths_mobile/features/relationships/presentation/relationship_controls.dart';
import 'package:paths_mobile/shared/widgets/paths_toast.dart';

import '../media/photo_screen_test.dart' show PhotoPickerFixture;
import '../requests/relationship_cubit_test.dart'
    show RelationshipFixture, status;
import 'posts_cubit_test.dart' show Api;

class Pages extends Api {
  bool connected = true;
  int reads = 0;
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) async {
    reads++;
    return {
      'items': connected
          ? [
              const PostDto(
                id: 'post',
                assetId: '11111111-1111-4111-8111-111111111111',
                caption: 'Private fixture caption',
                state: 'published',
                createdDate: '2026-10-17',
              ).toJson(),
            ]
          : [],
      'nextCursor': null,
      'locked': !connected,
    };
  }
}

class Relations extends RelationshipFixture {
  Relations(this.pages);
  final Pages pages;
  @override
  Future<RelationshipStatusDto> get(
    String id, {
    CancelToken? cancelToken,
  }) async => RelationshipStatusDto.fromJson({
    ...status().toJson(),
    'status': 'connected',
    'connectionId': 'connection',
  });
  @override
  Future<RelationshipStatusDto> act(
    String id,
    String action,
    String key, {
    String? resourceId,
    CancelToken? cancelToken,
  }) async {
    pages.connected = false;
    return status();
  }
}

class Binary implements AuthenticatedMediaApi {
  @override
  Future<Uint8List> imageBytes(
    String id, {
    bool thumbnail = true,
    CancelToken? cancelToken,
  }) async => throw const AuthFailure('media_unavailable');
  @override
  Future<void> uploadImage(
    String id,
    Uint8List bytes, {
    CancelToken? cancelToken,
    ProgressCallback? onProgress,
  }) async => throw const AuthFailure('media_unavailable');
}

void main() {
  testWidgets(
    'disconnect immediately revalidates a visible private post grid',
    (tester) async {
      final pages = Pages(),
          media = HttpMediaRepository(pages, Binary()),
          posts = PostRepository(pages),
          relations = Relations(pages);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => PathsToastHost(child: child!),
          home: MediaScope(
            media: media,
            picker: PhotoPickerFixture(),
            posts: posts,
            child: Builder(
              builder: (context) => Scaffold(
                body: ScrollNotificationObserver(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: RelationshipControls(
                          repository: relations,
                          target: 'owner',
                        ),
                      ),
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
      expect(find.text('Private photos'), findsNothing);
      expect(pages.reads, 1);
      await tester.tap(find.text('Disconnect'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Private photos'), findsOneWidget);
      expect(pages.reads, greaterThanOrEqualTo(2));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      media.dispose();
    },
  );
}
