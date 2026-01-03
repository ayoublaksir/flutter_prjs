import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/booking_models.dart';
import '../../models/review_models.dart' as review_models;
import '../../models/user_models.dart';
import '../../services/api_services.dart';

class BookingCompletionScreen extends StatefulWidget {
  final String bookingId;

  const BookingCompletionScreen({Key? key, required this.bookingId})
    : super(key: key);

  @override
  State<BookingCompletionScreen> createState() =>
      _BookingCompletionScreenState();
}

class _BookingCompletionScreenState extends State<BookingCompletionScreen> {
  final BookingAPI _bookingAPI = BookingAPI();
  final ReviewAPI _reviewAPI = ReviewAPI();
  final UserAPI _userAPI = UserAPI();

  bool _isLoading = true;
  bool _isSubmitting = false;
  Booking? _booking;
  ServiceProvider? _provider;

  // Review data
  final _reviewController = TextEditingController();
  double _rating = 0;
  double _punctualityRating = 0;
  double _professionalismRating = 0;
  double _serviceQualityRating = 0;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadBookingDetails() async {
    setState(() => _isLoading = true);

    try {
      // Load booking details
      final booking = await _bookingAPI.getBooking(widget.bookingId);
      setState(() => _booking = booking);

      // Load provider details
      if (booking != null) {
        final provider = await _userAPI.getProviderProfile(booking.providerId);
        setState(() => _provider = provider);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load booking details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      Get.snackbar('Error', 'Please provide a rating');
      return;
    }

    if (_booking == null || _provider == null) {
      Get.snackbar(
        'Error',
        'Cannot submit review: missing booking or provider details',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Create review model
      final review = review_models.Review(
        id: '',
        providerId: _booking!.providerId,
        seekerId: _booking!.seekerId,
        bookingId: _booking!.id,
        rating: _rating,
        comment: _reviewController.text,
        timestamp: DateTime.now(),
        reviewerName: 'Client', // Add the required field
        images: [], // Add the required field
      );

      // Submit review
      await _reviewAPI.addReview(review);

      // Mark booking as completed
      final updatedBooking = _booking!.copyWith(status: 'completed');

      // Use named parameters for updateBookingStatus
      await _bookingAPI.updateBookingStatus(
        bookingId: updatedBooking.id,
        status: 'completed',
      );

      // Show success message and navigate back
      Get.snackbar('Success', 'Review submitted successfully');
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit review: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complete Booking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complete Booking')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking summary card
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking #${_booking!.id.substring(0, 8)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),

                    // Service provider info
                    if (_provider != null) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                _provider!.profileImage.isNotEmpty
                                    ? NetworkImage(_provider!.profileImage)
                                    : null,
                            child:
                                _provider!.profileImage.isEmpty
                                    ? Text(_provider!.name.substring(0, 1))
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _provider!.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _provider!.businessName,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                    ],

                    // Booking details
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date'),
                              const SizedBox(height: 4),
                              Text(
                                '${_booking!.bookingDate.day}/${_booking!.bookingDate.month}/${_booking!.bookingDate.year}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Time'),
                              const SizedBox(height: 4),
                              Text(
                                _booking!.bookingTime,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Price
                    Row(
                      children: [
                        const Text('Total Price:'),
                        const Spacer(),
                        Text(
                          '\$${_booking!.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Review section
            Text(
              'How was your experience?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            // Overall rating
            Center(
              child: Column(
                children: [
                  const Text('Overall Rating'),
                  const SizedBox(height: 8),
                  RatingBar(
                    rating: _rating,
                    onRatingUpdate: (rating) {
                      setState(() => _rating = rating);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Detailed ratings
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate Specific Aspects',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Punctuality rating
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('Punctuality')),
                        Expanded(
                          flex: 3,
                          child: RatingBar(
                            itemSize: 24,
                            rating: _punctualityRating,
                            onRatingUpdate: (rating) {
                              setState(() => _punctualityRating = rating);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Professionalism rating
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('Professionalism')),
                        Expanded(
                          flex: 3,
                          child: RatingBar(
                            itemSize: 24,
                            rating: _professionalismRating,
                            onRatingUpdate: (rating) {
                              setState(() => _professionalismRating = rating);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Service quality rating
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('Service Quality')),
                        Expanded(
                          flex: 3,
                          child: RatingBar(
                            itemSize: 24,
                            rating: _serviceQualityRating,
                            onRatingUpdate: (rating) {
                              setState(() => _serviceQualityRating = rating);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Review text
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: 'Write your review (optional)',
                hintText: 'Share your experience with this service...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('Submit Review & Complete Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom RatingBar widget
class RatingBar extends StatelessWidget {
  final double rating;
  final Function(double) onRatingUpdate;
  final double itemSize;

  const RatingBar({
    Key? key,
    required this.rating,
    required this.onRatingUpdate,
    this.itemSize = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(maxWidth: itemSize),
          iconSize: itemSize,
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: index < rating ? Colors.amber : Colors.grey,
          ),
          onPressed: () => onRatingUpdate(index + 1.0),
        );
      }),
    );
  }
}
