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
  Future<ConversationPageDto> conversations({
    String? cursor,
    int? revision,
    String search = '',
    String? peerId,
    int limit = 20,
    CancelToken? cancelToken,
  }) => _parse(
    api.request(
      'GET',
      Uri(
        path: '/v1/conversations',
        queryParameters: {
          'limit': '$limit',
          'cursor': ?cursor,
          if (revision != null) 'revision': '$revision',
          if (search.isNotEmpty) 'search': search,
          'peerId': ?peerId,
        },
      ).toString(),
      cancelToken: cancelToken,
    ),
    ConversationPageDto.fromJson,
  );

  @override
  Future<ConversationDto> conversation(String id, {CancelToken? cancelToken}) =>
      _parse(
        api.request(
          'GET',
          '/v1/conversations/${Uri.encodeComponent(id)}',
          cancelToken: cancelToken,
        ),
        ConversationDto.fromJson,
      );

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
