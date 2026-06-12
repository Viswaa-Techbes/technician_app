import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/features/services/models/service_models.dart';
import 'package:customer_app/features/services/providers/services_provider.dart';

class ServiceDetailScreen extends ConsumerWidget {
  final String serviceId;

  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(serviceByIdProvider(serviceId));

    if (service == null) {
      return Scaffold(
        backgroundColor: AppColors.slate950,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text(
            'Service not found',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.slate950,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Cover Image Header with Back button
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: AppColors.slate950,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black50,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: CachedNetworkImage(
                    imageUrl: service.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: AppColors.slate900),
                    errorWidget: (context, url, err) => const Icon(Icons.broken_image, size: 60),
                  ),
                ),
              ),

              // Detailed Content
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title & Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            service.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (service.badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
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
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Rating and count
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${service.rating} (${service.reviewCount} reviews)',
                          style: TextStyle(color: Colors.slate[300], fontSize: 13),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.schedule, color: Colors.slate[400], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          service.duration,
                          style: TextStyle(color: Colors.slate[300], fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      service.tagline,
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      service.description,
                      style: TextStyle(
                        color: Colors.slate[300],
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Key Features
                    const Text(
                      'Service Highlights',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...service.features.map((feat) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppColors.emerald500, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  feat,
                                  style: TextStyle(color: Colors.slate[300], fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 32),

                    // What's Included
                    const Text(
                      'What is Included',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...service.includes.map((inc) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  inc,
                                  style: TextStyle(color: Colors.slate[300], fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 32),

                    // FAQs Accordion
                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...service.faqs.map((faq) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.slate900,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              title: Text(
                                faq.question,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                                  child: Text(
                                    faq.answer,
                                    style: TextStyle(color: Colors.slate[300], fontSize: 13, height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 32),

                    // Reviews List
                    const Text(
                      'Customer Reviews',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...service.reviews.map((rev) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.slate900,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rev.user,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        rev.role,
                                        style: TextStyle(color: Colors.slate[500], fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        Icons.star_rounded,
                                        color: i < rev.rating ? Colors.amber : Colors.slate[700],
                                        size: 14,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                rev.comment,
                                style: TextStyle(color: Colors.slate[300], fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  rev.date,
                                  style: TextStyle(color: Colors.slate[600], fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 100), // Spacing for sticky bottom button
                  ]),
                ),
              ),
            ],
          ),

          // Sticky Bottom Bar with Book button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Estimated Price',
                          style: TextStyle(color: Colors.slate[400], fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.price,
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/booking-flow', extra: {'serviceId': serviceId}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Configure Booking',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
