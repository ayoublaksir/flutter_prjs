import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../models/service_models.dart';
import '../../routes.dart';

class ServiceCategoriesSelectionScreen extends StatefulWidget {
  const ServiceCategoriesSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ServiceCategoriesSelectionScreen> createState() =>
      _ServiceCategoriesSelectionScreenState();
}

class _ServiceCategoriesSelectionScreenState
    extends State<ServiceCategoriesSelectionScreen> {
  final ServiceAPI _serviceAPI = ServiceAPI();
  bool _isLoading = true;
  List<ServiceCategory> _categories = [];
  Set<String> _selectedCategories = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _serviceAPI.getServiceCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Services')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        if (_searchQuery.isNotEmpty &&
                            !category.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            )) {
                          return const SizedBox.shrink();
                        }
                        return CheckboxListTile(
                          title: Text(category.name),
                          subtitle: Text(category.description),
                          value: _selectedCategories.contains(category.id),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedCategories.add(category.id);
                              } else {
                                _selectedCategories.remove(category.id);
                              }
                            });
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed:
              _selectedCategories.isEmpty
                  ? null
                  : () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.professionalDetails,
                      arguments: {
                        'selectedCategories': _selectedCategories.toList(),
                      },
                    );
                  },
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
