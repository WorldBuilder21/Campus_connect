import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_conn/auth/schemas/account.dart';
import 'package:campus_conn/messages/schema/chat_schema.dart';
import 'package:campus_conn/messages/schema/message_schema.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Define chat state class
class ChatState {
  /// List of all chats
  final List<Chat> chats;

  /// List of filtered chats (for search)
  final List<Chat> filteredChats;

  /// List of all users
  final List<Account> users;

  /// List of filtered users (for search)
  final List<Account> filteredUsers;

  /// List of suggested users
  final List<Account> suggestedUsers;

  /// Whether chats are loading
  final bool isLoading;

  /// Whether users are loading
  final bool isLoadingUsers;

  /// Error message, if any
  final String? error;

  /// Constructor
  ChatState({
    required this.chats,
    required this.filteredChats,
    required this.users,
    required this.filteredUsers,
    required this.suggestedUsers,
    required this.isLoading,
    required this.isLoadingUsers,
    this.error,
  });

  /// Create a copy with updated values
  ChatState copyWith({
    List<Chat>? chats,
    List<Chat>? filteredChats,
    List<Account>? users,
    List<Account>? filteredUsers,
    List<Account>? suggestedUsers,
    bool? isLoading,
    bool? isLoadingUsers,
    String? error,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      filteredChats: filteredChats ?? this.filteredChats,
      users: users ?? this.users,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      suggestedUsers: suggestedUsers ?? this.suggestedUsers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      error: error ?? this.error,
    );
  }
}

/// Chat provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

/// Chat state notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  ChatNotifier()
      : super(ChatState(
          chats: [],
          filteredChats: [],
          users: [],
          filteredUsers: [],
          suggestedUsers: [],
          isLoading: false,
          isLoadingUsers: false,
        )) {
    // Load chats when initialized
    loadChats();
  }

  /// Load chats with a single query
  Future<void> loadChats() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Fetch chats from Supabase with the correct query
      final response = await _supabase.from('chat_participants').select('''
        chat_id,
        other_user_id,
        chat:chat_id(
          id, 
          last_message, 
          last_message_time, 
          unread_count,
          created_at
        ),
        other_user:other_user_id(
          id, 
          username, 
          email, 
          image_url, 
          email_verified, 
          created_at,
          image_id,
          fcm_token
        )
      ''').eq('user_id', currentUserId);

      final chats = response.map<Chat>((json) {
        // Parse other user data - ensuring we're using the other user's data, not current user
        final userData = json['other_user'];

        final user = Account(
          id: userData['id'],
          username: userData['username'],
          email: userData['email'],
          image_url: userData['image_url'],
          email_verified: userData['email_verified'] ?? false,
          created_at: DateTime.parse(userData['created_at']),
          fcm_token: userData['fcm_token'],
          image_id: userData['image_id'],
        );

        final chatData = json['chat'];
        return Chat(
          id: chatData['id'],
          user: user, // This is the other user, not current user
          lastMessage: chatData['last_message'] ?? '',
          lastMessageTime: DateTime.parse(chatData['last_message_time']),
          unreadCount: chatData['unread_count'] ?? 0,
        );
      }).toList();

      // Sort chats by most recent message first
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      state = state.copyWith(
        chats: chats,
        filteredChats: chats,
        isLoading: false,
      );

      // Also load all users for new message creation
      await loadUsers();
    } catch (e) {
      print('Error loading chats: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading chats: $e',
      );
    }
  }

  /// Delete a chat
  Future<bool> deleteChat(String chatId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      // Call the SQL function to delete the chat
      final result = await _supabase.rpc(
        'delete_chat',
        params: {
          'chat_id_param': chatId,
          'user_id_param': currentUserId,
        },
      );

      // If deletion was successful, update the UI state
      if (result == true) {
        // Remove the chat from local state
        final updatedChats =
            state.chats.where((chat) => chat.id != chatId).toList();
        final updatedFilteredChats =
            state.filteredChats.where((chat) => chat.id != chatId).toList();

        state = state.copyWith(
          chats: updatedChats,
          filteredChats: updatedFilteredChats,
        );

        return true;
      }

      return false;
    } catch (e) {
      print('Error deleting chat: $e');
      state = state.copyWith(error: 'Error deleting chat: $e');
      return false;
    }
  }

  /// Load all users
  Future<void> loadUsers() async {
    state = state.copyWith(isLoadingUsers: true);

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        state = state.copyWith(isLoadingUsers: false);
        return;
      }

      // Fetch all users except current user
      final response =
          await _supabase.from('accounts').select('*').neq('id', currentUserId);

      final users =
          response.map<Account>((json) => Account.fromJson(json)).toList();

      // Sort users alphabetically by username
      users.sort((a, b) => (a.username ?? '').compareTo(b.username ?? ''));

      // Get suggested users - could be improved with algorithms for better suggestions
      // For now, just take first 10 users
      final suggestedUsers = users.take(10).toList();

      state = state.copyWith(
        users: users,
        filteredUsers: users,
        suggestedUsers: suggestedUsers,
        isLoadingUsers: false,
      );
    } catch (e) {
      print('Error loading users: $e');
      state = state.copyWith(
        isLoadingUsers: false,
        error: 'Error loading users: $e',
      );
    }
  }

  /// Filter chats by search query
  void filterChats(String query) {
    if (query.isEmpty) {
      state = state.copyWith(filteredChats: state.chats);
    } else {
      final lowercaseQuery = query.toLowerCase();

      final filtered = state.chats.where((chat) {
        final username = chat.user.username?.toLowerCase() ?? '';
        final lastMessage = chat.lastMessage.toLowerCase();

        return username.contains(lowercaseQuery) ||
            lastMessage.contains(lowercaseQuery);
      }).toList();

      state = state.copyWith(filteredChats: filtered);
    }
  }

  /// Update filtered chats list directly
  void updateFilteredChats(List<Chat> filteredChats) {
    state = state.copyWith(filteredChats: filteredChats);
  }

  /// Filter users by search query
  void filterUsers(String query) {
    if (query.isEmpty) {
      state = state.copyWith(filteredUsers: state.users);
    } else {
      final lowercaseQuery = query.toLowerCase();

      final filtered = state.users.where((user) {
        final username = user.username?.toLowerCase() ?? '';
        final email = user.email?.toLowerCase() ?? '';

        return username.contains(lowercaseQuery) ||
            email.contains(lowercaseQuery);
      }).toList();

      state = state.copyWith(filteredUsers: filtered);
    }
  }

  /// Create or get existing chat with user
  Future<Chat?> createOrGetChat(Account otherUser) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      if (currentUserId == null || otherUser.id == null) return null;

      // Check if chat already exists
      final existingChatResponse = await _supabase
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', currentUserId)
          .eq('other_user_id', otherUser.id!)
          .maybeSingle();

      String chatId;

      if (existingChatResponse != null) {
        chatId = existingChatResponse['chat_id'];
      } else {
        // Use the RPC function to create a new chat
        try {
          final response = await _supabase.rpc(
            'create_new_chat',
            params: {
              'creator_id': currentUserId,
              'other_user_id': otherUser.id,
            },
          );

          chatId = response as String;
        } catch (e) {
          throw e;
        }
      }

      // Create chat object
      final chat = Chat(
        id: chatId,
        user: otherUser,
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
      );

      // Add to local chats if not already there
      if (!state.chats.any((c) => c.id == chatId)) {
        final updatedChats = [chat, ...state.chats];

        // Sort by most recent
        updatedChats
            .sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

        state = state.copyWith(
          chats: updatedChats,
          filteredChats: updatedChats,
        );
      }

      return chat;
    } catch (e) {
      print('Error creating chat: $e');
      // Log more details for better debugging
      if (e is PostgrestException) {
        print('PostgrestException details:');
        print('Code: ${e.code}');
        print('Message: ${e.message}');
        print('Details: ${e.details}');
        print('Hint: ${e.hint}');
      }
      state = state.copyWith(error: 'Error creating chat: $e');
      return null;
    }
  }

  /// Load messages for a specific chat
  Future<List<Message>> loadMessages(String chatId) async {
    try {
      // Fetch messages for chat
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('chat_id', chatId)
          .order('timestamp', ascending: true);

      return response.map<Message>((json) {
        // Ensure imageUrl is properly handled
        return Message(
          id: json['id'],
          chatId: json['chat_id'],
          senderId: json['sender_id'],
          content: json['content'],
          timestamp: DateTime.parse(json['timestamp']),
          isRead: json['is_read'] ?? false,
          imageUrl: json['image_url'],
          fileType: json['file_type'],
        );
      }).toList();
    } catch (e) {
      print('Error loading messages: $e');
      // Return empty list on error
      return [];
    }
  }

  /// Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    try {
      // Update unread count in database
      await _supabase
          .from('chats')
          .update({'unread_count': 0}).eq('id', chatId);

      // Update local chat
      final chatIndex = state.chats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex != -1) {
        final chat = state.chats[chatIndex];
        final updatedChat = chat.copyWith(unreadCount: 0);

        final updatedChats = [...state.chats];
        updatedChats[chatIndex] = updatedChat;

        final updatedFilteredChats = state.filteredChats
            .map((c) => c.id == chatId ? c.copyWith(unreadCount: 0) : c)
            .toList();

        state = state.copyWith(
          chats: updatedChats,
          filteredChats: updatedFilteredChats,
        );
      }
    } catch (e) {
      print('Error marking chat as read: $e');
      state = state.copyWith(error: 'Error marking chat as read: $e');
    }
  }

  /// Update chat's last message locally
  void updateChatLastMessage(String chatId, String lastMessage) {
    final chatIndex = state.chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final chat = state.chats[chatIndex];
      final updatedChat = chat.copyWith(
        lastMessage: lastMessage,
        lastMessageTime: DateTime.now(),
      );

      // Remove old chat and add updated one at the top
      final updatedChats = [...state.chats];
      updatedChats.removeAt(chatIndex);
      updatedChats.insert(0, updatedChat);

      state = state.copyWith(
        chats: updatedChats,
        filteredChats: updatedChats,
      );
    }
  }

  /// Refresh chats
  Future<void> refreshChats() async {
    await loadChats();
  }
}
