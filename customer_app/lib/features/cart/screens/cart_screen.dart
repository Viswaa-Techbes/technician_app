import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/utils/formatters.dart';
import 'package:customer_app/features/cart/models/cart_item.dart';
import 'package:customer_app/features/cart/providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          cartState.when(
            data: (items) => items.isNotEmpty
                ? TextButton(
                    onPressed: () => _showClearCartConfirm(context, ref),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: cartState.when(
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyCart(context);
          }
          return _buildCartContent(context, ref, items);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.emerald500),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error loading cart: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 72,
              color: isLight ? AppColors.slate300 : AppColors.slate600,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Review and configure your CCTV or IT setup options by adding a service.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isLight ? AppColors.slate500 : AppColors.slate400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/services'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Browse Services', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, WidgetRef ref, List<CartItem> items) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final total = items.fold<double>(
      0.0,
      (sum, item) {
        final breakdown = item.price['priceBreakdown'] as Map?;
        final grand = breakdown?['grandTotal'] ?? item.price['grandTotal'] ?? 0.0;
        return sum + (grand is num ? grand.toDouble() : 0.0);
      },
    );

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildCartItemCard(context, ref, item);
            },
          ),
        ),

        // Order Summary Sticky Panel
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : AppColors.darkCard,
            border: Border(
              top: BorderSide(
                color: isLight ? AppColors.slate200 : Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items (${items.length})',
                      style: TextStyle(
                        color: isLight ? AppColors.slate500 : AppColors.slate400,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      Formatters.currency(total),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Check out the first item or let them proceed to checkout route.
                    // On checkout path, we pass the booking amount.
                    // Since checkout screen expects a bookingId, we will create booking and checkout.
                    // In our parity setup, the checkout processes one cart item or all items.
                    // Let's call the API to create booking from the cart or let checkout handle it!
                    // Let's check how checkout is triggered. It will create booking and go to payment.
                    // Let's create the booking for the first item (or all items) when they checkout.
                    _processCheckout(context, ref, items, total);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Proceed to Checkout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemCard(BuildContext context, WidgetRef ref, CartItem item) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final breakdown = item.price['priceBreakdown'] as Map?;
    final grandTotal = breakdown?['grandTotal'] ?? item.price['grandTotal'] ?? 0.0;
    
    // Details
    final cameraName = item.price['cameraType']?['name'] ?? 'Camera';
    final cameraCount = item.price['cameraCount'] ?? 0;
    final installationArea = item.price['installationArea'] ?? 'indoor';
    final wireLength = item.price['wireLength'] ?? 0;

    final date = item.input['date'] ?? 'No date';
    final time = item.input['time'] ?? 'No time';

    return Card(
      color: isLight ? Colors.white : AppColors.darkCard,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
                    item.serviceName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      onPressed: () => _showItemDetails(context, item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _showDeleteItemConfirm(context, ref, item),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (item.categoryId == 'cctv')
              Text(
                '$cameraName • $cameraCount cameras • $installationArea • ${wireLength}m wire',
                style: TextStyle(
                  color: isLight ? AppColors.slate600 : AppColors.slate400,
                  fontSize: 13,
                ),
              )
            else
              Text(
                'Standard Service Details',
                style: TextStyle(
                  color: isLight ? AppColors.slate600 : AppColors.slate400,
                  fontSize: 13,
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 14,
                      color: isLight ? AppColors.slate400 : AppColors.slate500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$date at $time',
                      style: TextStyle(
                        color: isLight ? AppColors.slate600 : AppColors.slate400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  Formatters.currency(grandTotal is num ? grandTotal.toDouble() : 0.0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context, CartItem item) {
    showDialog(
      context: context,
      builder: (context) {
        final isLight = Theme.of(context).brightness == Brightness.light;
        final breakdown = item.price['priceBreakdown'] as Map?;
        final cameraName = item.price['cameraType']?['name'] ?? 'Camera';
        final cameraCount = item.price['cameraCount'] ?? 0;
        final installationArea = item.price['installationArea'] ?? 'indoor';
        final wireLength = item.price['wireLength'] ?? 0;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(item.serviceName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Configuration details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLight ? AppColors.slate100 : AppColors.slate900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Camera', '$cameraName (x$cameraCount)'),
                      _buildDetailRow('Area Type', installationArea.toUpperCase()),
                      _buildDetailRow('Cabling Length', '$wireLength meters'),
                      _buildDetailRow('Schedule Slot', '${item.input['date']} at ${item.input['time']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Price Breakdown:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildBreakdownItem('Inspection/Base Charge', breakdown?['baseCharge'] ?? 0.0),
                _buildBreakdownItem('Installation labour', breakdown?['cameraTotal'] ?? 0.0),
                if ((breakdown?['areaCharge'] ?? 0.0) > 0)
                  _buildBreakdownItem('Area extra charge', breakdown?['areaCharge'] ?? 0.0),
                _buildBreakdownItem('Cabling cost', breakdown?['wireTotal'] ?? 0.0),
                _buildBreakdownItem('Tax (GST 18%)', breakdown?['taxTotal'] ?? 0.0),
                const Divider(),
                _buildBreakdownItem('Grand Total', breakdown?['grandTotal'] ?? 0.0, isBold: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, dynamic amount, {bool isBold = false}) {
    final amt = amount is num ? amount.toDouble() : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            Formatters.currency(amt),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.tealAccent : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteItemConfirm(BuildContext context, WidgetRef ref, CartItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item?'),
        content: Text('Are you sure you want to remove ${item.serviceName} from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).removeCartItem(item.id);
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showClearCartConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Are you sure you want to remove all configured items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            child: const Text('Clear Cart', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _processCheckout(
    BuildContext context,
    WidgetRef ref,
    List<CartItem> items,
    double total,
  ) async {
    // To checkout, we call the API to create booking from the first cart item.
    // In order to simplify the API create booking structure:
    // We send a POST to `/api/v2/bookings/create` for the item.
    // Let's create the bookings now!
    final api = ApiClient.instance;
    final item = items.first;

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.emerald500),
      ),
    );

    try {
      final payload = {
        'serviceId': item.subcategoryId,
        'cameraTypeId': item.input['cameraTypeId'],
        'cameraCount': item.input['cameraCount'],
        'installationArea': item.input['installationArea'],
        'wireLength': item.input['wireLength'],
        'addonIds': item.input['addonIds'],
        'scheduledDate': item.input['date'],
        'scheduledTime': item.input['time'],
        'addressLine1': item.input['addressLine1'] ?? 'Bengaluru Indiranagar',
        'city': item.input['city'] ?? 'Bengaluru',
        'state': item.input['state'] ?? 'Karnataka',
        'pincode': item.input['pincode'] ?? '560038',
        'notes': item.notes ?? '',
        'latitude': item.input['latitude'] ?? 12.9716,
        'longitude': item.input['longitude'] ?? 77.5946,
      };

      final response = await api.post<Map<String, dynamic>>(
        ApiEndpoints.createBooking,
        data: payload,
      );

      // Dismiss loading
      if (context.mounted) Navigator.pop(context);

      if (response['success'] == true && response['data'] != null) {
        final bookingId = response['data']['id'] ?? response['data']['_id'];
        
        // Remove from cart local and remote
        await ref.read(cartProvider.notifier).removeCartItem(item.id);

        if (context.mounted) {
          context.push('/checkout', extra: {
            'bookingId': bookingId,
            'amount': total,
          });
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Dismiss loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e')),
        );
      }
    }
  }
}
