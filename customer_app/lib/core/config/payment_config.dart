import 'package:flutter/foundation.dart';

class PaymentConfig {
  // Config flag to easily enable or disable test mode.
  static const bool enableTestMode = true;

  // Test mode is active ONLY in debug/development builds and when enabled by the flag.
  // This guarantees that production builds (where kDebugMode is false) are NEVER affected.
  static bool get isTestMode => kDebugMode && enableTestMode;
}
