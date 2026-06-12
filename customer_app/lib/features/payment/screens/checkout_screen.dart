import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:customer_app/core/auth/auth_provider.dart';
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/utils/formatters.dart';
import 'package:customer_app/core/notifications/notification_service.dart';
import 'package:customer_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:customer_app/features/payment/providers/payment_provider.dart';
import 'package:customer_app/features/payment/services/razorpay_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final double amount;

  const CheckoutScreen({
    super.key,
    required this.bookingId,
    required this.amount,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final RazorpayService _razorpayService = RazorpayService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _razorpayService.init(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
    );
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(paymentRepositoryProvider);
      
      // Verify payment on backend
      await repo.verifyPayment(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
        bookingId: widget.bookingId,
      );

      // Trigger local notification
      await NotificationService().showNotification(
        id: widget.bookingId.hashCode,
        title: 'Payment Confirmed! 🎉',
        body: 'Advance payment verified. Technician assignment is in progress.',
      );

      // Refresh dashboard
      ref.invalidate(dashboardDataProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Booking confirmed.'),
            backgroundColor: Colors.emerald,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment verification failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    setState(() {
      _errorMessage = 'Payment failed: ${response.message ?? "User cancelled or transaction failed"}';
      _isLoading = false;
    });
  }

  Future<void> _startCheckout() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(authProvider).user;
      final repo = ref.read(paymentRepositoryProvider);

      // Calculate checkout amount:
      // If widget.amount is 0.0, we can fetch the booking details from dashboard cache.
      double payAmount = widget.amount;
      if (payAmount <= 0.0) {
        final dashboardData = ref.read(dashboardDataProvider).value;
        final matching = dashboardData?.bookings.firstWhere(
          (b) => b.id == widget.bookingId,
          orElse: () => dashboardData.upcomingBookings.firstWhere((b) => b.id == widget.bookingId),
        );
        payAmount = (matching?.amount ?? matching?.price ?? 1000.0) / 2.0; // Default to 50% advance
      }

      // 1. Create order on server
      final order = await repo.createOrder(
        bookingId: widget.bookingId,
        amount: payAmount,
      );

      final keyId = order['keyId'] as String? ?? order['key'] as String? ?? 'rzp_test_yourkeyhere';
      final orderId = order['orderId'] as String? ?? order['id'] as String? ?? '';
      final grandTotal = (order['amount'] as num?)?.toDouble() ?? (payAmount * 100);

      // 2. Open Razorpay checkout modal
      _razorpayService.openCheckout(
        key: keyId,
        amount: grandTotal,
        orderId: orderId,
        name: 'Techbes Payments',
        description: 'Advance Payment for Booking #${widget.bookingId.substring(widget.bookingId.length - 6)}',
        email: user?.email ?? 'customer@techbes.com',
        phone: user?.phone ?? '9876543210',
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not initialize payment order: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardData = ref.watch(dashboardDataProvider).value;
    final matchingBooking = dashboardData?.bookings.firstWhere(
      (b) => b.id == widget.bookingId,
      orElse: () => dashboardData.upcomingBookings.firstWhere(
        (b) => b.id == widget.bookingId,
        orElse: () => const MapEntry('id', null) as dynamic,
      ),
    );

    final serviceName = matchingBooking?.serviceName ?? matchingBooking?.title ?? 'IT Technical Service';
    final totalCost = matchingBooking?.amount ?? matchingBooking?.price ?? widget.amount * 2.0;
    final advanceCost = widget.amount > 0 ? widget.amount : totalCost / 2.0;

    return Scaffold(
      backgroundColor: AppColors.slate950,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Complete Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verify your invoice and pay the 50% booking advance to confirm assignment.',
                style: TextStyle(
                  color: Colors.slate[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Order detail card
              Card(
                color: AppColors.slate900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.04)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Booking ID: ${widget.bookingId}',
                        style: TextStyle(
                          color: Colors.slate[400],
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Divider(height: 32, color: Colors.white10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Booking Price', style: TextStyle(color: Colors.slate[300], fontSize: 14)),
                          Text(Formatters.currency(totalCost), style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payable Advance (50%)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            Formatters.currency(advanceCost),
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: _isLoading ? null : _startCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Pay Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.payment_rounded, size: 18),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
