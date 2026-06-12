import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/utils/formatters.dart';
import 'package:customer_app/features/dashboard/models/dashboard_models.dart';
import 'package:customer_app/features/dashboard/providers/dashboard_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: AppColors.slate950,
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardDataProvider.future),
        color: AppColors.emerald500,
        backgroundColor: AppColors.slate900,
        child: dashboardAsync.when(
          data: (data) => _buildBookingList(context, data.bookings),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.emerald500)),
          error: (err, stack) => Center(
            child: Text(
              'Failed to load bookings: $err',
              style: const TextStyle(color: Colors.white60),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingList(BuildContext context, List<UserBooking> bookings) {
    if (bookings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: AppColors.slate600),
                const SizedBox(height: 16),
                const Text(
                  'No Bookings Found',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have not booked any services yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate400, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/services'),
                  child: const Text('Explore Services'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final displayStatus = booking.status.toUpperCase();
        final isCompleted = booking.status.toLowerCase() == 'completed';
        final isPendingPayment = booking.paymentStatus == 'pending' || booking.paymentStatus == 'unpaid';

        return Card(
          color: AppColors.slate900,
          margin: const EdgeInsets.only(bottom: 16),
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
                        booking.serviceName ?? booking.title ?? 'Support Service',
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
                    Icon(Icons.calendar_month, size: 14, color: AppColors.slate400),
                    const SizedBox(width: 6),
                    Text(
                      booking.scheduledDate ?? booking.bookingDate ?? 'Date TBD',
                      style: TextStyle(color: AppColors.slate300, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 14, color: AppColors.slate400),
                    const SizedBox(width: 6),
                    Text(
                      booking.scheduledTime ?? booking.timeSlot ?? 'Time TBD',
                      style: TextStyle(color: AppColors.slate300, fontSize: 13),
                    ),
                  ],
                ),
                if (booking.technicianName != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 14, color: AppColors.slate400),
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
                              'amount': booking.amount ?? booking.price ?? 0.0,
                            }),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emerald600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            child: const Text('Pay Now', style: TextStyle(fontSize: 11)),
                          )
                        else if (isCompleted && booking.rating == null)
                          ElevatedButton(
                            onPressed: () => context.push('/rating/${booking.id}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.slate800,
                              foregroundColor: Colors.tealAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star, size: 12, color: Colors.amber),
                                SizedBox(width: 4),
                                Text('Rate Service', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          )
                        else if (booking.status == 'assigned' || booking.status == 'en-route')
                          OutlinedButton(
                            onPressed: () => context.push('/tracking/${booking.id}'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            child: const Text('Track Live', style: TextStyle(fontSize: 11)),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
