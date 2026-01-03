import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/chat_models.dart';
import '../../models/user_models.dart';

class ProviderChatScreen extends StatefulWidget {
  final String seekerId;
  final String? bookingId;

  const ProviderChatScreen({Key? key, required this.seekerId, this.bookingId})
    : super(key: key);

  @override
  State<ProviderChatScreen> createState() => _ProviderChatScreenState();
}

class _ProviderChatScreenState extends State<ProviderChatScreen> {
  final ChatAPI _chatAPI = ChatAPI();
  final AuthService _authService = AuthService();
  final UserAPI _userAPI = UserAPI();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = true;
  ServiceSeeker? _seeker;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  Future<void> _loadChat() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _userAPI.getSeekerProfile(widget.seekerId),
        _chatAPI.getChatMessages(widget.seekerId),
      ]);

      setState(() {
        _seeker = results[0] as ServiceSeeker;
        _messages = results[1] as List<ChatMessage>;
      });
    } catch (e) {
      print('Error loading chat: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final user = _authService.currentUser;
    if (user == null) return;

    try {
      await _chatAPI.sendMessage(
        ChatMessage(
          id: '',
          senderId: user.uid,
          receiverId: widget.seekerId,
          content: message,
          timestamp: DateTime.now(),
          bookingId: widget.bookingId ?? '',
          isRead: false,
        ),
      );

      _messageController.clear();
      _loadChat();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_seeker?.name ?? 'Chat'),
        actions: [
          if (widget.bookingId != null)
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {
                // Navigate to booking details
              },
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
                  ),
                  _buildMessageInput(),
                ],
              ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final user = _authService.currentUser;
    final isMe = user?.uid == message.senderId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
          ],
        ),
      ),
    );
  }
}
