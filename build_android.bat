@echo off
REM Build script for Android Play Store deployment (Windows)

echo 🤖 Building WIA Prayer App for Android Play Store...

REM Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean
flutter pub get

REM Build Android App Bundle (recommended for Play Store)
echo 🔨 Building Android App Bundle...
flutter build appbundle --release

REM Also build APK for testing
echo 🔨 Building Android APK...
flutter build apk --release

echo ✅ Android builds completed!
echo.
echo Files created:
echo 📱 App Bundle: build\app\outputs\bundle\release\app-release.aab
echo 📦 APK: build\app\outputs\flutter-apk\app-release.apk
echo.
echo Next steps:
echo 1. Upload app-release.aab to Google Play Console
echo 2. Test app-release.apk on devices first

pause
