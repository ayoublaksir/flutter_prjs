import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/provider/service_management_controller.dart';
import '../../routes.dart';
import '../../models/service_models.dart';
import '../../screens/provider/add_service_form.dart';
import '../../widgets/common/index.dart';

class ServiceManagementScreen extends StatelessWidget {
  const ServiceManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(ServiceManagementController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Get.toNamed(AppRoutes.serviceCategoriesSelection),
          ),
        ],
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : controller.services.isEmpty
                ? _buildEmptyServices(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.services.length,
                    itemBuilder: (context, index) {
                      final service = controller.services[index];
                      return Card(
                        child: ListTile(
                          title: Text(service.name),
                          subtitle: Text(
                            'Price: \$${service.price.toStringAsFixed(2)}',
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editService(context, service);
                              } else if (value == 'delete') {
                                _deleteService(context, controller, service.id);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddServiceDialog(context, controller),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyServices(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Services Added',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first service to start receiving bookings',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _addService(context),
            child: const Text('Add Service'),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog(
    BuildContext context, 
    ServiceManagementController controller
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddServiceFormScreen()),
    ).then((result) {
      if (result == true) {
        controller.loadMockServices();
      }
    });
  }

  void _addService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddServiceFormScreen()),
    );
  }

  void _editService(BuildContext context, ProviderService service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServiceFormScreen(service: service),
      ),
    );
  }

  Future<void> _deleteService(
    BuildContext context, 
    ServiceManagementController controller, 
    String serviceId
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text(
          'Are you sure you want to delete this service? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      controller.deleteService(serviceId);
    }
  }
}