import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/core/router/app_router.dart';
import 'package:customer_app/core/theme/app_theme.dart';

class TechbesCustomerApp extends ConsumerWidget {
  const TechbesCustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Techbes Customer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark, // Default to premium dark mode
      routerConfig: router,
    );
  }
}
