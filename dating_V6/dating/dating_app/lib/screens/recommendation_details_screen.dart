import 'package:flutter/material.dart';
import '../models/date_models.dart';
import '../services/date_offer_service.dart';
import '../services/auth_service.dart';
import '../models/date_offer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/modern_app_bar.dart';
import 'package:provider/provider.dart';

class RecommendationDetailsScreen extends StatelessWidget {
  final DateIdea dateIdea;
  final DateOfferService _dateOfferService = DateOfferService();
  final AuthService _authService = AuthService();

  RecommendationDetailsScreen({Key? key, required this.dateIdea})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: ModernAppBar(
        title: 'Date Details',
        textColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (dateIdea.imageUrl != null)
              Image.network(
                dateIdea.imageUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),

            // Title and description
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateIdea.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(dateIdea.description, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.category,
                    'Category',
                    dateIdea.category.toString().split('.').last,
                  ),
                  _buildInfoRow(
                    Icons.mood,
                    'Mood',
                    dateIdea.mood.toString().split('.').last,
                  ),
                  _buildInfoRow(
                    Icons.attach_money,
                    'Average Cost',
                    '\$${dateIdea.averageCost.toStringAsFixed(0)}',
                  ),
                  SizedBox(height: 24),
                  _buildSection(
                    'Conversation Topics',
                    dateIdea.conversationTopics,
                  ),
                  SizedBox(height: 16),
                  _buildSection('Preparation Tips', dateIdea.prepTips),
                  SizedBox(height: 16),
                  if (dateIdea.locationDetails.isNotEmpty)
                    _buildSection('Location Details', dateIdea.locationDetails),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // Navigate to create date offer screen with this idea
            Navigator.pushNamed(
              context,
              '/create_date_offer',
              arguments: dateIdea,
            );
          },
          child: Text('Create Date Offer'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!authService.isPremium)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.pushNamed(context, '/premium');
                },
                icon: const Icon(Icons.star),
                label: const Text('Unlock Premium'),
                backgroundColor: Colors.amber,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(item, style: TextStyle(fontSize: 16))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
