#!/usr/bin/env python3
"""
Flutter Clean and Rebuild Script for BeautyGlow App
Ensures icon changes take effect by cleaning and rebuilding the project
"""

import os
import subprocess
import sys

def run_command(command, description):
    """Run a command and handle errors"""
    print(f"\n🔄 {description}...")
    print(f"Command: {command}")
    
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            cwd=os.getcwd()
        )
        
        if result.returncode == 0:
            print(f"✅ {description} completed successfully")
            if result.stdout:
                print(f"Output: {result.stdout}")
        else:
            print(f"❌ {description} failed")
            print(f"Error: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Error running {description}: {e}")
        return False
    
    return True

def check_flutter_installation():
    """Check if Flutter is installed and accessible"""
    print("🔍 Checking Flutter installation...")
    
    try:
        result = subprocess.run(
            "flutter --version",
            shell=True,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print("✅ Flutter is installed and accessible")
            print(f"Flutter version: {result.stdout.split('Flutter')[1].split('•')[0].strip()}")
            return True
        else:
            print("❌ Flutter is not accessible")
            return False
            
    except Exception as e:
        print(f"❌ Error checking Flutter: {e}")
        return False

def main():
    """Main function to clean and rebuild the Flutter project"""
    print("🧹 BeautyGlow Flutter Clean and Rebuild Script")
    print("=" * 50)
    
    # Check if we're in the right directory
    if not os.path.exists("pubspec.yaml"):
        print("❌ pubspec.yaml not found. Please run this script from the Flutter project root.")
        return
    
    # Check Flutter installation
    if not check_flutter_installation():
        print("❌ Flutter is not properly installed. Please install Flutter first.")
        return
    
    print("\n🚀 Starting clean and rebuild process...")
    
    # Step 1: Flutter clean
    if not run_command("flutter clean", "Cleaning Flutter project"):
        print("❌ Clean failed, but continuing...")
    
    # Step 2: Get dependencies
    if not run_command("flutter pub get", "Getting dependencies"):
        print("❌ Getting dependencies failed")
        return
    
    # Step 3: Clean Android build
    if not run_command("cd android && ./gradlew clean", "Cleaning Android build"):
        print("⚠️ Android clean failed, but continuing...")
    
    # Step 4: Build for Android
    print("\n📱 Building for Android...")
    if not run_command("flutter build apk --debug", "Building Android APK"):
        print("❌ Android build failed")
        return
    
    # Step 5: Check if APK was created
    apk_path = "build/app/outputs/flutter-apk/app-debug.apk"
    if os.path.exists(apk_path):
        apk_size = os.path.getsize(apk_path) / (1024 * 1024)  # Convert to MB
        print(f"✅ APK created successfully: {apk_path}")
        print(f"📦 APK size: {apk_size:.2f} MB")
    else:
        print("⚠️ APK not found at expected location")
    
    print("\n✅ Clean and rebuild completed!")
    print("\n📋 Next steps:")
    print("   1. Install the APK on your device")
    print("   2. Check if the new logo appears")
    print("   3. Test the app functionality")
    print("   4. Verify banner ads are working")
    
    print(f"\n📱 To install the APK:")
    print(f"   adb install {apk_path}")

if __name__ == '__main__':
    main() 