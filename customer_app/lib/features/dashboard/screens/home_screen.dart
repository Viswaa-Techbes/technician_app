import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/features/services/models/service_models.dart';
import 'package:customer_app/features/services/providers/services_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _popularChips = [
    {'label': 'CCTV Install', 'slug': 'cctv-installation'},
    {'label': 'Network setup', 'slug': 'office-network-deployment'},
    {'label': 'Hardware Fix', 'slug': 'laptop-desktop-repair'},
    {'label': 'AMC Plans', 'slug': 'business-amc-plan'},
  ];

  final List<Map<String, dynamic>> _amcPlans = [
    {
      'name': 'Standard Care',
      'price': '₹4,999/yr',
      'desc': 'For apartments and small homes up to 5 devices.',
      'features': ['1 scheduled audit visit', '2 emergency dispatch visits', '48-hour SLA response', 'Basic email support'],
      'isPopular': false,
    },
    {
      'name': 'Pro Business',
      'price': '₹18,999/yr',
      'desc': 'For active offices and retail shops up to 25 devices.',
      'features': ['4 scheduled audits (quarterly)', 'Unlimited emergency visits', '4-hour SLA response', 'Priority phone & chat support'],
      'isPopular': true,
    },
    {
      'name': 'Enterprise SLA',
      'price': '₹49,999/yr',
      'desc': 'For multi-site companies and warehouse scale teams.',
      'features': ['Monthly scheduled audits', 'Custom dedicated technician', '2-hour SLA response', 'Dedicated account manager'],
      'isPopular': false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(staticCategoriesProvider);
    final services = ref.watch(staticServicesProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Filter out test service from featured list
    final featuredServices = services
        .where((s) => s.slug != 'rupee-one-test-service')
        .toList()
        ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Techbes',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1, fontSize: 24),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.emerald200),
              ),
              child: const Text(
                'Verified IT',
                style: TextStyle(color: AppColors.emerald800, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HOME HERO SECTION
            _buildHero(context, isLight),

            // 2. CATEGORY GRID SECTION
            _buildCategoryGrid(context, categories, isLight),

            // 3. FEATURED SERVICES SECTION
            _buildFeaturedServices(context, featuredServices, isLight),

            // 4. AMC PLANS SECTION
            _buildAmcPlans(context, isLight),

            // 5. RECOMMENDED STRIP SECTION
            _buildRecommendedStrip(context),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isLight) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isLight ? AppColors.emerald50 : AppColors.emerald600.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Premium IT marketplace for homes & businesses',
              style: TextStyle(
                color: isLight ? AppColors.emerald700 : AppColors.emerald400,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Book Verified IT Experts at Your Doorstep',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'From CCTV installations to enterprise networking and annual maintenance contracts, get trusted technicians, transparent pricing, and fast booking.',
            style: TextStyle(
              color: isLight ? AppColors.slate600 : AppColors.slate400,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Search Field
          TextField(
            controller: _searchController,
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                ref.read(searchQueryProvider.notifier).state = value;
                ref.read(selectedCategoryProvider.notifier).state = null;
                context.go('/services');
              }
            },
            decoration: InputDecoration(
              hintText: 'What service do you need today?',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  final value = _searchController.text;
                  if (value.isNotEmpty) {
                    ref.read(searchQueryProvider.notifier).state = value;
                    ref.read(selectedCategoryProvider.notifier).state = null;
                    context.go('/services');
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Suggestion Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularChips.map((chip) {
              return ActionChip(
                backgroundColor: isLight ? Colors.white : AppColors.darkCard,
                side: BorderSide(
                  color: isLight ? AppColors.emerald100 : Colors.white.withOpacity(0.04),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                label: Text(
                  chip['label'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isLight ? AppColors.slate700 : AppColors.slate300,
                  ),
                ),
                onPressed: () {
                  context.push('/service/${chip['slug']}');
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Trust Stats
          _buildTrustStats(isLight),
          const SizedBox(height: 24),

          // Live Pulse Card
          _buildLivePulse(isLight),
        ],
      ),
    );
  }

  Widget _buildTrustStats(bool isLight) {
    return Column(
      children: [
        _buildTrustStatItem(Icons.star, '4.9 / 5', 'Average service rating', isLight),
        const SizedBox(height: 10),
        _buildTrustStatItem(Icons.badge, '2,500+', 'Verified field technicians', isLight),
        const SizedBox(height: 10),
        _buildTrustStatItem(Icons.verified_user, '30 min', 'Average booking confirmation', isLight),
      ],
    );
  }

  Widget _buildTrustStatItem(IconData icon, String value, String label, bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight ? AppColors.slate200 : Colors.white.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.emerald600, size: 18),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                label,
                style: TextStyle(
                  color: isLight ? AppColors.slate500 : AppColors.slate400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLivePulse(bool isLight) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.slate900, Color(0xFF0F766E), AppColors.blue600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Live booking pulse',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.flash_on, color: Colors.tealAccent, size: 18),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Today', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Text('128', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const Text('Confirmed technician visits across top categories.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.tealAccent, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fastest Slot: 11:30 AM (Available)',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLight ? Colors.white : AppColors.darkElevated,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _buildMetricItem('AMC Renewals', '42', 'This week', isLight),
                _buildMetricItem('Same-day Dispatch', '91%', 'Zone coverage', isLight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, String sub, bool isLight) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isLight ? AppColors.slate50 : AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(
      BuildContext context, List<ServiceCategory> categories, bool isLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isLight ? AppColors.slate100 : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Popular categories',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Service categories built for real operational needs',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return InkWell(
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).state = cat.id;
                  ref.read(searchQueryProvider.notifier).state = '';
                  context.go('/services');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isLight ? AppColors.slate200 : Colors.white.withOpacity(0.04),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.emerald50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.settings, color: AppColors.emerald600, size: 20),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cat.servicesLabel,
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedServices(
      BuildContext context, List<MarketplaceService> services, bool isLight) {
    return Container(
      color: AppColors.slate950,
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Featured services',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'High-conversion services customers book most',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return GestureDetector(
                  onTap: () => context.push('/service/${service.slug}'),
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.network(
                          service.image,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            color: Colors.white10,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    service.category,
                                    style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    service.price,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                service.title,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service.tagline,
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmcPlans(BuildContext context, bool isLight) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isLight ? AppColors.blue50 : AppColors.blue600.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Subscription plans',
              style: TextStyle(
                color: isLight ? AppColors.blue700 : Colors.blue[300],
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Annual maintenance plans that keep your IT predictable',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          ..._amcPlans.map((plan) {
            final isPopular = plan['isPopular'] as bool;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : AppColors.darkCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isPopular
                      ? AppColors.emerald500
                      : (isLight ? AppColors.slate200 : Colors.white.withOpacity(0.04)),
                  width: isPopular ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPopular)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.emerald50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Most Popular',
                        style: TextStyle(color: AppColors.emerald800, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Text(
                    plan['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan['desc'],
                    style: TextStyle(
                      color: isLight ? AppColors.slate500 : AppColors.slate400,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    plan['price'],
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                  ),
                  const Divider(height: 24),
                  ... (plan['features'] as List<String>).map((feat) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.emerald500, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feat,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(selectedCategoryProvider.notifier).state = 'amc';
                      context.go('/services');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? AppColors.emerald600 : Colors.transparent,
                      foregroundColor: isPopular ? Colors.white : (isLight ? AppColors.slate700 : Colors.white),
                      shadowColor: isPopular ? null : Colors.transparent,
                      side: isPopular ? null : BorderSide(color: isLight ? AppColors.slate300 : Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: const Text('Choose Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecommendedStrip(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [AppColors.slate900, Color(0xFF134E4A), AppColors.blue600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Recommended for you',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pair AMC coverage with on-demand visits to reduce downtime across all sites',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Most businesses that book networking or surveillance services also activate an AMC plan for preventive health checks and priority support.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(selectedCategoryProvider.notifier).state = 'amc';
                context.go('/services');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.slate950,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Explore AMC Plans', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
