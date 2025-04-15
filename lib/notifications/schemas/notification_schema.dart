import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_schema.g.dart';
part 'notification_schema.freezed.dart';

enum NotificationType {
  like,
  comment,
  follow,
  message,
}

@freezed
class Notification with _$Notification {
  const factory Notification({
    required String id,
    required String userId,
    required String actorId,
    required String actorUsername,
    String? actorImageUrl,
    required NotificationType type,
    String? postId,
    String? commentId,
    String? chatId,
    String? messageId,
    String? content,
    required bool isRead,
    required DateTime createdAt,
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);
}
