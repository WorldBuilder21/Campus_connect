import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_conn/config/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;
  final bool hasBackButton;
  final Color backgroundColor;
  final double elevation;
  final List<Widget>? actions;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.centerTitle = true,
    this.hasBackButton = false,
    this.backgroundColor = Colors.white,
    this.elevation = 0.0,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: _buildTitle(),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shadowColor: Colors.black.withOpacity(0.05),
      leading: hasBackButton ? _buildBackButton(context) : null,
      actions: actions,
      titleSpacing: hasBackButton ? 0 : 16,
      shape: elevation > 0
          ? Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.15),
                width: 0.5,
              ),
            )
          : null,
    );
  }

  Widget _buildTitle() {
    // Create a more stylish title based on the app's branding
    if (title == 'CampusConnect') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Campus',
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Text(
            'Connect',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
          // Optional: Add a small dot or icon for visual interest
          Container(
            margin: const EdgeInsets.only(left: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      );
    }

    // For other screens, use a clean, consistent style
    return Text(
      title,
      style: GoogleFonts.poppins(
        textStyle: const TextStyle(
          color: AppTheme.textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      splashRadius: 24,
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
