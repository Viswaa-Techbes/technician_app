import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_screen.dart'; // Maintain existing for now
import 'main_screen.dart';
import 'manager_main_screen.dart';
import 'presentation/providers/auth_provider.dart';
import 'core/error/error_handler.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Global Error Handling
  GlobalErrorHandler.initialize();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final container = ProviderContainer();
  
  // Initialize FCM
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
    final authState = ref.watch(authNotifierProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.user == null) {
      return const LoginScreen();
    }

    if (authState.user!.role == 'manager') {
      return const ManagerMainScreen();
    } else {
      return const MainScreen();
    }
  }
}
