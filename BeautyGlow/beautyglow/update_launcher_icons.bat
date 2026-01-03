@echo off
echo 🎨 BeautyGlow Launcher Icon Update Script
echo ================================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed or not in PATH
    echo Please install Python and try again
    pause
    exit /b 1
)

REM Check if source image exists
if not exist "assets\images\beautybglow-icon.jpg" (
    echo ❌ Source image not found: assets\images\beautybglow-icon.jpg
    echo Please ensure the source image exists
    pause
    exit /b 1
)

echo ✅ Python found and source image exists
echo.

REM Run the launcher icon update script
echo 🚀 Running launcher icon update...
python update_launcher_icons.py

if errorlevel 1 (
    echo.
    echo ❌ Launcher icon update failed
    pause
    exit /b 1
)

echo.
echo ✅ Launcher icon update completed successfully!
echo.
echo 📋 Next steps:
echo    1. Run clean_and_rebuild.bat to rebuild the app
echo    2. Install the APK on your device
echo    3. Check if the new logo appears
echo.
pause 