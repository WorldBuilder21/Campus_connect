import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';

/// ProfileTabBar creates a custom tab bar for profile tabs like Posts, Saved, etc.
/// It mimics Instagram's tab bar with custom styling and animations.
class ProfileTabBar extends StatelessWidget {
  final TabController tabController;
  final List<ProfileTab> tabs;

  const ProfileTabBar({
    Key? key,
    required this.tabController,
    required this.tabs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        // Remove the hard border and use a subtle shadow instead
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 2),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TabBar(
        controller: tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey[400],
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 2.0,
        // Use a more modern, Instagram-like indicator
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 2.0,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        // Subtle animation for tab switching
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        tabs: tabs.map((tab) => _buildTab(tab)).toList(),
      ),
    );
  }

  /// Build a single tab with icon and optional label
  Widget _buildTab(ProfileTab tab) {
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, child) {
        final isSelected = tabController.index == tabs.indexOf(tab);

        return Tab(
          icon: Icon(
            isSelected && tab.selectedIcon != null
                ? tab.selectedIcon
                : tab.icon,
            size: 24,
          ),
          // For accessibility, we include the label even if it's visually hidden
          child: Text(
            tab.label,
            style: const TextStyle(
                fontSize: 0), // Visually hidden but present for screen readers
          ),
        );
      },
    );
  }
}

/// ProfileTab model to represent a tab in the profile screen
class ProfileTab {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const ProfileTab({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

/// A persistent header delegate for sliver app bars that maintains
/// the tab bar at the top of the screen when scrolling
class ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  ProfileTabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant ProfileTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
