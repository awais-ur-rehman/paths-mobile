import 'package:dio/dio.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';

class NotificationRepository {
  NotificationRepository(this.api);
  final AuthenticatedApi api;
  String? get accountId => api.accountId;
  Future<T> _parse<T>(
    Future<Map<String, dynamic>> request,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      return parse(await request);
    } on FormatException {
      throw const AuthFailure('invalid_response');
    }
  }

  Future<NotificationPageDto> page({
    String? cursor,
    CancelToken? cancelToken,
  }) => _parse(
    api.request(
      'GET',
      Uri(
        path: '/v1/notifications',
        queryParameters: {'cursor': ?cursor},
      ).toString(),
      cancelToken: cancelToken,
    ),
    NotificationPageDto.fromJson,
  );
  Future<NotificationResolutionDto> resolve(
    String id, {
    CancelToken? cancelToken,
  }) => _parse(
    api.request(
      'GET',
      '/v1/notifications/${Uri.encodeComponent(id)}',
      cancelToken: cancelToken,
    ),
    NotificationResolutionDto.fromJson,
  );
  Future<void> read(String id) async {
    await _parse(
      api.request('POST', '/v1/notifications/${Uri.encodeComponent(id)}/read'),
      NotificationReadDto.fromJson,
    );
  }

  Future<NotificationPreferencesDto> preferences() => _parse(
    api.request('GET', '/v1/me/notification-preferences'),
    NotificationPreferencesDto.fromJson,
  );
  Future<NotificationPreferencesDto> setPreferences(
    NotificationPreferencesDto input,
  ) => _parse(
    api.request('PUT', '/v1/me/notification-preferences', data: input.toJson()),
    NotificationPreferencesDto.fromJson,
  );
  Future<DeviceDto> register(DeviceInput input) => _parse(
    api.request('POST', '/v1/devices', data: input.toJson()),
    DeviceDto.fromJson,
  );
  Future<void> remove(String id) async {
    await _parse(
      api.request('DELETE', '/v1/devices/${Uri.encodeComponent(id)}'),
      DeviceRemovedDto.fromJson,
    );
  }
}
