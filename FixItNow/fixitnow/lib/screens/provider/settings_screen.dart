import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/provider/settings_controller.dart';
import '../../routes.dart';

class ProviderSettingsScreen extends StatelessWidget {
  const ProviderSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(SettingsController());

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Obx(
        () =>
            controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Section
                      _buildSectionHeader(context, 'Account'),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.access_time),
                              title: const Text('Availability Settings'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap:
                                  () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.availabilitySettings,
                                  ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.payment),
                              title: const Text('Payment Settings'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap:
                                  () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.paymentSettings,
                                  ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.credit_card),
                              title: const Text('Credits Management'),
                              subtitle: const Text(
                                'Manage your service credits',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap:
                                  () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.providerCredits,
                                  ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.notifications),
                              title: const Text('Notification Settings'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap:
                                  () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.notificationSettings,
                                  ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: const Text('Profile Settings'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap:
                                  () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.profileSettings,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Notifications Section
                      _buildSectionHeader(context, 'Notifications'),
                      Card(
                        child: Column(
                          children: [
                            Obx(
                              () => SwitchListTile(
                                title: const Text('Push Notifications'),
                                subtitle: const Text(
                                  'Receive push notifications',
                                ),
                                value: controller.pushNotifications.value,
                                onChanged: (value) {
                                  controller.pushNotifications.value = value;
                                  controller.updateSettings();
                                },
                              ),
                            ),
                            Obx(
                              () => SwitchListTile(
                                title: const Text('Email Notifications'),
                                subtitle: const Text('Receive email updates'),
                                value: controller.emailNotifications.value,
                                onChanged: (value) {
                                  controller.emailNotifications.value = value;
                                  controller.updateSettings();
                                },
                              ),
                            ),
                            Obx(
                              () => SwitchListTile(
                                title: const Text('SMS Notifications'),
                                subtitle: const Text('Receive SMS alerts'),
                                value: controller.smsNotifications.value,
                                onChanged: (value) {
                                  controller.smsNotifications.value = value;
                                  controller.updateSettings();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Appearance Section
                      _buildSectionHeader(context, 'Appearance'),
                      Card(
                        child: Column(
                          children: [
                            Obx(
                              () => ListTile(
                                title: const Text('Language'),
                                subtitle: Text(
                                  controller.selectedLanguage.value,
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap:
                                    () => _showLanguageDialog(
                                      context,
                                      controller,
                                    ),
                              ),
                            ),
                            Obx(
                              () => ListTile(
                                title: const Text('Theme'),
                                subtitle: Text(
                                  controller.capitalize(
                                    controller.selectedTheme.value,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap:
                                    () => _showThemeDialog(context, controller),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Support Section
                      _buildSectionHeader(context, 'Support'),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.help),
                              title: const Text('Help Center'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.helpSupport,
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.description),
                              title: const Text('Terms & Conditions'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.termsConditions,
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.privacy_tip),
                              title: const Text('Privacy Policy'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // Navigate to privacy policy
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign Out Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _signOut(context, controller),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    SettingsController controller,
  ) async {
    final languages = ['English', 'Spanish', 'French', 'German'];
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
      controller.selectedLanguage.value = selected;
      controller.updateSettings();
    }
  }

  Future<void> _showThemeDialog(
    BuildContext context,
    SettingsController controller,
  ) async {
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
                        child: Text(controller.capitalize(theme)),
                      ),
                    )
                    .toList(),
          ),
    );

    if (selected != null) {
      controller.selectedTheme.value = selected;
      controller.updateSettings();
    }
  }

  Future<void> _signOut(
    BuildContext context,
    SettingsController controller,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await controller.signOut();
      if (success && context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.welcome,
          (route) => false,
        );
      }
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
