import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/domain/auth_models.dart';
import '../domain/verification_repository.dart';

final class VerificationState {
  const VerificationState({
    this.info,
    this.front,
    this.back,
    this.consent = false,
    this.loading = false,
    this.busy = false,
    this.uploading = false,
    this.error,
    this.skipRevision = 0,
    this.submitRevision = 0,
  });
  final VerificationInfo? info;
  final DocumentAsset? front, back;
  final bool consent, loading, busy, uploading;
  final AuthFailure? error;
  final int skipRevision, submitRevision;
  VerificationState copy({
    VerificationInfo? info,
    DocumentAsset? front,
    DocumentAsset? back,
    bool? consent,
    bool? loading,
    bool? busy,
    bool? uploading,
    AuthFailure? error,
    int? skipRevision,
    int? submitRevision,
  }) => VerificationState(
    info: info ?? this.info,
    front: front ?? this.front,
    back: back ?? this.back,
    consent: consent ?? this.consent,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    uploading: uploading ?? this.uploading,
    error: error,
    skipRevision: skipRevision ?? this.skipRevision,
    submitRevision: submitRevision ?? this.submitRevision,
  );
  bool get canSubmit =>
      !busy &&
      !loading &&
      info?.uploadsAvailable == true &&
      info?.status != 'pending' &&
      info?.status != 'approved' &&
      front?.processed == true &&
      (back == null || back!.processed) &&
      consent;
}

class VerificationCubit extends Cubit<VerificationState> {
  VerificationCubit(this.repository, this.documents)
    : super(const VerificationState(loading: true));
  final VerificationRepository repository;
  final VerificationDocuments documents;
  CancelToken? _request;
  int _generation = 0;
  Future<void> _run(
    Future<VerificationState> Function(CancelToken) operation, {
    bool loading = false,
    bool uploading = false,
  }) async {
    if (isClosed) return;
    _request?.cancel();
    final token = _request = CancelToken();
    final generation = ++_generation;
    emit(state.copy(busy: !loading, loading: loading, uploading: uploading));
    try {
      final result = await operation(token);
      if (!isClosed && generation == _generation) {
        emit(result.copy(busy: false, loading: false, uploading: false));
      }
    } on AuthFailure catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          state.copy(
            busy: false,
            loading: false,
            uploading: false,
            error: error,
          ),
        );
      }
    } catch (_) {
      if (!isClosed && generation == _generation) {
        emit(
          state.copy(
            busy: false,
            loading: false,
            uploading: false,
            error: const AuthFailure('unavailable'),
          ),
        );
      }
    }
  }

  VerificationInfo _forApp(VerificationInfo info) => VerificationInfo(
    status: info.status,
    offerSeen: info.offerSeen,
    reason: info.reason,
    uploadsAvailable: info.uploadsAvailable && documents.available,
  );
  Future<void> refresh() async {
    if (isClosed || state.loading || state.busy) return;
    await load();
  }

  Future<void> load() => _run(
    (token) async => state.copy(
      info: _forApp(await repository.loadVerification(cancelToken: token)),
    ),
    loading: true,
  );
  void setConsent(bool value) {
    if (!isClosed && !state.busy) emit(state.copy(consent: value));
  }

  Future<void> pick(DocumentSide side) async {
    if (isClosed ||
        state.busy ||
        state.loading ||
        state.info?.uploadsAvailable != true ||
        state.info?.status == 'pending' ||
        state.info?.status == 'approved') {
      return;
    }
    await _run((token) async {
      final asset = await documents.pickAndUpload(side, cancelToken: token);
      return side == DocumentSide.front
          ? state.copy(front: asset)
          : state.copy(back: asset);
    }, uploading: true);
  }

  Future<void> submit() async {
    if (isClosed || !state.canSubmit) return;
    final front = state.front!, back = state.back;
    await _run(
      (token) async => state.copy(
        info: _forApp(
          await repository.submitVerification(
            frontAssetId: front.id,
            backAssetId: back?.id,
            consent: true,
            cancelToken: token,
          ),
        ),
        submitRevision: state.submitRevision + 1,
      ),
    );
  }

  Future<void> skip() async {
    if (isClosed || (state.busy && !state.uploading)) return;
    await _run(
      (token) async => state.copy(
        info: _forApp(await repository.skipVerification(cancelToken: token)),
        skipRevision: state.skipRevision + 1,
      ),
    );
  }

  @override
  Future<void> close() {
    _generation++;
    _request?.cancel();
    return super.close();
  }
}
