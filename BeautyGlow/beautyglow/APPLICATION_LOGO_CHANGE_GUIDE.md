# Flutter Application Logo Change Guide

## 🎨 Overview

This guide covers the complete process of changing and updating application logos, icons, and splash screens in Flutter apps across all platforms (Android, iOS, Web, Windows, macOS, Linux). It includes automated scripts and manual methods.

## 📱 Icon Types and Locations

### Android Icons
```
android/app/src/main/res/
├── mipmap-hdpi/ic_launcher.png          (72×72)
├── mipmap-mdpi/ic_launcher.png          (48×48)
├── mipmap-xhdpi/ic_launcher.png         (96×96)
├── mipmap-xxhdpi/ic_launcher.png        (144×144)
├── mipmap-xxxhdpi/ic_launcher.png       (192×192)
└── mipmap-anydpi-v26/ic_launcher.xml    (Adaptive icon)
```

### iOS Icons
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
├── Icon-App-20x20@1x.png       (20×20)
├── Icon-App-20x20@2x.png       (40×40)
├── Icon-App-20x20@3x.png       (60×60)
├── Icon-App-29x29@1x.png       (29×29)
├── Icon-App-29x29@2x.png       (58×58)
├── Icon-App-29x29@3x.png       (87×87)
├── Icon-App-40x40@1x.png       (40×40)
├── Icon-App-40x40@2x.png       (80×80)
├── Icon-App-40x40@3x.png       (120×120)
├── Icon-App-60x60@2x.png       (120×120)
├── Icon-App-60x60@3x.png       (180×180)
├── Icon-App-76x76@1x.png       (76×76)
├── Icon-App-76x76@2x.png       (152×152)
├── Icon-App-83.5x83.5@2x.png   (167×167)
└── Icon-App-1024x1024@1x.png   (1024×1024)
```

### Web Icons
```
web/
├── favicon.png                 (16×16, 32×32)
└── icons/
    ├── Icon-192.png           (192×192)
    ├── Icon-512.png           (512×512)
    ├── Icon-maskable-192.png  (192×192)
    └── Icon-maskable-512.png  (512×512)
```

### Desktop Icons
```
windows/runner/resources/app_icon.ico
macos/Runner/Assets.xcassets/AppIcon.appiconset/
linux/ (handled by flutter_launcher_icons)
```

## 🛠️ Method 1: Automated with flutter_launcher_icons

### Step 1: Add Dependency

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

### Step 2: Create Configuration

Add configuration to `pubspec.yaml`:

```yaml
flutter_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icons/app_icon.png"  # Your source icon (1024×1024)
  min_sdk_android: 21
  
  # Web configuration
  web:
    generate: true
    image_path: "assets/icons/app_icon.png"
    background_color: "#hexcode"
    theme_color: "#hexcode"
  
  # Windows configuration
  windows:
    generate: true
    image_path: "assets/icons/app_icon.png"
    icon_size: 48
  
  # macOS configuration
  macos:
    generate: true
    image_path: "assets/icons/app_icon.png"
```

### Step 3: Prepare Source Image

Create your source icon:
- **Size**: 1024×1024 pixels minimum
- **Format**: PNG with transparency
- **Design**: Simple, recognizable, works at small sizes
- **Location**: `assets/icons/app_icon.png`

### Step 4: Generate Icons

```bash
# Install the package
flutter pub get

# Generate all icons
flutter pub run flutter_launcher_icons:main
```

## 🎨 Method 2: BeautyGlow Custom Configuration

### Complete Configuration File

Create `flutter_launcher_icons.yaml`:

```yaml
flutter_icons:
  android: "ic_launcher"
  ios: true
  image_path: "assets/images/logo.png"
  min_sdk_android: 21
  
  # Remove the old launcher icon
  remove_alpha_ios: true
  
  # Android adaptive icon configuration
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/logo.png"
  
  # Web icons
  web:
    generate: true
    image_path: "assets/images/logo.png"
    background_color: "#FFFFFF"
    theme_color: "#E91E63"  # BeautyGlow pink color
  
  # Windows icons
  windows:
    generate: true
    image_path: "assets/images/logo.png"
    icon_size: 48
  
  # macOS icons
  macos:
    generate: true
    image_path: "assets/images/logo.png"
```

### Run Icon Generation

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## 📝 Method 3: Manual Icon Creation

### PowerShell Script for Batch Resizing

Create `generate_icons.ps1`:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$SourceImage,
    
    [string]$OutputDir = "generated_icons"
)

# Requires ImageMagick to be installed
if (-not (Get-Command "magick" -ErrorAction SilentlyContinue)) {
    Write-Error "ImageMagick is required. Install from https://imagemagick.org/"
    exit 1
}

Write-Host "Generating icons from $SourceImage" -ForegroundColor Green

# Create output directory
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Android icon sizes
$AndroidSizes = @{
    "mdpi" = 48
    "hdpi" = 72
    "xhdpi" = 96
    "xxhdpi" = 144
    "xxxhdpi" = 192
}

Write-Host "Generating Android icons..." -ForegroundColor Yellow
foreach ($density in $AndroidSizes.Keys) {
    $size = $AndroidSizes[$density]
    $output = "$OutputDir/android_$density" + "_$size" + "x$size.png"
    magick $SourceImage -resize "${size}x${size}" $output
    Write-Host "✓ Created $output" -ForegroundColor Green
}

# iOS icon sizes
$iOSSizes = @(20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024)

Write-Host "Generating iOS icons..." -ForegroundColor Yellow
foreach ($size in $iOSSizes) {
    $output = "$OutputDir/ios_${size}x${size}.png"
    magick $SourceImage -resize "${size}x${size}" $output
    Write-Host "✓ Created $output" -ForegroundColor Green
}

# Web icon sizes
$WebSizes = @(16, 32, 192, 512)

Write-Host "Generating Web icons..." -ForegroundColor Yellow
foreach ($size in $WebSizes) {
    $output = "$OutputDir/web_${size}x${size}.png"
    magick $SourceImage -resize "${size}x${size}" $output
    Write-Host "✓ Created $output" -ForegroundColor Green
}

Write-Host "Icon generation completed! Check $OutputDir folder." -ForegroundColor Green
```

### Bash Script for Icon Generation

Create `generate_icons.sh`:

```bash
#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${RED}ImageMagick is required. Install it first:${NC}"
    echo -e "${YELLOW}Ubuntu/Debian: sudo apt-get install imagemagick${NC}"
    echo -e "${YELLOW}macOS: brew install imagemagick${NC}"
    exit 1
fi

# Check arguments
if [ $# -eq 0 ]; then
    echo -e "${RED}Usage: $0 <source_image> [output_directory]${NC}"
    echo -e "${YELLOW}Example: $0 my_logo.png generated_icons${NC}"
    exit 1
fi

SOURCE_IMAGE=$1
OUTPUT_DIR=${2:-"generated_icons"}

echo -e "${GREEN}Generating icons from $SOURCE_IMAGE${NC}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Android icon sizes
declare -A ANDROID_SIZES=(
    ["mdpi"]=48
    ["hdpi"]=72
    ["xhdpi"]=96
    ["xxhdpi"]=144
    ["xxxhdpi"]=192
)

echo -e "${YELLOW}Generating Android icons...${NC}"
for density in "${!ANDROID_SIZES[@]}"; do
    size=${ANDROID_SIZES[$density]}
    output="$OUTPUT_DIR/android_${density}_${size}x${size}.png"
    convert "$SOURCE_IMAGE" -resize "${size}x${size}" "$output"
    echo -e "${GREEN}✓ Created $output${NC}"
done

# iOS icon sizes
IOS_SIZES=(20 29 40 58 60 76 80 87 120 152 167 180 1024)

echo -e "${YELLOW}Generating iOS icons...${NC}"
for size in "${IOS_SIZES[@]}"; do
    output="$OUTPUT_DIR/ios_${size}x${size}.png"
    convert "$SOURCE_IMAGE" -resize "${size}x${size}" "$output"
    echo -e "${GREEN}✓ Created $output${NC}"
done

# Web icon sizes
WEB_SIZES=(16 32 192 512)

echo -e "${YELLOW}Generating Web icons...${NC}"
for size in "${WEB_SIZES[@]}"; do
    output="$OUTPUT_DIR/web_${size}x${size}.png"
    convert "$SOURCE_IMAGE" -resize "${size}x${size}" "$output"
    echo -e "${GREEN}✓ Created $output${NC}"
done

echo -e "${GREEN}Icon generation completed! Check $OUTPUT_DIR folder.${NC}"

# Show summary
echo -e "${YELLOW}Summary:${NC}"
echo "Android icons: ${#ANDROID_SIZES[@]} files"
echo "iOS icons: ${#IOS_SIZES[@]} files"
echo "Web icons: ${#WEB_SIZES[@]} files"
echo "Total: $((${#ANDROID_SIZES[@]} + ${#IOS_SIZES[@]} + ${#WEB_SIZES[@]})) files"
```

## 🔄 Complete Icon Replacement Script

### PowerShell Script for Complete Replacement

Create `replace_app_icons.ps1`:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$SourceImage,
    
    [string]$ProjectRoot = "."
)

# Verify source image exists
if (-not (Test-Path $SourceImage)) {
    Write-Error "Source image not found: $SourceImage"
    exit 1
}

Write-Host "Replacing all app icons with $SourceImage" -ForegroundColor Green

# Generate all required sizes
Write-Host "Step 1: Generating icon files..." -ForegroundColor Yellow
.\generate_icons.ps1 -SourceImage $SourceImage -OutputDir "temp_icons"

# Android icons
Write-Host "Step 2: Replacing Android icons..." -ForegroundColor Yellow
$AndroidMapping = @{
    "temp_icons/android_mdpi_48x48.png" = "android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
    "temp_icons/android_hdpi_72x72.png" = "android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
    "temp_icons/android_xhdpi_96x96.png" = "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
    "temp_icons/android_xxhdpi_144x144.png" = "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
    "temp_icons/android_xxxhdpi_192x192.png" = "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
}

foreach ($source in $AndroidMapping.Keys) {
    $dest = Join-Path $ProjectRoot $AndroidMapping[$source]
    if (Test-Path $source) {
        Copy-Item $source $dest -Force
        Write-Host "✓ Replaced $dest" -ForegroundColor Green
    }
}

# iOS icons
Write-Host "Step 3: Replacing iOS icons..." -ForegroundColor Yellow
$iOSMapping = @{
    "temp_icons/ios_20x20.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png"
    "temp_icons/ios_40x40.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png"
    "temp_icons/ios_60x60.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png"
    "temp_icons/ios_29x29.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png"
    "temp_icons/ios_58x58.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png"
    "temp_icons/ios_87x87.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png"
    "temp_icons/ios_40x40.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png"
    "temp_icons/ios_80x80.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png"
    "temp_icons/ios_120x120.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png"
    "temp_icons/ios_120x120.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"
    "temp_icons/ios_180x180.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png"
    "temp_icons/ios_76x76.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png"
    "temp_icons/ios_152x152.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"
    "temp_icons/ios_167x167.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"
    "temp_icons/ios_1024x1024.png" = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
}

foreach ($source in $iOSMapping.Keys) {
    $dest = Join-Path $ProjectRoot $iOSMapping[$source]
    if (Test-Path $source) {
        Copy-Item $source $dest -Force
        Write-Host "✓ Replaced $dest" -ForegroundColor Green
    }
}

# Web icons
Write-Host "Step 4: Replacing Web icons..." -ForegroundColor Yellow
$WebMapping = @{
    "temp_icons/web_16x16.png" = "web/favicon.png"
    "temp_icons/web_192x192.png" = "web/icons/Icon-192.png"
    "temp_icons/web_512x512.png" = "web/icons/Icon-512.png"
    "temp_icons/web_192x192.png" = "web/icons/Icon-maskable-192.png"
    "temp_icons/web_512x512.png" = "web/icons/Icon-maskable-512.png"
}

foreach ($source in $WebMapping.Keys) {
    $dest = Join-Path $ProjectRoot $WebMapping[$source]
    if (Test-Path $source) {
        Copy-Item $source $dest -Force
        Write-Host "✓ Replaced $dest" -ForegroundColor Green
    }
}

# Clean up temporary files
Write-Host "Step 5: Cleaning up..." -ForegroundColor Yellow
Remove-Item "temp_icons" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✓ Cleanup completed" -ForegroundColor Green

Write-Host "All app icons have been replaced successfully!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run: flutter clean" -ForegroundColor White
Write-Host "2. Run: flutter pub get" -ForegroundColor White
Write-Host "3. Test on all platforms" -ForegroundColor White
```

## 🎯 BeautyGlow Specific Implementation

### Current Icon Structure
```
BeautyGlow/
├── beautyglow/assets/images/logo.png    (Source logo)
├── android/app/src/main/res/
│   ├── mipmap-hdpi/ic_launcher.png
│   ├── mipmap-mdpi/ic_launcher.png
│   ├── mipmap-xhdpi/ic_launcher.png
│   ├── mipmap-xxhdpi/ic_launcher.png
│   └── mipmap-xxxhdpi/ic_launcher.png
└── ios/Runner/Assets.xcassets/AppIcon.appiconset/
    └── [All iOS icon files]
```

### BeautyGlow Icon Generation Command
```bash
# Navigate to project
cd BeautyGlow/beautyglow

# Using flutter_launcher_icons (recommended)
flutter pub run flutter_launcher_icons

# Or using custom script
.\replace_app_icons.ps1 -SourceImage "assets\images\logo.png"
```

## 🧪 Testing Icon Changes

### Visual Verification
```bash
# Build and install on device
flutter build apk --debug
flutter install

# Check launcher icon on device
# Check app switcher/recent apps
# Check settings > apps menu
```

### Platform Testing
```bash
# Test Android
flutter build apk
flutter build appbundle

# Test iOS (requires macOS)
flutter build ios

# Test Web
flutter build web

# Test Windows
flutter build windows

# Test macOS (requires macOS)
flutter build macos

# Test Linux
flutter build linux
```

## ⚠️ Common Issues & Solutions

### Issue 1: Icons Not Updating
```
Problem: Old icons still showing after replacement
```

**Solution**:
```bash
# Clear app cache
flutter clean
flutter pub get

# Uninstall app completely
adb uninstall com.beauty.beautyglow

# Rebuild and install
flutter build apk --debug
flutter install
```

### Issue 2: iOS Icons Not Showing
```
Problem: iOS shows default icon or blank icon
```

**Solution**: Verify Contents.json in iOS AppIcon.appiconset:
```json
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20",
      "filename" : "Icon-App-20x20@2x.png"
    },
    // ... more entries
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

### Issue 3: Adaptive Icons Not Working (Android)
```
Problem: Adaptive icons not displaying properly
```

**Solution**: Create adaptive icon XML:
```xml
<!-- android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml -->
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
```

### Issue 4: Web Icons Not Loading
```
Problem: Web favicon or PWA icons not showing
```

**Solution**: Update web/manifest.json:
```json
{
  "name": "BeautyGlow",
  "short_name": "BeautyGlow",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#E91E63",
  "description": "Beauty routine tracking app",
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
    }
  ]
}
```

## 📋 Icon Design Best Practices

### Design Guidelines
- **Simplicity**: Clear, recognizable at small sizes
- **Contrast**: Good contrast against various backgrounds
- **Platform Consistency**: Follow iOS/Android design guidelines
- **Scalability**: Vector-based designs work best
- **Brand Identity**: Consistent with app branding

### Technical Requirements
- **Source Size**: Start with 1024×1024 minimum
- **Format**: PNG with transparency
- **Color Space**: RGB
- **Quality**: High resolution, no compression artifacts
- **Background**: Transparent or solid color

### BeautyGlow Icon Specifications
```
Brand Colors:
- Primary Pink: #E91E63
- Primary Purple: #9C27B0
- Background: #FFFFFF

Design Elements:
- Beauty/cosmetic theme
- Clean, modern aesthetic
- Recognizable beauty symbol
- Good contrast on light/dark backgrounds
```

## 📋 Verification Checklist

### Pre-Generation:
- [ ] Source image is 1024×1024 or larger
- [ ] Image has good contrast and clarity
- [ ] Design works at small sizes
- [ ] Backup existing icons

### During Generation:
- [ ] All required sizes generated
- [ ] No errors in generation process
- [ ] Icons look correct at different sizes
- [ ] Transparency preserved where needed

### Post-Generation:
- [ ] Flutter clean and rebuild
- [ ] Test on Android device/emulator
- [ ] Test on iOS device/simulator (if available)
- [ ] Test web favicon
- [ ] Check app launcher grid
- [ ] Verify app switcher/recent apps
- [ ] Test different device themes
- [ ] Submit test build for approval

This comprehensive guide ensures consistent and professional icon implementation across all platforms in your Flutter application. 