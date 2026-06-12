import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:customer_app/core/auth/auth_provider.dart';
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/utils/formatters.dart';
import 'package:customer_app/features/dashboard/models/dashboard_models.dart';
import 'package:customer_app/features/dashboard/providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: AppColors.slate950,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardDataProvider.future),
        color: AppColors.emerald500,
        backgroundColor: AppColors.slate900,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.slate[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authState.user?.name ?? 'Guest User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.emerald600.withOpacity(0.2),
                    child: Text(
                      (authState.user?.name ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Quick Booking banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.emerald600, Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald600.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Need Professional IT Setup?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Book verified experts for CCTV installation, diagnostics, and repairs.',
                      style: TextStyle(
                        color: Colors.emerald[50],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/services'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.emerald800,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Book Now',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Metrics & Bookings from API
              dashboardAsync.when(
                data: (data) => _buildDashboardContent(context, data),
                loading: () => _buildShimmerLoading(),
                error: (err, stack) => _buildErrorState(ref, err),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Metrics Grid
        const Text(
          'Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: data.metrics.length,
          itemBuilder: (context, index) {
            final metric = data.metrics[index];
            final isEmerald = metric.tone == 'emerald';
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEmerald
                      ? AppColors.emerald600.withOpacity(0.15)
                      : AppColors.blue600.withOpacity(0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    metric.title,
                    style: TextStyle(color: Colors.slate[400], fontSize: 13),
                  ),
                  Text(
                    metric.value,
                    style: TextStyle(
                      color: isEmerald ? Colors.tealAccent : Colors.blue[300],
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),

        // Upcoming bookings
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Services',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (data.upcomingBookings.isNotEmpty)
              TextButton(
                onPressed: () => context.go('/bookings'),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (data.upcomingBookings.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.slate900,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.02)),
            ),
            child: Column(
              children: [
                Icon(Icons.calendar_today_outlined, color: Colors.slate[600], size: 40),
                const SizedBox(height: 12),
                Text(
                  'No upcoming services scheduled',
                  style: TextStyle(color: Colors.slate[400], fontSize: 14),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.upcomingBookings.length,
            itemBuilder: (context, index) {
              final booking = data.upcomingBookings[index];
              return _buildBookingCard(context, booking);
            },
          ),
      ],
    );
  }

  Widget _buildBookingCard(BuildContext context, UserBooking booking) {
    final displayStatus = booking.status.toUpperCase();
    final isPendingPayment = booking.paymentStatus == 'pending' || booking.paymentStatus == 'unpaid';

    return Card(
      color: AppColors.slate900,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.04)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.serviceName ?? booking.title ?? 'IT Support Service',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(booking.status).withOpacity(0.3)),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_month, size: 14, color: Colors.slate[400]),
                const SizedBox(width: 6),
                Text(
                  booking.scheduledDate ?? booking.bookingDate ?? 'Date TBD',
                  style: TextStyle(color: Colors.slate[300], fontSize: 13),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.slate[400]),
                const SizedBox(width: 6),
                Text(
                  booking.scheduledTime ?? booking.timeSlot ?? 'Time TBD',
                  style: TextStyle(color: Colors.slate[300], fontSize: 13),
                ),
              ],
            ),
            if (booking.technicianName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.badge_outlined, size: 14, color: Colors.slate[400]),
                  const SizedBox(width: 6),
                  Text(
                    'Technician: ${booking.technicianName}',
                    style: const TextStyle(color: Colors.tealAccent, fontSize: 13),
                  ),
                ],
              ),
            ],
            const Divider(height: 24, color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.currency(booking.amount ?? booking.price ?? 0.0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (isPendingPayment)
                      ElevatedButton(
                        onPressed: () => context.push('/checkout', extra: {
                          'bookingId': booking.id,
                          'amount': booking.amount ?? booking.price ?? 0.0
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Pay Now', style: TextStyle(fontSize: 12)),
                      )
                    else if (booking.status == 'assigned' || booking.status == 'en-route')
                      OutlinedButton(
                        onPressed: () => context.push('/tracking/${booking.id}'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Track Live', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.emerald;
      case 'en-route':
      case 'arrived':
      case 'in-progress':
        return Colors.blue;
      case 'assigned':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.slate900,
      highlightColor: AppColors.slate800,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 20,
            width: 100,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            height: 20,
            width: 150,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            2,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 120,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, Object error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          Text(
            'Failed to load dashboard data: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(dashboardDataProvider),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
