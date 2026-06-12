# Quick Start - 5 Minutes to Running

## TL;DR

```bash
# 1. Extract project
cd flutter_techbes_app

# 2. Get dependencies  
flutter pub get

# 3. Run app
flutter run

# That's it! 🎉
```

## One-Liner Install (macOS/Linux)

```bash
cd flutter_techbes_app && flutter pub get && flutter run
```

## Prerequisites Check

```bash
flutter doctor
```

Should show:
- ✅ Flutter SDK
- ✅ Android SDK or Xcode
- ✅ Connected device or emulator

## Common Scenarios

### First Time Setup
```bash
flutter pub get
flutter run
```

### After Code Changes
```bash
# Hot reload (keeps state)
Press 'r' in terminal

# Hot restart (loses state)  
Press 'R' in terminal
```

### Android Emulator Not Running?
```bash
emulator -list-avds                    # List available emulators
emulator -avd <emulator_name> &        # Start emulator
flutter run
```

### iOS Simulator Not Running?
```bash
open -a Simulator
flutter run
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter run
```

## Features to Test

1. **Home Tab** - Browse services with category filter
2. **Services Tab** - View all services with sorting
3. **Cart Tab** - Add services, set dates, checkout
4. **Dashboard Tab** - View bookings and profile
5. **Login** - Click profile, sign in with any credentials

## File Structure to Know

```
lib/
├── main.dart                    ← App entry point
├── screens/                     ← UI pages
├── providers/                   ← Business logic (state)
├── models/models.dart           ← Data models
├── theme/app_theme.dart         ← Colors & styles
└── widgets/                     ← Reusable UI components
```

## Customization (30 seconds)

### Change App Name
Edit `pubspec.yaml` line 1:
```yaml
name: your_app_name
```

### Change Colors
Edit `lib/theme/app_theme.dart`:
```dart
static const Color primaryColor = Color(0xFF10B981);  // Change this
```

### Change Services
Edit `lib/providers/services_provider.dart` in `_initializeMockData()` method

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "flutter command not found" | Add Flutter to PATH, restart terminal |
| Device not showing | Run `adb devices` (Android) or `open -a Simulator` (iOS) |
| Build fails | Run `flutter clean && flutter pub get` |
| Port 8888 in use | Kill process or use different port |

## Next: API Integration

Replace mock data with real API:

1. Add `http` to `pubspec.yaml`:
   ```yaml
   dependencies:
     http: ^1.0.0
   ```

2. Run `flutter pub get`

3. Update providers to use HTTP requests

## Production Build

```bash
# Android APK
flutter build apk --release

# iOS App
flutter build ios --release

# Android Play Store (AAB)
flutter build appbundle --release
```

Output locations:
- Android APK: `build/app/outputs/flutter-apk/app-release.apk`
- Android AAB: `build/app/outputs/bundle/release/app-release.aab`
- iOS: `build/ios/iphoneos/Runner.app`

## Support

- 📖 Full setup guide: `SETUP_GUIDE.md`
- 📚 Documentation: `README.md`
- 🐛 Stuck? Check `flutter doctor -v` output

---

**That's it! You're ready to code.** 🚀

Press `h` in terminal while app is running to see all available commands.
