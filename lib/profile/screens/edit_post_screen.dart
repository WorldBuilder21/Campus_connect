import 'package:campus_conn/profile/api/post_repository.dart';
import 'package:campus_conn/profile/provider/feed_notifier.dart';
import 'package:campus_conn/profile/provider/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/core/widget/app_bar.dart';
import 'package:campus_conn/profile/schemas/post_schema.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  final Post post;

  const EditPostScreen({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  late TextEditingController _captionController;
  bool _isLoading = false;
  List<String> _extractedTags = [];
  bool _hasChanges = false;
  final _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.post.caption);
    _captionController.addListener(_checkForChanges);
    _extractedTags = List.from(widget.post.tags);
  }

  // Add listener to detect changes
  void _checkForChanges() {
    final captionChanged = _captionController.text != widget.post.caption;
    final tagsChanged = !_areTagsEqual(_extractedTags, widget.post.tags);

    final newHasChanges = captionChanged || tagsChanged;
    if (newHasChanges != _hasChanges) {
      setState(() {
        _hasChanges = newHasChanges;
      });
    }
  }

  // Compare tag lists
  bool _areTagsEqual(List<String> tags1, List<String> tags2) {
    if (tags1.length != tags2.length) return false;

    // Sort both lists for comparison
    final sortedTags1 = List<String>.from(tags1)..sort();
    final sortedTags2 = List<String>.from(tags2)..sort();

    for (int i = 0; i < sortedTags1.length; i++) {
      if (sortedTags1[i] != sortedTags2[i]) return false;
    }

    return true;
  }

  @override
  void dispose() {
    _captionController.removeListener(_checkForChanges);
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Edit Post',
        hasBackButton: true,
        actions: [
          TextButton(
            onPressed: (_isLoading || !_hasChanges) ? null : _saveChanges,
            child: Text(
              'Save',
              style: TextStyle(
                color: (_isLoading || !_hasChanges)
                    ? Colors.grey
                    : AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post image (non-editable)
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: CachedNetworkImage(
                imageUrl: widget.post.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),

            // Caption section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Caption',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _captionController,
                    decoration: const InputDecoration(
                      hintText: 'Edit your caption...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    onChanged: (value) {
                      // Extract hashtags
                      _extractTags(value);
                      // _checkForChanges is called via listener
                    },
                  ),
                ],
              ),
            ),

            // Tags section
            if (_extractedTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _extractedTags
                          .map((tag) => Chip(
                                label: Text('#$tag'),
                                backgroundColor:
                                    AppTheme.primaryColor.withOpacity(0.1),
                                onDeleted: () {
                                  setState(() {
                                    _extractedTags.remove(tag);
                                    _checkForChanges();
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

            // Manually add tag section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add tag',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Enter a tag (without #)',
                            border: OutlineInputBorder(),
                            prefixText: '#',
                          ),
                          onSubmitted: _addTag,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          // The tag will be added via onSubmitted
                        },
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _extractTags(String text) {
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(text);
    final tags = matches.map((match) => match.group(1)!).toList();

    setState(() {
      _extractedTags = tags;
    });
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty) {
      setState(() {
        if (!_extractedTags.contains(tag)) {
          _extractedTags.add(tag);
          _checkForChanges();
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caption cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Pre-clear caches to ensure fresh data after update
      final postRepo = ref.read(postRepositoryProvider);
      postRepo.clearCaches();

      // Show a temporary status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving your changes...'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final updatedPost = await postRepo.editPost(
        postId: widget.post.id,
        caption: _captionController.text,
        tags: _extractedTags,
      );

      // Clear caches again after the update to ensure fresh data everywhere
      postRepo.clearCaches();

      if (mounted) {
        // Get current user ID for profile refresh
        final currentUserId = _client.auth.currentUser?.id;

        if (currentUserId != null) {
          // Force refresh the profile provider if it exists
          if (ref.exists(profileProvider(widget.post.user.id!))) {
            await ref
                .read(profileProvider(widget.post.user.id!).notifier)
                .refreshProfile();
            debugPrint('Profile refreshed immediately after post edit');
          }
        }

        // Update the post in feed directly if it exists there
        try {
          // First try to update in the existing feed
          final feedState = ref.read(feedNotifier);
          if (feedState is AsyncData) {
            final posts = feedState.value ?? [];
            final index = posts.indexWhere((p) => p.id == updatedPost.id);

            if (index != -1) {
              // Post exists in feed, update it
              final updatedPosts = [...posts];
              updatedPosts[index] = updatedPost;

              // Update feed state directly
              ref.read(feedNotifier.notifier).state =
                  AsyncValue.data(updatedPosts);
            }
          }

          // Also trigger a feed refresh
          ref.read(feedNotifier.notifier).refreshFeed();
        } catch (e) {
          debugPrint('Error updating feed: $e');
          // Continue anyway since post was updated successfully
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Return to previous screen with the updated post
        Navigator.pop(context, updatedPost);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update post: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
