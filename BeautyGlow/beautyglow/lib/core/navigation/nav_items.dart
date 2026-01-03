import 'package:flutter/material.dart';

/// Navigation item model for bottom navigation
class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int index;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.index,
  });
}

/// Navigation items for the app
class AppNavItems {
  AppNavItems._();

  static const List<NavItem> items = [
    NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      index: 0,
    ),
    NavItem(
      label: 'Routines',
      icon: Icons.event_note_outlined,
      activeIcon: Icons.event_note_rounded,
      index: 1,
    ),
    NavItem(
      label: 'Products',
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag_rounded,
      index: 2,
    ),
    NavItem(
      label: 'Tips',
      icon: Icons.lightbulb_outline,
      activeIcon: Icons.lightbulb_rounded,
      index: 3,
    ),
    NavItem(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      index: 4,
    ),
  ];

  /// Get nav item by index
  static NavItem getItemByIndex(int index) {
    return items.firstWhere(
      (item) => item.index == index,
      orElse: () => items[0],
    );
  }

  /// Get total nav items count
  static int get itemCount => items.length;
}
