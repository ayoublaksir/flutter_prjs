# 🎨 BeautyGlow App Icon Update Script

This comprehensive Python script updates your app's logo/icon across all platforms and components of your Flutter app.

## 📋 What This Script Updates

### Android Icons
- **Launcher Icons**: `ic_launcher.png` in all mipmap folders
- **Notification Icons**: `ic_notification.png` in all drawable folders (circular)
- **Adaptive Icons**: `ic_launcher_foreground.png` and `ic_launcher_background.png`
- **Splash Screen**: `logo.png` in drawable folders

### iOS Icons
- **App Icons**: All required sizes from 20x20 to 1024x1024
- **Launch Images**: Splash screen images

### macOS Icons
- **App Icons**: All sizes from 16x16 to 1024x1024

### Web Icons
- **PWA Icons**: Standard and maskable icons for web app
- **Favicon**: Web browser icons

## 🚀 Quick Start

### Prerequisites
1. **Python 3.6+** installed on your system
2. **Pillow library** for image processing

### Installation
```bash
# Install required dependencies
pip install -r requirements.txt
```

### Usage
```bash
# Run the script from the beautyglow directory
python update_app_icons.py
```

## 📁 File Structure

The script expects this structure:
```
beautyglow/
├── assets/
│   └── images/
│       └── beautybglow-icon.jpg  # Your source logo
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── res/           # Android resources
├── ios/
│   └── Runner/
│       └── Assets.xcassets/       # iOS assets
├── macos/
│   └── Runner/
│       └── Assets.xcassets/       # macOS assets
├── web/
│   └── icons/                     # Web icons
└── update_app_icons.py            # This script
```

## 🎯 Icon Sizes Generated

### Android
| Density | Launcher Icon | Notification Icon |
|---------|---------------|-------------------|
| mdpi    | 48x48         | 24x24            |
| hdpi    | 72x72         | 36x36            |
| xhdpi   | 96x96         | 48x48            |
| xxhdpi  | 144x144       | 72x72            |
| xxxhdpi | 192x192       | 96x96            |

### iOS
| Filename | Size | Use |
|----------|------|-----|
| Icon-App-20x20@1x.png | 20x20 | Settings, Spotlight |
| Icon-App-29x29@1x.png | 29x29 | Settings |
| Icon-App-40x40@1x.png | 40x40 | Spotlight |
| Icon-App-60x60@2x.png | 120x120 | App Store, Home Screen |
| Icon-App-60x60@3x.png | 180x180 | App Store, Home Screen |
| Icon-App-1024x1024@1x.png | 1024x1024 | App Store |

### macOS
| Filename | Size |
|----------|------|
| app_icon_16.png | 16x16 |
| app_icon_32.png | 32x32 |
| app_icon_128.png | 128x128 |
| app_icon_256.png | 256x256 |
| app_icon_512.png | 512x512 |
| app_icon_1024.png | 1024x1024 |

### Web
| Filename | Size | Use |
|----------|------|-----|
| Icon-192.png | 192x192 | PWA icon |
| Icon-512.png | 512x512 | PWA icon |
| Icon-maskable-192.png | 192x192 | PWA maskable icon |
| Icon-maskable-512.png | 512x512 | PWA maskable icon |

## 🔧 Customization

### Change Source Image
Edit the `SOURCE_IMAGE` variable in the script:
```python
SOURCE_IMAGE = 'assets/images/your-new-logo.png'
```

### Modify Icon Sizes
Update the size dictionaries in the script:
```python
ANDROID_MIPMAP_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    # ... add or modify sizes
}
```

### Custom Background Colors
For adaptive icons, modify the background color:
```python
# In create_adaptive_icon function
background = Image.new('RGBA', (background_size, background_size), (255, 255, 255, 255))
# Change to your preferred color: (R, G, B, A)
```

## ✅ Verification Checklist

After running the script, verify:

### Android
- [ ] App icon appears correctly on home screen
- [ ] Notification icon shows properly in system tray
- [ ] Splash screen displays the logo
- [ ] Adaptive icon works on different Android versions

### iOS
- [ ] App icon appears on home screen
- [ ] Settings icon shows correctly
- [ ] Spotlight search icon is visible
- [ ] App Store icon displays properly

### macOS
- [ ] App icon appears in Applications folder
- [ ] Dock icon displays correctly
- [ ] App switcher shows proper icon

### Web
- [ ] PWA icon appears when installed
- [ ] Favicon shows in browser tabs
- [ ] Maskable icons work on different devices

## 🐛 Troubleshooting

### Common Issues

1. **"Source image not found"**
   - Ensure your logo file exists at `assets/images/beautybglow-icon.jpg`
   - Check file permissions

2. **"Permission denied"**
   - Make sure you have write permissions to the project directories
   - Run with appropriate user privileges

3. **"PIL not found"**
   - Install Pillow: `pip install Pillow`
   - Or use: `pip install -r requirements.txt`

4. **Icons appear blurry**
   - Use a high-resolution source image (at least 1024x1024)
   - Ensure the source image is square

5. **iOS icons not updating**
   - Clean and rebuild the iOS project
   - Delete derived data in Xcode

### Debug Mode
Add debug prints to see what's happening:
```python
# Add this at the top of the script
import logging
logging.basicConfig(level=logging.DEBUG)
```

## 🔄 Updating Icons Regularly

### Automated Workflow
1. Replace `assets/images/beautybglow-icon.jpg` with your new logo
2. Run `python update_app_icons.py`
3. Test on different devices
4. Commit changes to version control

### Version Control
```bash
# Add updated icons to git
git add android/app/src/main/res/
git add ios/Runner/Assets.xcassets/
git add macos/Runner/Assets.xcassets/
git add web/icons/
git commit -m "Update app icons with new logo"
```

## 📱 Platform-Specific Notes

### Android
- Adaptive icons require both foreground and background layers
- Notification icons are automatically made circular
- Different densities ensure proper scaling on all devices

### iOS
- All icons must be square (no transparency for App Store)
- Different sizes for different contexts (Settings, Spotlight, etc.)
- Launch images should match your app's theme

### macOS
- Icons support transparency
- Multiple sizes for different display densities
- Dock icons should be visually distinct

### Web
- PWA icons should work well at small sizes
- Maskable icons adapt to different shapes
- Favicon should be recognizable at 16x16

## 🎨 Design Tips

1. **Use a square source image** (1024x1024 recommended)
2. **Keep it simple** - icons should be recognizable at small sizes
3. **Test on actual devices** - what looks good on screen may not work on device
4. **Consider your brand colors** - ensure good contrast
5. **Avoid text** in icons - it becomes unreadable at small sizes

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify your file structure matches the expected layout
3. Ensure all dependencies are installed
4. Test with a simple image first

---

**Happy icon updating! 🎉** 