import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/review_models.dart';
import 'package:intl/intl.dart';
import '../../models/user_models.dart';
import '../../models/booking_models.dart' as booking_models;

class ReviewsScreen extends StatefulWidget {
  final String providerId;

  const ReviewsScreen({Key? key, required this.providerId}) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final ReviewAPI _reviewAPI = ReviewAPI();
  final UserAPI _userAPI = UserAPI();

  bool _isLoading = true;
  ServiceProvider? _provider;
  List<Review> _reviews = [];
  String _sortBy = 'recent'; // 'recent', 'rating_high', 'rating_low'
  String _filterBy = 'all'; // 'all', '5', '4', '3', '2', '1'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _userAPI.getProviderProfile(widget.providerId),
        _reviewAPI.getProviderReviews(widget.providerId),
      ]);

      setState(() {
        _provider = results[0] as ServiceProvider;
        _reviews = results[1] as List<Review>;
        _sortReviews();
      });
    } catch (e) {
      print('Error loading reviews: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading reviews')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sortReviews() {
    switch (_sortBy) {
      case 'recent':
        _reviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case 'rating_high':
        _reviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'rating_low':
        _reviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }
  }

  List<Review> get _filteredReviews {
    if (_filterBy == 'all') return _reviews;
    return _reviews
        .where((review) => review.rating == int.parse(_filterBy))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  if (_provider != null) _buildReviewSummary(),
                  _buildFilterSort(),
                  Expanded(
                    child:
                        _filteredReviews.isEmpty
                            ? Center(
                              child: Text(
                                'No reviews found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            )
                            : ListView.builder(
                              itemCount: _filteredReviews.length,
                              itemBuilder: (context, index) {
                                return _buildReviewCard(
                                  _filteredReviews[index],
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildReviewSummary() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    _provider!.rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _provider!.rating.floor()
                            ? Icons.star
                            : index < _provider!.rating
                            ? Icons.star_half
                            : Icons.star_border,
                        color: Colors.amber,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_provider!.reviewCount} reviews',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                children: List.generate(5, (index) {
                  final rating = 5 - index;
                  final count =
                      _reviews.where((r) => r.rating == rating).length;
                  final percentage =
                      _reviews.isEmpty ? 0 : count / _reviews.length;

                  return Row(
                    children: [
                      Text('$rating'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage.toDouble(),
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$count'),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSort() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _filterBy,
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('All Ratings'),
                ),
                ...List.generate(5, (index) {
                  final rating = (5 - index).toString();
                  return DropdownMenuItem(
                    value: rating,
                    child: Text('$rating Stars'),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _filterBy = value!);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _sortBy,
              items: const [
                DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
                DropdownMenuItem(
                  value: 'rating_high',
                  child: Text('Highest Rated'),
                ),
                DropdownMenuItem(
                  value: 'rating_low',
                  child: Text('Lowest Rated'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                  _sortReviews();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      review.reviewerImage != null
                          ? NetworkImage(review.reviewerImage!)
                          : null,
                  child:
                      review.reviewerImage == null
                          ? const Icon(Icons.person)
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('MMM d, y').format(review.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
            if (review.serviceDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                review.serviceDetails!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Text(review.comment),
            if (review.response != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Provider Response',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(review.response!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
