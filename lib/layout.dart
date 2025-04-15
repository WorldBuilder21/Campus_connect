import 'package:campus_conn/auth/api/auth_repository.dart';
import 'package:campus_conn/home/home.dart';
import 'package:campus_conn/location/screens/nearby_user_map.dart';
import 'package:campus_conn/notifications/screens/notifications_screen.dart';
import 'package:campus_conn/notifications/service/fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:campus_conn/messages/screens/chat_list_screen.dart';
import 'package:campus_conn/profile/screens/profile_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/profile/screens/create_post_screen.dart';
// Import our improved bottom navigation bar
import 'package:campus_conn/core/widget/improved_bottom_nav.dart';

class Layout extends ConsumerStatefulWidget {
  static const routeName = '/layout';
  const Layout({super.key});

  @override
  ConsumerState<Layout> createState() => _LayoutState();
}

class _LayoutState extends ConsumerState<Layout>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  // For smooth transition animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(keepPage: true);

    // Animation controller for smooth transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _animationController.forward();

    // Initialize the feed when the layout is first loaded
    debugPrint('Initializing layout and feed');

    // Initialize FCM service when the layout is first created
    // This sets up Firebase Cloud Messaging for push notifications
    Future.microtask(() {
      ref.read(fcmServiceProvider);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Change page when tapping on bottom nav bar item with smooth transition
  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    // Animate page transition
    _animationController.reset();
    _pageController.jumpToPage(_currentIndex);
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building Layout with currentIndex: $_currentIndex');

    // Get current user ID for profile page
    final authRepo = ref.read(authRepositoryProvider);
    String userId;

    try {
      userId = authRepo.userId;
      debugPrint('Current user ID: $userId');
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      userId = '';
    }

    // Determine if we should show the FAB
    // Only show on Home screen to avoid duplication with Profile's FAB
    final bool showFab = _currentIndex == 0 || _currentIndex == 4;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swiping
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            // Main screens
            const HomeScreen(), // Index 0
            const ChatListScreen(), // Index 1
            const NotificationScreen(), // Index 2 - Notification Screen
            const NearbyUsersMapScreen(), // Index 3 - Map Screen
            ProfileScreen(
              userId: userId,
              showBackBtn: false,
            ), // Index 4
          ],
        ),
      ),
      extendBody: true, // Make bottom nav bar float over content
      // Using our improved bottom navigation bar
      bottomNavigationBar: ImprovedBottomNavBar(
        currentIndex: _currentIndex,
        onTabTapped: _onTabTapped,
      ),
      floatingActionButton: showFab ? _buildFloatingActionButton() : null,
    );
  }

  // Improved floating action button
  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          // Direct navigation instead of using a named route
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        heroTag: 'create_post',
        elevation: 0,
        backgroundColor: Colors.transparent, // Use container's gradient
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
