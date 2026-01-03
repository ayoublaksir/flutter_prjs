import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../services/storage_services.dart';

class PortfolioManagementScreen extends StatefulWidget {
  const PortfolioManagementScreen({Key? key}) : super(key: key);

  @override
  State<PortfolioManagementScreen> createState() =>
      _PortfolioManagementScreenState();
}

class _PortfolioManagementScreenState extends State<PortfolioManagementScreen> {
  final UserAPI _userAPI = UserAPI();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  List<WorkItem> _portfolio = [];

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final provider = await _userAPI.getProviderProfile(user.uid);
        if (provider != null) {
          setState(() {
            _portfolio =
                provider.workGallery
                    .map((url) => WorkItem(imageUrl: url))
                    .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading portfolio: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addWorkItem() async {
    final images = await _imagePicker.pickMultiImage();
    if (images == null || images.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        for (final image in images) {
          final url = await _storageService.uploadPortfolioImage(
            user.uid,
            image,
          );
          setState(() {
            _portfolio.add(WorkItem(imageUrl: url));
          });
        }

        // Update provider profile with new gallery
        await _userAPI.updateProviderProfile(
          (await _userAPI.getProviderProfile(user.uid))!.copyWith(
            workGallery: _portfolio.map((item) => item.imageUrl).toList(),
          ),
        );
      }
    } catch (e) {
      print('Error adding work items: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error adding images')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteWorkItem(int index) async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final url = _portfolio[index].imageUrl;
        await _storageService.deletePortfolioImage(url);

        setState(() {
          _portfolio.removeAt(index);
        });

        // Update provider profile
        await _userAPI.updateProviderProfile(
          (await _userAPI.getProviderProfile(user.uid))!.copyWith(
            workGallery: _portfolio.map((item) => item.imageUrl).toList(),
          ),
        );
      }
    } catch (e) {
      print('Error deleting work item: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error deleting image')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio Management')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Showcase your best work',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child:
                        _portfolio.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.photo_library_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('No portfolio items yet'),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _addWorkItem,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Work'),
                                  ),
                                ],
                              ),
                            )
                            : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount: _portfolio.length,
                              itemBuilder: (context, index) {
                                return _buildPortfolioItem(index);
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton:
          _portfolio.isNotEmpty
              ? FloatingActionButton(
                onPressed: _addWorkItem,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildPortfolioItem(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Image.network(_portfolio[index].imageUrl, fit: BoxFit.cover),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.white,
            onPressed: () => _deleteWorkItem(index),
          ),
        ),
      ],
    );
  }
}

class WorkItem {
  final String imageUrl;
  final String? description;

  WorkItem({required this.imageUrl, this.description});
}
