import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';

/// A beautiful empty state widget for when there are no chats
class EmptyChatState extends StatelessWidget {
  /// Callback for new message button
  final VoidCallback onNewMessage;

  /// Optional title text
  final String title;

  /// Optional subtitle text
  final String subtitle;

  /// Button text
  final String buttonText;

  /// Constructor
  const EmptyChatState({
    Key? key,
    required this.onNewMessage,
    this.title = 'No conversations yet',
    this.subtitle = 'Start chatting with friends and classmates',
    this.buttonText = 'New Message',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation or illustration
            _buildIllustration(),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action button
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  /// Build the illustration/animation
  Widget _buildIllustration() {
    // Use a styled icon instead of trying to load an animation that might not exist
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.chat_bubble_outline_rounded,
        size: 64,
        color: AppTheme.primaryColor,
      ),
    );
  }

  /// Build the action button
  Widget _buildActionButton() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onNewMessage,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            shadowColor: AppTheme.primaryColor.withOpacity(0.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 20),
              const SizedBox(width: 8),
              Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onNewMessage,
          icon: const Icon(
            Icons.people_outline,
            size: 18,
          ),
          label: const Text(
            'Find people to chat with',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}

/// A search empty state widget for when search has no results
class EmptySearchState extends StatelessWidget {
  /// The search query that returned no results
  final String searchQuery;

  /// Optional subtitle text template
  final String subtitleTemplate;

  /// Constructor
  const EmptySearchState({
    Key? key,
    required this.searchQuery,
    this.subtitleTemplate = 'No results found for "{query}"',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),

            // No results text
            Text(
              subtitleTemplate.replaceAll('{query}', searchQuery),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
