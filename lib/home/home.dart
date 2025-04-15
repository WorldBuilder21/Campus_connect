import 'package:campus_conn/home/widgets/post_card.dart';
import 'package:campus_conn/profile/provider/feed_notifier.dart';
import 'package:campus_conn/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/core/widget/app_bar.dart';
import 'package:campus_conn/core/widget/loading_indicator.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:campus_conn/home/screens/search_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  // For smoother scrolling
  final ScrollController _scrollController = ScrollController();

  // Add a flag to track whether first load has completed
  bool _initialLoadComplete = false;

  // Track if we're coming back from another screen
  bool _returnedToScreen = false;

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();
    // Initialize feed data when the screen is first created
    _initializeFeed();

    // Set up a scroll listener for more efficient infinite scrolling
    _scrollController.addListener(_scrollListener);
  }

  // More efficient initialization
  Future<void> _initializeFeed() async {
    if (!mounted) return;

    // Only show loading indicator on first load
    try {
      await ref.read(feedNotifier.notifier).loadFeed();
      if (mounted) {
        setState(() {
          _initialLoadComplete = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial feed: $e');
    }
  }

  // Add a scroll listener for more efficient loading
  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    // Load more posts when near the bottom (80% of the way down)
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;

    if (currentScroll > threshold) {
      // Load more posts if not already loading
      _loadMorePostsIfNeeded();
    }
  }

  // Check if we should load more posts
  Future<void> _loadMorePostsIfNeeded() async {
    final feedState = ref.read(feedNotifier);

    // Only try to load more if we have data and aren't already loading
    if (feedState is AsyncData && !_refreshController.isLoading) {
      await ref.read(feedNotifier.notifier).loadMorePosts();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we're returning to this screen
    if (_initialLoadComplete && !_returnedToScreen) {
      _returnedToScreen = true;

      // Refresh the feed when coming back to this screen
      // This ensures new posts created elsewhere will show up
      Future.microtask(() {
        if (mounted) {
          _onRefresh();
        }
      });
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    try {
      // Clear scroll position
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }

      await ref.read(feedNotifier.notifier).refreshFeed();
      if (mounted) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      if (mounted) {
        _refreshController.refreshFailed();
        debugPrint('Refresh failed: $e');
      }
    }
  }

  Future<void> _onLoading() async {
    try {
      await ref.read(feedNotifier.notifier).loadMorePosts();
      if (mounted) {
        _refreshController.loadComplete();
      }
    } catch (e) {
      if (mounted) {
        _refreshController.loadFailed();
        debugPrint('Load more failed: $e');
      }
    }
  }

  void _navigateToSearch() {
    try {
      // Using Navigator.push with a try-catch to handle any navigation errors
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SearchScreen(),
          // Set maintainState to false to avoid keeping the state in memory
          // which can help if there are memory issues
          maintainState: false,
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to search: $e');
      // Show a user-friendly error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open search. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    debugPrint('Building HomeScreen');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'CampusConnect',
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.magnifyingGlass,
              color: AppTheme.textPrimaryColor,
              size: 20,
            ),
            onPressed: _navigateToSearch,
          ),
        ],
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: true,
        header: const WaterDropHeader(
          waterDropColor: AppTheme.primaryColor,
          complete: Icon(Icons.check, color: AppTheme.primaryColor),
        ),
        footer: CustomFooter(
          builder: (context, mode) {
            Widget body;
            if (mode == LoadStatus.idle) {
              body = Text(
                "Pull up to load more",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              );
            } else if (mode == LoadStatus.loading) {
              body = const CircularLoadingIndicator(
                size: 22,
                color: AppTheme.primaryColor,
              );
            } else if (mode == LoadStatus.failed) {
              body = Text(
                "Failed to load. Tap to retry!",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              );
            } else if (mode == LoadStatus.canLoading) {
              body = Text(
                "Release to load more",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              );
            } else {
              body = Text(
                "No more posts",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              );
            }
            return Container(
              height: 55.0,
              padding: const EdgeInsets.only(bottom: 15),
              child: Center(child: body),
            );
          },
        ),
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final feedState = ref.watch(feedNotifier);

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // Posts section
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              0, 8, 0, 100), // Reduced horizontal padding
          sliver: feedState.when(
            loading: () {
              // Only show loading state on initial load
              if (_initialLoadComplete) {
                // If we've loaded before, show last known data during refresh
                final lastData = ref.read(feedNotifier).value ?? [];
                if (lastData.isNotEmpty) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = lastData[index];
                        return PostCard(
                          post: post,
                          onLike: () => ref
                              .read(feedNotifier.notifier)
                              .toggleLike(post.id),
                          onBookmark: () => ref
                              .read(feedNotifier.notifier)
                              .toggleBookmark(post.id),
                          onProfileTap: () =>
                              _navigateToProfile(context, post.user.id!),
                        );
                      },
                      childCount: lastData.length,
                    ),
                  );
                }
              }

              // Otherwise show shimmer loading state
              debugPrint('Rendering loading state...');
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const PostShimmerLoading(),
                  childCount: 3,
                ),
              );
            },
            error: (error, stackTrace) {
              debugPrint('Rendering error state: $error');
              return SliverToBoxAdapter(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.circleExclamation,
                            size: 50, color: Colors.grey[400]),
                        const SizedBox(height: 20),
                        Text(
                          'Could not load posts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pull down to refresh and try again',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(FontAwesomeIcons.arrowsRotate,
                              size: 16),
                          label: const Text('Try Again'),
                          onPressed: () =>
                              ref.read(feedNotifier.notifier).refreshFeed(),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            data: (posts) {
              debugPrint('Rendering posts: ${posts.length}');

              // Set flag to indicate data has been loaded
              if (!_initialLoadComplete) {
                _initialLoadComplete = true;
              }

              if (posts.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60.0),
                      child: Column(
                        children: [
                          Icon(FontAwesomeIcons.newspaper,
                              size: 70, color: Colors.grey[300]),
                          const SizedBox(height: 24),
                          Text(
                            'No posts yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Follow users to see their posts here',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    return PostCard(
                      post: post,
                      onLike: () =>
                          ref.read(feedNotifier.notifier).toggleLike(post.id),
                      onBookmark: () => ref
                          .read(feedNotifier.notifier)
                          .toggleBookmark(post.id),
                      onProfileTap: () =>
                          _navigateToProfile(context, post.user.id!),
                    );
                  },
                  childCount: posts.length,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          userId: userId,
          showBackBtn: true,
        ),
      ),
    ).then((value) {
      // Set flag to indicate we've returned to this screen
      _returnedToScreen = true;

      // Refresh the feed when returning from profile
      _onRefresh();
    });
  }
}

class PostShimmerLoading extends StatelessWidget {
  const PostShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          // Image
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: Colors.grey[200],
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
