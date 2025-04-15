import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_conn/auth/schemas/account.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/messages/providers/chat_provider.dart';
import 'package:campus_conn/messages/schema/chat_schema.dart';
import 'package:campus_conn/messages/screens/chat_screen.dart';
import 'package:campus_conn/messages/widgets/chat_list/chat_item.dart';
import 'package:campus_conn/messages/widgets/chat_list/chat_search_bar.dart';
import 'package:campus_conn/messages/widgets/chat_list/empty_chat_state.dart';
import 'package:campus_conn/messages/widgets/chat_list/new_message_sheet.dart';
import 'package:campus_conn/messages/widgets/chat_list/chat_options_menu.dart';
import 'package:campus_conn/messages/widgets/common/loading_states.dart';

/// A beautiful, modern chat list screen
class ChatListScreen extends ConsumerStatefulWidget {
  static const routeName = '/chats';

  const ChatListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // Search query
  String _searchQuery = '';

  // Filter states
  bool _showingUnreadOnly = false;
  bool _showingArchived = false;

  // Refresh control
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Start entrance animation
    _animationController.forward();

    // Set up scroll controller for pull-to-refresh
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll listener for pull-to-refresh functionality
  void _scrollListener() {
    // Implement pull-to-refresh logic
    if (_scrollController.position.pixels <= -80) {
      // Refresh data
      ref.read(chatProvider.notifier).refreshChats();
    }
  }

  /// Navigate to chat screen
  void _navigateToChat(BuildContext context, Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chat: chat,
          recipientImageUrl: chat.user.image_url,
        ),
      ),
    );
  }

  /// Show new message modal
  void _showNewMessageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9, // Cover most of the screen
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return NewMessageSheet(
              controller: scrollController,
              onUserSelected: _handleUserSelected,
            );
          },
        );
      },
    );
  }

  /// Handle user selection for new message
  void _handleUserSelected(Account user) {
    ref.read(chatProvider.notifier).createOrGetChat(user).then((chat) {
      if (chat != null && mounted) {
        _navigateToChat(context, chat);
      }
    });
  }

  /// Filter to show only unread chats
  void _filterUnreadChats() {
    setState(() {
      _showingUnreadOnly = !_showingUnreadOnly;
    });

    if (_showingUnreadOnly) {
      final unreadChats = ref
          .read(chatProvider)
          .chats
          .where((chat) => chat.unreadCount > 0)
          .toList();

      ref.read(chatProvider.notifier).updateFilteredChats(unreadChats);
    } else {
      ref.read(chatProvider.notifier).filterChats(_searchQuery);
    }
  }

  /// Show archived chats
  void _showArchivedChats() {
    setState(() {
      _showingArchived = !_showingArchived;
    });

    // TODO: Implement archived chats functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Archived chats coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Navigate to find new contacts
  void _findNewContacts() {
    _showNewMessageModal(context);
  }

  /// Show chat settings
  void _showChatSettings() {
    // TODO: Implement chat settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat settings coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            _buildAppBar(),

            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey[200],
            ),

            // Chat list
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildChatList(chatState),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewMessageModal(context),
        backgroundColor: AppTheme.primaryColor,
        elevation: 2,
        child: const Icon(
          Icons.edit_outlined,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Build app bar
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 8),
      child: Row(
        children: [
          // Title
          const Text(
            'Chats',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const Spacer(),

          // Options menu
          ChatOptionsMenu(
            onFilterByUnread: _filterUnreadChats,
            onShowArchived: _showArchivedChats,
            onFindNewContacts: _findNewContacts,
            onSettings: _showChatSettings,
          ),
        ],
      ),
    );
  }

  /// Build chat list based on state
  Widget _buildChatList(ChatState chatState) {
    // Loading state
    if (chatState.isLoading) {
      return MessageLoadingStates.chatListLoading(context);
    }

    // Empty state
    if (chatState.filteredChats.isEmpty) {
      // Check if it's due to search or no chats
      if (_searchQuery.isNotEmpty) {
        return EmptySearchState(searchQuery: _searchQuery);
      } else {
        return EmptyChatState(
          onNewMessage: () => _showNewMessageModal(context),
        );
      }
    }

    // Chat list with staggered animation
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(chatProvider.notifier).refreshChats();
      },
      color: AppTheme.primaryColor,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: chatState.filteredChats.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey[200],
          indent: 72, // Align with avatar
        ),
        itemBuilder: (context, index) {
          final chat = chatState.filteredChats[index];

          return ChatItem(
            chat: chat,
            onTap: (chat) => _navigateToChat(context, chat),
            onLongPress: (chat) {
              // TODO: Show chat options (delete, mute, etc.)
            },
            animationDelay: Duration(milliseconds: 50 * index),
          );
        },
      ),
    );
  }
}
