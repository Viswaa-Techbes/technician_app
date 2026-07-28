import 'dart:convert';

class JwtDecoder {
  /// Decodes the payload of a JWT token.
  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final map = json.decode(resp);
      return map is Map<String, dynamic> ? map : null;
    } catch (_) {
      return null;
    }
  }

  /// Checks if a JWT token has expired.
  static bool isExpired(String token) {
    final payload = decode(token);
    if (payload == null) return true;
    final exp = payload['exp'];
    if (exp == null) return false;
    if (exp is int) {
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      // Subtract a 10-second buffer to handle minor clock variations
      return DateTime.now().isAfter(expiryDate.subtract(const Duration(seconds: 10)));
    }
    return false;
  }
}
