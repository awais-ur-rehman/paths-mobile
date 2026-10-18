import 'package:dio/dio.dart';

import '../../../core/network/generated/api_contract.dart';

final class ChatSignal {
  const ChatSignal({this.resourceId, this.type = 'sync'});
  final String? resourceId;
  final String type;
}

abstract interface class ChatRepository {
  String? get accountId;
  Stream<ChatSignal> get events;
  Future<List<ConversationDto>> conversations({CancelToken? cancelToken});
  Future<ChatHistoryDto> history(
    String id, {
    String? cursor,
    String? after,
    CancelToken? cancelToken,
  });
  Future<ChatMessageDto> send(
    String id,
    String clientId,
    String text, {
    CancelToken? cancelToken,
  });
  Future<void> read(String id, int sequence, {CancelToken? cancelToken});
}
