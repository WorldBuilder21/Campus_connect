import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_schema.g.dart';
part 'message_schema.freezed.dart';

@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String chatId,
    required String senderId,
    required String content,
    required DateTime timestamp,
    required bool isRead,
    String? imageUrl,
    String? fileType,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}
