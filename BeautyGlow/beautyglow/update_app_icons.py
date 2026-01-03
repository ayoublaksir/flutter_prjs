#!/usr/bin/env python3
"""
Comprehensive App Icon Update Script for BeautyGlow Flutter App
Updates icons across all platforms: Android, iOS, macOS, and web
"""

import os
import shutil
from PIL import Image, ImageDraw, ImageFont
import json

# Source logo path - using the existing beautybglow-icon.jpg
SOURCE_IMAGE = 'assets/images/beautybglow-icon.jpg'

# Android mipmap folders and their required icon sizes
ANDROID_MIPMAP_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

# Android drawable folders for notification icons
ANDROID_DRAWABLE_SIZES = {
    'drawable-mdpi': 24,
    'drawable-hdpi': 36,
    'drawable-xhdpi': 48,
    'drawable-xxhdpi': 72,
    'drawable-xxxhdpi': 96,
}

# iOS App Icon sizes
IOS_ICON_SIZES = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-50x50@1x.png': 50,
    'Icon-App-50x50@2x.png': 100,
    'Icon-App-57x57@1x.png': 57,
    'Icon-App-57x57@2x.png': 114,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-72x72@1x.png': 72,
    'Icon-App-72x72@2x.png': 144,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
}

# macOS App Icon sizes
MACOS_ICON_SIZES = {
    'app_icon_16.png': 16,
    'app_icon_32.png': 32,
    'app_icon_64.png': 64,
    'app_icon_128.png': 128,
    'app_icon_256.png': 256,
    'app_icon_512.png': 512,
    'app_icon_1024.png': 1024,
}

# Web icons
WEB_ICON_SIZES = {
    'Icon-192.png': 192,
    'Icon-512.png': 512,
    'Icon-maskable-192.png': 192,
    'Icon-maskable-512.png': 512,
}

# Directories
ANDROID_RES_DIR = 'android/app/src/main/res'
IOS_ICON_DIR = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
MACOS_ICON_DIR = 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
WEB_ICON_DIR = 'web/icons'

def create_circular_mask(size):
    """Create a circular mask for the icon"""
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, size, size), fill=255)
    return mask

def resize_and_save_icon(source_img, output_path, size, make_circular=False):
    """Resize and save icon with optional circular mask"""
    try:
        # Resize the image
        resized = source_img.resize((size, size), Image.LANCZOS)
        
        if make_circular:
            # Create circular mask
            mask = create_circular_mask(size)
            # Create a new image with alpha channel
            output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
            output.paste(resized, (0, 0))
            output.putalpha(mask)
        else:
            output = resized
        
        # Ensure output directory exists
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # Save the image
        output.save(output_path, format='PNG', optimize=True)
        print(f"✓ Saved {output_path} ({size}x{size})")
        return True
    except Exception as e:
        print(f"✗ Error saving {output_path}: {e}")
        return False

def update_android_icons(source_img):
    """Update Android launcher and notification icons"""
    print("\n🔄 Updating Android Icons...")
    
    # Update launcher icons
    for folder, size in ANDROID_MIPMAP_SIZES.items():
        out_dir = os.path.join(ANDROID_RES_DIR, folder)
        out_path = os.path.join(out_dir, 'ic_launcher.png')
        resize_and_save_icon(source_img, out_path, size)
    
    # Update notification icons
    for folder, size in ANDROID_DRAWABLE_SIZES.items():
        out_dir = os.path.join(ANDROID_RES_DIR, folder)
        out_path = os.path.join(out_dir, 'ic_notification.png')
        resize_and_save_icon(source_img, out_path, size, make_circular=True)

def update_ios_icons(source_img):
    """Update iOS app icons"""
    print("\n🔄 Updating iOS Icons...")
    
    for filename, size in IOS_ICON_SIZES.items():
        out_path = os.path.join(IOS_ICON_DIR, filename)
        resize_and_save_icon(source_img, out_path, size)

def update_macos_icons(source_img):
    """Update macOS app icons"""
    print("\n🔄 Updating macOS Icons...")
    
    for filename, size in MACOS_ICON_SIZES.items():
        out_path = os.path.join(MACOS_ICON_DIR, filename)
        resize_and_save_icon(source_img, out_path, size)

def update_web_icons(source_img):
    """Update web icons"""
    print("\n🔄 Updating Web Icons...")
    
    for filename, size in WEB_ICON_SIZES.items():
        out_path = os.path.join(WEB_ICON_DIR, filename)
        resize_and_save_icon(source_img, out_path, size)

def update_splash_screen_icons(source_img):
    """Update splash screen related icons"""
    print("\n🔄 Updating Splash Screen Icons...")
    
    # Update logo.png in drawable folders
    for folder, size in ANDROID_DRAWABLE_SIZES.items():
        out_dir = os.path.join(ANDROID_RES_DIR, folder)
        out_path = os.path.join(out_dir, 'logo.png')
        resize_and_save_icon(source_img, out_path, size)
    
    # Update iOS launch image
    ios_launch_dir = 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    ios_launch_path = os.path.join(ios_launch_dir, 'LaunchImage.png')
    if os.path.exists(ios_launch_dir):
        resize_and_save_icon(source_img, ios_launch_path, 1024)

def create_adaptive_icon(source_img):
    """Create adaptive icon for Android (foreground and background)"""
    print("\n🔄 Creating Android Adaptive Icons...")
    
    # Create foreground icon (foreground layer)
    foreground_size = 108  # Standard adaptive icon foreground size
    foreground = source_img.resize((foreground_size, foreground_size), Image.LANCZOS)
    
    # Create background (solid color or gradient)
    background_size = 108
    background = Image.new('RGBA', (background_size, background_size), (255, 255, 255, 255))
    
    # Save adaptive icon components
    for density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']:
        folder = f'mipmap-{density}'
        out_dir = os.path.join(ANDROID_RES_DIR, folder)
        
        # Save foreground
        foreground_path = os.path.join(out_dir, 'ic_launcher_foreground.png')
        resize_and_save_icon(foreground, foreground_path, foreground_size)
        
        # Save background
        background_path = os.path.join(out_dir, 'ic_launcher_background.png')
        resize_and_save_icon(background, background_path, background_size)

def main():
    """Main function to update all app icons"""
    print("🎨 BeautyGlow App Icon Update Script")
    print("=" * 50)
    
    # Check if source image exists
    if not os.path.exists(SOURCE_IMAGE):
        print(f"❌ Source image not found: {SOURCE_IMAGE}")
        print("Please ensure the source image exists at the specified path.")
        return
    
    try:
        # Open and convert source image
        print(f"📸 Loading source image: {SOURCE_IMAGE}")
        source_img = Image.open(SOURCE_IMAGE).convert('RGBA')
        
        # Update all icon types
        update_android_icons(source_img)
        update_ios_icons(source_img)
        update_macos_icons(source_img)
        update_web_icons(source_img)
        update_splash_screen_icons(source_img)
        create_adaptive_icon(source_img)
        
        print("\n✅ All app icons have been updated successfully!")
        print("\n📋 Summary of updates:")
        print("   • Android launcher icons (mipmap folders)")
        print("   • Android notification icons (drawable folders)")
        print("   • iOS app icons (all sizes)")
        print("   • macOS app icons (all sizes)")
        print("   • Web icons (PWA support)")
        print("   • Splash screen logos")
        print("   • Android adaptive icons")
        
        print("\n💡 Next steps:")
        print("   1. Test the app on different devices")
        print("   2. Verify icons appear correctly in app stores")
        print("   3. Check notification icons in system tray")
        print("   4. Test splash screen appearance")
        
    except Exception as e:
        print(f"❌ Error during icon update: {e}")
        return

if __name__ == '__main__':
    main()
