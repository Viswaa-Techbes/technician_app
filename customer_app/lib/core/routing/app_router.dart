import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/dashboard/screens/main_navigation_screen.dart';
import '../../features/services/screens/service_detail_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/tracking/screens/live_tracking_screen.dart';
import '../../features/reports/screens/worksheet_viewer.dart';
import '../../features/auth/providers/auth_provider.dart';

// Import New Screens
import '../../features/home/screens/universal_search_screen.dart';
import '../../features/reports/screens/invoice_center_screen.dart';
import '../../features/amc/screens/amc_dashboard_screen.dart';
import '../../features/dashboard/screens/analytics_dashboard_screen.dart';
import '../../features/home/screens/ai_assistant_screen.dart';
import '../../features/profile/screens/referral_screen.dart';
import '../../features/reports/screens/service_timeline_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/otp' ||
          state.matchedLocation == '/forgot-password';

      if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) {
        return '/splash';
      }

      final isLoggedIn = authState.status == AuthStatus.authenticated;

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && (state.matchedLocation == '/login' || state.matchedLocation == '/splash')) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/services/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return ServiceDetailScreen(slug: slug);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/tracking/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          return LiveTrackingScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/reports/:worksheetId',
        builder: (context, state) {
          final worksheetId = state.pathParameters['worksheetId'] ?? '';
          return WorksheetViewerScreen(worksheetId: worksheetId);
        },
      ),
      // New Phase 2 Routes
      GoRoute(
        path: '/search',
        builder: (context, state) => const UniversalSearchScreen(),
      ),
      GoRoute(
        path: '/invoice-center',
        builder: (context, state) => const InvoiceCenterScreen(),
      ),
      GoRoute(
        path: '/amc',
        builder: (context, state) => const AmcDashboardScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsDashboardScreen(),
      ),
      GoRoute(
        path: '/ai-assistant',
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: '/referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/timeline',
        builder: (context, state) => const ServiceTimelineScreen(),
      ),
    ],
  );
});
