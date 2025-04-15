import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campus_conn/messages/schema/message_schema.dart';
import 'package:campus_conn/messages/providers/chat_provider.dart';
import 'package:campus_conn/messages/utils/file_handler.dart';

/// Message state class for individual chat screens
class MessageState {
  /// List of messages in the chat
  final List<Message> messages;

  /// Whether messages are loading
  final bool isLoading;

  /// Error message, if any
  final String? error;

  /// Whether audio is currently recording
  final bool isRecording;

  /// Whether there's a message being sent (for optimistic UI)
  final bool isSending;

  /// Whether a file is being uploaded
  final bool isUploading;

  /// Constructor
  MessageState({
    required this.messages,
    required this.isLoading,
    this.error,
    this.isRecording = false,
    this.isSending = false,
    this.isUploading = false,
  });

  /// Create a copy with updated values
  MessageState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    bool? isRecording,
    bool? isSending,
    bool? isUploading,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isRecording: isRecording ?? this.isRecording,
      isSending: isSending ?? this.isSending,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

/// Provider for message state - takes chatId parameter
final messageProvider =
    StateNotifierProvider.family<MessageNotifier, MessageState, String>(
  (ref, chatId) => MessageNotifier(ref, chatId),
);

/// Message state notifier
class MessageNotifier extends StateNotifier<MessageState> {
  final Ref ref;
  final String chatId;
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  /// Constructor
  MessageNotifier(this.ref, this.chatId)
      : super(MessageState(messages: [], isLoading: true)) {
    loadMessages();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  /// Set up realtime subscription for new messages
  void _setupRealtimeSubscription() {
    _channel = _supabase
        .channel('chat:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            try {
              // Parse new message with special handling for nulls
              final newRecord = payload.newRecord!;

              // Create Message manually instead of using fromJson
              final message = Message(
                id: newRecord['id'],
                chatId: newRecord['chat_id'],
                senderId: newRecord['sender_id'],
                content: newRecord['content'],
                timestamp: DateTime.parse(newRecord['timestamp']),
                isRead: newRecord['is_read'] ?? false,
                imageUrl: newRecord['image_url'],
                fileType: newRecord['file_type'],
              );

              // Add message to state
              state = state.copyWith(
                messages: [...state.messages, message],
              );

              // Mark message as read if from other user
              final currentUserId = _supabase.auth.currentUser?.id;
              if (message.senderId != currentUserId) {
                ref.read(chatProvider.notifier).markChatAsRead(chatId);
              }
            } catch (e) {
              debugPrint('Error processing new message: $e');
            }
          },
        )
        .subscribe();
  }

  /// Load messages for the chat
  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final messages =
          await ref.read(chatProvider.notifier).loadMessages(chatId);

      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );

      // Mark chat as read after loading messages
      ref.read(chatProvider.notifier).markChatAsRead(chatId);
    } catch (e) {
      debugPrint('Error loading messages: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading messages: $e',
      );
    }
  }

  /// Send a text message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add optimistic message to UI immediately
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Create temporary ID for optimistic message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Create optimistic message
    final optimisticMessage = Message(
      id: tempId,
      chatId: chatId,
      senderId: currentUserId,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // Update state with optimistic message
    state = state.copyWith(
      messages: [...state.messages, optimisticMessage],
      isSending: true,
    );

    try {
      // Send to server
      await _supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': currentUserId,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      });

      // Update chat last message
      await _supabase.rpc(
        'update_chat_last_message',
        params: {
          'chat_id_param': chatId,
          'message_content': content,
        },
      );

      // Update local chat
      ref.read(chatProvider.notifier).updateChatLastMessage(
            chatId,
            content,
          );

      // Update state
      state = state.copyWith(isSending: false);
    } catch (e) {
      debugPrint('Error sending message: $e');

      // Remove optimistic message on error
      state = state.copyWith(
        messages: state.messages.where((msg) => msg.id != tempId).toList(),
        isSending: false,
        error: 'Error sending message: $e',
      );
    }
  }

  /// Send a message with image
  Future<void> sendImageMessage(String localImagePath, String content) async {
    state = state.copyWith(isUploading: true);

    try {
      // Create File from path
      final file = File(localImagePath.replaceAll('file://', ''));

      // Upload image and get URL
      final imageUrl = await _uploadFile(file, 'image');

      if (imageUrl != null) {
        // Send message with image URL
        await _sendMessageWithAttachment(
          content.isEmpty ? '📸 Photo' : content,
          imageUrl,
          'image',
        );
      }

      state = state.copyWith(isUploading: false);
    } catch (e) {
      debugPrint('Error sending image: $e');
      state = state.copyWith(
        isUploading: false,
        error: 'Error sending image: $e',
      );
    }
  }

  /// Send a message with document
  Future<void> sendDocumentMessage(String localDocPath) async {
    state = state.copyWith(isUploading: true);

    try {
      // Create File from path
      final file = File(localDocPath.replaceAll('file://', ''));

      // Get file name for display
      final fileName = file.path.split('/').last;

      // Upload document and get URL
      final documentUrl = await _uploadFile(file, 'document');

      if (documentUrl != null) {
        // Send message with document URL
        await _sendMessageWithAttachment(
          '📎 $fileName',
          documentUrl,
          'document',
        );
      }

      state = state.copyWith(isUploading: false);
    } catch (e) {
      debugPrint('Error sending document: $e');
      state = state.copyWith(
        isUploading: false,
        error: 'Error sending document: $e',
      );
    }
  }

  /// Send an audio message
  Future<void> sendAudioMessage(String localAudioPath) async {
    state = state.copyWith(isUploading: true);

    try {
      // Create File from path
      final file = File(localAudioPath.replaceAll('file://', ''));

      // Upload audio and get URL
      final audioUrl = await _uploadFile(file, 'audio');

      if (audioUrl != null) {
        // Send message with audio URL
        await _sendMessageWithAttachment(
          '🎵 Voice Message',
          audioUrl,
          'audio',
        );
      }

      state = state.copyWith(isUploading: false);
    } catch (e) {
      debugPrint('Error sending audio: $e');
      state = state.copyWith(
        isUploading: false,
        error: 'Error sending audio: $e',
      );
    }
  }

  /// Upload a file and return the URL
  Future<String?> _uploadFile(File file, String fileType) async {
    try {
      // Check file size
      if (!await FileHandler.isFileSizeValid(file)) {
        throw Exception('File size exceeds the maximum limit of 10MB');
      }

      // Read file bytes
      final bytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;
      final fileExt = fileName.split('.').last.toLowerCase();

      // Generate unique filename
      final uniqueFileName = FileHandler.generateUniqueFileName(fileName);

      // Determine bucket based on file type
      final String bucketName = _getBucketNameForFile(fileType, fileExt);

      // Upload to Supabase storage
      final result = await _supabase.storage
          .from(bucketName)
          .uploadBinary(uniqueFileName, bytes);

      if (result != null) {
        // Get public URL
        return _supabase.storage.from(bucketName).getPublicUrl(uniqueFileName);
      }

      return null;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  /// Get the appropriate bucket name for the file type
  String _getBucketNameForFile(String fileType, String extension) {
    switch (fileType) {
      case 'image':
        return 'chatfiles/images';
      case 'document':
        return 'chatfiles/documents';
      case 'audio':
        return 'chatfiles/audio';
      default:
        // Determine bucket based on extension
        if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
          return 'chatfiles/images';
        } else if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt']
            .contains(extension)) {
          return 'chatfiles/documents';
        } else if (['m4a', 'mp3', 'wav'].contains(extension)) {
          return 'chatfiles/audio';
        } else {
          return 'chatfiles/other';
        }
    }
  }

  /// Send a message with an attachment
  Future<void> _sendMessageWithAttachment(
    String content,
    String attachmentUrl,
    String fileType,
  ) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Send message
    await _supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': currentUserId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'is_read': false,
      'image_url': attachmentUrl,
      'file_type': fileType,
    });

    // Update chat last message
    await _supabase.rpc(
      'update_chat_last_message',
      params: {
        'chat_id_param': chatId,
        'message_content': content,
      },
    );

    // Update local chat
    ref.read(chatProvider.notifier).updateChatLastMessage(
          chatId,
          content,
        );
  }

  /// Start recording audio
  void startRecording() {
    state = state.copyWith(isRecording: true);
  }

  /// Stop recording audio
  void stopRecording() {
    state = state.copyWith(isRecording: false);
  }
}
