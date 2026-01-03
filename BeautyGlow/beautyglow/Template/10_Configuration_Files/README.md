# ⚙️ Configuration Files - Platform-Specific Setup

## ✅ Purpose
Provide complete platform-specific configuration files for Android, iOS, and web deployment with proper permissions, capabilities, and service integrations.

## 🧠 Architecture Overview

### Configuration Structure
```
Configuration Files/
├── Android/
│   ├── AndroidManifest.xml          # Permissions and app configuration
│   ├── build.gradle (app)           # App-level build configuration
│   ├── build.gradle (project)       # Project-level build configuration
│   ├── gradle.properties            # Gradle properties
│   ├── proguard-rules.pro          # Code obfuscation rules
│   └── key.properties              # Signing key configuration
├── iOS/
│   ├── Info.plist                  # iOS app configuration
│   ├── Runner.entitlements         # iOS capabilities
│   ├── AppDelegate.swift           # iOS app delegate
│   └── GoogleService-Info.plist    # Firebase configuration
├── Web/
│   ├── index.html                  # Web app entry point
│   ├── manifest.json              # PWA manifest
│   └── firebase-config.js          # Firebase web configuration
└── Flutter/
    ├── pubspec.yaml                # Dependencies and assets
    ├── analysis_options.yaml       # Code analysis rules
    └── flutter_launcher_icons.yaml # App icon configuration
```

## 🛠️ Complete Configuration Files

### 1. Android Configuration

#### android/app/src/main/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.beautyglow.app">

    <!-- Internet and Network Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />

    <!-- Storage Permissions -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
        android:maxSdkVersion="28" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
        android:maxSdkVersion="32" />

    <!-- Camera and Gallery Permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

    <!-- Notification Permissions -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- Billing Permission -->
    <uses-permission android:name="com.android.vending.BILLING" />

    <!-- Hardware Features -->
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />

    <application
        android:label="BeautyGlow"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:requestLegacyExternalStorage="true"
        android:usesCleartextTraffic="true">

        <!-- Main Activity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <!-- Standard App Launch Intent -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <!-- Deep Link Support -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="beautyglow" />
            </intent-filter>

            <!-- Web Deep Links -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="https"
                      android:host="beautyglow.app" />
            </intent-filter>
        </activity>

        <!-- Flutter Engine Activity -->
        <activity
            android:name="io.flutter.embedding.android.FlutterActivity"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize" />

        <!-- AdMob App ID -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>

        <!-- Firebase Messaging -->
        <service
            android:name=".FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

        <!-- Notification Boot Receiver -->
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:enabled="true"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>

        <!-- Notification Receiver -->
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />

        <!-- File Provider for Image Sharing -->
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>

        <!-- Backup Rules -->
        <meta-data
            android:name="android.app.backup.BACKUP_AGENT_TIMEOUT"
            android:value="300000" />
    </application>

    <!-- Queries for Intent Resolution (Android 11+) -->
    <queries>
        <!-- Camera Apps -->
        <intent>
            <action android:name="android.media.action.IMAGE_CAPTURE" />
        </intent>
        
        <!-- Gallery Apps -->
        <intent>
            <action android:name="android.intent.action.GET_CONTENT" />
            <data android:mimeType="image/*" />
        </intent>
        
        <!-- Web Browsers -->
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        
        <!-- Email Apps -->
        <intent>
            <action android:name="android.intent.action.SENDTO" />
            <data android:scheme="mailto" />
        </intent>
    </queries>
</manifest>
```

#### android/app/build.gradle
```gradle
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterRoot = localProperties.getProperty('flutter.sdk')
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

// Keystore properties
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"

android {
    compileSdkVersion 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.beautyglow.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true
        
        // ProGuard configuration
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // Optimization flags
            zipAlignEnabled true
            debuggable false
            jniDebuggable false
            renderscriptDebuggable false
            
            // Build configuration fields
            buildConfigField "boolean", "DEBUG_MODE", "false"
            buildConfigField "String", "BUILD_TYPE", '"release"'
        }
        
        debug {
            signingConfig signingConfigs.debug
            minifyEnabled false
            debuggable true
            
            buildConfigField "boolean", "DEBUG_MODE", "true"
            buildConfigField "String", "BUILD_TYPE", '"debug"'
        }
    }

    flavorDimensions "default"
    productFlavors {
        production {
            dimension "default"
            applicationIdSuffix ""
            versionNameSuffix ""
        }
        
        staging {
            dimension "default"
            applicationIdSuffix ".staging"
            versionNameSuffix "-staging"
        }
    }

    packagingOptions {
        pickFirst '**/libc++_shared.so'
        pickFirst '**/libjsc.so'
    }

    lintOptions {
        disable 'InvalidPackage'
        checkReleaseBuilds false
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
    implementation 'androidx.multidex:multidex:2.0.1'
    implementation 'androidx.core:core-ktx:1.10.1'
    implementation 'androidx.lifecycle:lifecycle-runtime-ktx:2.6.1'
    
    // Google Play Services
    implementation 'com.google.android.gms:play-services-ads:22.1.0'
    implementation 'com.google.android.gms:play-services-base:18.2.0'
    
    // Firebase
    implementation platform('com.google.firebase:firebase-bom:32.1.1')
    implementation 'com.google.firebase:firebase-analytics-ktx'
    implementation 'com.google.firebase:firebase-messaging-ktx'
    
    // In-app billing
    implementation 'com.android.billingclient:billing-ktx:6.0.1'
}

// Apply Google Services plugin
apply plugin: 'com.google.gms.google-services'
```

#### android/app/proguard-rules.pro
```proguard
# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Hive database
-keep class hive.** { *; }
-keep class **$HiveFieldAdapter { *; }
-keepclassmembers class * extends hive.HiveObject {
    <fields>;
}

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# In-app purchases
-keep class com.android.billingclient.** { *; }
-keep class com.android.vending.billing.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Image picker and camera
-keep class androidx.camera.** { *; }
-keep class androidx.exifinterface.** { *; }

# Notification handling
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Gson (if used)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp and Retrofit (if used)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# General Android rules
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}
```

### 2. iOS Configuration

#### ios/Runner/Info.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Information -->
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>BeautyGlow</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>beautyglow</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>

    <!-- Minimum iOS Version -->
    <key>MinimumOSVersion</key>
    <string>12.0</string>

    <!-- Supported Interface Orientations -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>

    <!-- Launch Screen -->
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>

    <!-- Status Bar -->
    <key>UIStatusBarHidden</key>
    <false/>
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <true/>

    <!-- Privacy Permissions -->
    <key>NSCameraUsageDescription</key>
    <string>BeautyGlow needs camera access to take photos for your beauty routine tracking and progress photos.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>BeautyGlow needs photo library access to select and save images for your beauty routines and progress tracking.</string>
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>BeautyGlow needs permission to save photos to your photo library for progress tracking and routine documentation.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>BeautyGlow may need microphone access for video recording features in future updates.</string>

    <!-- Background Modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>background-processing</string>
        <string>background-fetch</string>
    </array>

    <!-- App Transport Security -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>localhost</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
            </dict>
        </dict>
    </dict>

    <!-- AdMob App ID -->
    <key>GADApplicationIdentifier</key>
    <string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>

    <!-- URL Schemes for Deep Linking -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>beautyglow.app</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>beautyglow</string>
            </array>
        </dict>
        <dict>
            <key>CFBundleURLName</key>
            <string>beautyglow.app.https</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>https</string>
            </array>
        </dict>
    </array>

    <!-- Associated Domains -->
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:beautyglow.app</string>
        <string>applinks:www.beautyglow.app</string>
    </array>

    <!-- iTunes File Sharing -->
    <key>UIFileSharingEnabled</key>
    <false/>
    <key>LSSupportsOpeningDocumentsInPlace</key>
    <false/>

    <!-- Appearance -->
    <key>UIUserInterfaceStyle</key>
    <string>Automatic</string>

    <!-- Capabilities -->
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>

    <!-- Scene Configuration -->
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
        <key>UISceneConfigurations</key>
        <dict>
            <key>UIWindowSceneSessionRoleApplication</key>
            <array>
                <dict>
                    <key>UISceneConfigurationName</key>
                    <string>Default Configuration</string>
                    <key>UISceneDelegateClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                </dict>
            </array>
        </dict>
    </dict>

    <!-- Firebase Configuration -->
    <key>FIREBASE_ANALYTICS_COLLECTION_ENABLED</key>
    <true/>
    <key>FIREBASE_CRASHLYTICS_COLLECTION_ENABLED</key>
    <true/>
</dict>
</plist>
```

#### ios/Runner/Runner.entitlements
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Associated Domains -->
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:beautyglow.app</string>
        <string>applinks:www.beautyglow.app</string>
    </array>

    <!-- Push Notifications -->
    <key>aps-environment</key>
    <string>production</string>

    <!-- In-App Purchase -->
    <key>com.apple.developer.in-app-payments</key>
    <array>
        <string>merchant.com.beautyglow.app</string>
    </array>

    <!-- Background Modes -->
    <key>com.apple.developer.background-modes</key>
    <array>
        <string>background-processing</string>
        <string>background-fetch</string>
    </array>

    <!-- App Groups (if needed for extensions) -->
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.beautyglow.app</string>
    </array>

    <!-- Keychain Sharing -->
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.beautyglow.app</string>
    </array>
</dict>
</plist>
```

### 3. Flutter Configuration

#### pubspec.yaml (Complete)
```yaml
name: beautyglow
description: A beautiful and intuitive Flutter application for tracking daily beauty routines
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # UI & Design
  cupertino_icons: ^1.0.2
  flutter_animate: ^4.3.0
  percent_indicator: ^4.2.3
  flutter_rating_bar: ^4.0.1
  shimmer: ^3.0.0
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0

  # State Management
  provider: ^6.1.1

  # Navigation
  go_router: ^13.0.0

  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1

  # Utilities
  intl: ^0.18.1
  uuid: ^4.2.2
  collection: ^1.18.0
  permission_handler: ^11.1.0

  # Image Handling
  image_picker: ^1.0.5

  # Notifications
  flutter_local_notifications: ^19.2.1
  shared_preferences: ^2.2.2
  timezone: ^0.10.0

  # Monetization
  google_mobile_ads: ^3.0.0
  in_app_purchase: ^3.1.11
  in_app_purchase_platform_interface: ^1.4.0

  # Analytics
  firebase_analytics: ^11.4.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  hive_generator: ^2.0.0
  build_runner: ^2.4.8
  flutter_launcher_icons: ^0.13.1
  mockito: ^5.4.4
  fake_async: ^1.3.2

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/images/app/
    - assets/images/categories/
    - assets/images/products/
    - assets/images/tips/
    - assets/images/achievements/
    - assets/images/routines/
    - assets/icons/

  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/app/icon.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/images/app/icon.png"
    background_color: "#hexcode"
    theme_color: "#hexcode"
  windows:
    generate: true
    image_path: "assets/images/app/icon.png"
    icon_size: 48
  macos:
    generate: true
    image_path: "assets/images/app/icon.png"
```

#### analysis_options.yaml
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/generated_plugin_registrant.dart"
  
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false

  errors:
    invalid_annotation_target: ignore
    todo: ignore
    deprecated_member_use_from_same_package: ignore

linter:
  rules:
    # Error rules
    avoid_empty_else: true
    avoid_print: true
    avoid_relative_lib_imports: true
    avoid_returning_null_for_future: true
    avoid_slow_async_io: true
    avoid_type_to_string: true
    avoid_types_as_parameter_names: true
    avoid_web_libraries_in_flutter: true
    cancel_subscriptions: true
    close_sinks: true
    comment_references: true
    control_flow_in_finally: true
    empty_statements: true
    hash_and_equals: true
    invariant_booleans: true
    iterable_contains_unrelated_type: true
    list_remove_unrelated_type: true
    literal_only_boolean_expressions: true
    no_adjacent_strings_in_list: true
    no_duplicate_case_values: true
    no_logic_in_create_state: true
    prefer_void_to_null: true
    test_types_in_equals: true
    throw_in_finally: true
    unnecessary_statements: true
    unrelated_type_equality_checks: true
    use_build_context_synchronously: true
    use_key_in_widget_constructors: true
    valid_regexps: true

    # Style rules
    always_declare_return_types: true
    always_put_control_body_on_new_line: true
    always_put_required_named_parameters_first: true
    always_specify_types: false
    annotate_overrides: true
    avoid_annotating_with_dynamic: true
    avoid_bool_literals_in_conditional_expressions: true
    avoid_catches_without_on_clauses: true
    avoid_catching_errors: true
    avoid_double_and_int_checks: true
    avoid_field_initializers_in_const_classes: true
    avoid_function_literals_in_foreach_calls: true
    avoid_implementing_value_types: true
    avoid_init_to_null: true
    avoid_null_checks_in_equality_operators: true
    avoid_positional_boolean_parameters: true
    avoid_private_typedef_functions: true
    avoid_redundant_argument_values: true
    avoid_renaming_method_parameters: true
    avoid_return_types_on_setters: true
    avoid_returning_null: true
    avoid_returning_null_for_void: true
    avoid_returning_this: true
    avoid_setters_without_getters: true
    avoid_shadowing_type_parameters: true
    avoid_single_cascade_in_expression_statements: true
    avoid_unnecessary_containers: true
    avoid_unused_constructor_parameters: true
    avoid_void_async: true
    await_only_futures: true
    camel_case_extensions: true
    camel_case_types: true
    cascade_invocations: true
    cast_nullable_to_non_nullable: true
    constant_identifier_names: true
    curly_braces_in_flow_control_structures: true
    directives_ordering: true
    empty_catches: true
    empty_constructor_bodies: true
    exhaustive_cases: true
    file_names: true
    flutter_style_todos: true
    implementation_imports: true
    join_return_with_assignment: true
    leading_newlines_in_multiline_strings: true
    library_names: true
    library_prefixes: true
    lines_longer_than_80_chars: false
    missing_whitespace_between_adjacent_strings: true
    no_runtimeType_toString: true
    non_constant_identifier_names: true
    null_closures: true
    omit_local_variable_types: true
    one_member_abstracts: true
    only_throw_errors: true
    overridden_fields: true
    package_api_docs: true
    package_prefixed_library_names: true
    parameter_assignments: true
    prefer_adjacent_string_concatenation: true
    prefer_asserts_in_initializer_lists: true
    prefer_asserts_with_message: true
    prefer_collection_literals: true
    prefer_conditional_assignment: true
    prefer_const_constructors: true
    prefer_const_constructors_in_immutables: true
    prefer_const_declarations: true
    prefer_const_literals_to_create_immutables: true
    prefer_constructors_over_static_methods: true
    prefer_contains: true
    prefer_equal_for_default_values: true
    prefer_expression_function_bodies: true
    prefer_final_fields: true
    prefer_final_in_for_each: true
    prefer_final_locals: true
    prefer_for_elements_to_map_fromIterable: true
    prefer_foreach: true
    prefer_function_declarations_over_variables: true
    prefer_generic_function_type_aliases: true
    prefer_if_elements_to_conditional_expressions: true
    prefer_if_null_operators: true
    prefer_initializing_formals: true
    prefer_inlined_adds: true
    prefer_int_literals: true
    prefer_interpolation_to_compose_strings: true
    prefer_is_empty: true
    prefer_is_not_empty: true
    prefer_is_not_operator: true
    prefer_iterable_whereType: true
    prefer_null_aware_operators: true
    prefer_relative_imports: true
    prefer_single_quotes: true
    prefer_spread_collections: true
    prefer_typing_uninitialized_variables: true
    provide_deprecation_message: true
    public_member_api_docs: false
    recursive_getters: true
    slash_for_doc_comments: true
    sort_child_properties_last: true
    sort_constructors_first: true
    sort_pub_dependencies: true
    sort_unnamed_constructors_first: true
    type_annotate_public_apis: true
    type_init_formals: true
    unawaited_futures: true
    unnecessary_await_in_return: true
    unnecessary_brace_in_string_interps: true
    unnecessary_const: true
    unnecessary_getters_setters: true
    unnecessary_lambdas: true
    unnecessary_new: true
    unnecessary_null_aware_assignments: true
    unnecessary_null_checks: true
    unnecessary_null_in_if_null_operators: true
    unnecessary_nullable_for_final_variable_declarations: true
    unnecessary_overrides: true
    unnecessary_parenthesis: true
    unnecessary_raw_strings: true
    unnecessary_string_escapes: true
    unnecessary_string_interpolations: true
    unnecessary_this: true
    use_full_hex_values_for_flutter_colors: true
    use_function_type_syntax_for_parameters: true
    use_is_even_rather_than_modulo: true
    use_named_constants: true
    use_raw_strings: true
    use_rethrow_when_possible: true
    use_setters_to_change_properties: true
    use_string_buffers: true
    use_to_and_as_if_applicable: true
    void_checks: true
```

### 4. Web Configuration

#### web/index.html
```html
<!DOCTYPE html>
<html>
<head>
  <!--
    If you are serving your web app in a path other than the root, change the
    href value below to reflect the base path you are serving from.

    The path provided below has to start and end with a slash "/" in order for
    it to work correctly.

    For more details:
    * https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base

    This is a placeholder for base href that will be replaced by the value of
    the `--base-href` argument provided to `flutter build`.
  -->
  <base href="$FLUTTER_BASE_HREF">

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="A beautiful and intuitive Flutter application for tracking daily beauty routines">

  <!-- iOS meta tags & icons -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="BeautyGlow">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>

  <title>BeautyGlow</title>
  <link rel="manifest" href="manifest.json">

  <script>
    // The value below is injected by flutter build, do not touch.
    var serviceWorkerVersion = null;
  </script>
  <!-- This script adds the flutter initialization JS code -->
  <script src="flutter.js" defer></script>

  <!-- Firebase Configuration -->
  <script src="https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/9.22.0/firebase-analytics-compat.js"></script>
  <script src="firebase-config.js"></script>

  <style>
    /* Loading screen styles */
    .loading {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100vh;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    }
    
    .loading-logo {
      width: 120px;
      height: 120px;
      margin-bottom: 30px;
      border-radius: 20px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.2);
    }
    
    .loading-text {
      color: white;
      font-size: 24px;
      font-weight: 600;
      margin-bottom: 20px;
    }
    
    .loading-spinner {
      width: 40px;
      height: 40px;
      border: 4px solid rgba(255,255,255,0.3);
      border-top: 4px solid white;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }
    
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <!-- Loading screen -->
  <div id="loading" class="loading">
    <img src="icons/Icon-192.png" alt="BeautyGlow" class="loading-logo">
    <div class="loading-text">BeautyGlow</div>
    <div class="loading-spinner"></div>
  </div>

  <script>
    window.addEventListener('load', function(ev) {
      // Download main.dart.js
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        },
        onEntrypointLoaded: function(engineInitializer) {
          engineInitializer.initializeEngine().then(function(appRunner) {
            // Hide loading screen
            document.getElementById('loading').style.display = 'none';
            appRunner.runApp();
          });
        }
      });
    });
  </script>
</body>
</html>
```

#### web/manifest.json
```json
{
    "name": "BeautyGlow",
    "short_name": "BeautyGlow",
    "start_url": ".",
    "display": "standalone",
    "background_color": "#667eea",
    "theme_color": "#667eea",
    "description": "A beautiful and intuitive Flutter application for tracking daily beauty routines",
    "orientation": "portrait-primary",
    "prefer_related_applications": false,
    "icons": [
        {
            "src": "icons/Icon-192.png",
            "sizes": "192x192",
            "type": "image/png"
        },
        {
            "src": "icons/Icon-512.png",
            "sizes": "512x512",
            "type": "image/png"
        },
        {
            "src": "icons/Icon-maskable-192.png",
            "sizes": "192x192",
            "type": "image/png",
            "purpose": "maskable"
        },
        {
            "src": "icons/Icon-maskable-512.png",
            "sizes": "512x512",
            "type": "image/png",
            "purpose": "maskable"
        }
    ]
}
```

## 🔁 Integration Guide

### Step 1: Platform Setup

#### Android Setup
1. Copy all Android configuration files to your project
2. Update package name in `AndroidManifest.xml` and `build.gradle`
3. Generate signing key: `keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key`
4. Create `key.properties` file with signing information
5. Add Firebase configuration file `google-services.json`

#### iOS Setup
1. Copy iOS configuration files to your project
2. Update bundle identifier in Xcode project settings
3. Configure signing certificates and provisioning profiles
4. Add Firebase configuration file `GoogleService-Info.plist`
5. Enable required capabilities in Xcode

#### Web Setup
1. Copy web configuration files
2. Update Firebase configuration in `firebase-config.js`
3. Customize PWA manifest and icons
4. Configure hosting (Firebase Hosting, Netlify, etc.)

### Step 2: Environment Configuration

#### Development Environment
```bash
# Install dependencies
flutter pub get

# Generate code (Hive adapters, etc.)
flutter packages pub run build_runner build

# Generate app icons
flutter pub run flutter_launcher_icons:main

# Run on different platforms
flutter run                    # Debug mode
flutter run --release         # Release mode
flutter run -d chrome         # Web
flutter run -d ios           # iOS simulator
flutter run -d android       # Android emulator
```

#### Production Build
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Step 3: Store Deployment

#### Google Play Store
1. Create developer account
2. Upload AAB file
3. Configure store listing
4. Set up in-app products
5. Submit for review

#### Apple App Store
1. Create developer account
2. Configure App Store Connect
3. Upload IPA via Xcode or Transporter
4. Configure in-app purchases
5. Submit for review

#### Web Deployment
1. Build web version
2. Deploy to hosting service
3. Configure domain and SSL
4. Set up analytics and monitoring

## 📱 Platform-Specific Features

### Android Features
- **Adaptive Icons**: Support for Android 8.0+ adaptive icons
- **App Bundles**: Optimized APK delivery with Play App Signing
- **Background Tasks**: Proper background processing configuration
- **Deep Linking**: App Links and custom URL schemes
- **Notifications**: Rich notifications with actions and images

### iOS Features
- **App Store Guidelines**: Compliant with latest iOS guidelines
- **Privacy Permissions**: Proper permission descriptions
- **Universal Links**: Seamless deep linking
- **Background App Refresh**: Optimized background processing
- **Push Notifications**: APNs integration

### Web Features
- **Progressive Web App**: Full PWA support with offline capabilities
- **Responsive Design**: Adaptive layout for all screen sizes
- **Service Worker**: Caching and offline functionality
- **Web App Manifest**: Native app-like experience
- **SEO Optimization**: Search engine friendly configuration

## 🔄 Feature Validation

✅ **Build Success**: All platforms build without errors
✅ **Permissions**: All required permissions properly configured
✅ **Deep Linking**: URL schemes and universal links work
✅ **Store Compliance**: Meets all platform store requirements
✅ **Performance**: Optimized builds with proper obfuscation
✅ **Security**: Secure configuration with proper signing
✅ **Analytics**: Tracking and monitoring properly configured

---

**Next**: Continue with `11_Assets_Resources` to organize images, icons, and other assets. 