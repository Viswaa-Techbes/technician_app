import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:techbes_app/providers/auth_provider.dart';
import 'package:techbes_app/providers/cart_provider.dart';
import 'package:techbes_app/providers/services_provider.dart';
import 'package:techbes_app/theme/app_theme.dart';
import 'package:techbes_app/widgets/service_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Techbes'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Consumer<CartProvider>(
                builder: (context, cartProvider, _) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined),
                        onPressed: () {},
                      ),
                      if (cartProvider.itemCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${cartProvider.itemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryDark,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return Text(
                        authProvider.isLoggedIn
                            ? 'Welcome, ${authProvider.currentUser?.name}'
                            : 'Welcome to Techbes',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: Colors.white),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Premium IT Services & Solutions',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search services...',
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Categories Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categories',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Consumer<ServicesProvider>(
                        builder: (context, servicesProvider, _) {
                          if (servicesProvider.selectedCategory.isNotEmpty) {
                            return GestureDetector(
                              onTap: () {
                                servicesProvider.clearFilter();
                              },
                              child: Text(
                                'View All',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer<ServicesProvider>(
                    builder: (context, servicesProvider, _) {
                      return SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: servicesProvider.categories.length,
                          itemBuilder: (context, index) {
                            final category =
                                servicesProvider.categories[index];
                            final isSelected =
                                servicesProvider.selectedCategory == category.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: GestureDetector(
                                onTap: () {
                                  servicesProvider.filterByCategory(
                                    category.id,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.borderColor,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.category,
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textPrimaryColor,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        category.name.split(' ').first,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppTheme.textPrimaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Popular Services
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popular Services',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Consumer<ServicesProvider>(
                    builder: (context, servicesProvider, _) {
                      final services = servicesProvider.filteredServices.isEmpty
                          ? servicesProvider.services.take(6).toList()
                          : servicesProvider.filteredServices;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          final service = services[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ServiceCard(service: service),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
