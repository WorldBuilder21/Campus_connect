import 'dart:io';
import 'package:campus_conn/auth/api/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_conn/auth/schemas/account.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/core/widget/app_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final Account user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  File? _imageFile;
  bool _isLoading = false;
  bool _usernameExists = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Edit Profile',
        hasBackButton: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile picture
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : widget.user.image_url != null
                            ? CachedNetworkImageProvider(widget.user.image_url!)
                            : null,
                    child: widget.user.image_url == null && _imageFile == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Username field
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
                errorText: _usernameError,
              ),
              onChanged: (value) async {
                // Clear error if user is typing
                if (_usernameError != null) {
                  setState(() {
                    _usernameError = null;
                  });
                }

                // Check if username exists (only if different from current)
                if (value != widget.user.username) {
                  await _checkUsernameAvailability(value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Email field (read-only)
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
                suffixIcon: Icon(Icons.lock),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),

            // Bio field
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 150,
            ),
            const SizedBox(height: 16),

            // // Privacy section
            // const Align(
            //   alignment: Alignment.centerLeft,
            //   child: Text(
            //     'Privacy',
            //     style: TextStyle(
            //       fontSize: 18,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 8),

            // // Private account toggle
            // SwitchListTile(
            //   title: const Text('Private Account'),
            //   subtitle: const Text(
            //     'When your account is private, only people you approve can see your posts and stories',
            //   ),
            //   value: widget.user.is_private ?? false,
            //   onChanged: (value) {
            //     // This will be handled in the save function
            //     setState(() {});
            //   },
            // ),
            // const Divider(),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty) return;

    final authRepo = ref.read(authRepositoryProvider);

    try {
      final exists = await authRepo.checkUsernameExists(username: username);

      setState(() {
        _usernameExists = exists;
        if (exists) {
          _usernameError = 'Username already taken';
        }
      });
    } catch (e) {
      // Silently handle errors to not interrupt user typing
      debugPrint('Error checking username: $e');
    }
  }

  Future<void> _saveProfile() async {
    // Validate inputs
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _usernameError = 'Username cannot be empty';
      });
      return;
    }

    if (_usernameExists) {
      setState(() {
        _usernameError = 'Username already taken';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);

      // Upload image if selected
      if (_imageFile != null) {
        await authRepo.uploadImage(file: _imageFile!);
      }

      // Get current user
      final currentUser = await authRepo.getAccount(widget.user.id!);

      // Update profile data
      final updatedUser = currentUser.copyWith(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        is_private: _isProfiePrivate(),
        show_activity: _showsActivity(),
      );

      // Update in database
      await ref.read(authRepositoryProvider).updateAccount(updatedUser);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        // Return to previous screen
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
      debugPrint(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper methods to get the current state of switches
  bool _isProfiePrivate() {
    return widget.user.is_private ?? false;
  }

  bool _showsActivity() {
    return widget.user.show_activity ?? true;
  }
}
