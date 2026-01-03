import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/modern_app_bar.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverImageUrl;

  const ChatScreen({
    Key? key,
    required this.receiverId,
    required this.receiverName,
    this.receiverImageUrl,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();

  late String _currentUserId;
  UserProfile? _otherUser;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final currentUser = await _authService.getCurrentUserProfile();
      _currentUserId = currentUser.uid;

      // Mark messages as read when opening chat
      await _chatService.markMessagesAsRead(_currentUserId, widget.receiverId);

      // Get other user's profile if not provided
      if (widget.receiverName == null || widget.receiverImageUrl == null) {
        _otherUser = await _userService.getUserProfile(widget.receiverId);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(
        senderId: _currentUserId,
        receiverId: widget.receiverId,
        content: message,
      );

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherUserName = widget.receiverName ?? _otherUser?.name ?? 'Chat';
    final otherUserImage =
        widget.receiverImageUrl ?? _otherUser?.profileImageUrl;

    return Scaffold(
      appBar: ModernAppBar(
        title: otherUserName,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/user_profile',
                arguments: widget.receiverId,
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<ChatMessage>>(
                      stream: _chatService.getMessages(
                        _currentUserId,
                        widget.receiverId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final messages = snapshot.data ?? [];

                        if (messages.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage:
                                      otherUserImage != null
                                          ? NetworkImage(otherUserImage)
                                          : null,
                                  child:
                                      otherUserImage == null
                                          ? Icon(Icons.person, size: 50)
                                          : null,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Start chatting with $otherUserName',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Say hello and get to know each other!',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          reverse: true,
                          padding: EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message.senderId == _currentUserId;

                            return _buildMessageBubble(message, isMe);
                          },
                        );
                      },
                    ),
                  ),
                  _buildMessageInput(),
                ],
              ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final dateFormat = DateFormat('h:mm a');
    final timeString = dateFormat.format(message.timestamp);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  widget.receiverImageUrl != null
                      ? NetworkImage(widget.receiverImageUrl!)
                      : _otherUser?.profileImageUrl != null
                      ? NetworkImage(_otherUser!.profileImageUrl!)
                      : null,
              child:
                  (widget.receiverImageUrl == null &&
                          (_otherUser == null ||
                              _otherUser!.profileImageUrl == null))
                      ? Icon(Icons.person, size: 16)
                      : null,
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isMe
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.isDeleted
                        ? 'This message was deleted'
                        : message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontStyle:
                          message.isDeleted
                              ? FontStyle.italic
                              : FontStyle.normal,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isMe
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: 8),
            Icon(
              message.status == MessageStatus.sent
                  ? Icons.check
                  : message.status == MessageStatus.delivered
                  ? Icons.done_all
                  : Icons.done_all,
              size: 16,
              color:
                  message.status == MessageStatus.read
                      ? Colors.blue
                      : Colors.grey[400],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.photo),
            onPressed: () {
              // Implement image sending
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
            ),
          ),
          SizedBox(width: 8),
          _isSending
              ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : IconButton(
                icon: Icon(Icons.send),
                color: Theme.of(context).colorScheme.primary,
                onPressed: _sendMessage,
              ),
        ],
      ),
    );
  }
}
