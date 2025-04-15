// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostImpl _$$PostImplFromJson(Map<String, dynamic> json) => _$PostImpl(
      id: json['id'] as String,
      caption: json['caption'] as String,
      imageUrl: json['imageUrl'] as String,
      user: Account.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      likes: (json['likes'] as num).toInt(),
      comments: (json['comments'] as num).toInt(),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      isLiked: json['isLiked'] as bool,
      isBookmarked: json['isBookmarked'] as bool,
    );

Map<String, dynamic> _$$PostImplToJson(_$PostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'caption': instance.caption,
      'imageUrl': instance.imageUrl,
      'user': instance.user,
      'createdAt': instance.createdAt.toIso8601String(),
      'likes': instance.likes,
      'comments': instance.comments,
      'tags': instance.tags,
      'isLiked': instance.isLiked,
      'isBookmarked': instance.isBookmarked,
    };
