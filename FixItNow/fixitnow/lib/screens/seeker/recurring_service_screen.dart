import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/service_models.dart';
import '../../routes.dart';
import 'package:intl/intl.dart';

class RecurringServicesScreen extends StatefulWidget {
  const RecurringServicesScreen({Key? key}) : super(key: key);

  @override
  State<RecurringServicesScreen> createState() =>
      _RecurringServicesScreenState();
}

class _RecurringServicesScreenState extends State<RecurringServicesScreen> {
  final ServiceAPI _serviceAPI = ServiceAPI();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  List<RecurringService> _recurringServices = [];

  @override
  void initState() {
    super.initState();
    _loadRecurringServices();
  }

  Future<void> _loadRecurringServices() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final services = await _serviceAPI.getRecurringServices(user.uid);
        setState(() => _recurringServices = services);
      }
    } catch (e) {
      print('Error loading recurring services: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading recurring services')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelRecurringService(String serviceId) async {
    try {
      await _serviceAPI.cancelRecurringService(serviceId);
      setState(() {
        _recurringServices.removeWhere((service) => service.id == serviceId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recurring service cancelled successfully'),
        ),
      );
    } catch (e) {
      print('Error cancelling recurring service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error cancelling recurring service')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Services')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _recurringServices.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.repeat, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No recurring services',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up recurring services for regular maintenance',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.search);
                      },
                      child: const Text('Browse Services'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _recurringServices.length,
                itemBuilder: (context, index) {
                  final service = _recurringServices[index];
                  return Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                service.provider.profileImage != null
                                    ? NetworkImage(
                                      service.provider.profileImage!,
                                    )
                                    : null,
                            child:
                                service.provider.profileImage == null
                                    ? const Icon(Icons.person)
                                    : null,
                          ),
                          title: Text(service.serviceName),
                          subtitle: Text(service.provider.businessName),
                          trailing: _buildStatusChip(service.status),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                'Frequency',
                                _getFrequencyText(service.frequency),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Next Service',
                                DateFormat(
                                  'MMM d, y',
                                ).format(service.nextServiceDate),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Price',
                                '\$${service.price.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ),
                        ButtonBar(
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.bookingHistory,
                                  arguments: {'serviceId': service.id},
                                );
                              },
                              child: const Text('View History'),
                            ),
                            TextButton(
                              onPressed: () {
                                // Show reschedule dialog
                              },
                              child: const Text('Reschedule'),
                            ),
                            TextButton(
                              onPressed:
                                  () => showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text(
                                            'Cancel Recurring Service',
                                          ),
                                          content: const Text(
                                            'Are you sure you want to cancel this recurring service?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: const Text('No'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _cancelRecurringService(
                                                  service.id,
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text('Yes, Cancel'),
                                            ),
                                          ],
                                        ),
                                  ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Active';
        break;
      case 'paused':
        color = Colors.orange;
        label = 'Paused';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'weekly':
        return 'Every week';
      case 'biweekly':
        return 'Every 2 weeks';
      case 'monthly':
        return 'Every month';
      case 'quarterly':
        return 'Every 3 months';
      default:
        return frequency;
    }
  }
}
