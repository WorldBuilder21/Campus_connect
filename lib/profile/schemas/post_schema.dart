import 'package:campus_conn/auth/schemas/account.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_schema.g.dart';
part 'post_schema.freezed.dart';

@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required String caption,
    required String imageUrl,
    required Account user,
    required DateTime createdAt,
    required int likes,
    required int comments,
    required List<String> tags,
    required bool isLiked,
    required bool isBookmarked,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
