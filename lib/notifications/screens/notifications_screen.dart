import 'package:campus_conn/notifications/provider/notification_provider.dart';
import 'package:campus_conn/notifications/schemas/notification_schema.dart'
    as notification_schema;
import 'package:campus_conn/profile/provider/profile_provider.dart';
import 'package:campus_conn/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/core/widget/loading_indicator.dart';

class NotificationScreen extends ConsumerWidget {
  static const routeName = '/notifications';

  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(notificationsPaginationProvider.notifier)
                  .markAllAsRead();
            },
            child: const Text(
              'Mark all as read',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: const NotificationsList(),
    );
  }
}

class NotificationsList extends ConsumerWidget {
  const NotificationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsPaginationProvider);

    // Loading state
    if (notificationsState.isLoading &&
        notificationsState.notifications.isEmpty) {
      return const Center(
        child: CircularLoadingIndicator(size: 32),
      );
    }

    // Empty state
    if (notificationsState.notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(notificationsPaginationProvider.notifier)
            .refreshNotifications();
      },
      color: AppTheme.primaryColor,
      child: ListView.builder(
        itemCount: notificationsState.notifications.length +
            (notificationsState.hasReachedEnd ? 0 : 1),
        itemBuilder: (context, index) {
          if (index == notificationsState.notifications.length) {
            if (notificationsState.isLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CircularLoadingIndicator()),
              );
            }

            // Load more when reaching end
            Future.microtask(() => ref
                .read(notificationsPaginationProvider.notifier)
                .loadMoreNotifications());

            return const SizedBox.shrink();
          }

          final notification = notificationsState.notifications[index];
          return NotificationTile(
            notification: notification,
            onTap: () {
              // Mark as read
              ref
                  .read(notificationsPaginationProvider.notifier)
                  .markAsRead(notification.id);

              // Navigate based on notification type
              _navigateToContent(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you get notifications, they\'ll appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Navigation method based on notification type
  void _navigateToContent(
      BuildContext context, notification_schema.Notification notification) {
    switch (notification.type) {
      case notification_schema.NotificationType.like:
      case notification_schema.NotificationType.comment:
        if (notification.postId != null) {
          // For now, show a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Viewing post interaction from ${notification.actorUsername}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;

      case notification_schema.NotificationType.follow:
        if (notification.actorId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(
                userId: notification.actorId,
                showBackBtn: true,
              ),
            ),
          );
        }
        break;

      case notification_schema.NotificationType.message:
        if (notification.chatId != null) {
          // For now, show a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening chat with ${notification.actorUsername}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;
    }
  }
}

class NotificationTile extends ConsumerStatefulWidget {
  final notification_schema.Notification notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  ConsumerState<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<NotificationTile> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check if already following
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFollowingStatus();
    });
  }

  // Check if we're already following this user
  Future<void> _checkFollowingStatus() async {
    try {
      final profileState =
          await ref.read(profileProvider(widget.notification.actorId).future);
      if (mounted) {
        setState(() {
          _isFollowing = profileState.isFollowing;
        });
      }
    } catch (e) {
      // Silently handle errors during initialization
      debugPrint('Error checking follow status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.notification.isRead
              ? Colors.white
              : AppTheme.primaryColor.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.15),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationContent(context),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        timeago.format(widget.notification.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (!widget.notification.isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle the follow action
  Future<void> _handleFollowAction() async {
    if (_isLoading) return; // Prevent multiple taps

    setState(() {
      _isLoading = true;
    });

    try {
      // Access profile provider
      final profileNotifier =
          ref.read(profileProvider(widget.notification.actorId).notifier);

      // Toggle follow status
      await profileNotifier.toggleFollow();

      // Update local state
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _isLoading = false;
        });
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing
                ? 'You are now following ${widget.notification.actorUsername}'
                : 'You unfollowed ${widget.notification.actorUsername}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow status: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white,
        backgroundImage: widget.notification.actorImageUrl != null
            ? NetworkImage(widget.notification.actorImageUrl!)
            : null,
        child: widget.notification.actorImageUrl == null
            ? const Icon(Icons.person)
            : null,
      ),
    );
  }

  Widget _buildNotificationContent(BuildContext context) {
    final TextStyle usernameStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).primaryColor,
    );

    const TextStyle regularStyle = TextStyle(
      fontWeight: FontWeight.normal,
      height: 1.3,
    );

    switch (widget.notification.type) {
      case notification_schema.NotificationType.like:
        return RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                  text: widget.notification.actorUsername,
                  style: usernameStyle),
              const TextSpan(text: ' liked your post', style: regularStyle),
            ],
          ),
        );

      case notification_schema.NotificationType.comment:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                      text: widget.notification.actorUsername,
                      style: usernameStyle),
                  const TextSpan(
                      text: ' commented on your post', style: regularStyle),
                ],
              ),
            ),
            if (widget.notification.content != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.notification.content!,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        );

      case notification_schema.NotificationType.follow:
        return Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                        text: widget.notification.actorUsername,
                        style: usernameStyle),
                    const TextSpan(
                        text: ' started following you', style: regularStyle),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: _isLoading
                  ? const SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: _handleFollowAction,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isFollowing
                            ? Colors.grey[600]
                            : AppTheme.primaryColor,
                        side: BorderSide(
                          color: _isFollowing
                              ? Colors.grey[400]!
                              : AppTheme.primaryColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32),
                        backgroundColor: _isFollowing
                            ? Colors.grey[200]
                            : Colors.transparent,
                      ),
                      child: Text(
                        _isFollowing ? 'Following' : 'Follow',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isFollowing
                              ? Colors.grey[600]
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
            ),
          ],
        );

      case notification_schema.NotificationType.message:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                      text: widget.notification.actorUsername,
                      style: usernameStyle),
                  const TextSpan(
                      text: ' sent you a message', style: regularStyle),
                ],
              ),
            ),
            if (widget.notification.content != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.notification.content!,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
    }
  }
}
