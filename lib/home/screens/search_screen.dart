import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/core/widget/loading_indicator.dart';
import 'package:campus_conn/profile/screens/profile_screen.dart';
import 'package:campus_conn/home/provider/user_search_provider.dart';
import 'package:campus_conn/profile/provider/profile_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  static const routeName = '/search';

  const SearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _showClearButton = false;

  // State for follow button
  bool _isProcessingFollow = false;
  String? _processingUserId;

  // Animation for better UI transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    // Add try-catch to prevent crashes during initialization
    try {
      // Load suggested users on start
      Future.microtask(() {
        if (mounted) {
          ref.read(userSearchProvider.notifier).getSuggestedUsers();
        }
      });

      // Set up listeners
      _searchController.addListener(() {
        if (mounted) {
          setState(() {
            _showClearButton = _searchController.text.isNotEmpty;
          });

          // Update search query provider
          ref.read(searchQueryProvider.notifier).state = _searchController.text;
        }
      });

      // Request focus for search field
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    } catch (e) {
      debugPrint('Error in SearchScreen initialization: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (!mounted) return;

    final query = _searchController.text.trim();
    setState(() {
      _isSearching = true;
    });

    try {
      // Use Future to catch any async errors
      Future.microtask(() async {
        try {
          await ref.read(userSearchProvider.notifier).searchUsers(query);
        } catch (e) {
          debugPrint('Error in search operation: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Search failed. Please try again.'),
                backgroundColor: Colors.red[400],
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        }
      });
    } catch (e) {
      debugPrint('Error performing search: $e');
    }
  }

  void _clearSearch() {
    if (!mounted) return;

    _searchController.clear();
    _searchFocusNode.requestFocus();
    try {
      ref.read(searchQueryProvider.notifier).state = '';
      ref.read(userSearchProvider.notifier).getSuggestedUsers();
    } catch (e) {
      debugPrint('Error clearing search: $e');
    }
    setState(() {
      _isSearching = false;
    });
  }

  void _navigateToProfile(String? userId) async {
    if (userId != null && userId.isNotEmpty) {
      // Navigate to profile screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            userId: userId,
            showBackBtn: true,
          ),
        ),
      );

      // When returning from profile, refresh the search results to sync follow state
      if (mounted) {
        final currentQuery = ref.read(searchQueryProvider);
        if (currentQuery.isEmpty) {
          ref.read(userSearchProvider.notifier).getSuggestedUsers();
        } else {
          ref.read(userSearchProvider.notifier).searchUsers(currentQuery);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot view this profile'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // Toggle follow status with improved handling and sync with profile provider
  void _toggleFollow(String userId) async {
    // Prevent double-taps during processing
    if (_isProcessingFollow) return;

    try {
      // Set processing state
      setState(() {
        _isProcessingFollow = true;
        _processingUserId = userId;
      });

      // Call the toggle function in search provider
      await ref.read(userSearchProvider.notifier).toggleFollow(userId);

      // Check if there's an active profile provider for this user and sync it
      try {
        // This will sync the follow status in the profile provider if it exists
        final hasProfile = ref.exists(profileProvider(userId));
        if (hasProfile) {
          await ref
              .read(profileProvider(userId).notifier)
              .refreshFollowStatus();
          debugPrint(
              'Synced follow status with profile provider for user $userId');
        }
      } catch (e) {
        debugPrint('Error syncing with profile provider: $e');
        // Continue normally as this is just a sync operation
      }

      // Reset state after operation completes
      if (mounted) {
        setState(() {
          _isProcessingFollow = false;
          _processingUserId = null;
        });
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');

      // Reset state and show error
      if (mounted) {
        setState(() {
          _isProcessingFollow = false;
          _processingUserId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update follow status'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsState = ref.watch(userSearchProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Status bar space
            SizedBox(height: MediaQuery.of(context).padding.top),

            // Search header
            _buildSearchHeader(),

            // Main content
            Expanded(
              child: _buildPeopleResults(searchResultsState, searchQuery),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 22),
              onPressed: () => Navigator.pop(context),
              splashRadius: 24,
            ),
          ),

          // Search field
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!, width: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              margin: const EdgeInsets.only(left: 8),
              child: Center(
                child: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[500],
                          ),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          // Remove any decoration that might cause visual issues
                          counterText: '',
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        textInputAction: TextInputAction.search,
                        showCursor: true,
                        cursorColor: AppTheme.primaryColor,
                        cursorWidth: 1.2,
                        onSubmitted: (_) => _performSearch(),
                        onChanged: (_) {
                          if (!_isSearching) {
                            setState(() {
                              _isSearching = true;
                            });
                          }

                          // Simple debounce
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted && _searchController.text == _) {
                              _performSearch();
                            }
                          });
                        },
                      ),
                    ),
                    if (_showClearButton)
                      GestureDetector(
                        onTap: _clearSearch,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleResults(
      AsyncValue<List<UserWithFollowStatus>> searchResults, String query) {
    // Handle loading state
    if (searchResults is AsyncLoading) {
      return const Center(child: CircularLoadingIndicator(size: 30));
    }

    // Handle error state
    if (searchResults is AsyncError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.circleExclamation,
              size: 50,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try again later',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Get the actual data with null safety
    final users = searchResults.value ?? [];

    // Handle empty results
    if (users.isEmpty) {
      if (query.isNotEmpty) {
        // No results for search
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.userLarge,
                size: 60,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 24),
              Text(
                'No users found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      } else {
        // No suggested users
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.users,
                size: 60,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 24),
              Text(
                'No users to suggest yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Come back later',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }
    }

    // Display users in a premium Instagram-style list
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header - suggested or search results
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  query.isNotEmpty ? 'Search Results' : 'Suggested for You',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                // Number of results
                Text(
                  '${users.length} ${users.length == 1 ? 'user' : 'users'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),

        // User list (Premium Instagram style)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildUserListItem(users[index]),
              childCount: users.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserListItem(UserWithFollowStatus userWithStatus) {
    final user = userWithStatus.account;
    final isFollowing = userWithStatus.isFollowing;

    return InkWell(
      onTap: () => _navigateToProfile(user.id),
      splashColor: Colors.transparent,
      highlightColor: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // User Avatar with premium border
            GestureDetector(
              onTap: () => _navigateToProfile(user.id),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: user.image_url == null || user.image_url!.isEmpty
                      ? Container(
                          color: Colors.grey[200],
                          child: Icon(
                            FontAwesomeIcons.userLarge,
                            size: 20,
                            color: Colors.grey[400],
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: user.image_url!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularLoadingIndicator(size: 20),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              FontAwesomeIcons.circleExclamation,
                              size: 20,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username ?? 'User',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  if (user.email != null && user.email!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        user.email!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Follow/Following button with improved touch handling
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (_isProcessingFollow && _processingUserId == user.id)
                    ? null
                    : () => _toggleFollow(user.id!),
                borderRadius: BorderRadius.circular(8),
                splashColor: Colors.grey.withOpacity(0.1),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isFollowing ? Colors.white : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFollowing
                          ? Colors.grey[300]!
                          : AppTheme.primaryColor,
                      width: 1,
                    ),
                  ),
                  child: (_isProcessingFollow && _processingUserId == user.id)
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFollowing
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isFollowing ? Colors.black87 : Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
