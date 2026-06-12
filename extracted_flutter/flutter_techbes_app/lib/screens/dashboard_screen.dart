import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:techbes_app/providers/auth_provider.dart';
import 'package:techbes_app/providers/cart_provider.dart';
import 'package:techbes_app/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (!authProvider.isLoggedIn) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.login_outlined,
                    size: 64,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sign in to your account',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View your bookings and manage services',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      _showLoginDialog(context, authProvider);
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Section
                Container(
                  color: AppTheme.primaryColor,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        authProvider.currentUser!.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authProvider.currentUser!.email,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // Stats Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Consumer<CartProvider>(
                    builder: (context, cartProvider, _) {
                      final userBookings = cartProvider
                          .getUserBookings(authProvider.currentUser!.id);
                      final confirmedCount = userBookings
                          .where((b) => b.status == 'confirmed')
                          .length;
                      final cancelledCount = userBookings
                          .where((b) => b.status == 'cancelled')
                          .length;

                      return Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Bookings',
                              value: '${userBookings.length}',
                              icon: Icons.shopping_bag_outlined,
                              color: AppTheme.accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Confirmed',
                              value: '$confirmedCount',
                              icon: Icons.check_circle_outlined,
                              color: AppTheme.successColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Cancelled',
                              value: '$cancelledCount',
                              icon: Icons.cancel_outlined,
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Recent Bookings
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Bookings',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, _) {
                          final userBookings = cartProvider
                              .getUserBookings(authProvider.currentUser!.id);

                          if (userBookings.isEmpty) {
                            return Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 48,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No bookings yet',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: userBookings.length,
                            itemBuilder: (context, index) {
                              final booking = userBookings[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    booking.service.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    booking.service.category,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: AppTheme
                                                              .textSecondaryColor,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: booking.status ==
                                                        'confirmed'
                                                    ? AppTheme.successColor
                                                    : AppTheme.errorColor,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                booking.status
                                                    .replaceFirst(
                                                      booking.status[0],
                                                      booking.status[0]
                                                          .toUpperCase(),
                                                    )
                                                    .replaceAll('_', ' '),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 12),
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
                                                      .format(
                                                    booking.scheduledDate,
                                                  ),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Amount',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '\$${booking.totalAmount.toStringAsFixed(2)}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: AppTheme
                                                            .primaryColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
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
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        authProvider.logout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logged out successfully'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLoginDialog(BuildContext context, AuthProvider authProvider) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              authProvider.login(
                emailController.text,
                passwordController.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed in successfully'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
