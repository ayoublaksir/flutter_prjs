import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/date_offer.dart';
import '../models/gender.dart';
import 'package:geolocator/geolocator.dart';
import 'notification_service.dart';
import 'package:rxdart/rxdart.dart';
import '../models/user_profile.dart'; // Add this import
import '../models/subscription.dart';
import '../services/purchase_service.dart';
import 'dart:math';
import '../services/chat_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart'; // Add this import
import 'package:geocoding/geocoding.dart';

class DateOfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final String _collection = 'dateOffers';

  // Create a new date offer
  Future<String> createDateOffer(DateOffer offer) async {
    try {
      // Check if user can create more offers
      final canCreate = await canCreateOffer(offer.creatorId);
      if (!canCreate) {
        throw Exception(
          'You have reached the maximum number of free offers. Upgrade to premium to create more!',
        );
      }

      // Get user's city if not provided
      if (offer.city == 'Unknown' && offer.location != null) {
        try {
          final placemarks = await placemarkFromCoordinates(
            offer.location!.latitude,
            offer.location!.longitude,
          );
          if (placemarks.isNotEmpty) {
            final city = placemarks.first.locality ?? 'Unknown';
            // Update the offer with the city
            final updatedOffer = DateOffer(
              id: offer.id,
              creatorId: offer.creatorId,
              creatorName: offer.creatorName,
              creatorImageUrl: offer.creatorImageUrl,
              creatorAge: offer.creatorAge,
              title: offer.title,
              description: offer.description,
              place: offer.place,
              dateTime: offer.dateTime,
              estimatedCost: offer.estimatedCost,
              interests: offer.interests,
              status: offer.status,
              responders: offer.responders,
              acceptedResponderId: offer.acceptedResponderId,
              createdAt: offer.createdAt,
              location: offer.location,
              creatorGender: offer.creatorGender,
              city: city,
            );
            offer = updatedOffer;
          }
        } catch (e) {
          print('Error getting city from coordinates: $e');
        }
      }

      final docRef = await _firestore
          .collection(_collection)
          .add(offer.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating date offer: $e');
      throw Exception('Failed to create date offer: $e');
    }
  }

  // Get date offers feed for a user
  Stream<List<DateOffer>> getDateOffersFeed(
    String userId,
    Gender userGender,
    GeoPoint userLocation,
    String userCity, {
    double radiusInKm = 50,
  }) {
    final now = DateTime.now();
    // Only show offers from the opposite gender in the same city
    final oppositeGender = _getOppositeGender(userGender);

    return _firestore
        .collection(_collection)
        .where(
          'status',
          whereIn: [
            DateOfferStatus.active.toString(),
            DateOfferStatus.pending.toString(),
          ],
        )
        .where('creatorGender', isEqualTo: oppositeGender.toString())
        .where('city', isEqualTo: userCity)
        .where('dateTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => DateOffer.fromFirestore(doc))
                  .where(
                    (offer) =>
                        offer.creatorId != userId && // Don't show own offers
                        !offer.responders.containsKey(
                          userId,
                        ), // Don't show offers user already responded to
                  )
                  .toList(),
        );
  }

  // Respond to a date offer
  Future<void> respondToOffer(
    String offerId,
    String responderId,
    String responderName,
    String? responderImageUrl,
    Gender responderGender,
  ) async {
    final offerDoc =
        await _firestore.collection(_collection).doc(offerId).get();
    final offer = DateOffer.fromFirestore(offerDoc);

    // Validation checks
    if (offer.creatorGender == responderGender) {
      throw Exception('Can only respond to offers from the opposite gender');
    }

    if (offer.dateTime.isBefore(DateTime.now())) {
      throw Exception('This offer has expired');
    }

    if (offer.creatorId == responderId) {
      throw Exception('Cannot respond to your own offer');
    }

    if (offer.status != DateOfferStatus.active &&
        offer.status != DateOfferStatus.pending) {
      throw Exception('This offer is no longer available');
    }

    // Check if user has already responded
    if (offer.responders.containsKey(responderId)) {
      throw Exception('You have already responded to this offer');
    }

    // Add response with transaction
    await _firestore.runTransaction((transaction) async {
      final freshOffer = await transaction.get(offerDoc.reference);
      final currentResponders =
          (freshOffer.data()?['responders'] as Map<String, dynamic>?) ?? {};

      // Set status to pending when getting first responder
      final newStatus =
          currentResponders.isEmpty
              ? DateOfferStatus.pending.toString()
              : freshOffer.get('status');

      transaction.update(offerDoc.reference, {
        'responders.$responderId': {
          'id': responderId,
          'name': responderName,
          'imageUrl': responderImageUrl,
          'respondedAt': FieldValue.serverTimestamp(),
          'status': ResponderStatus.pending.toString(),
        },
        'status': newStatus,
      });
    });

    // Send notification
    await _notificationService.sendResponseNotification(
      toUserId: offer.creatorId,
      fromUserId: responderId,
      fromUserName: responderName,
      fromUserImageUrl: responderImageUrl,
      offerId: offerId,
      offerTitle: offer.title,
    );
  }

  // Accept or decline a response
  Future<void> handleResponse(
    String offerId,
    bool accepted,
    String responderId,
    String creatorName,
    Gender creatorGender,
  ) async {
    print(
      '🔍 handleResponse called - offerId: $offerId, accepted: $accepted, responderId: $responderId',
    );

    try {
      final offerDoc =
          await _firestore.collection(_collection).doc(offerId).get();
      if (!offerDoc.exists) {
        print('❌ Offer document does not exist: $offerId');
        throw Exception('Offer not found');
      }

      final offer = DateOffer.fromFirestore(offerDoc);
      print('✅ Offer retrieved: ${offer.title}, creatorId: ${offer.creatorId}');

      // Verify the data we need is available
      print('👤 Creator ID: ${offer.creatorId}');
      print('👤 Responder ID: $responderId');
      print('📅 Date time: ${offer.dateTime}');
      print('📝 Responders: ${offer.responders.keys.join(', ')}');

      // Run the transaction to update the offer status
      await _firestore.runTransaction((transaction) async {
        // Get responder's profile to check gender
        final responderDoc = await transaction.get(
          _firestore.collection('users').doc(responderId),
        );
        final responderGender = Gender.values.firstWhere(
          (e) => e.toString() == responderDoc.get('gender'),
        );

        if (creatorGender == responderGender) {
          throw Exception('Can only accept responses from the opposite gender');
        }

        if (offer.dateTime.isBefore(DateTime.now())) {
          throw Exception('This offer has expired');
        }

        if (offer.creatorId == responderId) {
          throw Exception('Cannot respond to your own offer');
        }

        if (offer.status != DateOfferStatus.active &&
            offer.status != DateOfferStatus.pending) {
          throw Exception('This offer is no longer available');
        }

        if (accepted) {
          // Create base updates
          final updates = {
            'status': DateOfferStatus.matched.toString(),
            'acceptedResponderId': responderId,
            'responders.$responderId.status':
                ResponderStatus.accepted.toString(),
          };

          // Add declined status for other responders only if they exist
          final otherResponders =
              offer.responders.keys.where((key) => key != responderId).toList();
          if (otherResponders.isNotEmpty) {
            final declinedUpdates = otherResponders
                .map(
                  (key) => {
                    'responders.$key.status':
                        ResponderStatus.declined.toString(),
                  },
                )
                .reduce((value, element) => {...value, ...element});
            updates.addAll(declinedUpdates);
          }

          transaction.update(
            _firestore.collection(_collection).doc(offerId),
            updates,
          );
        } else {
          // When declining, check if any pending responders remain
          final updates = {
            'responders.$responderId.status':
                ResponderStatus.declined.toString(),
          };

          // If no pending responders left, revert to active
          if (!offer.pendingResponders
              .where((r) => r.id != responderId)
              .any((r) => r.status == ResponderStatus.pending)) {
            updates['status'] = DateOfferStatus.active.toString();
          }

          transaction.update(
            _firestore.collection(_collection).doc(offerId),
            updates,
          );
        }
        print('✅ Transaction completed successfully');
      });

      // Send notification
      await _notificationService.sendDecisionNotification(
        toUserId: responderId,
        fromUserId: offer.creatorId,
        fromUserName: creatorName,
        offerId: offerId,
        offerTitle: offer.title,
        accepted: accepted,
      );
      print('✅ Notification sent');

      // If accepted, send default messages to both users
      if (accepted) {
        print('🔔 Match accepted, preparing to send default messages');
        final chatService = ChatService();

        // Get responder's name
        final responderInfo = offer.responders[responderId];
        print('👤 Responder info: $responderInfo');

        if (responderInfo == null) {
          print('❌ Responder info is null! This should not happen.');
          // Try to get responder info from users collection as fallback
          final responderDoc =
              await _firestore.collection('users').doc(responderId).get();
          final responderData = responderDoc.data();
          final responderName =
              responderDoc.exists &&
                      responderData != null &&
                      responderData['name'] != null
                  ? responderData['name'] as String
                  : 'your match';
          print('👤 Fallback responder name: $responderName');

          try {
            // Send messages with fallback name
            await _sendMatchMessages(
              chatService,
              offer,
              responderId,
              responderName,
              creatorName,
            );
          } catch (e) {
            print('❌ Error sending messages with fallback: $e');
            print('Stack trace: ${StackTrace.current}');
          }
        } else {
          final responderName = responderInfo.name;
          print('👤 Responder name: $responderName');

          try {
            // Send messages with responder info
            await _sendMatchMessages(
              chatService,
              offer,
              responderId,
              responderName,
              creatorName,
            );
          } catch (e) {
            print('❌ Error sending messages: $e');
            print('Stack trace: ${StackTrace.current}');
          }
        }
      }
    } catch (e) {
      print('❌ Error in handleResponse: $e');
      print('Stack trace: ${StackTrace.current}');
      throw e;
    }
  }

  // Helper method to send match messages
  Future<void> _sendMatchMessages(
    ChatService chatService,
    DateOffer offer,
    String responderId,
    String responderName,
    String creatorName,
  ) async {
    print('📤 Sending message from creator to responder');
    // Send message from creator to responder
    await chatService.sendMessage(
      senderId: offer.creatorId,
      receiverId: responderId,
      content:
          "Hi $responderName! I'm excited we matched for \"${offer.title}\"! Looking forward to our date on ${_formatDate(offer.dateTime)}.",
    );

    print('📤 Sending message from responder to creator');
    // Send message from responder to creator
    await chatService.sendMessage(
      senderId: responderId,
      receiverId: offer.creatorId,
      content:
          "Hi $creatorName! Thanks for accepting my response to \"${offer.title}\"! I'm looking forward to our date!",
    );

    print('✅ Default messages sent successfully');
  }

  // Get user's active offers
  Stream<List<DateOffer>> getUserOffers(String userId) {
    return _firestore
        .collection(_collection)
        .where(
          'creatorId',
          isEqualTo: userId,
        ) // Show all user's offers regardless of status
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => DateOffer.fromFirestore(doc)).toList(),
        );
  }

  // Get user's matches (accepted date offers)
  Stream<List<DateOffer>> getUserMatches(String userId) {
    // Get offers where user is the creator and has an accepted match
    final creatorMatches = _firestore
        .collection(_collection)
        .where('status', isEqualTo: DateOfferStatus.matched.toString())
        .where('creatorId', isEqualTo: userId)
        .orderBy('dateTime', descending: true);

    // Get offers where user is the accepted responder
    final responderMatches = _firestore
        .collection(_collection)
        .where('status', isEqualTo: DateOfferStatus.matched.toString())
        .where('acceptedResponderId', isEqualTo: userId)
        .orderBy('dateTime', descending: true);

    // Combine both streams
    return Rx.combineLatest2(
      creatorMatches.snapshots(),
      responderMatches.snapshots(),
      (QuerySnapshot creator, QuerySnapshot responder) {
        final creatorOffers = creator.docs.map(
          (doc) => DateOffer.fromFirestore(doc),
        );
        final responderOffers = responder.docs.map(
          (doc) => DateOffer.fromFirestore(doc),
        );
        return [...creatorOffers, ...responderOffers]
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      },
    );
  }

  Stream<List<DateOffer>> getNearbyOffers(String userId) {
    return _firestore
        .collection('dateOffers')
        .where('status', isEqualTo: DateOfferStatus.active.toString())
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => DateOffer.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<DateOffer>> getMyOffers(String userId) {
    return _firestore
        .collection('dateOffers')
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => DateOffer.fromFirestore(doc)).toList(),
        );
  }

  Future<DateOffer> getDateOffer(String offerId) async {
    final doc = await _firestore.collection(_collection).doc(offerId).get();
    if (!doc.exists) {
      throw Exception('Date offer not found');
    }
    return DateOffer.fromFirestore(doc);
  }

  Stream<List<DateOffer>> getAvailableOffers(UserProfile currentUser) {
    final now = DateTime.now();
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: DateOfferStatus.active.toString())
        .where(
          'creatorGender',
          isEqualTo: _getOppositeGender(currentUser.gender).toString(),
        )
        .where('dateTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('dateTime', descending: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => DateOffer.fromFirestore(doc)).toList(),
        );
  }

  Gender _getOppositeGender(Gender userGender) {
    return userGender == Gender.male ? Gender.female : Gender.male;
  }

  Future<void> expireOldOffers() async {
    final now = DateTime.now();
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('status', isEqualTo: DateOfferStatus.active.toString())
            .where('dateTime', isLessThan: Timestamp.fromDate(now))
            .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': DateOfferStatus.expired.toString(),
      });
    }
    await batch.commit();
  }

  Stream<DateOffer> getDateOfferStream(String offerId) {
    return _firestore
        .collection(_collection)
        .doc(offerId)
        .snapshots()
        .map((doc) => DateOffer.fromFirestore(doc));
  }

  Future<bool> canCreateOffer(String userId) async {
    final purchaseService = PurchaseService();
    final isPremium = purchaseService.purchases.any(
      (purchase) =>
          purchase.status == PurchaseStatus.purchased &&
          purchase.productID.contains('premium'),
    );

    // Allow premium users to create unlimited offers
    if (isPremium) return true;

    // For free users, check how many offers they've created
    final userOffers =
        await _firestore
            .collection(_collection)
            .where('creatorId', isEqualTo: userId)
            .get();

    // Free users can create up to 3 offers
    return userOffers.docs.length < 3;
  }

  Future<void> cancelDateOffer(String offerId) async {
    // First check if the offer is already matched
    final offerDoc =
        await _firestore.collection(_collection).doc(offerId).get();
    final offer = DateOffer.fromFirestore(offerDoc);

    if (offer.status == DateOfferStatus.matched) {
      throw Exception('Cannot cancel a matched date offer');
    }

    await _firestore.collection(_collection).doc(offerId).update({
      'status': DateOfferStatus.expired.toString(),
    });
  }

  Future<void> acceptResponse(String offerId, String responderId) async {
    // First check if the offer is already matched
    final offerDoc =
        await _firestore.collection(_collection).doc(offerId).get();
    final offer = DateOffer.fromFirestore(offerDoc);

    if (offer.status == DateOfferStatus.matched) {
      throw Exception('This date offer is already matched with someone');
    }

    await _firestore.collection(_collection).doc(offerId).update({
      'status': DateOfferStatus.matched.toString(),
      'acceptedResponderId': responderId,
      'responders.$responderId.status': ResponderStatus.accepted.toString(),
    });

    // Send notification to the accepted responder
    final data = offerDoc.data() as Map<String, dynamic>;
    final responders = data['responders'] as Map<String, dynamic>;
    final responderInfo = responders[responderId] as Map<String, dynamic>;

    await _notificationService.sendNotification(
      responderId,
      'Date Offer Accepted!',
      'Your response to "${data['title']}" was accepted!',
    );
  }

  Future<void> declineResponse(String offerId, String responderId) async {
    await _firestore.collection(_collection).doc(offerId).update({
      'responders.$responderId.status': ResponderStatus.declined.toString(),
    });
  }

  Stream<List<DateOffer>> getNearbyDateOffers(
    String userId,
    Gender userGender,
    GeoPoint userLocation,
    String userCity, {
    double radius = 50,
    int limit = 50,
  }) {
    final now = DateTime.now();
    // Only show offers from the opposite gender in the same city
    final oppositeGender = _getOppositeGender(userGender);

    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: DateOfferStatus.active.toString())
        .where('creatorGender', isEqualTo: oppositeGender.toString())
        .where('city', isEqualTo: userCity)
        .where('dateTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('dateTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final offers =
              snapshot.docs.map((doc) => DateOffer.fromFirestore(doc)).toList();

          return offers.where((offer) {
            // Don't show own offers or already responded offers
            if (offer.creatorId == userId ||
                offer.responders.containsKey(userId)) {
              return false;
            }

            // Calculate distance and filter by radius
            final offerLocation = offer.location;
            if (offerLocation == null) return false;

            final distance = _calculateDistance(
              userLocation.latitude,
              userLocation.longitude,
              offerLocation.latitude,
              offerLocation.longitude,
            );

            return distance <= radius;
          }).toList();
        });
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  Future<DateOffer?> getOffer(String offerId) async {
    // Implementation to fetch a date offer by ID
    // This should connect to your data source (Firestore, API, etc.)
    try {
      // Example implementation if using Firestore:
      final doc =
          await FirebaseFirestore.instance
              .collection('dateOffers')
              .doc(offerId)
              .get();
      if (doc.exists && doc.data() != null) {
        return DateOffer.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting date offer: $e');
      return null;
    }
  }

  Future<DateOffer> getDateOfferById(String offerId) async {
    try {
      final doc = await _firestore.collection('dateOffers').doc(offerId).get();

      if (!doc.exists) {
        throw Exception('Date offer not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      return DateOffer.fromMap(data, doc.id);
    } catch (e) {
      print('Error getting date offer: $e');
      throw Exception('Failed to load date offer details');
    }
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
