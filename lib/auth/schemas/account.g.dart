// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountImpl _$$AccountImplFromJson(Map<String, dynamic> json) =>
    _$AccountImpl(
      id: json['id'] as String?,
      image_url: json['image_url'] as String?,
      image_id: json['image_id'] as String?,
      email: json['email'] as String?,
      username: json['username'] as String?,
      email_verified: json['email_verified'] as bool?,
      fcm_token: json['fcm_token'] as String?,
      created_at: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      bio: json['bio'] as String?,
      is_private: json['is_private'] as bool?,
      show_activity: json['show_activity'] as bool?,
    );

Map<String, dynamic> _$$AccountImplToJson(_$AccountImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'image_url': instance.image_url,
      'image_id': instance.image_id,
      'email': instance.email,
      'username': instance.username,
      'email_verified': instance.email_verified,
      'fcm_token': instance.fcm_token,
      'created_at': instance.created_at?.toIso8601String(),
      'bio': instance.bio,
      'is_private': instance.is_private,
      'show_activity': instance.show_activity,
    };
