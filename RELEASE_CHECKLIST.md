# Release Checklist for Google Play Store

## 📋 Pre-Release Checklist

### ✅ App Configuration
- [ ] Updated `applicationId` to `com.wia.prayer_app`
- [ ] Set proper `versionCode` and `versionName` in pubspec.yaml
- [ ] Updated app description in pubspec.yaml
- [ ] Configured release signing in build.gradle
- [ ] Created and secured signing key

### ✅ Testing
- [ ] Tested release build on multiple devices
- [ ] Verified all prayer notifications work correctly
- [ ] Confirmed Qibla compass accuracy
- [ ] Tested home widgets functionality
- [ ] Verified location permissions
- [ ] Tested offline functionality
- [ ] Checked app performance and memory usage

### ✅ Assets Created
- [ ] App icon (512x512 for Play Store)
- [ ] App icons for all densities (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- [ ] Feature graphic (1024x500)
- [ ] 2-8 screenshots for different screen types
- [ ] Video preview (optional but recommended)

### ✅ Store Listing
- [ ] App title: "WIA Prayer Times"
- [ ] Short description (80 characters)
- [ ] Full description with features and benefits
- [ ] Privacy policy created and linked
- [ ] Content rating completed
- [ ] App category selected (Lifestyle)
- [ ] Tags and keywords optimized

### ✅ Legal & Compliance
- [ ] Privacy policy covers location data usage
- [ ] Terms of service (if applicable)
- [ ] Content rating questionnaire completed
- [ ] Age restriction set appropriately
- [ ] Compliance with Google Play policies

## 🚀 Build Commands

```powershell
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK for testing
flutter build apk --release

# Build App Bundle for Play Store upload
flutter build appbundle --release

# Test release build
flutter install --release
```

## 📱 Final File Locations

After successful build, find these files:
- **APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **AAB**: `build/app/outputs/bundle/release/app-release.aab`

Upload the `.aab` file to Google Play Console (recommended) or `.apk` if needed.

## 🔐 Security Notes

- Keep `key.properties` file secure and never commit to version control
- Store signing key (`wia-prayer-release-key.keystore`) in secure location
- Document keystore passwords securely
- Consider using Google Play App Signing for additional security

## 📊 Post-Launch Monitoring

After publishing, monitor:
- Download and install rates
- User reviews and ratings
- Crash reports and ANRs
- Performance metrics
- User feedback for feature requests

## 🔄 Update Process

For future updates:
1. Increment version code and name in pubspec.yaml
2. Test changes thoroughly
3. Build new app bundle
4. Upload to Play Console
5. Add release notes describing changes
6. Rollout gradually (staged rollout recommended)
