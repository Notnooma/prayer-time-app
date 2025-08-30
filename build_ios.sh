#!/bin/bash
# Build script for iOS App Store deployment

echo "🍎 Building WIA Prayer App for iOS App Store..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build iOS release
echo "🔨 Building iOS release..."
flutter build ios --release --no-codesign

echo "✅ iOS build completed!"
echo ""
echo "Next steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Set your Team and Bundle Identifier"
echo "3. Archive and upload to App Store Connect"
