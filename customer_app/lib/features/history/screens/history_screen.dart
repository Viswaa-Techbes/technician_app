import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/core/auth/auth_provider.dart';
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/utils/formatters.dart';
import 'package:customer_app/features/dashboard/models/dashboard_models.dart';
import 'package:customer_app/features/dashboard/providers/dashboard_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Bookings & Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardDataProvider.future),
        color: AppColors.emerald500,
        backgroundColor: isLight ? Colors.white : AppColors.slate900,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. User Header
              _buildHeader(authState, isLight),
              const SizedBox(height: 24),

              dashboardAsync.when(
                data: (data) => _buildDashboardAndHistory(context, ref, data, isLight),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(color: AppColors.emerald500),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'Failed to load dashboard: $err',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthState authState, bool isLight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back,',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              authState.user?.name ?? 'Guest User',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.emerald50,
          child: Text(
            (authState.user?.name ?? 'U').substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: AppColors.emerald800,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardAndHistory(
      BuildContext context, WidgetRef ref, DashboardData data, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 2. Metrics Grid
        const Text(
          'Overview',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemCount: data.metrics.length,
          itemBuilder: (context, index) {
            final metric = data.metrics[index];
            final isEmerald = metric.tone == 'emerald';
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLight ? AppColors.slate200 : Colors.white.withOpacity(0.04),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    metric.title,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  Text(
                    metric.value,
                    style: TextStyle(
                      color: isEmerald ? AppColors.emerald600 : AppColors.blue600,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 28),

        // 3. Upcoming Services
        const Text(
          'Upcoming Services',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (data.upcomingBookings.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: isLight ? Colors.white : AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight ? AppColors.slate200 : Colors.white.withOpacity(0.04),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No upcoming services scheduled',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ...data.upcomingBookings.map((booking) => _buildBookingCard(context, booking, isLight)),
        const SizedBox(height: 28),

        // 4. Past Bookings
        const Text(
          'Service History',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (data.bookings.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            alignment: Alignment.center,
            child: const Text(
              'No past bookings found',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...data.bookings.map((booking) => _buildBookingCard(context, booking, isLight)),
      ],
    );
  }

  Widget _buildBookingCard(BuildContext context, UserBooking booking, bool isLight) {
    final displayStatus = booking.status.toUpperCase();
    final isCompleted = booking.status.toLowerCase() == 'completed';
    final isPendingPayment = booking.paymentStatus == 'pending' || booking.paymentStatus == 'unpaid';

    return Card(
      color: isLight ? Colors.white : AppColors.darkCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLight ? AppColors.slate200 : Colors.white.withOpacity(0.04),
        ),
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
                    booking.serviceName ?? booking.title ?? 'Support Service',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  booking.scheduledDate ?? booking.bookingDate ?? 'Date TBD',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  booking.scheduledTime ?? booking.timeSlot ?? 'Time TBD',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (booking.technicianName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Technician: ${booking.technicianName}',
                    style: const TextStyle(color: Colors.tealAccent, fontSize: 12),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.currency(booking.amount ?? booking.price ?? 0.0),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    if (isPendingPayment)
                      ElevatedButton(
                        onPressed: () => context.push('/checkout', extra: {
                          'bookingId': booking.id,
                          'amount': booking.amount ?? booking.price ?? 0.0,
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Pay Now', style: TextStyle(fontSize: 10)),
                      )
                    else if (isCompleted && booking.rating == null)
                      ElevatedButton(
                        onPressed: () => context.push('/rating/${booking.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald50,
                          foregroundColor: AppColors.emerald800,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, size: 10, color: Colors.amber),
                            SizedBox(width: 4),
                            Text('Rate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else if (booking.status == 'assigned' || booking.status == 'en-route')
                      OutlinedButton(
                        onPressed: () => context.push('/tracking/${booking.id}'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Track Live', style: TextStyle(fontSize: 10)),
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
        return AppColors.success;
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
}
