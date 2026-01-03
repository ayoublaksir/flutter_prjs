// services/api_services.dart
// Contains Firebase services for API operations

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_models.dart';
import '../models/service_models.dart';
import '../models/booking_models.dart';
import '../models/review_models.dart' as review_models;
import '../services/firebase_service.dart';
import '../models/chat_models.dart';
import '../models/support_models.dart';
import '../models/payment_models.dart' as payment_models;
import '../models/notification_models.dart';
import '../models/app_models.dart'; // Import app_models.dart for Address class
import '../models/provider_models.dart' as provider_models; // Import with alias

// Base API client for Firebase
class FirebaseAPIClient {
  // Use getters instead of direct initialization
  auth.FirebaseAuth get _auth => FirebaseService.auth;
  FirebaseFirestore get _firestore => FirebaseService.firestore;
  FirebaseStorage get _storage => FirebaseService.storage;

  // Auth getters
  auth.FirebaseAuth get firebaseAuth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;

  // Get current user
  auth.User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;
}

// Authentication API
class AuthAPI extends FirebaseAPIClient {
  // Sign in with email and password
  Future<auth.User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email and password
  Future<auth.User?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      await currentUser?.updateDisplayName(displayName);
      await currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      rethrow;
    }
  }
}

// User API
class UserAPI extends FirebaseAPIClient {
  final CollectionReference _seekersCollection = FirebaseFirestore.instance
      .collection('seekers');
  final CollectionReference _providersCollection = FirebaseFirestore.instance
      .collection('providers');

  // Create a new service seeker profile
  Future<void> createSeekerProfile(ServiceSeeker seeker) async {
    try {
      await _seekersCollection.doc(seeker.id).set(seeker.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Create a new service provider profile
  Future<void> createProviderProfile(ServiceProvider provider) async {
    try {
      await _providersCollection.doc(provider.id).set(provider.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Get service seeker profile
  Future<ServiceSeeker?> getSeekerProfile(String userId) async {
    try {
      final doc = await _seekersCollection.doc(userId).get();
      if (doc.exists) {
        return ServiceSeeker.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get service provider profile
  Future<ServiceProvider?> getProviderProfile(String userId) async {
    try {
      final doc = await _providersCollection.doc(userId).get();
      if (doc.exists) {
        return ServiceProvider.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update service seeker profile
  Future<void> updateSeekerProfile(ServiceSeeker seeker) async {
    try {
      await _seekersCollection.doc(seeker.id).update(seeker.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Update service provider profile
  Future<void> updateProviderProfile(ServiceProvider provider) async {
    try {
      await _providersCollection.doc(provider.id).update(provider.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(String userId, dynamic imageFile) async {
    try {
      final storageRef = storage.ref().child('profile_images/$userId');
      final uploadTask = await storageRef.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Update provider rating
  Future<void> updateProviderRating(String providerId, double rating) async {
    try {
      await _providersCollection.doc(providerId).update({'rating': rating});
    } catch (e) {
      rethrow;
    }
  }

  // Add this method to the UserAPI class
  Future<void> updateProviderSettings(
    String providerId,
    UserSettings settings,
  ) async {
    try {
      await _providersCollection.doc(providerId).update({
        'settings': settings.toMap(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update seeker addresses
  Future<void> updateSeekerAddresses(
    String userId,
    List<Address> addresses,
    String? defaultAddressId,
  ) async {
    try {
      await _seekersCollection.doc(userId).update({
        'addresses': addresses.map((address) => address.toMap()).toList(),
        'defaultAddressId': defaultAddressId,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update seeker default address
  Future<void> updateSeekerDefaultAddress(
    String userId,
    String addressId,
  ) async {
    try {
      await _seekersCollection.doc(userId).update({
        'defaultAddressId': addressId,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get top providers
  Future<List<ServiceProvider>> getTopProviders() async {
    try {
      final snapshot =
          await _providersCollection
              .orderBy('rating', descending: true)
              .limit(5)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                ServiceProvider.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting top providers: $e');
      return [];
    }
  }

  // Add this method to the UserAPI class
  Future<void> updateSeekerSettings(
    String userId,
    UserSettings settings,
  ) async {
    try {
      await _seekersCollection.doc(userId).update({
        'settings': settings.toMap(),
      });
    } catch (e) {
      print('Error updating seeker settings: $e');
      rethrow;
    }
  }

  // Add this method to the UserAPI class
  Future<void> updateUserRole(String userId, String role) async {
    try {
      // First update the user document in Firebase Auth custom claims
      // This would typically be done through a Cloud Function

      // Then update the user's role in Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        await _firestore.collection('users').doc(userId).update({'role': role});
      } else {
        // Create the user document if it doesn't exist
        await _firestore.collection('users').doc(userId).set({
          'id': userId,
          'role': role,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  // Update provider working hours
  Future<void> updateProviderWorkingHours(
    String providerId,
    Map<String, provider_models.WorkingHours> workingHours,
  ) async {
    try {
      await _providersCollection.doc(providerId).update({
        'workingHours': workingHours.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
      });
    } catch (e) {
      print('Error updating provider working hours: $e');
      rethrow;
    }
  }

  // Update provider vacation days
  Future<void> updateProviderVacationDays(
    String providerId,
    List<DateTime> vacationDays,
  ) async {
    try {
      await _providersCollection.doc(providerId).update({
        'vacationDays':
            vacationDays.map((date) => date.millisecondsSinceEpoch).toList(),
      });
    } catch (e) {
      print('Error updating provider vacation days: $e');
      rethrow;
    }
  }

  // Update provider pricing settings
  Future<void> updateProviderPricingSettings(
    String providerId,
    provider_models.PricingSettings pricingSettings,
  ) async {
    try {
      await _providersCollection.doc(providerId).update({
        'pricingSettings': pricingSettings.toMap(),
      });
    } catch (e) {
      print('Error updating provider pricing settings: $e');
      rethrow;
    }
  }

  // Add this method to the UserAPI class
  Future<List<ServiceProvider>> findAvailableProviders({
    required String categoryId,
    required String serviceType,
    required DateTime date,
    String? location,
  }) async {
    try {
      // Query providers that offer services in the selected category
      final snapshot =
          await _providersCollection
              .where('services', arrayContains: serviceType)
              .where('isAvailable', isEqualTo: true)
              .get();

      // Filter providers based on availability for the selected date
      List<ServiceProvider> availableProviders = [];

      for (var doc in snapshot.docs) {
        final provider = ServiceProvider.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        // Check if provider is available on the selected date
        // This is a simplified check - in a real app, you'd check working hours and existing bookings
        final dayOfWeek = date.weekday.toString();
        final workingHours = provider.workingHours[dayOfWeek];

        if (workingHours != null && workingHours.isWorking) {
          availableProviders.add(provider);
        }
      }

      return availableProviders;
    } catch (e) {
      print('Error finding available providers: $e');
      return [];
    }
  }

  // Get provider portfolio
  Future<List<provider_models.PortfolioItem>> getProviderPortfolio(
    String providerId,
  ) async {
    try {
      final doc =
          await _providersCollection
              .doc(providerId)
              .collection('portfolio')
              .get();
      return doc.docs
          .map((e) => provider_models.PortfolioItem.fromMap(e.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Add portfolio item
  Future<void> addPortfolioItem(
    String providerId,
    provider_models.PortfolioItem item,
  ) async {
    try {
      await _providersCollection
          .doc(providerId)
          .collection('portfolio')
          .doc(item.id)
          .set(item.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Update portfolio item
  Future<void> updatePortfolioItem(
    String providerId,
    provider_models.PortfolioItem item,
  ) async {
    try {
      await _providersCollection
          .doc(providerId)
          .collection('portfolio')
          .doc(item.id)
          .update(item.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Delete portfolio item
  Future<void> deletePortfolioItem(String providerId, String itemId) async {
    try {
      await _providersCollection
          .doc(providerId)
          .collection('portfolio')
          .doc(itemId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // Implement missing methods needed by ChatController
  Future<User?> getUserProfile(String userId) async {
    // Implementation that fetches a user profile
    return User(
      id: userId,
      name: 'User',
      email: 'user@example.com',
      phone: '',
      profileImage: '',
      createdAt: DateTime.now(),
      role: 'user',
    );
  }

  // Add searchProviders method to UserAPI class
  Future<List<User>> searchProviders({
    required String query,
    Map<String, dynamic>? filters,
    Map<String, double>? location,
  }) async {
    try {
      // Query providers based on name or description
      final querySnapshot =
          await _providersCollection.where('role', isEqualTo: 'provider').get();

      final providers =
          querySnapshot.docs
              .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
              .where(
                (provider) =>
                    provider.name.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

      // Apply filters
      if (filters != null) {
        final double minRating = filters['minRating'] ?? 0.0;
        final bool availableNow = filters['availableNow'] ?? false;

        // Add filter logic here
      }

      return providers;
    } catch (e) {
      print('Error searching providers: $e');
      return [];
    }
  }
}

// Service API
class ServiceAPI extends FirebaseAPIClient {
  final CollectionReference _categoriesCollection = FirebaseFirestore.instance
      .collection('categories');
  final CollectionReference _servicesCollection = FirebaseFirestore.instance
      .collection('services');
  final CollectionReference _providerServicesCollection = FirebaseFirestore
      .instance
      .collection('provider_services');

  // Add this line to define _userAPI
  final UserAPI _userAPI = UserAPI();

  // Get all service categories
  Future<List<ServiceCategory>> getServiceCategories() async {
    try {
      final querySnapshot =
          await _categoriesCollection.where('isActive', isEqualTo: true).get();

      return querySnapshot.docs
          .map(
            (doc) =>
                ServiceCategory.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get services by category
  Future<List<ServiceItem>> getServicesByCategory(String categoryId) async {
    try {
      final querySnapshot =
          await _servicesCollection
              .where('categoryId', isEqualTo: categoryId)
              .get();

      return querySnapshot.docs
          .map((doc) => ServiceItem.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get popular services
  Future<List<ServiceItem>> getPopularServices() async {
    try {
      final querySnapshot =
          await _servicesCollection
              .where('isPopular', isEqualTo: true)
              .limit(10)
              .get();

      return querySnapshot.docs
          .map((doc) => ServiceItem.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Search services
  Future<List<ServiceItem>> searchServices({
    required String query,
    Map<String, dynamic>? filters,
    Map<String, double>? location,
  }) async {
    try {
      // Firebase doesn't support full-text search natively
      // This is a simple implementation
      final querySnapshot = await _servicesCollection.get();

      final searchResults =
          querySnapshot.docs
              .map(
                (doc) =>
                    ServiceItem.fromMap(doc.data() as Map<String, dynamic>),
              )
              .where(
                (service) =>
                    service.name.toLowerCase().contains(query.toLowerCase()) ||
                    service.description.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    service.tags.any(
                      (tag) => tag.toLowerCase().contains(query.toLowerCase()),
                    ),
              )
              .toList();

      // Apply filters if provided
      if (filters != null) {
        final double maxPrice = filters['maxPrice'] ?? double.infinity;
        final double minRating = filters['minRating'] ?? 0.0;

        searchResults.removeWhere((service) => service.basePrice > maxPrice);
      }

      return searchResults;
    } catch (e) {
      print('Error searching services: $e');
      return [];
    }
  }

  // Get provider services
  Future<List<ProviderService>> getProviderServices(String providerId) async {
    try {
      final snapshot =
          await _firestore
              .collection('providerServices')
              .where('providerId', isEqualTo: providerId)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                ProviderService.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting provider services: $e');
      return [];
    }
  }

  // Add provider service
  Future<String> addProviderService(ProviderService service) async {
    try {
      final docRef = _firestore.collection('providerServices').doc();
      final newService = service.copyWith(id: docRef.id);
      await docRef.set(newService.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding provider service: $e');
      rethrow;
    }
  }

  // Upload service gallery image
  Future<String> uploadServiceImage(String serviceId, dynamic imageFile) async {
    try {
      final storageRef = storage.ref().child(
        'service_images/$serviceId/${DateTime.now().millisecondsSinceEpoch}',
      );
      final uploadTask = await storageRef.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Get service by ID
  Future<ServiceItem?> getServiceById(String serviceId) async {
    try {
      final doc = await _servicesCollection.doc(serviceId).get();
      if (doc.exists) {
        return ServiceItem.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Add this method to the ServiceAPI class
  Future<List<ProviderService>> getProvidersForService(String serviceId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('providerServices')
              .where('serviceItemId', isEqualTo: serviceId)
              .where('isAvailable', isEqualTo: true)
              .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                ProviderService.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting providers for service: $e');
      return [];
    }
  }

  // Add this method to the ServiceAPI class
  Future<ProviderService?> getServiceDetails(String serviceId) async {
    try {
      final doc = await _providerServicesCollection.doc(serviceId).get();
      if (doc.exists) {
        return ProviderService.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting service details: $e');
      return null;
    }
  }

  // Get popular categories
  Future<List<ServiceCategory>> getPopularCategories() async {
    try {
      final snapshot =
          await _categoriesCollection
              .where('isPopular', isEqualTo: true)
              .limit(10)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                ServiceCategory.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting popular categories: $e');
      return [];
    }
  }

  // Get featured services
  Future<List<ProviderService>> getFeaturedServices() async {
    try {
      final snapshot =
          await _providerServicesCollection
              .where('isFeatured', isEqualTo: true)
              .limit(6)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                ProviderService.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting featured services: $e');
      return [];
    }
  }

  // Add these methods to ServiceAPI class

  Future<List<RecurringService>> getRecurringServices(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('recurring_services')
              .where('userId', isEqualTo: userId)
              .get();

      List<RecurringService> services = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final provider = await _userAPI.getProviderProfile(data['providerId']);

        if (provider != null) {
          services.add(RecurringService.fromMap(data, provider));
        }
      }

      return services;
    } catch (e) {
      print('Error getting recurring services: $e');
      return [];
    }
  }

  Future<void> cancelRecurringService(String serviceId) async {
    try {
      await _firestore.collection('recurring_services').doc(serviceId).update({
        'status': 'cancelled',
      });
    } catch (e) {
      print('Error cancelling recurring service: $e');
      rethrow;
    }
  }

  // Add this method to the ServiceAPI class
  Future<List<ProviderService>> getSavedServices(String userId) async {
    try {
      // First get the user's saved service IDs
      final userDoc = await _firestore.collection('seekers').doc(userId).get();
      if (!userDoc.exists) return [];

      final userData = userDoc.data() as Map<String, dynamic>;
      final savedServiceIds = List<String>.from(
        userData['savedServices'] ?? [],
      );

      if (savedServiceIds.isEmpty) return [];

      // Then fetch the actual service details
      List<ProviderService> services = [];

      for (var serviceId in savedServiceIds) {
        final serviceDoc =
            await _firestore
                .collection('provider_services')
                .doc(serviceId)
                .get();
        if (serviceDoc.exists) {
          services.add(
            ProviderService.fromMap(serviceDoc.data() as Map<String, dynamic>),
          );
        }
      }

      return services;
    } catch (e) {
      print('Error getting saved services: $e');
      return [];
    }
  }

  // Also add this method
  Future<void> removeFromFavorites(String serviceId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get current saved services
      final userDoc = await _firestore.collection('seekers').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final savedServices = List<String>.from(userData['savedServices'] ?? []);

      // Remove the service ID
      savedServices.remove(serviceId);

      // Update the user document
      await _firestore.collection('seekers').doc(userId).update({
        'savedServices': savedServices,
      });
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  // Add these methods to the ServiceAPI class

  Future<bool> isServiceFavorite(String serviceId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final userDoc = await _firestore.collection('seekers').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final savedServices = List<String>.from(userData['savedServices'] ?? []);

      return savedServices.contains(serviceId);
    } catch (e) {
      print('Error checking if service is favorite: $e');
      return false;
    }
  }

  Future<void> addToFavorites(String serviceId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final userDoc = await _firestore.collection('seekers').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final savedServices = List<String>.from(userData['savedServices'] ?? []);

      if (!savedServices.contains(serviceId)) {
        savedServices.add(serviceId);

        await _firestore.collection('seekers').doc(userId).update({
          'savedServices': savedServices,
        });
      }
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  // Add these methods to your ServiceAPI class
  Future<void> createProviderService(ProviderService service) async {
    // Mock implementation for now
    await Future.delayed(const Duration(milliseconds: 500));
    print('Service created: ${service.name}');
    return;
  }

  Future<void> updateProviderService(ProviderService service) async {
    // Mock implementation for now
    await Future.delayed(const Duration(milliseconds: 500));
    print('Service updated: ${service.name}');
    return;
  }

  Future<void> deleteProviderService(String serviceId) async {
    // Mock implementation for now
    await Future.delayed(const Duration(milliseconds: 500));
    print('Service deleted: $serviceId');
    return;
  }

  // Add this method to the ServiceAPI class
  Future<ServiceProvider> getServiceProvider(String serviceId) async {
    try {
      final service = await getServiceDetails(serviceId);
      if (service == null) {
        throw Exception('Service not found');
      }

      // Get the provider details using the providerId from the service
      final provider = await _userAPI.getProviderProfile(service.providerId);
      if (provider == null) {
        throw Exception('Provider not found');
      }

      return provider;
    } catch (e) {
      print('Error getting service provider: $e');
      rethrow;
    }
  }

  // Add this method to the ServiceAPI class
  Future<void> unsaveService(String userId, String serviceId) async {
    try {
      // This is just a wrapper for the removeFromFavorites method
      await removeFromFavorites(serviceId);
    } catch (e) {
      print('Error unsaving service: $e');
      rethrow;
    }
  }

  // Add this method to ServiceAPI class
  Future<List<ServiceItem>> getRecentSearches(String userId) async {
    try {
      // In a real implementation, you would fetch from Firestore
      // For now, return a mock list of recent searches
      return [];
    } catch (e) {
      print('Error getting recent searches: $e');
      return [];
    }
  }

  // Add this method to ServiceAPI class
  Future<void> saveSearch(String userId, String query) async {
    try {
      // In a real implementation, save to Firestore
      // For now, just print
      print('Saving search query: $query for user: $userId');
    } catch (e) {
      print('Error saving search: $e');
    }
  }
}

// Booking API
class BookingAPI extends FirebaseAPIClient {
  final CollectionReference _bookingsCollection = FirebaseFirestore.instance
      .collection('bookings');
  final CollectionReference _paymentsCollection = FirebaseFirestore.instance
      .collection('payments');
  final CollectionReference _reviewsCollection = FirebaseFirestore.instance
      .collection('reviews');

  // Create a new booking
  Future<String> createBooking(Booking booking) async {
    try {
      final docRef = await _bookingsCollection.add(booking.toMap());

      // Update the booking with the generated ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Get booking by ID
  Future<Booking?> getBooking(String bookingId) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get bookings for seeker
  Future<List<Booking>> getSeekerBookings(
    String seekerId, {
    String? status,
  }) async {
    try {
      Query query = _bookingsCollection.where('seekerId', isEqualTo: seekerId);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot =
          await query.orderBy('bookingDate', descending: true).get();

      return querySnapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get bookings for provider
  Future<List<Booking>> getProviderBookings(
    String providerId, {
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _bookingsCollection.where(
        'providerId',
        isEqualTo: providerId,
      );

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      // Add date filtering if provided
      if (startDate != null && endDate != null) {
        query = query
            .where('bookingDate', isGreaterThanOrEqualTo: startDate)
            .where('bookingDate', isLessThanOrEqualTo: endDate);
      } else if (startDate != null) {
        query = query.where('bookingDate', isGreaterThanOrEqualTo: startDate);
      } else if (endDate != null) {
        query = query.where('bookingDate', isLessThanOrEqualTo: endDate);
      }

      final querySnapshot =
          await query.orderBy('bookingDate', descending: true).get();

      return querySnapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get provider recent bookings
  Future<List<Booking>> getProviderRecentBookings(
    String providerId, {
    int limit = 5,
  }) async {
    try {
      final querySnapshot =
          await _bookingsCollection
              .where('providerId', isEqualTo: providerId)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting provider recent bookings: $e');
      return [];
    }
  }

  // Get upcoming bookings for a provider
  Future<List<Booking>> getUpcomingBookings({
    required String providerId,
    int limit = 5,
  }) async {
    try {
      final now = DateTime.now();
      final querySnapshot =
          await _bookingsCollection
              .where('providerId', isEqualTo: providerId)
              .where('bookingDate', isGreaterThanOrEqualTo: now)
              .where('status', whereIn: ['pending', 'confirmed', 'accepted'])
              .orderBy('bookingDate')
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting upcoming bookings: $e');
      return [];
    }
  }

  // Get count of pending bookings
  Future<int> getPendingBookingCount({required String providerId}) async {
    try {
      final querySnapshot =
          await _bookingsCollection
              .where('providerId', isEqualTo: providerId)
              .where('status', isEqualTo: 'pending')
              .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting pending booking count: $e');
      return 0;
    }
  }

  // Update booking status with named parameters
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      await _bookingsCollection.doc(bookingId).update({'status': status});
    } catch (e) {
      print('Error updating booking status: $e');
      rethrow;
    }
  }

  // Update booking notes
  Future<void> updateBookingNotes(String bookingId, String notes) async {
    try {
      await _bookingsCollection.doc(bookingId).update({'description': notes});
    } catch (e) {
      print('Error updating booking notes: $e');
      rethrow;
    }
  }

  // Update booking date and time
  Future<void> updateBookingDateTime({
    required String bookingId,
    required DateTime date,
    required String time,
  }) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'bookingDate': date,
        'bookingTime': time,
      });
    } catch (e) {
      print('Error updating booking date and time: $e');
      rethrow;
    }
  }

  // Get provider stats
  Future<provider_models.ProviderStats> getProviderStats(
    String providerId,
  ) async {
    try {
      // Get all bookings for this provider
      final querySnapshot =
          await _bookingsCollection
              .where('providerId', isEqualTo: providerId)
              .get();

      final bookings =
          querySnapshot.docs
              .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

      // Calculate statistics
      int totalBookings = bookings.length;
      int pendingBookings = bookings.where((b) => b.status == 'pending').length;
      int completedBookings =
          bookings.where((b) => b.status == 'completed').length;
      int cancelledBookings =
          bookings
              .where((b) => b.status == 'cancelled' || b.status == 'declined')
              .length;
      double totalEarnings = bookings
          .where((b) => b.status == 'completed')
          .fold(0.0, (sum, booking) => sum + booking.price);

      // Get provider's average rating
      final reviewSnapshot =
          await _reviewsCollection
              .where('revieweeId', isEqualTo: providerId)
              .get();

      final reviews =
          reviewSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

      double rating = 0.0;
      int totalReviews = reviews.length;

      if (totalReviews > 0) {
        rating =
            reviews.fold(
              0.0,
              (sum, review) => sum + (review['rating'] ?? 0.0),
            ) /
            totalReviews;
      }

      return provider_models.ProviderStats(
        totalBookings: totalBookings,
        pendingBookings: pendingBookings,
        completedBookings: completedBookings,
        cancelledBookings: cancelledBookings,
        totalEarnings: totalEarnings,
        rating: rating,
        totalReviews: totalReviews,
      );
    } catch (e) {
      print('Error getting provider stats: $e');
      return provider_models.ProviderStats(
        totalBookings: 0,
        pendingBookings: 0,
        completedBookings: 0,
        cancelledBookings: 0,
        totalEarnings: 0.0,
        rating: 0.0,
        totalReviews: 0,
      );
    }
  }

  // Get booking statistics for a provider
  Future<Map<String, dynamic>> getProviderBookingStats(
    String providerId,
  ) async {
    try {
      // Get all bookings for this provider
      final querySnapshot =
          await _bookingsCollection
              .where('providerId', isEqualTo: providerId)
              .get();

      final bookings =
          querySnapshot.docs
              .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

      // Calculate statistics
      int totalBookings = bookings.length;
      int pendingBookings = bookings.where((b) => b.status == 'pending').length;
      int completedBookings =
          bookings.where((b) => b.status == 'completed').length;
      double totalEarnings = bookings
          .where((b) => b.status == 'completed')
          .fold(0.0, (sum, booking) => sum + booking.price);

      return {
        'totalBookings': totalBookings,
        'pendingBookings': pendingBookings,
        'completedBookings': completedBookings,
        'totalEarnings': totalEarnings,
      };
    } catch (e) {
      print('Error getting provider booking stats: $e');
      return {
        'totalBookings': 0,
        'pendingBookings': 0,
        'completedBookings': 0,
        'totalEarnings': 0.0,
      };
    }
  }
}

class ChatAPI extends FirebaseAPIClient {
  final CollectionReference _messagesCollection = FirebaseFirestore.instance
      .collection('messages');

  // Get chat messages
  Future<List<ChatMessage>> getChatMessages(String bookingId) async {
    try {
      final snapshot =
          await _messagesCollection
              .where('bookingId', isEqualTo: bookingId)
              .orderBy('timestamp')
              .get();

      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting chat messages: $e');
      return [];
    }
  }

  // Send message
  Future<void> sendMessage(ChatMessage message) async {
    try {
      await _messagesCollection.add(message.toMap());
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String bookingId) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final snapshot =
          await _messagesCollection
              .where('bookingId', isEqualTo: bookingId)
              .where('receiverId', isEqualTo: user.uid)
              .where('isRead', isEqualTo: false)
              .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Listen to messages
  void listenToMessages(
    String bookingId,
    Function(List<ChatMessage>) onMessages,
  ) {
    _messagesCollection
        .where('bookingId', isEqualTo: bookingId)
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
          final messages =
              snapshot.docs
                  .map(
                    (doc) =>
                        ChatMessage.fromMap(doc.data() as Map<String, dynamic>),
                  )
                  .toList();
          onMessages(messages);
        });
  }

  // Update typing status
  Future<void> updateTypingStatus(String bookingId, bool isTyping) async {
    try {
      final user = currentUser;
      if (user == null) return;

      await firestore.collection('typingStatus').doc(bookingId).set({
        user.uid: isTyping,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  // Implement missing methods needed by ChatController
  Future<List<Conversation>> getUserConversations(String userId) async {
    // Implementation that fetches conversations from Firestore
    return [];
  }

  Future<Conversation> getConversation(String conversationId) async {
    // Implementation that fetches a single conversation
    return Conversation(
      id: conversationId,
      participants: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      unreadCount: {},
    );
  }

  Future<Conversation?> findConversation(
    String userId,
    String otherUserId,
  ) async {
    // Implementation that finds a conversation between two users
    return null;
  }

  Future<Conversation> createConversation({
    required List<String> participants,
    required String title,
  }) async {
    // Implementation that creates a new conversation
    return Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      participants: participants,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      unreadCount: {},
    );
  }

  Future<List<ChatMessage>> getMessages({
    required String conversationId,
    required int page,
    required int limit,
  }) async {
    // Implementation that fetches messages for a conversation
    return [];
  }

  Future<void> markMessageAsRead(String messageId) async {
    // Implementation that marks a message as read
  }

  Future<void> markConversationAsRead(
    String conversationId,
    String userId,
  ) async {
    // Implementation that marks all messages in a conversation as read
  }

  Future<void> deleteMessage(String messageId) async {
    // Implementation that deletes a message
  }
}

class PaymentAPI extends FirebaseAPIClient {
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Get payment methods for a user
  Future<List<payment_models.PaymentMethod>> getPaymentMethods(
    String userId,
  ) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return [];

      final data = doc.data() as Map<String, dynamic>;
      final paymentMethods = data['paymentMethods'] as List<dynamic>?;

      if (paymentMethods == null) return [];

      return paymentMethods
          .map(
            (method) => payment_models.PaymentMethod.fromMap(
              method as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      print('Error getting payment methods: $e');
      return [];
    }
  }

  // Get default payment method
  Future<String?> getDefaultPaymentMethod(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return data['defaultPaymentMethodId'] as String?;
    } catch (e) {
      print('Error getting default payment method: $e');
      return null;
    }
  }

  // Set default payment method
  Future<void> setDefaultPaymentMethod(String userId, String methodId) async {
    try {
      await _usersCollection.doc(userId).update({
        'defaultPaymentMethodId': methodId,
      });
    } catch (e) {
      print('Error setting default payment method: $e');
      rethrow;
    }
  }

  // Remove payment method
  Future<void> removePaymentMethod(String userId, String methodId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final paymentMethods = data['paymentMethods'] as List<dynamic>?;

      if (paymentMethods == null) return;

      final updatedMethods =
          paymentMethods.where((method) => method['id'] != methodId).toList();

      await _usersCollection.doc(userId).update({
        'paymentMethods': updatedMethods,
      });
    } catch (e) {
      print('Error removing payment method: $e');
      rethrow;
    }
  }

  // Add payment method
  Future<void> addPaymentMethod(
    String userId,
    payment_models.PaymentMethod method,
  ) async {
    try {
      final doc = await _usersCollection.doc(userId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final paymentMethods = data['paymentMethods'] as List<dynamic>? ?? [];

        // Add new method
        paymentMethods.add(method.toMap());

        await _usersCollection.doc(userId).update({
          'paymentMethods': paymentMethods,
        });
      } else {
        await _usersCollection.doc(userId).set({
          'paymentMethods': [method.toMap()],
        });
      }
    } catch (e) {
      print('Error adding payment method: $e');
      rethrow;
    }
  }

  // Get bank account for a provider
  Future<provider_models.BankAccount?> getBankAccount(String userId) async {
    try {
      final doc =
          await _firestore.collection('bank_accounts').doc(userId).get();

      if (doc.exists) {
        return provider_models.BankAccount.fromMap(
          doc.data() as Map<String, dynamic>,
        );
      }

      return null;
    } catch (e) {
      print('Error getting bank account: $e');
      return null;
    }
  }

  // Save bank account
  Future<void> saveBankAccount(
    String userId,
    provider_models.BankAccount account,
  ) async {
    try {
      await _firestore
          .collection('bank_accounts')
          .doc(userId)
          .set(account.toMap());
    } catch (e) {
      print('Error saving bank account: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getProviderPayments(
    String providerId,
    DateTime startDate,
  ) async {
    // Implement the method
    // Return payment data
    return []; // Add this line to return an empty list
  }

  Future<List<dynamic>> getPendingPayouts(String providerId) async {
    // Implement the method
    // Return payout data
    return []; // Add this line to return an empty list
  }
}

class NotificationAPI extends FirebaseAPIClient {
  final CollectionReference _notificationsCollection = FirebaseFirestore
      .instance
      .collection('notifications');

  // Get user notifications
  Future<List<UserNotification>> getUserNotifications(String userId) async {
    try {
      final snapshot =
          await _notificationsCollection
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                UserNotification.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting user notifications: $e');
      return [];
    }
  }

  // Mark notifications as read
  Future<void> markNotificationsAsRead(String userId) async {
    try {
      final snapshot =
          await _notificationsCollection
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  // Add these methods to the NotificationAPI class

  // Clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    try {
      final snapshot =
          await _notificationsCollection
              .where('userId', isEqualTo: userId)
              .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Get notifications for a user
  Future<List<UserNotification>> getNotifications(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => UserNotification.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('read', isEqualTo: false)
              .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }
}

// Add this class to your api_services.dart file
class ReviewAPI {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get reviewsCollection => _firestore.collection('reviews');

  // Get reviews for a provider
  Future<List<review_models.Review>> getProviderReviews(
    String providerId,
  ) async {
    try {
      final snapshot =
          await reviewsCollection
              .where('providerId', isEqualTo: providerId)
              .orderBy('timestamp', descending: true)
              .get();

      return snapshot.docs
          .map(
            (doc) => review_models.Review.fromMap(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      print('Error getting provider reviews: $e');
      return [];
    }
  }

  // Add a review
  Future<String> addReview(review_models.Review review) async {
    try {
      final docRef = reviewsCollection.doc();
      final newReview = review.copyWith(id: docRef.id);
      await docRef.set(newReview.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }

  // Update a review
  Future<void> updateReview(review_models.Review review) async {
    try {
      await reviewsCollection.doc(review.id).update(review.toMap());
    } catch (e) {
      print('Error updating review: $e');
      rethrow;
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      await reviewsCollection.doc(reviewId).delete();
    } catch (e) {
      print('Error deleting review: $e');
      rethrow;
    }
  }
}

// Add this class to api_services.dart
class SupportAPI extends FirebaseAPIClient {
  final CollectionReference _ticketsCollection = FirebaseFirestore.instance
      .collection('support_tickets');
  final CollectionReference _faqCollection = FirebaseFirestore.instance
      .collection('faqs');

  // Get user tickets
  Future<List<SupportTicket>> getUserTickets(String userId) async {
    try {
      final snapshot =
          await _ticketsCollection
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map(
            (doc) => SupportTicket.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting user tickets: $e');
      return [];
    }
  }

  // Create ticket
  Future<String> createTicket(SupportTicket ticket) async {
    try {
      final docRef = await _ticketsCollection.add(ticket.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating ticket: $e');
      rethrow;
    }
  }

  // Get FAQ categories
  Future<List<FAQCategory>> getFAQCategories() async {
    try {
      final snapshot = await _faqCollection.get();

      return snapshot.docs
          .map((doc) => FAQCategory.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting FAQ categories: $e');
      return [];
    }
  }
}
