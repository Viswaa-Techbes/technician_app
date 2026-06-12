# Techbes - IT Services Mobile App

A premium Flutter mobile application for Techbes IT Services Marketplace, mirroring the Next.js web app design and functionality.

## Features

- 🏠 **Home Screen** - Hero section with category browsing and popular services
- 🔧 **Services Catalog** - Browse and filter IT services by category
- 🛒 **Shopping Cart** - Add services, set schedules, and manage quantities
- 📦 **Checkout** - Complete service bookings with pricing summary
- 📊 **Dashboard** - View bookings, track service history, and manage account
- 👤 **Authentication** - Sign in/up with email and password
- 💳 **Booking System** - Schedule services with date selection
- 🎨 **Premium UI** - Modern design with emerald/teal and blue color scheme

## Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **Backend API**: Techbes IT Services API (https://technician-app.onrender.com)
- **HTTP Client**: Dart's http package with Bearer token authentication
- **Local Storage**: SharedPreferences for token/session management
- **UI Framework**: Material Design 3
- **Fonts**: Google Fonts (Geist)

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── theme/
│   └── app_theme.dart       # Theme configuration
├── models/
│   └── models.dart          # Data models
├── providers/
│   ├── auth_provider.dart   # Authentication state
│   ├── services_provider.dart # Services state
│   └── cart_provider.dart   # Shopping cart state
├── screens/
│   ├── home_screen.dart
│   ├── services_screen.dart
│   ├── cart_screen.dart
│   └── dashboard_screen.dart
└── widgets/
    └── service_card.dart    # Reusable service card
```

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart 3.0 or higher
- Android Studio or Xcode for iOS development

### Installation

1. **Clone or extract the project**
   ```bash
   cd flutter_techbes_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Build for Production

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Features in Detail

### 1. Home Screen
- Welcome message with user greeting
- Search functionality
- Category browsing with filtering
- Popular services display
- Cart badge showing item count

### 2. Services Screen
- Complete service catalog
- Filter by category
- Sort options (rating, price)
- Service details with ratings and reviews
- Feature highlights

### 3. Shopping Cart
- View all added services
- Adjust quantities
- Set scheduled dates
- View pricing breakdown with tax
- Proceed to checkout

### 4. Dashboard
- User profile section
- Booking statistics
- View all bookings
- Track booking status (confirmed, cancelled)
- View booking details and amounts

## API Integration

The app is **fully integrated with the Techbes backend API** at `https://technician-app.onrender.com`.

### Integrated APIs:
- ✅ **Authentication API** - Login, Register, OTP, Session management
- ✅ **Services API** - Browse services, filter by category, search
- ✅ **Cart API** - Add/remove items, manage quantities, checkout
- ✅ **Bookings API** - Create, view, cancel service bookings
- ✅ **User API** - Profile management, addresses, payment history
- ✅ **Reviews API** - Submit service reviews and ratings
- ✅ **Dispatch API** - Track service dispatch status
- ✅ **Notification API** - Receive booking updates

### API Architecture:
- Service Layer: `lib/services/` contains all API service classes
- Configuration: `lib/config/api_config.dart` defines all endpoints
- Token Management: Automatic Bearer token authentication
- Error Handling: Graceful fallback to mock data if API unavailable
- Local Caching: SharedPreferences for session persistence

### See Also:
For detailed API integration documentation, see `API_INTEGRATION.md`

## Customization

### Theme Colors

Edit `lib/theme/app_theme.dart`:
- `primaryColor` - Main brand color (currently emerald #10B981)
- `accentColor` - Secondary color (currently blue #3B82F6)
- `backgroundColor` - App background
- `errorColor`, `successColor`, `warningColor` - Status colors

### Services Data

Edit `lib/providers/services_provider.dart` `_initializeMockData()` method to:
- Add/remove services
- Update pricing
- Modify categories
- Change features and descriptions

## Performance Optimization

- Uses efficient list rendering with `ListView.builder`
- Implements proper Provider scoping
- Lazy loads images when available
- Optimizes widget rebuilds

## Deployment

### Google Play Store
1. Create a Google Play Console account
2. Run `flutter build appbundle --release`
3. Upload AAB to Play Store

### Apple App Store
1. Create an Apple Developer account
2. Run `flutter build ios --release`
3. Upload to App Store Connect

## Support

For issues and feature requests, please contact the development team.

## License

All rights reserved © Techbes 2024
