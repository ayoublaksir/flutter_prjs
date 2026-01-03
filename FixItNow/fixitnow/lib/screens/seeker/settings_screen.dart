import 'package:flutter/material.dart';
import '../../services/auth_services.dart';
import '../../services/api_services.dart';
import '../../models/user_models.dart';
import '../../routes.dart';

class SeekerSettingsScreen extends StatefulWidget {
  const SeekerSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SeekerSettingsScreen> createState() => _SeekerSettingsScreenState();
}

class _SeekerSettingsScreenState extends State<SeekerSettingsScreen> {
  final AuthService _authService = AuthService();
  final UserAPI _userAPI = UserAPI();

  bool _isLoading = true;
  ServiceSeeker? _profile;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'system';
  bool _locationServices = true;
  bool _savePaymentInfo = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final profile = await _userAPI.getSeekerProfile(user.uid);
        if (profile != null) {
          setState(() {
            _profile = profile;
            _pushNotifications = profile.settings.pushNotifications;
            _emailNotifications = profile.settings.emailNotifications;
            _smsNotifications = profile.settings.smsNotifications;
            _selectedLanguage = profile.settings.language;
            _selectedTheme = profile.settings.theme;
            _locationServices = profile.settings.locationServices;
            _savePaymentInfo = profile.settings.savePaymentInfo;
          });
        }
      }
    } catch (e) {
      print('Error loading settings: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading settings')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings() async {
    setState(() => _isLoading = true);

    try {
      if (_profile != null) {
        final updatedSettings = UserSettings(
          pushNotifications: _pushNotifications,
          emailNotifications: _emailNotifications,
          smsNotifications: _smsNotifications,
          language: _selectedLanguage,
          theme: _selectedTheme,
          locationServices: _locationServices,
          savePaymentInfo: _savePaymentInfo,
        );

        await _userAPI.updateSeekerSettings(_profile!.id, updatedSettings);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully')),
        );
      }
    } catch (e) {
      print('Error updating settings: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error updating settings')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _authService.signOut();
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Notifications Section
                  _buildSectionHeader('Notifications'),
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive push notifications'),
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() => _pushNotifications = value);
                      _updateSettings();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Email Notifications'),
                    subtitle: const Text('Receive email updates'),
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() => _emailNotifications = value);
                      _updateSettings();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('SMS Notifications'),
                    subtitle: const Text('Receive SMS alerts'),
                    value: _smsNotifications,
                    onChanged: (value) {
                      setState(() => _smsNotifications = value);
                      _updateSettings();
                    },
                  ),
                  const Divider(),

                  // Preferences Section
                  _buildSectionHeader('Preferences'),
                  ListTile(
                    title: const Text('Language'),
                    subtitle: Text(_selectedLanguage),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showLanguageDialog,
                  ),
                  ListTile(
                    title: const Text('Theme'),
                    subtitle: Text(_selectedTheme.capitalize()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showThemeDialog,
                  ),
                  const Divider(),

                  // Privacy Section
                  _buildSectionHeader('Privacy'),
                  SwitchListTile(
                    title: const Text('Location Services'),
                    subtitle: const Text('Allow location access'),
                    value: _locationServices,
                    onChanged: (value) {
                      setState(() => _locationServices = value);
                      _updateSettings();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Save Payment Info'),
                    subtitle: const Text('Securely save payment methods'),
                    value: _savePaymentInfo,
                    onChanged: (value) {
                      setState(() => _savePaymentInfo = value);
                      _updateSettings();
                    },
                  ),
                  const Divider(),

                  // Account Section
                  _buildSectionHeader('Account'),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Change Password'),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.changePassword);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.helpSupport);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Terms & Conditions'),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.termsConditions);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                    },
                  ),
                  const Divider(),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _showLanguageDialog() async {
    final languages = ['English', 'Spanish', 'French', 'German', 'Chinese'];
    final selected = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Select Language'),
            children:
                languages
                    .map(
                      (lang) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, lang),
                        child: Text(lang),
                      ),
                    )
                    .toList(),
          ),
    );

    if (selected != null) {
      setState(() => _selectedLanguage = selected);
      _updateSettings();
    }
  }

  Future<void> _showThemeDialog() async {
    final themes = ['system', 'light', 'dark'];
    final selected = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Select Theme'),
            children:
                themes
                    .map(
                      (theme) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, theme),
                        child: Text(theme.capitalize()),
                      ),
                    )
                    .toList(),
          ),
    );

    if (selected != null) {
      setState(() => _selectedTheme = selected);
      _updateSettings();
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
