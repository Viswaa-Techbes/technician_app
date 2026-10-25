class ApiConfig {
  static const String baseUrl = "https://api.techbes.co.in";

  // Auth endpoints
  static const String login = "/api/auth/login";
  static const String register = "/api/auth/register";
  static const String sendOtp = "/api/auth/send-otp";
  static const String verifyOtp = "/api/auth/verify-otp";
  static const String session = "/api/auth/session";
  static const String logout = "/api/auth/logout";
  static const String me = "/api/auth/me";
  static const String forgotPassword = "/api/auth/forgot-password";
  static const String resetPassword = "/api/auth/reset-password";

  // Service Catalog (public)
  static const String catalogCategories = "/api/v2/catalog/categories";
  static const String catalogSubcategories = "/api/v2/catalog/subcategories";
  // /api/v2/catalog/categories/:slug/subcategories  — build with categorySubcategories(slug)
  // /api/v2/catalog/subcategories/:slug/questions   — build with subcategoryQuestions(slug)
  static String categorySubcategories(String slug) =>
      "/api/v2/catalog/categories/$slug/subcategories";
  static String subcategoryDetails(String slug) =>
      "/api/v2/catalog/subcategories/$slug";
  static String subcategoryQuestions(String slug) =>
      "/api/v2/catalog/subcategories/$slug/questions";
  static String subcategoryPackages(String slug) =>
      "/api/v2/catalog/subcategories/$slug/packages";

  // CCTV Configuration & Services
  static const String cctvCategories = "/api/v2/cctv/categories";
  static const String cctvSubcategories = "/api/v2/cctv/subcategories";
  static const String cctvBrands = "/api/v2/cctv/brands";
  static const String cctvModels = "/api/v2/cctv/models";
  static const String cctvSdCards = "/api/v2/cctv/sd-cards";
  static const String cctvCablePricings = "/api/v2/cctv/cable-pricings";
  static const String cctvInstallationCharges = "/api/v2/cctv/installation-charges";
  static const String cctvAccessories = "/api/v2/cctv/accessories";
  static const String cctvHdds = "/api/v2/cctv/hdds";
  static const String cctvRacks = "/api/v2/cctv/racks";
  static const String cctvProducts = "/api/v2/cctv/products";
  static const String cctvAddons = "/api/v2/cctv/addons";
  static const String calculatePrice = "/api/v2/cctv/calculate-price";

  // Bookings
  static const String createBooking = "/api/v2/bookings/create";
  static const String myBookings = "/api/v2/user/bookings";
  static String bookingDetails(String id) => "/api/v2/bookings/$id";
  static String updateBookingStatus(String id) => "/api/v2/bookings/$id/status";

  // Quotations / Enquiries
  static const String submitQuote = "/api/v2/quotes";
  static const String myQuotes = "/api/v2/quotes/my-quotes";
  static String quoteDetails(String id) => "/api/v2/quotes/$id";

  // Payments (Razorpay)
  static const String createOrder = "/api/v2/payments/create-order";
  static const String verifyPayment = "/api/v2/payments/verify-payment";
  static const String myPayments = "/api/v2/payments/my";

  // User Dashboard & Profile
  static const String userDashboard = "/api/v2/user/dashboard";
  static const String userProfile = "/api/v2/user/profile";
  static const String userAddresses = "/api/v2/user/addresses";
  static const String createAddress = "/api/v2/user/address";
  static String updateAddress(String id) => "/api/v2/user/address/$id";
  static String deleteAddress(String id) => "/api/v2/user/address/$id";

  // Wallet
  static const String wallet = "/api/v2/customer/wallet";

  // Reviews & Ratings
  static const String reviews = "/api/reviews";

  // Notifications
  static const String notifications = "/api/v2/notifications";
  static const String fcmToken = "/api/auth/fcm-token";

  // AMC
  static const String amcContracts = "/api/v2/amc/contracts";
  static const String amcPlans = "/api/v2/amc/plans";

  // Analytics (User)
  static const String userAnalytics = "/api/v2/analytics/user";

  // Apartment & Society Complaints
  static const String residentActivate = "/api/v2/apartments/residents/activate";
  static const String residentProfile = "/api/v2/apartments/residents/me";
  static const String apartmentTickets = "/api/v2/apartments/tickets";
  static String apartmentTicketDetails(String id) => "/api/v2/apartments/tickets/$id";
  static String apartmentTicketReply(String id) => "/api/v2/apartments/tickets/$id/reply";
  static String apartmentTicketStatus(String id) => "/api/v2/apartments/tickets/$id/status";
  static String apartmentTicketInternalNotes(String id) => "/api/v2/apartments/tickets/$id/internal-notes";
  static String apartmentTicketResolve(String id) => "/api/v2/apartments/tickets/$id/resolve";
  static String apartmentTicketReopen(String id) => "/api/v2/apartments/tickets/$id/reopen";
  static const String apartments = "/api/v2/apartments";
  static String apartmentDetails(String id) => "/api/v2/apartments/$id";
  static const String upload = "/api/v2/upload";
}
