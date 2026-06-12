import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:techbes_app/providers/services_provider.dart';
import 'package:techbes_app/theme/app_theme.dart';
import 'package:techbes_app/widgets/service_card.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Services'),
        elevation: 0,
      ),
      body: Consumer<ServicesProvider>(
        builder: (context, servicesProvider, _) {
          final services = servicesProvider.filteredServices.isEmpty
              ? servicesProvider.services
              : servicesProvider.filteredServices;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Filter Section
                Container(
                  color: AppTheme.backgroundColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter by Category',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: servicesProvider.categories.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final isSelected =
                                  servicesProvider.selectedCategory.isEmpty;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: const Text('All'),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    servicesProvider.clearFilter();
                                  },
                                  selectedColor: AppTheme.primaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimaryColor,
                                  ),
                                ),
                              );
                            }
                            final category =
                                servicesProvider.categories[index - 1];
                            final isSelected =
                                servicesProvider.selectedCategory == category.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category.name),
                                selected: isSelected,
                                onSelected: (_) {
                                  servicesProvider.filterByCategory(
                                    category.id,
                                  );
                                },
                                selectedColor: AppTheme.primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimaryColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Services List
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${services.length} Services',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              // Handle sort
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(
                                value: 'rating',
                                child: Text('Rating: High to Low'),
                              ),
                              const PopupMenuItem(
                                value: 'price_asc',
                                child: Text('Price: Low to High'),
                              ),
                              const PopupMenuItem(
                                value: 'price_desc',
                                child: Text('Price: High to Low'),
                              ),
                            ],
                            child: const Icon(Icons.sort),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
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
