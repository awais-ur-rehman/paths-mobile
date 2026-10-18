import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/safety_repository.dart';

enum EvidenceProblem { unavailable, expired }

final class ReportState {
  const ReportState({
    this.busy = false,
    this.preparing = false,
    this.blocked = false,
    this.receipt,
    this.error,
    this.problem,
  });
  final bool busy, preparing, blocked;
  final String? receipt;
  final AuthFailure? error;
  final EvidenceProblem? problem;
}

class ReportCubit extends Cubit<ReportState> {
  ReportCubit(
    this.repository,
    this.target, {
    int Function()? elapsedMilliseconds,
  }) : _account = repository.accountId,
       _kind = target.kind,
       _blocked = target.alreadyBlocked,
       super(ReportState(blocked: target.alreadyBlocked)) {
    _clock.start();
    _elapsed = elapsedMilliseconds ?? () => _clock.elapsedMilliseconds;
  }
  final SafetyRepository repository;
  final SafetyTarget target;
  final String? _account;
  final _cancel = CancelToken(), _clock = Stopwatch();
  late final int Function() _elapsed;
  String _kind;
  String get kind => _kind;
  bool _busy = false, _blocked, _preparing = false;
  String? _receipt, _grantId, _attemptPayload;
  String _grantIntent = newIntentKey();
  int? _grantUntil;
  ReportInput? _attempt;
  Future<void>? _preparation;
  EvidenceProblem? _problem;
  bool get valid =>
      !isClosed && repository.accountId == _account && _account != null;
  bool get _fresh =>
      _grantId != null && _grantUntil != null && _elapsed() < _grantUntil!;
  void _publish([AuthFailure? error]) {
    if (valid) {
      emit(
        ReportState(
          busy: _busy,
          preparing: _preparing,
          blocked: _blocked,
          receipt: _receipt,
          error: error,
          problem: _problem,
        ),
      );
    }
  }

  AuthFailure _failure(Object e) =>
      e is AuthFailure ? e : const AuthFailure('unavailable');
  Future<void> _capture({bool renew = false}) async {
    if (_kind != 'post' || (_fresh && !renew)) return;
    if (_preparation != null) return _preparation!;
    if (renew || _grantId != null) {
      _grantIntent = newIntentKey();
      _grantId = null;
      _grantUntil = null;
    }
    _preparing = true;
    _publish();
    final request = repository
        .preparePost(
          ReportEvidenceInput(
            clientGrantId: _grantIntent,
            subjectId: target.subjectId,
            contentId: target.contentId!,
          ),
          cancelToken: _cancel,
        )
        .then((grant) {
          if (!valid || _kind != 'post') return;
          if (grant.validForSeconds < 0 || grant.validForSeconds > 900) {
            throw const AuthFailure('invalid_response');
          }
          _grantId = grant.grantId;
          _grantUntil = _elapsed() + grant.validForSeconds * 1000;
          _problem = null;
        });
    _preparation = request;
    try {
      await request;
    } finally {
      _preparation = null;
      _preparing = false;
    }
  }

  Future<void> prepare() async {
    if (_kind != 'post' || !valid) return;
    AuthFailure? error;
    try {
      await _capture();
    } catch (e) {
      error = _failure(e);
      if (_blocked) _problem = EvidenceProblem.unavailable;
    }
    _publish(error);
  }

  ReportInput _input(String category, String details) => ReportInput(
    clientReportId: newIntentKey(),
    subjectId: target.subjectId,
    kind: _kind,
    contentId: _kind == 'profile' ? null : target.contentId,
    category: category,
    details: details,
    evidenceGrantId: _kind == 'post' ? _grantId : null,
  );
  Future<void> submit(String category, String details) async {
    if (_busy || _receipt != null || !valid || _problem != null) return;
    if (details.runes.length > 1000) {
      _publish(const AuthFailure('report_length'));
      return;
    }
    _busy = true;
    _publish();
    AuthFailure? error;
    try {
      final payload = '$_kind\u0000$category\u0000$details';
      if (_attempt == null || _attemptPayload != payload) {
        if (_kind == 'post' && _blocked && !_fresh) {
          _problem = EvidenceProblem.expired;
          return;
        }
        await _capture();
        if (!valid) return;
        _attempt = _input(category, details);
        _attemptPayload = payload;
      }
      ReportReceiptDto receipt;
      try {
        receipt = await repository.report(_attempt!, cancelToken: _cancel);
      } catch (e) {
        // First retry the original body: a previous response may have been lost after commit.
        if (_kind != 'post' || _failure(e).code != 'NOT_FOUND' || _fresh) {
          rethrow;
        }
        if (_blocked) {
          _problem = EvidenceProblem.expired;
          return;
        }
        await _capture(renew: true);
        if (!valid) return;
        _attempt = _input(category, details);
        receipt = await repository.report(_attempt!, cancelToken: _cancel);
      }
      if (valid) _receipt = receipt.id;
    } catch (e) {
      error = _failure(e);
      if (_kind == 'post' && error.code == 'NOT_FOUND') {
        _problem = EvidenceProblem.unavailable;
      }
    } finally {
      _busy = false;
      _publish(error);
    }
  }

  Future<void> block() async {
    if (_busy || _blocked || !valid) return;
    _busy = true;
    _publish();
    AuthFailure? error;
    try {
      // Blocking never waits for, or depends on, report-evidence preparation.
      await repository.block(target.subjectId, cancelToken: _cancel);
      if (!valid) return;
      _blocked = true;
      if (_kind == 'post' && !_fresh && !_preparing) {
        _problem = EvidenceProblem.unavailable;
      }
    } catch (e) {
      error = _failure(e);
    } finally {
      _busy = false;
      _publish(error);
    }
  }

  void reportMemberInstead() {
    if (_busy || !valid) return;
    _kind = 'profile';
    _problem = null;
    _attempt = null;
    _attemptPayload = null;
    _publish();
  }

  @override
  Future<void> close() {
    _cancel.cancel();
    _clock.stop();
    return super.close();
  }
}
