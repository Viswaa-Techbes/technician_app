class ApiConfig {
  // Backend API Base URL - Techbes IT Services
  static const String baseUrl = 'https://technician-app.onrender.com';

  // Auth Endpoints
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String sendOtp = '/api/auth/send-otp';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String session = '/api/auth/session';

  // Services Endpoints
  static const String services = '/api/services';
  static const String categories = '/api/categories';

  // Cart Endpoints
  static const String cart = '/api/v2/cart';
  static const String addToCart = '/api/v2/cart/add';
  static const String removeFromCart = '/api/v2/cart/remove';
  static const String clearCart = '/api/v2/cart/clear';

  // Bookings Endpoints
  static const String bookings = '/api/bookings';
  static const String userBookings = '/api/user/bookings';
  static const String createBooking = '/api/bookings/create';

  // User Endpoints
  static const String userProfile = '/api/v2/user/profile';
  static const String userAddresses = '/api/v2/user/address';
  static const String userPayments = '/api/user/payments';
  static const String userServiceReports = '/api/user/service-reports';

  // Reviews & Ratings Endpoints
  static const String reviews = '/api/reviews';
  static const String ratings = '/api/ratings';

  // Payment Endpoints
  static const String payments = '/api/payments';

  // Dispatch Endpoints
  static const String dispatch = '/api/dispatch';

  // Notification Endpoints
  static const String notifications = '/api/notifications';

  // Address Endpoints
  static const String geocode = '/api/geocode';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
