import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/responsive/responsive_util.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
              'Terms of Service for BeautyGlow',
              'Last updated: ${DateTime.now().toLocal().toString().split(' ')[0]}',
              isHeader: true,
            ),
            _buildSection(
              '1. Acceptance of Terms',
              '''By downloading, installing, or using the BeautyGlow mobile application, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our app.

These terms constitute a legally binding agreement between you and BeautyGlow regarding your use of the application.''',
            ),
            _buildSection(
              '2. Description of Service',
              '''BeautyGlow is a free mobile application that provides:

• Personal beauty and skincare routine tracking
• Educational beauty tips and content library
• Product collection management for items you own or want to try
• Profile management and routine completion tracking
• Local notifications and reminders for your beauty routines
• Achievement system to track your progress

All features are available offline and your data is stored locally on your device.''',
            ),
            _buildSection(
              '3. Eligibility and Account',
              '''To use BeautyGlow:

• You must be at least 13 years of age
• No account creation is required
• All data is managed locally on your device
• You are responsible for the security of your device
• Comply with all applicable laws and regulations''',
            ),
            _buildSection(
              '4. User Content and Data',
              '''Regarding your personal data in BeautyGlow:

• You retain full ownership of all data you create
• Your routines, products, and profile information belong to you
• Data is stored locally and never transmitted to external servers
• You can modify or delete your information at any time
• No backup or sync services are provided by the app''',
            ),
            _buildSection(
              '5. Permitted Use',
              '''You may use BeautyGlow to:

• Create and track personal beauty routines
• Add products to your personal collection
• Set reminders for skincare activities
• Access educational beauty content
• Monitor your routine completion progress
• Use all features for personal, non-commercial purposes''',
            ),
            _buildSection(
              '6. Prohibited Activities',
              '''You may not:

• Attempt to reverse engineer or modify the application
• Use the app for any illegal or unauthorized purpose
• Share or distribute the app outside official app stores
• Attempt to access non-public areas of the application
• Use the app in a way that could harm its functionality''',
            ),
            _buildSection(
              '7. Health and Beauty Disclaimers',
              '''IMPORTANT HEALTH NOTICE:

• BeautyGlow provides general beauty and skincare information for educational purposes only
• Content is not a substitute for professional medical or dermatological advice
• Always consult healthcare professionals for skin conditions, allergies, or concerns
• We are not responsible for adverse reactions to products or routines you choose to follow
• Individual results may vary based on skin type and personal factors
• Discontinue use of any product that causes irritation or adverse reactions
• The app does not diagnose, treat, or cure any medical conditions''',
            ),
            _buildSection(
              '8. No Purchases or Payments',
              '''BeautyGlow is completely free:

• No in-app purchases or subscriptions
• No payment processing or billing
• No premium features requiring payment
• All functionality is available to all users
• No advertising or monetization features''',
            ),
            _buildSection(
              '9. Privacy and Data Protection',
              '''Your privacy is our priority:

• Please review our Privacy Policy for detailed information
• All data is stored locally on your device
• No data collection or transmission to external servers
• You have complete control over your personal information''',
            ),
            _buildSection(
              '10. App Updates and Changes',
              '''We may update BeautyGlow to:

• Add new features or beauty content
• Improve app performance and user experience
• Fix bugs or technical issues
• Ensure compatibility with new device versions
• Updates are provided free through app stores''',
            ),
            _buildSection(
              '11. Limitation of Liability',
              '''BeautyGlow is provided "as is" without warranties:

• We do not guarantee uninterrupted or error-free operation
• We are not liable for any data loss (back up your device regularly)
• We are not responsible for skin reactions or beauty routine outcomes
• Our liability is limited to the maximum extent permitted by law
• Use the app at your own risk and discretion''',
            ),
            _buildSection(
              '12. Termination',
              '''These terms remain in effect until:

• You uninstall the application from your device
• We discontinue the BeautyGlow service
• You violate these terms (though we prefer to resolve issues amicably)
• Upon termination, all your local data will be removed with the app''',
            ),
            _buildSection(
              '13. Updates to Terms',
              '''We may update these terms periodically:

• Material changes will be communicated through the app
• Continued use after changes constitutes acceptance
• You should review terms regularly for updates
• Previous versions are available upon request''',
            ),
            _buildSection(
              '14. Contact Information',
              '''For questions about these Terms of Service:

Email: support@beautyglow.app
Subject: Terms of Service Inquiry

We are committed to resolving any concerns promptly and fairly.''',
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
                  'I Accept',
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
