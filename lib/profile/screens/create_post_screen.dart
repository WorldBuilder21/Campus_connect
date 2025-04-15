import 'dart:io';
import 'package:campus_conn/profile/api/post_repository.dart';
import 'package:campus_conn/profile/provider/feed_notifier.dart';
import 'package:campus_conn/profile/provider/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/core/widget/app_bar.dart';
import 'package:campus_conn/profile/schemas/post_schema.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _captionController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  List<String> _extractedTags = [];
  final _client = Supabase.instance.client;

  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Create Post',
        hasBackButton: true,
        actions: [
          TextButton(
            onPressed: _isLoading || _imageFile == null ? null : _createPost,
            child: Text(
              'Share',
              style: TextStyle(
                color: _isLoading || _imageFile == null
                    ? Colors.grey
                    : AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          // Dismiss keyboard when tapping outside
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                _buildImageSection(),

                // Caption section
                _buildCaptionSection(),

                // Tags section
                if (_extractedTags.isNotEmpty) _buildTagsSection(),

                // Camera button
                _buildCameraButton(),

                // Loading indicator
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Bottom padding for scrolling
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // IMAGE SECTION: Visually appealing image picker area
  Widget _buildImageSection() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        height: MediaQuery.of(context)
            .size
            .width, // Square aspect ratio like Instagram
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: _imageFile == null
              ? Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1))
              : null,
        ),
        child: _imageFile != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  // Image display
                  Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                  ),

                  // Change image button overlay
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Change',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            // Empty state - no image selected yet
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate,
                      size: 50,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Add a photo to share',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to choose from your gallery',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // CAPTION SECTION: Modern, clean text input area
  Widget _buildCaptionSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Caption header with icon
          const Row(
            children: [
              Icon(Icons.edit, size: 20, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Caption',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Caption text field with improved styling
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                hintText: 'Write a caption...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                hintStyle: TextStyle(color: Colors.grey),
              ),
              maxLines: 5,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimaryColor,
              ),
              onChanged: (value) {
                // Extract hashtags with # symbol
                _extractTags(value);
              },
            ),
          ),

          // Caption helper text
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Use # to add tags to your post',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAGS SECTION: Visually distinct tag chips
  Widget _buildTagsSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12, left: 4),
            child: Row(
              children: [
                Icon(Icons.tag, size: 18, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _extractedTags
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // CAMERA BUTTON: Attractive button to take new photos
  Widget _buildCameraButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _takePicture,
        icon: const Icon(Icons.camera_alt, size: 20),
        label: const Text('Take a New Photo',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // Image picker with error handling
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Slightly higher quality for better images
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Handle errors gracefully to prevent crashes
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access gallery: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Camera access with error handling
  Future<void> _takePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Handle camera errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access camera: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Extract hashtags from text
  void _extractTags(String text) {
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(text);
    final tags = matches.map((match) => match.group(1)!).toList();

    setState(() {
      _extractedTags = tags;
    });
  }

  // Post creation with improved error handling and real-time updates
  Future<void> _createPost() async {
    // Validation checks
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a caption'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Pre-clear caches before creating the post
      ref.read(postRepositoryProvider).clearCaches();

      // Show a temporary status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creating your post...'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Access post repository
      final postRepo = ref.read(postRepositoryProvider);

      // Create new post
      final newPost = await postRepo.createPost(
        caption: _captionController.text,
        imageFile: _imageFile!,
        tags: _extractedTags,
      );

      // Clear all caches again after creation
      postRepo.clearCaches();

      if (mounted) {
        // Get current user ID for profile refresh
        final currentUserId = _client.auth.currentUser?.id;

        if (currentUserId != null) {
          // Force refresh the profile provider if it exists
          if (ref.exists(profileProvider(currentUserId))) {
            await ref
                .read(profileProvider(currentUserId).notifier)
                .refreshProfile();
            debugPrint('Profile refreshed immediately after post creation');
          }

          // Add post to feed state directly
          try {
            ref.read(feedNotifier.notifier).addPost(newPost);

            // Also refresh the feed
            await ref.read(feedNotifier.notifier).refreshFeed();
            debugPrint('Feed refreshed after post creation');
          } catch (e) {
            debugPrint('Error updating feed with new post: $e');
            // Continue anyway since post was created successfully
          }
        }

        // Show success message with icon
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Post created successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Return to previous screen with the new post
        Navigator.pop(context, newPost);
      }
    } catch (e) {
      if (mounted) {
        // Show error with descriptive message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            duration:
                const Duration(seconds: 5), // Give more time to read error
          ),
        );

        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
