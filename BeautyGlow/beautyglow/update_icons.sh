#!/bin/bash

echo "🎨 BeautyGlow App Icon Update Script"
echo "====================================="
echo

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed"
    echo "Please install Python 3.6+ from https://python.org"
    exit 1
fi

# Check if requirements are installed
echo "📦 Checking dependencies..."
if ! python3 -c "import PIL" &> /dev/null; then
    echo "📥 Installing required dependencies..."
    pip3 install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install dependencies"
        exit 1
    fi
fi

echo "🚀 Running icon update script..."
python3 update_app_icons.py

if [ $? -ne 0 ]; then
    echo "❌ Script failed with errors"
    exit 1
fi

echo
echo "✅ Icon update completed successfully!"
echo
echo "💡 Next steps:"
echo "   1. Test the app on different devices"
echo "   2. Verify icons appear correctly in app stores"
echo "   3. Check notification icons in system tray"
echo "   4. Test splash screen appearance"
echo 