# Techbes Flutter App - Setup Guide

This guide will walk you through setting up and running the Techbes Flutter mobile application on your local machine.

## Prerequisites

Before starting, ensure you have the following installed:

### 1. Flutter SDK
- **Download**: https://flutter.dev/docs/get-started/install
- **Version**: 3.0 or higher
- **Verify Installation**:
  ```bash
  flutter --version
  flutter doctor
  ```

### 2. Dart SDK
- Comes with Flutter installation
- **Verify**:
  ```bash
  dart --version
  ```

### 3. IDE/Editor
Choose one:
- **Android Studio** (recommended for Android development)
- **Visual Studio Code** (with Flutter extension)
- **Xcode** (for iOS development on macOS)

### 4. Platform Requirements

**For Android Development:**
- Android SDK (minimum API level 21)
- Android Emulator or physical Android device
- Java Development Kit (JDK) 11+

**For iOS Development (macOS only):**
- Xcode 14+
- CocoaPods
- iOS deployment target: 11.0+

## Installation Steps

### Step 1: Get Flutter
```bash
# Download and extract Flutter
git clone https://github.com/flutter/flutter.git -b stable

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

### Step 2: Project Setup
```bash
# Navigate to project directory
cd flutter_techbes_app

# Get dependencies
flutter pub get

# Upgrade packages (optional)
flutter pub upgrade
```

### Step 3: Android Setup (If targeting Android)

```bash
# Connect Android device or start emulator
adb devices

# Run the app
flutter run
```

### Step 4: iOS Setup (If targeting iOS - macOS only)

```bash
# Install CocoaPods dependencies
cd ios
pod install
cd ..

# Run the app
flutter run
```

## Running the App

### Development Build

**Run on connected device/emulator:**
```bash
flutter run
```

**Run with specific device:**
```bash
flutter devices                    # List available devices
flutter run -d <device-id>
```

**Run in release mode:**
```bash
flutter run --release
```

### Debug/Development Features

**Enable hot reload:**
- Press `r` in terminal (hot reload code)
- Press `R` in terminal (hot restart - full app restart)
- Press `q` to quit

**Enable debug logs:**
```bash
flutter run -v
```

## Building for Production

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS App
```bash
flutter build ios --release
# Output: build/ios/iphoneos/Runner.app
```

## Project Structure

```
flutter_techbes_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── theme/
│   │   └── app_theme.dart          # Theming configuration
│   ├── models/
│   │   └── models.dart             # Data models
│   ├── providers/
│   │   ├── auth_provider.dart      # Auth logic
│   │   ├── services_provider.dart  # Services logic
│   │   └── cart_provider.dart      # Cart logic
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── services_screen.dart
│   │   ├── cart_screen.dart
│   │   └── dashboard_screen.dart
│   └── widgets/
│       └── service_card.dart       # Reusable widgets
├── android/                         # Android native code
├── ios/                            # iOS native code
├── pubspec.yaml                    # Dependencies
└── README.md                        # Documentation
```

## Key Dependencies

The app uses these packages:

```yaml
provider: ^6.0.0              # State management
google_fonts: ^6.0.0          # Typography
feather_icons: ^0.14.0        # Icons
flutter_rating_bar: ^4.0.0    # Star ratings
intl: ^0.19.0                 # Internationalization
cached_network_image: ^3.3.0  # Image caching
```

To update dependencies:
```bash
flutter pub get
flutter pub upgrade
```

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

## Troubleshooting

### Common Issues

**1. "Flutter not found"**
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"
```

**2. CocoaPods issues (iOS)**
```bash
cd ios
rm Podfile.lock
pod install
cd ..
flutter run
```

**3. Gradle build issues (Android)**
```bash
flutter clean
flutter pub get
flutter run
```

**4. Port already in use**
```bash
flutter run -d <device-id> --observe=5000
```

**5. Device not found**
```bash
# Restart ADB server
adb kill-server
adb start-server
adb devices
```

### Getting Help

- **Flutter Docs**: https://flutter.dev/docs
- **Stack Overflow**: Tag with `flutter`
- **GitHub Issues**: https://github.com/flutter/flutter/issues

## Development Tips

### Hot Reload
During development, use hot reload to quickly test changes:
- **Save file** → **Press `r`** → See changes immediately
- Hot reload preserves app state, making development faster

### DevTools
Enable Flutter DevTools for debugging:
```bash
flutter pub global activate devtools
devtools
```

### Performance Profiling
```bash
# Run with performance profiling
flutter run --profile

# Enable frame rate overlay
# Press 'P' during app runtime
```

## API Integration

Currently, the app uses mock data. To integrate with a backend API:

1. **Update `lib/providers/`** to make HTTP requests using `http` package:
   ```dart
   dependencies:
     http: ^1.0.0
   ```

2. **Replace mock data** with API calls

3. **Add environment configuration**:
   ```dart
   const String API_BASE_URL = 'https://api.example.com';
   ```

## Next Steps

- ✅ Install Flutter
- ✅ Clone/Extract project
- ✅ Run `flutter pub get`
- ✅ Connect device or start emulator
- ✅ Run `flutter run`
- ✅ Test the app
- ✅ Make modifications
- ✅ Build for production when ready

## Support & Questions

For issues specific to this project, please refer to:
- **main.dart** - App structure
- **lib/theme/app_theme.dart** - Styling
- **lib/providers/** - Business logic
- **lib/screens/** - UI screens

Happy coding! 🚀
