import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../repositories/service_repository.dart';
import '../../dashboard/screens/main_navigation_screen.dart';
import '../components/service_config_modal.dart';

class ServicesListScreen extends ConsumerStatefulWidget {
  const ServicesListScreen({super.key});

  @override
  ConsumerState<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends ConsumerState<ServicesListScreen> {
  List<dynamic> _subcategories = [];
  bool _isLoadingSubcategories = false;
  String? _loadedCategorySlug;

  @override
  void initState() {
    super.initState();
    // Initial fetch of CCTV subcategories or whatever is selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeSlug = ref.read(selectedCategoryProvider);
      _fetchSubcategories(activeSlug);
    });
  }

  Future<void> _fetchSubcategories(String slug) async {
    if (slug != 'cctv') {
      setState(() {
        _subcategories = [];
        _loadedCategorySlug = slug;
        _isLoadingSubcategories = false;
      });
      return;
    }

    setState(() {
      _isLoadingSubcategories = true;
      _loadedCategorySlug = slug;
      _subcategories = [];
    });

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/catalog/categories/cctv/subcategories');
      if (response.data != null && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _subcategories = response.data['data'] ?? [];
            _isLoadingSubcategories = false;
          });
        }
      } else {
        throw Exception('Failed to load subcategories');
      }
    } catch (e) {
      debugPrint('Error loading subcategories: $e');
      if (mounted) {
        setState(() {
          _isLoadingSubcategories = false;
          // Robust Fallbacks for CCTV subcategories
          _subcategories = [
            {
              '_id': '1000',
              'name': 'Install New CCTV',
              'slug': 'install-new-cctv',
              'description': 'Fresh CCTV camera installation for homes and offices.',
            },
            {
              '_id': '1001',
              'name': 'Repair Existing CCTV',
              'slug': 'repair-existing-cctv',
              'description': 'Diagnose and repair video loss, DVR/NVR errors, and power faults.',
            },
            {
              '_id': '1002',
              'name': 'Maintenance (AMC)',
              'slug': 'maintenance-amc',
              'description': 'Annual Maintenance Contracts for continuous, uninterrupted security coverage.',
            },
            {
              '_id': '1003',
              'name': 'Upgrade Existing CCTV',
              'slug': 'upgrade-existing-cctv',
              'description': 'Expand your coverage, upgrade to IP cameras, or increase storage capacities.',
            },
            {
              '_id': '1004',
              'name': 'Buy CCTV Products',
              'slug': 'buy-cctv-products',
              'description': 'Purchase individual security cameras, recorders, or cables.',
            },
            {
              '_id': '1005',
              'name': 'Free Site Survey',
              'slug': 'free-site-survey',
              'description': 'Schedule a free on-site survey for custom security planning and estimation.',
            }
          ];
        });
      }
    }
  }

  void _openBookingWizard(dynamic subcategory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ServiceConfigModal(
          serviceSlug: subcategory['slug'] ?? '',
          serviceName: subcategory['name'] ?? '',
          categoryId: 'cctv',
          subcategoryId: subcategory['_id']?.toString() ?? subcategory['id']?.toString() ?? '1000',
          defaultPrice: (subcategory['packages'] != null && subcategory['packages'].isNotEmpty)
              ? (subcategory['packages'][0]['price'] as num).toDouble()
              : 499.0,
        );
      },
    );
  }

  IconData _getCategoryIcon(String slug) {
    switch (slug.toLowerCase()) {
      case 'cctv':
        return Icons.videocam;
      case 'networking':
        return Icons.router;
      case 'laptop':
        return Icons.laptop;
      case 'desktop':
        return Icons.monitor;
      case 'server':
        return Icons.dns;
      case 'electronic-contracts':
        return Icons.article_outlined;
      case 'home-automation':
        return Icons.home_outlined;
      case 'website-development':
        return Icons.language;
      case 'software-licensing':
        return Icons.card_membership_outlined;
      case 'cyber-security':
        return Icons.security_outlined;
      default:
        return Icons.category;
    }
  }

  IconData _getSubcategoryIcon(String slug) {
    if (slug.contains('install')) return Icons.videocam;
    if (slug.contains('repair')) return Icons.build;
    if (slug.contains('maintenance') || slug.contains('amc')) return Icons.handyman;
    if (slug.contains('upgrade')) return Icons.trending_up;
    if (slug.contains('buy') || slug.contains('products')) return Icons.shopping_bag;
    if (slug.contains('survey')) return Icons.assignment;
    return Icons.arrow_circle_right_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategorySlug = ref.watch(selectedCategoryProvider);

    // Sync subcategory loading if category slug changed
    if (_loadedCategorySlug != selectedCategorySlug) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchSubcategories(selectedCategorySlug);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Sidebar for Categories list
          Container(
            width: 110,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: AppTheme.borderColor)),
            ),
            child: ListView.builder(
              itemCount: ServiceRepository.categories.length,
              itemBuilder: (context, index) {
                final cat = ServiceRepository.categories[index];
                final isSelected = selectedCategorySlug == cat.id;
                return InkWell(
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).state = cat.id;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.04) : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(cat.id),
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.title,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Right content panel: Subcategories or Coming Soon
          Expanded(
            child: Container(
              color: AppTheme.backgroundColor,
              child: selectedCategorySlug != 'cctv'
                  ? ComingSoonPanel(
                      categoryTitle: ServiceRepository.categories
                          .firstWhere((c) => c.id == selectedCategorySlug,
                              orElse: () => ServiceRepository.categories[0])
                          .title,
                    )
                  : _isLoadingSubcategories
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                      : _subcategories.isEmpty
                          ? const Center(child: Text('No services found in this category'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _subcategories.length,
                              itemBuilder: (context, index) {
                                final sub = _subcategories[index];
                                final startPrice = sub['packages'] != null && sub['packages'].isNotEmpty
                                    ? '₹${sub['packages'][0]['price']}'
                                    : (sub['slug'] == 'free-site-survey' ? 'Free' : '₹499');

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: AppTheme.borderColor),
                                  ),
                                  child: InkWell(
                                    onTap: () => _openBookingWizard(sub),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                                            child: Icon(
                                              _getSubcategoryIcon(sub['slug'] ?? ''),
                                              color: AppTheme.primaryColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  sub['name'] ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: AppTheme.textPrimaryColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  sub['description'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.textSecondaryColor,
                                                    height: 1.35,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 10),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Starting from: $startPrice',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12.5,
                                                        color: AppTheme.primaryColor,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.primaryColor,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: const Row(
                                                        children: [
                                                          Text(
                                                            'Book Now',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10.5,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          SizedBox(width: 4),
                                                          Icon(
                                                            Icons.arrow_forward,
                                                            color: Colors.white,
                                                            size: 11,
                                                          ),
                                                        ],
                                                      ),
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
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class ComingSoonPanel extends StatelessWidget {
  final String categoryTitle;

  const ComingSoonPanel({super.key, required this.categoryTitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.upcoming_outlined,
                color: AppTheme.secondaryColor,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "$categoryTitle Services",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Coming Soon",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "We are currently setting up operations and certifying local technicians for this category. Full booking will be enabled shortly.",
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("We'll notify you once this category goes live!"),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active_outlined, size: 16),
              label: const Text("Notify Me When Live"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
