import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/chat_models.dart';
import '../../models/user_models.dart';
import 'package:intl/intl.dart';

class SeekerChatScreen extends StatefulWidget {
  final String providerId;
  final String bookingId;

  const SeekerChatScreen({
    Key? key,
    required this.providerId,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<SeekerChatScreen> createState() => _SeekerChatScreenState();
}

class _SeekerChatScreenState extends State<SeekerChatScreen> {
  final ChatAPI _chatAPI = ChatAPI();
  final UserAPI _userAPI = UserAPI();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  ServiceProvider? _provider;
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadChatData();
    _setupMessageListener();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _userAPI.getProviderProfile(widget.providerId),
        _chatAPI.getChatMessages(widget.bookingId),
      ]);

      setState(() {
        _provider = results[0] as ServiceProvider?;
        _messages = results[1] as List<ChatMessage>;
      });

      // Mark messages as read
      _chatAPI.markMessagesAsRead(widget.bookingId);

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error loading chat data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading chat')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupMessageListener() {
    _chatAPI.listenToMessages(widget.bookingId, (messages) {
      setState(() => _messages = messages);
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = _authService.currentUser;
    if (user == null) return;

    _messageController.clear();

    try {
      await _chatAPI.sendMessage(
        ChatMessage(
          bookingId: widget.bookingId,
          senderId: user.uid,
          receiverId: widget.providerId,
          content: text,
          timestamp: DateTime.now(),
          isRead: false,
        ),
      );
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error sending message')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isLoading
                ? const Text('Loading...')
                : Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          _provider?.profileImage != null
                              ? NetworkImage(_provider!.profileImage!)
                              : null,
                      child:
                          _provider?.profileImage == null
                              ? const Icon(Icons.person)
                              : null,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _provider?.businessName ?? 'Provider',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (_isTyping)
                          const Text(
                            'typing...',
                            style: TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final user = _authService.currentUser;
                        final isMe = message.senderId == user?.uid;

                        return _MessageBubble(message: message, isMe: isMe);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          onPressed: () {
                            // Implement file attachment
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                            ),
                            onChanged: (text) {
                              // Notify typing status
                              _chatAPI.updateTypingStatus(
                                widget.bookingId,
                                true,
                              );
                            },
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isMe
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(color: isMe ? Colors.white : null),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
