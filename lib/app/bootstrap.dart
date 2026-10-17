import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/network/generated/api_contract.dart';

/// Explicitly invoked by a route owner; constructing this object performs no I/O.
final class AppBootstrap {
  AppBootstrap(this._api);
  final ApiClient _api;
  Future<HealthDto> check({CancelToken? cancelToken}) =>
      _api.readiness(cancelToken: cancelToken);
}
