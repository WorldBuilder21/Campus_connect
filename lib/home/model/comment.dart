// Comment model
import 'package:campus_conn/auth/schemas/account.dart';

class Comment {
  final String id;
  final String postId;
  final Account user;
  final String content;
  final DateTime createdAt;
  int likes;
  bool isLiked;

  Comment({
    required this.id,
    required this.postId,
    required this.user,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.isLiked = false,
  });
}
