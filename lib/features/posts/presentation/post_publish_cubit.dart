import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/authenticated_api.dart';
import '../../auth/domain/auth_models.dart';
import '../data/post_repository.dart';

class PostPublishState {
  const PostPublishState({this.busy = false, this.postId, this.error});
  final bool busy;
  final String? postId;
  final AuthFailure? error;
}

class PostPublishCubit extends Cubit<PostPublishState> {
  PostPublishCubit(this.repository) : super(const PostPublishState());
  final PostRepository repository;
  final _token = CancelToken();
  String? _key, _asset, _caption;
  Future<void> publish(String asset, String caption) async {
    if (isClosed || state.busy || state.postId != null) return;
    final owner = repository.accountId;
    if (owner == null) return;
    if (_asset != asset || _caption != caption) {
      _key = newIntentKey();
      _asset = asset;
      _caption = caption;
    }
    emit(const PostPublishState(busy: true));
    try {
      final post = await repository.create(
        asset,
        caption,
        _key!,
        cancelToken: _token,
      );
      if (!isClosed && owner == repository.accountId) {
        emit(PostPublishState(postId: post.id));
      }
    } catch (error) {
      if (!isClosed && owner == repository.accountId) {
        emit(
          PostPublishState(
            error: error is AuthFailure
                ? error
                : const AuthFailure('unavailable'),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _token.cancel();
    return super.close();
  }
}
