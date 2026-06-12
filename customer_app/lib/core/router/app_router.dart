import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:customer_app/core/auth/auth_provider.dart';
import 'package:customer_app/features/auth/screens/login_screen.dart';
import 'package:customer_app/features/auth/screens/signup_screen.dart';
import 'package:customer_app/features/auth/screens/otp_screen.dart';
import 'package:customer_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:customer_app/features/dashboard/screens/home_screen.dart';
import 'package:customer_app/features/cart/screens/cart_screen.dart';
import 'package:customer_app/features/services/screens/service_listing_screen.dart';
import 'package:customer_app/features/services/screens/service_detail_screen.dart';
import 'package:customer_app/features/booking/screens/booking_flow_screen.dart';
import 'package:customer_app/features/booking/screens/booking_success_screen.dart';
import 'package:customer_app/features/payment/screens/checkout_screen.dart';
import 'package:customer_app/features/tracking/screens/tracking_screen.dart';
import 'package:customer_app/features/profile/screens/profile_screen.dart';
import 'package:customer_app/features/profile/screens/edit_profile_screen.dart';
import 'package:customer_app/features/history/screens/history_screen.dart';
import 'package:customer_app/features/ratings/screens/rating_screen.dart';
import 'package:customer_app/features/address/screens/address_screen.dart';
import 'package:customer_app/shared/widgets/app_scaffold.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSigningUp = state.matchedLocation == '/signup';
      final isOtp = state.matchedLocation == '/otp';

      if (authState.isLoading) return null;

      if (!isAuthenticated) {
        if (isLoggingIn || isSigningUp || isOtp) return null;
        return '/login';
      }

      if (isAuthenticated && (isLoggingIn || isSigningUp || isOtp)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpScreen(
            email: extra?['email'] as String? ?? '',
            name: extra?['name'] as String?,
            phone: extra?['phone'] as String?,
            password: extra?['password'] as String?,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/services',
            builder: (context, state) => const ServiceListingScreen(),
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/service/:id',
        builder: (context, state) {
          final serviceId = state.pathParameters['id'] ?? '';
          return ServiceDetailScreen(serviceId: serviceId);
        },
      ),
      GoRoute(
        path: '/booking-flow',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final serviceId = extra?['serviceId'] as String? ?? '';
          return BookingFlowScreen(serviceId: serviceId);
        },
      ),
      GoRoute(
        path: '/booking-success',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final bookingId = extra?['bookingId'] as String? ?? '';
          return BookingSuccessScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final bookingId = extra?['bookingId'] as String? ?? '';
          final amount = extra?['amount'] as double? ?? 0.0;
          return CheckoutScreen(bookingId: bookingId, amount: amount);
        },
      ),
      GoRoute(
        path: '/tracking/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          return TrackingScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/addresses',
        builder: (context, state) => const AddressScreen(),
      ),
      GoRoute(
        path: '/rating/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          return RatingScreen(bookingId: bookingId);
        },
      ),
    ],
  );
});
