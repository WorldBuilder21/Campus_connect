// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationImpl _$$NotificationImplFromJson(Map<String, dynamic> json) =>
    _$NotificationImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      actorId: json['actorId'] as String,
      actorUsername: json['actorUsername'] as String,
      actorImageUrl: json['actorImageUrl'] as String?,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      postId: json['postId'] as String?,
      commentId: json['commentId'] as String?,
      chatId: json['chatId'] as String?,
      messageId: json['messageId'] as String?,
      content: json['content'] as String?,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$NotificationImplToJson(_$NotificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'actorId': instance.actorId,
      'actorUsername': instance.actorUsername,
      'actorImageUrl': instance.actorImageUrl,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'postId': instance.postId,
      'commentId': instance.commentId,
      'chatId': instance.chatId,
      'messageId': instance.messageId,
      'content': instance.content,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$NotificationTypeEnumMap = {
  NotificationType.like: 'like',
  NotificationType.comment: 'comment',
  NotificationType.follow: 'follow',
  NotificationType.message: 'message',
};
