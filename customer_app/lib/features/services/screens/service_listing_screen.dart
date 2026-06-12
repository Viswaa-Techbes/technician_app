import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/features/services/models/service_models.dart';
import 'package:customer_app/features/services/providers/services_provider.dart';

class ServiceListingScreen extends ConsumerWidget {
  const ServiceListingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(staticCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchController = TextEditingController(text: ref.read(searchQueryProvider));
    final filteredServices = ref.watch(filteredServicesProvider);

    return Scaffold(
      backgroundColor: AppColors.slate950,
      body: CustomScrollView(
        slivers: [
          // Premium Header App Bar
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: AppColors.slate950,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              centerTitle: false,
              title: const Text(
                'Explore Services',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),

          // Search Bar & Filter Options
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search TextField
                  TextField(
                    controller: searchController,
                    onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search for services...',
                      prefixIcon: const Icon(Icons.search, color: Colors.slate),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.slate),
                              onPressed: () {
                                searchController.clear();
                                ref.read(searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Horizontal list of Categories
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        // "All" chip
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: const Text('All Services'),
                            selected: selectedCategory == null,
                            onSelected: (selected) {
                              if (selected) {
                                ref.read(selectedCategoryProvider.notifier).state = null;
                              }
                            },
                          ),
                        ),
                        // List of categories chips
                        ...categories.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(cat.title),
                              selected: selectedCategory == cat.id,
                              onSelected: (selected) {
                                ref.read(selectedCategoryProvider.notifier).state =
                                    selected ? cat.id : null;
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Service Cards Grid/List
          if (filteredServices.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60.0),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 60, color: Colors.slate),
                    SizedBox(height: 16),
                    Text(
                      'No services found matching your query.',
                      style: TextStyle(color: Colors.slate, fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final service = filteredServices[index];
                    return _buildServiceCard(context, service);
                  },
                  childCount: filteredServices.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, MarketplaceService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => context.push('/service/${service.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover image
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: service.image,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 160,
                      color: AppColors.slate800,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.emerald500),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      color: AppColors.slate800,
                      child: const Icon(Icons.broken_image, color: Colors.slate, size: 40),
                    ),
                  ),
                  // Dark gradient overlay on top
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Badge if any
                  if (service.badge != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.emerald600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          service.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Category label overlay
                  Positioned(
                    bottom: 12,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        service.category,
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Title and content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            service.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${service.rating}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.tagline,
                      style: TextStyle(
                        color: Colors.slate[300],
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Colors.white10),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.price,
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.slate[400], size: 14),
                            const SizedBox(width: 4),
                            Text(
                              service.duration,
                              style: TextStyle(
                                color: Colors.slate[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
