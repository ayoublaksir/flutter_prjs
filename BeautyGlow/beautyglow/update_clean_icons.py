#!/usr/bin/env python3
"""
Clean Icon Update Script for BeautyGlow Flutter App
Ensures crisp, clean logos without blur or flow issues
"""

import os
import shutil
from PIL import Image, ImageEnhance
import glob

# Source logo path
SOURCE_IMAGE = 'assets/images/beautybglow-icon.jpg'

# Android directories to update
ANDROID_DIRS = [
    'android/app/src/main/res/mipmap-mdpi',
    'android/app/src/main/res/mipmap-hdpi', 
    'android/app/src/main/res/mipmap-xhdpi',
    'android/app/src/main/res/mipmap-xxhdpi',
    'android/app/src/main/res/mipmap-xxxhdpi',
]

# Launcher icon sizes for each density
LAUNCHER_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

# Files to update in each directory
LAUNCHER_FILES = [
    'ic_launcher.png',
    'ic_launcher_foreground.png',
    'ic_launcher_background.png',
]

def enhance_image_quality(image, size):
    """Enhance image quality for crisp, clean appearance"""
    # Resize with high-quality algorithm
    resized = image.resize((size, size), Image.LANCZOS)
    
    # Enhance sharpness
    enhancer = ImageEnhance.Sharpness(resized)
    enhanced = enhancer.enhance(1.2)  # Slightly increase sharpness
    
    # Enhance contrast slightly
    contrast_enhancer = ImageEnhance.Contrast(enhanced)
    enhanced = contrast_enhancer.enhance(1.1)
    
    return enhanced

def create_clean_icon(source_img, size, is_foreground=True):
    """Create a clean, crisp icon at the specified size"""
    if is_foreground:
        # For foreground, use the source image with enhancements
        return enhance_image_quality(source_img, size)
    else:
        # For background, create a clean white background
        background = Image.new('RGBA', (size, size), (255, 255, 255, 255))
        return background

def update_launcher_icons():
    """Update all launcher icons with clean, crisp logos"""
    print("🔄 Updating Launcher Icons with Clean Quality...")
    
    if not os.path.exists(SOURCE_IMAGE):
        print(f"❌ Source image not found: {SOURCE_IMAGE}")
        return False
    
    try:
        # Load source image with high quality
        source_img = Image.open(SOURCE_IMAGE).convert('RGBA')
        print(f"✅ Loaded source image: {SOURCE_IMAGE}")
        
        # Update each density directory
        for android_dir in ANDROID_DIRS:
            if not os.path.exists(android_dir):
                print(f"⚠️ Directory not found: {android_dir}")
                continue
                
            density = os.path.basename(android_dir)
            size = LAUNCHER_SIZES.get(density, 48)
            
            print(f"\n📱 Updating {density} ({size}x{size}) with clean quality...")
            
            # Update each launcher file
            for file_name in LAUNCHER_FILES:
                file_path = os.path.join(android_dir, file_name)
                
                if file_name == 'ic_launcher.png':
                    # Main launcher icon - use enhanced source image
                    clean_icon = create_clean_icon(source_img, size, is_foreground=True)
                    clean_icon.save(file_path, format='PNG', optimize=True, quality=95)
                    print(f"✓ Updated {file_path} ({size}x{size}) with clean quality")
                    
                elif file_name == 'ic_launcher_foreground.png':
                    # Foreground icon - use enhanced source image
                    clean_icon = create_clean_icon(source_img, size, is_foreground=True)
                    clean_icon.save(file_path, format='PNG', optimize=True, quality=95)
                    print(f"✓ Updated {file_path} ({size}x{size}) with clean quality")
                    
                elif file_name == 'ic_launcher_background.png':
                    # Background icon - create clean white background
                    clean_background = create_clean_icon(source_img, size, is_foreground=False)
                    clean_background.save(file_path, format='PNG', optimize=True, quality=95)
                    print(f"✓ Updated {file_path} ({size}x{size}) with clean background")
        
        return True
        
    except Exception as e:
        print(f"❌ Error updating launcher icons: {e}")
        return False

def update_splash_logos():
    """Update splash screen logos with clean quality"""
    print("\n🔄 Updating Splash Screen Logos...")
    
    if not os.path.exists(SOURCE_IMAGE):
        print(f"❌ Source image not found: {SOURCE_IMAGE}")
        return False
    
    try:
        source_img = Image.open(SOURCE_IMAGE).convert('RGBA')
        
        # Splash logo sizes for different densities
        splash_sizes = {
            'drawable-mdpi': 24,
            'drawable-hdpi': 36,
            'drawable-xhdpi': 48,
            'drawable-xxhdpi': 72,
            'drawable-xxxhdpi': 96,
        }
        
        for density, size in splash_sizes.items():
            logo_path = f"android/app/src/main/res/{density}/logo.png"
            if os.path.exists(os.path.dirname(logo_path)):
                # Create clean splash logo
                clean_logo = create_clean_icon(source_img, size, is_foreground=True)
                clean_logo.save(logo_path, format='PNG', optimize=True, quality=95)
                print(f"✓ Updated splash logo: {logo_path} ({size}x{size})")
        
        return True
        
    except Exception as e:
        print(f"❌ Error updating splash logos: {e}")
        return False

def update_notification_icons():
    """Update notification icons with clean quality"""
    print("\n🔄 Updating Notification Icons...")
    
    if not os.path.exists(SOURCE_IMAGE):
        print(f"❌ Source image not found: {SOURCE_IMAGE}")
        return False
    
    try:
        source_img = Image.open(SOURCE_IMAGE).convert('RGBA')
        
        # Notification icon sizes
        notification_sizes = {
            'drawable-hdpi': 36,
            'drawable-xhdpi': 48,
            'drawable-xxhdpi': 72,
            'drawable-xxxhdpi': 96,
        }
        
        for density, size in notification_sizes.items():
            icon_path = f"android/app/src/main/res/{density}/ic_notification.png"
            if os.path.exists(os.path.dirname(icon_path)):
                # Create clean notification icon
                clean_icon = create_clean_icon(source_img, size, is_foreground=True)
                clean_icon.save(icon_path, format='PNG', optimize=True, quality=95)
                print(f"✓ Updated notification icon: {icon_path} ({size}x{size})")
        
        return True
        
    except Exception as e:
        print(f"❌ Error updating notification icons: {e}")
        return False

def verify_clean_icons():
    """Verify that all icons have been updated with clean quality"""
    print("\n🔍 Verifying Clean Icon Updates...")
    
    total_files = 0
    updated_files = 0
    
    for android_dir in ANDROID_DIRS:
        if not os.path.exists(android_dir):
            continue
            
        for file_name in LAUNCHER_FILES:
            file_path = os.path.join(android_dir, file_name)
            total_files += 1
            
            if os.path.exists(file_path):
                file_size = os.path.getsize(file_path)
                if file_size > 1000:  # File should be at least 1KB
                    updated_files += 1
                    print(f"✅ {file_path} - {file_size} bytes (clean quality)")
                else:
                    print(f"❌ {file_path} - File too small ({file_size} bytes)")
            else:
                print(f"⚠️ {file_path} - File not found")
    
    print(f"\n📊 Clean Icon Update Summary:")
    print(f"   Total files: {total_files}")
    print(f"   Successfully updated: {updated_files}")
    print(f"   Success rate: {(updated_files/total_files)*100:.1f}%" if total_files > 0 else "N/A")
    
    return updated_files == total_files

def main():
    """Main function to update all icons with clean quality"""
    print("🎨 BeautyGlow Clean Icon Update Script")
    print("=" * 50)
    
    # Check if source image exists
    if not os.path.exists(SOURCE_IMAGE):
        print(f"❌ Source image not found: {SOURCE_IMAGE}")
        print("Please ensure the source image exists at the specified path.")
        return
    
    try:
        # Step 1: Update launcher icons with clean quality
        if not update_launcher_icons():
            print("❌ Failed to update launcher icons")
            return
        
        # Step 2: Update splash screen logos
        if not update_splash_logos():
            print("❌ Failed to update splash logos")
            return
        
        # Step 3: Update notification icons
        if not update_notification_icons():
            print("❌ Failed to update notification icons")
            return
        
        # Step 4: Verify updates
        if verify_clean_icons():
            print("\n✅ All icons updated with clean quality successfully!")
        else:
            print("\n⚠️ Some icons may not have been updated properly")
        
        print("\n📋 Summary of clean updates:")
        print("   • Android launcher icons (all densities)")
        print("   • Splash screen logos")
        print("   • Notification icons")
        print("   • Enhanced image quality with sharpness and contrast")
        
        print("\n💡 Next steps:")
        print("   1. Clean and rebuild your Flutter project")
        print("   2. Test the app on different devices")
        print("   3. Verify icons appear crisp and clean")
        print("   4. Check splash screen appearance")
        
    except Exception as e:
        print(f"❌ Error during clean icon update: {e}")
        return

if __name__ == '__main__':
    main() 