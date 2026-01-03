import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/responsive/responsive_util.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.primaryPink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          ResponsiveUtil.instance.proportionateWidth(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Privacy Policy for BeautyGlow',
              'Last updated: ${DateTime.now().toLocal().toString().split(' ')[0]}',
              isHeader: true,
            ),
            _buildSection(
              '1. Information We Collect',
              '''BeautyGlow stores all your data locally on your device. We collect and store:

• Personal Information: Your name and profile details (stored locally only)
• Beauty Routines: Your skincare and beauty routines you create and track
• Product Information: Beauty products you add to your personal collection
• Usage Preferences: App settings and notification preferences
• Completion History: Records of completed routines and achievements

All this information remains on your device and is never transmitted to external servers.''',
            ),
            _buildSection(
              '2. How We Use Your Information',
              '''Your locally stored information is used to:

• Provide personalized beauty routine tracking
• Display your beauty tips and educational content
• Manage your product collection and wishlist
• Track your routine completion progress
• Send local notifications and reminders
• Maintain your achievements and statistics

No data is shared with third parties or external services.''',
            ),
            _buildSection(
              '3. Data Storage and Security',
              '''• All personal data is stored locally on your device using secure encrypted storage
• No data is transmitted to external servers or cloud services
• Your information is only accessible through the BeautyGlow app on your device
• If you uninstall the app, all your data is permanently removed
• No backup or sync services are used''',
            ),
            _buildSection(
              '4. Third-Party Services',
              '''BeautyGlow uses minimal third-party services:

• Local Notifications: For beauty routine reminders (no data transmitted)
• Device Storage: For secure local data storage
• No analytics services, advertising networks, or cloud services are used
• No user data is shared with any third-party services''',
            ),
            _buildSection(
              '5. Advertising',
              '''BeautyGlow does not display advertisements or use advertising networks. The app is completely ad-free and focused solely on helping you track your beauty routines.''',
            ),
            _buildSection(
              '6. Children\'s Privacy',
              '''BeautyGlow is suitable for users aged 13 and above. We do not knowingly collect personal information from children under 13. Since all data is stored locally, parents can monitor their child\'s use of the app directly on the device.''',
            ),
            _buildSection(
              '7. Your Privacy Rights',
              '''You have complete control over your data:

• Access all your data through the app interface
• Edit or delete any information at any time
• Export your routine data through the app
• Completely remove all data by uninstalling the app
• No external requests or procedures needed for data management''',
            ),
            _buildSection(
              '8. Data Retention',
              '''• Data is retained locally as long as the app is installed
• You can manually delete specific routines, products, or profile information
• Complete data removal occurs when you uninstall the app
• No data recovery is possible after uninstallation
• No external backups are created''',
            ),
            _buildSection(
              '9. Data Sharing',
              '''BeautyGlow does not share your data with anyone:

• No data transmission to external servers
• No analytics or tracking services
• No social media integration
• No email or messaging services
• Your beauty routine information remains completely private''',
            ),
            _buildSection(
              '10. Changes to Privacy Policy',
              '''Updates to this privacy policy will be communicated through:

• In-app notifications
• App store update notes

Your continued use of the app after changes constitutes acceptance of the updated policy.''',
            ),
            _buildSection(
              '11. Contact Information',
              '''For privacy-related questions contact us at:

Email: privacy@beautyglow.app
Subject: BeautyGlow Privacy Inquiry

Since all data is stored locally, most privacy concerns can be resolved by managing your data directly through the app settings.''',
            ),
            _buildSection(
              '12. Compliance',
              '''This privacy policy complies with:

• Google Play Developer Policy
• General Data Protection Regulation (GDPR)
• California Consumer Privacy Act (CCPA)
• Children\'s Online Privacy Protection Act (COPPA)
• Local data protection regulations''',
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'I Understand',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtil.instance.proportionateHeight(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: isHeader
                ? AppTypography.headingMedium.copyWith(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.bold,
                  )
                : AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
          ),
          SizedBox(
            height: ResponsiveUtil.instance.proportionateHeight(8),
          ),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
