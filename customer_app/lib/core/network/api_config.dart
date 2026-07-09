class ApiConfig {
  static const String baseUrl = "https://api.techbes.co.in";

  // Auth endpoints
  static const String login = "/api/auth/login";
  static const String register = "/api/auth/register";
  static const String sendOtp = "/api/auth/send-otp";
  static const String verifyOtp = "/api/auth/verify-otp";
  static const String session = "/api/auth/session";
  static const String logout = "/api/auth/logout";

  // CCTV Configuration & Services
  static const String cctvCategories = "/api/v2/cctv/categories";
  static const String cctvSubcategories = "/api/v2/cctv/subcategories";
  static const String calculatePrice = "/api/v2/cctv/calculate-price";
  static const String serviceConfig = "/api/v2/services"; // + /:serviceId/config

  // Bookings & Payments
  static const String createBooking = "/api/v2/bookings/create";
  static const String myBookings = "/api/v2/user/dashboard"; // dashboard overview
  static const String createOrder = "/api/v2/payments/create-order";
  static const String verifyPayment = "/api/v2/payments/verify-payment";

  // Saved Addresses
  static const String address = "/api/user/address";

  // Reviews & Rating
  static const String reviews = "/api/reviews";
}
