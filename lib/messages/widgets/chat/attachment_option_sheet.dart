import 'dart:io';
import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/messages/utils/file_handler.dart';
import 'package:image_picker/image_picker.dart';

/// A beautiful bottom sheet for selecting attachment options
class AttachmentOptionSheet extends StatefulWidget {
  /// Callback for image selection
  final Function(File, bool) onImageSelected;

  /// Callback for document selection
  final Function(File) onDocumentSelected;

  /// Constructor
  const AttachmentOptionSheet({
    Key? key,
    required this.onImageSelected,
    required this.onDocumentSelected,
  }) : super(key: key);

  @override
  State<AttachmentOptionSheet> createState() => _AttachmentOptionSheetState();
}

class _AttachmentOptionSheetState extends State<AttachmentOptionSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Loading state tracking
  bool _isLoading = false;
  String? _loadingText;

  @override
  void initState() {
    super.initState();

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start entrance animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Close the bottom sheet
  void _closeSheet() {
    // Play exit animation
    _animationController.reverse().then((_) {
      Navigator.pop(context);
    });
  }

  /// Show a loading indicator
  void _showLoading(String text) {
    setState(() {
      _isLoading = true;
      _loadingText = text;
    });
  }

  /// Hide the loading indicator
  void _hideLoading() {
    setState(() {
      _isLoading = false;
      _loadingText = null;
    });
  }

  /// Pick an image from camera
  Future<void> _pickFromCamera() async {
    _showLoading('Opening camera...');

    try {
      final File? imageFile = await FileHandler.pickImage(fromCamera: true);
      _hideLoading();

      if (imageFile != null) {
        // Check file size
        if (await FileHandler.isFileSizeValid(imageFile)) {
          _closeSheet();
          widget.onImageSelected(imageFile, true);
        } else {
          _showFileSizeError();
        }
      }
    } catch (e) {
      _hideLoading();
      _showError('Error accessing camera: $e');
    }
  }

  /// Pick an image from gallery
  Future<void> _pickFromGallery() async {
    _showLoading('Opening gallery...');

    try {
      final File? imageFile = await FileHandler.pickImage(fromCamera: false);
      _hideLoading();

      if (imageFile != null) {
        // Check file size
        if (await FileHandler.isFileSizeValid(imageFile)) {
          _closeSheet();
          widget.onImageSelected(imageFile, false);
        } else {
          _showFileSizeError();
        }
      }
    } catch (e) {
      _hideLoading();
      _showError('Error accessing gallery: $e');
    }
  }

  /// Pick a document
  Future<void> _pickDocument() async {
    _showLoading('Opening document picker...');

    try {
      final File? document = await FileHandler.pickDocument();
      _hideLoading();

      if (document != null) {
        // Check file size
        if (await FileHandler.isFileSizeValid(document)) {
          _closeSheet();
          widget.onDocumentSelected(document);
        } else {
          _showFileSizeError();
        }
      }
    } catch (e) {
      _hideLoading();
      _showError('Error picking document: $e');
    }
  }

  /// Show file size error
  void _showFileSizeError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File size must be less than 10MB'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Show general error
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          // Slide up animation
          offset: Offset(0,
              MediaQuery.of(context).size.height * 0.3 * _slideAnimation.value),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with handle
              _buildHandle(),
              const SizedBox(height: 16),

              // Title
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Attach a file',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ),

              // Loading indicator
              if (_isLoading) _buildLoadingIndicator() else _buildOptionGrid(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the draggable handle at the top
  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _loadingText ?? 'Loading...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Build grid of attachment options
  Widget _buildOptionGrid() {
    final options = [
      _AttachmentOption(
        icon: Icons.photo_library_rounded,
        label: 'Gallery',
        color: Colors.purple[600]!,
        onTap: _pickFromGallery,
      ),
      _AttachmentOption(
        icon: Icons.camera_alt_rounded,
        label: 'Camera',
        color: Colors.blue[600]!,
        onTap: _pickFromCamera,
      ),
      _AttachmentOption(
        icon: Icons.insert_drive_file_rounded,
        label: 'Document',
        color: Colors.orange[700]!,
        onTap: _pickDocument,
      ),
      // Additional options can be added here
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      children: options,
    );
  }
}

/// Individual attachment option item
class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with background
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),

          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
