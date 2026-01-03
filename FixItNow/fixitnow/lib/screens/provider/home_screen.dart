import 'package:flutter/material.dart';
import '../../screens/provider/dashboard_screen.dart';
import '../../screens/provider/booking_requests_screen.dart';
import '../../screens/provider/service_management_screen.dart';
import '../../screens/provider/profile_screen.dart';
import '../../services/api_services.dart';
import '../../services/auth_services.dart';
import '../../models/booking_models.dart';
import '../../models/user_models.dart';
import '../../routes.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({Key? key}) : super(key: key);

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final UserAPI _userAPI = UserAPI();
  final BookingAPI _bookingAPI = BookingAPI();

  bool _isLoading = true;
  ServiceProvider? _profile;
  List<Booking> _upcomingBookings = [];
  Map<String, dynamic> _stats = {
    'totalEarnings': 0.0,
    'completedJobs': 0,
    'rating': 0.0,
    'activeBookings': 0,
  };

  // List of screens to display
  final List<Widget> _screens = [
    const ProviderDashboardScreen(),
    const BookingRequestsScreen(),
    const ServiceManagementScreen(),
    const ProviderProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Load data in parallel
        final results = await Future.wait([
          _userAPI.getProviderProfile(user.uid),
          _bookingAPI.getProviderBookings(user.uid, status: 'confirmed'),
          _loadProviderStats(user.uid),
        ]);

        setState(() {
          _profile = results[0] as ServiceProvider?;
          _upcomingBookings = results[1] as List<Booking>;
          _stats = results[2] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading provider data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _loadProviderStats(String providerId) async {
    // TODO: Implement stats calculation from Firebase
    return {
      'totalEarnings': 1250.00,
      'completedJobs': 25,
      'rating': 4.8,
      'activeBookings': 3,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_repair_service),
            label: 'Services',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
