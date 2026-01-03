# In-App Purchase Setup Guide for BeautyGlow

This guide will help you set up in-app purchases in Google Play Console to resolve the "product not found" error.

## Prerequisites

1. **Google Play Console Account**: You need a Google Play Console developer account
2. **App Upload**: Your app must be uploaded to Google Play Console (at least as an internal testing build)
3. **Signed APK**: The app must be signed with the same keystore as your production builds

## Step-by-Step Setup

### 1. Access Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with your developer account
3. Select your BeautyGlow app

### 2. Create In-App Products

#### Navigate to Monetization
1. In the left sidebar, click on **"Monetize"**
2. Select **"Products"** → **"In-app products"**

#### Create Monthly Subscription
1. Click **"Create product"**
2. **Product ID**: `beautyglow_monthly_premium` (MUST match exactly)
3. **Name**: `BeautyGlow Monthly Premium`
4. **Description**: `Unlock unlimited access to all beauty tips, ad-free experience, and premium features for one month.`
5. **Status**: Set to **"Active"**
6. **Price**: Set your desired monthly price (e.g., $4.99)

#### Create Lifetime Purchase
1. Click **"Create product"** again
2. **Product ID**: `beautyglow_lifetime_premium` (MUST match exactly)
3. **Name**: `BeautyGlow Lifetime Premium`
4. **Description**: `One-time purchase for lifetime access to all premium features, unlimited content, and ad-free experience.`
5. **Status**: Set to **"Active"**
6. **Price**: Set your desired lifetime price (e.g., $29.99)

### 3. Create Subscription (for Monthly)

1. Go to **"Monetize"** → **"Subscriptions"**
2. Click **"Create subscription"**
3. **Subscription ID**: `beautyglow_monthly_premium` (same as product ID)
4. **Name**: `BeautyGlow Monthly Premium`
5. **Benefits**: List premium features
6. **Base plan**:
   - **Billing period**: 1 month
   - **Price**: Match your product price
   - **Free trial**: Optional (e.g., 7 days)

### 4. Set Up Testing

#### Create Internal Testing Track
1. Go to **"Release"** → **"Testing"** → **"Internal testing"**
2. Create a new release if you haven't already
3. Upload your signed APK/AAB

#### Add Test Users
1. In Internal testing, scroll to **"Testers"**
2. Create an email list with test accounts
3. Add the Gmail accounts that will test purchases

#### License Testing (Optional)
1. Go to **"Settings"** → **"License testing"**
2. Add Gmail accounts for license testing
3. Set test response (usually "RESPOND_NORMALLY")

### 5. App Configuration

#### Update Product IDs in Code
Ensure your app uses these exact product IDs:

```dart
// In subscription_service.dart
static const String _monthlySubId = 'beautyglow_monthly_premium';
static const String _lifetimeId = 'beautyglow_lifetime_premium';
```

#### Android Manifest Permissions
Ensure you have the billing permission in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="com.android.vending.BILLING"/>
```

### 6. Testing Process

#### Important Testing Notes
- **Real Device Only**: In-app purchases don't work on emulators
- **Signed Build**: Use a signed release build, not debug
- **Google Play Store**: Device must have Google Play Store installed
- **Test Account**: Use an account added to internal testing
- **Published App**: App must be published to at least internal testing

#### Testing Steps
1. Install the app from Google Play Console (internal testing link)
2. Sign in with a test account
3. Navigate to Premium features
4. Attempt to purchase
5. Check debug logs for detailed error information

### 7. Common Issues and Solutions

#### "Product not found" Error
- **Cause**: Product IDs don't match between app and Google Play Console
- **Solution**: Verify exact product ID spelling and case sensitivity

#### "Item unavailable for purchase" Error
- **Cause**: Product not set to "Active" status
- **Solution**: Ensure products are activated in Google Play Console

#### "Authentication required" Error
- **Cause**: Not signed in to correct Google account
- **Solution**: Sign in with test account that has console access

#### "This version of the application is not configured for billing through Google Play"
- **Cause**: Using debug build or wrong signature
- **Solution**: Use signed release build uploaded to console

### 8. Debugging Tools

#### Use IAP Debug Screen
The app includes a debug screen accessible through:
1. Profile → Settings → "IAP Debug"
2. This screen shows:
   - Product availability
   - Service initialization status
   - Test purchase buttons
   - Troubleshooting information

#### Enable Debug Logging
Add this to your debug configuration:
```dart
// Enable detailed in-app purchase logging
debugPrint('IAP Debug Mode Enabled');
```

#### Check Logs
Monitor the console for detailed logs that start with:
- `🛒 SubscriptionService:` - Product loading
- `💳 SubscriptionService:` - Monthly purchases
- `💎 SubscriptionService:` - Lifetime purchases
- `❌ SubscriptionService:` - Errors

### 9. Production Checklist

Before releasing to production:

- [ ] Products created and activated in Google Play Console
- [ ] Product IDs match exactly in code and console
- [ ] App uploaded and published (at least to internal testing)
- [ ] Testing completed on real devices
- [ ] Purchase flow works end-to-end
- [ ] Restore purchases functionality tested
- [ ] Error handling verified

### 10. Support Resources

- [Google Play Billing Documentation](https://developer.android.com/google/play/billing)
- [Flutter In-App Purchase Plugin](https://pub.dev/packages/in_app_purchase)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)

### 11. Product Configuration Summary

For quick reference, here are the exact product configurations:

**Monthly Subscription:**
- ID: `beautyglow_monthly_premium`
- Type: Subscription
- Billing: Monthly
- Auto-renewing: Yes

**Lifetime Purchase:**
- ID: `beautyglow_lifetime_premium`
- Type: Managed Product
- One-time purchase: Yes

### Troubleshooting Contact

If you continue to experience issues after following this guide:

1. Check the IAP Debug screen for specific error messages
2. Verify all product IDs match exactly
3. Ensure you're testing on a real device with a signed build
4. Confirm the test account has access to internal testing

Remember: The most common cause of "product not found" errors is a mismatch between the product IDs in your code and those configured in Google Play Console. 