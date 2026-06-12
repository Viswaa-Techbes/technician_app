import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://technician-app.onrender.com';

  static String get razorpayKeyId =>
      dotenv.env['RAZORPAY_KEY_ID'] ?? '';

  static String get socketUrl =>
      dotenv.env['SOCKET_URL'] ?? 'https://technician-app.onrender.com';
}
