import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../widgets/modern_app_bar.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  String? _currentUserId;
  bool _isLoading = true;
  List<ChatPreview>? _chats;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId != null) {
        setState(() => _currentUserId = userId);

        print('🔍 Loading chats for user: $userId');

        // Debug chat data
        await _chatService.debugChatData(userId);

        // Try to repair chat data
        await _chatService.repairChatData(userId);

        // Debug again after repair
        await _chatService.debugChatData(userId);

        // Listen to chat list updates
        _chatService
            .getUserChatList(userId)
            .listen(
              (chats) {
                print('📋 Received ${chats.length} chats from stream');
                if (mounted) {
                  setState(() {
                    _chats = chats;
                    _isLoading = false;
                  });
                }
              },
              onError: (error) {
                print('❌ Error in chat list stream: $error');
                setState(() => _isLoading = false);
              },
            );
      }
    } catch (e) {
      print('❌ Error loading chats: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(title: 'Messages', showBackButton: false),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _chats == null || _chats!.isEmpty
              ? _buildEmptyState()
              : _buildChatList(),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'When you match with someone, your conversations will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/offers-feed'),
            child: Text('Find Dates'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
          SizedBox(height: 16),
          if (_currentUserId != null)
            TextButton(
              onPressed: () async {
                final testUserId = await _userService.getRandomUserId(
                  _currentUserId!,
                );
                if (testUserId != null) {
                  await _chatService.createTestChat(
                    _currentUserId!,
                    testUserId,
                  );
                  _loadChats();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No other users found for testing')),
                  );
                }
              },
              child: Text('Debug: Create Test Chat'),
            ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      itemCount: _chats!.length,
      itemBuilder: (context, index) {
        final chat = _chats![index];
        return FutureBuilder<UserProfile?>(
          future: _userService.getUserProfile(chat.userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, color: Colors.grey[600]),
                ),
                title: Text('Loading...'),
                subtitle: Text(chat.lastMessage),
              );
            }

            final userProfile = snapshot.data!;
            return ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChatScreen(
                          receiverId: chat.userId,
                          receiverName: userProfile.name,
                          receiverImageUrl: userProfile.profileImageUrl,
                        ),
                  ),
                );
              },
              leading: CircleAvatar(
                backgroundImage:
                    userProfile.profileImageUrl != null
                        ? NetworkImage(userProfile.profileImageUrl!)
                        : null,
                backgroundColor: Colors.grey[300],
                child:
                    userProfile.profileImageUrl == null
                        ? Text(userProfile.name[0].toUpperCase())
                        : null,
              ),
              title: Text(
                userProfile.name,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTimestamp(chat.timestamp),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  if (chat.unreadCount > 0)
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        chat.unreadCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', () {
                Navigator.pushReplacementNamed(context, '/home');
              }),
              _buildNavItem(Icons.explore_outlined, 'Explore', () {
                Navigator.pushReplacementNamed(context, '/offers-feed');
              }),
              _buildNavItem(Icons.favorite_border_outlined, 'Matches', () {
                Navigator.pushReplacementNamed(context, '/matches');
              }),
              _buildNavItem(Icons.chat_bubble_outline, 'Chat', () {
                Navigator.pushReplacementNamed(context, '/chat-list');
              }, isSelected: true),
              _buildNavItem(Icons.person_outline, 'Profile', () {
                Navigator.pushReplacementNamed(context, '/profile');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
