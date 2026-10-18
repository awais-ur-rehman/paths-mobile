import 'package:dio/dio.dart';

import '../../../core/network/authenticated_api.dart';
import '../../../core/network/generated/api_contract.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/chat_repository.dart';

final class HttpChatRepository implements ChatRepository {
  HttpChatRepository(this.api, this.events);
  final AuthenticatedApi api;
  @override
  final Stream<ChatSignal> events;
  @override
  String? get accountId => api.accountId;
  Future<T> _parse<T>(
    Future<Map<String, dynamic>> response,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      return parse(await response);
    } on FormatException {
      throw const AuthFailure('invalid_response');
    }
  }

  @override
  Future<List<ConversationDto>> conversations({
    CancelToken? cancelToken,
  }) async {
    final account = accountId;
    for (var attempt = 0; attempt < 3; attempt++) {
      final all = <ConversationDto>[];
      String? cursor;
      int? revision;
      try {
        do {
          final page = await _parse(
            api.request(
              'GET',
              Uri(
                path: '/v1/conversations',
                queryParameters: {
                  'limit': '50',
                  'cursor': ?cursor,
                  if (revision != null) 'revision': '$revision',
                },
              ).toString(),
              cancelToken: cancelToken,
            ),
            ConversationPageDto.fromJson,
          );
          if (account == null || account != accountId) {
            throw const AuthFailure('cancelled');
          }
          revision ??= page.revision;
          if (page.revision != revision) throw const AuthFailure('conflict');
          all.addAll(page.items);
          cursor = page.nextCursor;
        } while (cursor != null);
        all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return List.unmodifiable(all);
      } on AuthFailure catch (e) {
        if (!const {'CONFLICT', 'conflict'}.contains(e.code)) rethrow;
        if (attempt == 2) rethrow;
      }
    }
    throw const AuthFailure('conflict');
  }

  @override
  Future<ChatHistoryDto> history(
    String id, {
    String? cursor,
    String? after,
    CancelToken? cancelToken,
  }) => _parse(
    api.request(
      'GET',
      Uri(
        path: '/v1/conversations/${Uri.encodeComponent(id)}/messages',
        queryParameters: {'limit': '50', 'cursor': ?cursor, 'after': ?after},
      ).toString(),
      cancelToken: cancelToken,
    ),
    ChatHistoryDto.fromJson,
  );
  @override
  Future<ChatMessageDto> send(
    String id,
    String clientId,
    String text, {
    CancelToken? cancelToken,
  }) => _parse(
    api.request(
      'POST',
      '/v1/conversations/${Uri.encodeComponent(id)}/messages',
      data: SendMessageInput(clientMessageId: clientId, text: text).toJson(),
      cancelToken: cancelToken,
    ),
    ChatMessageDto.fromJson,
  );
  @override
  Future<void> read(String id, int sequence, {CancelToken? cancelToken}) async {
    await api.request(
      'POST',
      '/v1/conversations/${Uri.encodeComponent(id)}/read',
      data: ReadMessagesInput(sequence: sequence).toJson(),
      cancelToken: cancelToken,
    );
  }
}
