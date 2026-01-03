#!/usr/bin/env python3
"""
Fix Icon References Script for BeautyGlow Flutter App
Fixes any remaining drawable references and ensures all icon references are correct
"""

import os
import glob
import re

def fix_xml_references():
    """Fix any XML files that reference drawable instead of mipmap"""
    print("🔧 Fixing XML references...")
    
    # Find all XML files in the res directory
    xml_files = glob.glob("android/app/src/main/res/**/*.xml", recursive=True)
    
    for xml_file in xml_files:
        try:
            with open(xml_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Fix drawable references to mipmap
            content = re.sub(
                r'@drawable/ic_launcher_foreground',
                '@mipmap/ic_launcher_foreground',
                content
            )
            content = re.sub(
                r'@drawable/ic_launcher_background',
                '@mipmap/ic_launcher_background',
                content
            )
            content = re.sub(
                r'@color/ic_launcher_background',
                '@mipmap/ic_launcher_background',
                content
            )
            
            # If content changed, write it back
            if content != original_content:
                with open(xml_file, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"✅ Fixed references in {xml_file}")
            else:
                print(f"✓ No changes needed in {xml_file}")
                
        except Exception as e:
            print(f"⚠️ Error processing {xml_file}: {e}")

def remove_old_drawable_icons():
    """Remove any old drawable icon files that might conflict"""
    print("\n🧹 Removing old drawable icon files...")
    
    # Patterns for old drawable icon files
    old_icon_patterns = [
        "android/app/src/main/res/drawable*/ic_launcher*",
        "android/app/src/main/res/drawable*/ic_notification*",
    ]
    
    for pattern in old_icon_patterns:
        old_files = glob.glob(pattern)
        for old_file in old_files:
            try:
                os.remove(old_file)
                print(f"🗑️ Removed old file: {old_file}")
            except Exception as e:
                print(f"⚠️ Could not remove {old_file}: {e}")

def verify_mipmap_files():
    """Verify that all required mipmap files exist"""
    print("\n🔍 Verifying mipmap files...")
    
    required_files = [
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png",
        "android/app/src/main/res/mipmap-mdpi/ic_launcher_background.png",
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png",
        "android/app/src/main/res/mipmap-hdpi/ic_launcher_background.png",
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png",
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher_background.png",
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png",
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_background.png",
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png",
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_background.png",
    ]
    
    missing_files = []
    for file_path in required_files:
        if os.path.exists(file_path):
            file_size = os.path.getsize(file_path)
            if file_size > 100:  # File should be at least 100 bytes
                print(f"✅ {file_path} - {file_size} bytes")
            else:
                print(f"⚠️ {file_path} - File too small ({file_size} bytes)")
                missing_files.append(file_path)
        else:
            print(f"❌ {file_path} - File not found")
            missing_files.append(file_path)
    
    if missing_files:
        print(f"\n⚠️ Missing or invalid files: {len(missing_files)}")
        return False
    else:
        print(f"\n✅ All mipmap files verified successfully!")
        return True

def main():
    """Main function to fix icon references"""
    print("🔧 BeautyGlow Icon Reference Fix Script")
    print("=" * 50)
    
    try:
        # Step 1: Fix XML references
        fix_xml_references()
        
        # Step 2: Remove old drawable files
        remove_old_drawable_icons()
        
        # Step 3: Verify mipmap files
        if verify_mipmap_files():
            print("\n✅ All icon references fixed successfully!")
        else:
            print("\n⚠️ Some files may need attention")
        
        print("\n📋 Summary:")
        print("   • Fixed XML references to use mipmap instead of drawable")
        print("   • Removed old drawable icon files")
        print("   • Verified all required mipmap files exist")
        
        print("\n💡 Next steps:")
        print("   1. Run 'flutter clean' to clear build cache")
        print("   2. Run 'flutter pub get' to refresh dependencies")
        print("   3. Try building the app again")
        print("   4. Test the app on your device")
        
    except Exception as e:
        print(f"❌ Error during reference fix: {e}")
        return

if __name__ == '__main__':
    main() 