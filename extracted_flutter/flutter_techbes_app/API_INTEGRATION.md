# Techbes Flutter App - API Integration Guide

## Overview

The Flutter mobile app is fully integrated with the existing Techbes backend API at `https://technician-app.onrender.com`. All API calls are made directly from the Flutter app without duplicating any backend logic.

## Architecture

### API Service Layer

The app uses a clean service-based architecture with multiple layers:

```
Flutter Screens (UI)
    ↓
Providers (State Management)
    ↓
API Services (Business Logic)
    ↓
ApiService (HTTP Client)
    ↓
Backend API (https://technician-app.onrender.com)
```

### Service Files

- **lib/services/api_service.dart** - Base HTTP client with authentication
- **lib/services/auth_service.dart** - Authentication logic
- **lib/services/services_api_service.dart** - Services browsing logic
- **lib/services/cart_api_service.dart** - Shopping cart logic
- **lib/services/bookings_api_service.dart** - Bookings & user management logic

## API Configuration

**File**: `lib/config/api_config.dart`

Base URL: `https://technician-app.onrender.com`

All endpoints are defined as constants:

```dart
static const String baseUrl = 'https://technician-app.onrender.com';

// Auth Endpoints
static const String login = '/api/auth/login';
static const String register = '/api/auth/register';

// Services Endpoints
static const String services = '/api/services';
static const String categories = '/api/categories';

// Cart Endpoints
static const String cart = '/api/v2/cart';
static const String addToCart = '/api/v2/cart/add';

// And many more...
```

## API Service Class

**File**: `lib/services/api_service.dart`

The `ApiService` class handles:
- HTTP requests (GET, POST, PUT, DELETE)
- Bearer token authentication
- Request/response handling
- Error handling and timeouts
- Token storage in SharedPreferences

### Usage Example

```dart
final apiService = ApiService();
await apiService.init(); // Initialize on app startup

// Make authenticated request
final response = await apiService.get('/api/user/profile');

if (response['success']) {
  final userData = response['data'];
  // Use data
}
```

## Authentication Flow

### Login Process

1. User enters email/password on login screen
2. `AuthProvider.login()` calls `AuthService.login()`
3. `AuthService` makes POST request to `/api/auth/login`
4. Backend returns token and user data
5. Token is stored in `SharedPreferences`
6. Token is automatically added to all subsequent requests
7. User is authenticated and Dashboard loads

### Code Example

```dart
// In LoginScreen or LoginForm
await authProvider.login(email, password);

// In AuthProvider
Future<void> login(String email, String password) async {
  final result = await _authService.login(email, password);
  
  if (result['success']) {
    _currentUser = User.fromJson(result['user']);
    _isLoggedIn = true;
  }
  notifyListeners();
}

// In AuthService
Future<Map<String, dynamic>> login(String email, String password) async {
  final response = await _apiService.post(
    ApiConfig.login,
    {'email': email, 'password': password},
    includeAuth: false,
  );
  
  if (response['success']) {
    final token = response['data']['token'];
    await _apiService.setAuthToken(token);
    return {
      'success': true,
      'user': response['data']['user'],
      'token': token,
    };
  }
  return response;
}
```

## Services & Categories API

### Getting All Services

```dart
final servicesApiService = ServicesApiService();

// Load services (called in ServicesProvider.loadServices())
final result = await servicesApiService.getAllServices();

if (result['success']) {
  List<Service> services = result['services'];
  // Display services
}
```

### Getting Categories

```dart
final result = await servicesApiService.getCategories();

if (result['success']) {
  List<String> categories = result['categories'];
  // Display categories
}
```

### Searching Services

```dart
final result = await servicesApiService.searchServices('CCTV');

if (result['success']) {
  List<Service> filteredServices = result['services'];
}
```

## Shopping Cart API

### Adding to Cart

```dart
final cartApiService = CartApiService();

final result = await cartApiService.addToCart(
  serviceId: '123',
  quantity: 1,
  scheduledDate: '2024-12-25',
);
```

### Getting Cart

```dart
final result = await cartApiService.getCart();

if (result['success']) {
  var cart = result['cart'];
  // Display cart items
}
```

### Removing from Cart

```dart
final result = await cartApiService.removeFromCart(itemId);
```

### Clearing Cart

```dart
final result = await cartApiService.clearCart();
```

### Checkout (Create Booking)

```dart
final checkoutData = {
  'items': [
    {
      'serviceId': '123',
      'quantity': 1,
      'scheduledDate': '2024-12-25',
      'notes': 'Installation at office',
      'amount': 499.99,
    }
  ],
  'totalAmount': 499.99,
};

final result = await cartApiService.checkout(checkoutData);

if (result['success']) {
  String bookingId = result['bookingId'];
  // Show success message and navigate
}
```

## User & Bookings API

### Getting User Profile

```dart
final bookingsApiService = BookingsApiService();

final result = await bookingsApiService.getUserProfile();

if (result['success']) {
  var profile = result['profile'];
  // Display profile data
}
```

### Updating User Profile

```dart
final result = await bookingsApiService.updateUserProfile({
  'name': 'John Doe',
  'phone': '+1234567890',
  'email': 'john@example.com',
});
```

### Getting User Bookings

```dart
final result = await bookingsApiService.getUserBookings();

if (result['success']) {
  List<Booking> bookings = result['bookings'];
  // Display booking history
}
```

### Getting Single Booking

```dart
final result = await bookingsApiService.getBookingById(bookingId);

if (result['success']) {
  var booking = result['booking'];
  // Display booking details
}
```

### Canceling a Booking

```dart
final result = await bookingsApiService.cancelBooking(bookingId);

if (result['success']) {
  // Show success message
}
```

### Adding Address

```dart
final result = await bookingsApiService.addAddress({
  'street': '123 Main St',
  'city': 'New York',
  'state': 'NY',
  'zipCode': '10001',
  'country': 'USA',
  'isDefault': true,
});
```

### Getting Addresses

```dart
final result = await bookingsApiService.getUserAddresses();

if (result['success']) {
  List addresses = result['addresses'];
  // Display user addresses
}
```

### Getting Payments

```dart
final result = await bookingsApiService.getUserPayments();

if (result['success']) {
  List payments = result['payments'];
  // Display payment history
}
```

## Reviews API

### Submitting a Review

```dart
final result = await bookingsApiService.submitReview(
  bookingId,
  {
    'rating': 5,
    'comment': 'Excellent service!',
    'description': 'The technician was professional and on time.',
  },
);

if (result['success']) {
  // Show success message
}
```

## Error Handling

All API responses follow a consistent format:

```dart
{
  'success': true/false,
  'status': 200/400/401/500,
  'message': 'Human readable message',
  'data': { /* response data */ },
  'error': 'Error details if applicable'
}
```

### Example Error Handling

```dart
try {
  final result = await apiService.post(endpoint, body);
  
  if (result['success']) {
    // Handle success
  } else {
    final errorMessage = result['message'];
    
    if (result['status'] == 401) {
      // Handle unauthorized - redirect to login
      authProvider.logout();
    } else if (result['status'] == 404) {
      // Handle not found
    } else {
      // Show error message to user
      showSnackBar(errorMessage);
    }
  }
} catch (e) {
  // Handle network errors
  showSnackBar('Network error: ${e.toString()}');
}
```

## Authentication Header

All authenticated requests automatically include:

```
Authorization: Bearer {token}
Content-Type: application/json
```

The token is stored in `SharedPreferences` and automatically added to requests by the `ApiService` class.

## Timeout Configuration

- Connection timeout: 30 seconds
- Receive timeout: 30 seconds

These are defined in `lib/config/api_config.dart` and can be adjusted:

```dart
static const int connectionTimeout = 30000; // 30 seconds
static const int receiveTimeout = 30000; // 30 seconds
```

## Response Format Flexibility

The API services handle various response formats from the backend:

```dart
// The backend might return:
// 1. { "data": { "user": {...} } }
// 2. { "user": {...} }
// 3. { "data": [...] }
// 4. [...]

// The service layer handles all these formats automatically
final data = response['data']['data'] ?? response['data'];
```

## Fallback to Mock Data

If the backend API is unavailable, the app gracefully falls back to mock data:

```dart
// In ServicesProvider.loadServices()
try {
  final servicesResult = await _apiService.getAllServices();
  if (servicesResult['success']) {
    _services = servicesResult['services'];
  } else {
    // Fallback to mock data
    _initializeMockData();
    _error = 'Using cached data. API unavailable.';
  }
} catch (e) {
  _initializeMockData();
}
```

This ensures the app remains usable even if the backend is temporarily down.

## Testing API Integration

### Test Login

```bash
# Using curl or Postman
POST https://technician-app.onrender.com/api/auth/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password123"
}
```

### Test Services Endpoint

```bash
GET https://technician-app.onrender.com/api/services
```

### Test Cart Operations

```bash
# Add to cart
POST https://technician-app.onrender.com/api/v2/cart/add
Authorization: Bearer {token}
Content-Type: application/json

{
  "serviceId": "123",
  "quantity": 1
}
```

## Debugging API Calls

Add console logs in the ApiService to debug:

```dart
// In lib/services/api_service.dart
Future<Map<String, dynamic>> get(String endpoint, {bool includeAuth = true}) async {
  print('[API] GET: ${ApiConfig.baseUrl}$endpoint');
  
  // ... make request ...
  
  print('[API] Response: ${response.statusCode} - $body');
  return _handleResponse(response);
}
```

Or use Flutter DevTools Network profiler to monitor all HTTP requests.

## Updating API Endpoints

To add new endpoints or modify existing ones:

1. **Add to ApiConfig**: Update `lib/config/api_config.dart` with new endpoint constant
2. **Create Service Method**: Add method to appropriate service class
3. **Use in Provider**: Call the service method from the Provider
4. **Display in UI**: Use the Provider in your Widget

Example:

```dart
// 1. Add to ApiConfig
static const String newEndpoint = '/api/new-endpoint';

// 2. Create service method
Future<Map<String, dynamic>> getNewData() async {
  final response = await _apiService.get(ApiConfig.newEndpoint);
  return {
    'success': response['success'],
    'data': response['data'],
  };
}

// 3. Use in provider
Future<void> loadNewData() async {
  final result = await _apiService.getNewData();
  if (result['success']) {
    _data = result['data'];
    notifyListeners();
  }
}

// 4. Use in widget
Consumer<MyProvider>(
  builder: (context, provider, child) {
    return ListView(
      children: provider.data.map((item) => Text(item.name)).toList(),
    );
  },
)
```

## Troubleshooting

### 401 Unauthorized
- Token has expired
- Token is invalid or corrupted
- Solution: User needs to login again

### 404 Not Found
- Endpoint doesn't exist
- Resource ID is invalid
- Solution: Verify endpoint URL in ApiConfig

### 500 Internal Server Error
- Backend server error
- Solution: Check backend logs, wait for fix

### Timeout
- Network is slow
- Backend is slow to respond
- Solution: Increase timeout in ApiConfig or check network

### CORS Errors
- Should not occur since Flutter app doesn't have CORS restrictions
- If testing with web version, ensure backend has proper CORS headers

## Best Practices

1. **Always use ApiService** for HTTP calls - don't make raw http requests
2. **Handle errors gracefully** - show user-friendly messages
3. **Use loading states** - show spinners while API calls are in progress
4. **Implement fallback** - use mock data when API unavailable
5. **Cache tokens securely** - use SharedPreferences for local storage
6. **Clear tokens on logout** - ensure old tokens are removed
7. **Test API endpoints** - verify endpoints work before implementing
8. **Monitor network** - use DevTools to debug slow API calls
9. **Handle 401 responses** - automatically logout on unauthorized
10. **Validate responses** - ensure data matches expected structure

## Support

For API-related issues:
1. Check backend logs at Render dashboard
2. Verify API endpoint is correct in ApiConfig
3. Test endpoint with Postman or curl
4. Check network connectivity
5. Review error messages in app logs
