import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/review_repository.dart';

final class ReviewSubmitState {
  const ReviewSubmitState({this.busy = false, this.sent = false, this.error});
  final bool busy, sent;
  final AuthFailure? error;
}

class ReviewSubmitCubit extends Cubit<ReviewSubmitState> {
  ReviewSubmitCubit(this.repository, this.draft)
    : super(const ReviewSubmitState());
  final ReviewRepository repository;
  final ReviewDraft draft;
  final _cancel = CancelToken();
  String? _explanation;
  String _id = newIntentKey();
  Future<void> submit(String explanation) async {
    if (isClosed || state.busy || state.sent) return;
    final owner = repository.accountId;
    if (owner == null) return;
    if (explanation.trim().isEmpty || explanation.runes.length > 500) return;
    if (_explanation != null && _explanation != explanation) {
      _id = newIntentKey();
    }
    _explanation = explanation;
    emit(const ReviewSubmitState(busy: true));
    try {
      await repository.submit(
        AppealInput(
          clientId: _id,
          kind: draft.kind,
          content: draft.content,
          explanation: explanation,
          conversationId: draft.conversationId,
          assetId: draft.assetId,
        ),
        cancelToken: _cancel,
      );
      if (!isClosed && owner == repository.accountId) {
        emit(const ReviewSubmitState(sent: true));
      }
    } catch (e) {
      if (!isClosed && owner == repository.accountId) {
        emit(
          ReviewSubmitState(
            error: e is AuthFailure ? e : const AuthFailure('unavailable'),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _cancel.cancel();
    return super.close();
  }
}
