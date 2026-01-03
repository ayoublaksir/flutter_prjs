# Flutter Application ID Change Guide

## 📱 Overview

This guide covers the complete process of changing a Flutter app's application ID from the default `com.example.xxx` format to a production-ready `com.yourcompany.appname` format. This is essential for Play Store publishing and proper app identification.

## 🎯 Why Change Application ID?

### Issues with Default ID:
- ❌ **Play Store Rejection**: `com.example.*` IDs are not allowed in production
- ❌ **Package Conflicts**: Multiple apps with same ID can't coexist
- ❌ **Unprofessional**: Indicates development/testing phase
- ❌ **Update Issues**: Can't update existing apps with different package names

### Benefits of Custom ID:
- ✅ **Play Store Compliance**: Required for publishing
- ✅ **Brand Identity**: Reflects your company/app name
- ✅ **Unique Identification**: Prevents package conflicts
- ✅ **Professional Appearance**: Shows production readiness

## 🔄 BeautyGlow Case Study

### Original Configuration:
```
Application ID: com.example.beautyglow
Package Structure: com/example/beautyglow/
MainActivity: com.example.beautyglow.MainActivity
```

### Updated Configuration:
```
Application ID: com.beauty.beautyglow
Package Structure: com/beauty/beautyglow/
MainActivity: com.beauty.beautyglow.MainActivity
```

## 📝 Step-by-Step Implementation

### Step 1: Update build.gradle.kts

**File**: `android/app/build.gradle.kts`

```kotlin
android {
    namespace = "com.beauty.beautyglow"  // Update this
    compileSdk = flutter.compileSdkVersion
    
    defaultConfig {
        applicationId = "com.beauty.beautyglow"  // Update this
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
    // Rest of configuration...
}
```

### Step 2: Create New Directory Structure

Create the new package directory structure:

```bash
# Windows
mkdir android\app\src\main\kotlin\com\beauty\beautyglow

# Linux/macOS
mkdir -p android/app/src/main/kotlin/com/beauty/beautyglow
```

### Step 3: Create New MainActivity

**File**: `android/app/src/main/kotlin/com/beauty/beautyglow/MainActivity.kt`

```kotlin
package com.beauty.beautyglow

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

### Step 4: Remove Old MainActivity

```bash
# Delete old MainActivity
rm android/app/src/main/kotlin/com/example/beautyglow/MainActivity.kt

# Clean up empty directories (optional)
rmdir android/app/src/main/kotlin/com/example/beautyglow
rmdir android/app/src/main/kotlin/com/example
```

### Step 5: Update AndroidManifest.xml

**File**: `android/app/src/main/AndroidManifest.xml`

Usually no changes needed, but verify the activity declaration:

```xml
<activity
    android:name=".MainActivity"  <!-- This should work automatically -->
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme">
    <!-- Activity configuration -->
</activity>
```

### Step 6: Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter build apk --debug  # Test build
```

## 🛠️ Automated Script for Package Change

### PowerShell Script (Windows)

Create `change_package_name.ps1`:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$OldPackage,
    
    [Parameter(Mandatory=$true)]
    [string]$NewPackage
)

Write-Host "Changing package from $OldPackage to $NewPackage" -ForegroundColor Green

# Convert package names to paths
$OldPath = $OldPackage -replace '\.', '\'
$NewPath = $NewPackage -replace '\.', '\'

# Update build.gradle.kts
Write-Host "Updating build.gradle.kts..." -ForegroundColor Yellow
$BuildGradlePath = "android\app\build.gradle.kts"
if (Test-Path $BuildGradlePath) {
    (Get-Content $BuildGradlePath) `
        -replace "namespace = `"$OldPackage`"", "namespace = `"$NewPackage`"" `
        -replace "applicationId = `"$OldPackage`"", "applicationId = `"$NewPackage`"" |
    Set-Content $BuildGradlePath
    Write-Host "✓ Updated build.gradle.kts" -ForegroundColor Green
}

# Create new directory structure
Write-Host "Creating new directory structure..." -ForegroundColor Yellow
$NewDir = "android\app\src\main\kotlin\$NewPath"
New-Item -ItemType Directory -Path $NewDir -Force | Out-Null
Write-Host "✓ Created directory: $NewDir" -ForegroundColor Green

# Create new MainActivity
Write-Host "Creating new MainActivity..." -ForegroundColor Yellow
$MainActivityContent = @"
package $NewPackage

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
"@

$MainActivityPath = "$NewDir\MainActivity.kt"
Set-Content -Path $MainActivityPath -Value $MainActivityContent
Write-Host "✓ Created MainActivity: $MainActivityPath" -ForegroundColor Green

# Remove old MainActivity if it exists
$OldMainActivityPath = "android\app\src\main\kotlin\$OldPath\MainActivity.kt"
if (Test-Path $OldMainActivityPath) {
    Remove-Item $OldMainActivityPath -Force
    Write-Host "✓ Removed old MainActivity: $OldMainActivityPath" -ForegroundColor Green
    
    # Try to remove empty directories
    try {
        $OldDir = "android\app\src\main\kotlin\$OldPath"
        Remove-Item $OldDir -Force
        Write-Host "✓ Removed old directory: $OldDir" -ForegroundColor Green
    } catch {
        Write-Host "△ Could not remove old directory (may not be empty)" -ForegroundColor Yellow
    }
}

Write-Host "Package change completed successfully!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run: flutter clean" -ForegroundColor White
Write-Host "2. Run: flutter pub get" -ForegroundColor White
Write-Host "3. Run: flutter build apk --debug" -ForegroundColor White
```

### Bash Script (Linux/macOS)

Create `change_package_name.sh`:

```bash
#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if correct number of arguments provided
if [ $# -ne 2 ]; then
    echo -e "${RED}Usage: $0 <old_package> <new_package>${NC}"
    echo -e "${YELLOW}Example: $0 com.example.myapp com.company.myapp${NC}"
    exit 1
fi

OLD_PACKAGE=$1
NEW_PACKAGE=$2

echo -e "${GREEN}Changing package from $OLD_PACKAGE to $NEW_PACKAGE${NC}"

# Convert package names to paths
OLD_PATH=$(echo $OLD_PACKAGE | sed 's/\./\//g')
NEW_PATH=$(echo $NEW_PACKAGE | sed 's/\./\//g')

# Update build.gradle.kts
echo -e "${YELLOW}Updating build.gradle.kts...${NC}"
BUILD_GRADLE="android/app/build.gradle.kts"
if [ -f "$BUILD_GRADLE" ]; then
    sed -i.bak \
        -e "s/namespace = \"$OLD_PACKAGE\"/namespace = \"$NEW_PACKAGE\"/g" \
        -e "s/applicationId = \"$OLD_PACKAGE\"/applicationId = \"$NEW_PACKAGE\"/g" \
        "$BUILD_GRADLE"
    echo -e "${GREEN}✓ Updated build.gradle.kts${NC}"
fi

# Create new directory structure
echo -e "${YELLOW}Creating new directory structure...${NC}"
NEW_DIR="android/app/src/main/kotlin/$NEW_PATH"
mkdir -p "$NEW_DIR"
echo -e "${GREEN}✓ Created directory: $NEW_DIR${NC}"

# Create new MainActivity
echo -e "${YELLOW}Creating new MainActivity...${NC}"
cat > "$NEW_DIR/MainActivity.kt" << EOF
package $NEW_PACKAGE

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
EOF
echo -e "${GREEN}✓ Created MainActivity: $NEW_DIR/MainActivity.kt${NC}"

# Remove old MainActivity if it exists
OLD_MAIN_ACTIVITY="android/app/src/main/kotlin/$OLD_PATH/MainActivity.kt"
if [ -f "$OLD_MAIN_ACTIVITY" ]; then
    rm "$OLD_MAIN_ACTIVITY"
    echo -e "${GREEN}✓ Removed old MainActivity: $OLD_MAIN_ACTIVITY${NC}"
    
    # Try to remove empty directories
    OLD_DIR="android/app/src/main/kotlin/$OLD_PATH"
    rmdir "$OLD_DIR" 2>/dev/null && echo -e "${GREEN}✓ Removed old directory: $OLD_DIR${NC}" || echo -e "${YELLOW}△ Could not remove old directory (may not be empty)${NC}"
fi

echo -e "${GREEN}Package change completed successfully!${NC}"
echo -e "${CYAN}Next steps:${NC}"
echo -e "${NC}1. Run: flutter clean${NC}"
echo -e "${NC}2. Run: flutter pub get${NC}"
echo -e "${NC}3. Run: flutter build apk --debug${NC}"
```

## 🔧 Usage Examples

### Using PowerShell Script:
```powershell
# Make script executable and run
.\change_package_name.ps1 -OldPackage "com.example.beautyglow" -NewPackage "com.beauty.beautyglow"
```

### Using Bash Script:
```bash
# Make script executable and run
chmod +x change_package_name.sh
./change_package_name.sh com.example.beautyglow com.beauty.beautyglow
```

### Manual Method:
```bash
# For any app, replace these values:
OLD_PACKAGE="com.example.myapp"
NEW_PACKAGE="com.mycompany.myapp"

# Follow the 6 steps outlined above
```

## 🧪 Testing the Changes

### Step 1: Clean Build
```bash
flutter clean
flutter pub get
```

### Step 2: Debug Build Test
```bash
flutter build apk --debug
```

### Step 3: Install and Test
```bash
# Install on device/emulator
flutter install

# Or run directly
flutter run
```

### Step 4: Verify Package Name
```bash
# Check installed package name on device
adb shell pm list packages | grep beauty

# Should show: package:com.beauty.beautyglow
```

## ⚠️ Common Issues & Solutions

### Issue 1: ClassNotFoundException
```
Error: Didn't find class "com.beauty.beautyglow.MainActivity"
```

**Solution**: Ensure MainActivity is in correct directory with correct package declaration.

```kotlin
// Verify MainActivity.kt has correct package:
package com.beauty.beautyglow  // Must match directory structure
```

### Issue 2: Build Gradle Sync Issues
```
Error: Namespace not specified
```

**Solution**: Ensure both namespace and applicationId are updated:

```kotlin
android {
    namespace = "com.beauty.beautyglow"      // Add this
    defaultConfig {
        applicationId = "com.beauty.beautyglow"  // Update this
    }
}
```

### Issue 3: Directory Structure Mismatch
```
Error: Package does not match directory structure
```

**Solution**: Verify directory structure matches package name:

```
✓ Package: com.beauty.beautyglow
✓ Directory: android/app/src/main/kotlin/com/beauty/beautyglow/
✓ MainActivity.kt in correct location
```

### Issue 4: Multiple Package References
```
Error: Multiple MainActivity classes found
```

**Solution**: Remove old MainActivity and clean build:

```bash
# Remove old files
rm -rf android/app/src/main/kotlin/com/example/

# Clean and rebuild
flutter clean
flutter pub get
```

## 📋 Verification Checklist

### Before Making Changes:
- [ ] Backup your project
- [ ] Note current package name
- [ ] Ensure no pending changes

### During Changes:
- [ ] Update namespace in build.gradle.kts
- [ ] Update applicationId in build.gradle.kts
- [ ] Create new directory structure
- [ ] Create new MainActivity with correct package
- [ ] Remove old MainActivity
- [ ] Clean up old directories

### After Changes:
- [ ] Run flutter clean
- [ ] Run flutter pub get
- [ ] Test debug build
- [ ] Install and test on device
- [ ] Verify package name in device settings
- [ ] Test all app functionality
- [ ] Update keystore references if needed

## 🚀 Production Considerations

### Keystore Compatibility
If you have an existing keystore, the package name change is compatible as long as:
- ✅ Same keystore file used
- ✅ Same key alias and passwords
- ✅ Only package name changed (not signing configuration)

### Play Store Publishing
- ✅ **New App**: Use new package name from the start
- ❌ **Existing App**: Cannot change package name for published apps
- ✅ **Update Strategy**: Publish as new app if package name must change

### Data Migration
- ❌ **App Data**: Will be lost when package name changes
- ❌ **Shared Preferences**: Not accessible after package change
- ❌ **Database Files**: Located in package-specific directories
- ✅ **External Storage**: May be accessible if permissions match

## 📋 Best Practices

### Package Naming Convention:
```
Format: com.company.appname
Examples:
✅ com.beauty.beautyglow
✅ com.mycompany.myapp
✅ com.studio.photoeditor
❌ com.example.myapp (avoid for production)
❌ com.test.app (avoid for production)
```

### Directory Structure:
```
android/app/src/main/kotlin/
└── com/
    └── beauty/
        └── beautyglow/
            └── MainActivity.kt
```

### Version Control:
```bash
# Commit before making changes
git add .
git commit -m "Backup before package name change"

# Make changes
# Test thoroughly

# Commit after successful change
git add .
git commit -m "Changed package from com.example.beautyglow to com.beauty.beautyglow"
```

This guide provides a complete solution for changing Flutter app package names, with both manual steps and automated scripts for different platforms. 