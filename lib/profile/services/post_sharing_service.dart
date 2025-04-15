import 'dart:io';
import 'package:campus_conn/profile/schemas/post_schema.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;

class PostSharingService {
  // Share a post with image and caption
  static Future<void> sharePost(BuildContext context, Post post) async {
    try {
      final shareText = _formatPostForSharing(post);
      final tempFile = await _downloadImage(post.imageUrl);

      if (tempFile != null) {
        // Share both text and image
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: shareText,
          subject: 'Check out this post from Campus Connect!',
        );
      } else {
        // Share just the text if image download fails
        await Share.share(
          shareText,
          subject: 'Check out this post from Campus Connect!',
        );
      }
    } catch (e) {
      debugPrint('Error sharing post: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share post: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Format post content for sharing
  static String _formatPostForSharing(Post post) {
    final username = post.user.username ?? 'User';
    final caption = post.caption;

    // Add hashtags
    final hashtagsText = post.tags.isNotEmpty
        ? '\n\nHashtags: ${post.tags.map((tag) => '#$tag').join(' ')}'
        : '';

    return '''
📱 Shared from Campus Connect 📱

👤 $username posted:
$caption
$hashtagsText

🔗 Open Campus Connect app to see more!
''';
  }

  // Download and save image to temporary file
  static Future<File?> _downloadImage(String imageUrl) async {
    try {
      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final filename = 'campus_connect_${path.basename(imageUrl)}';
      final file = File('${tempDir.path}/$filename');

      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      debugPrint('Error downloading image for sharing: $e');
    }
    return null;
  }
}
