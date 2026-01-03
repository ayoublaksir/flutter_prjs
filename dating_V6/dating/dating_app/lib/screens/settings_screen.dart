import 'package:flutter/material.dart';
import '../widgets/modern_app_bar.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/purchase_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final PurchaseService _purchaseService = PurchaseService();
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _currentTheme = 'System';
  String _currentLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load user settings from preferences or database
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(title: 'Settings', showNotifications: false),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  _buildSection(
                    title: 'Account',
                    children: [
                      _buildSettingTile(
                        title: 'Edit Profile',
                        icon: Icons.person,
                        onTap:
                            () => Navigator.pushNamed(context, '/edit_profile'),
                      ),
                      _buildSettingTile(
                        title: 'Subscription',
                        icon: Icons.card_membership,
                        onTap:
                            () => Navigator.pushNamed(context, '/subscription'),
                      ),
                      _buildSettingTile(
                        title: 'Privacy',
                        icon: Icons.lock,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              '/privacy_settings',
                            ),
                      ),
                    ],
                  ),
                  // More settings sections...
                ],
              ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // Rest of your implementation...
}
