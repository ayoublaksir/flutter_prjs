#!/usr/bin/env python3
"""
Comprehensive Launcher Icon Update Script for BeautyGlow Flutter App
Specifically updates all ic_launcher files with the new logo
"""

import os
import shutil
from PIL import Image
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

def backup_original_files():
    """Create backup of original files before updating"""
    print("📦 Creating backup of original files...")
    
    backup_dir = "backup_original_icons"
    if not os.path.exists(backup_dir):
        os.makedirs(backup_dir)
    
    for android_dir in ANDROID_DIRS:
        if os.path.exists(android_dir):
            # Create backup subdirectory
            backup_subdir = os.path.join(backup_dir, os.path.basename(android_dir))
            if not os.path.exists(backup_subdir):
                os.makedirs(backup_subdir)
            
            # Backup all launcher files
            for file_name in LAUNCHER_FILES:
                original_path = os.path.join(android_dir, file_name)
                backup_path = os.path.join(backup_subdir, file_name)
                
                if os.path.exists(original_path):
                    shutil.copy2(original_path, backup_path)
                    print(f"✓ Backed up {original_path} -> {backup_path}")

def update_launcher_icons():
    """Update all launcher icons with the new logo"""
    print("\n🔄 Updating Launcher Icons...")
    
    if not os.path.exists(SOURCE_IMAGE):
        print(f"❌ Source image not found: {SOURCE_IMAGE}")
        return False
    
    try:
        # Load source image
        source_img = Image.open(SOURCE_IMAGE).convert('RGBA')
        print(f"✅ Loaded source image: {SOURCE_IMAGE}")
        
        # Update each density directory
        for android_dir in ANDROID_DIRS:
            if not os.path.exists(android_dir):
                print(f"⚠️ Directory not found: {android_dir}")
                continue
                
            density = os.path.basename(android_dir)
            size = LAUNCHER_SIZES.get(density, 48)
            
            print(f"\n📱 Updating {density} ({size}x{size})...")
            
            # Update each launcher file
            for file_name in LAUNCHER_FILES:
                file_path = os.path.join(android_dir, file_name)
                
                if file_name == 'ic_launcher.png':
                    # Main launcher icon - use the source image directly
                    resized = source_img.resize((size, size), Image.LANCZOS)
                    resized.save(file_path, format='PNG', optimize=True)
                    print(f"✓ Updated {file_path} ({size}x{size})")
                    
                elif file_name == 'ic_launcher_foreground.png':
                    # Foreground icon - use source image with transparency
                    resized = source_img.resize((size, size), Image.LANCZOS)
                    resized.save(file_path, format='PNG', optimize=True)
                    print(f"✓ Updated {file_path} ({size}x{size})")
                    
                elif file_name == 'ic_launcher_background.png':
                    # Background icon - create solid background
                    background = Image.new('RGBA', (size, size), (255, 255, 255, 255))
                    background.save(file_path, format='PNG', optimize=True)
                    print(f"✓ Updated {file_path} ({size}x{size})")
        
        return True
        
    except Exception as e:
        print(f"❌ Error updating launcher icons: {e}")
        return False

def update_adaptive_icons():
    """Update adaptive icon components"""
    print("\n🔄 Updating Adaptive Icons...")
    
    if not os.path.exists(SOURCE_IMAGE):
        print(f"❌ Source image not found: {SOURCE_IMAGE}")
        return False
    
    try:
        source_img = Image.open(SOURCE_IMAGE).convert('RGBA')
        
        # Adaptive icon foreground size (108dp)
        foreground_size = 108
        
        for android_dir in ANDROID_DIRS:
            if not os.path.exists(android_dir):
                continue
                
            # Update foreground
            foreground_path = os.path.join(android_dir, 'ic_launcher_foreground.png')
            foreground = source_img.resize((foreground_size, foreground_size), Image.LANCZOS)
            foreground.save(foreground_path, format='PNG', optimize=True)
            print(f"✓ Updated adaptive foreground: {foreground_path}")
            
            # Update background
            background_path = os.path.join(android_dir, 'ic_launcher_background.png')
            background = Image.new('RGBA', (foreground_size, foreground_size), (255, 255, 255, 255))
            background.save(background_path, format='PNG', optimize=True)
            print(f"✓ Updated adaptive background: {background_path}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error updating adaptive icons: {e}")
        return False

def verify_updates():
    """Verify that all launcher icons have been updated"""
    print("\n🔍 Verifying Updates...")
    
    total_files = 0
    updated_files = 0
    
    for android_dir in ANDROID_DIRS:
        if not os.path.exists(android_dir):
            continue
            
        for file_name in LAUNCHER_FILES:
            file_path = os.path.join(android_dir, file_name)
            total_files += 1
            
            if os.path.exists(file_path):
                # Check file size to ensure it's not empty
                file_size = os.path.getsize(file_path)
                if file_size > 1000:  # File should be at least 1KB
                    updated_files += 1
                    print(f"✅ {file_path} - {file_size} bytes")
                else:
                    print(f"❌ {file_path} - File too small ({file_size} bytes)")
            else:
                print(f"⚠️ {file_path} - File not found")
    
    print(f"\n📊 Update Summary:")
    print(f"   Total files: {total_files}")
    print(f"   Successfully updated: {updated_files}")
    print(f"   Success rate: {(updated_files/total_files)*100:.1f}%" if total_files > 0 else "N/A")
    
    return updated_files == total_files

def clean_old_icons():
    """Remove any old icon files that might conflict"""
    print("\n🧹 Cleaning Old Icons...")
    
    # List of old icon files that might exist
    old_icon_patterns = [
        'android/app/src/main/res/drawable*/ic_launcher*',
        'android/app/src/main/res/mipmap*/ic_launcher_old*',
        'android/app/src/main/res/mipmap*/ic_launcher_backup*',
    ]
    
    for pattern in old_icon_patterns:
        old_files = glob.glob(pattern)
        for old_file in old_files:
            try:
                os.remove(old_file)
                print(f"🗑️ Removed old file: {old_file}")
            except Exception as e:
                print(f"⚠️ Could not remove {old_file}: {e}")

def main():
    """Main function to update all launcher icons"""
    print("🎨 BeautyGlow Launcher Icon Update Script")
    print("=" * 50)
    
    # Check if source image exists
    if not os.path.exists(SOURCE_IMAGE):
        print(f"❌ Source image not found: {SOURCE_IMAGE}")
        print("Please ensure the source image exists at the specified path.")
        return
    
    try:
        # Step 1: Backup original files
        backup_original_files()
        
        # Step 2: Clean old icons
        clean_old_icons()
        
        # Step 3: Update launcher icons
        if not update_launcher_icons():
            print("❌ Failed to update launcher icons")
            return
        
        # Step 4: Update adaptive icons
        if not update_adaptive_icons():
            print("❌ Failed to update adaptive icons")
            return
        
        # Step 5: Verify updates
        if verify_updates():
            print("\n✅ All launcher icons updated successfully!")
        else:
            print("\n⚠️ Some icons may not have been updated properly")
        
        print("\n📋 Summary of updates:")
        print("   • Android launcher icons (all densities)")
        print("   • Adaptive icon foreground and background")
        print("   • Backup created in 'backup_original_icons' folder")
        
        print("\n💡 Next steps:")
        print("   1. Clean and rebuild your Flutter project")
        print("   2. Test the app on different devices")
        print("   3. Verify icons appear correctly in app stores")
        print("   4. Check launcher icons on home screen")
        
    except Exception as e:
        print(f"❌ Error during icon update: {e}")
        return

if __name__ == '__main__':
    main() 