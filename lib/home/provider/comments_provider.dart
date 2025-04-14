// Comments provider
import 'package:campus_conn/home/model/comment.dart';
import 'package:campus_conn/home/provider/comment_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final commentsProvider = StateNotifierProvider.family<CommentsNotifier,
    AsyncValue<List<Comment>>, String>(
  (ref, postId) => CommentsNotifier(postId),
);
