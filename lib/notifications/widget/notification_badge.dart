import 'package:campus_conn/notifications/provider/notification_provider.dart';
import 'package:campus_conn/notifications/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_conn/config/theme.dart';

class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final double? top;
  final double? right;
  final double? size;
  final bool navigateOnTap;
  final VoidCallback? onTap;

  const NotificationBadge({
    super.key,
    required this.child,
    this.top,
    this.right,
    this.size,
    this.navigateOnTap = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    // Create a GestureDetector if navigation is enabled
    Widget badge = Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        unreadCount.when(
          data: (count) {
            if (count > 0) {
              return Positioned(
                top: top ?? -2,
                right: right ?? -2,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.5, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      minWidth: size ?? 16,
                      minHeight: size ?? 16,
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (size != null) ? size! * 0.6 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );

    // Add tap functionality if needed
    if (navigateOnTap || onTap != null) {
      return GestureDetector(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else if (navigateOnTap) {
            // Navigate to notifications screen
            Navigator.pushNamed(context, NotificationScreen.routeName);
          }
        },
        child: badge,
      );
    }

    return badge;
  }
}
