import 'package:dio/dio.dart';

import '../../../core/network/shared_read_queue.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/profile_repository.dart';

/// One own-account snapshot; setup and peer access always use server checks.
class OwnProfileMemory {
  OwnProfileMemory({
    required this.owner,
    required this.load,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final String? Function() owner;
  final Future<ProfileSummary> Function(String, CancelToken) load;
  final DateTime Function() clock;
  ProfileSummary? _snapshot;
  DateTime? _fetchedAt;
  int _revision = 0;
  late final _reads = SharedReadQueue<(int, String), ProfileSummary>(
    load: (key, token) async {
      final result = await load(key.$2, token);
      if (token.isCancelled || key.$1 != _revision || key.$2 != owner()) {
        throw const AuthFailure('cancelled');
      }
      if (result.userId != key.$2) throw const AuthFailure('invalid_response');
      _snapshot = result;
      _fetchedAt = clock();
      return result;
    },
    copy: (value) => value,
  );

  ProfileSummary? get snapshot {
    final fetched = _fetchedAt, profile = _snapshot;
    if (fetched == null || profile == null || owner() != profile.userId) {
      return null;
    }
    final age = clock().difference(fetched);
    return age >= Duration.zero && age < const Duration(seconds: 30)
        ? profile
        : null;
  }

  Future<ProfileSummary> read({
    bool force = false,
    CancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled == true) {
      return Future.error(const AuthFailure('cancelled'));
    }
    final account = owner();
    if (account == null) {
      return Future.error(const AuthFailure('SESSION_INVALID'));
    }
    final cached = snapshot;
    if (!force && cached != null) return Future.value(cached);
    final revision = _revision;
    try {
      return await _reads.read((revision, account), cancelToken: cancelToken);
    } on AuthFailure catch (error) {
      if (revision == _revision &&
          !error.offline &&
          error.code != 'cancelled') {
        invalidate();
      }
      rethrow;
    }
  }

  void invalidate() {
    _revision++;
    _snapshot = null;
    _fetchedAt = null;
    _reads.clear();
  }

  void dispose() {
    invalidate();
    _reads.dispose();
  }
}
