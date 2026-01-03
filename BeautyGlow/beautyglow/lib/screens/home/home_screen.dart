import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/navigation/nav_items.dart';
import '../../widgets/navigation/custom_bottom_nav.dart';
import '../../data/storage_service.dart';
import 'widgets/home_dashboard.dart';
import '../routines/routine_screen.dart';
import '../products/products_screen.dart';
import '../tips/tips_screen.dart';
import '../profile/profile_screen.dart';

/// Main home screen with bottom navigation
class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const HomeDashboard(),
    const RoutineScreen(),
    const ProductsScreen(),
    const TipsScreen(),
    const ProfileScreen(),
  ];

  void _onNavigationChanged(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavigationChanged,
        items: AppNavItems.items,
      ),
    );
  }
}
