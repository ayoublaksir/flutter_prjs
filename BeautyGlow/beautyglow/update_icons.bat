@echo off
echo 🎨 BeautyGlow App Icon Update Script
echo =====================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed or not in PATH
    echo Please install Python 3.6+ from https://python.org
    pause
    exit /b 1
)

REM Check if requirements are installed
echo 📦 Checking dependencies...
pip show Pillow >nul 2>&1
if errorlevel 1 (
    echo 📥 Installing required dependencies...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo ❌ Failed to install dependencies
        pause
        exit /b 1
    )
)

echo 🚀 Running icon update script...
python update_app_icons.py

if errorlevel 1 (
    echo ❌ Script failed with errors
    pause
    exit /b 1
)

echo.
echo ✅ Icon update completed successfully!
echo.
echo 💡 Next steps:
echo    1. Test the app on different devices
echo    2. Verify icons appear correctly in app stores
echo    3. Check notification icons in system tray
echo    4. Test splash screen appearance
echo.
pause 