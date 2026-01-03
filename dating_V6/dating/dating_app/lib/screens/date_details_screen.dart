import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/date_models.dart';
import '../services/date_offer_service.dart';
import '../models/date_offer.dart';
import '../services/auth_service.dart';

class DateDetailsScreen extends StatelessWidget {
  final DateIdea dateIdea;
  final UserPreferences userPreferences;
  final DateOfferService _dateOfferService = DateOfferService();
  final AuthService _authService = AuthService();

  DateDetailsScreen({
    Key? key,
    required this.dateIdea,
    required this.userPreferences,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(dateIdea.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image Section
            Container(
              height: 300,
              width: double.infinity,
              child: Image.network(
                dateIdea.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.pink[100],
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),

            // Content Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateIdea.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(dateIdea.description),
                  SizedBox(height: 16),

                  // Category and Mood
                  Row(
                    children: [
                      _buildDetailChip(
                        icon: Icons.category,
                        label: _formatEnumString(dateIdea.category),
                        color: Colors.blue[100]!,
                      ),
                      SizedBox(width: 8),
                      _buildDetailChip(
                        icon: Icons.mood,
                        label: _formatEnumString(dateIdea.mood),
                        color: Colors.pink[100]!,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Cost
                  Text(
                    'Average Cost: \$${dateIdea.averageCost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Conversation Topics
                  Text(
                    'Conversation Topics:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Wrap(
                    spacing: 8,
                    children:
                        dateIdea.conversationTopics
                            .map((topic) => Chip(label: Text(topic)))
                            .toList(),
                  ),
                  SizedBox(height: 16),

                  // Preparation Tips
                  Text(
                    'Preparation Tips:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Column(
                    children:
                        dateIdea.prepTips.map((tip) {
                          return ListTile(
                            leading: Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                            title: Text(tip),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            try {
              final user = await _authService.getCurrentUserProfile();
              await _dateOfferService.createDateOffer(
                DateOffer(
                  id: '', // Firestore will generate this
                  creatorId: user.uid,
                  creatorName: user.name,
                  creatorImageUrl: user.imageUrl,
                  creatorAge: user.age ?? 0,
                  title: dateIdea.name,
                  description: dateIdea.description,
                  place: dateIdea.name,
                  dateTime: DateTime.now().add(Duration(days: 1)),
                  estimatedCost: dateIdea.averageCost,
                  interests: [],
                  createdAt: DateTime.now(),
                  creatorGender: user.gender,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Date planned successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to plan date: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Text('Plan This Date'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink[400],
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(icon, size: 20, color: Colors.black87),
      label: Text(label),
      backgroundColor: color,
      labelStyle: TextStyle(color: Colors.black87, fontSize: 14),
    );
  }

  String _formatEnumString(dynamic enumValue) {
    return enumValue
        .toString()
        .split('.')
        .last
        .replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ')
        .capitalize();
  }
}

// Extension method to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
