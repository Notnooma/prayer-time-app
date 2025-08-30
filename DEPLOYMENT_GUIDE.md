# 🚀 Production Deployment Guide
## Windsor Islamic Association Prayer App

### 📋 Pre-Deployment Checklist

#### ✅ Code Preparation
- [x] Widget optimization completed (Issue #2)
- [x] Notification scheduling fixed (Issue #1) 
- [x] Debug logging disabled for production (debug: false)
- [ ] Release build configuration verified
- [ ] Performance testing completed

#### ✅ App Configuration
- [ ] Version number updated for release
- [x] Application ID verified: `com.wia.prayer_app`
- [ ] Release signing configured (see keystore setup below)
- [x] ProGuard/R8 optimization settings applied

#### ✅ Asset Requirements
- [ ] App icon (512x512 for Play Store)
- [ ] Feature graphic (1024x500)
- [ ] Screenshots (minimum 2, maximum 8)
- [ ] Privacy policy URL ready
- [ ] App description finalized

### 🔐 Keystore Setup for Release Signing

#### Step 1: Create Release Keystore
```powershell
# Navigate to android directory
cd android

# Create keystore using keytool (requires Java JDK)
keytool -genkeypair -v -keystore wia-prayer-release-key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias wia-prayer-key

# You'll be prompted for:
# - Keystore password (remember this!)
# - Key password (can be same as keystore password)
# - Your name, organization, city, state, country
```

#### Step 2: Update key.properties
Edit `android/key.properties`:
```properties
storePassword=YOUR_ACTUAL_KEYSTORE_PASSWORD
keyPassword=YOUR_ACTUAL_KEY_PASSWORD  
keyAlias=wia-prayer-key
storeFile=wia-prayer-release-key.keystore
```

#### Step 3: Secure Your Keystore
- **NEVER** commit `key.properties` or `.keystore` files to git
- Back up your keystore file securely
- Store passwords in a password manager
- If you lose the keystore, you cannot update your app on Play Store

### 🔧 Production Build Commands

```powershell
# Step 1: Clean previous builds
flutter clean
flutter pub get

# Step 2: Build release APK for testing
flutter build apk --release

# Step 3: Build App Bundle for Play Store (PREFERRED)
flutter build appbundle --release

# Step 4: Test release build locally
flutter install --release
```

### 📁 Build Output Locations
- **Release APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **App Bundle**: `build/app/outputs/bundle/release/app-release.aab`

### 🔐 Security Checklist
- [ ] Signing key created and secured
- [ ] key.properties configured (never commit to git)
- [x] Debug logging disabled in production
- [ ] API keys and sensitive data secured

### 📱 Testing Requirements
- [ ] Tested on multiple Android versions (API 21+)
- [ ] Tested on different screen sizes
- [ ] Widget functionality verified
- [ ] Notification scheduling tested
- [ ] Qibla compass accuracy confirmed
- [ ] Location permissions working
- [ ] Offline functionality verified

### 🎯 Publishing Targets

#### Google Play Store
1. Create Google Play Console account ($25 one-time fee)
2. Upload app bundle (.aab file)
3. Complete store listing with:
   - App name: "WIA Prayer Times"
   - Description highlighting key features
   - Screenshots and graphics
   - Privacy policy URL
4. Submit for review (usually 1-3 days)

#### Direct Distribution (Optional)
- Use .apk file for direct installation
- Requires "Unknown Sources" permission
- Good for beta testing

### 📈 Post-Launch Monitoring
- Monitor Play Console crash reports
- Track user reviews and ratings  
- Monitor performance metrics
- Plan for regular updates (annual prayer time updates)

### 🔄 Future Update Process
1. Increment version in pubspec.yaml (e.g., 1.0.0+1 → 1.0.1+2)
2. Test changes thoroughly
3. Build new release
4. Upload to Play Console
5. Add release notes describing changes
6. Use staged rollout for safety (start with 5%, then 20%, 50%, 100%)

### ⚠️ Current Status
- **Code**: Production ready ✅
- **Debug logging**: Disabled ✅  
- **Build config**: Ready ✅
- **Keystore**: Needs setup for actual release ⚠️
- **Testing**: In progress 🔄

### 📞 Support
For keystore setup help or production deployment questions, ensure you:
1. Have Java JDK installed (required for keytool)
2. Follow keystore security best practices
3. Test release builds thoroughly before publishing

---
**Status**: Ready for keystore setup and final testing ✅