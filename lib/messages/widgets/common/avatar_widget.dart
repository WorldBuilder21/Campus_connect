import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_conn/config/theme.dart';

/// A reusable avatar widget with various styling options and verified badge support
class AvatarWidget extends StatelessWidget {
  /// The image URL to display
  final String? imageUrl;

  /// Avatar radius (determines size)
  final double radius;

  /// Whether to show the verified badge
  final bool isVerified;

  /// Optional border color
  final Color? borderColor;

  /// Optional border width
  final double borderWidth;

  /// Fallback icon when no image is available
  final IconData fallbackIcon;

  /// Fallback icon color
  final Color fallbackIconColor;

  /// Background color for the avatar
  final Color backgroundColor;

  /// Optional on tap handler
  final VoidCallback? onTap;

  /// Optional placeholder widget
  final Widget? placeholder;

  /// Constructor
  const AvatarWidget({
    Key? key,
    this.imageUrl,
    this.radius = 24,
    this.isVerified = false,
    this.borderColor,
    this.borderWidth = 2,
    this.fallbackIcon = Icons.person,
    this.fallbackIconColor = Colors.grey,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.onTap,
    this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Main avatar
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: borderColor != null
                  ? Border.all(color: borderColor!, width: borderWidth)
                  : null,
              boxShadow: borderColor == null
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          placeholder ?? _buildPlaceholder(),
                      errorWidget: (context, url, error) =>
                          _buildFallbackIcon(),
                    )
                  : _buildFallbackIcon(),
            ),
          ),

          // Verified badge
          if (isVerified)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: radius * 0.7,
                height: radius * 0.7,
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: borderWidth,
                  ),
                ),
                child: radius >= 20
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  /// Build placeholder while image loads
  Widget _buildPlaceholder() {
    return Container(
      color: backgroundColor,
      child: Center(
        child: SizedBox(
          width: radius * 0.8,
          height: radius * 0.8,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }

  /// Build fallback icon when image is not available
  Widget _buildFallbackIcon() {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Icon(
          fallbackIcon,
          size: radius,
          color: fallbackIconColor,
        ),
      ),
    );
  }
}
