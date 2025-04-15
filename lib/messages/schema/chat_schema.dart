import 'package:campus_conn/auth/schemas/account.dart';
import 'package:campus_conn/messages/schema/message_schema.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_schema.g.dart';
part 'chat_schema.freezed.dart';

@freezed
class Chat with _$Chat {
  const factory Chat({
    required String id,
    required Account user,
    required String lastMessage,
    required DateTime lastMessageTime,
    required int unreadCount,
    List<Message>? messages,
  }) = _Chat;

  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);
}
