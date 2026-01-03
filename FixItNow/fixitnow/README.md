# FixItNow

A comprehensive home services platform connecting service providers with customers who need their services.

## Project Description

FixItNow is a dual-purpose mobile application developed with Flutter, designed to seamlessly connect home service professionals with customers seeking reliable, local services. The platform enhances convenience, transparency, and efficiency on both ends of the home services spectrum.

1. **For Service Seekers (Customers)**
   - Discover and connect with local, verified service providers across various home service categories
   - Book services quickly with access to provider profiles, portfolios, and user reviews
   - Schedule one-time or recurring services with flexible booking options
   - Manage all service interactions, payment history, and upcoming appointments in one place
   - Rate and review providers to ensure quality and accountability

2. **For Service Providers (Professionals)**
   - Create and customize service listings with detailed descriptions, pricing, and media
   - Build a professional presence with a portfolio and customer ratings
   - Manage and accept booking requests, with calendar integration for easy scheduling
   - Track earnings, view analytics, and optimize performance
   - Define working hours and control availability

## Monetization Model (Credit-Based Access and Engagement)

FixItNow adopts a credit-based monetization model, inspired by inDrive, to ensure fairness and active engagement from service providers while maintaining a free and accessible platform for customers.

- **Free Browsing, Restricted Engagement**:
  Service providers can freely browse available customer requests that match their services (e.g., plumbing, electrical work, cleaning). However, they cannot place bids, make offers, or accept jobs unless they have sufficient credits in their account.

- **Purchasing Credits**:
  Providers can buy credit bundles through in-app purchases. Multiple pricing tiers are available to suit part-time freelancers or high-volume professionals.

- **Pay-per-Engagement Model**:
  When a provider sends an offer or responds to a customer request, a small number of credits may be held. Once the offer is accepted and confirmed by the customer, a credit deduction occurs based on the service type or value.

- **Encourages Qualified Participation**:
  This model prevents spam or low-effort bids by ensuring that only serious, credit-holding professionals can engage with customers. It rewards providers who actively manage and close jobs, aligning spending with business outcomes.

- **No Charges Without Value**:
  Providers are only charged credits once their offer is accepted, ensuring they only pay when there's a clear opportunity to earn.

This approach makes FixItNow both accessible and performance-based, allowing professionals to scale usage as their business grows, while ensuring high-quality interactions for customers.

## Implementation Status

The following features have been implemented:

1. **Credit-Based Monetization System**
   - ✅ Provider credit system model implementation
   - ✅ Credit bundles purchasing interface
   - ✅ Credit transactions and history tracking
   - ✅ Credit hold and release mechanism for booking acceptance
   - ✅ Warning system for providers with insufficient credits

2. **Assets and Media**
   - ✅ Assets directory structure configured
   - ✅ Environment variables configuration
   - ✅ Proper image compression utilities

3. **Utility Services**
   - ✅ Completed utility functions for date formatting, sharing, etc.
   - ✅ Completed realtime services for Firebase streams

4. **Documentation**
   - ✅ Detailed architecture documentation
   - ✅ Core features description

The following features still need implementation:

1. **Payment Integration**
   - ⚠️ Actual payment gateway integration for credit purchases
   - ⚠️ Receipt generation for transactions

2. **Testing**
   - ⚠️ Unit tests for credit system
   - ⚠️ Integration tests for booking workflows

3. **Cloud Functions**
   - ⚠️ Server-side functions for credit expiration
   - ⚠️ Automated credit holds and releases

## Project Architecture

### Technology Stack

- **Frontend:** Flutter/Dart
- **State Management:** GetX for dependency injection and navigation
- **Backend Services:** Firebase (Authentication, Firestore, Storage, Messaging)
- **Location Services:** Google Maps, Geolocator
- **Notifications:** Firebase Cloud Messaging, Local Notifications

### Project Structure

```
lib/
├── app.dart                  # Main application configuration
├── main.dart                 # Entry point
├── theme.dart                # App theming
├── routes.dart               # Application routes
├── firebase_options.dart     # Firebase configuration
├── bindings/                 # GetX dependency injection
├── controllers/              # Business logic
│   ├── base_controller.dart
│   ├── chat_controller.dart
│   ├── provider/            # Provider-specific controllers
│   └── seeker/              # Seeker-specific controllers
├── models/                   # Data models
│   ├── app_models.dart
│   ├── booking_models.dart
│   ├── chat_models.dart
│   ├── credit_models.dart    # Credit system models
│   ├── notification_models.dart
│   ├── payment_models.dart
│   ├── provider_models.dart
│   ├── review_models.dart
│   ├── service_models.dart
│   ├── support_models.dart
│   └── user_models.dart
├── screens/                  # UI screens
│   ├── auth_screens.dart
│   ├── welcome_screen.dart
│   ├── provider/            # Provider interfaces
│   └── seeker/              # Seeker interfaces
├── services/                 # Services layer
│   ├── api_services.dart
│   ├── auth_services.dart
│   ├── booking_services.dart
│   ├── credit_services.dart  # Credit management services
│   ├── firebase_service.dart
│   ├── location_services.dart
│   ├── notification_services.dart
│   ├── realtime_services.dart
│   ├── storage_services.dart
│   └── utility_services.dart
├── utils/                    # Utility functions and helpers
└── widgets/                  # Reusable UI components
```

### Architectural Design

The application follows a clean architecture with clear separation of concerns:

1. **Models Layer** - Data structure definitions representing business entities
2. **Controllers Layer** - Business logic handling with GetX controllers
3. **Services Layer** - API interactions and data processing
4. **UI Layer** - User interface components organized by user role
5. **Bindings** - Dependency injection for controllers and services

## Core Features

### Authentication & Onboarding
- User registration and login
- Role selection (Service Provider or Service Seeker)
- Location permissions handling

### Service Seeker Features
- Home dashboard with service categories
- Provider discovery and search
- Booking management
- Payment methods
- Notifications
- Saved services and favorites
- Service history and recurring services
- Reviews and ratings
- Profile management

### Service Provider Features
- Professional dashboard with analytics
- Service and portfolio management
- Booking requests handling
- Schedule management
- Earnings tracking
- Availability settings
- Payment settings
- Professional profile management
- Credit management system

### Common Features
- Chat functionality
- Real-time notifications
- Location-based services
- Reviews and ratings system
- Settings management

## Getting Started

### Prerequisites
- Flutter SDK (>= 3.7.0)
- Firebase project setup
- Google Maps API key

### Installation

1. Clone the repository
   ```
   git clone https://github.com/yourusername/fixitnow.git
   ```

2. Navigate to the project directory
   ```
   cd fixitnow
   ```

3. Create assets directories
   ```
   mkdir -p assets/images assets/icons
   ```

4. Update the .env file with your API keys
   ```
   cp assets/.env.example assets/.env
   # Edit the .env file with your API keys
   ```

5. Install dependencies
   ```
   flutter pub get
   ```

6. Run the app
   ```
   flutter run
   ```

## Development Guidelines

- Follow the existing architecture pattern
- Maintain separation of concerns between providers and seekers
- Use GetX for state management and navigation
- Keep UI components modular and reusable
- Follow Flutter best practices for performance optimization

## Project Roadmap

- [x] Credit-based monetization system
- [ ] Payment gateway integration
- [ ] Enhanced analytics and reporting
- [ ] Multi-language support
- [ ] Web application version
- [ ] Integration with third-party service providers

## License

[Add your license information here]

## Contact

[Add contact information here]
