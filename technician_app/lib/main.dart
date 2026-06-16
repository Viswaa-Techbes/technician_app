import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'manager_main_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'core/security/rbac_constants.dart';
import 'core/error/error_handler.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  GlobalErrorHandler.initialize();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final container = ProviderContainer();
  
  try {
    await container.read(pushNotificationServiceProvider).initialize();
  } catch (e) {
    debugPrint('FCM init failed: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TechbesApp(),
    ),
  );
}

class TechbesApp extends StatelessWidget {
  const TechbesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Techbes Production',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFFEA580C),
        ),
      ),
      home: const RootGate(),
    );
  }
}

class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return const LoginScreen();
    }

    // Sync FCM push token to the backend once authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationServiceProvider).syncToken();
    });

    if (user.role == Role.manager) {
      return const ManagerMainScreen();
    } else {
      return const MainScreen();
    }
  }
}
