import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: Markdown(
        data: _termsAndConditionsText,
        styleSheet: MarkdownStyleSheet(
          h1: Theme.of(context).textTheme.headlineLarge,
          h2: Theme.of(context).textTheme.headlineSmall,
          p: Theme.of(context).textTheme.bodyLarge,
          listBullet: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

const _termsAndConditionsText = '''
# Terms and Conditions

Last updated: [Date]

## 1. Agreement to Terms

By accessing and using Fix It Now, you agree to be bound by these Terms and Conditions.

## 2. Service Description

Fix It Now is a platform connecting service providers with customers seeking home services.

### 2.1 Platform Services
- Service booking
- Provider discovery
- Payment processing
- Communication tools
- Review system

## 3. User Accounts

### 3.1 Account Creation
- Must be 18 years or older
- Provide accurate information
- Maintain account security
- One account per user

### 3.2 Account Responsibilities
- Maintain accurate information
- Keep credentials secure
- Report unauthorized access
- Comply with platform rules

## 4. Service Bookings

### 4.1 Booking Process
- Select service provider
- Schedule appointment
- Provide service location
- Make payment
- Receive confirmation

### 4.2 Cancellations
- 24-hour notice required
- Cancellation fees may apply
- Provider no-show policy
- Refund procedures

## 5. Payments

### 5.1 Payment Terms
- Secure payment processing
- Accepted payment methods
- Service fees
- Refund policy

### 5.2 Pricing
- Set by service providers
- Platform fees
- Tax obligations
- Payment disputes

## 6. User Conduct

Users must:
- Provide accurate information
- Treat others with respect
- Follow platform guidelines
- Report violations
- Maintain professional conduct

## 7. Provider Standards

Providers must:
- Maintain required licenses
- Carry insurance
- Arrive on time
- Provide quality service
- Follow safety protocols

## 8. Reviews and Ratings

### 8.1 Review Guidelines
- Honest feedback
- No harassment
- No false information
- No competitor reviews

### 8.2 Provider Response
- Professional responses
- Timely addressing of issues
- No retaliation
- Dispute resolution

## 9. Liability

### 9.1 Platform Liability
- Service quality
- Provider conduct
- User interactions
- Data security

### 9.2 Limitation of Liability
- Direct damages
- Indirect damages
- Service interruptions
- Force majeure

## 10. Intellectual Property

### 10.1 Platform Content
- Copyright protection
- Trademark rights
- User-generated content
- License terms

### 10.2 User Content
- Content ownership
- Platform license
- Content removal
- Copyright claims

## 11. Privacy

User privacy is governed by our Privacy Policy, which is incorporated into these Terms.

## 12. Termination

### 12.1 Account Termination
- User-initiated
- Platform-initiated
- Termination effects
- Data retention

### 12.2 Termination Reasons
- Terms violation
- Illegal activity
- Platform abuse
- Payment issues

## 13. Changes to Terms

We reserve the right to modify these terms with notice to users.

## 14. Contact Information

For questions about these Terms, contact us at:
[Contact Information]

## 15. Governing Law

These Terms are governed by [Jurisdiction] law.
''';
