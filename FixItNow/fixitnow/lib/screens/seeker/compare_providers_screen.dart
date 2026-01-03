import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../models/user_models.dart';
import '../../models/review_models.dart';
import '../../routes.dart';

class CompareProvidersScreen extends StatefulWidget {
  final List<String> providerIds;

  const CompareProvidersScreen({Key? key, required this.providerIds})
    : super(key: key);

  @override
  State<CompareProvidersScreen> createState() => _CompareProvidersScreenState();
}

class _CompareProvidersScreenState extends State<CompareProvidersScreen> {
  final UserAPI _userAPI = UserAPI();
  final ReviewAPI _reviewAPI = ReviewAPI();

  bool _isLoading = true;
  List<ServiceProvider> _providers = [];
  Map<String, List<Review>> _providerReviews = {};

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    setState(() => _isLoading = true);

    try {
      // Load providers and their reviews in parallel
      final futures = widget.providerIds.map((id) async {
        final provider = await _userAPI.getProviderProfile(id);
        final reviews = await _reviewAPI.getProviderReviews(id);
        return [provider, reviews];
      });

      final results = await Future.wait(futures);

      setState(() {
        _providers = results.map((r) => r[0] as ServiceProvider).toList();
        _providerReviews = {
          for (var i = 0; i < results.length; i++)
            widget.providerIds[i]: results[i][1] as List<Review>,
        };
      });
    } catch (e) {
      print('Error loading provider data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading provider data')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compare Providers')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Comparison')),
                    DataColumn(label: Text('Provider 1')),
                    DataColumn(label: Text('Provider 2')),
                  ],
                  rows: [
                    // Basic Information
                    DataRow(
                      cells: [
                        const DataCell(Text('Business Name')),
                        ..._providers.map(
                          (p) => DataCell(Text(p.businessName)),
                        ),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('Rating')),
                        ..._providers.map(
                          (p) => DataCell(
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Text(' ${p.rating.toStringAsFixed(1)}'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('Reviews')),
                        ..._providers.map(
                          (p) => DataCell(Text(p.reviewCount.toString())),
                        ),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('Experience')),
                        ..._providers.map(
                          (p) => DataCell(Text('${p.yearsOfExperience} years')),
                        ),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('Response Time')),
                        ..._providers.map(
                          (p) => DataCell(Text(p.averageResponseTime)),
                        ),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('Completion Rate')),
                        ..._providers.map(
                          (p) => DataCell(
                            Text(
                              '${(p.completionRate * 100).toStringAsFixed(1)}%',
                            ),
                          ),
                        ),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('Services Offered')),
                        ..._providers.map(
                          (p) => DataCell(Text(p.serviceCount.toString())),
                        ),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('Verified')),
                        ..._providers.map(
                          (p) => DataCell(
                            Icon(
                              p.isVerified ? Icons.check_circle : Icons.cancel,
                              color: p.isVerified ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children:
              _providers.map((provider) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.providerProfile,
                          arguments: {'providerId': provider.id},
                        );
                      },
                      child: const Text('View Profile'),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
