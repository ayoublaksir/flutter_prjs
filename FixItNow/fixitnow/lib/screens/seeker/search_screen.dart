import 'package:flutter/material.dart';
import '../../models/service_models.dart';
import '../../models/user_models.dart';
import '../../services/api_services.dart';
import '../../routes.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ServiceAPI _serviceAPI = ServiceAPI();

  bool _isLoading = false;
  List<ServiceCategory> _categories = [];
  List<ServiceProvider> _popularProviders = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load categories and popular providers
      setState(() {
        _categories = [];
        _popularProviders = [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading search data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    // Implement search functionality
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for services or providers',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                        : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _performSearch,
              onSubmitted: _performSearch,
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchQuery.isNotEmpty
              ? _buildSearchResults()
              : _buildInitialContent(),
    );
  }

  Widget _buildInitialContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _categories.isEmpty
              ? const Center(child: Text('No categories found'))
              : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryItem(_categories[index]);
                },
              ),

          const SizedBox(height: 24),

          const Text(
            'Popular Providers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _popularProviders.isEmpty
              ? const Center(child: Text('No popular providers found'))
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _popularProviders.length,
                itemBuilder: (context, index) {
                  return _buildProviderItem(_popularProviders[index]);
                },
              ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // Implement search results UI
    return const Center(child: Text('Search results will appear here'));
  }

  Widget _buildCategoryItem(ServiceCategory category) {
    return InkWell(
      onTap: () {
        // Navigate to category details
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.category, color: Colors.blue, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderItem(ServiceProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              provider.profileImage.isNotEmpty
                  ? NetworkImage(provider.profileImage)
                  : null,
          child:
              provider.profileImage.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(provider.name),
        subtitle: Text(provider.businessName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text('${provider.rating}'),
          ],
        ),
        onTap: () {
          // Navigate to provider details
        },
      ),
    );
  }
}
