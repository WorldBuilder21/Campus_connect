import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/messages/utils/file_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// A beautiful document preview card for file attachments
class DocumentPreview extends StatelessWidget {
  /// File name to display
  final String fileName;

  /// URL to the file
  final String fileUrl;

  /// Whether this message is from the current user
  final bool isMe;

  /// Optional file size in bytes
  final int? fileSize;

  /// Optional document type
  final String? documentType;

  /// Constructor
  const DocumentPreview({
    Key? key,
    required this.fileName,
    required this.fileUrl,
    required this.isMe,
    this.fileSize,
    this.documentType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine file extension and icon
    final fileExtension = fileName.split('.').last.toLowerCase();
    final fileIcon = FileHandler.getFileIcon(fileName);

    // Get document type name
    final docType = documentType ?? FileHandler.getDocumentTypeName(fileName);

    // Calculate color scheme based on file type and sender
    final Color primaryColor = _getColorForFileType(fileExtension);
    final Color backgroundColor =
        isMe ? AppTheme.primaryColor : Colors.grey[100]!;
    final Color textColor = isMe ? Colors.white : AppTheme.textPrimaryColor;
    final Color iconColor = isMe ? Colors.white : primaryColor;

    return InkWell(
      onTap: () => _openDocument(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File icon and extension row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white.withOpacity(0.2)
                        : primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    fileIcon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),

                // File extension and type
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileExtension.toUpperCase(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      docType,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Open icon
                Icon(
                  Icons.open_in_new,
                  color:
                      isMe ? Colors.white.withOpacity(0.7) : Colors.grey[500],
                  size: 16,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // File name
            Text(
              fileName,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // File size if available
            if (fileSize != null) ...[
              const SizedBox(height: 4),
              Text(
                FileHandler.getReadableFileSize(fileSize!),
                style: TextStyle(
                  color:
                      isMe ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get appropriate color based on file type
  Color _getColorForFileType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red[700]!;
      case 'doc':
      case 'docx':
        return Colors.blue[700]!;
      case 'xls':
      case 'xlsx':
        return Colors.green[700]!;
      case 'ppt':
      case 'pptx':
        return Colors.orange[700]!;
      case 'txt':
        return Colors.blueGrey[700]!;
      case 'zip':
      case 'rar':
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  /// Open the document
  Future<void> _openDocument(BuildContext context) async {
    try {
      final Uri url = Uri.parse(fileUrl);
      final bool canLaunch = await canLaunchUrl(url);

      if (canLaunch) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open the document.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening document: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
