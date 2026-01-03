import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_models.dart';
import '../models/user_models.dart';
import '../services/api_services.dart';
import '../services/realtime_services.dart';
import '../services/storage_services.dart';
import 'base_controller.dart';

class ChatController extends BaseController {
  // Services via dependency injection
  final ChatAPI _chatAPI = Get.find<ChatAPI>();
  final UserAPI _userAPI = Get.find<UserAPI>();
  final RealtimeService _realtimeServices = Get.find<RealtimeService>();
  final StorageService _storageServices = Get.find<StorageService>();

  // Reactive state
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxList<Conversation> conversations = <Conversation>[].obs;
  final Rx<Conversation?> currentConversation = Rx<Conversation?>(null);
  final Rx<User?> chattingWith = Rx<User?>(null);
  final RxBool hasMoreMessages = true.obs;
  final RxBool isTyping = false.obs;

  // Message state
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  final RxList<File> selectedImages = <File>[].obs;

  // Pagination
  final int messagesPerPage = 30;
  final RxInt currentPage = 1.obs;

  // Conversation ID (passed from arguments)
  final String? conversationId;
  final String? recipientId;

  ChatController({this.conversationId, this.recipientId});

  @override
  void onInit() {
    super.onInit();

    // If we have a conversation ID, load that conversation
    if (conversationId != null) {
      loadConversation(conversationId!);
    }
    // If we have a recipient ID but no conversation ID, load/create conversation
    else if (recipientId != null) {
      findOrCreateConversation(recipientId!);
    }
    // Otherwise just load all conversations
    else {
      loadConversations();
    }

    // Setup scroll listener for pagination
    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();

    // Unsubscribe from real-time updates
    if (currentConversation.value != null) {
      _realtimeServices.unsubscribeFromMessages(currentConversation.value!.id);
    }

    super.onClose();
  }

  /// Scroll listener for pagination
  void _scrollListener() {
    if (scrollController.position.pixels ==
            scrollController.position.maxScrollExtent &&
        hasMoreMessages.value) {
      loadMoreMessages();
    }
  }

  /// Load all conversations
  Future<void> loadConversations() {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      final result = await _chatAPI.getUserConversations(userId);
      conversations.value = result;
    });
  }

  /// Load specific conversation
  Future<void> loadConversation(String conversationId) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Load conversation details
      final conversation = await _chatAPI.getConversation(conversationId);
      currentConversation.value = conversation;

      // Load recipient details
      final otherUserId = conversation.participants.firstWhere(
        (id) => id != userId,
        orElse: () => '',
      );

      if (otherUserId.isNotEmpty) {
        final otherUser = await _userAPI.getUserProfile(otherUserId);
        chattingWith.value = otherUser;
      }

      // Load messages (first page)
      await loadMessages(conversationId);

      // Subscribe to real-time updates for new messages
      _subscribeToMessages(conversationId);

      // Mark conversation as read
      _chatAPI.markConversationAsRead(conversationId, userId);
    });
  }

  /// Find or create conversation with a user
  Future<void> findOrCreateConversation(String otherUserId) {
    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty) {
        showError('User not authenticated');
        return;
      }

      // Load recipient details
      final otherUser = await _userAPI.getUserProfile(otherUserId);
      chattingWith.value = otherUser;

      // Check if a conversation already exists
      final existingConversation = await _chatAPI.findConversation(
        userId,
        otherUserId,
      );

      if (existingConversation != null) {
        currentConversation.value = existingConversation;
        await loadMessages(existingConversation.id);
        _subscribeToMessages(existingConversation.id);

        // Mark as read
        _chatAPI.markConversationAsRead(existingConversation.id, userId);
      } else {
        // Create a new conversation
        final newConversation = await _chatAPI.createConversation(
          participants: [userId, otherUserId],
          title: otherUser?.name ?? 'New Conversation',
        );

        currentConversation.value = newConversation;
        messages.clear();
        hasMoreMessages.value = false;

        // Subscribe to updates
        _subscribeToMessages(newConversation.id);
      }
    });
  }

  /// Load messages for a conversation
  Future<void> loadMessages(String conversationId) async {
    hasMoreMessages.value = true;
    currentPage.value = 1;

    final result = await _chatAPI.getMessages(
      conversationId: conversationId,
      page: currentPage.value,
      limit: messagesPerPage,
    );

    messages.value = result;

    // Check if we've reached the end
    if (result.length < messagesPerPage) {
      hasMoreMessages.value = false;
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (!hasMoreMessages.value || currentConversation.value == null) return;

    currentPage.value++;

    final result = await _chatAPI.getMessages(
      conversationId: currentConversation.value!.id,
      page: currentPage.value,
      limit: messagesPerPage,
    );

    if (result.isNotEmpty) {
      messages.addAll(result);
    }

    // Check if we've reached the end
    if (result.length < messagesPerPage) {
      hasMoreMessages.value = false;
    }
  }

  /// Subscribe to real-time message updates
  void _subscribeToMessages(String conversationId) {
    _realtimeServices.subscribeToMessages(
      conversationId: conversationId,
      onNewMessage: (message) {
        if (!messages.any((m) => m.id == message.id)) {
          messages.insert(0, message);

          // Mark as read if it's from the other user
          if (message.senderId != currentUserId) {
            _chatAPI.markMessageAsRead(message.id);
          }
        }
      },
      onUserTyping: (userId, isTyping) {
        if (userId != currentUserId) {
          this.isTyping.value = isTyping;
        }
      },
    );
  }

  /// Send text message
  Future<void> sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty && selectedImages.isEmpty) return Future.value();

    return runWithLoading(() async {
      final userId = currentUserId;
      if (userId.isEmpty || currentConversation.value == null) {
        showError('Cannot send message');
        return;
      }

      final conversationId = currentConversation.value!.id;

      // Get recipient ID
      final recipientId = currentConversation.value!.participants.firstWhere(
        (id) => id != userId,
        orElse: () => '',
      );

      if (recipientId.isEmpty) {
        showError('Invalid recipient');
        return;
      }

      // Upload images if any
      List<String> imageUrls = [];
      if (selectedImages.isNotEmpty) {
        for (final image in selectedImages) {
          final url = await _storageServices.uploadChatImage(image);
          if (url.isNotEmpty) {
            imageUrls.add(url);
          }
        }
      }

      // Create message
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: userId,
        receiverId: recipientId,
        content: text,
        images: imageUrls,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Send message
      await _chatAPI.sendMessage(message);

      // Clear input
      messageController.clear();
      selectedImages.clear();
    });
  }

  /// Update typing status
  void updateTypingStatus(bool isTyping) {
    if (currentConversation.value == null) return;

    _realtimeServices.updateTypingStatus(
      conversationId: currentConversation.value!.id,
      userId: currentUserId,
      isTyping: isTyping,
    );
  }

  /// Select images
  Future<void> selectImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        selectedImages.addAll(images.map((xFile) => File(xFile.path)));
      }
    } catch (e) {
      debugPrint('Error selecting images: $e');
      showError('Failed to select images');
    }
  }

  /// Take photo
  Future<void> takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        selectedImages.add(File(photo.path));
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      showError('Failed to take photo');
    }
  }

  /// Remove selected image
  void removeSelectedImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  /// Format message time
  String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return 'Today, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Check if message is from current user
  bool isFromCurrentUser(ChatMessage message) {
    return message.senderId == currentUserId;
  }

  /// Delete message
  Future<void> deleteMessage(String messageId) {
    return runWithLoading(() async {
      await _chatAPI.deleteMessage(messageId);
      messages.removeWhere((message) => message.id == messageId);
      showSuccess('Message deleted');
    });
  }

  /// Mark all messages as read
  Future<void> markAllAsRead() {
    return runWithLoading(() async {
      if (currentConversation.value == null) return;

      await _chatAPI.markConversationAsRead(
        currentConversation.value!.id,
        currentUserId,
      );

      // Update local state
      final updatedMessages =
          messages.map((message) {
            if (message.recipientId == currentUserId && !message.isRead) {
              return message.copyWith(isRead: true);
            }
            return message;
          }).toList();

      messages.value = updatedMessages;
    });
  }

  /// Get conversation title
  String getConversationTitle(Conversation conversation) {
    if (conversation.title.isNotEmpty) {
      return conversation.title;
    }

    // Default to the other participant's name if we have it
    final otherUserId = conversation.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    return conversation.participantsInfo[otherUserId]?.name ?? 'Conversation';
  }

  /// Get conversation image
  String? getConversationImage(Conversation conversation) {
    // Use the other participant's image
    final otherUserId = conversation.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    return conversation.participantsInfo[otherUserId]?.image;
  }

  /// Get unread count for a conversation
  int getUnreadCount(Conversation conversation) {
    return conversation.unreadCount[currentUserId] ?? 0;
  }
}
