import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: Markdown(
        data: _privacyPolicyText,
        styleSheet: MarkdownStyleSheet(
          h1: Theme.of(context).textTheme.headlineLarge,
          h2: Theme.of(context).textTheme.headlineSmall,
          p: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

const _privacyPolicyText = '''
# Privacy Policy

Last updated: [Date]

## 1. Introduction

Welcome to Fix It Now. We respect your privacy and are committed to protecting your personal data.

## 2. Information We Collect

### 2.1 Personal Information
- Name and contact details
- Location data
- Payment information
- Service history
- Device information

### 2.2 Usage Data
- App interaction
- Service preferences
- Communication records

## 3. How We Use Your Information

- To provide our services
- To process payments
- To improve our platform
- To communicate with you
- To ensure platform safety

## 4. Data Security

We implement appropriate security measures to protect your personal information.

## 5. Your Rights

You have the right to:
- Access your data
- Correct your data
- Delete your data
- Object to processing
- Data portability

## 6. Contact Us

For any privacy-related questions, please contact us at:
[Contact Information]
''';
