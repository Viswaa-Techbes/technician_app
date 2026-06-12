/// All backend API endpoint constants.
/// The Flutter app calls the backend directly (no BFF proxy like the web app).
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ───────────────────────────────────────────────────────────────
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String sendOtp = '/api/auth/send-otp';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String session = '/api/auth/session';
  static const String logout = '/api/auth/logout';

  // ── Dashboard ──────────────────────────────────────────────────────────
  static const String dashboard = '/api/v2/user/dashboard';

  // ── Bookings ───────────────────────────────────────────────────────────
  static const String createBooking = '/api/v2/bookings/create';
  static const String myBookings = '/api/bookings';

  // ── CCTV / Services ────────────────────────────────────────────────────
  static const String cctvCategories = '/api/v2/cctv/categories';
  static const String cctvSubcategories = '/api/v2/cctv/subcategories';
  static String cctvSubcategory(String slug) => '/api/v2/cctv/subcategories/$slug';
  static const String cctvCameraTypes = '/api/v2/cctv/camera-types';
  static const String cctvAddons = '/api/v2/cctv/addons';
  static const String materials = '/api/v2/materials';
  static const String calculatePrice = '/api/v2/cctv/calculate-price';
  static String serviceConfig(String serviceId) => '/api/v2/services/$serviceId/config';

  // ── Cart ───────────────────────────────────────────────────────────────
  static const String getCart = '/api/v2/cart';
  static const String addCart = '/api/v2/cart/add';
  static String deleteCartItem(String id) => '/api/v2/cart/item/$id';
  static const String clearCart = '/api/v2/cart/clear';

  // ── Payments ───────────────────────────────────────────────────────────
  static const String createOrder = '/api/v2/payments/create-order';
  static const String verifyPayment = '/api/v2/payments/verify-payment';
  static const String myPayments = '/api/v2/payment/my';

  // ── User ───────────────────────────────────────────────────────────────
  static const String userProfile = '/api/v2/user/profile';
  static const String userAddresses = '/api/v2/user/addresses';
  static const String userAddress = '/api/v2/user/address';
  static String userAddressById(String id) => '/api/v2/user/address/$id';

  // ── Reviews ────────────────────────────────────────────────────────────
  static const String reviews = '/api/reviews';

  // ── Leads ──────────────────────────────────────────────────────────────
  static const String leads = '/leads';
}
