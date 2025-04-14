// Profile state class
import 'package:campus_conn/auth/schemas/account.dart';
import 'package:campus_conn/profile/schemas/post_schema.dart';

class ProfileState {
  final Account? user;
  final List<Post> posts;
  final List<Post> savedPosts;
  final bool isLoading;
  final bool isFollowing;
  final int followerCount;  // Added follower count
  final int followingCount; // Added following count
  final String? error;

  ProfileState({
    this.user,
    required this.posts,
    required this.savedPosts,
    required this.isLoading,
    required this.isFollowing,
    this.followerCount = 0,  // Default to 0
    this.followingCount = 0, // Default to 0
    this.error,
  });

  // Create a copy with updated values
  ProfileState copyWith({
    Account? user,
    List<Post>? posts,
    List<Post>? savedPosts,
    bool? isLoading,
    bool? isFollowing,
    int? followerCount,
    int? followingCount,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      posts: posts ?? this.posts,
      savedPosts: savedPosts ?? this.savedPosts,
      isLoading: isLoading ?? this.isLoading,
      isFollowing: isFollowing ?? this.isFollowing,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      error: error ?? this.error,
    );
  }
}