import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:flutter/services.dart';

/// Utility class for handling files in chat (uploads, downloads, etc.)
class FileHandler {
  /// Max file size for uploads (10MB)
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB in bytes

  /// Allowed file extensions for documents
  static const List<String> allowedDocumentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'txt'
  ];

  /// Allowed file extensions for images
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];

  /// Allowed file extensions for audio
  static const List<String> allowedAudioExtensions = [
    'm4a',
    'mp3',
    'wav',
    'aac'
  ];

  /// Pick an image from gallery
  static Future<File?> pickImage(
      {required bool fromCamera, int quality = 70}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: quality,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to pick image: $e');
    }

    return null;
  }

  /// Pick a document file
  static Future<File?> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedDocumentExtensions,
        allowMultiple: false,
      );

      if (result != null) {
        return File(result.files.single.path!);
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to pick document: $e');
    }

    return null;
  }

  /// Check if file size is within allowed limit
  static Future<bool> isFileSizeValid(File file) async {
    final size = await file.length();
    return size <= maxFileSize;
  }

  /// Get a human-readable file size
  static String getReadableFileSize(int bytes) {
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return size.toStringAsFixed(1) + " " + suffixes[i];
  }

  /// Generate a unique filename for uploading
  static String generateUniqueFileName(String originalPath) {
    final extension = path.extension(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (1000 + (DateTime.now().microsecond % 9000)).toString();

    return '${timestamp}_$random$extension';
  }

  /// Determine file type from extension
  static String getFileType(String filePath) {
    final extension =
        path.extension(filePath).toLowerCase().replaceAll('.', '');

    if (allowedImageExtensions.contains(extension)) {
      return 'image';
    } else if (allowedDocumentExtensions.contains(extension)) {
      return 'document';
    } else if (allowedAudioExtensions.contains(extension)) {
      return 'audio';
    } else {
      return 'unknown';
    }
  }

  /// Get file icon based on file type/extension
  static IconData getFileIcon(String fileName) {
    final extension =
        path.extension(fileName).toLowerCase().replaceAll('.', '');

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Get document type display name
  static String getDocumentTypeName(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    switch (extension) {
      case '.pdf':
        return 'PDF Document';
      case '.doc':
      case '.docx':
        return 'Word Document';
      case '.xls':
      case '.xlsx':
        return 'Excel Spreadsheet';
      case '.txt':
        return 'Text Document';
      default:
        return 'Document';
    }
  }

  /// Create a temporary file (useful for recording)
  static Future<String> createTempFilePath(
      String prefix, String extension) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/${prefix}_$timestamp.$extension';
  }

  /// Get MIME type from file extension
  static String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }
}
