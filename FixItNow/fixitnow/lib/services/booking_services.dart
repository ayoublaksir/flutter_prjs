// services/booking_services.dart
// Booking service for handling booking-related business logic

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_models.dart';
import '../models/service_models.dart';
import '../models/user_models.dart';
import '../models/review_models.dart' as review_models;
import 'api_services.dart';
import 'notification_services.dart';
import 'location_services.dart';

class BookingService {
  final BookingAPI _bookingAPI = BookingAPI();
  final ServiceAPI _serviceAPI = ServiceAPI();
  final UserAPI _userAPI = UserAPI();
  final ReviewAPI _reviewAPI = ReviewAPI();
  final LocationService _locationService = LocationService();
  final NotificationManager _notificationManager = NotificationManager();

  // Create a new booking
  Future<String> createBooking({
    required String seekerId,
    required String providerId,
    required String serviceId,
    required DateTime bookingDate,
    required String address,
    required String description,
    required double latitude,
    required double longitude,
    required double price,
    required Map<String, dynamic> additionalServices,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final booking = Booking(
      id: '',
      seekerId: seekerId,
      providerId: providerId,
      serviceId: serviceId,
      bookingDate: bookingDate,
      createdAt: DateTime.now(),
      status: 'pending',
      address: address,
      description: description,
      latitude: latitude,
      longitude: longitude,
      price: price,
      additionalServices: additionalServices,
      startTime: startTime,
      endTime: endTime,
      bookingTime: DateTime.now().toString(),
      paymentMethod: 'card',
      location: address,
    );

    final bookingId = await _bookingAPI.createBooking(booking);

    // Send notification to provider
    await _sendBookingNotification(
      bookingId: bookingId,
      providerId: providerId,
      seekerId: seekerId,
      type: 'new_booking',
    );

    return bookingId;
  }

  // Get booking by ID
  Future<Booking?> getBooking(String bookingId) async {
    return await _bookingAPI.getBooking(bookingId);
  }

  // Get bookings for seeker
  Future<List<Booking>> getSeekerBookings(
    String seekerId, {
    String? status,
  }) async {
    return await _bookingAPI.getSeekerBookings(seekerId, status: status);
  }

  // Get bookings for provider
  Future<List<Booking>> getProviderBookings(
    String providerId, {
    String? status,
  }) async {
    return await _bookingAPI.getProviderBookings(providerId, status: status);
  }

  // Update booking status
  Future<void> updateBookingStatus(
    String bookingId,
    String status, {
    String? cancellationReason,
  }) async {
    final booking = await _bookingAPI.getBooking(bookingId);
    if (booking == null) {
      throw Exception('Booking not found');
    }

    // Update booking with new status
    final updatedBooking = booking.copyWith(
      status: status,
      cancellationReason: cancellationReason,
    );

    await _bookingAPI.updateBookingStatus(bookingId: bookingId, status: status);

    // Send appropriate notifications
    String notificationType;
    switch (status) {
      case 'confirmed':
        notificationType = 'booking_confirmed';
        break;
      case 'cancelled':
        notificationType = 'booking_cancelled';
        break;
      case 'in_progress':
        notificationType = 'booking_started';
        break;
      case 'completed':
        notificationType = 'booking_completed';
        break;
      default:
        notificationType = 'booking_updated';
    }

    await _sendBookingNotification(
      bookingId: bookingId,
      providerId: booking.providerId,
      seekerId: booking.seekerId,
      type: notificationType,
    );
  }

  // Complete a booking with review
  Future<void> completeBookingWithReview(
    String bookingId,
    double rating,
    String comment,
    Map<String, double> categoryRatings,
  ) async {
    final booking = await _bookingAPI.getBooking(bookingId);
    if (booking == null) {
      throw Exception('Booking not found');
    }

    // Update booking status to completed
    await updateBookingStatus(bookingId, 'completed');

    // Create review if rating and comment provided
    if (rating > 0) {
      final review = Review(
        id: '',
        bookingId: bookingId,
        reviewerId: booking.seekerId,
        revieweeId: booking.providerId,
        serviceId: booking.serviceId,
        rating: rating,
        comment: comment,
        categoryRatings: categoryRatings,
        createdAt: DateTime.now(),
      );

      // Convert booking_models.Review to review_models.Review
      final reviewModel = review_models.Review(
        id: review.id,
        bookingId: review.bookingId,
        seekerId: review.reviewerId,
        providerId: review.revieweeId,
        rating: review.rating,
        comment: review.comment,
        timestamp: review.createdAt,
        reviewerName: "User",
      );

      await _reviewAPI.addReview(reviewModel);

      // Update provider's average rating
      await _updateProviderRating(booking.providerId);
    }
  }

  // Calculate distance between booking location and provider
  Future<double> calculateBookingDistance(String bookingId) async {
    final booking = await _bookingAPI.getBooking(bookingId);
    if (booking == null) {
      throw Exception('Booking not found');
    }

    final provider = await _userAPI.getProviderProfile(booking.providerId);
    if (provider == null) {
      throw Exception('Provider not found');
    }

    return _locationService.calculateDistance(
      booking.latitude,
      booking.longitude,
      provider.latitude,
      provider.longitude,
    );
  }

  // Get upcoming bookings for a user (either provider or seeker)
  Future<List<Booking>> getUpcomingBookings(
    String userId,
    String userType,
  ) async {
    if (userType == 'provider') {
      return await _bookingAPI.getProviderBookings(userId, status: 'confirmed');
    } else {
      return await _bookingAPI.getSeekerBookings(userId, status: 'confirmed');
    }
  }

  // Private method to send booking notifications
  Future<void> _sendBookingNotification({
    required String bookingId,
    required String providerId,
    required String seekerId,
    required String type,
  }) async {
    // Determine recipient based on notification type
    String recipientId;
    if (type == 'new_booking' || type == 'booking_cancelled') {
      recipientId = providerId; // Notify provider
    } else {
      recipientId = seekerId; // Notify seeker
    }

    // Get booking details for notification
    final booking = await _bookingAPI.getBooking(bookingId);
    if (booking == null) return;

    // Get service details
    final service = await _serviceAPI.getServiceById(booking.serviceId);
    if (service == null) return;

    // Create notification title and body
    String title, body;
    switch (type) {
      case 'new_booking':
        title = 'New Booking Request';
        body = 'You have a new booking request for ${service.name}';
        break;
      case 'booking_confirmed':
        title = 'Booking Confirmed';
        body = 'Your booking for ${service.name} has been confirmed';
        break;
      case 'booking_cancelled':
        title = 'Booking Cancelled';
        body = 'A booking for ${service.name} has been cancelled';
        break;
      case 'booking_started':
        title = 'Service Started';
        body = 'Your service for ${service.name} has started';
        break;
      case 'booking_completed':
        title = 'Service Completed';
        body = 'Your service for ${service.name} has been completed';
        break;
      default:
        title = 'Booking Update';
        body = 'Your booking for ${service.name} has been updated';
    }

    // Send notification
    // This would use the NotificationManager to send a push notification
    // Implementation depends on how notifications are handled in the app
  }

  // Update provider's average rating after a new review
  Future<void> _updateProviderRating(String providerId) async {
    final reviews = await _reviewAPI.getProviderReviews(providerId);

    if (reviews.isEmpty) return;

    // Calculate average rating
    double totalRating = 0;
    for (final review in reviews) {
      totalRating += review.rating;
    }

    final averageRating = totalRating / reviews.length;

    // Update provider profile with new rating
    await _userAPI.updateProviderRating(providerId, averageRating);
  }
}
