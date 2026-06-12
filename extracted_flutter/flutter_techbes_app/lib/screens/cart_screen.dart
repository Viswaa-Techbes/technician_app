import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:techbes_app/providers/auth_provider.dart';
import 'package:techbes_app/providers/cart_provider.dart';
import 'package:techbes_app/theme/app_theme.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        elevation: 0,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          if (cartProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add services to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to services
                    },
                    child: const Text('Browse Services'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Cart Items
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: List.generate(
                      cartProvider.items.length,
                      (index) {
                        final item = cartProvider.items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color: AppTheme.backgroundColor,
                                        ),
                                        child: Icon(
                                          Icons.image,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.service.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.service.category,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppTheme
                                                        .textSecondaryColor,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '\$${item.service.price.toStringAsFixed(2)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    color:
                                                        AppTheme.primaryColor,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          cartProvider.removeFromCart(item.id);
                                        },
                                        color: AppTheme.errorColor,
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Scheduled Date',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('MMM dd, yyyy')
                                                .format(item.scheduledDate),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Quantity',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.remove,
                                                  size: 18,
                                                ),
                                                onPressed: item.quantity > 1
                                                    ? () {
                                                        cartProvider
                                                            .updateQuantity(
                                                          item.id,
                                                          item.quantity - 1,
                                                        );
                                                      }
                                                    : null,
                                                constraints:
                                                    const BoxConstraints(),
                                                padding: EdgeInsets.zero,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                                child: Text(
                                                  '${item.quantity}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.add,
                                                  size: 18,
                                                ),
                                                onPressed: () {
                                                  cartProvider.updateQuantity(
                                                    item.id,
                                                    item.quantity + 1,
                                                  );
                                                },
                                                constraints:
                                                    const BoxConstraints(),
                                                padding: EdgeInsets.zero,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Summary
                Container(
                  color: AppTheme.backgroundColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '\$${cartProvider.totalPrice.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tax (10%)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '\$${(cartProvider.totalPrice * 0.1).toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${(cartProvider.totalPrice * 1.1).toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                          onPressed: () {
                            final authProvider = context.read<AuthProvider>();
                            if (authProvider.isLoggedIn) {
                              cartProvider.checkout(
                                authProvider.currentUser!.id,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Services booked successfully!'),
                                  backgroundColor:
                                      AppTheme.successColor,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please login to proceed'),
                                ),
                              );
                            }
                          },
                          child: const Text('Proceed to Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
