# Flutter App Signing & AdMob Implementation Guide

## 🔑 Android App Signing Setup

### 1. Generate Keystore File

#### Command to Generate Keystore:
```bash
keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias beauty
```

#### Interactive Prompts (Example):
```
Enter keystore password: beauty
Re-enter new password: beauty
What is your first and last name?
  [Unknown]:  BeautyGlow Developer
What is the name of your organizational unit?
  [Unknown]:  Development
What is the name of your organization?
  [Unknown]:  BeautyGlow
What is the name of your City or Locality?
  [Unknown]:  Your City
What is the name of your State or Province?
  [Unknown]:  Your State
What is the two-letter country code for this unit?
  [Unknown]:  US
Is CN=BeautyGlow Developer, OU=Development, O=BeautyGlow, L=Your City, ST=Your State, C=US correct?
  [no]:  yes

Enter key password for <beauty>
	(RETURN if same as keystore password): beauty
```

### 2. Create key.properties File

Create `android/key.properties`:
```properties
storePassword=beauty
keyPassword=beauty
keyAlias=beauty
storeFile=../keystore.jks
```

### 3. Configure build.gradle.kts for Signing

Add to `android/app/build.gradle.kts`:

```kotlin
import java.util.Properties
import java.io.FileInputStream

// Load signing properties
val keystoreProperties = Properties().apply {
    load(FileInputStream(rootProject.file("key.properties")))
}

android {
    namespace = "com.beauty.beautyglow" // Your app package name
    compileSdk = flutter.compileSdkVersion
    
    defaultConfig {
        applicationId = "com.beauty.beautyglow" // Your unique app ID
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("debug") {
            isDebuggable = true
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            isMinifyEnabled = true             // Required for shrinking
            isShrinkResources = true 
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### 4. Build Signed APK/AAB

```bash
# Build signed APK
flutter build apk --release

# Build signed AAB (Recommended for Play Store)
flutter build appbundle --release
```

---

## 📱 Google AdMob Integration Guide

### 1. Dependencies Setup

#### pubspec.yaml
```yaml
dependencies:
  google_mobile_ads: ^3.0.0
  firebase_analytics: ^11.4.6  # Optional: For better ad analytics
  provider: ^6.1.1             # For state management
```

### 2. Android Configuration

#### android/app/src/main/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add internet permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <application
        android:label="BeautyGlow"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Your MainActivity -->
        <activity android:name=".MainActivity" ...>
            <!-- Activity config -->
        </activity>
        
        <!-- AdMob App ID Configuration -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-9204828301343579~9177265799"/>
    </application>
</manifest>
```

### 3. Ads Configuration Class

#### lib/core/config/ads_config.dart
```dart
import 'package:flutter/foundation.dart';

/// Configuration for Google AdMob
class AdsConfig {
  AdsConfig._();

  /// Whether to use test ads (should be true for development)
  static bool get useTestAds {
    if (kDebugMode || kProfileMode) {
      return true;
    }
    return false;
  }

  /// App ID for AdMob
  static String get appId {
    return 'ca-app-pub-9204828301343579~9177265799'; // Your Production App ID
  }

  /// Banner ad unit ID
  static String get bannerAdUnitId {
    if (useTestAds) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test Banner Ad ID
    }
    return 'ca-app-pub-9204828301343579/9044036878'; // Your Production Banner Ad ID
  }

  /// Interstitial ad unit ID
  static String get interstitialAdUnitId {
    if (useTestAds) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test Interstitial Ad ID
    }
    return 'ca-app-pub-9204828301343579/3967788251'; // Your Production Interstitial Ad ID
  }

  /// Native advanced ad unit ID
  static String get nativeAdvancedAdUnitId {
    if (useTestAds) {
      return 'ca-app-pub-3940256099942544/2247696110'; // Test Native Advanced Ad ID
    }
    return 'ca-app-pub-9204828301343579/3344971722'; // Your Production Native Advanced Ad ID
  }
}
```

### 4. Ad Service Implementation

#### lib/services/ad_service.dart
```dart
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/config/ads_config.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;
  NativeAd? _nativeAd;

  bool _isInterstitialAdReady = false;
  bool _isBannerAdReady = false;
  bool _isNativeAdReady = false;

  /// Initialize AdService
  void init() {
    debugPrint('📱 AdService: Initialized');
  }

  // Getters for ad readiness
  bool get isInterstitialAdReady => _isInterstitialAdReady;
  bool get isBannerAdReady => _isBannerAdReady;
  bool get isNativeAdReady => _isNativeAdReady;

  // Load interstitial ad
  Future<void> loadInterstitialAd() async {
    if (_isInterstitialAdReady) return;

    try {
      await InterstitialAd.load(
        adUnitId: AdsConfig.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            debugPrint('Interstitial ad loaded successfully');

            // Set full screen callback
            _interstitialAd!.fullScreenContentCallback =
                FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                _isInterstitialAdReady = false;
                ad.dispose();
                loadInterstitialAd(); // Preload next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _isInterstitialAdReady = false;
                ad.dispose();
                loadInterstitialAd(); // Retry loading
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: $error');
            _isInterstitialAdReady = false;
            // Retry after delay
            Future.delayed(const Duration(minutes: 1), loadInterstitialAd);
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
      _isInterstitialAdReady = false;
    }
  }

  // Show interstitial ad
  Future<void> showInterstitialAd() async {
    if (!_isInterstitialAdReady || _interstitialAd == null) {
      debugPrint('Interstitial ad not ready');
      return;
    }

    try {
      await _interstitialAd!.show();
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      _isInterstitialAdReady = false;
      loadInterstitialAd(); // Reload for next time
    }
  }

  // Load banner ad
  Future<void> loadBannerAd({
    required double width,
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) async {
    if (_isBannerAdReady) return;

    try {
      _bannerAd = BannerAd(
        adUnitId: AdsConfig.bannerAdUnitId,
        size: AdSize.banner, // Using standard banner size
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerAdReady = true;
            onAdLoaded(ad);
          },
          onAdFailedToLoad: (ad, error) {
            _isBannerAdReady = false;
            ad.dispose();
            onAdFailedToLoad(ad, error);
          },
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      _isBannerAdReady = false;
    }
  }

  // Load native ad
  Future<void> loadNativeAd({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) async {
    if (_isNativeAdReady) return;

    try {
      _nativeAd = NativeAd(
        adUnitId: AdsConfig.nativeAdvancedAdUnitId,
        factoryId: 'listTile',
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            _isNativeAdReady = true;
            onAdLoaded(ad);
          },
          onAdFailedToLoad: (ad, error) {
            _isNativeAdReady = false;
            ad.dispose();
            onAdFailedToLoad(ad, error);
          },
        ),
      );

      await _nativeAd!.load();
    } catch (e) {
      debugPrint('Error loading native ad: $e');
      _isNativeAdReady = false;
    }
  }

  // Dispose ads
  void dispose() {
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    _nativeAd?.dispose();
    _isInterstitialAdReady = false;
    _isBannerAdReady = false;
    _isNativeAdReady = false;
  }
}
```

### 5. Main App Initialization

#### lib/main.dart
```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'services/ad_service.dart';
import 'core/config/ads_config.dart';

Future<void> initGoogleMobileAds() async {
  try {
    await MobileAds.instance.initialize();

    // Get the device ID for testing
    String? deviceId = await MobileAds.instance
        .getRequestConfiguration()
        .then((config) => config.testDeviceIds?.firstOrNull);

    debugPrint('💡 AdMob Test Device ID: $deviceId');

    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: [if (deviceId != null) deviceId],
      ),
    );
    debugPrint('Mobile ads initialized successfully');
  } catch (e) {
    debugPrint('Error initializing mobile ads: $e');
    // Non-critical error, continue without ads
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize your other services (Hive, etc.)
  // ...
  
  // Create AdService instance
  final adService = AdService();
  
  // Initialize AdService
  adService.init();
  
  // Initialize Google Mobile Ads
  await initGoogleMobileAds();
  
  runApp(
    MultiProvider(
      providers: [
        // Your other providers
        Provider<AdService>.value(value: adService),
      ],
      child: const MyApp(),
    ),
  );
}
```

### 6. Using Ads in Screens

#### Banner Ad Example:
```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';

class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    final adService = Provider.of<AdService>(context, listen: false);
    
    adService.loadBannerAd(
      width: MediaQuery.of(context).size.width,
      onAdLoaded: (ad) {
        setState(() {
          _bannerAd = ad as BannerAd;
          _isBannerAdReady = true;
        });
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('Banner ad failed to load: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Screen')),
      body: Column(
        children: [
          // Your content
          Expanded(
            child: YourMainContent(),
          ),
          
          // Banner Ad
          if (_isBannerAdReady && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
```

#### Interstitial Ad Example:
```dart
class MyButtonScreen extends StatefulWidget {
  @override
  _MyButtonScreenState createState() => _MyButtonScreenState();
}

class _MyButtonScreenState extends State<MyButtonScreen> {
  @override
  void initState() {
    super.initState();
    // Preload interstitial ad
    final adService = Provider.of<AdService>(context, listen: false);
    adService.loadInterstitialAd();
  }

  void _onButtonPressed() async {
    final adService = Provider.of<AdService>(context, listen: false);
    
    // Show interstitial ad before navigation
    if (adService.isInterstitialAdReady) {
      await adService.showInterstitialAd();
    }
    
    // Navigate to next screen
    Navigator.push(context, MaterialPageRoute(builder: (_) => NextScreen()));
    
    // Preload next ad
    adService.loadInterstitialAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _onButtonPressed,
          child: Text('Show Ad & Navigate'),
        ),
      ),
    );
  }
}
```

### 7. Native Ad Example:
```dart
class NativeAdWidget extends StatefulWidget {
  @override
  _NativeAdWidgetState createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    final adService = Provider.of<AdService>(context, listen: false);
    
    adService.loadNativeAd(
      onAdLoaded: (ad) {
        setState(() {
          _nativeAd = ad as NativeAd;
          _isNativeAdLoaded = true;
        });
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('Native ad failed to load: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isNativeAdLoaded && _nativeAd != null
        ? Container(
            height: 300,
            child: AdWidget(ad: _nativeAd!),
          )
        : Container(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }
}
```

---

## 🚀 Quick Setup Checklist

### For New Project:
1. ✅ Add `google_mobile_ads` dependency to `pubspec.yaml`
2. ✅ Add AdMob App ID to `AndroidManifest.xml`
3. ✅ Create `ads_config.dart` with your ad unit IDs
4. ✅ Create `ad_service.dart` with ad management logic
5. ✅ Initialize AdMob in `main.dart`
6. ✅ Add AdService to Provider tree
7. ✅ Implement ads in screens where needed

### For App Signing:
1. ✅ Generate keystore with `keytool` command
2. ✅ Create `key.properties` file
3. ✅ Configure `build.gradle.kts` for signing
4. ✅ Build signed APK/AAB with Flutter commands

### Production Checklist:
1. ✅ Replace test ad unit IDs with production IDs
2. ✅ Test ads in release mode
3. ✅ Verify app signing works
4. ✅ Test APK/AAB installation
5. ✅ Upload to Play Store

---

## 🔧 Troubleshooting

### Common Ad Issues:
- **Ads not showing**: Check internet connection and ad unit IDs
- **Test ads not appearing**: Verify test device ID in logs
- **Production ads not showing**: Ensure correct ad unit IDs and app is live

### Common Signing Issues:
- **Build fails**: Check `key.properties` file paths and passwords
- **Can't install APK**: Verify keystore matches previous releases
- **Upload rejected**: Ensure target SDK >= 34 and proper signing

---

## 📄 Example File Structure
```
your_app/
├── android/
│   ├── app/
│   │   ├── build.gradle.kts (configured for signing)
│   │   └── src/main/AndroidManifest.xml (with AdMob App ID)
│   └── key.properties
├── lib/
│   ├── core/config/
│   │   └── ads_config.dart
│   ├── services/
│   │   └── ad_service.dart
│   └── main.dart (with AdMob initialization)
├── keystore.jks
└── pubspec.yaml (with google_mobile_ads dependency)
```

This guide provides a complete implementation that you can adapt to any Flutter project! 🎉 