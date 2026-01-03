import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:get/get.dart';
import '../models/booking_models.dart';
import '../models/chat_models.dart';
import '../models/notification_models.dart';
import '../models/provider_models.dart';
import '../models/service_models.dart';
import '../models/user_models.dart';
import '../models/credit_models.dart';

/// A service for handling real-time updates and streams from Firebase
class RealtimeService {
  // Singleton instance
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Cache of active streams to avoid duplicates
  final Map<String, Stream> _activeStreams = {};

  // Get the current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Stream of the current user profile
  Stream<User?> userProfileStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(null);

    final cacheKey = 'user_profile_$uid';
    if (_activeStreams.containsKey(cacheKey)) {
      return _activeStreams[cacheKey] as Stream<User?>;
    }

    final stream = _firestore.collection('users').doc(uid).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      return _convertDocToUser(snapshot);
    });

    _activeStreams[cacheKey] = stream;
    return stream;
  }

  // Stream for a provider profile
  Stream<ServiceProvider?> providerProfileStream(String providerId) {
    final cacheKey = 'provider_profile_$providerId';
    if (_activeStreams.containsKey(cacheKey)) {
      return _activeStreams[cacheKey] as Stream<ServiceProvider?>;
    }

    final stream = _firestore
        .collection('providers')
        .doc(providerId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return _convertDocToProvider(snapshot);
        });

    _activeStreams[cacheKey] = stream;
    return stream;
  }

  // Stream for a provider's services
  Stream<List<ProviderService>> providerServicesStream(String providerId) {
    final cacheKey = 'provider_services_$providerId';
    if (_activeStreams.containsKey(cacheKey)) {
      return _activeStreams[cacheKey] as Stream<List<ProviderService>>;
    }

    final stream = _firestore
        .collection('services')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _convertDocToService(doc)).toList(),
        );

    _activeStreams[cacheKey] = stream;
    return stream;
  }

  // Stream for notifications
  Stream<List<UserNotification>> notificationsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    final cacheKey = 'notifications_$uid';
    if (_activeStreams.containsKey(cacheKey)) {
      return _activeStreams[cacheKey] as Stream<List<UserNotification>>;
    }

    final stream = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => _convertDocToNotification(doc))
                  .toList(),
        );

    _activeStreams[cacheKey] = stream;
    return stream;
  }

  // Stream for bookings (either as seeker or provider)
  Stream<List<Booking>> bookingsStream({bool asProvider = false}) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    final fieldToCheck = asProvider ? 'providerId' : 'seekerId';
    final cacheKey = 'bookings_${asProvider ? 'provider' : 'seeker'}_$uid';

    if (_activeStreams.containsKey(cacheKey)) {
      return _activeStreams[cacheKey] as Stream<List<Booking>>;
    }

    final stream = _firestore
        .collection('bookings')
        .where(fieldToCheck, isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _convertDocToBooking(doc)).toList(),
        );

    _activeStreams[cacheKey] = stream;
    return stream;
  }

  // Stream for chat messages between two users
  Stream<List<ChatMessage>> chatMessagesStream(String chatId) {
    final cacheKey = 'chat_messages_$chatId';
    if (_activeStreams.containsKey(cacheKey)) {
      return _activeStreams[cacheKey] as Stream<List<ChatMessage>>;
    }

    final stream = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => _convertDocToChatMessage(doc))
                  .toList(),
        );

    _activeStreams[cacheKey] = stream;
    return stream;
  }

  // Stream for active chats list
  Stream<List<Conversation>> chatThreadsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    final cacheKey = 'chat_threads_$uid';
    if (_activeStreams.containsKey(cacheKey)) {
      return _activeStreams[cacheKey] as Stream<List<Conversation>>;
    }

    final stream = _firestore
        .collection('chatThreads')
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => _convertDocToConversation(doc))
                  .toList(),
        );

    _activeStreams[cacheKey] = stream;
    return stream;
  }

  // Stream for a provider's credit account
  Stream<ProviderCreditAccount?> providerCreditAccountStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(null);

    final cacheKey = 'provider_credits_$uid';
    if (_activeStreams.containsKey(cacheKey)) {
      return _activeStreams[cacheKey] as Stream<ProviderCreditAccount?>;
    }

    final accountStream = _firestore
        .collection('providerCredits')
        .doc(uid)
        .snapshots()
        .asyncMap((snapshot) async {
          if (!snapshot.exists) return null;

          // Get recent transactions too
          final transactionsSnapshot =
              await _firestore
                  .collection('creditTransactions')
                  .where('providerId', isEqualTo: uid)
                  .orderBy('timestamp', descending: true)
                  .limit(10)
                  .get();

          final transactions =
              transactionsSnapshot.docs
                  .map((doc) => _convertDocToCreditTransaction(doc))
                  .toList();

          return _convertDocToCreditAccount(
            snapshot,
            transactions: transactions,
          );
        });

    _activeStreams[cacheKey] = accountStream;
    return accountStream;
  }

  // Stream for nearby service providers (based on coordinates and service category)
  Stream<List<ServiceProvider>> nearbyProvidersStream({
    required double latitude,
    required double longitude,
    double radiusInKm = 10,
    String? serviceCategory,
  }) {
    // Note: This is a simplified implementation. In a real app, you would use Firestore's GeoPoint
    // with a solution like GeoFlutterFire or Firebase Extensions for proper geospatial queries.

    final cacheKey =
        'nearby_providers_${latitude}_${longitude}_${radiusInKm}_${serviceCategory ?? 'all'}';
    if (_activeStreams.containsKey(cacheKey)) {
      return _activeStreams[cacheKey] as Stream<List<ServiceProvider>>;
    }

    Query query = _firestore
        .collection('providers')
        .where('isActive', isEqualTo: true);

    if (serviceCategory != null) {
      query = query.where('serviceCategories', arrayContains: serviceCategory);
    }

    // For a real geospatial query, you would use a specialized solution here
    // This is just a simplified example that retrieves all active providers and filters in-memory
    final stream = query.snapshots().map((snapshot) {
      final providers =
          snapshot.docs.map((doc) => _convertDocToProvider(doc)).toList();

      // In-memory filtering based on distance - not efficient for large datasets
      // In a real app, use a proper geospatial query solution
      return providers.where((provider) {
        if (provider.latitude == 0.0 || provider.longitude == 0.0) return false;

        // Calculate rough distance - for demonstration only
        final latDiff = (provider.latitude - latitude).abs();
        final lngDiff = (provider.longitude - longitude).abs();

        // Very rough approximation - not accurate but works for example
        final roughDistance =
            (latDiff + lngDiff) * 111; // ~ km per degree at equator

        return roughDistance <= radiusInKm;
      }).toList();
    });

    _activeStreams[cacheKey] = stream;
    return stream;
  }

  // Stream for a single booking
  Stream<Booking?> singleBookingStream(String bookingId) {
    final cacheKey = 'booking_$bookingId';
    if (_activeStreams.containsKey(cacheKey)) {
      return _activeStreams[cacheKey] as Stream<Booking?>;
    }

    final stream = _firestore
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return _convertDocToBooking(snapshot);
        });

    _activeStreams[cacheKey] = stream;
    return stream;
  }

  // Stream for credit transactions history
  Stream<List<CreditTransaction>> creditTransactionsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    final cacheKey = 'credit_transactions_$uid';
    if (_activeStreams.containsKey(cacheKey)) {
      return _activeStreams[cacheKey] as Stream<List<CreditTransaction>>;
    }

    final stream = _firestore
        .collection('creditTransactions')
        .where('providerId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => _convertDocToCreditTransaction(doc))
                  .toList(),
        );

    _activeStreams[cacheKey] = stream;
    return stream;
  }

  // Clean up a specific stream
  void disposeStream(String cacheKey) {
    _activeStreams.remove(cacheKey);
  }

  // Subscribe to real-time message updates
  void subscribeToMessages({
    required String conversationId,
    required Function(ChatMessage) onNewMessage,
    required Function(String, bool) onUserTyping,
  }) {
    final cacheKey = 'chat_messages_$conversationId';

    // Set up message subscription
    _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final message = _convertDocToChatMessage(change.doc);
              onNewMessage(message);
            }
          }
        });

    // Set up typing status subscription
    _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('typing')
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            final userId = doc.id;
            final isTyping = doc.data()['isTyping'] ?? false;
            onUserTyping(userId, isTyping);
          }
        });
  }

  // Unsubscribe from message updates
  void unsubscribeFromMessages(String conversationId) {
    final cacheKey = 'chat_messages_$conversationId';
    disposeStream(cacheKey);
  }

  // Update typing status
  void updateTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) {
    _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('typing')
        .doc(userId)
        .set({'isTyping': isTyping});
  }

  // Clear all cached streams
  void disposeAllStreams() {
    _activeStreams.clear();
  }

  // Helper methods to convert Firestore documents to model objects
  User _convertDocToUser(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User.fromMap(data);
  }

  ServiceProvider _convertDocToProvider(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceProvider.fromMap(data);
  }

  ProviderService _convertDocToService(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProviderService.fromMap(data);
  }

  UserNotification _convertDocToNotification(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserNotification.fromMap(data);
  }

  Booking _convertDocToBooking(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking.fromMap(data);
  }

  ChatMessage _convertDocToChatMessage(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage.fromMap(data);
  }

  Conversation _convertDocToConversation(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation.fromMap(data);
  }

  CreditTransaction _convertDocToCreditTransaction(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CreditTransaction.fromMap(data);
  }

  ProviderCreditAccount _convertDocToCreditAccount(
    DocumentSnapshot doc, {
    List<CreditTransaction>? transactions,
  }) {
    final data = doc.data() as Map<String, dynamic>;

    // Create the account directly with the transactions
    return ProviderCreditAccount.fromMap(data, transactions: transactions);
  }
}
