class ApiConfig {
  static const String baseUrl = "https://technician-app.onrender.com";
  
  // Auth
  static const String login = "/auth/login";
  static const String signup = "/auth/register";
  static const String me = "/auth/me";
  static const String fcmToken = "/auth/fcm-token";
  
  // Jobs
  static const String jobs = "/jobs";
  static const String updateJobStatus = "/technician/tasks";
  static const String location = "/technician/location";
  static const String updateStatus = "/technician/update-status";
  static const String assignJob = "/jobs/assign";
  
  // Expenses
  static const String expenses = "/expenses";
  
  // Reviews
  static const String reviews = "/reviews";
  
  // Dashboard
  static const String dashboard = "/admin/dashboard";
  
  // Notifications
  static const String notifications = "/notifications";
  
  // Socket
  static const String socketUrl = "https://technician-app.onrender.com";
}

class AppConstants {
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}
