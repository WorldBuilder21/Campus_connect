import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/notifications/widget/notification_badge.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ImprovedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabTapped;

  const ImprovedBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTabTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Increased icon size for better visibility
    const double iconSize = 28.0;

    // Define nav items with consistent icon sizing
    final List<Map<String, dynamic>> navItems = [
      {
        'label': 'Home',
        'activeIcon': Icons.home,
        'inactiveIcon': Icons.home_outlined,
      },
      {
        'label': 'Messages',
        'activeIcon': Icons.chat,
        'inactiveIcon': Icons.chat_outlined,
      },
      {
        'label': 'Notifications',
        'activeIcon': Icons.notifications,
        'inactiveIcon': Icons.notifications_outlined,
        'hasBadge': true,
      },
      {
        'label': 'Nearby',
        'activeIcon': Icons.map,
        'inactiveIcon': Icons.map_outlined,
      },
      {
        'label': 'Profile',
        'activeIcon': Icons.person,
        'inactiveIcon': Icons.person_outline,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        // Add SafeArea to handle bottom insets properly
        child: Container(
          height: 80, // Increased height for better touch targets
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              navItems.length,
              (index) => _buildNavItem(
                context,
                index,
                navItems[index]['label'],
                navItems[index]['activeIcon'],
                navItems[index]['inactiveIcon'],
                navItems[index]['hasBadge'] == true,
                iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build each nav item with consistent styling and size
  Widget _buildNavItem(
    BuildContext context,
    int index,
    String label,
    IconData activeIcon,
    IconData inactiveIcon,
    bool hasBadge,
    double iconSize,
  ) {
    final bool isSelected = currentIndex == index;

    // Calculate the width to ensure equal spacing
    final width = MediaQuery.of(context).size.width / 5;

    // Base nav item with fixed width for consistency
    Widget item = Container(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with increased size
          Container(
            height: 40, // Increased from 30
            width: 40, // Increased from 30
            alignment: Alignment.center,
            child: Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: iconSize,
              color: isSelected ? AppTheme.primaryColor : Colors.black87,
            ),
          ),

          // Add spacing
          const SizedBox(height: 5),

          // Label - only visible when selected
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isSelected ? 18 : 0, // Increased from 16
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14, // Increased from 12
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Apply notification badge wrapper if needed
    if (hasBadge) {
      item = NotificationBadge(
        child: item,
        onTap: () => onTabTapped(index),
      );
    }

    // Wrap in InkWell for tap handling with consistent sizing
    return InkWell(
      onTap: () => onTabTapped(index),
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: item,
    );
  }
}
