import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/app.dart';
import 'package:customer_app/core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    // Fail-soft if env is missing
  }

  // Initialize notifications
  try {
    await NotificationService().init();
  } catch (e) {
    // Fail-soft if notifications fail to init (e.g. on unsupported platform)
  }

  runApp(
    const ProviderScope(
      child: TechbesCustomerApp(),
    ),
  );
}
